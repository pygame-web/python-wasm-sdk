#!/bin/bash

. ${CONFIG:-config}

mkdir -p src build

for pkg in $ROOT/sources.extra/*.sh
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
        exit 54
    fi
done


# those depend on nanoX/microwindows compiled above
if [ -d $ROOT/sources.extra/x11 ]
then
    for pkg in $ROOT/sources.extra/x11/*.sh
    do
        cd $ROOT
        chmod +x $pkg
        echo "

        Third party (X11) : $pkg


    "
        $pkg
    done
fi


