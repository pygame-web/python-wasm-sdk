##!/bin/bash

. ${CONFIG:-config}

echo "
    *   cpython-fetch $PYBUILD  *
"

mkdir -p src

pushd src

NOPATCH=false
PYPATCH=true

[ -L cpython${PYBUILD} ] && rm cpython${PYBUILD}

[ -f $HPY ] || REBUILD=true


if echo $PYBUILD |grep -q 15$
then
    if [ -d cpython${PYBUILD} ]
    then
        pushd cpython${PYBUILD}
        # put the tree back to original state so we can pull
        # Programs/python.c Modules/readline.c
        git restore .

        if git pull|grep -q 'Already up to date'
        then
            export REBUILD=${REBUILD:-false}
        else
            export REBUILD=true
        fi
        #not here or pip won't install properly anymore its wheels
        #cat $ROOT/support/compilenone.py > ./Lib/compileall.py
        popd
    else
        git clone --no-tags --depth 1 --single-branch --branch main https://github.com/python/cpython.git cpython${PYBUILD}
        export REBUILD=true
    fi
fi

if echo $PYBUILD |grep -q 14$
then
    wget -c https://www.python.org/ftp/python/3.14.0/Python-3.14.0rc1.tar.xz
    tar xf Python-3.14.0rc1.tar.xz
    ln -s Python-3.14.0rc1 cpython${PYBUILD}


    mkdir $SDKROOT/devices/emsdk/usr/lib $SDKROOT/devices/$(arch)/usr/lib -p

    if ${Py_GIL_DISABLED:-false}
    then
        ln -s $SDKROOT/devices/$(arch)/usr/lib/python3.14t  $SDKROOT/devices/$(arch)/usr/lib/python3.14
        ln -s $SDKROOT/devices/emsdk/usr/lib/python3.14t  $SDKROOT/devices/emsdk/usr/lib/python3.14
    fi

    pushd cpython${PYBUILD}


        patch -p1 <<END

--- Python-3.14.0rc1/Python/emscripten_syscalls.c
+++ Python-3.14.0rc1-mvpbi/Python/emscripten_syscalls.c
@@ -139,7 +139,7 @@
                "Unexpected __wasi_iovec_t layout");
 _Static_assert(sizeof(__wasi_iovec_t) == IOVEC_T_SIZE,
                "Unexpected __wasi_iovec_t layout");
-
+#ifdef __wasm_reference_types__
 // If the stream has a readAsync handler, read to buffer defined in iovs, write
 // number of bytes read to *nread, and return a promise that resolves to the
 // errno. Otherwise, return null.
@@ -285,7 +285,7 @@
     }
     return __block_for_int(p);
 }
-
+#endif // __wasm_reference_types__
 #include <sys/ioctl.h>

 int syscall_ioctl_orig(int fd, int request, void* varargs)
END

        patch -p1 <<END
--- Python-3.14.0rc1/Modules/_hacl/include/krml/lowstar_endianness.h
+++ Python-3.14.0rc1-mvpbi/Modules/_hacl/include/krml/lowstar_endianness.h
@@ -12,7 +12,7 @@
 /******************************************************************************/

 /* ... for Linux */
-#if defined(__linux__) || defined(__CYGWIN__) || defined (__USE_SYSTEM_ENDIAN_H__) || defined(__GLIBC__)
+#if defined(__linux__) || defined(__CYGWIN__) || defined (__USE_SYSTEM_ENDIAN_H__) || defined(__GLIBC__) || defined(__EMSCRIPTEN__)
 #  include <endian.h>

 /* ... for OSX */
END
        patch -p1 <<END
--- Python-3.14.0rc1/Modules/_hacl/libintvector.h
+++ Python-3.14.0rc1-mvpbi/Modules/_hacl/libintvector.h
@@ -21,13 +21,28 @@

 #define Lib_IntVector_Intrinsics_bit_mask64(x) -((x) & 1)

-#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
+#if defined(__wasm__) && !defined(__wasm_simd128__)
+    #define SIMDE_ENABLE_NATIVE_ALIASES
+    #define SIMDE_NO_NATIVE
+//    typedef void* Lib_IntVector_Intrinsics_vec128;
+    #define WASM_SIMD
+#endif
+
+#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86) || defined(WASM_SIMD)

 #if defined(HACL_CAN_COMPILE_VEC128)

+#if !defined(WASM_SIMD)
 #include <emmintrin.h>
 #include <tmmintrin.h>
 #include <smmintrin.h>
+#else
+    #warning "Modules/_hacl: using SIMDE emulation for wasm"
+//    #include <simde/wasm/simd128.h>
+    #include <simde/x86/sse4.1.h>
+    #include <simde/x86/sse4.2.h>
+#endif
+

 typedef __m128i Lib_IntVector_Intrinsics_vec128;

END


        patch -p1 <<END
--- Python-3.13.0rc3/Objects/moduleobject.c	2024-10-01 04:03:08.000000000 +0200
+++ Python-3.13.0rc3.wasm/Objects/moduleobject.c	2024-10-02 13:16:33.030387509 +0200
@@ -442,8 +442,8 @@
 PyUnstable_Module_SetGIL(PyObject *module, void *gil)
 {
     if (!PyModule_Check(module)) {
-        PyErr_BadInternalCall();
-        return -1;
+        //PyErr_BadInternalCall();
+        return 0;
     }
     ((PyModuleObject *)module)->md_gil = gil;
     return 0;
END









    popd

fi

if echo $PYBUILD |grep -q 13$
then
    if [ -f cpython${PYBUILD}/configure ]
    then
        echo "  * Using local cpython sources"
    else
        pwd
        ls
        echo "  * fetching remote cpython sources"
        wget -q -c  https://www.python.org/ftp/python/3.13.5/Python-3.13.5.tar.xz
        tar xf Python-3.13.5.tar.xz || exit 90
        ln -s Python-3.13.5 cpython${PYBUILD}


        sed -i 's|ProcessPoolExecutor = None|return True|g' cpython3.13/Lib/compileall.py

        mkdir $SDKROOT/devices/emsdk/usr/lib $SDKROOT/devices/$(arch)/usr/lib -p

        if ${Py_GIL_DISABLED:-false}
        then
            ln -s $SDKROOT/devices/$(arch)/usr/lib/python3.13t  $SDKROOT/devices/$(arch)/usr/lib/python3.13
            ln -s $SDKROOT/devices/emsdk/usr/lib/python3.13t  $SDKROOT/devices/emsdk/usr/lib/python3.13
        fi

        pushd cpython${PYBUILD}

            # gh-135621: Remove dependency on curses from PyREPL #136758
            wget --no-check-certificate https://pmp-p.ddns.net/py/patches/3.13/136758.diff
            patch -p1 < 136758.diff
            patch -p1 <<END
--- Python-3.13.0rc3/Objects/moduleobject.c	2024-10-01 04:03:08.000000000 +0200
+++ Python-3.13.0rc3.wasm/Objects/moduleobject.c	2024-10-02 13:16:33.030387509 +0200
@@ -442,8 +442,8 @@
 PyUnstable_Module_SetGIL(PyObject *module, void *gil)
 {
     if (!PyModule_Check(module)) {
-        PyErr_BadInternalCall();
-        return -1;
+        //PyErr_BadInternalCall();
+        return 0;
     }
     ((PyModuleObject *)module)->md_gil = gil;
     return 0;
END

        popd

    fi
fi

if echo $PYBUILD |grep -q 12$
then
    wget -q -c https://www.python.org/ftp/python/3.12.11/Python-3.12.11.tar.xz
    tar xf Python-3.12.11.tar.xz
    ln -s Python-3.12.11 cpython${PYBUILD}
fi


if echo $PYBUILD | grep -q 11$
then
#    wget -q -c https://www.python.org/ftp/python/3.11.12/Python-3.11.12.tar.xz
#    tar xf Python-3.11.12.tar.xz
#    ln -s Python-3.11.12 cpython${PYBUILD}
    wget -q -c https://www.python.org/ftp/python/3.11.13/Python-3.11.13.tar.xz
    tar xf Python-3.11.13.tar.xz
    ln -s Python-3.11.13 cpython${PYBUILD}
fi

popd


# 3.10 is not wasm stable
if [ -f support/__EMSCRIPTEN__.patches/${PYBUILD}-host.diff ]
then
    pushd src/cpython${PYBUILD}
        patch -p1 < ../../support/__EMSCRIPTEN__.patches/${PYBUILD}-host.diff
    popd
fi


# the sys._emscripten_info is actually not compatible with shared build
# because it uses javascript inlines
# just move that part to main

if $NOPATCH
then
    echo "finally there"
else
    pushd src/cpython${PYBUILD}

    # do some patching for 3.11+ to allow shared libs and move js to pymain
    patch -p1 < ../../support/__EMSCRIPTEN__.embed/cpython${PYBUILD}.diff

    # patch host to be PIC
    patch -p1 < ../../support/hostpic.diff

    popd
fi

echo "
    * fetched cpython source, status is :
        REBUILD=${REBUILD}
"

[ -d build/cpython-host ] && rm -rf build/cpython-host
[ -d build/cpython-wasm ] && rm -rf build/cpython-wasm
