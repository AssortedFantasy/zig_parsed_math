const std = @import("std");

pub fn eval() void {}

const Arithmetic = struct {
    val: u32,

    const Self = @This();

    pub fn init(val: u32) Self {
        return .{
            .val = val,
        };
    }

    pub fn add(self: Self, other: Self) Self {
        return .{ .val = self.val + other.val };
    }
};

// test "eval" {
//     var locals = .{
//         .x = Arithmetic.init(1),
//         .y = Arithmetic.init(2),
//         .z = @as(Arithmetic, undefined),
//     };

//     eval(&locals,
//         \\ z = x + y
//         \\ z = z + z
//         \\ z = x
//     );

//     // z = x.add(y).
// }

const Expression = struct {
    result_var: []const u8,
    assignment: Operation,
};

const Operation = union(enum) {
    const BinOp = struct {
        lhs: *Operation,
        rhs: *Operation,
    };

    singleton: []const u8,
    add: BinOp,
    mul: BinOp,
};

pub fn parse_string(comptime expressions: []const u8) []Expression {
    // Expressions are broken up by lines.
    var iter = std.mem.tokenizeScalar(u8, expressions, '\n');

    while (iter.next()) |line| {
        _ = line;
    }
}

const Token = union(enum) {
    literal: []const u8,
    equals,
    plus,
    times,
};

const MAX_TOKENS = 1000;

pub fn tokenize(comptime expression: []const u8) []const Token {
    var i: usize = 0;
    var tokens: [MAX_TOKENS]Token = undefined;
    var token_count: usize = 0;

    while (i < expression.len) switch (expression[i]) {
        '=' => {
            tokens[token_count] = .equals;
            i += 1;
            token_count += 1;
        },
        '+' => {
            tokens[token_count] = .plus;
            i += 1;
            token_count += 1;
        },
        '*' => {
            tokens[token_count] = .times;
            i += 1;
            token_count += 1;
        },
        ' ', '\t' => {
            i += 1;
        },
        'a'...'z', 'A'...'Z', '0'...'9', '_' => {
            const start = i;
            var end = i + 1;
            while (end < expression.len and switch (expression[end]) {
                'a'...'z',
                'A'...'Z',
                '0'...'9',
                '_',
                => true,
                else => false,
            }) end += 1;
            tokens[token_count] = .{ .literal = expression[start..end] };
            token_count += 1;
            i = end;
        },
        else => |c| @compileError(std.fmt.comptimePrint("invalid character in expression \"{c}\"", .{c})),
    };

    return tokens[0..token_count];
}

test "tokenize" {
    const tokens = comptime tokenize("z_a= z + 1 * 2 * adwa");
    std.debug.print("{any}", .{tokens});
}

pub fn parse_line(comptime expression: []const u8) Expression {
    // x = z + y
    // [Literal X] [EqualsSymbol] [Literal Z] [Plus Sign] [Literal Y]
    const tokens = tokenize(expression);
    _ = tokens;
}
