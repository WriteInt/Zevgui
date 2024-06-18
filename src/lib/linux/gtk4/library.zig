app: [*c]gtk.GtkApplication,

const std = @import("std");
const gtk = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("webkit/webkit.h");
});

pub const Self = @This();

const WindowSizeHint = enum {
    NONE,
    MIN, // TODO
    MAX, // TODO
    FIXED,
};

var _WINDOW: ?[*c]gtk.GtkWidget = null;
var WINDOW: ?*gtk.GtkWindow = null;
var _WEBVIEW: ?[*c]gtk.WebKitWebView = null;
var WEBVIEW: ?*gtk.GtkWidget = null; // This would have to redesigned once multi-webviews are ready.

var hiddenByDefault: bool = true;
var onActivate: ?*const fn (self: *Self) void = null;
var isResizable: bool = true;

pub const Options = struct { identifier: [*c]const u8, hidden: bool = true, onActivate: *const fn (self: *Self) void, resizable: bool = true };

pub fn create(opts: Options) Self {
    const app = gtk.gtk_application_new(opts.identifier, gtk.G_APPLICATION_FLAGS_NONE) orelse @panic("null app! :(");

    hiddenByDefault = opts.hidden;
    onActivate = opts.onActivate;
    isResizable = opts.resizable;

    return Self{ .app = app };
}

pub fn destroy(self: *const Self) void {
    gtk.g_object_unref(self.app);
}

pub fn run(self: *const Self) void {
    _ = gtk.g_signal_connect_data(self.app, "activate", @ptrCast(&activate), @ptrCast(@constCast(&self)), null, 0);
    const status = gtk.g_application_run(@ptrCast(self.app), 0, null);
    std.process.exit(if (status > 0) 1 else 0);
}

fn activate(app: *gtk.GtkApplication, dat: *gtk.gpointer) callconv(.C) void {
    const window = gtk.gtk_application_window_new(app);
    const webview = gtk.WEBKIT_WEB_VIEW(gtk.webkit_web_view_new());

    _WINDOW = window;
    WINDOW = @as(*gtk.GtkWindow, @ptrCast(window));
    _WEBVIEW = webview;
    WEBVIEW = @as(*gtk.GtkWidget, @ptrCast(webview));

    gtk.gtk_window_set_child(WINDOW, WEBVIEW);

    _ = gtk.gtk_widget_grab_focus(WEBVIEW);

    if (!hiddenByDefault) {
        gtk.gtk_window_present(WINDOW);
    }

    if (!isResizable) {
        gtk.gtk_window_set_resizable(WINDOW, @intFromBool(isResizable));
    }

    onActivate.?(@as(*Self, @ptrCast(@constCast(&dat))));
}

pub fn show(_: *Self) void {
    if (WINDOW != null) {
        gtk.gtk_window_present(WINDOW);
    }
}

pub fn setTitle(_: *Self, title: [*c]const u8) void {
    gtk.gtk_window_set_title(WINDOW, title);
}

pub fn setSize(_: *Self, width: c_int, height: c_int, hint: ?WindowSizeHint) void {
    if (hint != null) {
        gtk.gtk_window_set_resizable(WINDOW, @intFromBool(hint != .FIXED));
        if (hint == .NONE) {
            gtk.gtk_window_set_default_size(WINDOW, width, height);
        } else if (hint == .FIXED) {
            gtk.gtk_widget_set_size_request(_WINDOW.?, width, height);
        } else {}
    }
    //gtk.gtk_window_set_default_size(WINDOW, width, height);
}

pub fn loadURI(_: *Self, link: [*c]const u8) void {
    if (_WEBVIEW != null) {
        _ = gtk.webkit_web_view_load_uri(_WEBVIEW.?, link);
    }
}