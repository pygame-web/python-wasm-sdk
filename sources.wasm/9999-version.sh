#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh

    ALL="-m32 \
-D_FILE_OFFSET_BITS=64 \
-sSUPPORT_LONGJMP=emscripten \
-mno-bulk-memory \
-mnontrapping-fptoint \
-mno-reference-types \
-mno-sign-ext \
-mno-extended-const \
-mno-atomics \
-mno-tail-call \
-mno-fp16 \
-mno-multivalue \
-mno-relaxed-simd \
-mno-simd128 \
-mno-multimemory \
-mno-exception-handling"

pushd /tmp
    rm hello_em.*

    cat > /tmp/hello_em.c <<END
#include <stdio.h>
#include <assert.h>
#if defined(__EMSCRIPTEN__)
#include "emscripten.h"
#endif

int main(int argc, char**arv){
#if defined(__EMSCRIPTEN__)
    printf("export EMFLAVOUR=" "%d.%d.%d\n",__EMSCRIPTEN_major__, __EMSCRIPTEN_minor__, __EMSCRIPTEN_tiny__);
#else
    puts("native");
#endif
    return 0;
}
END

    emcc -sASSERTIONS=0 -sENVIRONMENT=node,web -o hello_em.html hello_em.c
    $SDKROOT/emsdk/node/*.*.*64bit/bin/node hello_em.js >> $SDKROOT/config
    rm hello_em.js hello_em.wasm hello_em.c
popd


