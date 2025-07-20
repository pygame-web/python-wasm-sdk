#!/bin/bash

. ${SDKROOT}/config



WEBP_VER="1.4.0"
SDL_IMG="3.2.4"

TIFF_VER="4.6.0"

# AVIF : OFF
# JXL : OFF
# TIF : OFF

sdl_get () {
    wget -c -q $1/$2
    tar xfz $2 && rm $2
}

if [ -d ${SDKROOT}/src/SDL3-3.2.18 ]
then
    echo using local files SDKROOT=$SDKROOT PREFIX=$PREFIX
else
    mkdir -p ${SDKROOT}/src
    pushd ${SDKROOT}/src
        sdl_get https://github.com/libsdl-org/SDL/releases/download/release-3.2.18 SDL3-3.2.18.tar.gz
        sdl_get https://github.com/libsdl-org/SDL_image/releases/download/release-${SDL_IMG} SDL3_image-${SDL_IMG}.tar.gz
        sdl_get https://github.com/libsdl-org/SDL_ttf/releases/download/release-3.2.2 SDL3_ttf-3.2.2.tar.gz
    popd
fi

. ${SDKROOT}/emsdk/emsdk_env.sh

pushd ${SDKROOT}/src

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
     --disable-threading --disable-asserts --disable-neon --disable-sse2 --enable-libwebpdecoder 2>&1>/dev/null
    EMCC_CFLAGS="$ALL" emmake make 2>&1>/dev/null
    emmake make install 2>&1>/dev/null
    popd
fi

if [ -d plutosvg ]
then
    echo "
    *   plutovg and plutosvg already built
"
else
    git clone --recursive --no-tags --depth 1 --single-branch --branch master https://github.com/sammycage/plutosvg

    mkdir -p ${SDKROOT}/build/plutosvg
    pushd ${SDKROOT}/build/plutosvg
        emcmake cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
            ${SDKROOT}/src/plutosvg
        emmake make install
    popd
fi


popd


export SDL3_DIR=${SDKROOT}/build/SDL3
mkdir -p ${SDL3_DIR}
pushd ${SDL3_DIR}

# embuilder --pic sdl3
# "SDL", "SDL_image", "SDL_mixer", "SDL_ttf", "SDL_rtf", "SDL_net"

if ( emcmake cmake -DEMSCRIPTEN=1 -DSDL_VIDEO_DRIVER_DUMMY=1 \
 -DCMAKE_INSTALL_PREFIX=${PREFIX} \
 -DSDL_STATIC_PIC=True \
 -DCMAKE_POSITION_INDEPENDENT_CODE=True \
 ../../src/SDL3-3.*.* && emmake make install )
then
    mkdir -p ${SDKROOT}/build/SDL3_image
    pushd ${SDKROOT}/build/SDL3_image

        if emcmake cmake -DSDL3_DIR=${SDL3_DIR} \
         -DCMAKE_INSTALL_PREFIX=${PREFIX} \
         -DCMAKE_POSITION_INDEPENDENT_CODE=True \
         -Dwebp_LIBRARY=${PREFIX}/lib -Dwebp_INCLUDE_PATH=${PREFIX}/include \
         -Dwebpdemux_LIBRARY=${PREFIX}/lib -Dwebpdemux_INCLUDE_PATH=${PREFIX}/include \
         -DSDLIMAGE_SAMPLES=OFF \
         ../../src/SDL3_image-3.*.*
        then
            emmake make install
        fi

    popd


    mkdir -p ${SDKROOT}/build/SDL3_ttf
    pushd ${SDKROOT}/build/SDL3_ttf

        if emcmake cmake -DSDL3_DIR=${SDL3_DIR} \
         -DCMAKE_INSTALL_PREFIX=${PREFIX} \
         -DCMAKE_POSITION_INDEPENDENT_CODE=True \
         -Dplutovg_LIBRARY=${PREFIX}/lib -Dplutovg_INCLUDE_PATH=${PREFIX}/include/plutovg \
         -Dplutosvg_LIBRARY=${PREFIX}/lib -Dplutosvg_INCLUDE_PATH=${PREFIX}/include/plutosvg \
         -DSDLTTF_SAMPLES=OFF \
         ../../src/SDL3_ttf-3.*.*
        then
            EMCC_CFLAGS="-lz" emmake make install
        fi

    popd
else
    echo ERROR
    exit 66
fi
popd

