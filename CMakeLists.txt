cmake_minimum_required(VERSION 3.18)

cmake_policy(SET CMP0057 NEW) # Enable IN_LIST operator
cmake_policy(SET CMP0064 NEW) # Support if (TEST) operator

if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW) # Enable MSVC_RUNTIME_LIBRARY setting
endif()

PROJECT(libcat LANGUAGES C)

include(CMakePackageConfigHelpers)
include(CMakeDependentOption)
include(CheckCCompilerFlag)
include(GNUInstallDirs)
include(CTest)

macro(check_add_cflags)
    check_c_compiler_flag(${ARGV0} ${ARGV2})
    if(${ARGV2})
        list(APPEND ${ARGV1} ${ARGV0})
        set(${ARGV2} BOOL TRUE)
    else()
        set(${ARGV2} BOOL FALSE)
    endif()
endmacro()

macro(check_add_cflags_global)
    check_c_compiler_flag(${ARGV0} ${ARGV1})
    if(${ARGV1})
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGV0}")
        set (CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} ${ARGV0}")
        set(${ARGV1} BOOL TRUE)
    else()
        set(${ARGV1} BOOL FALSE)
    endif()
endmacro()

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_C_STANDARD 90)

find_package(PkgConfig)

# Qemu Build
# seems libcat is not used in qemu
#option(QEMU "build for qemu" OFF)
#if(QEMU)
#    add_definitions(-D__QEMU__=1)
#endif()

# Compiler check
message(STATUS "C Compiler is ${CMAKE_C_COMPILER_ID}")
string(CONCAT is-msvc $<OR:
    $<C_COMPILER_ID:MSVC>,
    $<STREQUAL:${CMAKE_C_COMPILER_FRONTEND_VARIANT},MSVC>
>)

set(cat_defines "")
set(cat_includes include)

set(cat_sources
    # [internal]
    src/cat_cp.c
    src/cat_memory.c
    src/cat_string.c
    src/cat_error.c
    src/cat_log.c
    src/cat_env.c
    # [public]
    src/cat.c
    src/cat_api.c
    src/cat_coroutine.c
    src/cat_channel.c
    src/cat_sync.c
    src/cat_event.c
    src/cat_poll.c
    src/cat_time.c
    src/cat_socket.c
    src/cat_dns.c
    src/cat_work.c
    src/cat_buffer.c
    src/cat_fs.c
    src/cat_signal.c
    src/cat_os_wait.c
    src/cat_async.c
    src/cat_watchdog.c
    src/cat_process.c
    src/cat_http.c
    src/cat_websocket.c
)

set(cat_libraries)

list(APPEND cat_defines HAVE_LIBCAT=1)

# prepare debug cflags
if (NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    set(CMAKE_BUILD_TYPE Debug)
    set(CAT_DEBUG 1)
    set(CAT_LINT_EXTRA TRUE)
    list(APPEND cat_defines CAT_DEBUG=1)
    if(NOT MSVC)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g3 -O0")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g3 -O0")
        check_add_cflags(-Wextra cat_cflags HAVE_LINT_WEXTRA)
        check_add_cflags(-Wno-unused-parameter cat_cflags HAVE_LINT_NO_UNUSED_PARAMETER)
        check_add_cflags(-Wbool-conversion cat_cflags HAVE_LINT_BOOL_CONVERSION)
        check_add_cflags(-Wignored-qualifiers cat_cflags HAVE_LINT_IGNORED_QUALIFIERS)
        check_add_cflags(-Wduplicate-enum cat_cflags HAVE_LINT_DUPLICATE_ENUM)
        check_add_cflags(-Wempty-body cat_cflags HAVE_LINT_EMPTY_BODY)
        check_add_cflags(-Wenum-compare cat_cflags HAVE_LINT_ENUM_COMPARE)
        check_add_cflags(-Wenum-conversion cat_cflags HAVE_LINT_ENUM_CONVERSION)
        check_add_cflags(-Wformat-security cat_cflags HAVE_LINT_FORMAT_SECURITY)
        check_add_cflags(-Wheader-guard cat_cflags HAVE_LINT_HEADER_GUARD)
        check_add_cflags(-Wincompatible-pointer-types-discards-qualifiers cat_cflags HAVE_LINT_INCOMPATIBLE_POINTER_TYPES_DISCARDS_QUALIFIERS)
        check_add_cflags(-Winit-self cat_cflags HAVE_LINT_INIT_SELF)
        check_add_cflags(-Wlogical-not-parentheses cat_cflags HAVE_LINT_LOGICAL_NOT_PARENTHESES)
        check_add_cflags(-Wlogical-op-parentheses cat_cflags HAVE_LINT_LOGICAL_OP_PARENTHESES)
        check_add_cflags(-Wloop-analysis cat_cflags HAVE_LINT_LOOP_ANALYSIS)
        check_add_cflags(-Wuninitialized cat_cflags HAVE_LINT_UNINITIALIZED)
        check_add_cflags(-Wno-missing-field-initializers cat_cflags HAVE_LINT_NO_MISSING_FIELD_INITIALIZERS)
        check_add_cflags(-Wno-sign-compare cat_cflags HAVE_LINT_NO_SIGN_COMPARE)
        check_add_cflags(-Wno-unused-const-variable cat_cflags HAVE_LINT_NO_UNUSED_CONST_VARIABLE)
        check_add_cflags(-Wno-unused-parameter cat_cflags HAVE_LINT_NO_UNUSED_PARAMETER)
        check_add_cflags(-Wno-variadic-macros cat_cflags HAVE_LINT_NO_VARIADIC_MACROS)
        check_add_cflags(-Wparentheses cat_cflags HAVE_LINT_PARENTHESES)
        check_add_cflags(-Wpointer-bool-conversion cat_cflags HAVE_LINT_POINTER_BOOL_CONVERSION)
        check_add_cflags(-Wsizeof-array-argument cat_cflags HAVE_LINT_SIZEOF_ARRAY_ARGUMENT)
        check_add_cflags(-Wwrite-strings cat_cflags HAVE_LINT_WRITE_STRINGS)
        check_add_cflags(-fdiagnostics-show-option cat_cflags HAVE_FDIAGNOSTICS_SHOW_OPTION)
        check_add_cflags(-fno-omit-frame-pointer cat_cflags HAVE_FNO-OMIT_FRAME_POINTER)
        check_add_cflags(-fno-optimize-sibling-calls cat_cflags HAVE_FNO_OPTIMIZE_SIBLING_CALLS)
        check_add_cflags(-fstack-protector cat_cflags HAVE_FSTACK_PROTECTOR)
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /Od")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Od")
        # arrange cat's debug warnings
        check_add_cflags(/W4 cat_cflags HAVE_MSVC_LINT_W4)
        check_add_cflags(/wd4820 cat_cflags HAVE_MSVC_LINT_wd4820)
        check_add_cflags(/wd4668 cat_cflags HAVE_MSVC_LINT_wd4668)
        check_add_cflags(/wd5045 cat_cflags HAVE_MSVC_LINT_wd5045)
        check_add_cflags(/wd4127 cat_cflags HAVE_MSVC_LINT_wd4127)
        check_add_cflags(/wd4201 cat_cflags HAVE_MSVC_LINT_wd4201)
        check_add_cflags(/wd4206 cat_cflags HAVE_MSVC_LINT_wd4206)
        check_add_cflags(/wd4210 cat_cflags HAVE_MSVC_LINT_wd4210)
        check_add_cflags(/wd4232 cat_cflags HAVE_MSVC_LINT_wd4232)
        check_add_cflags(/wd4245 cat_cflags HAVE_MSVC_LINT_wd4245)
        check_add_cflags(/wd4456 cat_cflags HAVE_MSVC_LINT_wd4456)
        check_add_cflags(/wd4457 cat_cflags HAVE_MSVC_LINT_wd4457)
        check_add_cflags(/wd4459 cat_cflags HAVE_MSVC_LINT_wd4459)
        check_add_cflags(/wd4464 cat_cflags HAVE_MSVC_LINT_wd4464)
        check_add_cflags(/wd4706 cat_cflags HAVE_MSVC_LINT_wd4706)
        check_add_cflags(/wd4710 cat_cflags HAVE_MSVC_LINT_wd4710)
    endif()
    check_add_cflags(-Wall cat_cflags HAVE_LINT_WALL)
else()
    if(MSVC)
        check_add_cflags(/wd4267 cat_cflags HAVE_MSVC_LINT_wd4267)
    endif()
endif()


# prepare warning cflags
if(MSVC)
    # arrange uv's warnings
    check_add_cflags(/W3 uv_cflags HAVE_MSVC_LINT_W3)
    check_add_cflags(/wd4018 uv_cflags HAVE_MSVC_LINT_wd4018)
    check_add_cflags(/wd4090 uv_cflags HAVE_MSVC_LINT_wd4090)
    check_add_cflags(/wd4100 uv_cflags HAVE_MSVC_LINT_wd4100)
    check_add_cflags(/wd4244 uv_cflags HAVE_MSVC_LINT_wd4244)
    check_add_cflags(/wd4267 uv_cflags HAVE_MSVC_LINT_wd4267)
    # C4334: https://learn.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-3-c4334?view=msvc-170
    # for code like: `procmask & (1 << i)`, `threadmask |= 1 << i`
    check_add_cflags(/wd4334 uv_cflags HAVE_MSVC_LINT_wd4334)
    check_add_cflags(/wd4819 uv_cflags HAVE_MSVC_LINT_wd4819)
    # arrange global warnings
    # for while (0, 0) in FD_SET() at Winsock2.h:
    # https://developercommunity.visualstudio.com/t/fd-clr-and-fd-set-macros-generate-warning-c4548/172702
    check_add_cflags_global(/wd4548 HAVE_MSVC_LINT_wd4548)
    check_add_cflags_global(/wd4996 HAVE_MSVC_LINT_wd4996)
    check_add_cflags_global(/utf-8 HAVE_MSVC_UTF8)
    check_add_cflags_global(/we4013 HAVE_MSVC_LINT_we4013)
else()
    check_add_cflags(-Wstrict-prototypes cat_cflags HAVE_STRICT_PROTOTYPES)
    check_add_cflags(-Werror=implicit-function-declaration cat_cflags HAVE_LINT_ERROR_IMPLICIT_FUNCTION_DECLARATION)
endif()

# ASan options
option(LIBCAT_ENABLE_ASAN "Enable AddressSanitizer (ASan)" OFF)
# TODO: TSAN support, see: https://github.com/libuv/libuv/commit/22d62239289c7c6e50e6cc4a93642b3b46bf2dad (@dixyes)

if(LIBCAT_ENABLE_ASAN)
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
        message(WARNING "ASan is not supported in release build")
        message(STATUS "ASan is not enabled")
    else()
        # asan cflags needs to be added in global cflags
        if(CMAKE_C_COMPILER_ID MATCHES "AppleClang|GNU|Clang")
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-omit-frame-pointer -fsanitize=address")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer -fsanitize=address")
            set (CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} -fno-omit-frame-pointer -fsanitize=address")
            # FIXME: the following line is synced from libuv, please check it (@dixyes)
            set (CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fno-omit-frame-pointer -fsanitize=address")
            message(STATUS "ASan is enabled by ${CMAKE_C_COMPILER_ID}")
        elseif(MSVC)
            # vs donot need linker enable asan cflags
            check_c_compiler_flag(-fsanitize=address MSVC_HAVE_ASAN_CFLAGS)
            if(NOT MSVC_HAVE_ASAN_CFLAGS)
                message(WARNING "Your visual studio donot have a workable asan, use VS 2019 atleast version 16.9 to support it.")
            else()
            message(STATUS "ASan is enabled by ${CMAKE_C_COMPILER_ID}")
                set(cflags
                    CMAKE_CXX_FLAGS
                    CMAKE_CXX_FLAGS_DEBUG
                    CMAKE_CXX_FLAGS_RELWITHDEBINFO
                    CMAKE_C_FLAGS
                    CMAKE_C_FLAGS_DEBUG
                    CMAKE_C_FLAGS_RELWITHDEBINFO)
                foreach(flag ${cflags})
                    string(REGEX REPLACE "/M[DT]d{0,1}" "/M\\1d" ${flag} "${${flag}}")
                    string(REGEX REPLACE "/Z[7iI]" "" ${flag} "${${flag}}")
                    set(${flag} "${${flag}} -fsanitize=address /MDd /Z7") # todo: MDd -> M(T|D)
                    # MSVC donot support RTC with ASan
                    string(REGEX REPLACE "/RTC(su|[1su])" "" ${flag} "${${flag}}")
                endforeach()

                set(ldflags
                    CMAKE_EXE_LINKER_FLAGS
                    CMAKE_EXE_LINKER_FLAGS_DEBUG
                    CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO)
                foreach(flag ${ldflags})
                    # disable incremental build option
                    string(REGEX REPLACE "/INCREMENTAL(\\:YES)*" "/INCREMENTAL:NO" ${flag} "${${flag}}")
                    set(${flag} "${${flag}} /debug")
                endforeach()
            endif()
        endif()
    endif()
else()
    message(STATUS "ASan is not enabled")
endif()

# ========== Context ===========
option(LIBCAT_USE_THREAD_CONTEXT "Use thread context" OFF)
if (LIBCAT_USE_THREAD_CONTEXT)
    message(STATUS "Thread-Context selected")
    list(APPEND cat_defines CAT_COROUTINE_USE_THREAD_CONTEXT=1)
else()
    set(LIBCAT_USE_BOOST_CONTEXT 1)
    if (NOT MSVC)
        enable_language(ASM)
        if(CMAKE_ASM_COMPILER_WORKS)
            message(STATUS "ASM enabled")
            message(STATUS "ASM Compiler is ${CMAKE_ASM_COMPILER_ID}")
        else()
            # TODO: use ucontext
            message(FATAL_ERROR "Enable ASM failed")
        endif(CMAKE_ASM_COMPILER_WORKS)
    else()
        set(MASMFound FALSE)
        enable_language(ASM_MASM)
        if(CMAKE_ASM_MASM_COMPILER_WORKS)
            SET(MASMFound TRUE)
            message(STATUS "ASM_MASM enabled")
            message(STATUS "ASM_MASM Compiler is ${CMAKE_ASM_MASM_COMPILER_ID}")
        else()
            message(FATAL_ERROR "Enable ASM_MASM failed")
        endif(CMAKE_ASM_MASM_COMPILER_WORKS)
    endif()
endif()
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -x assembler-with-cpp")
# ========== msvc x86 disable safeseh ==========
# if (MSVC AND "${LIBCOPP_FCONTEXT_OS_PLATFORM}" STREQUAL "i386")
#     set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SAFESEH:NO")
#     set (CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO")
#     set (CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /SAFESEH:NO")
# endif()

# ========== Detect mac info (thanks to libcopp) ==========
if (LIBCAT_USE_BOOST_CONTEXT)
    # ========== set os platform ==========
    # CAT_CPU_ARCH can be set to arm/arm64/i386/x86_64/combined/mips/ppc32/ppc64/sparc/sparc64
    if (NOT CAT_CPU_ARCH)
        if(NOT CMAKE_SYSTEM_PROCESSOR)
            set(CMAKE_SYSTEM_PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR})
        endif()
        string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} CAT_CPU_ARCH)
        if(CAT_CPU_ARCH STREQUAL "unknown" OR
            CAT_CPU_ARCH STREQUAL "i386" OR
            CAT_CPU_ARCH STREQUAL "i686" OR
            CAT_CPU_ARCH STREQUAL "x86_64" OR
            CAT_CPU_ARCH STREQUAL "amd64"
            )
            if(CMAKE_SIZEOF_VOID_P MATCHES 8)
                set(CMAKE_SYSTEM_PROCESSOR "x86_64")
                set(CAT_CPU_ARCH "x86_64")
            else()
                set(CMAKE_SYSTEM_PROCESSOR "i386")
                set(CAT_CPU_ARCH "i386")
            endif()
        elseif(
            CAT_CPU_ARCH MATCHES "^armv5" OR
            CAT_CPU_ARCH MATCHES "^armv7" OR
            CAT_CPU_ARCH MATCHES "^armeabi"
        )
            set(CAT_CPU_ARCH "arm")
        elseif(
                CAT_CPU_ARCH MATCHES "^arm64" OR
                CAT_CPU_ARCH MATCHES "^aarch64"
            )
            set(CAT_CPU_ARCH "arm64")
        elseif(
            CAT_CPU_ARCH MATCHES "^mips64" OR
            CAT_CPU_ARCH MATCHES "^mips64el" OR
            CAT_CPU_ARCH MATCHES "^mips64le"
        )
            set(CAT_CPU_ARCH "mips64")
        elseif(
            CAT_CPU_ARCH MATCHES "^riscv64" OR
        )
            set(CAT_CPU_ARCH "riscv64")
        endif()
        if (CAT_CPU_ARCH STREQUAL "unknown")
            # TODO use ucontext
            message(FATAL_ERROR RED "Can not detect the processor, please add -DCAT_CPU_ARCH=arm/arm64/i386/x86_64/combined/mips32/mips64/ppc32/ppc64 to help us to find target processor")
        endif()
    endif()
    # patch for old -DCAT_CPU_ARCH=mips to -DCAT_CPU_ARCH=mips32
    if (CAT_CPU_ARCH STREQUAL "mips")
        set(CAT_CPU_ARCH "mips32")
    endif ()
    # ========== set abi ==========
    if( CAT_CPU_ARCH STREQUAL "arm" OR CAT_CPU_ARCH STREQUAL "arm64")
        set(CAT_ABI "aapcs")
    elseif( CAT_CPU_ARCH STREQUAL "mips32" )
        set(CAT_ABI "o32")
    elseif( CAT_CPU_ARCH STREQUAL "mips64" )
        set(CAT_ABI "n64")
    elseif (WIN32 OR WINCE OR WINDOWS_PHONE OR WINDOWS_STORE OR MINGW OR CYGWIN)
        set(CAT_ABI "ms")
    else()
        set(CAT_ABI "sysv")
    endif()
    # ========== set binary format ==========
    # CAT_BINARY_FORMAT can be set to elf/macho/pe/xcoff
    if(NOT CAT_BINARY_FORMAT)
        if(WIN32 OR WINCE OR WINDOWS_PHONE OR WINDOWS_STORE OR MINGW OR CYGWIN)
            set(CAT_BINARY_FORMAT "pe")
        elseif(APPLE)
            set(CAT_BINARY_FORMAT "macho")
        elseif(AIX) # cmake not supported now
            set(CAT_BINARY_FORMAT "xcoff")
        else()
            set(CAT_BINARY_FORMAT "elf")
        endif()
    endif()
    # ========== set as tool ==========
    # CAT_ASM_TOOL can be set to gas/armasm/masm
    if(NOT CAT_ASM_TOOL)
        if(MSVC)
            if ("${CAT_CPU_ARCH}" STREQUAL "arm" OR "${CAT_CPU_ARCH}" STREQUAL "arm64")
                set(CAT_ASM_TOOL "armasm")
            else()
                set(CAT_ASM_TOOL "masm")
            endif()
        else()
            set(CAT_ASM_TOOL "gas")
        endif()
        if (WIN32 OR MINGW)
            set(CAT_COROUTINE_CONTEXT_AS_OUTPUT_SUFFIX "obj")
        else()
            set(CAT_COROUTINE_CONTEXT_AS_OUTPUT_SUFFIX "o")
        endif()
    endif()
    # ========== set suffix ==========
    if (WIN32 OR WINCE OR WINDOWS_PHONE OR WINDOWS_STORE OR MINGW OR CYGWIN)
        set(CAT_ASM_SUFFIX "asm")
    else()
        set(CAT_ASM_SUFFIX "S")
    endif()
endif()

# context dep
if (LIBCAT_USE_BOOST_CONTEXT)
    set(cat_coroutine_context_dir "deps/context/asm")
    set(cat_coroutine_context_name "${CAT_CPU_ARCH}_${CAT_ABI}_${CAT_BINARY_FORMAT}_${CAT_ASM_TOOL}.${CAT_ASM_SUFFIX}")
    message(STATUS "ASM of context is ${cat_coroutine_context_name}")
    set(cat_context_sources
        ${cat_coroutine_context_dir}/make_${cat_coroutine_context_name}
        ${cat_coroutine_context_dir}/jump_${cat_coroutine_context_name}
    )
    add_library(cat_context OBJECT ${cat_context_sources})
endif()

# libuv dep /* $Id: 97a903309f79d79496a2a1f95cbcce21bfc2f76e $ */
if (1)
    set(uv_dir "deps/libuv")

    set(uv_sources
        ${uv_dir}/src/fs-poll.c
        ${uv_dir}/src/idna.c
        ${uv_dir}/src/inet.c
        ${uv_dir}/src/random.c
        ${uv_dir}/src/strscpy.c
        ${uv_dir}/src/strtok.c
        ${uv_dir}/src/threadpool.c
        ${uv_dir}/src/timer.c
        ${uv_dir}/src/uv-common.c
        ${uv_dir}/src/uv-data-getter-setters.c
        ${uv_dir}/src/version.c)

    if(WIN32)
      list(APPEND uv_defines WIN32_LEAN_AND_MEAN _WIN32_WINNT=0x0600)
      list(APPEND uv_libraries
           psapi
           user32
           advapi32
           iphlpapi
           userenv
           ws2_32)
      list(APPEND uv_sources
           ${uv_dir}/src/win/async.c
           ${uv_dir}/src/win/core.c
           ${uv_dir}/src/win/detect-wakeup.c
           ${uv_dir}/src/win/dl.c
           ${uv_dir}/src/win/error.c
           ${uv_dir}/src/win/fs.c
           ${uv_dir}/src/win/fs-event.c
           ${uv_dir}/src/win/getaddrinfo.c
           ${uv_dir}/src/win/getnameinfo.c
           ${uv_dir}/src/win/handle.c
           ${uv_dir}/src/win/loop-watcher.c
           ${uv_dir}/src/win/pipe.c
           ${uv_dir}/src/win/thread.c
           ${uv_dir}/src/win/poll.c
           ${uv_dir}/src/win/process.c
           ${uv_dir}/src/win/process-stdio.c
           ${uv_dir}/src/win/signal.c
           ${uv_dir}/src/win/snprintf.c
           ${uv_dir}/src/win/stream.c
           ${uv_dir}/src/win/tcp.c
           ${uv_dir}/src/win/tty.c
           ${uv_dir}/src/win/udp.c
           ${uv_dir}/src/win/util.c
           ${uv_dir}/src/win/winapi.c
           ${uv_dir}/src/win/winsock.c)
    else()
      list(APPEND uv_defines _FILE_OFFSET_BITS=64 _LARGEFILE_SOURCE)
      if(NOT CMAKE_SYSTEM_NAME MATCHES "Android|OS390|QNX")
        # TODO: This should be replaced with find_package(Threads) if possible
        # Android has pthread as part of its c library, not as a separate
        # libpthread.so.
        list(APPEND uv_libraries pthread)
      endif()
      list(APPEND uv_sources
           ${uv_dir}/src/unix/async.c
           ${uv_dir}/src/unix/core.c
           ${uv_dir}/src/unix/dl.c
           ${uv_dir}/src/unix/fs.c
           ${uv_dir}/src/unix/getaddrinfo.c
           ${uv_dir}/src/unix/getnameinfo.c
           ${uv_dir}/src/unix/loop-watcher.c
           ${uv_dir}/src/unix/loop.c
           ${uv_dir}/src/unix/pipe.c
           ${uv_dir}/src/unix/poll.c
           ${uv_dir}/src/unix/process.c
           ${uv_dir}/src/unix/random-devurandom.c
           ${uv_dir}/src/unix/signal.c
           ${uv_dir}/src/unix/stream.c
           ${uv_dir}/src/unix/tcp.c
           ${uv_dir}/src/unix/thread.c
           ${uv_dir}/src/unix/tty.c
           ${uv_dir}/src/unix/udp.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "AIX")
      list(APPEND uv_defines
           _ALL_SOURCE
           _LINUX_SOURCE_COMPAT
           _THREAD_SAFE
           _XOPEN_SOURCE=500
           HAVE_SYS_AHAFS_EVPRODS_H)
      list(APPEND uv_libraries perfstat)
      list(APPEND uv_sources
           ${uv_dir}/src/unix/aix.c
           ${uv_dir}/src/unix/aix-common.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Android")
      list(APPEND uv_defines _GNU_SOURCE)
      list(APPEND uv_libraries dl)
      list(APPEND uv_sources
           ${uv_dir}/src/unix/linux.c
           ${uv_dir}/src/unix/procfs-exepath.c
           ${uv_dir}/src/unix/random-getentropy.c
           ${uv_dir}/src/unix/random-getrandom.c
           ${uv_dir}/src/unix/random-sysctl-linux.c)
    endif()

    if(APPLE OR CMAKE_SYSTEM_NAME MATCHES "Android|Linux|OS390")
      list(APPEND uv_sources ${uv_dir}/src/unix/proctitle.c)
    endif()

    if(CMAKE_SYSTEM_NAME MATCHES "DragonFly|FreeBSD")
      list(APPEND uv_sources ${uv_dir}/ ${uv_dir}/src/unix/freebsd.c)
    endif()

    if(CMAKE_SYSTEM_NAME MATCHES "DragonFly|FreeBSD|NetBSD|OpenBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/posix-hrtime.c ${uv_dir}/src/unix/bsd-proctitle.c)
    endif()

    if(APPLE OR CMAKE_SYSTEM_NAME MATCHES "DragonFly|FreeBSD|NetBSD|OpenBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/bsd-ifaddrs.c ${uv_dir}/src/unix/kqueue.c)
    endif()

    if(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/random-getrandom.c)
    endif()

    if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/random-getentropy.c)
    endif()

    if(APPLE)
      list(APPEND uv_defines _DARWIN_UNLIMITED_SELECT=1 _DARWIN_USE_64_BIT_INODE=1)
      list(APPEND uv_sources
           ${uv_dir}/src/unix/darwin-proctitle.c
           ${uv_dir}/src/unix/darwin.c
           ${uv_dir}/src/unix/fsevents.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "GNU")
      list(APPEND uv_libraries dl)
      list(APPEND uv_sources
           src/unix/bsd-ifaddrs.c
           src/unix/no-fsevents.c
           src/unix/no-proctitle.c
           src/unix/posix-hrtime.c
           src/unix/posix-poll.c
           src/unix/hurd.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "kFreeBSD")
      list(APPEND uv_defines _GNU_SOURCE)
      list(APPEND uv_libraries dl freebsd-glue)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      list(APPEND uv_defines _GNU_SOURCE _POSIX_C_SOURCE=200112)
      list(APPEND uv_libraries dl rt)
      list(APPEND uv_sources
           ${uv_dir}/src/unix/linux.c
           ${uv_dir}/src/unix/procfs-exepath.c
           ${uv_dir}/src/unix/random-getrandom.c
           ${uv_dir}/src/unix/random-sysctl-linux.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/netbsd.c)
      list(APPEND uv_libraries kvm)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
      list(APPEND uv_sources ${uv_dir}/src/unix/openbsd.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "OS390")
      list(APPEND uv_defines PATH_MAX=255)
      list(APPEND uv_defines _AE_BIMODAL)
      list(APPEND uv_defines _ALL_SOURCE)
      list(APPEND uv_defines _ISOC99_SOURCE)
      list(APPEND uv_defines _LARGE_TIME_API)
      list(APPEND uv_defines _OPEN_MSGQ_EXT)
      list(APPEND uv_defines _OPEN_SYS_FILE_EXT)
      list(APPEND uv_defines _OPEN_SYS_IF_EXT)
      list(APPEND uv_defines _OPEN_SYS_SOCK_EXT3)
      list(APPEND uv_defines _OPEN_SYS_SOCK_IPV6)
      list(APPEND uv_defines _UNIX03_SOURCE)
      list(APPEND uv_defines _UNIX03_THREADS)
      list(APPEND uv_defines _UNIX03_WITHDRAWN)
      list(APPEND uv_defines _XOPEN_SOURCE_EXTENDED)
      list(APPEND uv_sources
           ${uv_dir}/src/unix/os390.c
           ${uv_dir}/src/unix/os390-syscalls.c
           ${uv_dir}src/unix/os390-proctitle.c)
      list(APPEND uv_cflags -Wc,DLL -Wc,exportall -Wc,xplink)
      list(APPEND uv_libraries -Wl,xplink)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "OS400")
      list(APPEND uv_defines
           _ALL_SOURCE
           _LINUX_SOURCE_COMPAT
           _THREAD_SAFE
           _XOPEN_SOURCE=500)
      list(APPEND uv_sources
        ${uv_dir}/src/unix/aix-common.c
        ${uv_dir}/src/unix/ibmi.c
        ${uv_dir}/src/unix/no-fsevents.c
        ${uv_dir}/src/unix/posix-poll.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "SunOS")
      list(APPEND uv_defines __EXTENSIONS__ _XOPEN_SOURCE=500 _REENTRANT)
      list(APPEND uv_libraries kstat nsl sendfile socket)
      list(APPEND uv_sources
        ${uv_dir}/src/unix/no-proctitle.c
        ${uv_dir}/src/unix/sunos.c)
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Haiku")
      list(APPEND uv_defines _BSD_SOURCE)
      list(APPEND uv_libraries bsd network)
      list(APPEND uv_sources
          ${uv_dir}/src/unix/haiku.c
          ${uv_dir}/src/unix/bsd-ifaddrs.c
          ${uv_dir}/src/unix/no-fsevents.c
          ${uv_dir}/src/unix/no-proctitle.c
          ${uv_dir}/src/unix/posix-hrtime.c
          ${uv_dir}/src/unix/posix-poll.c)
    endif()

    # TODO: include => public, src => private
    set(uv_includes ${uv_dir}/include ${uv_dir}/src)

    add_library(cat_uv OBJECT ${uv_sources})

    if(MSVC)
        set_property(TARGET cat_uv PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    list(APPEND cat_defines ${uv_defines})
    target_compile_definitions(cat_uv PRIVATE ${cat_defines})
    target_compile_options(cat_uv PRIVATE ${uv_cflags})
    list(APPEND cat_includes ${uv_includes})
    target_include_directories(cat_uv PRIVATE ${uv_includes})
    list(APPEND cat_libraries ${uv_libraries})
endif()

# Valgrind headers and libraries finder (UNIX-like only)
#
# Usage of this module as follows:
#     find_package(Valgrind)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
# VALGRIND_ROOT Set this variable to the root installation of valgrind if the
# module has problems finding the proper installation path.
#
# Variables defined by this module:
#     Valgrind_FOUND System has valgrind
#     Valgrind_INCLUDE_DIR where to find valgrind/memcheck.h, etc.
#     Valgrind_EXECUTABLE the valgrind executable.
# Get hint from environment variable (if any)
if(NOT WIN32)
    if(NOT VALGRIND_ROOT)
        if (DEFINED ENV{VALGRIND_ROOT})
            set(VALGRIND_ROOT "$ENV{VALGRIND_ROOT}" CACHE PATH "Valgrind base directory location (optional, used for nonstandard installation paths)")
        else()
            set(VALGRIND_ROOT "/usr/")
        endif()
        mark_as_advanced(VALGRIND_ROOT)
    endif()
    # Search path for nonstandard locations
    if(VALGRIND_ROOT)
        set(Valgrind_INCLUDE_PATH PATHS "${VALGRIND_ROOT}/include" NO_DEFAULT_PATH)
        set(Valgrind_BINARY_PATH PATHS "${VALGRIND_ROOT}/bin" NO_DEFAULT_PATH)
    endif()
    find_path(Valgrind_INCLUDE_DIR valgrind HINTS ${Valgrind_INCLUDE_PATH})
    find_program(Valgrind_EXECUTABLE NAMES valgrind PATH ${Valgrind_BINARY_PATH})
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(Valgrind DEFAULT_MSG Valgrind_INCLUDE_DIR Valgrind_EXECUTABLE)
    mark_as_advanced(Valgrind_INCLUDE_DIR Valgrind_EXECUTABLE)
endif()

# Valgrind dep (UNIX-like only)
if (NOT WIN32)
    find_package(Valgrind QUIET)
    cmake_dependent_option(LIBCAT_WITH_VALGRIND
        "Build with valgrind by default if build type is Debug and found Valgrind" ON
        "CAT_DEBUG; VALGRIND_FOUND"
        OFF)
    if (LIBCAT_WITH_VALGRIND)
        if (NOT VALGRIND_FOUND)
            message(FATAL_ERROR "Require Valgrind but not found")
        endif()
        message(STATUS "Build with Valgrind")
        list(APPEND cat_defines CAT_HAVE_VALGRIND=1)
        list(APPEND cat_includes ${VALGRIND_INCLUDE_DIR})
    else()
        message(STATUS "Build without Valgrind")
    endif()
endif()

# llhttp dep
if (1)
    set(llhttp_dir "deps/llhttp")
    add_library(cat_llhttp OBJECT
        ${llhttp_dir}/src/api.c
        ${llhttp_dir}/src/http.c
        ${llhttp_dir}/src/llhttp.c
    )
    if(MSVC)
        set_property(TARGET cat_llhttp PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
    list(APPEND cat_includes ${llhttp_dir}/include)
    target_include_directories(cat_llhttp PRIVATE ${llhttp_dir}/include)
endif()

# multipart-parser-c dep
if (1)
    set(multipart_parser_dir "deps/multipart-parser-c")
    add_library(cat_multipart_parser OBJECT
        ${multipart_parser_dir}/multipart_parser.c
    )
    if(MSVC)
        set_property(TARGET cat_multipart_parser PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
    list(APPEND cat_includes ${multipart_parser_dir})
    target_include_directories(cat_multipart_parser PRIVATE ${multipart_parser_dir})
endif()

# Thread safe

option(LIBCAT_USE_THREAD_LOCAL "Use thread_local for global vars" OFF)
if (LIBCAT_USE_THREAD_LOCAL)
    set(CAT_THREAD_SAFE "THREAD_LOCAL")
    list(APPEND cat_defines CAT_USE_THREAD_LOCAL=1)
endif()

option(LIBCAT_USE_THREAD_KEY "Use uv_key for global vars" OFF)
if (LIBCAT_USE_THREAD_KEY)
    if (CAT_THREAD_SAFE)
        message(WARNING "Another thread-safe option ${CAT_THREAD_SAFE} is on, THREAD_KEY option will be skipped")
    else()
        set(CAT_THREAD_SAFE "THREAD_KEY")
        list(APPEND cat_defines CAT_USE_THREAD_KEY=1)
    endif()
endif()

if (CAT_THREAD_SAFE)
    if (LIBCAT_USE_THREAD_CONTEXT)
        message(FATAL_ERROR "Thread-safe mode and coroutine thread-context can not be enabled at the same time")
    endif()
    message(STATUS "Thread-safe mode is enabled with ${CAT_THREAD_SAFE}")
else()
    message(STATUS "Thread-safe mode is disabled (by default)")
endif()

# OpenSSL dep
find_package(OpenSSL QUIET)
if (NOT OPENSSL_FOUND AND PkgConfig_FOUND)
    pkg_check_modules(OPENSSL openssl QUIET)
endif()
if (APPLE AND NOT OPENSSL_INCLUDE_DIR)
    message(WARNING "OpenSSL shipped with macOS cannot be used, please install openssl from brew and set environment variables")
    set(OPENSSL_FOUND NOTFOUND)
endif()
cmake_dependent_option(LIBCAT_ENABLE_OPENSSL
    "Enable OpenSSL if found"
    ON OPENSSL_FOUND
    OFF)
if (LIBCAT_ENABLE_OPENSSL)
    if (NOT OPENSSL_FOUND)
        message(FATAL_ERROR "Require OpenSSL but not found")
    endif()
    message(STATUS "Enable OpenSSL")
    list(APPEND cat_defines CAT_HAVE_OPENSSL=1)
    list(APPEND cat_includes ${OPENSSL_INCLUDE_DIR})
    list(APPEND cat_libraries ${OPENSSL_LIBRARIES})
    list(APPEND cat_sources src/cat_ssl.c)
    if(MSVC)
        list(APPEND cat_libraries crypt32.lib)
    endif()
else()
    find_package(OpenSSL) # throw warning
    message(STATUS "OpenSSL is not enabled")
endif()

# cURL dep
find_package(CURL QUIET)
if (NOT CURL_FOUND AND PkgConfig_FOUND)
    pkg_check_modules(CURL libcurl QUIET)
endif()
cmake_dependent_option(LIBCAT_ENABLE_CURL
    "Enable cURL if found"
    ON CURL_FOUND
    OFF)
if (LIBCAT_ENABLE_CURL)
    if (NOT CURL_FOUND)
        message(FATAL_ERROR "Require cURL but not found")
    endif()
    message(STATUS "Enable cURL")
    list(APPEND cat_defines CAT_HAVE_CURL=1)
    list(APPEND cat_includes ${CURL_INCLUDE_DIR})
    list(APPEND cat_libraries ${CURL_LIBRARIES})
    list(APPEND cat_sources src/cat_curl.c)
else()
    find_package(CURL) # throw warning
    message(STATUS "cURL is not enabled")
endif()

# pq dep
find_package(PostgreSQL QUIET)
if(NOT PostgreSQL_FOUND AND PkgConfig_FOUND)
    pkg_check_modules(PostgreSQL libpq QUIET)
    if(PostgreSQL_FOUND)
        set(PostgreSQL_LIBRARIES ${PostgreSQL_LINK_LIBRARIES})
    endif()
endif()

cmake_dependent_option(LIBCAT_ENABLE_POSTGRESQL
    "Enable PostgreSQL if found"
    ON PostgreSQL_FOUND
    OFF)
if (LIBCAT_ENABLE_POSTGRESQL)
    if (NOT PostgreSQL_FOUND)
        message(FATAL_ERROR "Require PostgreSQL but not found")
    endif()
    message(STATUS "Enable PostgreSQL")
    list(APPEND cat_defines CAT_HAVE_PQ=1)
    
    list(APPEND cat_includes ${PostgreSQL_INCLUDE_DIRS})
    list(APPEND cat_libraries ${PostgreSQL_LIBRARIES})
    list(APPEND cat_sources src/cat_pq.c)
else()
    find_package(PostgreSQL) # throw warning
    message(STATUS "PostgreSQL is not enabled")
endif()

set(cat_target_objects "")
if (LIBCAT_USE_BOOST_CONTEXT)
    list(APPEND cat_target_objects $<TARGET_OBJECTS:cat_context>)
endif()
list(APPEND cat_target_objects $<TARGET_OBJECTS:cat_uv>)
list(APPEND cat_target_objects $<TARGET_OBJECTS:cat_llhttp>)
list(APPEND cat_target_objects $<TARGET_OBJECTS:cat_multipart_parser>)
add_library(cat STATIC ${cat_target_objects} ${cat_sources})
if(MSVC)
    set_property(TARGET cat PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

target_compile_definitions(cat PRIVATE ${cat_defines})
target_compile_options(cat PRIVATE ${cat_cflags})
# TODO: Separate public and private
target_include_directories(cat PRIVATE ${cat_includes})
target_link_libraries(cat ${cat_libraries})

# Code Coverage Configuration (unix-like)
# TODO: support windows
if(NOT MSVC)
    add_library(coverage_config INTERFACE)
    option(CODE_COVERAGE "Enable coverage reporting" OFF)
    if(CODE_COVERAGE)
        target_compile_options(coverage_config INTERFACE
            -O0
            -g
            --coverage
        )
        if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.13)
            target_link_options(coverage_config INTERFACE --coverage)
        else()
            target_link_libraries(coverage_config INTERFACE --coverage)
        endif()
    endif()
    target_link_libraries(cat coverage_config)
endif()

# tests
find_package(GTest QUIET)
if (NOT GTEST_FOUND AND PkgConfig_FOUND)
    pkg_check_modules(CAT_GTEST_MAIN gtest_main QUIET)
    pkg_check_modules(CAT_GTEST gtest QUIET)
else()
    set(CAT_GTEST_MAIN_LIBRARIES "GTest::Main")
    set(CAT_GTEST_LIBRARIES "GTest::GTest")
endif()
if (GTEST_FOUND)
message(STATUS "GTest founded")
else()
message(STATUS "GTest not found")
endif()
cmake_dependent_option(LIBCAT_BUILD_TESTS
    "Build the GTest-based unit tests when we have GTest and we are the root project"
    ON GTEST_FOUND
    OFF)
if (LIBCAT_BUILD_TESTS)
    if (NOT GTEST_FOUND AND NOT (CAT_GTEST_FOUND AND CAT_GTEST_MAIN_FOUND))
        message(FATAL_ERROR "Require GTest to build tests but not found")
    endif()
    message(STATUS "Enable testing (GTest-based)")
    enable_testing()
    enable_language(CXX)
    if(NOT MSVC)
        set(cat_cxxflags ${cat_cflags} -std=c++14 -Wall)
    else()
        set(cat_cxxflags ${cat_cflags} /std:c++latest /EHsc)
        #check_add_cflags(/wd5039 cat_cxxflags HAVE_MSVC_LINT_wd5039)
        list(REMOVE_ITEM cat_cxxflags /W4)
        list(REMOVE_ITEM cat_cxxflags -Wall)
    endif()
    list(REMOVE_ITEM cat_cxxflags -Werror=implicit-function-declaration)
    list(REMOVE_ITEM cat_cxxflags -Wstrict-prototypes)

    message(STATUS "C++ Compiler is ${CMAKE_CXX_COMPILER_ID}")
    set(cat_test_sources
        tests/test.cc
        tests/test_cat.cc
        tests/test_cat_memory.cc
        tests/test_cat_string.cc
        tests/test_cat_error.cc
        tests/test_cat_log.cc
        tests/test_cat_env.cc
        tests/test_cat_coroutine.cc
        tests/test_cat_event.cc
        tests/test_cat_poll.cc
        tests/test_cat_time.cc
        tests/test_cat_channel.cc
        tests/test_cat_sync.cc
        tests/test_cat_socket.cc
        tests/test_cat_dns.cc
        tests/test_cat_work.cc
        tests/test_cat_buffer.cc
        tests/test_cat_fs.cc
        tests/test_cat_signal.cc
        tests/test_cat_os_wait.cc
        tests/test_cat_async.cc
        tests/test_cat_watchdog.cc
        tests/test_cat_process.cc
        tests/test_cat_atomic.cc
        tests/test_cat_http.cc
        tests/test_cat_websocket.cc
    )
    if (LIBCAT_ENABLE_OPENSSL)
        list(APPEND cat_test_sources tests/test_cat_ssl.cc)
    endif()
    if (LIBCAT_ENABLE_CURL)
        list(APPEND cat_test_sources tests/test_cat_curl.cc)
    endif()
    if (LIBCAT_ENABLE_POSTGRESQL)
        list(APPEND cat_test_sources tests/test_cat_pq.cc)
    endif()
    add_executable(cat_tests ${cat_test_sources})
    if(MSVC)
        set_property(TARGET cat_tests PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
    target_compile_definitions(cat_tests PRIVATE ${cat_defines})
    target_compile_options(cat_tests PRIVATE ${cat_cxxflags})
    target_include_directories(cat_tests PRIVATE /tests/test.h ${cat_includes} ${GTEST_INCLUDE_DIRS})
    # NOTE: gtest may needs gtest_main before its linking (on windows), that's strange
    target_link_libraries(cat_tests PRIVATE cat ${CAT_GTEST_MAIN_LIBRARIES} ${CAT_GTEST_LIBRARIES})
    add_test(
        NAME cat_tests
        COMMAND $<TARGET_FILE:cat_tests> --gtest_color=yes
    )
else()
    message(STATUS "Tests will not be built")
endif()

message(STATUS "Summary of build options:
    Install prefix:  ${CMAKE_INSTALL_PREFIX}
    Target system:   ${CMAKE_SYSTEM_NAME}
    Compiler:
      C Compiler:    ${CMAKE_C_COMPILER} (${CMAKE_C_COMPILER_ID})
      C++ Compiler:  ${CMAKE_CXX_COMPILER} (${CMAKE_CXX_COMPILER_ID})
      CFLAGS:        ${CMAKE_C_FLAGS}
      CXXFLAGS:      ${CMAKE_CXX_FLAGS}
      cat CFLAGS:    ${cat_cflags}
      cat CXXFLAGS:  ${cat_cxxflags}
      cat DEFINES:   ${cat_defines}
      cat INCLUDES:  ${cat_includes}
      cat LIBRARIES: ${cat_libraries}
    Build type:      ${CMAKE_BUILD_TYPE}
")
