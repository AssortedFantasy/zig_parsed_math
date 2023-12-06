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
    assignment: *const Operation,
};

const Operation = union(enum) {
    const BinOp = struct {
        lhs: *const Operation,
        rhs: *const Operation,
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
    lparen,
    rparen,
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

// test "tokenize" {
//     const tokens = comptime tokenize("z_a= z + 1 * 2 * adwa");
//     std.debug.print("{any}", .{tokens});
// }

pub fn parse_line(comptime expression: []const u8) Expression {
    // x = z + y
    // [Literal X] [EqualsSymbol] [Literal Z] [Plus Sign] [Literal Y]
    const tokens = comptime tokenize(expression);

    var parsed: Expression = undefined;
    if (tokens.len < 3) @compileError("invalid expression: " ++ expression);
    if (tokens[0] != .literal) @compileError("");
    if (tokens[1] != .equals) @compileError("");

    parsed.result_var = tokens[0].literal;
    parsed.assignment = parse_tree(tokens[2..]);

    return parsed;
}

pub fn parse_tree(comptime tokens: []const Token) *const Operation {
    const shunted = comptime shunting_yard(tokens);

    var stack: [MAX_TOKENS]*const Operation = undefined;
    var stack_size: usize = 0;

    for (shunted) |token| switch (token) {
        .literal => |lit| {
            const single: Operation = .{ .singleton = lit };
            stack[stack_size] = &single;
            stack_size += 1;
        },
        .plus => {
            if (stack_size < 2) @panic("");
            const addition: Operation = .{ .add = .{ .lhs = stack[stack_size] } };
            _ = addition;
        },
    };

    //

    return stack[0];
}

fn Precedence(comptime tag: std.meta.Tag(Token)) u8 {
    return switch (tag) {
        .plus => 0,
        .times => 1,
        .lparen => 127,
        else => @compileError(""),
    };
}

// From:
// https://en.wikipedia.org/wiki/Shunting_yard_algorithm

fn shunting_yard(comptime tokens: []const Token) []const Token {
    var result: [MAX_TOKENS]Token = undefined; // Outputs
    var result_size: usize = 0;

    var operator_stack: [MAX_TOKENS]Token = undefined;
    var operator_size: usize = 0;

    for (tokens) |token| switch (token) {
        .literal => {
            result[result_size] = token;
            result_size += 1;
        },
        .lparen => {
            operator_stack[operator_size] = token;
            operator_size += 1;
        },
        .rparen => {
            while (true) {
                if (operator_size == 0) @panic("bad");
                switch (operator_stack[operator_size - 1]) {
                    .lparen => {
                        operator_size -= 1;
                        break;
                    },
                    else => {
                        result[result_size] = operator_stack[operator_size - 1];
                        result_size += 1;
                        operator_size -= 1;
                    },
                }
            }
        },
        .plus, .times => {
            const o1 = Precedence(token);
            while (operator_size > 0) {
                const o2 = Precedence(operator_stack[operator_size - 1]);
                if (o2 >= o1) {
                    // Remove it and push it.
                    result[result_size] = operator_stack[operator_size - 1];
                    result_size += 1;
                    operator_size -= 1;
                } else {
                    break;
                }
            }
            operator_stack[operator_size] = token;
            operator_size += 1;
        },
        else => @panic("bad token"),
    };

    while (operator_size > 0) : (operator_size -= 1) {
        switch (operator_stack[operator_size - 1]) {
            .lparen => @panic(""),
            .plus, .times => {
                result[result_size] = operator_stack[operator_size - 1];
                result_size += 1;
            },
            else => @panic(""),
        }
    }

    return result[0..result_size];
}

fn print_token(tokens: []const Token) void {
    for (tokens) |token| switch (token) {
        .literal => |c| {
            std.debug.print("{s} ", .{c});
        },
        .plus => std.debug.print("+ ", .{}),
        .times => std.debug.print("* ", .{}),
        .equals => std.debug.print("= ", .{}),
        else => @panic(""),
    };
}

// test "shunting" {
//     const tokens = comptime tokenize("a + b + c + d");
//     //std.debug.print("{any}\n", .{tokens});
//     const shunted = comptime shunting_yard(tokens);
//     //_ = shunted;
//     print_token(shunted);
// }
