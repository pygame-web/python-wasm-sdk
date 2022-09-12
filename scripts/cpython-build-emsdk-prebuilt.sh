#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.0a11}
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

# make wheels
# /opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel

$PIP install --upgrade pip

for pkg in wheel installer
do
    if [ -d prebuilt/emsdk/${PYBUILD}/site-packages/$pkg ]
    then
        echo "
            $pkg already set to prebuilt
            "
    else
        $PIP install $pkg
        mv $PREFIX/lib/python${PYBUILD}/site-packages/${pkg} prebuilt/emsdk/${PYBUILD}/site-packages/
        mv $PREFIX/lib/python${PYBUILD}/site-packages/${pkg}-* prebuilt/emsdk/${PYBUILD}/site-packages/
    fi
done


$PIP install build/$CYTHON_WHL



pushd src


# TODO



















popd
