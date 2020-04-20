// The @cImport function takes an expression as a parameter.
// This expression is evaluated at compile-time and is used to control preprocessor directives
// and include multiple .h files
// cfr: https://ziglang.org/documentation/master/#Import-from-C-Header-File
const c = @cImport({
    @cInclude("stdio.h");
});

pub fn main() void {
    _ = c.printf("%s from an imported c function!\n", "Hello World");
}
