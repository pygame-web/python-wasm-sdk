#!/bin/bash

. ${CONFIG:-config}

export PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD:-${HPY}}

mkdir -p build/cpython-host $HOST_PREFIX/lib
[ -L $HOST_PREFIX/lib64 ] || ln -s $HOST_PREFIX/lib $HOST_PREFIX/lib64

if $REBUILD
then
    echo "
        * building CPython $PYBUILD for $CIVER
    " 1>&2
else
    if [ -f ${PYTHON_FOR_BUILD} ]
    then
        REBUILD=false
        echo "
            * will *RE-USE* PYTHON_FOR_BUILD found at ${PYTHON_FOR_BUILD}
        " 1>&2
    else
        REBUILD=true
    fi
fi

# special case build testsuite
# pygame-web won't build test modules
if echo $GITHUB_WORKSPACE|grep -q /python-wasm-sdk/
then
    TESTSUITE=""
else
    TESTSUITE="--enable-test-modules"
fi

echo "




    ********** TESTSUITE test-modules == $TESTSUITE *******************




" 1>&2


if $REBUILD
then
    pushd build/cpython-host

    # those are for wasm
    unset CPPFLAGS
    unset LDFLAGS

#export OPT="$CPOPTS -DNDEBUG -fwrapv"
    mkdir -p $ROOT/src/cpython${PYBUILD}/Tools/wasm
    cat > $ROOT/src/cpython${PYBUILD}/Tools/wasm/config.host-wasm32-emscripten <<END
ac_cv_lib_intl_textdomain=no
ac_cv_func_bind_textdomain_codeset=no
END

    CONFIG_SITE=$ROOT/src/cpython${PYBUILD}/Tools/wasm/config.host-wasm32-emscripten \
    PYOPTS="--disable-ipv6 \
     --with-c-locale-coercion --without-pymalloc --without-pydebug \
     --with-ensurepip $TESTSUITE \
     --with-decimal-contextvar --disable-shared"

    cat >> pyconfig.h <<END
#ifdef HAVE_LIBINTL_H
#warning "HAVE_LIBINTL_H but We do not want to link to libintl"
#undef HAVE_LIBINTL_H
#endif

#ifdef WITH_LIBINTL
#warning "WITH_LIBINTL but We do not want to link to libintl"
#undef WITH_LIBINTL
#endif

END

    if echo $PYBUILD|grep -q 3\\.14$
    then
        # Prevent freezing bytecode with a different magic
        rm -f $HOST_PREFIX/bin/python3 $HOST_PREFIX/bin/python${PYBUILD}
        if command -v python3.${PYMINOR}
        then
            echo "

    ===================================================================================

            it's not safe to have a python3.${PYMINOR} in the path :
                $(command -v python3.${PYMINOR})
            while in pre-release cycle : _sre.MAGIC / bytecode weird errors etc ...

    ===================================================================================

            " 1>&2
            sleep 6
        fi
    fi

#  CFLAGS="-fPIC" CPPFLAGS="-fPIC"
    CNF="${ROOT}/src/cpython${PYBUILD}/configure \
     --prefix=$HOST_PREFIX $PYOPTS $GIL"
    if CC=clang CXX=clang++ $CNF
    then
        if make -j$(nproc)
        then
            if make install
            then
                echo "CPython $PYTHON_FOR_BUILD ready" 1>&2
            else
                echo "CPython $PYTHON_FOR_BUILD failed to install" 1>&2
                exit 117
            fi
        else
            echo "
failed to build $PYTHON_FOR_BUILD

CC=clang CXX=clang++ $CNF
"  1>&2
            exit 125
        fi
    else
        echo "
==========================================================================
    ERROR: could not configure cpython

    reminder: you need clang libffi-dev and usual cpython requirements.

CC=clang CXX=clang++ $CNF

==========================================================================
    " 1>&2
        exit 149
    fi

    popd
else
    echo "
        *   cpython host already built :
                PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD}
    " 1>&2
fi


unset PYTHON_FOR_BUILD
