#!/bin/bash

. scripts/emsdk-fetch.sh

cd ${ROOT}/src

DO_PATCH=false

if [ -d libgdal ]
then
    echo ok
else
    wget -c https://github.com/OSGeo/gdal/releases/download/v3.9.1/gdal-3.9.1.tar.gz
    tar xfz gdal-3.9.1.tar.gz
    mv gdal-3.9.1 libgdal
    pushd libgdal
        # patches
    popd

fi

if [ -f $PREFIX/lib/libgdal.a ]
then
    echo "
        already built in $PREFIX/lib/libgdal.a
    "
else

    mkdir -p $ROOT/build/libgdal
    pushd $ROOT/build/libgdal

        GDAL_PYTHON_BINDINGS_WITHOUT_NUMPY=1 emcmake cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX ${ROOT}/src/libgdal \
         -DPROJ_DIR=${PREFIX} -DPROJ_LIBRARY=${PREFIX}/lib/libproj.a -DPROJ_INCLUDE_DIR=${PREFIX}/include \
         -DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC:BOOL=ON -DBUILD_PYTHON_BINDINGS=OFF

        emmake make -j 2
        emmake make install

    popd
    [ -f $PREFIX/lib/libgdal.a ] || exit 98
fi

