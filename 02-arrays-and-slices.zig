const assert = @import("std").debug.assert;
const heap = @import("std").heap;
const mem = @import("std").mem;
const warn = @import("std").debug.warn;


pub fn main() !void {
    // an array is a pointer and a length, known at compile time.
    // The lenght of the array is part of the type
    const array_of_u8: [3]u8 = [3]u8{ 1, 2, 3 };
    debugValue("array of u8", array_of_u8);

    // array literal: length is still known at compile time, but its inferred from code
    const array_literal_of_u8 = [_]u8{ 1, 2, 3 };
    debugValue("array literal of u8", array_literal_of_u8);

    // anonymous array literal: we must define type beforehand, the compiler will do the rest
    const anonymous_array_literal_of_u8: [3]u8 = .{ 1, 2, 3 };
    debugValue("anonymous array literal of u8", array_literal_of_u8);

    // check that the content of the array is known at compile time
    comptime {
        const expected_len = 3;
        assert(expected_len == array_of_u8.len);
        assert(expected_len == array_literal_of_u8.len);
        assert(expected_len == anonymous_array_literal_of_u8.len);

        assert(mem.eql(u8, &array_of_u8, &[3]u8{ 1, 2, 3 }));
        assert(mem.eql(u8, &array_of_u8, &array_literal_of_u8));
        assert(mem.eql(u8, &array_of_u8, &anonymous_array_literal_of_u8));
    }

    // string literal is a (constant) pointer to a null-terminated array of u8
    const string_literal = "hello";
    debugValue("string literal", string_literal); // *const [5:0]u8
    debugValue("array pointed by string", string_literal.*); // [5:0]u8

    const string_as_const_pointer_to_null_terminated_array: *const[5:0]u8
        = &[_:0]u8{ 'h', 'e', 'l', 'l', 'o' };

    comptime {
        // they are both pointers (== `&` is not needed)
        assert(mem.eql(u8, string_literal, string_as_const_pointer_to_null_terminated_array));
    }

    // array concatenation
    const a = [_]u8{ 1, 2, 3 };
    const b = [_]u8{ 4, 5 };
    const c = a ++ b;
    assert(mem.eql(u8, &[_]u8{ 1, 2, 3, 4, 5 }, &c));
    assert(mem.eql(u8, "hello world", "hello" ++ " " ++ "world"));  // string can be concatentated

    // repeating patterns
    const length = 3;
    const three_zeroes = [_]u8{ 0 } ** length;
    assert(length == three_zeroes.len);
    assert(mem.eql(u8, &three_zeroes, &[_]u8{ 0, 0, 0 }));

    // arrays of struct
    const Book = struct {
        title: []const u8,
        author: []const u8,
    };
    const books = [_]Book {
        Book{ .title = "Odissey", .author = "Homer" },
        Book{ .title = "Aeneid", .author = "Virgil" },
    };
    debugValue("array of struct", books);
    debugValue("array of struct (element)", books[0]);

    // arrays can be initialized at compile time with an arbitrarly complex init function
    const books_of_italo_calvino = init: {
        // this is an array (length is known at compile time - inferred in this case) of const u8,
        // null-terminated slices (length of each slice is known at runtime, but its bounded)
        const titles = [_] [:0]const u8{
            "Il sentiero dei nidi di ragno",
            "Il visconte dimezzato",
            "l barone rampante",
            "Il cavaliere inesistente",
            "Il castello dei destini incrociati",
         };

         // we have to use a var to modify the content pointed by the array
         var books_of_italo_calvino: [titles.len]Book = undefined;
         for (titles) |title, i| {
             books_of_italo_calvino[i] = Book{
                 .author = "Italo Calvino",
                 .title = title
             };
         }
         break :init books_of_italo_calvino;
    };
    debugValue("comptime-initialized array", books_of_italo_calvino);


    // a slice is a pointer and a length, like arryas
    // the fundamental difference is that length is known at runtime rather than at compile time and
    // it's not part of the type
    var runtime_known_length: u8 = 10;
    var slice_of_integers: []u8 = undefined;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    slice_of_integers = try allocator.alloc(u8, runtime_known_length);
    assert(runtime_known_length == slice_of_integers.len);

    var i: u8 = 0;
    while (i < runtime_known_length) {
        slice_of_integers[i] = i;
        i = i + 1;
    }
    debugValue("slice of integers", slice_of_integers);

    // slices have bound checking, like arrays
    // trying to access out-of-bounds elements will result in a failure
    // _ = slice_of_integers[slice_of_integers.len];  // uncomment me to verify failure

    // Using the address-of operator on a slice gives a pointer to a single item
    assert(@TypeOf(&slice_of_integers) == *[]u8);
    // using the `ptr` field gives an unknown length pointer.
    assert(@TypeOf(slice_of_integers.ptr) == [*]u8);
    assert(@ptrToInt(slice_of_integers.ptr) == @ptrToInt(&slice_of_integers[0]));

    // you can obtain a slice from an array
    const origin_array = [_]u8{ 4, 5, 6, 7 };
    const tail_slice = origin_array[1..origin_array.len];
    assert(tail_slice.len == origin_array.len - 1);
    assert(tail_slice[0] == origin_array[1]);
    debugValue("slice from array", tail_slice);
    assert(@TypeOf(tail_slice) == *const [origin_array.len - 1]u8);

    // you can also obtain a slice from a pointer, using the same slicing syntax
    const origin_array_ptr = &origin_array;
    const init_slice = origin_array_ptr[0..origin_array.len - 1];
    assert(init_slice.len == origin_array.len - 1);
    assert(init_slice[0] == origin_array[0]);
    debugValue("slice from pointer", init_slice);
    assert(@TypeOf(init_slice) == *const [origin_array.len - 1]u8);

    // like array, slice can be sentinel-terminated
    const slice_from_string_literal: [:0]const u8 = "hello";
    debugValue("null-terminated slice", slice_from_string_literal);
}


fn debugValue(title: []const u8, value: var) void {
    warn("{}\nvalue: {}\ntype: {}\n\n", .{
        title,
        value,
        @typeName(@TypeOf(value)),
    });
}
