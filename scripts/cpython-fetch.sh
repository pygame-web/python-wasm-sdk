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

    wget -c https://www.python.org/ftp/python/3.14.0/Python-3.14.0b3.tar.xz
    tar xf Python-3.14.0b3.tar.xz
    ln -s Python-3.14.0b3 cpython${PYBUILD}

    mkdir $SDKROOT/devices/emsdk/usr/lib $SDKROOT/devices/$(arch)/usr/lib -p

    if ${Py_GIL_DISABLED:-false}
    then
        ln -s $SDKROOT/devices/$(arch)/usr/lib/python3.14t  $SDKROOT/devices/$(arch)/usr/lib/python3.14
        ln -s $SDKROOT/devices/emsdk/usr/lib/python3.14t  $SDKROOT/devices/emsdk/usr/lib/python3.14
    fi

    pushd cpython${PYBUILD}
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
