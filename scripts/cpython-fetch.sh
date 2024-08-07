##!/bin/bash

. ${CONFIG:-config}

echo "
    *   cpython-fetch $PYBUILD  *
"

mkdir -p src

pushd src 2>&1 >/dev/null

NOPATCH=false
PYPATCH=true

[ -L cpython${PYBUILD} ] && rm cpython${PYBUILD}

[ -f $HPY ] || REBUILD=true


if echo $PYBUILD |grep -q 14$
then
    if [ -d cpython${PYBUILD} ]
    then
        pushd cpython${PYBUILD} 2>&1 >/dev/null
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


if echo $PYBUILD |grep -q 13$
then
#    wget -q -c https://www.python.org/ftp/python/3.13.0/Python-3.13.0b4.tar.xz
#    tar xf Python-3.13.0b4.tar.xz
#    ln -s Python-3.13.0b4 cpython${PYBUILD}
    wget -q -c https://www.python.org/ftp/python/3.13.0/Python-3.13.0rc1.tar.xz
    tar xf Python-3.13.0rc1.tar.xz
    ln -s Python-3.13.0rc1 cpython${PYBUILD}

    mkdir $ROOT/devices/emsdk/usr/lib $ROOT/devices/$(arch)/usr/lib -p
    ln -s $ROOT/devices/$(arch)/usr/lib/python3.13t  $ROOT/devices/$(arch)/usr/lib/python3.13
    ln -s $ROOT/devices/emsdk/usr/lib/python3.13t  $ROOT/devices/emsdk/usr/lib/python3.13
    pushd cpython${PYBUILD}

    popd

fi

if echo $PYBUILD |grep -q 12$
then
    wget -q -c https://www.python.org/ftp/python/3.12.5/Python-3.12.5.tar.xz
    tar xf Python-3.12.5.tar.xz
    ln -s Python-3.12.5 cpython${PYBUILD}
fi


if echo $PYBUILD | grep -q 11$
then
    wget -q -c https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tar.xz
    tar xf Python-3.11.9.tar.xz
    ln -s Python-3.11.9 cpython${PYBUILD}
fi

popd


# 3.10 is not wasm stable
if [ -f support/__EMSCRIPTEN__.patches/${PYBUILD}-host.diff ]
then
    pushd src/cpython${PYBUILD} 2>&1 >/dev/null
    patch -p1 < ../../support/__EMSCRIPTEN__.patches/${PYBUILD}-host.diff
    popd 2>&1 >/dev/null
fi


# the sys._emscripten_info is actually not compatible with shared build
# because it uses javascript inlines
# just move that part to main

if $NOPATCH
then
    echo "finally there"
else
    # do some patching for 3.11+ to allow more shared libs
    pushd src/cpython${PYBUILD} 2>&1 >/dev/null
    patch -p1 < ../../support/__EMSCRIPTEN__.embed/cpython${PYBUILD}.diff
    popd 2>&1 >/dev/null
fi

echo "
    * fetched cpython source, status is :
        REBUILD=${REBUILD}
"

[ -d build/cpython-host ] && rm -rf build/cpython-host
[ -d build/cpython-wasm ] && rm -rf build/cpython-wasm
