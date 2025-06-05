#!/bin/bash

if [[ -z ${EMSDK+z} ]]
then
    pushd ${SDKROOT:-/opt/python-wasm-sdk}

    . ${CONFIG:-config}

    # for full rebuild
    # rm emsdk/.complete

    if [ -d emsdk ]
    then
        echo "
        * using emsdk from $(realpath emsdk)
            with sys python $SYS_PYTHON
" 1>&2
    else
        git clone --no-tags --depth 1 --single-branch --branch main https://github.com/emscripten-core/emsdk.git
        pushd emsdk
            ./emsdk install ${EMFLAVOUR:-latest}
            ./emsdk activate ${EMFLAVOUR:-latest}
        popd
    fi


    if [ -f emsdk/.complete ]
    then
        echo " * found emsdk/.complete : not patching/building emsdk"
    else
        pushd emsdk
            pushd upstream/emscripten
            patch -p1 << END
diff --git a/src/lib/libbrowser.js b/src/lib/libbrowser.js
index 548506f..9c3d9b1 100644
--- a/src/lib/libbrowser.js
+++ b/src/lib/libbrowser.js
@@ -604,7 +604,8 @@ var LibraryBrowser = {
       PATH.basename(_file),
       // TODO: This copy is not needed if the contents are already a Uint8Array,
       //       which they often are (and always are in WasmFS).
-      new Uint8Array(data.object.contents), true, true,
+      // new Uint8Array(data.object.contents), true, true,
+      FS.readFile(_file), true, true,
       () => {
         {{{ runtimeKeepalivePop() }}}
         if (onload) {{{ makeDynCall('vp', 'onload') }}}(file);
diff --git a/src/lib/libdylink.js b/src/lib/libdylink.js
index 44e349d..b97edac 100644
--- a/src/lib/libdylink.js
+++ b/src/lib/libdylink.js
@@ -828,7 +828,7 @@ var LibraryDylink = {
             cSig = cSig.split(',');
             for (var i in cSig) {
               var jsArg = cSig[i].split(' ').pop();
-              jsArgs.push(jsArg.replace('*', ''));
+              jsArgs.push(jsArg.replaceAll('*', ''));
             }
           }
           var func = `(\${jsArgs}) => \${body};`;
END

            popd # upstream/emscripten
        popd # emsdk
    fi # emsdk/.complete

    export EMSDK_PYTHON=$SYS_PYTHON

    if [ -f ${SDKROOT}/emsdk/emsdk_env.sh ]
    then
        echo "
        * activating emsdk via emsdk_env.sh with EMSDK_PYTHON=$EMSDK_PYTHON
" 1>&2
        . ${SDKROOT}/emsdk/emsdk_env.sh

    else
        echo "
        ERROR cannot find emsdk/emsdk_env.sh in $(pwd)
" 1>&2
        exit 41
    fi

    # EMSDK_PYTHON may have been cleared, restore it
    export EMSDK_PYTHON=$SYS_PYTHON

    if [ -f emsdk/.complete ]
    then
        echo "
        * emsdk third parties ok
    "  1>&2
    else
        # sdl2_image is too old
        ALL="libembind libgl libal libhtml5 libstubs libnoexit libsockets"
        ALL="$ALL libc libdlmalloc libcompiler_rt libc++-noexcept libc++abi-noexcept"
        ALL="$ALL libfetch zlib bzip2 libpng libjpeg freetype harfbuzz"
        ALL="$ALL sqlite3 vorbis ogg"

        if echo $EMFLAVOUR|grep -q tot
        then
            SDL3=true
            echo "
    * using SDL3
"
        else
            SDL3=false
            echo "
    * using SDL2
"
            ALL="$ALL sdl2 sdl2_mixer sdl2_gfx sdl2_ttf"
        fi

        echo "
        * building third parties libraries for emsdk ( can take time ... )
    "  1>&2

        for one in $ALL
        do
            echo "
            + $done
    "  1>&2
            embuilder build $one
            embuilder --pic build $one
        done


        if $SDL3
        then
#=============================================================================================================================
            ./scripts/emsdk-fetch-sdl3.sh
#=============================================================================================================================
        else
#=============================================================================================================================
            ./scripts/emsdk-fetch-sdl2.sh
#=============================================================================================================================
        fi # SDL3


       echo "
        * building third parties done, mark is emsdk/.complete )
    "  1>&2


        export PATH=$(echo -n ${SDKROOT}/emsdk/node/??.??.*/bin):$PATH

        cat > emsdk/upstream/emscripten/emcc <<END
#!/bin/bash

EMCC_TRACE=\${EMCC_TRACE:-false}
if \$EMCC_TRACE
then
    echo "
\$0 \$@" >> $SDKROOT/emcc.log
fi

unset _EMCC_CCACHE
unset _PYTHON_SYSCONFIGDATA_NAME
unset PYTHONHOME
unset PYTHONPATH

$SYS_PYTHON -E $SDKROOT/emsdk-cc \$0.py "\$@"
exit \$?
END

        rm emsdk/upstream/emscripten/em++
        if ln emsdk/upstream/emscripten/emcc emsdk/upstream/emscripten/em++
        then
            # cmake usually wants cc
            ln emsdk/upstream/emscripten/emcc emsdk/upstream/emscripten/cc
            ln emsdk/upstream/emscripten/emcc.py emsdk/upstream/emscripten/cc.py
        else
            echo "

             ============ hard link not supported ==============


            "
            cat emsdk/upstream/emscripten/emcc > emsdk/upstream/emscripten/em++
            cat emsdk/upstream/emscripten/emcc > emsdk/upstream/emscripten/cc
            cat emsdk/upstream/emscripten/emcc.py > emsdk/upstream/emscripten/cc.py
        fi

        cat > emsdk/upstream/emscripten/emar <<END
#!/bin/bash

unset _PYTHON_SYSCONFIGDATA_NAME
unset PYTHONHOME
unset PYTHONPATH

$SYS_PYTHON -E \$0.py "\$@"
END

        cat emsdk/upstream/emscripten/emar > emsdk/upstream/emscripten/emcmake

        cat > emsdk/upstream/emscripten/emconfigure <<END
#!/bin/bash
$SYS_PYTHON -E \$0.py "\$@"
END

        chmod +x emsdk/upstream/emscripten/em*
        touch emsdk/.complete
    fi

    # EM_PKG_CONFIG_PATH ?
    # https://emscripten.org/docs/compiling/Building-Projects.html#pkg-config

    # export PKG_CONFIG_SYSROOT_DIR="${SDKROOT}/devices/emsdk"
    export PKG_CONFIG_LIBDIR="${SDKROOT}/emsdk/upstream/emscripten/system/lib/pkgconfig"
    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${HOST_PREFIX}/lib/pkgconfig"
    export EM_PKG_CONFIG_PATH=$PKG_CONFIG_PATH

    if echo $PATH|grep -q $EMSDK/upstream/emscripten/system/bin
    then
        # emsdk env does not set it, but it's required for eg sdl2-config
        echo -n
    else
        export PATH=$(echo -n ${EMSDK}/node/??.??.*/bin):$EMSDK/upstream/emscripten/system/bin:$EMSDK/upstream/emscripten:$PATH
    fi

    echo "
    * installing wasm-objdump (wasi)
"
    mkdir -p ${SDKROOT}/devices/$(arch)/usr/bin/
    cp $SDKROOT/wasisdk/bin/wasm-objdump* ${SDKROOT}/devices/$(arch)/usr/bin/




    TRUE=$(which true)
    echo "
    * pointing readelf and ldconfig to ${TRUE}
"
    for fix in readelf ldconfig
    do
        FIXED=$EMSDK/upstream/emscripten/system/bin/$fix
        [ -f $FIXED ] || cp $TRUE $FIXED
    done



    # emsdk shipped node cannot run on alpine
    export SYS_NODE=$(echo -n $SDKROOT/emsdk/node/??.??.*/bin/node)
    if [ -f /alpine ]
    then
        if [ -f $SYS_NODE.glibc ]
        then
            echo "node alpine node version already selected"
        else
            mv $SYS_NODE $SYS_NODE.glibc
            cp -vf /usr/bin/node $SYS_NODE
        fi
    fi

    export NPROC=1
    export EMSDK_NUM_CORES=$NPROC

    mkdir -p src
    export SYSROOT=$EMSDK/upstream/emscripten/cache/sysroot
    popd  # ${SDKROOT:-/opt/python-wasm-sdk}

    echo "
    will use node = $SYS_NODE
    sysroot = $SYSROOT
"
else
    echo "emsdk: already fetched and config set !" 1>&2
fi

