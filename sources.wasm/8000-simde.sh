#!/bin/bash

PKG=simde

cd ${ROOT}/src

if [ -d $PKG ]
then
    echo "using $PKG local copy"
else
    git clone --no-tags --depth 1 --single-branch --branch master https://github.com/simd-everywhere/simde
fi

if [ -d $PREFIX/include/${PKG} ]
then
    echo "
        $PKG already built in $PREFIX/include/${PKG}
    "
else
    cp -R ${ROOT}/src/${PKG}/${PKG} $PREFIX/include/
fi



