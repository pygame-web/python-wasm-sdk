#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh

cd ${ROOT}/src

if [ -d uuid-1.6.2 ]
then
    echo ok
else
    #wget -c http://www.mirrorservice.org/sites/ftp.ossp.org/pkg/lib/uuid/uuid-1.6.2.tar.gz
    #tar xfz uuid-1.6.2.tar.gz
    git clone https://github.com/pygame-web/ossp-uuid uuid-1.6.2
fi

INCDIR=$EMSDK/upstream/emscripten/cache/sysroot/include
LIBDIR=$EMSDK/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten

if [ -f $LIBDIR/pic/libossp-uuid.a ]
then
    echo "
        already built in $PREFIX/lib/
    "
else

    mkdir -p $ROOT/build/libuuid

    for mode in "--without-pic"  "--with-pic"
    do
        rm -rf $ROOT/build/libuuid/*
        pushd $ROOT/build/libuuid
            cat > config.site << END
ac_cv_exeext=.cjs
END
            mkdir -p bin
            ln -sf /bin/true bin/strip
            export PATH=$(pwd)/bin:$PATH

            if CONFIG_SIZE=$(pwd)/config.site emconfigure ../../src/uuid-1.6.2/configure --with-gnu-ld $mode --disable-shared --prefix=$PREFIX
            then
                emmake make
                sed -i 's|luuid|lossp-uuid|g' uuid.pc
                cp uuid.pc ../../src/uuid-1.6.2/
                echo "------ installing uuid ---------"
                emmake make install
                mkdir -p ${INCDIR}/ossp
                mv $PREFIX/include/uuid.h ${INCDIR}/ossp/

                cp -r ${INCDIR}/ossp $PREFIX/include/

                if echo $mode | grep -q with-pic
                then
                    mv $PREFIX/lib/libuuid.a $LIBDIR/pic/libossp-uuid.a
                else
                    mv $PREFIX/lib/libuuid.a $LIBDIR/libossp-uuid.a
                fi
                rm $PREFIX/lib/libuuid.la
            else
                echo "

        failed to build uuid-ossp

    "
                exit 44
            fi
        popd
    done
fi

