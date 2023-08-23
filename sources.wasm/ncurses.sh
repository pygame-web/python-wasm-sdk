#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


cd ${ROOT}/src

# --disable-database --enable-termcap

NCOPTS="--enable-ext-colors --enable-ext-mouse --prefix=$PREFIX --disable-echo --without-pthread \
 --without-tests --without-tack --without-progs --without-manpages \
 --disable-db-install --without-cxx --without-cxx-binding --enable-pc-files \
 --with-pkg-config-libdir=$PREFIX/lib/pkgconfig \
 --with-termlib --enable-termcap --disable-database"


export NCURSES=${NCURSES:-"ncurses-6.1"}
export URL_NCURSES=${URL_NCURSES:-"URL https://ftp.NCURSES.org/source/$NCURSES.tar.gz"}
export HASH_NCURSES=${HASH_NCURSES:-"URL_HASH SHA256=aa057eeeb4a14d470101eff4597d5833dcef5965331be3528c08d99cebaa0d17"}



if true
then

    wget -q -c $URL_NCURSES && tar xfz $NCURSES.tar.gz

    pushd $NCURSES
    [ -f $NCURSES.done ] || patch -p1 < $ROOT/support/__EMSCRIPTEN__.deps/ncurses-6.1_emscripten.patch
    touch $NCURSES.done
    popd


    cd $ROOT

    if [ -f devices/emsdk/usr/lib/libncursesw.a ]
    then
        echo "
            * ncursesw already built
        "  1>&2
    else
        mkdir -p build/ncurses/

        # build wide char
        rm -rf build/ncurses/*

        pushd build/ncurses
        make clean
        CC=clang CFLAGS="-fpic -Wno-unused-command-line-argument" $ROOT/src/ncurses-6.1/configure \
         $NCOPTS --enable-widec && make && make install

        popd
    fi



    if  false #[ -f ../devices/emsdk/usr/lib/libncurses.a ]
    then
        echo "
            * skiping [ncurses] or already built
        " 1>&2
    else
        rm -rf ../build/ncurses/*
        pushd ../build/ncurses

        CC=clang CFLAGS="-fpic -Wno-unused-command-line-argument" $ROOT/src/ncurses-6.1/configure \
         $NCOPTS && make && make install

        CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
         $ROOT/src/ncurses-6.1/configure \
         $NCOPTS

        if patch -p1 < $ROOT/support/__EMSCRIPTEN__.deps/ncurses-6.1_emscripten_make.patch
        then
            emmake make clean
            if emmake make
            then
                emmake make install
            fi
        fi
        popd
    fi


    if [ -f ../devices/emsdk/usr/lib/libncursesw.a ]
    then
        echo "
            * ncursesw already built
        "  1>&2
    else
        # build wide char
        pushd ../build/ncurses

        CFLAGS="-fpic -Wno-unused-command-line-argument" emconfigure \
         $ROOT/src/ncurses-6.1/configure $NCOPTS --enable-widec

        if patch -p1 < $SDKROOT/support/__EMSCRIPTEN__.deps/ncurses-6.1_emscripten_makew.patch
        then
            emmake make clean
            if emmake make
            then
                emmake make install
            fi
        fi
        popd
    fi

fi

