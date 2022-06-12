#!/bin/bash
reset
export SDKDIR=/opt/python-wasm-sdk

sudo mkdir -p ${SDKDIR}
sudo chmod 777 ${SDKDIR}

cp -Rf * ${SDKDIR}/

if cd ${SDKDIR}/
then
    pwd
    mkdir -p build/pycache
    export PYTHONDONTWRITEBYTECODE=1

    # make install cpython will force bytecode generation
    export PYTHONPYCACHEPREFIX="$(realpath build/pycache)"

    . ${CONFIG:-config}

    . scripts/cpython-fetch.sh
    . support/__EMSCRIPTEN__.sh
    . scripts/cpython-build-host.sh
# >/dev/null
    . scripts/cpython-build-host-deps.sh
# >/dev/null

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

            mkdir -p /tmp/sdk
            tar -cpPR \
                ${SDKDIR}/config \
                ${SDKDIR}/build/pycache/.??* \
                ${SDKDIR}/build/pycache/sysconfig/_sysconfigdata__emscripten_debug.py \
                ${SDKDIR}/python3-wasm \
                ${SDKDIR}/wasm32-*-shell.sh \
                ${SDKDIR}/emsdk \
                ${SDKDIR}/devices/* \
                ${SDKDIR}/prebuilt/* \
                > /tmp/sdk/python-wasm-sdk-stable.tar
                lz4 /tmp/sdk/python-wasm-sdk-${$CIVER:-ubuntu-latest}.tar
                # bzip2 will remove original
                bzip2 /tmp/sdk/python-wasm-sdk-${$CIVER:-ubuntu-latest}.tar
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
