#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh



export NCURSES=${NCURSES:-"ncurses-6.5"}
export URL_NCURSES=${URL_NCURSES:-"https://invisible-mirror.net/archives/ncurses/$NCURSES.tar.gz"}

# --disable-database --enable-termcap

NCOPTS="--cache-file=${SDKROOT}/build/${NCURSES}.cache --enable-ext-mouse --prefix=$PREFIX --disable-echo --without-pthread \
 --without-tests --without-tack --without-progs --without-manpages \
 --disable-db-install --without-cxx --without-cxx-binding --enable-pc-files \
 --with-pkg-config-libdir=$PREFIX/lib/pkgconfig \
 --with-termlib --enable-termcap --disable-database"


function FIX () {
    echo "


    FIXING report_offsets build


"
    pushd ${SDKROOT}/build/ncurses/ncurses
    ${EMSDK}/upstream/emscripten/emcc -o report_offsets \
 -fpic -DHAVE_CONFIG_H -DUSE_BUILD_CC -DBUILDING_NCURSES -DNDEBUG \
 -I../ncurses -I${SDKROOT}/src/${NCURSES}/ncurses -I../include -I${SDKROOT}/src/${NCURSES}/ncurses/../include \
 -I../ncurses -I. -I${SDKROOT}/src/${NCURSES}/ncurses -I../include -I${SDKROOT}/src/${NCURSES}/ncurses/../include -I${SDKROOT}/devices/emsdk/usr/include \
 -Wno-unused-command-line-argument -Qunused-arguments -Wno-error=implicit-function-declaration \
 ${SDKROOT}/src/${NCURSES}/ncurses/report_offsets.c -L${SDKROOT}/devices/emsdk/usr/lib
    popd
}


if cd ${SDKROOT}/src
then
    if [ -d ${SDKROOT}/src/$NCURSES ]
    then
        echo using $NCURSES local sources
    else
        wget -c $URL_NCURSES && tar xfz $NCURSES.tar.gz
    fi

    if cd ${SDKROOT}/src/$NCURSES
    then
        [ -f $NCURSES.patched ] || patch -p1 < $SDKROOT/support/__EMSCRIPTEN__.deps/${NCURSES}_emscripten.patch
        touch $NCURSES.patched
    fi

    mkdir -p ${SDKROOT}/build/ncurses/

    if true
    then
        cd $ROOT

        if  [ -f ${PREFIX}/lib/libncurses.a ]
        then
            echo "
                * ncurses (non unicode) already built
            " 1>&2
        else
            echo " building non unicode ${NCURSES}"
            rm -rf ${SDKROOT}/build/ncurses/*
            cd ${SDKROOT}/build/ncurses

            CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
             $ROOT/src/${NCURSES}/configure $NCOPTS --disable-widec

            emmake make clean
            emmake make 2>&1 > /dev/null || FIX
            emmake make install 2>&1 > /dev/null || exit 76

        fi
    fi

    if  true
    then
        cd $ROOT

        if [ -f ${PREFIX}/lib/libncursesw.a ]
        then
            echo "
                * ncursesw already built
            "  1>&2
        else
            echo " building wide char ${NCURSES}"

            # build wide char
            rm -rf ${SDKROOT}/build/ncurses/*

            cd ${SDKROOT}/build/ncurses

            #CC=clang CFLAGS="-fpic -Wno-unused-command-line-argument" $ROOT/src/${NCURSES}/configure \
            # $NCOPTS --enable-widec && make && make install

            CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
             $ROOT/src/${NCURSES}/configure $NCOPTS --enable-ext-colors --enable-widec 2>&1 > /dev/null

            emmake make clean
            emmake make 2>&1 > /dev/null || FIX
            emmake make install 2>&1 > /dev/null || exit 106
        fi
    fi
fi

