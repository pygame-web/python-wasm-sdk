#!/bin/bash
reset
export SDKDIR=/opt/python-wasm-sdk

sudo mkdir -p ${SDKDIR}
sudo chmod 777 ${SDKDIR}

mv * ${SDKDIR}/

if cd ${SDKDIR}/
then
    mkdir -p build/pycache
    export PYTHONDONTWRITEBYTECODE=1

    # make install cpython will force bytecode generation
    export PYTHONPYCACHEPREFIX="$(realpath build/pycache)"

    . ${CONFIG:-config}

    . scripts/cpython-fetch.sh
    . support/__EMSCRIPTEN__.sh
    . scripts/cpython-build-host.sh >/dev/null
    . scripts/cpython-build-host-deps.sh >/dev/null

    # use ./ or emsdk will pollute env
    ./scripts/emsdk-fetch.sh

    echo " ------------------- building cpython wasm -----------------------"
    if ./scripts/cpython-build-emsdk.sh > /dev/null
    then
        echo " ------------------- building cpython wasm plus -------------------"
        if ./scripts/cpython-build-emsdk-deps.sh > /dev/null
        then
            echo "making tarball"
            cd /
            rm -rf ${SDKDIR}/emsdk/upstream/emscripten/cache
            mkdir -p ${SDKDIR}/sdk
            tar -cpRj \
                .${SDKDIR}/config \
                .${SDKDIR}/${PYDK_PYTHON_HOST_PLATFORM}-shell.sh \
                .${SDKDIR}/emsdk \
                .${SDKDIR}/devices/* \
                .${SDKDIR}/prebuilt/* \
                 > ${SDKDIR}/sdk/python-wasm-sdk-stable.tar.bz2
        else
            echo " cpython-build-emsdk-deps failed"
            exit 2
        fi
    else
        echo " cpython-build-emsdk failed"
        exit 1
    fi

    echo done
else
    echo failed
fi
