#!/bin/bash


SDKROOT=${SDKROOT:-/opt/python-wasm-sdk}

pushd ${SDKROOT}

. ${CONFIG:-config}


#export PREFIX=${PREFIX:-${SDKROOT}/devices/wasisdk/usr}
export PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD:-${HPY}}


if [ -f ${PYTHON_FOR_BUILD} ]
then
    echo found PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD}
else
    mkdir -p ${SDKROOT}/build/cpython-host
    pushd ${SDKROOT}/build/cpython-host
        CC=clang CXX=clang++ ../../src/cpython${PYBUILD}/configure --prefix=${SDKROOT}/devices/x86_64/usr
        make && make install
    popd
fi


export LD_LIBRARY_PATH=${SDKROOT}/devices/x86_64/usr/lib:$LD_LIBRARY_PATH

if [ -f $PYTHON_FOR_BUILD ]
then

    PYSRC=${SDKROOT}/src/cpython${PYBUILD}

    . ${SDKROOT}/wasisdk/wasisdk_env.sh


    echo "

    * building cpython-wasi ${PREFIX}/bin/python${PYBUILD}.wasm
        from ${PYSRC}
        with PYTHON_FOR_BUILD=$PYTHON_FOR_BUILD
        CC=$CC
        CXX=$CXX
        CPP=$CPP

" 1>&2


    mkdir -p ${SDKROOT}/build/cpython-wasi

    export PLATFORM_TRIPLET=wasm32-unknown-wasi
    cat $PYSRC/Tools/wasm/config.site-wasm32-wasi > $PYSRC/Tools/wasm/config.site-wasm32-wasisdk
    cat  >> $PYSRC/Tools/wasm/config.site-wasm32-wasisdk <<END
ac_cv_func_clock_gettime=yes
ac_cv_func_clock=yes
ac_cv_func_timegm=yes
ac_cv_cc_name=clang
cross_compiling=yes
END

    pushd ${SDKROOT}/build/cpython-wasi
#        sed -i 's| -Wl,--stack-first -Wl,--initial-memory=10485760| --stack-first --initial-memory=10485760|g' $PYSRC/configure.ac
#        sed -i 's| -Wl,--stack-first -Wl,--initial-memory=10485760| --stack-first --initial-memory=10485760|g' $PYSRC/configure

        LDSHARED="${SDKROOT}/wasisdk/upstream/bin/wasm-ld --no-entry" CONFIG_SITE=$PYSRC/Tools/wasm/config.site-wasm32-wasisdk \
        $PYSRC/configure -C $GIL \
        --with-c-locale-coercion --without-pymalloc --disable-ipv6  --with-ensurepip=no \
        --prefix=${PREFIX} \
        --host=wasm32-unknown-wasi --with-suffix=.wasm \
        --build=$($PYSRC/config.guess) \
        --with-build-python=$PYTHON_FOR_BUILD

        cat <<END >>pyconfig.h
#ifdef HAVE_MEMFD_CREATE
#undef HAVE_MEMFD_CREATE
#endif

#ifdef HAVE_PTHREAD_H
#undef HAVE_PTHREAD_H
#endif

//#define HAVE_CLOCK
//#define HAVE_CLOCK_GETTIME
//#define HAVE_TIMEGM
END

        make platform

        if make && make install
        then
            sed -i 's|cpython/pthread_stubs|pthread|g' ${PREFIX}/include/python${PYBUILD}/cpython/pythread.h
        fi
    popd

    pushd ${SDKROOT}/wasisdk
        if [ -f libpython${PYBUILD}.a ]
        then
            echo already moved initial libpython${PYBUILD}.a
        else
            mv /opt/python-wasm-sdk/devices/wasisdk/usr/lib/libpython${PYBUILD}.a /opt/python-wasm-sdk/wasisdk/
        fi

        LINKALL="/opt/python-wasm-sdk/wasisdk/libpython${PYBUILD}.a \
         /opt/python-wasm-sdk/build/cpython-wasi/Modules/_decimal/libmpdec/libmpdec.a \
         /opt/python-wasm-sdk/build/cpython-wasi/Modules/_hacl/libHacl_Hash_SHA2.a \
         /opt/python-wasm-sdk/build/cpython-wasi/Modules/expat/libexpat.a \
         /opt/python-wasm-sdk/wasisdk/upstream/share/wasi-sysroot/lib/wasm32-wasi/libbz2.a \
         /opt/python-wasm-sdk/wasisdk/upstream/share/wasi-sysroot/lib/wasm32-wasi/libz.a \
         /opt/python-wasm-sdk/wasisdk/upstream/share/wasi-sysroot/lib/wasm32-wasi/libsqlite3.a \
         /opt/python-wasm-sdk/wasisdk/upstream/share/wasi-sysroot/lib/wasm32-wasi/libuuid.a"

# maybe just -nostartfiles  ? https://github.com/WebAssembly/wasi-sdk/issues/320
        wasi-c -nostdlib -fpic -r -Wl,--whole-archive -o libpython${PYBUILD}.o $LINKALL
        llvm-ar rcs ${PREFIX}/lib/libpython${PYBUILD}.a libpython${PYBUILD}.o
    popd


else
    echo cannot find PYTHON_FOR_BUILD=$PYTHON_FOR_BUILD
fi

popd
