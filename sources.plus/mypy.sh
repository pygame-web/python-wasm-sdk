#!/bin/bash

. ${CONFIG:-config}

if [ -d src/mypy ]
then
    pushd src/mypy
    git pull
else
    pushd src
    git clone --no-tags --depth 1 --single-branch --branch master https://github.com/python/mypy
fi
popd


pushd src/mypy
if ${SDKROOT}/python3-wasm -m build .
then
    ${SDKROOT}/python3-wasm -m pip install dist/mypy-*.whl
else
    echo failed to build mypyc wheel
    exit 21
fi
popd

