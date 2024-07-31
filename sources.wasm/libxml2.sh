#!/bin/bash

. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


cd ${ROOT}/src

if [ -d libxml2 ]
then
    echo ok
else
    wget -c https://download.gnome.org/sources/libxml2/2.12/libxml2-2.12.7.tar.xz
    tar xf libxml2-2.12.7.tar.xz
    mv libxml2-2.12.7 libxml2
fi

if [ -f $PREFIX/lib/libxml2.a ]
then
    echo "
        already built in $PREFIX/lib/libxml2.a
    "
else

    mkdir -p $ROOT/build/libxml2
    pushd $ROOT/build/libxml2
    emconfigure ${ROOT}/src/libxml2/configure --prefix=$PREFIX \
     --with-http=no --with-ftp=no --with-python=no --with-threads=no \
     --enable-shared=no --enable-static=yes \
     --without-icu

# --enable-shared=yes => link error of
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlMemSetup
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlCheckVersion
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSetCompressMode
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlAddEncodingAlias
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlNoNetExternalEntityLoader
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSetExternalEntityLoader
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlLoadCatalogs
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlRegisterNodeDefault
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlDeregisterNodeDefault
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlTreeIndentString
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlGetExternalEntityLoader
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSetExternalEntityLoader
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlGenericErrorContext
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlGenericError
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSchematronNewParserCtxt
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSchematronParse
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlGenericErrorContext
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlGenericError
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlSchematronFreeParserCtxt
#wasm-ld: error: xmllint-xmllint.o: undefined symbol: xmlRelaxNGNewParserCtxt

    emmake make install
    popd
fi



