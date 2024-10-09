#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.11}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

if echo $CYTHON_REL|grep -q 3\\.0\\.11$
then
    CYTHON_REL=3.0.11-1
fi


PIP="${SDKROOT}/python3-wasm -m pip"

$HPIP install \
 trove-classifiers pluggy pathspec packaging hatchling \
 typing_extensions mypy_extensions pyproject_hooks pyproject-metadata \
 build pyparsing packaging hatchling setuptools_scm meson-python \
 idna urllib3 charset_normalizer certifi tomli requests flit pip


# all needed for PEP722/723, hpy, cffi modules and wheel building

for module in /data/git/flit/flit_core \
 git+https://github.com/pygame-web/wheel \
 git+https://github.com/pygame-web/setuptools \
 git+https://github.com/python-cffi/cffi \
 git+https://github.com/pypa/installer
do
    echo "

  pre-installing $module
_____________________________________________
"  1>&2

    # $PIP install --no-build-isolation $module
    if $HPIP install --no-deps --no-index --no-build-isolation --force "$module"
    then
        echo -n ok
    else
        echo "  TARGET FAILED on required module $module" 1>&2
        exit 39
    fi
done



if [ ${PYMINOR} -ge 13 ]
then

    echo "


        USING CYTHON GIT for $PYBUILD




"
    # $HPIP install setuptools
    $HPIP install --upgrade --no-build-isolation --force git+https://github.com/pygame-web/cython.git
else
    # cython get the latest release on gh install on both host python and build python
    pushd build
    wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
    $HPIP install --upgrade $CYTHON_WHL
    popd
    $PIP install build/$CYTHON_WHL
fi


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



