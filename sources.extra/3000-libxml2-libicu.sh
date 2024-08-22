#!/bin/bash

. ${CONFIG:-config}


if [ -d src/icu ]
then
    echo ok
else
    pushd ${ROOT}/src
        wget -c https://github.com/unicode-org/icu/releases/download/release-75-1/icu4c-75_1-src.tgz
        tar xfz icu4c-75_1-src.tgz
    popd
fi

if [ -f $PREFIX/lib/libicui18n.a ]
then
    echo "
        $PREFIX/lib/libicui18n.a already built
    "
else
    . scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/libicu

    pushd $ROOT/build/libicu
        if emconfigure $ROOT/src/icu/source/configure --prefix=$PREFIX \
         --disable-shared --enable-static \
         --disable-samples --disable-tests --disable-tools \
         --disable-extras --disable-draft
        then
            [ -f ./common/Makefile.patched ] && rm ./common/Makefile.patched
            grep -v DDEFAULT_ICU_PLUGINS ./common/Makefile > ./common/Makefile.patched
            cat ./common/Makefile.patched > ./common/Makefile
            emmake make
            cat ./common/Makefile.patched > ./common/Makefile
            emmake make install
        fi
    popd

    if [ -f $PREFIX/lib/libicui18n.a ]
    then
        echo -n
    else
        echo "

    failed to build ICU

"
        exit 49

    fi
fi

