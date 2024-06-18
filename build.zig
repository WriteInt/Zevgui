const std = @import("std");

pub fn build(b: *std.Build) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "lib",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    switch (target.result.os.tag) {
        .linux => {
            const gtkV = std.process.getEnvVarOwned(allocator, "GTK") catch @panic("no gtk version specified/reachable!");
            const vGtkInt = std.fmt.parseInt(i16, gtkV, 10) catch @panic("GTK version has to be either 3 or 4!");

            if (vGtkInt == 4) {
                const gui = b.addModule("frontend", .{ .target = target, .optimize = optimize, .root_source_file = .{ .cwd_relative = "src/lib/linux/gtk4/library.zig" } });
                gui.linkSystemLibrary("gtk-4", .{});
                gui.linkSystemLibrary("webkitgtk-6.0", .{});

                exe.root_module.addImport("frontend", gui);
            } else if (vGtkInt == 3) {
                const gui = b.addModule("frontend", .{ .target = target, .optimize = optimize, .root_source_file = .{ .cwd_relative = "src/lib/linux/gtk3/library.zig" } });
                gui.linkSystemLibrary("gtk+-3.0", .{});
                gui.linkSystemLibrary("webkit2gtk-4.0", .{});

                exe.root_module.addImport("frontend", gui);
            } else {
                @panic("GTK version has to be either 3 or 4!");
            }
        },
        else => {},
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}