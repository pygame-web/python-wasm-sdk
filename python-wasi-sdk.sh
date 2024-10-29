#!/bin/bash
reset

# TODO: check how dbg tools work with default settings
# https://developer.chrome.com/blog/wasm-debugging-2020/


. /etc/lsb-release
DISTRIB="${DISTRIB_ID}-${DISTRIB_RELEASE}"

SDKROOT=${SDKROOT:-/opt/python-wasm-sdk}

export SDKROOT
export CIVER=${CIVER:-$DISTRIB}
export CI=true

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
    nimsdk=true
fi

if $wasisdk
then
    echo " * adding wasi-sdk to wasm-sdk"
fi

if $nimsdk
then
    echo " * adding nim-sdk to wasm-sdk"
fi


if [ -d ${SDKROOT} ]
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
            #wget https://github.com/bytecodealliance/wasmtime/releases/download/v22.0.0/wasmtime-v22.0.0-x86_64-linux.tar.xz \
            wget https://github.com/bytecodealliance/wasmtime/releases/download/v23.0.2/wasmtime-v23.0.2-$(arch)-linux.tar.xz \
             -O-|xzcat|tar xfv -
            mv -vf $(find wasmtime*|grep /wasmtime$) ${SDKROOT}/devices/$(arch)/usr/bin
        fi

        if $emsdk
        then
            cd ${SDKROOT}

            mkdir -p src build ${SDKROOT}/devices/emsdk ${SDKROOT}/prebuilt/emsdk

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
            ./scripts/emsdk-fetch.sh > /dev/null

            echo " ---------- building cpython wasm support ${PYBUILD} ${CIVER} -----------" 1>&2

            if [ -f /tmp/emsdk.tar ]
            then
                echo " using cached cpython-build-emsdk-deps"
            else
                if ./scripts/cpython-build-emsdk-deps.sh
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
            if ./scripts/cpython-build-emsdk.sh  > /dev/null
            then

                echo " --------- adding some usefull pkg ${PYBUILD} ${CIVER} ---------" 1>&2
                ./scripts/cpython-build-emsdk-prebuilt.sh || exit 223


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

            mkdir -p src build ${SDKROOT}/devices/wasisdk ${SDKROOT}/prebuilt/wasisdk

            # do not source to protect env
            ./scripts/cpython-build-wasisdk.sh

            > ${SDKROOT}/python3-wasi

# ROOT=/opt/python-wasm-sdk SDKROOT=/opt/python-wasm-sdk
# HOST_PREFIX=/opt/python-wasm-sdk/devices/$(arch)/usr
            > ${SDKROOT}/wasm32-wasi-shell.sh

            CPU=wasm32 TARGET=wasi \
             PYDK_PYTHON_HOST_PLATFORM=wasm32-wasi \
             PREFIX=/opt/python-wasm-sdk/devices/wasisdk/usr \
             ./scripts/make-shells.sh

            cat >> $ROOT/wasm32-wasi-shell.sh <<END
#!/bin/bash
. ${WASISDK}/wasisdk_env.sh

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export PS1="[PyDK:wasi] \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]\$ "

END
            chmod +x ${SDKROOT}/python3-wasi ${SDKROOT}/wasm32-wasi-shell.sh

        fi

        if $nimsdk
        then
            ${SDKROOT}/python-nim-sdk.sh
        fi

        mkdir -p /tmp/sdk
        # pack extra build scripts
        pushd /
            tar -cpPRz \
             ${SDKROOT}/scripts/emsdk-extra.sh \
             ${SDKROOT}/scripts/emsdk-fetch.sh \
             ${SDKROOT}/sources.extra/* > /tmp/sdk/sdk-extra.tar.gz

            # pack sdl as minimal prebuilt tar, and use lz4 compression on it
            . ${SDKROOT}/scripts/pack-sdk.sh
        popd

    else
        echo "cd failed"  1>&2
        exit 208
    fi
done



exit 0

