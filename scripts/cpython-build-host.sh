#!/bin/bash

. ${CONFIG:-config}

export PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD:-${HPY}}

mkdir -p build/cpython-host

if $REBUILD
then
    echo "
    * building cpython
"
else
    if [ -f ${PYTHON_FOR_BUILD} ]
    then
        REBUILD=false
        echo "  * will *RE-USE* PYTHON_FOR_BUILD found at ${PYTHON_FOR_BUILD}"
    else
        REBUILD=true
    fi
fi

if $REBUILD
then
    pushd build/cpython-host

    # those are for wasm
    unset CPPFLAGS
    unset LDFLAGS


#export OPT="$CPOPTS -DNDEBUG -fwrapv"
    cat $ROOT/src/cpython/Tools/wasm/config.host-wasm32-emscripten <<END
ac_cv_lib_intl_textdomain=no
ac_cv_func_bind_textdomain_codeset=no
END

    CONFIG_SITE=$ROOT/src/cpython/Tools/wasm/config.host-wasm32-emscripten \
    PYOPTS="--disable-ipv6 \
     --with-c-locale-coercion --without-pymalloc --without-pydebug \
     --with-ensurepip\
     --with-decimal-contextvar --disable-shared \
     --with-computed-gotos"

    cat >> pyconfig.h <<END
#ifdef HAVE_LIBINTL_H
#undef HAVE_LIBINTL_H
#endif

#ifdef WITH_LIBINTL
#undef WITH_LIBINTL
#endif

END



    # Prevent freezing bytecode with a different magic
    rm -f $HOST_PREFIX/bin/python3*

    if which python3.11|grep -q python
    then
        echo "


    ===================================================================================

            it's not safe to have a python3.11 in the path while in pre-release cycle
            _sre.MAGIC / bytecode weird errors etc ...

    ===================================================================================

"
        sleep 3
    fi

# OPT="$OPT"
# CFLAGS="-DHAVE_FFI_PREP_CIF_VAR=1 -DHAVE_FFI_PREP_CLOSURE_LOC=1 -DHAVE_FFI_CLOSURE_ALLOC=1"
    if \
    CC=clang CXX=clang++ \
    eval ${ROOT}/src/cpython/configure \
     --prefix=$HOST_PREFIX $PYOPTS $QUIET
    then
        eval make -j$(nproc) install $QUIET
        rm -rf $(find $ROOT/devices/ -type d|grep __pycache__$)

        patchelf --remove-needed libintl.so.8  $HOST_PREFIX/bin/python3.11
        sed -i 's|-lintl ||g' /opt/python-wasm-sdk/devices/x86_64/usr/bin/python3.11-config

        cp -Rfv $ROOT/support/__EMSCRIPTEN__.patches/. $HOST_PREFIX/lib/python3.??/
    else
        echo "
==========================================================================
    ERROR: could not configure cpython

    reminder: you need clang libffi-dev and usual cpython requirements.
==========================================================================
    "
        exit 1
    fi



    popd
else
    echo "

    *   cpython host already built :
            PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD}
"
fi


unset PYTHON_FOR_BUILD
