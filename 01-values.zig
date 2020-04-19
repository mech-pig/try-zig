const assert = @import("std").debug.assert;
const f128_max = @import("std").math.f128_max;
const maxInt = @import("std").math.maxInt;
const minInt = @import("std").math.minInt;
const warn = @import("std").debug.warn;
const eql = @import("std").mem.eql;


pub fn main() void {
    // const assigns a variable to an identifier -> you can't reassign an indentifier
    // const applies to all of the bytes that the identifier immediately addresses.
    // Pointers have their own const-ness.
    const im_a_const_label: u8 = 12;
    debugValue("const integer", im_a_const_label);

    // `var` is used for identifiers that can be reassigned.
    // variables MUST be initialized
    var im_a_var_label: u8 = im_a_const_label;
    debugValue("var integer", im_a_var_label);

    // use `undefined` to explicitly leave variable uninitialized
    // cfr: https://ziglang.org/documentation/master/#undefined
    im_a_var_label = undefined;  // in debug mode Zig writes 0xaa bytes to undefined memory
    debugValue("var integer (undefined)", im_a_var_label);

    // integers & floats
    const unsigned_32_int: u32 = minInt(u32);
    const signed_64_int: i64 = maxInt(i64);
    const float_128: f128 = f128_max;

    debugValue("unsigned 32-bit integer", unsigned_32_int);
    debugValue("signed 64-bit integer", signed_64_int);
    debugValue("float 128-bit", float_128);

    // errors and error sets
    // the type of Errors is ErrorSetType (a sort of enum)
    // cfr: https://ziglang.org/documentation/master/#Error-Set-Type
    const Errors = error{
        ErrorA,
        ErrorB,
    };

    var error_or_number: Errors!i32 = 42;
    debugValue("error unions", error_or_number); // type is Errors!i32
    error_or_number = Errors.ErrorA;
    debugValue("error unions", error_or_number); // type is Errors!i32

    // anyerror is the union of all errors
    const err: anyerror = error.ImAnError;
    debugValue("error", err);

    // optional values
    var optional_int: ?u8 = 42;
    debugValue("optional int (int)", optional_int);
    optional_int = null;
    debugValue("optional int (null)", optional_int);

    // string
    const string = "hello";
    debugValue("string literal", string);
    // string literals are just single-item constant pointers
    // to Null-Terminated UTF-8 encoded byte arrays
    assert(string.len == 5);  // len is the length of the string
    assert(string[5] == 0); // array is null-terminated automatically

    const still_a_string: *const [5:0]u8 = "hello";
    debugValue("string", still_a_string);
    assert(eql(u8, string, still_a_string));

    const multiline =
        \\This is
        \\a multiline string
    ;
    debugValue("multiline string", multiline);

    // character
    const char = 's';
    debugValue("char (ascii range)", char);
    // char literals have type comptime_int
    assert(char == 115);
    const unicode = '🙃';
    debugValue("char (unicode range)", unicode);
    assert('\u{1f643}' == unicode);  // hexadecimal unicode point is valid as char literal
}

// var can be used to infer type when the function is called
// cfr: https://ziglang.org/documentation/master/#Function-Parameter-Type-Inference
fn debugValue(title: []const u8, value: var) void {
    // @TypeOf is a builtin function that takes any (nonzero) number of expressions as parameters
    // and returns the type of the result, using Peer Type Resolution.
    // This kind of type resolution chooses a type that all peer types can coerce into
    // cfr: https://ziglang.org/documentation/master/#Peer-Type-Resolution
    warn("{}\nvalue: {}\ntype: {}\n\n", .{
        title,
        value,
        @typeName(@TypeOf(value)),
    });
}
