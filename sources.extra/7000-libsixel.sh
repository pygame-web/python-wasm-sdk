#!/bin/bash

PKG=libsixel-wasm

pushd ${SDKROOT}/src

[ -d $PKG ] || git clone --no-tags --depth 1 --single-branch --branch python-wasm-sdk https://github.com/pmp-p/libsixel-wasm libsixel-wasm



mkdir -p ${SDKROOT}/build/${PLATFORM_TRIPLET}/${PKG}
pushd ${SDKROOT}/build/${PLATFORM_TRIPLET}/${PKG}
    if $WASI
    then
        emconfigure ${SDKROOT}/src/${PKG}/configure --prefix=$WASI_SYSROOT --with-libcurl=no --disable-python --with-jpeg=no --with-png=no --disable-img2sixel --disable-sixel2png && emmake make install
    else
        emconfigure ${SDKROOT}/src/${PKG}/configure --prefix=${PREFIX} --with-libcurl=no --enable-python --with-jpeg=no --with-png=no --disable-img2sixel --disable-sixel2png && emmake make install
    fi
popd

