#!/bin/bash

. ${CONFIG:-config}

echo "
    *   cpython-build-host-prebuilt pip==$HPIP   *
" 1>&2



# probably lot of pip install made in cpython-build-emsdk-prebuilt.sh
# should only go here in host python

# TODO



# install and update critical packages.
$HPIP install --upgrade pip

# 3.12 and git deprecated setuptools bundling.
# NO MORE: setuptools is patched for bdist_wheel
$HPIP install --upgrade setuptools

# install early to build some host tools like w2c2
$HPIP install --upgrade --force cmake
