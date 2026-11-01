#import "Basic";

// {{TEST}}
Struct :: struct { // {{CONTEXT}}
    field1: u32;
    field2: u32;
    // {{CURSOR}}
}

// {{TEST}}
Enum :: enum { // {{CONTEXT}}
    MEMBER1;
    MEMBER2;
    // {{CURSOR}}
}

// {{TEST}}
for 0 .. 10 { // {{CONTEXT}}
    print("%\n", it_index);
    // {{CURSOR}}
}

// {{TEST}}
while true { // {{CONTEXT}}
    print("Hello, Sailor!\n");
    // {{CURSOR}}
}

// {{TEST}}
if true { // {{CONTEXT}}
    print("Hello, Sailor!\n");
    // {{CURSOR}}
// {{TEST}}
} else { // {{CONTEXT}}
    print("Hello, World!\n");
    // {{CURSOR}}
}

// {{TEST}}
multiline_params :: ( // {{Context}}
    a: int,
    b: int,
    c: int,
    d: int,
) -> void {
    print("%\n", a + b)
    // {{CURSOR}}
}

// {{TEST}}
do_stuff :: (a: int, b: *bool) -> string { // {{CONTEXT}}
    for 0 .. 10 { // {{CONTEXT}}
        if int > 0 { // {{CONTEXT}}
            b.* = true;
        }
    }
    // Comment
    // {{CURSOR}}
}

// {{TEST}}
#if DEBUG { // {{CONTEXT}}
    #assert false, "Sorry!";
    // {{CURSOR}}
}
