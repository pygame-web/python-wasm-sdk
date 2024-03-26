#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.8}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

PIP="${SDKROOT}/python3-wasm -m pip"

# all needed for PEP722/723, hpy, cffi modules and wheel building

if echo $PYBUILD|grep -q 3.13$
then
# cython get the latest release on gh install on both host python and build python
pushd build
    wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
    $HPIP install --upgrade $CYTHON_WHL
popd
else
    echo "












        USING CYTHON GIT













"
    $HPIP install --upgrade git+https://github.com/cython/cython
fi


$PIP install build/$CYTHON_WHL


for module in typing_extensions mypy_extensions pyproject-metadata \
 setuptools build wheel pyparsing packaging hatchling setuptools_scm \
 git+https://github.com/python-cffi/cffi meson-python git+https://github.com/pypa/installer
do
    $PIP install --force $module
    if $HPIP install --upgrade --force "$module"
    then
        echo "  pre-installing $module"  1>&2
    else
        echo "  TARGET FAILED on required module $module" 1>&2
        exit 23
    fi
done

# cannot use wasi ninja yet
$HPIP install --force ninja

echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2



# some we want to be certain to have in all minimal rootfs
mkdir -p prebuilt/emsdk/common/site-packages/

# BUG 3.13 : installer

for pkg in pyparsing packaging pkg_resources
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
    if [ -d installer ]
    then
        echo "  * re-using installer git copy"
    else
        echo "  * getting installer git copy"
        git clone --no-tags --depth 1 --single-branch --branch main https://github.com/pypa/installer/
    fi
    cp -rf installer/src/installer ../prebuilt/emsdk/common/site-packages/

popd

rm ${SDKROOT}/prebuilt/emsdk/common/site-packages/installer/_scripts/*exe


