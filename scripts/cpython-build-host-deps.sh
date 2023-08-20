#!/bin/bash

. ${CONFIG:-config}

echo "
    *   cpython-build-host-prebuilt pip==$PIP   *
" 1>&2


# install critical packages.


# 3.12 and git deprecated setuptools bundling.
$PIP install --upgrade setuptools
