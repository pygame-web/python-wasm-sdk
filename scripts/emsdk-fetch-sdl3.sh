#!/bin/bash

. ${SDKROOT}/config

sdl_get () {
    wget -c -q $1/$2
    tar xfz $2 && rm $2
}

if [ -d ${SDKROOT}/src/SDL3-3.2.4 ]
then
    echo using local files SDKROOT=$SDKROOT PREFIX=$PREFIX
else
    mkdir -p ${SDKROOT}/src
    pushd ${SDKROOT}/src
        sdl_get https://github.com/libsdl-org/SDL/releases/download/release-3.2.4 SDL3-3.2.4.tar.gz
        sdl_get https://github.com/libsdl-org/SDL_image/releases/download/release-3.2.0 SDL3_image-3.2.0.tar.gz
        sdl_get https://github.com/libsdl-org/SDL_ttf/releases/download/prerelease-3.1.2 SDL3_ttf-3.1.2.tar.gz
    popd
fi

. ${SDKROOT}/emsdk/emsdk_env.sh

export SDL3_DIR=${SDKROOT}/build/SDL3
mkdir -p ${SDL3_DIR}
pushd ${SDL3_DIR}

# embuilder --pic sdl3
# "SDL", "SDL_image", "SDL_mixer", "SDL_ttf", "SDL_rtf", "SDL_net"


if ( emcmake cmake -DEMSCRIPTEN=1 -DSDL_VIDEO_DRIVER_DUMMY=1 \
 -DCMAKE_INSTALL_PREFIX=${PREFIX} \
 -DSDL_STATIC_PIC=True \
 -DCMAKE_POSITION_INDEPENDENT_CODE=True \
 ../../src/SDL3-3.?.? && emmake make install )
then
    mkdir -p ${SDKROOT}/build/SDL3_image
    pushd ${SDKROOT}/build/SDL3_image

        if emcmake cmake -DSDL3_DIR=${SDL3_DIR} \
         -DCMAKE_INSTALL_PREFIX=${PREFIX} \
         -DSDL_STATIC_PIC=True \
         -DCMAKE_POSITION_INDEPENDENT_CODE=True \
         ../../src/SDL3_image-3.?.?
        then
            emmake make install
        fi

    popd


    mkdir -p ${SDKROOT}/build/SDL3_ttf
    pushd ${SDKROOT}/build/SDL3_ttf

        if emcmake cmake -DSDL3_DIR=${SDL3_DIR} \
         -DCMAKE_INSTALL_PREFIX=${PREFIX} \
         -DSDL_STATIC_PIC=True \
         -DCMAKE_POSITION_INDEPENDENT_CODE=True \
         ../../src/SDL3_ttf-3.?.?
        then
            EMCC_CFLAGS="-lz" emmake make install
        fi

    popd
else
    echo ERROR
    exit 66
fi
popd

