#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.1}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

# all needed for PEP722/723
PACKAGING="pip build wheel pyparsing packaging installer"

$HPIP install --upgrade $PACKAGING

# setuptools for HPy/static
$HPIP install --upgrade setuptools

# aioconsole only for the simulator
$HPIP install --upgrade aioconsole



PIP="${SDKROOT}/python3-wasm -m pip"

echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2


# support package build/install
$HPY -m pip install --upgrade $PACKAGING

$PIP install --upgrade $PACKAGING

# setuptools for HPy/static
$PIP install --upgrade setuptools



# make wheels
# /opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel


# cython get the latest release on gh
pushd build
    wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
    $HPIP install --upgrade $CYTHON_WHL
popd

$PIP install build/$CYTHON_WHL


# some we want to be certain to have in all minimal rootfs
mkdir -p prebuilt/emsdk/common/site-packages/
for pkg in pyparsing packaging installer pkg_resources
do
    if [ -d prebuilt/emsdk/${PYBUILD}/site-packages/$pkg ]
    then
        echo "
            $pkg already set to prebuilt
            "
    else
        if [ -d ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg} ]
        then
            cp -rf ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg} prebuilt/emsdk/common/site-packages/
            # skip the distinfo to save some space
            #cp -rf ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg}-* prebuilt/emsdk/common/site-packages/

        else
            cp -rf ${ROOT}/.local/lib/python${PYBUILD}/site-packages/{$pkg} prebuilt/emsdk/common/site-packages/
            # skip the distinfo to save some space
        fi
    fi
done


pushd src


# TODO



















popd
