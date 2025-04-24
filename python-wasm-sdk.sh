#!/bin/bash
reset

if [ $UID -ne 0 ]; then
    echo "not UID 0, assuming not docker"
else
    echo "UID 0, assuming docker debian:stable"
    apt-get update && apt-get --yes install build-essential clang autoconf wget curl lz4 lsb-release zlib1g-dev libssl-dev git
fi

[ -f ../config ] && . ../config

# TODO: check how dbg tools work with default settings
# https://developer.chrome.com/blog/wasm-debugging-2020/

if which python3
then
    SYS_PYTHON=$(which python3)
else
    SYS_PYTHON=$(which python)
fi

DISTRIB_RELEASE=${DISTRIB_RELEASE:-any}

# is it linux enough ?
if [ -f /etc/lsb-release ]
then
    . /etc/lsb-release
    export PLATFORM=linux
else
    # is it Debian
    if [ -f /etc/os-release ]
    then
        . /etc/os-release
        export DISTRIB_ID="${ID}${VERSION_ID}"
        export DISTRIB_RELEASE=$(arch)
    else
        # or not
        export DISTRIB_ID=$($SYS_PYTHON -E -c "print(__import__('sysconfig').get_config_var('HOST_GNU_TYPE'))")
        export PLATFORM=$($SYS_PYTHON -E -c "print(__import__('sys').platform)")
        echo no /etc/lsb-release found, please identify platform $PLATFORM : \"${DISTRIB_ID}-${DISTRIB_RELEASE}\" or hit enter to continue
        read
    fi
fi

export DISTRIB="${DISTRIB_ID}-${DISTRIB_RELEASE}"

export SDKROOT=${SDKROOT:-/tmp/sdk}

# default is behave like a CI
export CI={CI:-true}

# maybe have ci flavours later
export CIVER=${CIVER:-$DISTRIB}


if echo $0|grep -q python-wasm-sdk\.sh
then
    echo " * adding emsdk to wasm-sdk"
    emsdk=true
    wasisdk=${wasisdk:-false}
    nimsdk=${nimsdk:-false}
else
    emsdk=false
    BUILDS=3.13
    wasisdk=true
    gosdk=${gosdk:-false}
    rustsdk=${rustdsk:-false}
    nimsdk=${nimsdk:-false}
fi

for lang in wasisdk gosdk rustsdk nimsdk
do
    if ${!lang:-false}
    then
        echo " * adding ${lang} to wasm-sdk"
    fi
done

if mkdir -p ${SDKROOT}
then
    echo "Assuming destination $SDKROOT is ready"
else
    sudo mkdir -p ${SDKROOT}
    sudo chmod 777 ${SDKROOT}
fi


ORIGIN=$(pwd)

BUILDS=${BUILDS:-"3.12 3.13"}

for PYBUILD in $BUILDS
do
    cd "$ORIGIN"

    export PYBUILD


    if [ -f ${SDKROOT}/dev ]
    then
        echo "${SDKROOT}/dev found : using build cache"
    else
        echo "doing a clean build"
        if [ -d ${SDKROOT}/go ]
        then
            chown -R u+rwx ${SDKROOT}/build ${SDKROOT}/go
        fi
        rm -rf ${SDKROOT}/* ${SDKROOT}/.??*
    fi

    cp -Rf * ${SDKROOT}/
    chmod +x ${SDKROOT}/scripts/*

    if cd ${SDKROOT}/
    then
        mkdir -p build/pycache
        export PYTHONDONTWRITEBYTECODE=1

        # make install cpython will force bytecode generation
        export PYTHONPYCACHEPREFIX="$(realpath build/pycache)"

        # reset config
        unset CONFIG_ENV

        . ${CONFIG:-config}

        cd ${SDKROOT}


        if [ ${PYMINOR} -ge 13 ]
        then
            GILOPT=true
            if ${Py_GIL_DISABLED:-false}
            then
                GIL="--disable-gil --with-mimalloc --disable-experimental-jit"
            else
                Py_GIL_DISABLED=false
                GIL="--without-mimalloc --disable-experimental-jit"
            fi
        else
            GILOPT=false
            GIL=""
        fi

        export GILOPT
        export Py_GIL_DISABLED


        if [ -f $HPY ]
        then
            echo " re-using host python HPY=$HPY"

        else

            cd ${SDKROOT}
            . scripts/cpython-fetch.sh

            cd ${SDKROOT}

            # generic wasm patchwork
            . support/__EMSCRIPTEN__.sh

            . scripts/cpython-build-host.sh 2>&1 >/tmp/python-wasm-sdk.log

            [ -f $HPY ] || exit 100

            . scripts/cpython-build-host-deps.sh > /dev/null

        fi

        [ -f $HPY ] || exit 106


        cat > /opt/python-wasm-sdk/devices/$(arch)/usr/bin/py <<END
#!/bin/bash
export XDG_SESSION_TYPE=x11
export SDKROOT=${SDKROOT}
export PYTHONPATH=/data/git/pygbag/src:/data/git/platform_wasm:${PYTHONPATH}
export PYTHONPYCACHEPREFIX=$PYTHONPYCACHEPREFIX
export HOME=${SDKROOT}
export PATH=${SDKROOT}/devices/$(arch)/usr/bin:\$PATH
export LD_LIBRARY_PATH=${SDKROOT}/devices/$(arch)/usr/lib:${SDKROOT}/devices/$(arch)/usr/lib64:$LD_LIBRARY_PATH
${SDKROOT}/devices/$(arch)/usr/bin/python\${PYBUILD:-$PYBUILD} \$@
END
        chmod +x /opt/python-wasm-sdk/devices/$(arch)/usr/bin/py

        # always install wasmtime because wasm-objdump needs it.
        if [ -f ${SDKROOT}/devices/$(arch)/usr/bin/wastime ]
        then
            echo "keeping installed wasmtime and wasi binaries"
        else
            # wget https://github.com/bytecodealliance/wasmtime/releases/download/v22.0.0/wasmtime-v22.0.0-x86_64-linux.tar.xz
            # wget https://github.com/bytecodealliance/wasmtime/releases/download/v26.0.1/wasmtime-v26.0.1-$(arch)-$(PLATFORM).tar.xz
            # wget https://github.com/bytecodealliance/wasmtime/releases/download/v27.0.0/wasmtime-v27.0.0-$(arch)-${PLATFORM}.tar.xz
            #
# TODO: window only has a zip archive, better use wasmtime-py instead.

            wget https://github.com/bytecodealliance/wasmtime/releases/download/v29.0.1/wasmtime-v29.0.1-$(arch)-${PLATFORM}.tar.xz \
             -O-|xzcat|tar xfv -
            mv -vf $(find wasmtime*|grep /wasmtime$) ${SDKROOT}/devices/$(arch)/usr/bin
        fi

        if $emsdk
        then
            cd ${SDKROOT}

            export TARGET=emsdk

            mkdir -p src build ${SDKROOT}/devices/${TARGET} ${SDKROOT}/prebuilt/${TARGET}

            if [ -f /tmp/emsdk.tar ]
            then
                echo "


            ===========================================================================

            Using emsdk cache from :

            $(cat /tmp/sdk/emsdk.version)


            ===========================================================================



"
                pushd /
                tar xfp /tmp/emsdk.tar
                mkdir -p ${SDKROOT}/src ${SDKROOT}/build
                popd
            fi

            # use ./ or emsdk will pollute env
            if echo $EMFLAVOUR|grep -q ^3\\.
            then
                ./scripts/emsdk-fetch.sh
            else
                ./scripts/emsdk-fetch4.sh
            fi
        # > /dev/null

            echo " ---------- building cpython wasm support ${PYBUILD} ${CIVER} -----------" 1>&2

            if [ -f /tmp/emsdk.tar ]
            then
                echo " using cached cpython-build-emsdk-deps"
            else
                if ./scripts/cpython-build-${TARGET}-deps.sh
                then
#                    if $CI
                    if false
                    then
                        pushd /
                        tar  \
 --exclude=${SDKROOT}/devices/*/usr/bin/*3.1* \
 --exclude=${SDKROOT}/devices/*/usr/lib/python3.1? \
 --exclude=${SDKROOT}/devices/*/usr/include/python3.1? \
 --exclude=${SDKROOT}/config \
 --exclude=${SDKROOT}/python-was?-sdk.sh \
 --exclude=${SDKROOT}/python3-was? \
 --exclude=${SDKROOT}/scripts/* \
 --exclude=${SDKROOT}/sources.* \
 --exclude=${SDKROOT}/build \
 --exclude=${SDKROOT}/src \
 -cpR $SDKROOT > /tmp/emsdk.tar

                        date "+%d-%m-%4Y" > /tmp/sdk/emsdk.version
                        popd
                    fi
                else
                    echo " cpython-build-emsdk-deps failed" 1>&2
                    exit 213
                fi
            fi

            echo " ------------ building cpython wasm ${PYBUILD} ${CIVER} ----------------"  1>&2
            if ./scripts/cpython-build-${TARGET}.sh  > /dev/null
            then

                echo " --------- adding some usefull pkg ${PYBUILD} ${CIVER} ---------" 1>&2
                ./scripts/cpython-build-${TARGET}-prebuilt.sh || exit 223


                # experimental stuff
                chmod +x sources.plus/*.sh
                for extra in sources.plus/*.sh
                do
                    ./$extra
                done

                echo "

                ==========================================================
                                    stripping emsdk ${PYBUILD} ${CIVER}
                ==========================================================        " 1>&2

                rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports*
                rm -rf ${SDKROOT}/emsdk/upstream/emscripten/tests

            else
                echo " cpython-build-emsdk failed" 1>&2
                exit 239
            fi

        fi

        # compile wasi last because of configure patches

        if $wasisdk
        then
            cd ${SDKROOT}

            export TARGET=wasi

            mkdir -p src build ${SDKROOT}/devices/wasisdk ${SDKROOT}/prebuilt/wasisdk

            # do not source to protect env
            ./scripts/cpython-build-wasisdk.sh

            > ${SDKROOT}/python3-${TARGET}

# ROOT=/opt/python-wasm-sdk SDKROOT=/opt/python-wasm-sdk
# HOST_PREFIX=/opt/python-wasm-sdk/devices/$(arch)/usr
            > ${SDKROOT}/wasm32-${TARGET}-shell.sh

            CPU=wasm32
            CPU=$CPU TARGET=$TARGET PYDK_PYTHON_HOST_PLATFORM=${CPU}-${TARGET} \
             PYDK_SYSCONFIG_PLATFORM=${CPU}-${TARGET} \
             PREFIX=/opt/python-wasm-sdk/devices/${TARGET}sdk/usr \
             ./scripts/make-shells.sh

            cat >> $ROOT/${CPU}-${TARGET}-shell.sh <<END
#!/bin/bash
. ${WASISDK}/wasisdk_env.sh

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export PS1="[PyDK:${TARGET}] \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]\$ "

END
            chmod +x ${SDKROOT}/python3-${TARGET} ${SDKROOT}/wasm32-${TARGET}-shell.sh

        fi

        if $nimsdk
        then
            ${SDKROOT}/lang/nimsdk.sh
        fi

        mkdir -p /tmp/sdk/dist
        # pack extra build scripts
        pushd /
            tar -cpPRz \
             ${SDKROOT}/scripts/emsdk-extra.sh \
             ${SDKROOT}/scripts/emsdk-fetch.sh \
             ${SDKROOT}/sources.extra/* > /tmp/sdk/dist/sdk-extra.tar.gz

            # pack sdl as minimal prebuilt tar, and use lz4 compression on it
            . ${SDKROOT}/scripts/pack-sdk.sh
        popd

    else
        echo "cd failed"  1>&2
        exit 208
    fi
done

# remove builder/installer
rm ${SDKROOT}/python-was?-sdk.sh

exit 0

