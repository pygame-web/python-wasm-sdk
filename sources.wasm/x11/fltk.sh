#!/bin/bash

. ${CONFIG:-config}


cd ${ROOT}/src


PKG=fltk-wasm


if [ -f ${PKG}.patched ]
then
    echo "
        ${PKG} already prepared
    "
    pushd ${PKG}
else
    git clone --recursive https://github.com/pmp-p/${PKG}
    pushd ${PKG}
    touch ../${PKG}.patched
fi

. ${SDKROOT}/scripts/emsdk-fetch.sh

. fltk-wasm-build.sh


popd

