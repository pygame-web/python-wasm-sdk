#!/bin/bash

if [[ -z ${WASISDK+z} ]]
then
    echo please use wasisdk_env.sh
    exit 1
fi
SDKROOT=${SDKROOT:-/opt/python-wasm-sdk}

pushd ${SDKROOT}

    . ${CONFIG:-config}

    pushd ${SDKROOT}/wasisdk

        wget -c https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK}/wasi-sdk-${WASI_SDK}.0-linux.tar.gz
        tar xfz wasi-sdk-${WASI_SDK}.0-linux.tar.gz
        mv wasi-sdk-${WASI_SDK}.0 upstream && rm wasi-sdk-${WASI_SDK}.0-linux.tar.gz

        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-cpp
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c++

        mkdir -p upstream/share/wasi-sysroot/include/wasm32-wasi/
        cp -vf hotfix/dlfcn.h upstream/share/wasi-sysroot/include/wasm32-wasi/

    popd

    $HPIP install cmake wasmtime

    mkdir -p ${SDKROOT}/wasisdk/share/cmake/Modules/Platform/

    cat > ${CMAKE_TOOLCHAIN_FILE} <<END
# Cmake toolchain description file for the Makefile

# set(CMAKE_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")
list(APPEND CMAKE_MODULE_PATH "${WASISDK}/share/cmake/Modules")


# This is arbitrary, AFAIK, for now.
cmake_minimum_required(VERSION 3.5.0)
set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(triple wasm32-wasi)

set(WASI True)
option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)
set_property(GLOBAL PROPERTY CXX_EXCEPTIONS OFF)
set_property(GLOBAL PROPERTY CXX_RTTI OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(COMPILER_SUPPORTS_FEXCEPTIONS FALSE)
#add_compile_options(-fpic)
#add_compile_options(-fno-exceptions)

set(CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}")

set(CMAKE_CROSSCOMPILING 1)


if(WIN32)
	set(WASI_HOST_EXE_SUFFIX ".exe")
else()
	set(WASI_HOST_EXE_SUFFIX "")
endif()

# lock those
set(CMAKE_C_COMPILER "${WASISDK}/bin/wasi-c")
set(CMAKE_CXX_COMPILER "${WASISDK}/bin/wasi-c++")

set(CMAKE_C_COMPILER_ID_RUN TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_ID Clang)
set(CMAKE_C_COMPILER_FRONTEND_VARIANT GNU)
set(CMAKE_C_STANDARD_COMPUTED_DEFAULT 11)

#set(CMAKE_C_STANDARD 99)
#set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

set(CMAKE_CXX_COMPILER_ID_RUN TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_ID Clang)
set(CMAKE_CXX_COMPILER_FRONTEND_VARIANT GNU)
set(CMAKE_CXX_STANDARD_COMPUTED_DEFAULT 98)

set(CMAKE_C_PLATFORM_ID "wasi")
set(CMAKE_CXX_PLATFORM_ID "wasi")

set(CMAKE_ASM_COMPILER "${WASI_SDK_PREFIX}/bin/clang${WASI_HOST_EXE_SUFFIX}")
set(CMAKE_AR "${WASI_SDK_PREFIX}/bin/llvm-ar${WASI_HOST_EXE_SUFFIX}")
set(CMAKE_RANLIB "${WASI_SDK_PREFIX}/bin/llvm-ranlib${WASI_HOST_EXE_SUFFIX}")
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER_TARGET ${triple})

# Don't look in the sysroot for executables to run during the build
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Only look in the sysroot (not in the host paths) for the rest
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 64
#set(CMAKE_SIZEOF_VOID_P 8)
#set(CMAKE_C_SIZEOF_DATA_PTR 8)
#set(CMAKE_CXX_SIZEOF_DATA_PTR 8)

# 32
set(CMAKE_SIZEOF_VOID_P 4)
set(CMAKE_C_SIZEOF_DATA_PTR 4)
set(CMAKE_CXX_SIZEOF_DATA_PTR 4)

# faster
set(CMAKE_SKIP_COMPATIBILITY_TESTS 1)
set(CMAKE_SIZEOF_CHAR 1)
set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
set(CMAKE_SIZEOF_SHORT 2)
set(CMAKE_SIZEOF_INT 4)
set(CMAKE_SIZEOF_UNSIGNED_LONG 4)
set(CMAKE_SIZEOF_UNSIGNED_INT 4)
set(CMAKE_SIZEOF_LONG 4)
set(CMAKE_SIZEOF_FLOAT 4)
set(CMAKE_SIZEOF_DOUBLE 8)
set(CMAKE_HAVE_LIMITS_H 1)
set(CMAKE_HAVE_UNISTD_H 1)
set(CMAKE_HAVE_PTHREAD_H 1)
set(CMAKE_HAVE_SYS_PRCTL_H 1)
set(CMAKE_WORDS_BIGENDIAN 0)

set(CMAKE_EXECUTABLE_SUFFIX ".wasi")

set(CMAKE_CROSSCOMPILING_EMULATOR "${WASISDK}/bin/wasi-run" FILEPATH "Path to the emulator for the target system.")

END

    # cp ${SDKROOT}/wasisdk/share/cmake/Modules/Platform/WASI.cmake ${SDKROOT}/devices/$(arch)/usr/lib/python${PYBUILD}/site-packages/cmake/data/share/cmake-*/Modules/Platform/

    pushd ${WASI_SYSROOT}
        VMLABS="https://github.com/vmware-labs/webassembly-language-runtimes/releases/download"
        wget "${VMLABS}/libs%2Flibpng%2F1.6.39%2B20230629-ccb4cb0/libpng-1.6.39-wasi-sdk-20.0.tar.gz" -O-| tar xfz -
        wget "${VMLABS}/libs%2Fzlib%2F1.2.13%2B20230623-2993864/libz-1.2.13-wasi-sdk-20.0.tar.gz"  -O-| tar xfz -
        wget "${VMLABS}/libs%2Fsqlite%2F3.42.0%2B20230623-2993864/libsqlite-3.42.0-wasi-sdk-20.0.tar.gz" -O-| tar xfz -
        wget "${VMLABS}/libs%2Flibxml2%2F2.11.4%2B20230623-2993864/libxml2-2.11.4-wasi-sdk-20.0.tar.gz" -O-| tar xfz -
        wget "${VMLABS}/libs%2Fbzip2%2F1.0.8%2B20230623-2993864/libbzip2-1.0.8-wasi-sdk-20.0.tar.gz"  -O-| tar xfz -
        wget "${VMLABS}/libs%2Flibuuid%2F1.0.3%2B20230623-2993864/libuuid-1.0.3-wasi-sdk-20.0.tar.gz" -O-| tar xfz -
    popd

popd
