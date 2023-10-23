#!/bin/bash


if [[ -z ${WASISDK+z} ]]
then
    pushd ${SDKROOT:-/opt/python-wasm-sdk}
    . ${CONFIG:-config}

    export WASISDK="${SDKROOT}/wasisdk"
    export WASI_SDK_PREFIX="${WASISDK}/upstream"
    export WASI_SYSROOT="${WASI_SDK_PREFIX}/share/wasi-sysroot"


    export CMAKE_TOOLCHAIN_FILE=${SDKROOT}/wasisdk/share/cmake/Modules/Platform/WASI.cmake
    export CMAKE_INSTALL_PREFIX="${SDKROOT}/devices/wasi/usr"

    if [ -d ${WASI_SDK_PREFIX} ]
    then
        echo "
        * using wasisdk from $(realpath wasisdk/upstream)
            with sys python $SYS_PYTHON and host python $HPY

" 1>&2
    else
        pushd wasisdk
        if [ -f /pp ]
        then
            wget -c http://192.168.1.66/cfake/wasi-sdk-20.0-linux.tar.gz
        else
            wget -c https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sdk-20.0-linux.tar.gz
        fi
        tar xfz wasi-sdk-20.0-linux.tar.gz
        mv wasi-sdk-20.0 upstream && rm wasi-sdk-20.0-linux.tar.gz
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-cpp
        ln ${SDKROOT}/wasisdk/bin/wasi ${SDKROOT}/wasisdk/bin/wasi-c++
        popd

        $HPIP install cmake wasmtime

        # /opt/python-wasm-sdk/devices/x86_64/usr/lib/python3.11/site-packages/cmake/data/share/cmake-3.27/Modules/Platform/
        cp -v wasisdk/share/cmake/WASI.cmake ${SDKROOT}/devices/$(arch)/usr/lib/python${PYBUILD}/site-packages/cmake/data/share/cmake-*/Modules/Platform/


#cat > ${SDKROOT}/devices/$(arch)/usr/lib/python${PYBUILD}/site-packages/cmake/data/share/cmake-*/Modules/Platform/WASI.cmake <<END

mkdir -p ${SDKROOT}/wasisdk/share/cmake/Modules/Platform/

cat > ${CMAKE_TOOLCHAIN_FILE} <<END
# Cmake toolchain description file for the Makefile

# set(CMAKE_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")
# list(APPEND CMAKE_MODULE_PATH "${WASISDK}/share/cmake/Modules")


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


# Make HandleLLVMOptions.cmake happy.
# TODO(sbc): We should probably fix llvm or libcxxabi instead.
# See: https://reviews.llvm.org/D33753
# set(UNIX 1)

set(CMAKE_CROSSCOMPILING 1)


if(WIN32)
	set(WASI_HOST_EXE_SUFFIX ".exe")
else()
	set(WASI_HOST_EXE_SUFFIX "")
endif()

# lock those
set(CMAKE_C_COMPILER ${WASISDK}/bin/wasi-c)
set(CMAKE_CXX_COMPILER ${WASISDK}/bin/wasi-c++)

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

set(CMAKE_ASM_COMPILER ${WASI_SDK_PREFIX}/bin/clang${WASI_HOST_EXE_SUFFIX})
set(CMAKE_AR ${WASI_SDK_PREFIX}/bin/llvm-ar${WASI_HOST_EXE_SUFFIX})
set(CMAKE_RANLIB ${WASI_SDK_PREFIX}/bin/llvm-ranlib${WASI_HOST_EXE_SUFFIX})
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
    wget "https://github.com/vmware-labs/webassembly-language-runtimes/releases/download/libs%2Flibpng%2F1.6.39%2B20230629-ccb4cb0/libpng-1.6.39-wasi-sdk-20.0.tar.gz" -O-| tar xvfz -
    wget "https://github.com/vmware-labs/webassembly-language-runtimes/releases/download/libs%2Fzlib%2F1.2.13%2B20230623-2993864/libz-1.2.13-wasi-sdk-20.0.tar.gz"  -O-| tar xvfz -
    popd


    fi

    popd

    export PATH="${WASISDK}/bin:${WASI_SDK_PREFIX}/bin:$PATH"

    export PREFIX=$CMAKE_INSTALL_PREFIX

    # instruct pkg-config to use wasi target root
    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${WASI_SYSROOT}/lib/wasm32-wasi/pkgconfig"

    # for thirparty prebuilts .pc in sdk
    export PKG_CONFIG_LIBDIR="${WASI_SYSROOT}/lib/wasm32-wasi/pkgconfig:${WASI_SYSROOT}/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="${WASI_SYSROOT}"


    export PS1="[PyDK:wasi] \w $ "


    export LDSHARED="${WASI_SDK_PREFIX}/bin/wasm-ld"
    export AR="${WASI_SDK_PREFIX}/bin/llvm-ar"
    export RANLIB="${WASI_SDK_PREFIX}/bin/ranlib"

    WASI_CFG="--sysroot=${WASI_SDK_PREFIX}/share/wasi-sysroot -I${WASISDK}/hotfix"
    WASI_DEF="-D_WASI_EMULATED_MMAN -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_GETPID"

    # wasi assembly
    WASI_ALL="${WASI_CFG} ${WASI_DEF} -fPIC -fno-rtti -fno-exceptions"

    WASI_ALL="$WASI_ALL -Wno-unused-but-set-variable -Wno-unused-command-line-argument -Wno-unsupported-floating-point-opt"

    # wasi linking
    WASI_LNK="-lwasi-emulated-getpid -lwasi-emulated-mman -lwasi-emulated-signal -lwasi-emulated-process-clocks -lc++experimental -fno-exceptions"

#    export CC="${WASISDK}/bin/wasi-c"
#    export CPP="${WASISDK}/bin/wasi-cpp"
#    export CXX="${WASISDK}/bin/wasi++"

    CXX_LIBS="-lc++ -lc++abi -lc++experimental"

    export CC="${WASI_SDK_PREFIX}/bin/clang ${WASI_ALL}"
    export CXX="${WASI_SDK_PREFIX}/bin/clang++ ${WASI_ALL} ${CXX_LIBS}"
    export CPP="${WASI_SDK_PREFIX}/bin/clang-cpp ${WASI_CFG} ${WASI_DEF}"





else
    echo "wasidk: config already set !" 1>&2
fi
