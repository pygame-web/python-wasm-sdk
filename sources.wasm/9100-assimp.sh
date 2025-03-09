#!/bin/bash


. ${CONFIG:-config}

. ${SDKROOT}/scripts/emsdk-fetch.sh


cd ${ROOT}/src


# CMake Warning (dev) at /opt/python-wasm-sdk/devices/x86_64/usr/lib/python3.11/site-packages/cmake/data/share/cmake-3.27/Modules/GNUInstallDirs.cmake:243 (message):
#   Unable to determine default CMAKE_INSTALL_LIBDIR directory because no
#   target architecture is known.  Please enable at least one language before
#   including GNUInstallDirs.


export ASSIMP="assimpjs-wasm"

if [ -f assimp.patched ]
then
    echo "
        already prepared $PREFIX
    "
else
    git clone --recursive https://github.com/pmp-p/$ASSIMP
    pushd $ASSIMP
    # patch -p1 <<END END
    popd
    touch assimp.patched
fi


if [ -f $PREFIX/lib/libassimp.a ]
then
    echo "
        already built in $PREFIX/lib/libassimp.a
    "
else
    mkdir -p $ROOT/build/assimp
    pushd $ROOT/build/assimp
    emcmake ${ROOT}/devices/$(arch)/usr/bin/cmake $ROOT/src/$ASSIMP -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=OFF
    PYDK_CFLAGS="-Wno-nontrivial-memaccess" emmake make install
    popd

    cp -v ./src/assimpjs-wasm/assimp/code/Common/*.h ${PREFIX}/include/assimp/

    [ -f $PREFIX/lib/libassimp.a ] || exit 46
fi
