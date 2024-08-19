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

if [ -f $PREFIX/lib/libossp-uuid.a ]
then
    echo "
        already built in $PREFIX/lib/
    "
else

    mkdir -p $ROOT/build/libuuid
    cat > config.site <<END
ac_cv_prog_ac_ct_STRIP=/bin/true
ac_cv_prog_STRIP=/bin/true
END
    pushd $ROOT/build/libuuid
        mkdir -p bin
        ln -sf /bin/true bin/strip
        export PATH=$(pwd)/bin:$PATH
        if STRIP=/bin/true CONFIG_SITE=config.site emconfigure ../../src/uuid-1.6.2/configure --with-gnu-ld --with-pic --disable-shared --prefix=$PREFIX
        then
            emmake make
            sed -i 's|luuid|lossp-uuid|g' uuid.pc
            cp uuid.pc ../../src/uuid-1.6.2/
            echo "------ installing uuid ---------"
            emmake make install
            INCDIR=$EMSDK/upstream/emscripten/cache/sysroot/include
            LIBDIR=$EMSDK/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
            mkdir -p ${INCDIR}/ossp
            mv $PREFIX/include/uuid.h ${INCDIR}/ossp/

            cp -r ${INCDIR}/ossp $PREFIX/include/
            mv $PREFIX/lib/libuuid.a $PREFIX/lib/libossp-uuid.a
            # FIXME: non pic version is not built
            cp $PREFIX/lib/libossp-uuid.a $LIBDIR
            cp $PREFIX/lib/libossp-uuid.a $LIBDIR/pic
            rm $PREFIX/lib/libuuid.la
        else
            echo "

    failed to build uuid-ossp

"
            exit 44
        fi
    popd
fi

