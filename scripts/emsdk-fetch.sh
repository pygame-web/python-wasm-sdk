#!/bin/bash

if [[ -z ${EMSDK+z} ]]
then
    pushd ${SDKROOT:-/opt/python-wasm-sdk}

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
                    echo "FIXME: applying stdio* are not const"
                    sed -i 's|extern FILE \*const|extern FILE \*|g' cache/sysroot/include/stdio.h

                    echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/20281 dylink.js : handle ** argument case"
if [ -f test/other/test_em_js_side.c b/test/other/test_em_js_side.c ]
then
                    wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/20281.diff
                    patch -p1 < 20281.diff
else
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
           var func = `(${jsArgs}) => ${body};`;
END

fi
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
                popd

#                wget https://raw.githubusercontent.com/paradust7/minetest-wasm/main/emsdk_emcc.patch
#                patch -p1 < emsdk_emcc.patch

                pushd upstream/emscripten
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
                popd



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
        ALL="$ALL sqlite3 vorbis ogg"

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

        curl -fsSL https://bun.sh/install | bash

        # emsdk shipped node cannot run on alpine
        if [ -f /alpine ]
        then
            cp -vf /usr/bin/node $ROOT/emsdk/node/??.??.*/bin/node
        fi

        export PATH=$(echo -n ${SDKROOT}/emsdk/node/??.??.*/bin):$PATH
        $ROOT/emsdk/node/??.??.*/bin/npm install --prefix $ROOT/emsdk/node/??.??.* -g pnpm@^9.0.0

# maybe rewrite that in python and move it to emcc.py

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
# if \${PYDK_CC:-false}
if true
then
    $EMSDK_PYTHON -E $SDKROOT/emsdk-cc \$0.py "\$@"
    exit \$?
fi


# -Wwarn-absolute-paths
# --valid-abspath ${SDKROOT}

# COMMON="-Wno-unsupported-floating-point-opt"
COMMON="-Wno-limited-postlink-optimizations -Wno-unused-command-line-argument -Wno-unreachable-code-fallthrough -Wno-unused-function"
SHARED=""
IS_SHARED=false
PY_MODULE=false
MVP=\${MVP:true}
WASM_PURE=\${WASM_PURE:true}


if \$MVP
then

    # turn of wasm ex (https://github.com/emscripten-core/emscripten/pull/20536)
    # -fno-wasm-exceptions -sEMSCRIPTEN_LONGJMP=0


    # -mcpu=generic would activate those https://reviews.llvm.org/D125728
    # https://github.com/emscripten-core/emscripten/pull/17689

    # -fPIC not allowed with -mno-mutable-globals
    # -mno-sign-ext not allowed with pthread

    #WASMOPTS="-fno-wasm-exceptions -sSUPPORT_LONGJMP=emscripten"
    #CPU="-mnontrapping-fptoint -mno-reference-types -mno-sign-ext  -m32"

#  -mno-bulk-memory <= this is problematic 2024-10-26

    CPU="-D_FILE_OFFSET_BITS=64 -sSUPPORT_LONGJMP=emscripten -mno-bulk-memory -mnontrapping-fptoint -mno-reference-types -mno-sign-ext -m32"

else
    CPU="-D_FILE_OFFSET_BITS=64 -mcpu=bleeding-edge -m64"
fi

# try to keep 32 but with 64 iface (bitint)
WASMEXTRA="$WASM_EXTRA \$WASMOPTS"


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

    if [ "\$arg" = "-c" ]
    then
        CPU_EXTRA=\$WASM_EXTRA
    fi

    if [ "\$arg" = "-o" ]
    then
        CPU_EXTRA=\$WASM_EXTRA
    fi

    if [ "\$arg" = "-fallow-argument-mismatch" ]
    then
        continue
    fi

    if [ "\$arg" = "-lutil" ]
    then
        continue
    fi

    if [ "\$arg" = "-O3" ]
    then
        continue
    fi

    if [ "\$arg" = "-g" ]
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

    if [ "\$arg" = "-pthread" ]
    then
        if echo \$CPU|grep -q mno-sign-ext
        then
            continue
        fi
    fi


    # that is for some very bad setup.py behaviour regarding cross compiling.
    # should not be needed ..
    [ "\$arg" = "-I/usr/include" ] && continue
    [ "\$arg" = "-I/usr/include/SDL2" ] && continue
    [ "\$arg" = "-L/usr/lib64" ]	&& continue
    [ "\$arg" = "-L/usr/lib" ]   && continue
    [ "\$arg" = "-latomic" ]   && continue

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
    # always pass CPU opts when linking
    $EMSDK_PYTHON -E \$0.py \$SHARED $COPTS \$CPU \$WASM_EXTRA \$LDFLAGS -sSIDE_MODULE -gsource-map --source-map-base / "\$@" \$COMMON
    if \$MVP
    then
        if \$WASM_PURE
        then
            SOTMP=\$(mktemp).so
            mv \$SHARED_TARGET \$SOTMP
            # --memory64-lowering --signext-lowering
            $SDKROOT/emsdk/upstream/bin/wasm-emscripten-finalize -mvp \$SOTMP -o \$SHARED_TARGET
            [ -f \$SHARED_TARGET.map ] && rm \$SHARED_TARGET.map
            rm \$SOTMP
        fi
    fi
else
    # do not pass WASM opts when -c/-o but always PIC
    if echo $@|grep -q MAIN_MODULE
    then
        $EMSDK_PYTHON -E \$0.py $COPTS \$CPU \$CPU_EXTRA \$CPPFLAGS -DBUILD_STATIC "\$@" \$COMMON
    else
        $EMSDK_PYTHON -E \$0.py $COPTS \$CPU_EXTRA \$CPPFLAGS -DBUILD_STATIC "\$@" \$COMMON
    fi
fi
#else
#  unset _EMCC_CCACHE
#  exec ccache "\$0" "\$@"
#fi

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
        sync
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

    #ln $EMSDK/upstream/emscripten/emstrip $EMSDK/upstream/emscripten/strip
    #ln $EMSDK/upstream/emscripten/emstrip.py $EMSDK/upstream/emscripten/strip.py

    mkdir -p ${SDKROOT}/devices/$(arch)/usr/bin/
    cp $SDKROOT/wasisdk/bin/wasm-objdump* ${SDKROOT}/devices/$(arch)/usr/bin/

    TRUE=$(which true)
    for fix in readelf ldconfig
    do
        FIXED=$EMSDK/upstream/emscripten/system/bin/$fix
        [ -f $FIXED ] || cp $TRUE $FIXED
    done


    export NPROC=1
    export EMSDK_NUM_CORES=$NPROC

    mkdir -p src

    export CPPFLAGS="-I$PREFIX/include"
    export LDFLAGS="-L$PREFIX/lib"
    # -msoft-float

    # module build opts
    export CFLDPFX="$CPPFLAGS $LDFLAGS -Wno-unused-command-line-argument"
    export PYDK=true

    if command -v ccache 2>&1 >/dev/null; then
        export EM_COMPILER_WRAPPER=ccache
        export _EMCC_CCACHE=1
    fi

    export EMCC_SKIP_SANITY_CHECK=1
    export EM_IGNORE_SANITY=1

    export SYSROOT=$EMSDK/upstream/emscripten/cache/sysroot
    popd
else
    echo "emsdk: config already set !" 1>&2
fi

