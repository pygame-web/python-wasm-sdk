#!/bin/bash

if [[ -z ${EMSDK+z} ]]
then

    . ${CONFIG:-config}

    if [ -d emsdk ]
    then
        echo "
        * using emsdk from $(realpath emsdk)
            with sys python $SYS_PYTHON
" 1>&2
    else
        # emsdk could have been deleted for full rebuild
        rm emsdk/.complete

        if git clone --no-tags --depth 1 --single-branch --branch main https://github.com/emscripten-core/emsdk.git
        then
            pushd emsdk
                #git checkout 91f8563a9d1a4a0ec03bbb2be23485367d85a091
                ./emsdk install ${EMFLAVOUR:-latest}
                ./emsdk activate ${EMFLAVOUR:-latest}
                pushd upstream/emscripten
                    echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/17956"
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
                popd

#                wget https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_emcc.patch
#                patch -p1 < emsdk_emcc.patch

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
                # https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_file_packager.patch
                patch -p1 << END
--- emsdk1/upstream/emscripten/tools/file_packager.py	2022-03-24 19:45:39.000000000 +0000
+++ emsdk2/upstream/emscripten/tools/file_packager.py	2022-03-22 10:13:11.332849695 +0000
@@ -686,8 +686,12 @@
       use_data = '''// Reuse the bytearray from the XHR as the source for file reads.
           DataRequest.prototype.byteArray = byteArray;
           var files = metadata['files'];
+          function make_callback(i) {
+            var req = DataRequest.prototype.requests[files[i].filename];
+            return () => {req.onload()};
+          }
           for (var i = 0; i < files.length; ++i) {
-            DataRequest.prototype.requests[files[i].filename].onload();
+            setTimeout(make_callback(i));
           }'''
       use_data += ("          Module['removeRunDependency']('datafile_%s');\n"
                    % js_manipulation.escape_for_js_string(data_target))
END
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



            popd
        fi
    fi

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
        * emsdk prereq ok
    "  1>&2
    else
        # sdl2_image is too old
        ALL="libembind libgl libal libhtml5 libstubs libnoexit libsockets"
        ALL="$ALL libc libdlmalloc libcompiler_rt libc++-noexcept libc++abi-noexcept"
        ALL="$ALL libfetch zlib bzip2 libpng libjpeg freetype harfbuzz"
        ALL="$ALL sdl2 sdl2_mixer sdl2_gfx sdl2_ttf"
        ALL="$ALL sqlite3"

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

        for one in $ALL
        do
            embuilder build $one
            embuilder --pic build $one
        done

        cat > emsdk/upstream/emscripten/emcc <<END
#!/bin/bash

EMCC_TRACE=\${EMCC_TRACE:-false}
if \$EMCC_TRACE
then
echo "
$@" >> $SDKROOT/emcc.log

fi

unset _EMCC_CCACHE

#if [ -z "\$_EMCC_CCACHE" ]
#then

unset _PYTHON_SYSCONFIGDATA_NAME
unset PYTHONHOME
unset PYTHONPATH

# -Wwarn-absolute-paths
# --valid-abspath ${SDKROOT}

COMMON="-Wno-unsupported-floating-point-opt -Wno-unused-command-line-argument -Wno-unreachable-code-fallthrough -Wno-limited-postlink-optimizations"
SHARED=""
IS_SHARED=false
PY_MODULE=false
MVP=\${MVP:true}

if \$MVP
then
    # -mcpu=generic would activate those https://reviews.llvm.org/D125728
    # https://github.com/emscripten-core/emscripten/pull/17689
    CPU="-sWASM_BIGINT=0 -sMIN_SAFARI_VERSION=120000 -mnontrapping-fptoint -mno-reference-types -mno-sign-ext -mno-mutable-globals -m32"
else
    CPU="-mcpu=bleeding-edge -m32"
fi


LINKING=\${LINKING:-false}

if echo "\$@ "|grep -q "\\.so "
then
    LINKING=true
fi


declare -A seen=( )

for arg do
    shift

    if [ "\$arg" = "-v" ]
    then
        $EMSDK_PYTHON -E \$0.py -v
        exit 0
    fi

    if [ "\$arg" = "--version" ]
    then
        $EMSDK_PYTHON -E \$0.py --version
        exit 0
    fi

    if \$LINKING
    then
        # prevent duplicates objects/archives files on cmdline when linking shared
        if echo \$arg|grep -q \\\\.o\$
        then
            [[ \${seen[\$arg]} ]] && continue
        fi
        if echo \$arg|grep -q \\\\.a\$
        then
            [[ \${seen[\$arg]} ]] && continue
        fi
        if echo \$arg|grep -q ^-l
        then
            [[ \${seen[\$arg]} ]] && continue
        fi
        seen[\$arg]=1
    fi

    arg_is_bad=false

    for badarg in "-Wl,--as-needed" "-Wl,--eh-frame-hdr" "-Wl,-znoexecstack" "-Wl,-znow" "-Wl,-zrelro" "-Wl,-zrelro,-znow"
    do
        if [ "\$arg" = "\$badarg" ]
        then
            arg_is_bad=true
            break
        fi
    done

    if \$arg_is_bad
    then
        continue
    fi

    if [ "\$arg" = "-fallow-argument-mismatch" ]
    then
        continue
    fi

    if [ "\$arg" = "-lutil" ]
    then
        continue
    fi

    if [ "\$arg" = "-lgcc" ]
    then
        continue
    fi

    if [ "\$arg" = "-lgcc_s" ]
    then
        continue
    fi

    if [ "\$arg" = "-nomvp" ]
    then
        MVP=false
        continue
    fi

    # that is for some very bad setup.py behaviour regarding cross compiling.
    # should not be needed ..
    [ "\$arg" = "-I/usr/include" ] && continue
    [ "\$arg" = "-I/usr/include/SDL2" ] && continue
    [ "\$arg" = "-L/usr/lib64" ]	&& continue
    [ "\$arg" = "-L/usr/lib" ]   && continue

    if [ "\$arg" = "-shared" ]
    then
        IS_SHARED=true
        SHARED="\$SHARED -sSIDE_MODULE"
    fi

    if echo "\$arg"|grep -q wasm32-emscripten.so\$
    then
        PY_MODULE=true
        SHARED_TARGET=\$arg
    else
        if echo "\$arg"|grep -q abi3.so\$
        then
            PY_MODULE=true
            SHARED_TARGET=\$arg
        fi
    fi

    if \$PY_MODULE
    then
        if \$IS_SHARED
        then
            true
        else
            IS_SHARED=true
            SHARED="\$SHARED -shared -sSIDE_MODULE"
        fi
    else
        if \$IS_SHARED
        then
            if echo "\$arg"|grep \\\\.so\$
            then
                PY_MODULE=true
                SHARED_TARGET=\$arg
                SHARED="-sSIDE_MODULE"
            fi
        fi
    fi

    set -- "\$@" "\$arg"
done

if \$IS_SHARED
then
    $EMSDK_PYTHON -E \$0.py \$SHARED $CPU  $COPTS $LDFLAGS -sSIDE_MODULE -gsource-map --source-map-base / "\$@" \$COMMON
    if \$MVP
    then
        SOTMP=\$(mktemp).so
        mv \$SHARED_TARGET \$SOTMP
        $SDKROOT/emsdk/upstream/bin/wasm-emscripten-finalize -mvp \$SOTMP -o \$SHARED_TARGET
        [ -f \$SHARED_TARGET.map ] && rm \$SHARED_TARGET.map
        rm \$SOTMP
    fi
else
    $EMSDK_PYTHON -E \$0.py $CPU -fpic \$COPTS \$CPPFLAGS -DBUILD_STATIC "\$@" \$COMMON
fi
#else
#  unset _EMCC_CCACHE
#  exec ccache "\$0" "\$@"
#fi

END

        cat emsdk/upstream/emscripten/emcc > emsdk/upstream/emscripten/em++

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
        sync
    fi

    # EM_PKG_CONFIG_PATH ?
    # https://emscripten.org/docs/compiling/Building-Projects.html#pkg-config

    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"

    if echo $PATH|grep -q $EMSDK/upstream/emscripten/system/bin
    then
        # emsdk env does not set it, but it's required for eg sdl2-config
        echo -n
    else
        export PATH=$EMSDK/upstream/emscripten/system/bin:$EMSDK/upstream/emscripten:$PATH
    fi

    TRUE=$(which true)
    for fix in readelf ldconfig
    do
        FIXED=$EMSDK/upstream/emscripten/system/bin/$fix
        [ -f $FIXED ] || cp $TRUE $FIXED
    done


    if [ -f /pp ]
    then
        # yes, i only have a amd200GE with 32G
        NPROC=1
        export EMSDK_NUM_CORES=1
    else
        NPROC=$(nproc)
    fi

    mkdir -p src
    export PKG_CONFIG_PATH="${SDKROOT}/emsdk/upstream/emscripten/system/lib/pkgconfig:${HOST_PREFIX}/lib/pkgconfig"

    export CPPFLAGS="-I$PREFIX/include"
    export LDFLAGS="-L$PREFIX/lib"
    # -msoft-float

    # module build opts
    export CFLDPFX="$CPPFLAGS $LDFLAGS -Wno-unused-command-line-argument"
    export PYDK=minimal

    if command -v ccache 2>&1 >/dev/null; then
        export EM_COMPILER_WRAPPER=ccache
        export _EMCC_CCACHE=1
    fi

    export EMCC_SKIP_SANITY_CHECK=1
    export EM_IGNORE_SANITY=1

else
    echo "emsdk: config already set !" 1>&2
fi

