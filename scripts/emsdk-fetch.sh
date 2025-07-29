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

    export SYSROOT=${SDKROOT}/emsdk/upstream/emscripten/cache/sysroot

    if [ -f emsdk/.complete ]
    then
        echo " * found emsdk/.complete : not patching/building emsdk"
    else
        pushd emsdk
            if grep -q __emscripten_tempret_get upstream/emscripten/src/library_dylink.js
            then
                echo -n
            else

                # including
                # https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes/emscripten_emscripten-wasm32/patches/0001-Add-useful-error-when-symbol-resolution-fails.patch
                patch -p1 <<END
--- emsdk/upstream/emscripten/src/library_dylink.js	2025-07-25 08:13:59.548799211 +0200
+++ emsdk.fix/upstream/emscripten/src/library_dylink.js	2025-07-25 08:11:56.611055127 +0200
@@ -723,6 +723,13 @@
             var resolved;
             stubs[prop] = (...args) => {
               resolved ||= resolveSymbol(prop);
+              if (!resolved) {
+                if (prop==='getTempRet0')
+                    return __emscripten_tempret_get(...args);
+                if (prop==='setTempRet0')
+                    return __emscripten_tempret_set(...args);
+                throw new Error(`Dynamic linking error: cannot resolve symbol ${prop}`);
+              }
               return resolved(...args);
             };
           }
END
            fi

    # this one for debug mode and changing  -Wl,--global-base= with -sGLOBAL_BASE
    patch -p1 <<END
--- emsdk/upstream/emscripten/tools/link.py	2025-06-23 08:45:26.554013381 +0200
+++ emsdk.fix/upstream/emscripten/tools/link.py	2025-06-23 08:45:31.445921560 +0200
@@ -1662,7 +1662,7 @@
     # use a smaller LEB encoding).
     # However, for debugability is better to have the stack come first
     # (because stack overflows will trap rather than corrupting data).
-    settings.STACK_FIRST = True
+    settings.STACK_FIRST = False

   if state.has_link_flag('--stack-first'):
     settings.STACK_FIRST = True
END


        pushd upstream/emscripten

            echo "FIXME: applying stdio* are not const"
            sed -i 's|extern FILE \*const|extern FILE \*|g' ${SYSROOT}/include/stdio.h

            echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/20281 dylink.js : handle ** argument case"
                patch -p1 <<END
diff --git a/src/library_dylink.js b/src/library_dylink.js
index 632e20aa61e3..ebb13995d6c3 100644
--- a/src/library_dylink.js
+++ b/src/library_dylink.js
@@ -803,7 +803,7 @@ var LibraryDylink = {
             cSig = cSig.split(',');
             for (var i in cSig) {
               var jsArg = cSig[i].split(' ').pop();
-              jsArgs.push(jsArg.replace('*', ''));
+              jsArgs.push(jsArg.replaceAll('*', ''));
             }
           }
           var func = `(\${jsArgs}) => \${body};`;
END

            echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/17956 file corruption when using emscripten_run_preload_plugins with BrowserFS"
            wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/17956.diff

            if patch -p1 < 17956.diff
            then
                echo applied https://github.com/emscripten-core/emscripten/pull/17956
                # 18941 has been merged
            else
                # deal with old version of emsdk for the above 3.1.45 patch
                sed -i 's|new Uint8Array(data.object.contents), true, true|FS.readFile(_file), true, true|g' src/library_browser.js
                # merged since 3.1.34 which quite the more stable atm
                #echo "MAYBE FIXME: Applying https://github.com/emscripten-core/emscripten/pull/18941"
                #wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/18941.diff
                #patch -p1 < 18941.diff
            fi

            echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/21472 glfw3: gl level version major/minor hints"
            wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/21472.diff
            patch -p1 < 21472.diff


            echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/20442 fix mouse position for 3D canvas"
            # wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/20442.diff
            # patch -p1 < 20442.diff
            wget https://patch-diff.githubusercontent.com/raw/pmp-p/emscripten/pull/2.diff
            patch -p1 < 2.diff

            echo "FIXME: Applying https://github.com/pmp-p/emscripten/pull/3 ioctl TIOCSWINSZ"
            wget  https://github.com/pmp-p/emscripten/pull/3.diff
            patch -p1 < 3.diff

            #echo "FIXME:  remove XHR for .data and use fetch" MERGED
            #wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/22016.diff
            #patch -p1 < 22016.diff

            #echo "FIXME: scriptDirectory workaround" MERGER
            #wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/22605.diff
            #patch -p1 < 22605.diff

        popd # emsdk/upstream/emscripten -> emsdk

#        wget https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_emcc.patch
#        patch -p1 < emsdk_emcc.patch





        # https://github.com/paradust7/minetest-wasm/blob/main/emsdk_dirperms.patch
        patch -p1 <<END
--- emsdk-orig/upstream/emscripten/system/lib/wasmfs/wasmfs.cpp	2022-07-29 17:22:28.000000000 +0000
+++ emsdk/upstream/emscripten/system/lib/wasmfs/wasmfs.cpp	2022-08-06 02:07:24.098196400 +0000
@@ -141,7 +141,7 @@
     }

     auto inserted =
-      lockedParentDir.insertDirectory(childName, S_IRUGO | S_IXUGO);
+      lockedParentDir.insertDirectory(childName, S_IRUGO | S_IWUGO | S_IXUGO);
     assert(inserted && "TODO: handle preload insertion errors");
   }
END

#                # https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_file_packager.patch
#                patch -p1 << END
#--- emsdk1/upstream/emscripten/tools/file_packager.py	2022-03-24 19:45:39.000000000 +0000
#+++ emsdk2/upstream/emscripten/tools/file_packager.py	2022-03-22 10:13:11.332849695 +0000
#@@ -686,8 +686,12 @@
#       use_data = '''// Reuse the bytearray from the XHR as the source for file reads.
#           DataRequest.prototype.byteArray = byteArray;
#           var files = metadata['files'];
#+          function make_callback(i) {
#+            var req = DataRequest.prototype.requests[files[i].filename];
#+            return () => {req.onload()};
#+          }
#           for (var i = 0; i < files.length; ++i) {
#-            DataRequest.prototype.requests[files[i].filename].onload();
#+            setTimeout(make_callback(i));
#           }'''
#       use_data += ("          Module['removeRunDependency']('datafile_%s');\n"
#                    % js_manipulation.escape_for_js_string(data_target))
#END


            # https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_setlk.patch
            patch -p1 << END
--- emsdk-orig/upstream/emscripten/system/lib/wasmfs/syscalls.cpp	2022-07-29 17:22:28.000000000 +0000
+++ emsdk/upstream/emscripten/system/lib/wasmfs/syscalls.cpp	2022-08-06 05:05:17.014502697 +0000
@@ -1419,7 +1419,7 @@
       static_assert(F_SETLK == F_SETLK64);
       static_assert(F_SETLKW == F_SETLKW64);
       // Always error for now, until we implement byte-range locks.
-      return -EACCES;
+      return 0; //-EACCES;
     }
     case F_GETOWN_EX:
     case F_SETOWN:
END
        popd # emsdk
    fi # emsdk/.complete

    export EMSDK_PYTHON=$SYS_PYTHON

    if [ -f ${SDKROOT}/emsdk/emsdk_env.sh ]
    then
        echo "
        * activating emsdk via emsdk_env.sh with EMSDK_PYTHON=$EMSDK_PYTHON
" 1>&2
        . ${SDKROOT}/emsdk/emsdk_env.sh
        # EMSDK_PYTHON may be cleared, restore it

    else
        echo "
        ERROR cannot find emsdk/emsdk_env.sh in $(pwd)
" 1>&2
        exit 41
    fi

    export EMSDK_PYTHON=$SYS_PYTHON

    if [ -f emsdk/.complete ]
    then
        echo "
        * emsdk third parties ok
    "  1>&2
    else
        ALL="libembind libgl libal libhtml5 libstubs libnoexit libsockets"
        ALL="$ALL libc libdlmalloc libcompiler_rt libc++-noexcept libc++abi-noexcept"
        ALL="$ALL libfetch zlib bzip2 libpng libjpeg freetype harfbuzz"
        ALL="$ALL sqlite3 vorbis ogg"

        # sdl2_image is too old
        if ${SDL3:-false}
        then
            echo "Will build SDL3"
        else
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


        # why ?

        cat > ${SYSROOT}/lib/pkgconfig/freetype2.pc <<END
prefix=${SYSROOT}
exec_prefix=${PREFIX}
libdir=\${prefix}/lib/wasm32-emscripten/pic
includedir=\${prefix}/include

Name: FreeType 2
URL: https://freetype.org
Description: A free, high-quality, and portable font engine.
Version: 26.2.20
Libs: -L\${libdir} -lfreetype -lharfbuzz
Cflags: -I\${includedir}/freetype2
END
        cat > ${SYSROOT}/lib/pkgconfig/sdl2.pc <<END
prefix=${SYSROOT}
exec_prefix=${PREFIX}
libdir=\${prefix}/lib/wasm32-emscripten/pic
includedir=\${prefix}/include

Name: sdl2
Description: Simple DirectMedia Layer is a cross-platform multimedia library designed to provide low level access to audio, keyboard, mouse, joystick, 3D hardware via OpenGL, and 2D video framebuffer.
Version: 2.30.9
Requires.private:
Conflicts:
Libs: -L\${libdir} -lSDL2
Cflags: -I${includedir} -I${includedir}/SDL2   -D_REENTRANT
END
        cat > ${SYSROOT}/lib/pkgconfig/SDL2_mixer.pc <<END
prefix=${SYSROOT}
exec_prefix=/usr
libdir=\${prefix}/lib/wasm32-emscripten/pic
includedir=\${prefix}/include

Name: SDL2_mixer
Description: mixer library for Simple DirectMedia Layer
Version: 2.8.0
Requires: sdl2 >= 2.30.9
Libs: -L\${libdir} -lvorbis -logg -lSDL2_mixer_ogg
Cflags: -I${includedir}/SDL2
END




        if ${SDL3:-false}
        then
#=============================================================================================================================
            ./scripts/emsdk-fetch-sdl3.sh
#=============================================================================================================================
        else
            MIXER_LIB=${SYSROOT}/lib/wasm32-emscripten/pic/libSDL2_mixer.a
            [ -f ${MIXER_LIB} ] || llvm-ar cr {$MIXER_LIB}
            MIXER_LIB=${SYSROOT}/lib/wasm32-emscripten/libSDL2_mixer.a
            [ -f ${MIXER_LIB} ] || llvm-ar cr {$MIXER_LIB}
#=============================================================================================================================
            ./scripts/emsdk-fetch-sdl2.sh
#=============================================================================================================================
        fi # SDL3

        echo "

        * building third parties done, marking emsdk/.complete )

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

$EMSDK_PYTHON -E $SDKROOT/emsdk-cc \$0.py "\$@"
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

$EMSDK_PYTHON -E \$0.py "\$@"
END

        cat emsdk/upstream/emscripten/emar > emsdk/upstream/emscripten/emcmake

        cat > emsdk/upstream/emscripten/emconfigure <<END
#!/bin/bash
$EMSDK_PYTHON -E \$0.py "\$@"
END

        chmod +x emsdk/upstream/emscripten/em*
        touch emsdk/.complete
    fi

    # EM_PKG_CONFIG_PATH ?
    # https://emscripten.org/docs/compiling/Building-Projects.html#pkg-config

    # export PKG_CONFIG_SYSROOT_DIR="${SDKROOT}/devices/emsdk"

    # be carefull changes also needed in scripts/make-shells.sh

    export PKG_CONFIG_LIBDIR="${SDKROOT}/emsdk/upstream/emscripten/system/lib/pkgconfig"
    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${SYSROOT}/lib/pkgconfig:${HOST_PREFIX}/lib/pkgconfig"
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

    popd  # ${SDKROOT:-/opt/python-wasm-sdk}

    echo "
    will use node = $SYS_NODE
    sysroot = $SYSROOT
"
else
    echo "emsdk: already fetched and config set !" 1>&2
fi

