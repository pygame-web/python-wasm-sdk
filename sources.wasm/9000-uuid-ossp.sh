#!/bin/bash

. ${CONFIG:-config}



pushd ${ROOT}/src

if [ -d libuuid ]
then
    echo "using local source tree"
else
    #wget -c http://www.mirrorservice.org/sites/ftp.ossp.org/pkg/lib/uuid/libuuid.tar.gz
    #tar xfz libuuid.tar.gz

    #wget -c http://deb.debian.org/debian/pool/main/o/ossp-uuid/ossp-uuid_1.6.4.orig.tar.gz
    #tar xvfz ossp-uuid_1.6.4.orig.tar.gz
    #mv ossp-uuid-UUID_1_6_4 libuuid

    git clone https://github.com/pygame-web/ossp-uuid libuuid

    #tar xfp /data/git/python-wasm-sdk/libuuid.tar

    pushd libuuid
    # libtoolize && aclocal && autoheader && autoconf && autoreconf && automake --add-missing
    #cp -vf /data/git/python-wasm-sdk/{libtool,shtool} ./
    cp -vf /data/git/python-wasm-sdk/shtool ./
    chmod u-w+x libtool shtool
    popd

fi

popd


. scripts/emsdk-fetch.sh

INCDIR=$EMSDK/upstream/emscripten/cache/sysroot/include
LIBDIR=$EMSDK/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten

if [ -f $LIBDIR/pic/libossp-uuid.a ]
then
    echo "
        already built in $PREFIX/lib/
    "
else

    mkdir -p $ROOT/build/libuuid

    for mode in "--without-pic" "--with-pic"
    do
        rm -rf $ROOT/build/libuuid/*
        pushd $ROOT/build/libuuid
            cat > config.site << END
ac_cv_exeext=.cjs
END
            mkdir -p bin
            ln -sf /bin/true bin/strip
            export PATH=$(pwd)/bin:$PATH

            cp -vf /data/git/python-wasm-sdk/{libtool,shtool} /tmp/
            cp -vf /data/git/python-wasm-sdk/libtool ./
            chmod u-w+x /tmp/libtool /tmp/shtool libtool

            if PATH=/tmp:$PATH CONFIG_SITE=$(pwd)/config.site emconfigure ../../src/libuuid/configure --with-gnu-ld $mode --disable-shared --prefix=$PREFIX
            then
                cp -vf /data/git/python-wasm-sdk/{libtool,shtool} /tmp/
                cp -vf /data/git/python-wasm-sdk/libtool ./
                chmod u-w+x /tmp/libtool /tmp/shtool libtool

                PATH=/tmp:$PATH emmake make
# LIBTOOL="'bash ${ROOT}/src/libuuid/libtool'" SHTOOL="'bash ${ROOT}/src/libuuid/shtool'"
                sed -i 's|luuid|lossp-uuid|g' uuid.pc
                cp uuid.pc ../../src/libuuid/

                if echo $mode | grep -q with-pic
                then
                    TARGETLIB=$LIBDIR/pic/libossp-uuid.a
                else
                    TARGETLIB=$LIBDIR/libossp-uuid.a
                fi


                echo "------ installing uuid to $TARGETLIB ---------"

                if PATH=/tmp:$PATH emmake make install
                then
                    mkdir -p ${INCDIR}/ossp
                    cp $PREFIX/include/uuid.h ${INCDIR}/ossp/
                    cp -r ${INCDIR}/ossp $PREFIX/include/
                    mv $PREFIX/lib/libuuid.a $TARGETLIB
                    rm $PREFIX/lib/libuuid.la
                else
                    echo "FIXME: libtool wasm"
                fi

                if [ -f $TARGETLIB ]
                then
                    echo "normal build sucess"
                else
                    echo "TODO: fix uuid ossp for alpine"
                    mkdir -p ${INCDIR}/ossp
                    cp $PREFIX/include/uuid.h ${INCDIR}/ossp/
                    cp -r ${INCDIR}/ossp $PREFIX/include/
                    emar cr libuuid.a *.o
                    mv libuuid.a $TARGETLIB
                fi

            else
                echo "

        failed to build uuid-ossp

    "
                exit 115
            fi
        popd
    done
fi

