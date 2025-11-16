
// Import the standard library for basic functionality
const std = @import("std");
// Import the root module to access application-level features and configurations
const root = @import("root");

// Catalog represents a collection of feature names.
// This struct is used to organize and manage the list of features
// that are exported by the root module.
const Catalog = struct {
    // items holds a slice of string slices, where each string represents
    // a feature name. The slice is immutable (const) to prevent modifications.
    items: []const []const u8,
};

// printCatalog writes a formatted list of features to the provided writer.
// This function is useful for debugging and displaying what features are
// available from the root module at runtime.
//
// Parameters:
//   - writer: An output writer (e.g., std.io.Writer) that supports the print method.
//             The anytype allows flexibility in the writer type used.
//
// Returns:
//   - !void: Returns void on success, or an error if writing fails.
pub fn printCatalog(writer: anytype) !void {
    // Create a Catalog instance populated with features from the root module
    // The slice syntax [0..] takes all items from the Features array
    const catalog = Catalog{ .items = root.Features[0..] };
    
    // Print the header line showing the total count of features
    try writer.print("Features exported by root ({d}):\n", .{catalog.items.len});
    
    // Iterate through each feature with its index
    // The 0.. syntax starts the index counter at 0
    for (catalog.items, 0..) |name, idx| {
        // Print each feature with a 1-based index number (idx + 1)
        // The format {d:>2} right-aligns the number in a 2-character width
        try writer.print("  {d:>2}. {s}\n", .{ idx + 1, name });
    }
}
