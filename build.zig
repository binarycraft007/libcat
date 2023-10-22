const std = @import("std");
const path = std.fs.path;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "cat",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    const t = lib.target_info.target;
    if (optimize == .Debug) {
        lib.defineCMacro("CAT_DEBUG", "1");
    }
    lib.defineCMacro("HAVE_LIBCAT", "1");
    inline for (cat_src_files) |src_file| {
        lib.addCSourceFile(.{
            .file = .{ .path = src_file },
            .flags = &.{
                "-std=gnu11",
                "-Wno-incompatible-function-pointer-types",
            },
        });
    }
    inline for (uv_src_files) |src_file| {
        lib.addCSourceFile(.{
            .file = .{ .path = src_file },
            .flags = &.{"-std=gnu11"},
        });
    }
    if (t.os.tag == .windows) {
        if (t.cpu.arch == .x86_64) {
            inline for (windows_x86_64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
        if (t.cpu.arch == .aarch64) {
            inline for (windows_aarch64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
        lib.linkSystemLibrary("psapi");
        lib.linkSystemLibrary("user32");
        lib.linkSystemLibrary("advapi32");
        lib.linkSystemLibrary("iphlpapi");
        lib.linkSystemLibrary("userenv");
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("ntdll");
        lib.defineCMacro("CAT_USE_THREAD_KEY", "1");
        lib.defineCMacro("_WIN32_WINNT", "0x0600");
        lib.defineCMacro("WIN32_LEAN_AND_MEAN", "");
        inline for (windows_src_files) |src_file| {
            lib.addCSourceFile(.{
                .file = .{ .path = src_file },
                .flags = &.{"-std=gnu11"},
            });
        }
    } else {
        lib.defineCMacro("CAT_USE_THREAD_LOCAL", "1");
        if (t.abi != .android) {
            lib.linkSystemLibrary("pthread");
        }
        inline for (unix_src_files) |src_file| {
            lib.addCSourceFile(.{
                .file = .{ .path = src_file },
                .flags = &.{"-std=gnu11"},
            });
        }
    }
    if (t.os.tag == .macos) {
        lib.defineCMacro("_DARWIN_UNLIMITED_SELECT", "1");
        lib.defineCMacro("_DARWIN_USE_64_BIT_INODE", "1");
        inline for (darwin_src_files) |src_file| {
            lib.addCSourceFile(.{
                .file = .{ .path = src_file },
                .flags = &.{"-std=gnu11"},
            });
        }
        if (t.cpu.arch == .aarch64) {
            inline for (macos_aarch64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
        if (t.cpu.arch == .x86_64) {
            inline for (macos_x86_64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
    }
    if (t.os.tag == .linux) {
        if (t.abi == .android) {
            lib.defineCMacro("_GNU_SOURCE", "");
            lib.linkSystemLibrary("rt");
            inline for (android_src_files) |src_file| {
                lib.addCSourceFile(.{
                    .file = .{ .path = src_file },
                    .flags = &.{"-std=gnu11"},
                });
            }
        }
        lib.linkSystemLibrary("rt");
        lib.linkSystemLibrary("dl");
        lib.defineCMacro("_GNU_SOURCE", "");
        lib.defineCMacro("_POSIX_C_SOURCE", "200112");
        inline for (linux_src_files) |src_file| {
            lib.addCSourceFile(.{
                .file = .{ .path = src_file },
                .flags = &.{"-std=gnu11"},
            });
        }
        if (t.cpu.arch == .aarch64) {
            inline for (linux_aarch64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
        if (t.cpu.arch == .x86_64) {
            inline for (linux_x86_64_asm) |src_file| {
                lib.addAssemblyFile(.{ .path = src_file });
            }
        }
    }
    inline for (llhttp_src_files) |src_file| {
        lib.addCSourceFile(.{
            .file = .{ .path = src_file },
            .flags = &.{"-std=gnu11"},
        });
    }
    inline for (parser_src_files) |src_file| {
        lib.addCSourceFile(.{
            .file = .{ .path = src_file },
            .flags = &.{"-std=gnu11"},
        });
    }
    lib.addIncludePath(.{ .path = "include" });
    lib.addIncludePath(.{ .path = "deps/libuv/src" });
    lib.addIncludePath(.{ .path = "deps/llhttp/include" });
    lib.addIncludePath(.{ .path = "deps/libuv/include" });
    lib.addIncludePath(.{ .path = "deps/multipart-parser-c" });
    lib.installHeadersDirectory("deps/multipart-parser-c", "");
    lib.installHeadersDirectory("deps/llhttp/include", "");
    lib.installHeadersDirectory("deps/libuv/include", "");
    lib.installHeadersDirectory("include", "");
    b.installArtifact(lib);

    inline for (example_src_files) |src_file| {
        var it = try path.componentIterator(src_file);
        _ = it.last(); // to last component
        const exe = b.addExecutable(.{
            .name = it.previous().?.name,
            .target = target,
            .optimize = optimize,
        });
        if (optimize == .Debug) {
            exe.defineCMacro("CAT_DEBUG", "1");
        }
        exe.defineCMacro("HAVE_LIBCAT", "1");
        exe.defineCMacro("CAT_MAGIC_BACKLOG", "8192");
        exe.defineCMacro("CAT_MAGIC_PORT", "9764");
        exe.addCSourceFile(.{
            .file = .{ .path = src_file },
            .flags = &.{"-std=gnu11"},
        });
        exe.linkLibrary(lib);
        b.installArtifact(exe);
    }

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/test.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.linkLibrary(lib);

    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}

const cat_src_files = [_][]const u8{
    // [internal]
    "src/cat_cp.c",
    "src/cat_memory.c",
    "src/cat_string.c",
    "src/cat_error.c",
    "src/cat_tsrm.c",
    "src/cat_log.c",
    "src/cat_env.c",
    // [public]
    "src/cat.c",
    "src/cat_api.c",
    "src/cat_coroutine.c",
    "src/cat_channel.c",
    "src/cat_sync.c",
    "src/cat_event.c",
    "src/cat_poll.c",
    "src/cat_time.c",
    "src/cat_socket.c",
    "src/cat_dns.c",
    "src/cat_work.c",
    "src/cat_buffer.c",
    "src/cat_fs.c",
    "src/cat_signal.c",
    "src/cat_os_wait.c",
    "src/cat_async.c",
    "src/cat_watchdog.c",
    "src/cat_process.c",
    "src/cat_http.c",
    "src/cat_websocket.c",
};

const uv_src_files = [_][]const u8{
    "deps/libuv/src/fs-poll.c",
    "deps/libuv/src/idna.c",
    "deps/libuv/src/inet.c",
    "deps/libuv/src/random.c",
    "deps/libuv/src/strscpy.c",
    "deps/libuv/src/strtok.c",
    "deps/libuv/src/threadpool.c",
    "deps/libuv/src/timer.c",
    "deps/libuv/src/uv-common.c",
    "deps/libuv/src/uv-data-getter-setters.c",
    "deps/libuv/src/version.c",
};

const windows_src_files = [_][]const u8{
    "deps/libuv/src/win/async.c",
    "deps/libuv/src/win/core.c",
    "deps/libuv/src/win/detect-wakeup.c",
    "deps/libuv/src/win/dl.c",
    "deps/libuv/src/win/error.c",
    "deps/libuv/src/win/fs.c",
    "deps/libuv/src/win/fs-event.c",
    "deps/libuv/src/win/getaddrinfo.c",
    "deps/libuv/src/win/getnameinfo.c",
    "deps/libuv/src/win/handle.c",
    "deps/libuv/src/win/loop-watcher.c",
    "deps/libuv/src/win/pipe.c",
    "deps/libuv/src/win/thread.c",
    "deps/libuv/src/win/poll.c",
    "deps/libuv/src/win/process.c",
    "deps/libuv/src/win/process-stdio.c",
    "deps/libuv/src/win/signal.c",
    "deps/libuv/src/win/snprintf.c",
    "deps/libuv/src/win/stream.c",
    "deps/libuv/src/win/tcp.c",
    "deps/libuv/src/win/tty.c",
    "deps/libuv/src/win/udp.c",
    "deps/libuv/src/win/util.c",
    "deps/libuv/src/win/winapi.c",
    "deps/libuv/src/win/winsock.c",
};

const unix_src_files = [_][]const u8{
    "deps/libuv/src/unix/async.c",
    "deps/libuv/src/unix/core.c",
    "deps/libuv/src/unix/dl.c",
    "deps/libuv/src/unix/fs.c",
    "deps/libuv/src/unix/getaddrinfo.c",
    "deps/libuv/src/unix/getnameinfo.c",
    "deps/libuv/src/unix/loop-watcher.c",
    "deps/libuv/src/unix/loop.c",
    "deps/libuv/src/unix/pipe.c",
    "deps/libuv/src/unix/poll.c",
    "deps/libuv/src/unix/process.c",
    "deps/libuv/src/unix/random-devurandom.c",
    "deps/libuv/src/unix/signal.c",
    "deps/libuv/src/unix/stream.c",
    "deps/libuv/src/unix/tcp.c",
    "deps/libuv/src/unix/thread.c",
    "deps/libuv/src/unix/tty.c",
    "deps/libuv/src/unix/udp.c",

    "deps/libuv/src/unix/proctitle.c",
};

const android_src_files = [_][]const u8{
    "deps/libuv/src/unix/linux.c",
    "deps/libuv/src/unix/procfs-exepath.c",
    "deps/libuv/src/unix/random-getentropy.c",
    "deps/libuv/src/unix/random-getrandom.c",
    "deps/libuv/src/unix/random-sysctl-linux.c",
};

const darwin_src_files = [_][]const u8{
    "deps/libuv/src/unix/darwin-proctitle.c",
    "deps/libuv/src/unix/darwin.c",
    "deps/libuv/src/unix/fsevents.c",
    "deps/libuv/src/unix/bsd-ifaddrs.c",
    "deps/libuv/src/unix/kqueue.c",
    "deps/libuv/src/unix/random-getentropy.c",
};

const linux_src_files = [_][]const u8{
    "deps/libuv/src/unix/linux.c",
    "deps/libuv/src/unix/procfs-exepath.c",
    "deps/libuv/src/unix/random-getrandom.c",
    "deps/libuv/src/unix/random-sysctl-linux.c",
};

const llhttp_src_files = [_][]const u8{
    "deps/llhttp/src/api.c",
    "deps/llhttp/src/http.c",
    "deps/llhttp/src/llhttp.c",
};

const parser_src_files = [_][]const u8{
    "deps/multipart-parser-c/multipart_parser.c",
};

const linux_x86_64_asm = [_][]const u8{
    "deps/context/asm/make_x86_64_sysv_elf_gas.S",
    "deps/context/asm/jump_x86_64_sysv_elf_gas.S",
};

const linux_aarch64_asm = [_][]const u8{
    "deps/context/asm/make_arm64_aapcs_elf_gas.S",
    "deps/context/asm/jump_arm64_aapcs_elf_gas.S",
};

const macos_aarch64_asm = [_][]const u8{
    "deps/context/asm/make_arm64_aapcs_macho_gas.S",
    "deps/context/asm/jump_arm64_aapcs_macho_gas.S",
};

const macos_x86_64_asm = [_][]const u8{
    "deps/context/asm/make_x86_64_sysv_macho_gas.S",
    "deps/context/asm/jump_x86_64_sysv_macho_gas.S",
};

const windows_x86_64_asm = [_][]const u8{
    "deps/context/asm/make_x86_64_ms_pe_clang_gas.S",
    "deps/context/asm/jump_x86_64_ms_pe_clang_gas.S",
};

const windows_aarch64_asm = [_][]const u8{
    "deps/context/asm/make_arm64_aapcs_pe_gas.S",
    "deps/context/asm/jump_arm64_aapcs_pe_gas.S",
};

const example_src_files = [_][]const u8{
    "examples/dns/getaddrinfo/main.c",
    "examples/http_parser/http_parser.c",
    "examples/socket/cross_close/connecting/main.c",
    "examples/socket/server/http_echo/main.c",
};
