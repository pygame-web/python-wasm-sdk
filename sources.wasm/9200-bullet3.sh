#!/bin/bash


. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


if pushd ${ROOT}/src
then
    if [ -d bullet3 ]
    then
        echo -n
    else
        git clone --recursive --single-branch --branch master https://github.com/bulletphysics/bullet3
        pushd bullet3

        # tags/3.25
        git checkout 2c204c49e56ed15ec5fcfa71d199ab6d6570b3f5
        popd
    fi

    mkdir -p $ROOT/build/bullet3

    pushd $ROOT/build/bullet3
        emcmake cmake ../../src/bullet3 -DCMAKE_INSTALL_PREFIX=$PREFIX \
 -DBUILD_SHARED_LIBS=NO -DUSE_DOUBLE_PRECISION=NO -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
     -DBUILD_EXTRAS=NO -DBUILD_CPU_DEMOS=NO -DBUILD_PYBULLET=NO -DBUILD_ENET=NO \
     -DBUILD_CLSOCKET=NO -DUSE_GRAPHICAL_BENCHMARK=NO \
     -DBUILD_OPENGL3_DEMOS=NO -DBUILD_BULLET2_DEMOS=NO -DBUILD_UNIT_TESTS=NO
    emmake make install
    popd # build/bullet3

    popd # src
fi

