#!/bin/bash


if [[ -z ${WASISDK+z} ]]
then
    . ${CONFIG:-config}

    export WASISDK="${SDKROOT}/wasisdk"
    export WASI_SDK_PREFIX="${WASISDK}/upstream"



    if [ -d ${WASI_SDK_PREFIX} ]
    then
        echo "
        * using wasisdk from $(realpath wasisdk/upstream)
            with sys python $SYS_PYTHON
" 1>&2
    else
        pushd wasisdk
        if [ -f /pp ]
        then
            wget -c http://192.168.1.66/cfake/wasi-sdk-20.0-linux.tar.gz
        else
            wget -c https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sdk-20.0-linux.tar.gz
        fi
        tar xfz wasi-sdk-20.0-linux.tar.gz
        mv wasi-sdk-20.0 upstream && rm wasi-sdk-20.0-linux.tar.gz
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-cpp
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c++
        popd

    fi

    export PATH="${WASISDK}/bin:${WASI_SDK_PREFIX}/bin:$PATH"

    export WASI_SYSROOT="${WASI_SDK_PREFIX}/share/wasi-sysroot"

    export CC="${WASISDK}/bin/wasi-c"
    export CPP="${WASISDK}/bin/wasi-cpp"
    export CXX="${WASISDK}/bin/wasi++"


    export LDSHARED="${WASI_SDK_PREFIX}/bin/wasm-ld"
    export AR="${WASI_SDK_PREFIX}/bin/llvm-ar"
    export RANLIB="${WASI_SDK_PREFIX}/bin/ranlib"


    # instruct pkg-config to use wasi target root
    export PKG_CONFIG_PATH="${SDKROOT}/devices/wasi/usr/lib/pkgconfig"

    # for thirparty prebuilts .pc in sdk
    export PKG_CONFIG_LIBDIR="${WASI_SYSROOT}/lib/pkgconfig:${WASI_SYSROOT}/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="${WASI_SYSROOT}"




else
    echo "wasidk: config already set !" 1>&2
fi
