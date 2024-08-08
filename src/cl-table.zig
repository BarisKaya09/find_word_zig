const std = @import("std");
const ArrayList = std.ArrayList;

pub const HorizontalEdgeStyle = enum {
    Equal,
    Dash,
    Plus,

    fn getStyle(self: @This()) []const u8 {
        return switch (self) {
            .Equal => "=",
            .Dash => "-",
            .Plus => "+",
        };
    }
};

pub const VerticalEdgeStyle = enum {
    Column,
    Hash,
    SemiColon,

    fn getStyle(self: @This()) []const u8 {
        return switch (self) {
            .Column => "|",
            .Hash => "#",
            .SemiColon => ";",
        };
    }
};

const TableError = error{NumberOfColumnsExceeded};

pub const CLTable = struct {
    header: ArrayList([][]const u8),
    rows: ArrayList([][]const u8),
    colSize: usize,
    alloc: std.mem.Allocator,
    horizontalEdgeStyle: HorizontalEdgeStyle,
    verticalEdgeStyle: VerticalEdgeStyle,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, colSize: usize, horizontalEdgeStyle: HorizontalEdgeStyle, verticalEdgeStyle: VerticalEdgeStyle) CLTable {
        return CLTable{
            .alloc = alloc,
            .header = ArrayList([][]const u8).init(alloc),
            .rows = ArrayList([][]const u8).init(alloc),
            .colSize = colSize,
            .horizontalEdgeStyle = horizontalEdgeStyle,
            .verticalEdgeStyle = verticalEdgeStyle,
        };
    }

    pub fn render(self: Self) !void {
        const horizontalStyle = self.getHorizontalStyle();
        const verticalStyle = self.getVerticalStyle();
        if (self.header.items.len > 0) {
            for (self.header.items) |row| {
                const headerHorizontalStyle = HorizontalEdgeStyle.Equal.getStyle();
                const corner = HorizontalEdgeStyle.Plus.getStyle();
                std.debug.print("\n", .{});
                std.debug.print("{s}", .{corner});
                for (0..18 * row.len) |_| {
                    std.debug.print("{s}", .{headerHorizontalStyle});
                }
                std.debug.print("{s}", .{corner});
                std.debug.print("\n", .{});
                for (row) |col| {
                    std.debug.print("{s}     {s}     ", .{ verticalStyle, col });
                }
                std.debug.print("{s}\n", .{verticalStyle});
                std.debug.print("{s}", .{corner});
                for (0..18 * row.len) |_| {
                    std.debug.print("{s}", .{headerHorizontalStyle});
                }
                std.debug.print("{s}", .{corner});
            }
        }

        for (self.rows.items) |row| {
            std.debug.print("\n", .{});
            for (0..18 * row.len) |_| {
                std.debug.print("{s}", .{horizontalStyle});
            }
            std.debug.print("\n", .{});
            for (row) |col| {
                std.debug.print("{s}     {s}     ", .{ verticalStyle, col });
            }
            std.debug.print("{s}\n", .{verticalStyle});
            for (0..18 * row.len) |_| {
                std.debug.print("{s}", .{horizontalStyle});
            }
        }
    }

    fn getHorizontalStyle(self: Self) []const u8 {
        return self.horizontalEdgeStyle.getStyle();
    }

    fn getVerticalStyle(self: Self) []const u8 {
        return self.verticalEdgeStyle.getStyle();
    }

    pub fn addHeader(self: *Self, header: [][]const u8) !void {
        if (header.len != self.colSize) {
            std.debug.print("number of column exceeded!: {}\n", .{header.len});
            return TableError.NumberOfColumnsExceeded;
        }
        try self.header.append(header);
    }

    pub fn addRow(self: *Self, row: [][]const u8) !void {
        if (row.len != self.colSize) {
            std.debug.print("number of columns exceeded!: {}", .{row.len});
            return TableError.NumberOfColumnsExceeded;
        }
        try self.rows.append(row);
    }

    pub fn deinit(self: Self) void {
        //for (self.rows.items) |row| {
        //  for (row) |str| {
        //    self.alloc.free(str);
        //}
        //}
        self.header.deinit();
        self.rows.deinit();
    }
};
