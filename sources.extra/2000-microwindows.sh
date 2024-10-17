#!/bin/bash

# X11 include dest /opt/python-wasm-sdk/./emsdk/upstream/emscripten/cache/sysroot/include/X11


. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


cd ${ROOT}/src

PKG=microwindows


if [ -f ${PKG}.patched ]
then
    echo "
        ${PKG} already prepared
    "
else
    git clone --recursive https://github.com/pmp-p/${PKG}
    pushd ${PKG}
    popd
    touch ${PKG}.patched
fi


if [ -f $PREFIX/lib/libNX11.a ]
then
    echo "
        already built in $PREFIX/lib/libX11.a
    "
else

    #    mkdir -p $ROOT/build/${PKG}
    cp -rf $ROOT/src/${PKG} $ROOT/build/

    pushd $ROOT/build/${PKG}

patch -p1 <<END
diff --git a/src/nanox/client.c b/src/nanox/client.c
index 5c44e26..1fbe424 100644
--- a/src/nanox/client.c
+++ b/src/nanox/client.c
@@ -77,6 +77,19 @@
  */
 #define SHM_BLOCK_SIZE 4096

+
+#if defined(__EMSCRIPTEN__) || defined(__wasi__)
+int nxGlobalLock = 0;
+#undef LOCK_DECLARE
+#undef LOCK
+#undef UNLOCK
+#undef LOCK_FREE
+#define LOCK_DECLARE(x)
+#define LOCK(l)
+#define UNLOCK(l)
+#define LOCK_FREE(l)
+#endif
+
 #if !__ECOS
 /* exported global data */
 int nxSocket = -1;              /* The network socket descriptor */
diff --git a/src/nanox/serv.h b/src/nanox/serv.h
index d7379a0..e1968b4 100644
--- a/src/nanox/serv.h
+++ b/src/nanox/serv.h
@@ -134,6 +134,15 @@
  * in lock.h) for linked-in mode, or a no-op for client/server mode.
  */

+
+#if defined(__EMSCRIPTEN__) || defined(__wasi__)
+//static int gr_server_mutex = 0;
+#define SERVER_LOCK_DECLARE
+#define SERVER_LOCK_INIT()
+#define SERVER_LOCK()
+#define SERVER_UNLOCK()
+#else
+
 #if NONETWORK
 /* Use a server-side mutex. */

@@ -153,6 +162,7 @@ LOCK_EXTERN(gr_server_mutex);
 #define SERVER_LOCK()       do {} while(0) /* no-op, but require a ";" */
 #define SERVER_UNLOCK()     do {} while(0) /* no-op, but require a ";" */
 #endif /* !NONETWORK*/
+#endif /* __EMSCRIPTEN__ __wasi__ */

 /*
  * Drawing types.
END

    patch -p1 < ${SDKROOT}/sources.extra/microwindows.diff


# FIXME: use pkg config !!!

    EMCC_CFLAGS="-I${EMSDK}/upstream/emscripten/cache/sysroot/include/freetype2" \
     CC=emcc CXX=emc++ emmake make -C src NX11=Y NANOX=Y MICROWIN=N ARCH=EMSCRIPTEN LINK_APP_INTO_SERVER=Y NANOXDEMO=N ERASEMOVE=1 || exit 99


    if [ -f /pp ]
    then
        emcc -sASYNCIFY -o xhello.html -I./src/nx11/X11-local ./src/contrib/nx11-test/xhello.c -L./src/lib -lNX11 -lnano-X -lfreetype -lz -lSDL2; mv xhello.* /srv/www/html/wasm/x11/
    fi
    cp ./src/lib/{libNX11.a,libnano-X.a} $PREFIX/lib/
    cp -r ./src/nx11/X11-local/X11 $PREFIX/include/
    popd
fi

# for fltk build

cat <<END > ${SDKROOT}/emsdk/upstream/emscripten/cache/sysroot/include/X11/Xlocale.h
#define LC_CTYPE "C"
#define setlocale(ct0,ct1)
END


