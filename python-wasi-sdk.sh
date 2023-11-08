#!/bin/bash
reset

# TODO: check how dbg tools work with default settings
# https://developer.chrome.com/blog/wasm-debugging-2020/


. /etc/lsb-release
DISTRIB="${DISTRIB_ID}-${DISTRIB_RELEASE}"

export SDKROOT=/opt/python-wasm-sdk

export CIVER=${CIVER:-$DISTRIB}
export CI=true

if echo $0|grep -q python-wasm-sdk
then
    echo " * adding emsdk to wasm-sdk"
    emsdk=true
else
    emsdk=false
fi

echo " * adding wasi-sdk to wasm-sdk"
wasisdk=true


sudo mkdir -p ${SDKROOT}
sudo chmod 777 ${SDKROOT}

ORIGIN=$(pwd)

# 3.12 3.11 3.10

BUILDS=${BUILDS:-3.12 3.11}

for PYBUILD in $BUILDS
do
    cd "$ORIGIN"

    if [ -f ${SDKROOT}/dev ]
    then
        echo "${SDKROOT}/dev found : using build cache"
    else
        echo "doing a clean build"
        rm -rf ${SDKROOT}/* ${SDKROOT}/.??*
    fi

    cp -Rf * ${SDKROOT}/

    if cd ${SDKROOT}/
    then
        mkdir -p build/pycache
        export PYTHONDONTWRITEBYTECODE=1

        # make install cpython will force bytecode generation
        export PYTHONPYCACHEPREFIX="$(realpath build/pycache)"

        . ${CONFIG:-config}

        cd ${SDKROOT}

        if [ -f $HPY ]
        then
            echo " re-using host python HPY=$HPY"

        else
            cd ${SDKROOT}
            . scripts/cpython-fetch.sh

            cd ${SDKROOT}
            . support/__EMSCRIPTEN__.sh

            . scripts/cpython-build-host.sh 2>&1 >/dev/null

            . scripts/cpython-build-host-deps.sh >/dev/null

        fi

        cd ${SDKROOT}

        if $wasisdk
        then
            echo WASI SDK TODO
            > ${SDKROOT}/python3-wasi

# ROOT=/opt/python-wasm-sdk SDKROOT=/opt/python-wasm-sdk
# HOST_PREFIX=/opt/python-wasm-sdk/devices/$(arch)/usr
            > ${SDKROOT}/wasm32-wasi-shell.sh

            CPU=wasm32 TARGET=wasi \
             PYDK_PYTHON_HOST_PLATFORM=wasm32-wasi \
             PREFIX=/opt/python-wasm-sdk/devices/wasi/usr \
             ./scripts/make-shells.sh

            cat >> $ROOT/wasm32-wasi-shell.sh <<END

export PS1="[PyDK:wasisdk] \w $ "

END

            chmod +x ${SDKROOT}/python3-wasi ${SDKROOT}/wasm32-wasi-shell.sh

            mkdir -p src build ${SDKROOT}/devices/wasi ${SDKROOT}/prebuilt/wasisdk

        fi

        if $emsdk
        then
            # use ./ or emsdk will pollute env
            ./scripts/emsdk-fetch.sh

            echo " ------------ building cpython wasm ${PYBUILD} ${CIVER} ----------------" 1>&2

            if ./scripts/cpython-build-emsdk.sh > /dev/null
            then
                echo " ---------- building cpython wasm plus ${PYBUILD} ${CIVER} -----------" 1>&2
                if ./scripts/cpython-build-emsdk-deps.sh > /dev/null
                then

                    echo " --------- adding some usefull pkg ${PYBUILD} ${CIVER} ---------" 1>&2
                    ./scripts/cpython-build-emsdk-prebuilt.sh


                    echo "

                    ==========================================================
                                        stripping emsdk ${PYBUILD} ${CIVER}
                    ==========================================================
            " 1>&2
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports*
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports/sdl2/SDL-*
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports-builds
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/tests

                else
                    echo " cpython-build-emsdk-deps failed" 1>&2
                    exit 124
                fi
            else
                echo " cpython-build-emsdk failed" 1>&2
                exit 128
            fi

        fi

        . ${SDKROOT}/scripts/pack-sdk.sh

    else
        echo "cd failed"  1>&2
        exit 137
    fi
done

exit 0

