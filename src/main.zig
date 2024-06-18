const std = @import("std");
const frontend = @import("frontend");

const onReady = struct {
    pub fn onReady(app: *frontend) void {
        app.setTitle("Hello, World!");
        app.setSize(800, 600, .NONE);
        app.loadURI("https://google.com/");
        app.show();
    }
}.onReady;

pub fn main() !void {
    var app = frontend.create(.{ .identifier = "com.rendre.xyz", .hidden = false, .onActivate = &onReady, .resizable = false });
    defer app.destroy();

    app.run();

    std.debug.print("{any}\n", .{app});
}