#!/bin/bash


. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


if pushd ${ROOT}/src
then
    if [ -d ODE-wasm ]
    then
        echo -n
    else
        git clone --recursive --no-tags --depth 1 --single-branch --branch python-wasm-sdk https://github.com/pygame-web/ODE-wasm
    fi

    mkdir -p $ROOT/build/ode

    if [ -f ${PREFIX}/lib/libode.a ]
    then
    echo    "
        * ODE already built
    "
    else
        pushd $ROOT/build/ode
            emcmake cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX=$PREFIX \
     -DODE_NO_THREADING_INTF=OFF -DODE_NO_BUILTIN_THREADING_IMPL=OFF \
     -DODE_WITH_DEMOS=OFF ${ROOT}/src/ODE-wasm
        sed -i 's/#error/\/\/#warning/g' ode/src/config.h
        emmake make install
        popd
    fi

    popd
fi

