const builtin = @import("builtin");

pub const include_plugins = builtin.mode == .Debug;

pub const namespace = if (include_plugins)
    @import("plugins_enabled.zig")
else
    struct {};
