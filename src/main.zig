const std = @import("std");
const CLTable = @import("./cl-table.zig").CLTable;
const HorizontalEdgeStyle = @import("./cl-table.zig").HorizontalEdgeStyle;
const VerticalEdgeStyle = @import("./cl-table.zig").VerticalEdgeStyle;

const COMMAND_NAME = "fw"; // find word command
const F_FLAG = "-f"; // -f file name
const W_FLAG = "-w"; // -w word
const HELP_FLAG = "-help";

const FindWord = struct {
    args: std.ArrayList([]const u8),
    alloc: std.mem.Allocator,

    const Self = @This();

    fn init(alloc: std.mem.Allocator) Self {
        return Self{ .args = std.ArrayList([]const u8).init(alloc), .alloc = alloc };
    }

    fn deinit(self: *Self) void {
        self.args.deinit();
    }

    fn find(self: *Self) !void {
        const parsedArgs = try parseArgs(self.args);
        if (parsedArgs.isHelp) {
            var table = CLTable.init(self.alloc, 2, HorizontalEdgeStyle.Dash, VerticalEdgeStyle.Column);
            defer table.deinit();
            var title = [_][]const u8{ "Name", "Description" };
            try table.addHeader(&title);

            var row1 = [_][]const u8{ "fw", "Komutu ayaga kaldirir." };
            try table.addRow(&row1);

            var row2 = [_][]const u8{ "-f", "Dosya yolunun algilandigi komuttur." };
            try table.addRow(&row2);

            var row3 = [_][]const u8{ "-w", "Aranacak kelimenin algilandigi komuttur." };
            try table.addRow(&row3);
            try table.render();

            var table2 = CLTable.init(self.alloc, 2, HorizontalEdgeStyle.Dash, VerticalEdgeStyle.Column);
            defer table2.deinit();

            var row4 = [_][]const u8{ "Shortcut", "Description" };
            try table2.addHeader(&row4);

            var row5 = [_][]const u8{ "desk/", "Masaustu kisayoludur." };
            try table2.addRow(&row5);
            try table2.render();
            return;
        }

        var buffer: [std.fs.max_path_bytes]u8 = undefined;
        const realPath = try std.fs.realpath(parsedArgs.file, &buffer);

        const file = try std.fs.openFileAbsolute(realPath, .{ .mode = std.fs.File.OpenMode.read_only });
        defer file.close();

        const file_stat = try file.stat();
        const file_size = file_stat.size;

        const readBuffer = try self.alloc.alloc(u8, file_size);
        defer self.alloc.free(readBuffer);

        _ = try file.read(readBuffer);

        var lines = std.mem.splitAny(u8, readBuffer, "\n");

        const red = "\x1b[31m";
        const blue = "\x1b[36m";
        const reset = "\x1b[39m";
        var count: u32 = 0;

        while (lines.next()) |line| {
            var words = std.mem.splitAny(u8, line, " ");
            while (words.next()) |word| {
                if (std.mem.eql(u8, parsedArgs.word, word)) {
                    count = count + 1;
                    std.debug.print("{s}{s}{s} ", .{ red, word, reset });
                } else std.debug.print("{s} ", .{word});
            }
            std.debug.print("\n", .{});
        }

        std.debug.print("{s}{}{s} tane {s}{s}{s} bulundı.", .{ blue, count, reset, blue, parsedArgs.word, reset });
    }
};

const ParsedArgs = struct {
    file: []const u8,
    word: []const u8,
    isHelp: bool,
};

const ParseError = error{ InvalidCommand, InvalidArgsLen, MissingOption, FileExtNotSupported };

fn parseArgs(args: std.ArrayList([]const u8)) ParseError!ParsedArgs {
    const cmd = args.items[0];
    if (!std.mem.eql(u8, cmd, COMMAND_NAME)) {
        std.debug.print("invalid command name. expected command name -> fw | ", .{});
        return ParseError.InvalidCommand;
    }

    if (args.items.len == 2 and std.mem.eql(u8, args.items[1], "-help")) {
        return ParsedArgs{ .file = "", .word = "", .isHelp = true };
    }

    if (args.items.len != 5) {
        std.debug.print("invalid arguments len. expected arguments len -> 5 | ", .{});
        return ParseError.InvalidArgsLen;
    }

    const flag1 = args.items[1..3];
    const flag2 = args.items[3..5];
    var file: []const u8 = "";
    var word: []const u8 = "";

    if (std.mem.eql(u8, flag1[0], F_FLAG)) {
        file = flag1[1];
        word = flag2[1];
    } else {
        file = flag2[1];
        word = flag1[1];
    }

    var it = std.mem.splitAny(u8, file, ".");
    var index: u8 = 0;
    var ext: []const u8 = "";
    while (it.next()) |x| {
        if (index == 1) {
            ext = x;
        }
        index += 1;
    }
    if (!isSupportedExt(ext)) {
        std.debug.print("{s} file extension not supported", .{ext});
        return ParseError.FileExtNotSupported;
    }
    return ParsedArgs{ .file = file, .word = word, .isHelp = false };
}

fn isSupportedExt(ext: []const u8) bool {
    const supportedExt = [4][]const u8{ "txt", "html", "xml", "json" };
    var matched = false;
    for (supportedExt) |se| {
        if (std.mem.eql(u8, ext, se)) matched = true;
    }
    return matched;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var fw = FindWord.init(alloc);
    defer fw.deinit();

    var args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len >= 1) {
        args = args[1..];
        for (args) |arg| {
            try fw.args.append(arg);
        }
    } else {
        std.debug.print("No arguments provided.\n", .{});
    }

    try fw.find();
}
