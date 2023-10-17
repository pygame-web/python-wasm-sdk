# Cmake toolchain description file for the Makefile
set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(triple wasm32-wasi)

# This is arbitrary
cmake_minimum_required(VERSION 3.5.0)

set(WASI True)
set(CMAKE_CROSSCOMPILING TRUE)
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)
option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

set_property(GLOBAL PROPERTY CXX_EXCEPTIONS OFF)
set_property(GLOBAL PROPERTY CXX_RTTI OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(COMPILER_SUPPORTS_FEXCEPTIONS FALSE)

#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fpic -fno-exceptions")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic -fno-exceptions")
#add_compile_options(-fpic)
#add_compile_options(-fno-exceptions)


set(WASI_SDK_PREFIX ${WASI_SDK_PREFIX})

# Make HandleLLVMOptions.cmake happy.
# TODO(sbc): We should probably fix llvm or libcxxabi instead.
# See: https://reviews.llvm.org/D33753
# set(UNIX 1)

set(ENV{PKG_CONFIG_PATH} ${WASI_SDK_PREFIX}/share/wasi-sysroot/lib/wasm32-wasi/pkgconfig)


set(ZLIB_FOUND YES)
set(ZLIB_INCLUDE_DIR ${WASI_SDK_PREFIX}/share/wasi-sysroot/include)

set(ZLIB_LIBRARY ${WASI_SDK_PREFIX}/share/wasi-sysroot/lib/wasm32-wasi/libz.a)

set(PNG_PNG_INCLUDE_DIR ${WASI_SDK_PREFIX}/share/wasi-sysroot/include)
set(PNG_LIBRARY ${WASI_SDK_PREFIX}/share/wasi-sysroot/lib/wasm32-wasi/libpng.a)



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




set(CMAKE_EXECUTABLE_SUFFIX ".wasm")


set(CMAKE_CROSSCOMPILING_EMULATOR "${WASISDK}/bin/wasi-run" FILEPATH "Path to the emulator for the target system.")











