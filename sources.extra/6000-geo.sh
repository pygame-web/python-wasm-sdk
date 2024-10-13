#!/bin/bash

. ${CONFIG:-config}


cd ${ROOT}/src

if [ -d libgeos ]
then
    echo ok
else
    wget -c https://download.osgeo.org/geos/geos-3.12.1.tar.bz2
    tar xfj geos-3.12.1.tar.bz2
    mv geos-3.12.1 libgeos
    pushd libgeos
    patch -p1 <<END
--- geos-3.12.1/CMakeLists.txt	2023-11-11 23:39:58.000000000 +0100
+++ libgeos/CMakeLists.txt	2024-05-30 15:05:39.552891249 +0200
@@ -340,7 +340,8 @@
 endif()

 add_subdirectory(capi)
-
+if (CMAKE_CROSSCOMPILING_EMULATOR)
+else()
 #-----------------------------------------------------------------------------
 # Tests
 #-----------------------------------------------------------------------------
@@ -381,6 +382,7 @@
   add_subdirectory(web)
 endif()

+endif() # EMSCRIPTEN/WASI
 #-----------------------------------------------------------------------------
 # Install and export targets - support 'make install' or equivalent
 #-----------------------------------------------------------------------------
END
    popd

fi

if [ -f $PREFIX/lib/libgeos.a ]
then
    echo "
        already built in $PREFIX/lib/libgeos.a
    "
else
    . ${SDKROOT}/scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/libgeos
    pushd $ROOT/build/libgeos
    emcmake cmake -DCMAKE_POSITION_INDEPENDENT_CODE=True -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX ${ROOT}/src/libgeos
    emmake make -j $(nproc) install
    popd
fi



