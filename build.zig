const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("tilegame", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    
    if(true) {
        exe.addIncludeDir("deps/");
        exe.addObjectFile("deps/libraylib.a");
        exe.addIncludeDir("src/raylib");
        
        if(target.isDarwin()) {
            exe.linkFramework("CoreVideo");
            exe.linkFramework("IOKit");
            exe.linkFramework("Cocoa");
            exe.linkFramework("GLUT");
            exe.linkFramework("OpenGL");
        }
    }else{
        exe.linkSystemLibrary("raylib");
    }
    //exe.addCSourceFile("src/raylib/workaround.h", &.{"-Dworkaround_implementation"}); // it crashes? idk why
    exe.addCSourceFile("src/raylib/workaround.c", &.{});
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
