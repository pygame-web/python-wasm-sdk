#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh

# --disable-database --enable-termcap

NCOPTS="--enable-ext-colors --enable-ext-mouse --prefix=$PREFIX --disable-echo --without-pthread \
 --without-tests --without-tack --without-progs --without-manpages \
 --disable-db-install --without-cxx --without-cxx-binding --enable-pc-files \
 --with-pkg-config-libdir=$PREFIX/lib/pkgconfig \
 --with-termlib --enable-termcap --disable-database"

export PYDK_CC=true
export NCURSES=${NCURSES:-"ncurses-6.5"}
export URL_NCURSES=${URL_NCURSES:-"https://invisible-mirror.net/archives/ncurses/$NCURSES.tar.gz"}

if cd ${ROOT}/src
then

    wget -c $URL_NCURSES && tar xfz $NCURSES.tar.gz

    if cd ${ROOT}/src/$NCURSES
    then
        [ -f $NCURSES.done ] || patch -p1 < $SDKROOT/support/__EMSCRIPTEN__.deps/${NCURSES}_emscripten.patch
        touch $NCURSES.done
    fi

    cd $ROOT
    mkdir -p ${ROOT}/build/ncurses/

    if  [ -f ../devices/emsdk/usr/lib/libncurses.a ]
    then
        echo "
            * skiping [ncurses] or already built
        " 1>&2
    else
        rm -rf ${ROOT}/build/ncurses/*
        cd ${ROOT}/build/ncurses

        #CC=clang CFLAGS="-fpic -Wno-unused-command-line-argument" $ROOT/src/${NCURSES}/configure \
        # $NCOPTS && make && make install

        CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
         $ROOT/src/${NCURSES}/configure \
         $NCOPTS

        if true #patch -p1 < $SDKROOT/support/__EMSCRIPTEN__.deps/${NCURSES}_emscripten_make.patch
        then
            emmake make clean
            if emmake make
            then
                emmake make install
            fi
        fi
    fi

    cd $ROOT
    mkdir -p ${ROOT}/build/ncurses/

    if [ -f devices/emsdk/usr/lib/libncursesw.a ]
    then
        echo "
            * ncursesw already built
        "  1>&2
    else
        # build wide char
        rm -rf ${ROOT}/build/ncurses/*

        cd ${ROOT}/build/ncurses

        #CC=clang CFLAGS="-fpic -Wno-unused-command-line-argument" $ROOT/src/${NCURSES}/configure \
        # $NCOPTS --enable-widec && make && make install

        CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
         $ROOT/src/${NCURSES}/configure $NCOPTS --enable-widec

        cp ncurses/Makefile ncurses/Makefile.makew

        if true #patch -p0 < $SDKROOT/support/__EMSCRIPTEN__.deps/${NCURSES}_emscripten_makew.patch
        then
            emmake make clean
            if emmake make
            then
                emmake make install
            fi
        fi
    fi

fi

