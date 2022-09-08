#!/bin/bash

. ${CONFIG:-config}

PIP="$(realpath python3-wasm) -m pip"

echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2

# make wheels
# /opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel

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


pushd src

CYTHON=Cython-3.0.0a11-py2.py3-none-any.whl

wget -q -c https://github.com/cython/cython/releases/download/3.0.0a11/${CYTHON}
$PIP install $CYTHON
































popd
