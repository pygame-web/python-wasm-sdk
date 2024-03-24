#!/bin/bash

. ${CONFIG:-config}

echo "
    *   cpython-build-host-prebuilt pip==$HPIP   *
" 1>&2


# install and update critical packages.
$HPIP install --upgrade pip


# 3.12 and git deprecated setuptools bundling.
$HPIP install --upgrade setuptools


# probably lot of pip install made in cpython-build-emsdk-prebuilt.sh
# should only go here in host python

# TODO
