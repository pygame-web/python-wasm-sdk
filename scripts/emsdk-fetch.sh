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
                ./emsdk install ${EMFLAVOUR:-latest}
                ./emsdk activate ${EMFLAVOUR:-latest}
                pushd upstream/emscripten
                    echo "FIXME: Applying https://github.com/emscripten-core/emscripten/pull/17956"
                    wget https://patch-diff.githubusercontent.com/raw/emscripten-core/emscripten/pull/17956.diff
                    patch -p1 < 17956.diff
                popd
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
        ALL="$ALL struct_info libfetch zlib bzip2"
        ALL="$ALL libpng libjpeg freetype harfbuzz"
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

unset _EMCC_CCACHE

#if [ -z "\$_EMCC_CCACHE" ]
#then

unset _PYTHON_SYSCONFIGDATA_NAME
unset PYTHONHOME
unset PYTHONPATH

# -Wwarn-absolute-paths
# --valid-abspath ${SDKROOT}

COMMON="-Wno-unused-command-line-argument -Wno-unreachable-code-fallthrough -Wno-limited-postlink-optimizations"
SHARED=""
IS_SHARED=false
PY_MODULE=false
MVP=true

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

    if [ "\$arg" = "-fallow-argument-mismatch" ]
    then
        continue
    fi

    if [ "\$arg" = "-nomvp" ]
    then
        MVP=false
        continue
    fi

    # that is for some very bad setup.py behaviour regarding cross compiling. should not be needed ..
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
    $EMSDK_PYTHON -E \$0.py \$SHARED $COPTS $LDFLAGS -sSIDE_MODULE -gsource-map --source-map-base / "\$@" \$COMMON
    if \$MVP
    then
        SOTMP=\$(mktemp).so
        mv \$SHARED_TARGET \$SOTMP
        $SDKROOT/emsdk/upstream/bin/wasm-emscripten-finalize -mvp \$SOTMP -o \$SHARED_TARGET
        [ -f \$SHARED_TARGET.map ] && rm \$SHARED_TARGET.map
        rm \$SOTMP
    fi
else
    $EMSDK_PYTHON -E \$0.py \$COPTS \$CPPFLAGS -DBUILD_STATIC "\$@" \$COMMON
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

