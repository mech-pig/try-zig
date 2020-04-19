// this is a comment

// top-level declarations are order independent
const warn = std.debug.warn;
const stdout = std.io.getStdOut().outStream();
const std = @import("std");


/// This is a docstring documenting the main function (`///`)
/// `pub` means we that the function will be accessible if the module is imported
/// the exclamation mark before the return value
pub fn main() !void {
    // stdout.print may fail:
    // - we should check the return value to handle the possible error
    // - `try` short-circuits this check by returning prematurley with the error if it is returned
    try stdout.print("Hello, {}!\n", .{"World"});

    // warn can't fail (i.e. we don't care about the result - it can fail on OS level, of course)
    warn("I can't fail!\n", .{});
}
