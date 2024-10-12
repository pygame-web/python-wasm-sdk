#!/bin/bash

. ${CONFIG:-config}


# cmake for assimp build
$HPIP install --upgrade cmake


for pkg in $ROOT/sources.wasm/*.sh
do
    cd $ROOT
    chmod +x $pkg
    echo "

    Third party : $pkg


"
    if $pkg
    then
        echo "$pkg : done"
    else
        echo "

Failed to build extra $pkg

"
        exit 29
    fi
done

if ${EXTRA:-false}
then
    . scripts/emsdk-extra.sh
fi

cd $ROOT



