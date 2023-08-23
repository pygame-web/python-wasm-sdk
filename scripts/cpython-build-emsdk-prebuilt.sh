#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.0}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

$HPY -m pip install --upgrade pip

pushd build
    wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
    $HPY install --upgrade $CYTHON_WHL
popd


PIP="${SDKROOT}/python3-wasm -m pip"

echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2


$PIP install --upgrade pip

$PIP install --upgrade build

# make wheels
# /opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel

$PIP install wheel


# cython
$HPY -m pip install build/$CYTHON_WHL
$PIP install build/$CYTHON_WHL


# install them
$PIP install installer


# some we want in all minimal rootfs
mkdir -p prebuilt/emsdk/common/site-packages/
for pkg in installer
do
    if [ -d prebuilt/emsdk/${PYBUILD}/site-packages/$pkg ]
    then
        echo "
            $pkg already set to prebuilt
            "
    else
        $PIP install $pkg
        cp -rf $PREFIX/lib/python${PYBUILD}/site-packages/${pkg} prebuilt/emsdk/common/site-packages/
        cp -rf $PREFIX/lib/python${PYBUILD}/site-packages/${pkg}-* prebuilt/emsdk/common/site-packages/
    fi
done


pushd src


# TODO



















popd
