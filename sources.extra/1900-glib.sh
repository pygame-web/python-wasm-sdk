#!/usr/bin/env bash

# https://github.com/kleisauke/glib


. ${CONFIG:-config}

. scripts/emsdk-fetch.sh

if pushd ${ROOT}/src
then

    SOURCE_DIR=$PWD

    # Working directories
    DEPS=$SOURCE_DIR

    # Define default arguments

    # JS BigInt to Wasm i64 integration, enabled by default
    WASM_BIGINT=true

    # Parse arguments
    while [ $# -gt 0 ]; do
      case $1 in
        --disable-wasm-bigint) WASM_BIGINT=false ;;
        *) echo "ERROR: Unknown parameter: $1" >&2; exit 1 ;;
      esac
      shift
    done

    # Configure the ENABLE_* and DISABLE_* expansion helpers
    for arg in WASM_BIGINT; do
      if [ "${!arg}" = "true" ]; then
        declare ENABLE_$arg=true
      else
        declare DISABLE_$arg=true
      fi
    done

    # Common compiler flags
    export COPTS="-Os -g0"
    export LDFLAGS="-L$PREFIX/lib"


    # Build paths
    export CPATH="$PREFIX/include"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"

    # Specific variables for cross-compilation
    export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten
    export MESON_CROSS="$SOURCE_DIR/emscripten-crossfile.meson"

    # Run as many parallel jobs as there are available CPU cores
    export MAKEFLAGS="-j$(nproc)"

    # Ensure we link against internal/private dependencies
    export PKG_CONFIG="pkg-config --static"

    # Dependency version numbers
    VERSION_ZLIB=1.3
    VERSION_FFI=3.4.4
    VERSION_GLIB=2.78.0

    # Remove patch version component
    without_patch() {
      echo "${1%.[[:digit:]]*}"
    }

    #mkdir $DEPS/zlib
    #curl -Ls https://github.com/madler/zlib/releases/download/v$VERSION_ZLIB/zlib-$VERSION_ZLIB.tar.xz | tar xJC $DEPS/zlib --strip-components=1
    #cd $DEPS/zlib
    #emconfigure ./configure --prefix=$PREFIX --static
    #make install

    #mkdir $DEPS/ffi
    #curl -Ls https://github.com/libffi/libffi/releases/download/v$VERSION_FFI/libffi-$VERSION_FFI.tar.gz | tar xzC $DEPS/ffi --strip-components=1
    #cd $DEPS/ffi
    ## TODO(kleisauke): Wait for upstream release with PR https://github.com/libffi/libffi/pull/763 included
    #curl -Ls https://github.com/libffi/libffi/compare/v$VERSION_FFI...kleisauke:wasm-vips${ENABLE_WASM_BIGINT:+-bigint}.patch | patch -p1
    #autoreconf -fiv
    ## Compile without -fexceptions
    #sed -i 's/ -fexceptions//g' configure
    #emconfigure ./configure --host=$CHOST --prefix=$PREFIX --enable-static --disable-shared --disable-dependency-tracking \
    #  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-structs --disable-docs
    #make install SUBDIRS='include'

    if [ -d glib ]
    then
        pushd glib
    else
        mkdir glib
        curl -Lks https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-$VERSION_GLIB.tar.xz | tar xJC $DEPS/glib --strip-components=1
        pushd glib

        echo "

TODO(kleisauke): Discuss these patches upstream https://github.com/GNOME/glib/compare/$VERSION_GLIB...kleisauke:wasm-vips-$VERSION_GLIB.patch

"

        curl -Ls https://github.com/GNOME/glib/compare/$VERSION_GLIB...kleisauke:wasm-vips-$VERSION_GLIB.patch | patch -p1
    fi


    cat <<END > emscripten-crossfile.meson
[binaries]
c = 'emcc'
cpp = 'em++'
ar = 'emar'
ranlib = 'emranlib'
pkg-config = ['pkg-config', '--static']
# https://docs.gtk.org/glib/cross-compiling.html#cross-properties

[properties]
growing_stack = true
have_c99_vsnprintf = true
have_c99_snprintf = true
have_unix98_printf = true

# Ensure that -s PTHREAD_POOL_SIZE=* is not injected into .pc files
[built-in options]
c_thread_count = 0
cpp_thread_count = 0

[host_machine]
system = 'emscripten'
cpu_family = 'wasm32'
cpu = 'wasm32'
endian = 'little'

[backend]
backend_max_links = 1

END

    echo "


    ============ MESON SETUP $(which ninja) =========================


"
    meson setup _build --reconfigure --prefix=$PREFIX --cross-file=emscripten-crossfile.meson --default-library=static --buildtype=minsize \
      --force-fallback-for=pcre2,gvdb -Dselinux=disabled -Dxattr=false -Dlibmount=disabled -Dnls=disabled \
      -Dtests=false -Dglib_assert=false -Dglib_checks=false
    echo "


    ============ MESON COMPILE =========================


"
    # meson compile _build -j 1
    echo "


    ============ MESON INSTALL =========================


"

    meson install -C _build --tag devel
    popd  # glib
    popd # src

fi
