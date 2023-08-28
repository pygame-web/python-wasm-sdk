#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.0}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

PACKAGING="pip build wheel pyparsing packaging installer"


$HPY -m pip install --upgrade $PACKAGING

# only for the simulator
$HPY -m pip install --upgrade aioconsole

pushd build
    wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
    $HPY install --upgrade $CYTHON_WHL
popd


PIP="${SDKROOT}/python3-wasm -m pip"

echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2


# support package build/install
$HPY -m pip install --upgrade $PACKAGING
$PIP install --upgrade $PACKAGING

# make wheels
# /opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel


# cython
$HPY -m pip install build/$CYTHON_WHL
$PIP install build/$CYTHON_WHL


# some we want to be certain to have in all minimal rootfs
mkdir -p prebuilt/emsdk/common/site-packages/
for pkg in pyparsing packaging installer
do
    if [ -d prebuilt/emsdk/${PYBUILD}/site-packages/$pkg ]
    then
        echo "
            $pkg already set to prebuilt
            "
    else
        $PIP install $pkg
        cp -rf $PREFIX/lib/python${PYBUILD}/site-packages/${pkg} prebuilt/emsdk/common/site-packages/
        # skip the distinfo to save space
        #cp -rf $PREFIX/lib/python${PYBUILD}/site-packages/${pkg}-* prebuilt/emsdk/common/site-packages/
    fi
done


pushd src


# TODO



















popd
