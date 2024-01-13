#!/bin/bash

. ${CONFIG:-config}


# cmake for assimp build
$HPIP install --upgrade cmake


for pkg in $ROOT/sources.wasm/*.sh
do
    cd $ROOT
    chmod +x $pkg
    echo "

    Third party : $pkg


"
    $pkg
done


cd $ROOT

. ./scripts/emsdk-fetch.sh

# https://download.osgeo.org/libtiff/tiff-4.3.0.tar.gz
# http://code.google.com/intl/en-US/speed/webp/index.html

ALL="-fPIC -s USE_SDL=2 -sUSE_LIBPNG -sUSE_LIBJPEG $CPPFLAGS"
CNF="emconfigure ./configure --prefix=$PREFIX --with-pic --disable-shared --host $(clang -dumpmachine)"

# ncurses ncursesw

# SDL_image

cd $ROOT/src

TIFF_VER="4.6.0"
WEBP_VER="1.3.2"
SDL_IMG="2.8.2"


# AVIF : OFF
# JXL : OFF
# TIF : OFF

# ================== tiff ===================


# OFF
if false
then
    if [ -f ../devices/emsdk/usr/lib/libtiff.a ]
    then
        echo "
        * tiff $TIFF_VER already built
    "
    else
        wget -c https://download.osgeo.org/libtiff/tiff-$TIFF_VER.tar.gz && tar xfz tiff-$TIFF_VER.tar.gz
        pushd tiff-$TIFF_VER
        EMCC_CFLAGS="$ALL" $CNF
        EMCC_CFLAGS="$ALL" emmake make 2>&1>/dev/null
        emmake make install 2>&1>/dev/null
        popd
    fi
else
    echo "  * NOT adding libtiff $TIFF_VER support"
fi

# ============ webp =========================

if [ -f ../devices/emsdk/usr/lib/libwebp.a ]
then
    echo "
    * libwep $WEBP_VER already built
"  1>&2
else
    echo "
            * build libwebp
"  1>&2
    wget -q -c https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$WEBP_VER.tar.gz \
        && tar xfz libwebp-$WEBP_VER.tar.gz
    pushd libwebp-$WEBP_VER
    EMCC_CFLAGS="$ALL" CC=emcc $CNF \
     --disable-threading --disable-neon --disable-sse2 --enable-libwebpdecoder 2>&1>/dev/null
    EMCC_CFLAGS="$ALL" emmake make 2>&1>/dev/null
    emmake make install 2>&1>/dev/null
    popd
fi

# ================== SDL2_image ====================

if [ -f ../devices/emsdk/usr/lib/libSDL2_image.a ]
then
    echo "
    * SDL2_image already built
"  1>&2
else
    #[ -d SDL_image ] || git clone https://github.com/libsdl-org/SDL_image
    if [ -d SDL2_image-2.6.1 ]
    then
        echo "
            * build SDL2_image from release
"  1>&2
    else
        wget -c -q https://github.com/libsdl-org/SDL_image/releases/download/release-${SDL_IMG}/SDL2_image-${SDL_IMG}.tar.gz

        tar xfz SDL2_image-${SDL_IMG}.tar.gz
    fi

    pushd SDL2_image-${SDL_IMG}
    CFLAGS=$CPOPTS EMCC_CFLAGS="$ALL" CC=emcc  $CNF \
     --disable-sdltest --disable-jpg-shared --disable-png-shared
    #--disable-tif-shared
    EMCC_CFLAGS="$ALL" emmake make
    emmake make install
    popd
    [ -f $PREFIX/include/SDL2/SDL_image.h ] || exit 1
fi


# TODO https://github.com/onelivesleft/PrettyErrors





cd $ROOT

