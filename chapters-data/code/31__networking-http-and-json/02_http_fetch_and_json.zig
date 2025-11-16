const std = @import("std");

/// Arguments passed to the HTTP server thread so it can respond to a single request.
const HttpTask = struct {
    server: *std.net.Server,
    ready: *std.Thread.ResetEvent,
};

/// Minimal HTTP handler: accept one client, reply with a JSON document, and exit.
fn serveJson(task: HttpTask) void {
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

    // Allocate buffers for receiving HTTP request and sending HTTP response
    var recv_buffer: [4096]u8 = undefined;
    var send_buffer: [4096]u8 = undefined;
    // Create buffered reader and writer for the TCP connection
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);
    // Initialize HTTP server state machine with the buffered connection interfaces
    var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

    // Parse the HTTP request headers (method, path, version, etc.)
    var request = server.receiveHead() catch |err| {
        std.debug.print("receive head failed: {s}\n", .{@errorName(err)});
        return;
    };

    // Define the shape of our JSON response payload
    const Body = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // Build a response that echoes request details back to the client
    const payload = Body{
        .service = "loopback-api",
        .message = "hello from Zig HTTP server",
        .method = @tagName(request.head.method), // Convert HTTP method enum to string
        .path = request.head.target, // Echo the requested path
        .sequence = 1,
    };

    // Allocate a buffer for the JSON-encoded response body
    var json_buffer: [256]u8 = undefined;
    // Create a fixed-size writer that writes into our buffer
    var body_writer = std.Io.Writer.fixed(json_buffer[0..]);
    // Serialize the payload struct into JSON format
    std.json.Stringify.value(payload, .{}, &body_writer) catch |err| {
        std.debug.print("json encode failed: {s}\n", .{@errorName(err)});
        return;
    };
    // Get the slice containing the actual JSON bytes written
    const body = std.Io.Writer.buffered(&body_writer);

    // Send HTTP 200 response with the JSON body and appropriate content-type header
    request.respond(body, .{
        .extra_headers = &.{
            .{ .name = "content-type", .value = "application/json" },
        },
    }) catch |err| {
        std.debug.print("respond failed: {s}\n", .{@errorName(err)});
        return;
    };
}

pub fn main() !void {
    // Initialize allocator for dynamic memory needs (HTTP client requires allocation)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a loopback server on 127.0.0.1 with an OS-assigned port (port 0)
    const address = try std.net.Address.parseIp("127.0.0.1", 0);
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // Create a synchronization primitive to coordinate server readiness
    var ready = std.Thread.ResetEvent{};
    // Spawn the server thread that will accept and handle one HTTP request
    const server_thread = try std.Thread.spawn(.{}, serveJson, .{HttpTask{
        .server = &server,
        .ready = &ready,
    }});
    // Ensure the server thread completes before main() exits
    defer server_thread.join();

    // Block until the server thread signals it has reached accept()
    // This prevents a race condition where the client tries to connect too early
    ready.wait();

    // Retrieve the dynamically assigned port number for the client connection
    const port = server.listen_address.in.getPort();

    // Initialize HTTP client with our allocator
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Construct the full URL for the HTTP request
    var url_buffer: [64]u8 = undefined;
    const url = try std.fmt.bufPrint(&url_buffer, "http://127.0.0.1:{d}/stats", .{port});

    // Allocate buffer to receive the HTTP response body
    var response_buffer: [512]u8 = undefined;
    // Create a fixed-size writer that will capture the response
    var response_writer = std.Io.Writer.fixed(response_buffer[0..]);

    // Perform the HTTP GET request with custom User-Agent header
    const fetch_result = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response_writer, // Where to write response body
        .headers = .{
            .user_agent = .{ .override = "zigbook-demo/0.15.2" },
        },
    });

    // Get the slice containing the actual response body bytes
    const body = std.Io.Writer.buffered(&response_writer);

    // Define the expected structure of the JSON response
    const ResponseShape = struct {
        service: []const u8,
        message: []const u8,
        method: []const u8,
        path: []const u8,
        sequence: u32,
    };

    // Parse the JSON response into a typed struct
    var parsed = try std.json.parseFromSlice(ResponseShape, allocator, body, .{});
    // Free the memory allocated during JSON parsing
    defer parsed.deinit();

    // Set up a buffered writer for stdout to efficiently output results
    var stdout_storage: [256]u8 = undefined;
    var stdout_state = std.fs.File.stdout().writer(&stdout_storage);
    const out = &stdout_state.interface;
    // Display the HTTP response status code
    try out.print("status: {d}\n", .{@intFromEnum(fetch_result.status)});
    // Display the parsed JSON fields
    try out.print("service: {s}\n", .{parsed.value.service});
    try out.print("method: {s}\n", .{parsed.value.method});
    try out.print("path: {s}\n", .{parsed.value.path});
    try out.print("message: {s}\n", .{parsed.value.message});
    // Ensure all output is visible before program exits
    try out.flush();
}
