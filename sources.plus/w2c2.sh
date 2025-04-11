#!/bin/bash

# TODO make it wasm

. ${CONFIG:-config}

mkdir -p src native build/libdwarf  build/zstd

DPIC="-DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

pushd src
    [ -d libdwarf-code ] || git clone --recursive --no-tags --depth 1 --single-branch --branch main https://github.com/davea42/libdwarf-code
    [ -d w2c2 ] || git clone --recursive --no-tags --depth 1 --single-branch --branch main https://github.com/pygame-web/w2c2
    wget -c -q https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz
    tar xfz zstd-1.5.6.tar.gz
popd

if [ -f $HOST_PREFIX/lib/libzstd.a ]
then
    echo "zstd already built"
else
    pushd build/zstd
        cmake $DPIC -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=$HOST_PREFIX ../../src/zstd-1.5.6/build/cmake
        make -j $(nproc) && make install
    popd
fi

if [ -f $HOST_PREFIX/bin/dwarfdump ]
then
    echo "libdarwf already built"
else
    pushd build/libdwarf
        cmake $DPIC -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_DECOMPRESSION=False -DCMAKE_INSTALL_PREFIX=$HOST_PREFIX ../../src/libdwarf-code
        make install
    popd
fi

pushd native

    cmake $DPIC -DCMAKE_INSTALL_PREFIX=$HOST_PREFIX ${SDKROOT}/src/w2c2 \
     -DDWARF_FOUND=1 -DDWARF_LIBRARIES="-ldwarf -lzstd" -DDWARF_LIBRARY_DIRS=$HOST_PREFIX/lib -DDWARF_INCLUDE_DIRS=$HOST_PREFIX/include
    make
popd

