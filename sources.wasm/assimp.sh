#!/bin/bash



. ${CONFIG:-config}

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

    touch ../assimp.patched
    popd
fi


if [ -f $PREFIX/lib/libassimp.a ]
then
    echo "
        already built in $PREFIX/lib/libassimp.a
    "
else
    . $ROOT/scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/assimp
    pushd $ROOT/build/assimp
    emmake cmake $ROOT/src/$ASSIMP -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=OFF
    emmake make install
    popd
fi

cd $SDKROOT
