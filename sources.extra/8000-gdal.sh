#!/bin/bash

. ${CONFIG:-config}

DO_PATCH=true

if [ -d src/libgdal ]
then
    echo ok
else
    pushd ${ROOT}/src
        wget -c https://github.com/OSGeo/gdal/releases/download/v3.9.3/gdal-3.9.3.tar.gz
        tar xfz gdal-3.9.3.tar.gz
        mv gdal-3.9.3 libgdal
        pushd libgdal
            if $DO_PATCH
            then
                patch -p1 <<END
--- gdal-3.9.1/port/cpl_recode_iconv.cpp
+++ libgdal/port/cpl_recode_iconv.cpp
@@ -297,8 +297,7 @@
     /*      argument could be declared as char** (as POSIX defines) or      */
     /*      as a const char**. Handle it with the ICONV_CPP_CONST macro here. */
     /* -------------------------------------------------------------------- */
-    ICONV_CPP_CONST char *pszSrcBuf = const_cast<ICONV_CPP_CONST char *>(
-        reinterpret_cast<char *>(pszIconvSrcBuf));
+    char *pszSrcBuf = (char*)pszIconvSrcBuf;

     /* iconv expects a number of bytes, not characters */
     nSrcLen *= nTargetCharWidth;
@@ -315,7 +314,7 @@
     while (nSrcLen > 0)
     {
         const size_t nConverted =
-            iconv(sConv, &pszSrcBuf, &nSrcLen, &pszDstBuf, &nDstLen);
+            iconv(sConv, (const char **)&pszSrcBuf, &nSrcLen, &pszDstBuf, &nDstLen);

         if (nConverted == static_cast<size_t>(-1))
         {
END
            fi
        popd
    popd
fi

if [ -f $PREFIX/lib/libgdal.a ]
then
    echo "
        already built in $PREFIX/lib/libgdal.a
    "
else

    . scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/libgdal
    pushd $ROOT/build/libgdal

    ICONV_H="$EMSDK/upstream/emscripten/cache/sysroot/include/iconv.h"
    cp ${ICONV_H} ${ICONV_H}.save

    if $DO_PATCH
    then
        cat > $ICONV_H <<END
#ifndef _ICONV_H
#define _ICONV_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#define __NEED_size_t

#include <bits/alltypes.h>

typedef void *iconv_t;

iconv_t iconv_open(const char *, const char *);
size_t iconv(iconv_t, const char **__restrict, size_t *__restrict, char **__restrict, size_t *__restrict);
int iconv_close(iconv_t);

#ifdef __cplusplus
}
#endif

#endif
END
    fi

    GDAL_PYTHON_BINDINGS_WITHOUT_NUMPY=1 emcmake cmake \
 -DCMAKE_CXX_FLAGS=-m32 -DCMAKE_C_FLAGS=-m32 \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_POSITION_INDEPENDENT_CODE=True -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX ${ROOT}/src/libgdal \
     -DPROJ_DIR=${PREFIX} -DPROJ_LIBRARY=${PREFIX}/lib/libproj.a -DPROJ_INCLUDE_DIR=${PREFIX}/include \
     -DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC:BOOL=ON -DBUILD_PYTHON_BINDINGS=OFF

    emmake make -j 2
    emmake make install
    mv ${ICONV_H}.save ${ICONV_H}
    popd

fi

if [ -f $PREFIX/lib/libgdal.a ]
then
    echo -n
else
    echo "

    failed to build GDAL

"
    exit 110
fi

