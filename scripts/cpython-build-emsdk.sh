#!/bin/bash

. ${CONFIG:-config}

# TODO:
# fix /pip/_internal/operations/install/wheel.py
# for allowing to avoid pyc creation

    echo "

    * building cpython-wasm EMSDK_PYTHON=$SYS_PYTHON and install to $PREFIX

" 1>&2


export PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD:-${HPY}}

. ./scripts/emsdk-fetch.sh

if ${REBUILD_WASMPY:-false}
then
    rm -rf build/cpython-wasm/ build/pycache/config.cache
    rm build/cpython-wasm/libpython${PYBUILD}.a 2>/dev/null
    rm prebuilt/emsdk/libpython${PYBUILD}.a prebuilt/emsdk/${PYBUILD}/*.so
    REBUILD=true
fi

# 3.10 is not wasm stable
if [ -f support/__EMSCRIPTEN__.patches/${PYBUILD}.diff ]
then
    pushd src/cpython${PYBUILD} 2>&1 >/dev/null
    patch -p1 < ../../support/__EMSCRIPTEN__.patches/${PYBUILD}.diff
    popd 2>&1 >/dev/null
fi

if [ -f $EMSDK/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten/pic/libffi.a ]
then
    echo "
        * ffi already built
    " 1>&2
else
    echo "
        * building libffi javascript port
    " 1>&2

    if [ -d src/libffi ]
    then
        echo    "
            using local sources
        "
    else
        pushd src 2>&1 >/dev/null
            # breaks with 3.1.46
            #git clone https://github.com/pmp-p/libffi-emscripten.git libffi

            # breaks with 3.1.46
            #git clone --no-tags --depth 1 --single-branch --branch master https://github.com/libffi/libffi
            #pushd libffi
                ./autogen.sh
            #popd
            wget https://github.com/libffi/libffi/releases/download/v3.4.8/libffi-3.4.8.tar.gz
            tar xvfz libffi-3.4.8.tar.gz && rm libffi-3.4.8.tar.gz
            mv libffi-*.*.* libffi
        popd
    fi

    mkdir -p build/libffi $PREFIX
    pushd build/libffi

#TODO: check if export PATH=${HOST_PREFIX}/bin:$PATH is really set to avoid system python with different bytecode
#and no loder lib-dynload in the way.



    CC=${SDKROOT}/emsdk/upstream/emscripten/emcc \
     emconfigure $ROOT/src/libffi/configure --host=wasm32-bi-emscripten \
      --prefix=$PREFIX --enable-static --disable-shared --disable-dependency-tracking\
      --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs

    emmake make install

    unset EMCC_CFLAGS
    popd

    cp -fv  ${PREFIX}/lib/libffi.a $EMSDK/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten/pic/
    cp -vf  ${PREFIX}/include/ffi*.h ${EMSDK}/upstream/emscripten/cache/sysroot/include/

    ffipc=${SDKROOT}/emsdk/upstream/emscripten/system/lib/pkgconfig/libffi.pc
    cat > $ffipc <<END
prefix=${SDKROOT}/emsdk/upstream/emscripten/cache/sysroot
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib/wasm32-emscripten/pic
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: libffi
Description: Library supporting Foreign Function Interfaces
Version: 3.4.2
Libs: -L\${toolexeclibdir} -lffi
Cflags: -I\${includedir}
END
    chmod +x $ffipc

echo "

    *************************************************************************
    *************************************************************************

"
fi

# in this special case build testsuite
# main repo https://github.com/pmp-p/python-wasm-test

# pygame-web won't build test modules

if echo $GITHUB_WORKSPACE|grep -q /python-wasm-test/
then
    TESTSUITE="--enable-test-modules"
    #TESTSUITE=""
else
    TESTSUITE=""
fi

echo "



    ********** TESTSUITE test-modules == $TESTSUITE *******************




" 1>&2



if [ -f ${SDKROOT}/build/cpython-wasm/libpython${PYBUILD}.a ]
then
    echo "
        * not rebuilding cpython-wasm for [$PYDK_PYTHON_HOST_PLATFORM]
    " 1>&2
else
    echo "
        * rebuilding build/cpython-wasm for [$PYDK_PYTHON_HOST_PLATFORM]
            PYTHON_FOR_BUILD=${PYTHON_FOR_BUILD}
    " 1>&2


    mkdir -p build/cpython-wasm $PREFIX
    pushd build/cpython-wasm

#     --with-tzpath="/usr/share/zoneinfo" \

    export EMCC_CFLAGS="-D_XOPEN_SOURCE_EXTENDED=1 -I$PREFIX/include/ncursesw -sUSE_ZLIB -sUSE_BZIP2"

    CPPFLAGS="$CPPFLAGS -I$PREFIX/include/ncursesw"
    CFLAGS="$CPPFLAGS -I$PREFIX/include/ncursesw"

# CFLAGS="-DHAVE_FFI_PREP_CIF_VAR=1 -DHAVE_FFI_PREP_CLOSURE_LOC=1 -DHAVE_FFI_CLOSURE_ALLOC=1"

    cat $ROOT/src/cpython${PYBUILD}/Tools/wasm/config.site-wasm32-emscripten \
         > $ROOT/src/cpython${PYBUILD}/Tools/wasm/config.site-wasm32-pydk

    cat >> $ROOT/src/cpython${PYBUILD}/Tools/wasm/config.site-wasm32-pydk << END

ac_cv_exeext=.cjs
have_libffi=yes
ac_cv_func_dlopen=yes
ac_cv_lib_ffi_ffi_call=yes
py_cv_module__ctypes=yes
py_cv_module__ctypes_test=yes
ax_cv_c_float_words_bigendian=no
ac_cv_func_sem_clockwait=no
END



#_ctypes _ctypes/_ctypes.c _ctypes/callbacks.c _ctypes/callproc.c _ctypes/stgdict.c _ctypes/cfield.c -ldl -lffi -DHAVE_FFI_PREP_CIF_VAR -DHAVE_FFI_PREP_CLOSURE_LOC -DHAVE_FFI_CLOSURE_ALLOC


#*shared*
#_ctypes_test _ctypes/_ctypes_test.c
#_testcapi _testcapimodule.c
#_testimportmultiple _testimportmultiple.c
#_testmultiphase _testmultiphase.c




# OPT="$CPOPTS -DNDEBUG -fwrapv" \
#      --with-c-locale-coercion --without-pydebug --without-pymalloc --disable-ipv6  \

#     --with-libs='-lz -lffi' \

    pushd $ROOT/src/cpython${PYBUILD}
    # fix double linking
    # sed -i 's|   -lcrypto||g' Makefile.pre.in

# REALLY FIXME: appeared only after 3.1.49bi
    sed -i 's|#error|//#error|g' $ROOT/src/cpython${PYBUILD}/Include/pyport.h

    # please let compiler/user decide what to do with wasm CPU.
    sed -i 's|-sWASM_BIGINT||g' configure
    sed -i 's|-sWASM_BIGINT||g' configure.ac


    if [ ${PYMINOR} -ge 13 ]
    then
        sed -i 's|{ABIFLAGS}t|{ABIFLAGS}|g' configure
        sed -i 's|{ABIFLAGS}t|{ABIFLAGS}|g' configure.ac
        sed -i 's|--wasi preview2||g' configure
        sed -i 's|--wasi preview2||g' configure.ac
        EXTRA="--without-pydebug --without-trace-refs --without-dsymutil --without-pymalloc --without-strict-overflow"
    fi

    if [ ${PYMINOR} -ge 14 ]
    then
        sed -i 's|wasm32-unknown-emscripten|wasm32-bi-emscripten|g' Makefile.pre.in
    fi


    popd

    chmod +x ${SDKROOT}/emsdk-cc

    export PYDK_CC=true
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" CONFIG_SITE=$ROOT/src/cpython${PYBUILD}/Tools/wasm/config.site-wasm32-pydk \
     emconfigure $ROOT/src/cpython${PYBUILD}/configure -C --with-emscripten-target=browser $GIL \
     --cache-file=${PYTHONPYCACHEPREFIX}/config.cache \
     --enable-wasm-dynamic-linking $TESTSUITE\
     --host=$PYDK_PYTHON_HOST_PLATFORM \
     --build=$($ROOT/src/cpython${PYBUILD}/config.guess) \
     --prefix=$PREFIX \
     --with-build-python=${PYTHON_FOR_BUILD} \
     ${EXTRA_PYOPTS}

    mkdir -p ${PYTHONPYCACHEPREFIX}/empty
    touch ${PYTHONPYCACHEPREFIX}/empty/$($HPY -V|cut -f2 -d' ')

    #echo "#define HAVE_NCURSES_H" >> pyconfig.h

    # prevent an error in install when byte compiling is disabled.
    mkdir -p ${ROOT}/devices/emsdk/usr/lib/python${PYMAJOR}.${PYMINOR}/lib-dynload/__pycache__


    sed -i 's|-lpthread|-lcrypto|g' Makefile


    echo "=========== cpython build ================" 1>&2
    if  emmake make -j$(nproc) WASM_ASSETS_DIR=$(realpath ${PYTHONPYCACHEPREFIX}/empty)@/
    then
        echo -n
    else
        echo "

     **** cpython wasm build failed ***

    emmake make WASM_ASSETS_DIR=$(realpath ${PYTHONPYCACHEPREFIX}/empty)@/

        " 1>&2
        exit 244
    fi
    #emmake make -j1 Modules/_ctypes/_ctypes.o

    echo "=========== cpython install ================" 1>&2
    if emmake make WASM_ASSETS_DIR=$(realpath ${PYTHONPYCACHEPREFIX}/empty)@/ install
    then
        echo "ok"
        #cp -rf ${PREFIX}/usr/lib/python${PYMAJOR}.${PYMINOR}/* ${ROOT}/devices/$(arch)/usr/lib/python${PYMAJOR}.${PYMINOR}/
        #rm -rf ${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}
        #ln -sf ${ROOT}/devices/$(arch)/usr/lib/python${PYMAJOR}.${PYMINOR} ${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}
    else
        echo "

     **** cpython wasm install failed ***

    emmake make WASM_ASSETS_DIR=$(realpath ${PYTHONPYCACHEPREFIX}/empty)@/ install

        " 1>&2
        exit 263

    fi


    if pushd ${SDKROOT}/build/cpython-wasm
    then
        if echo $PYBUILD|grep -q 11$
        then
            mkdir -p ${SDKROOT}/prebuilt/emsdk
            OBJDIR=$(echo -n build/temp.emscripten-wasm32-${PYBUILD}/opt/python-wasm-sdk/src/Python-3.*)
            OBJS="${OBJDIR}/Modules/_ctypes/_ctypes.o \
             ${OBJDIR}/Modules/_ctypes/callbacks.o \
             ${OBJDIR}/Modules/_ctypes/callproc.o \
             ${OBJDIR}/Modules/_ctypes/cfield.o \
             ${OBJDIR}/Modules/_ctypes/stgdict.o"
        else
        # 3.12+
            OBJS=$(find $(pwd)/Modules/_ctypes|grep o$)
        fi

        $SDKROOT/emsdk/upstream/emscripten/emar rcs ${SDKROOT}/prebuilt/emsdk/lib_ctypes${PYBUILD}.a $OBJS
        popd
    fi


    rm -rf $(find $ROOT/devices/ -type d|grep /__pycache__$)

    popd

    mkdir -p ${SDKROOT}/prebuilt/emsdk/${PYBUILD}/site-packages
    mkdir -p ${SDKROOT}/prebuilt/emsdk/${PYBUILD}/lib-dynload

    if [ -d $PREFIX/lib/python${PYBUILD}/lib-dynload ]
    then
        # move them to MEMFS
        mv $PREFIX/lib/python${PYBUILD}/lib-dynload/* ${SDKROOT}/prebuilt/${TARGET}/${PYBUILD}/lib-dynload/

        echo "         =============== FIXME: _ctype dynamic build ==============="
        rm ${SDKROOT}/prebuilt/emsdk/${PYBUILD}/lib-dynload/_ctypes.*
        rm ${SDKROOT}/prebuilt/emsdk/${PYBUILD}/lib-dynload/xxlimited*

        # specific platform support
        cp -Rfv $ROOT/support/__EMSCRIPTEN__.patches/${PYBUILD}/. $PREFIX/lib/python${PYBUILD}/

        cp -vf build/cpython-wasm/libpython${PYBUILD}.a prebuilt/emsdk/
        for lib in $(find build/cpython-wasm/|grep -v /libpython3|grep lib.*.a$)
        do
            name=$(basename $lib .a)
            cp $lib prebuilt/emsdk/${name}${PYBUILD}.a
        done
        rmdir  $PREFIX/lib/python${PYBUILD}/lib-dynload
    fi
fi

unset PYDK_CC

# FIXME: seems CI cannot locate that one with python3-wasm

MODSYSCONFIG="${SDKROOT}/prebuilt/emsdk/${PYBUILD}/_sysconfigdata__emscripten_debug.py"

cp $PREFIX/lib/python${PYBUILD}/_sysconfigdata__emscripten_wasm32-emscripten.py \
 ${MODSYSCONFIG}

sed -i 's|-Os|-O0|g' ${MODSYSCONFIG}
sed -i 's|-g0|-g3|g' ${MODSYSCONFIG}

# this one is required for `python3-wasm -mbuild` venv
ln ${MODSYSCONFIG} ${SDKROOT}/devices/$(arch)/usr/lib/python${PYBUILD}/
ln ${MODSYSCONFIG} ${SDKROOT}/devices/${TARGET}/usr/lib/python${PYBUILD}/

cat > ${PYTHONPYCACHEPREFIX}/.nanorc <<END
set tabsize 4
set tabstospaces
END

cat >${PYTHONPYCACHEPREFIX}/.numpy-site.cfg <<NUMPY
[DEFAULT]
library_dirs = $PREFIX/lib
include_dirs = $PREFIX/include
NUMPY





. scripts/make-shells.sh

# C/C++/cmake shell

cat >> $ROOT/${PYDK_PYTHON_HOST_PLATFORM}-shell.sh <<END

export PS1="[PyDK:emsdk] \w $ "

export PYTHONSTARTUP="${SDKROOT}/support/__EMSCRIPTEN__.py"
> \${HOME}/.pythonrc.py

export EMSDK_QUIET=1
export EM_IGNORE_SANITY=1
export EMCC_SKIP_SANITY_CHECK=1

if [[ ! -z \${EMSDK+z} ]]
then
    # emsdk_env already parsed
    echo -n
else
    pushd ${SDKROOT}
    . config
    . emsdk/emsdk_env.sh
    popd
    export PATH=$SDKROOT/${TARGET}/upstream/emscripten:$SDKROOT/${TARGET}/upstream/emscripten/system/bin:\$PATH
    # export PKG_CONFIG_SYSROOT_DIR="${SDKROOT}/devices/emsdk"
    export PKG_CONFIG_LIBDIR="${SDKROOT}/emsdk/upstream/emscripten/system/lib/pkgconfig"
    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${HOST_PREFIX}/lib/pkgconfig"
    export NODE=\$(find \$EMSDK|grep /bin/node\$)
fi

export SYS_PYTHON=${SYS_PYTHON}
export EMSDK_PYTHON=${SYS_PYTHON}
export _PYTHON_SYSCONFIGDATA_NAME=\${_PYTHON_SYSCONFIGDATA_NAME:-_sysconfigdata__emscripten_debug}

END


# python shell
cat > $HOST_PREFIX/bin/python3-wasm <<END
#!/bin/bash

. ${SDKROOT}/${PYDK_PYTHON_HOST_PLATFORM}-shell.sh

# most important
export CC=emcc
export _PYTHON_SYSCONFIGDATA_NAME=\${_PYTHON_SYSCONFIGDATA_NAME:-_sysconfigdata__emscripten_debug}

# reserved for interactive python testing of modules.
export PYTHONSTARTUP=$ROOT/support/__EMSCRIPTEN__.py

# so include dirs are good
export PYTHONHOME=$PREFIX

# find sysconfig ( tweaked )
# but still can load dynload and setuptools

PYTHONPATH=${HOST_PREFIX}/lib/python\${PYBUILD}/site-packages:\$PYTHONPATH
export PYTHONPATH=${SDKROOT}/prebuilt/${TARGET}/\${PYBUILD}:${HOST_PREFIX}/lib/python\${PYBUILD}/lib-dynload:\$PYTHONPATH

export _PYTHON_HOST_PLATFORM=${PYDK_PYTHON_HOST_PLATFORM}
export PYTHON_FOR_BUILD=${HOST_PREFIX}/bin/python\${PYBUILD}

\${PYTHON_FOR_BUILD} -u -B "\$@"
END

chmod +x $HOST_PREFIX/bin/python3-wasm


cp -f $HOST_PREFIX/bin/python3-wasm ${SDKROOT}/

unset PYTHON_FOR_BUILD
unset EMCC_CFLAGS
