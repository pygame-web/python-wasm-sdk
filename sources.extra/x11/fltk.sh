#!/bin/bash

. ${SDKROOT}/scripts/emsdk-fetch.sh


cd ${ROOT}/src


PKG=fltk-wasm


if [ -f ${PKG}.patched ]
then
    echo "
        ${PKG} already prepared
    "
else
    git clone --recursive https://github.com/pmp-p/${PKG}
    touch ${PKG}.patched
fi

pushd ${PKG}

. fltk-wasm-build.sh


popd

