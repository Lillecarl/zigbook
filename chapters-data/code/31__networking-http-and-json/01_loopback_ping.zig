const std = @import("std");

/// Arguments passed to the server thread so it can accept exactly one client and reply.
const ServerTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

/// Reads a single line from a `std.Io.Reader`, stripping the trailing newline.
/// Returns `null` when the stream ends before any bytes are read.
fn readLine(reader: *std.Io.Reader, buffer: []u8) !?[]const u8 {
    var len: usize = 0;
    while (true) {
        // Attempt to read a single byte from the stream
        const byte = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => {
                // Stream ended: return null if no data was read, otherwise return what we have
                if (len == 0) return null;
                return buffer[0..len];
            },
            else => return err,
        };

        // Complete the line when newline is encountered
        if (byte == '\n') return buffer[0..len];
        // Skip carriage returns to handle both Unix (\n) and Windows (\r\n) line endings
        if (byte == '\r') continue;

        // Guard against buffer overflow
        if (len == buffer.len) return error.StreamTooLong;
        buffer[len] = byte;
        len += 1;
    }
}

/// Blocks waiting for a single client, echoes what the client sent, then exits.
fn serveOne(task: ServerTask) void {
    // Signal the main thread that the server thread reached the accept loop.
    // This synchronization prevents the client from attempting connection before the server is ready.
    task.ready.set();

    // Block until a client connects; handle connection errors gracefully
    const connection = task.server.accept() catch |err| {
        std.debug.print("accept failed: {s}\n", .{@errorName(err)});
        return;
    };
    // Ensure the connection is closed when this function exits
    defer connection.stream.close();

    // Set up a buffered reader to receive data from the client
    var inbound_storage: [128]u8 = undefined;
    var net_reader = connection.stream.reader(&inbound_storage);
    const conn_reader = net_reader.interface();

    // Read one line from the client using our custom line-reading logic
    var line_storage: [128]u8 = undefined;
    const maybe_line = readLine(conn_reader, &line_storage) catch |err| {
        std.debug.print("receive failed: {s}\n", .{@errorName(err)});
        return;
    };

    // Handle case where connection closed without sending data
    const line = maybe_line orelse {
        std.debug.print("connection closed before any data arrived\n", .{});
        return;
    };

    // Clean up any trailing whitespace from the received line
    const trimmed = std.mem.trimRight(u8, line, "\r\n");

    // Build a response message that echoes what the server observed
    var response_storage: [160]u8 = undefined;
    const response = std.fmt.bufPrint(&response_storage, "server observed \"{s}\"\n", .{trimmed}) catch |err| {
        std.debug.print("format failed: {s}\n", .{@errorName(err)});
        return;
    };

    // Send the response back to the client using a buffered writer
    var outbound_storage: [128]u8 = undefined;
    var net_writer = connection.stream.writer(&outbound_storage);
    net_writer.interface.writeAll(response) catch |err| {
        std.debug.print("write error: {s}\n", .{@errorName(err)});
        return;
    };
    // Ensure all buffered data is transmitted before the connection closes
    net_writer.interface.flush() catch |err| {
        std.debug.print("flush error: {s}\n", .{@errorName(err)});
        return;
    };
}

pub fn main() !void {
    // Initialize allocator for dynamic memory needs
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a loopback server on 127.0.0.1 with an OS-assigned port (port 0)
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // Create a synchronization primitive to coordinate server readiness
    var ready = std.Thread.ResetEvent{};
    // Spawn the server thread that will accept and handle one connection
    const server_thread = try std.Thread.spawn(.{}, serveOne, .{ServerTask{
        .server = &server,
        .ready = &ready,
    }});
    // Ensure the server thread completes before main() exits
    defer server_thread.join();

    // Block until the server thread signals it has reached accept()
    // This prevents a race condition where the client tries to connect too early
    ready.wait();

    // Retrieve the dynamically assigned port number and connect as a client
    const port = server.listen_address.in.getPort();
    var stream = try std.net.tcpConnectToHost(allocator, "127.0.0.1", port);
    defer stream.close();

    // Send a test message to the server using a buffered writer
    var outbound_storage: [64]u8 = undefined;
    var client_writer = stream.writer(&outbound_storage);
    const payload = "ping over loopback\n";
    try client_writer.interface.writeAll(payload);
    // Force transmission of buffered data
    try client_writer.interface.flush();

    // Receive the server's response using a buffered reader
    var inbound_storage: [128]u8 = undefined;
    var client_reader = stream.reader(&inbound_storage);
    const client_reader_iface = client_reader.interface();
    var reply_storage: [128]u8 = undefined;
    const maybe_reply = try readLine(client_reader_iface, &reply_storage);
    const reply = maybe_reply orelse return error.EmptyReply;
    // Strip any trailing whitespace from the server's reply
    const trimmed = std.mem.trimRight(u8, reply, "\r\n");

    // Display the results to stdout using a buffered writer for efficiency
    var stdout_storage: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_storage);
    const out = &stdout_state.interface;
    try out.writeAll("loopback handshake succeeded\n");
    try out.print("client received: {s}\n", .{trimmed});
    // Ensure all output is visible before program exits
    try out.flush();
}
