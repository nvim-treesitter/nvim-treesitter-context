test "stuff" {
    while (i < 3 &&
        j > 4) {
        i += 1;


        if (i == 2
        && j == 3) {
            // stuff




        } else if (i == 3 &&
            j == 4) {
            // stuff




        } else {
            // stuff




        }
    }

    inline while (i < 3) : (i += 1) {


        // stuff


    }


    while (eventuallyNullSequence()) |value| {





        sum1 += value;



    }


    const items = [_]i32 { 4, 5, 3, 4, 0 };

    // counting for loop
    for


    var sum: i32 = 0;
    const result = for (
    items) |value| {
        if (value != null) {
            sum += value.?;
        }











    } else blk: {
        try expect(sum == 12);
        break :blk sum;





    };


}



const Stuff = struct {
    a: i8,



    b: i8,




    c: i8,





    d: i8,
}

fn bar(a: i8,
b: i8) {
    switch (a) {
        42,
        1 => {

        }
    }
    const b = switch (a) {
        42,
        1 => {


        },

        101,
        102=> blk: {




            const c: u64 = 5;




            break :blk c * 2 + 1;
        },

        else => 9,
    };

}
fn foo(a: i8,

b:i8) Stuff {
    var p = Stuff {
        a: 1,



        b: 2,



        c: 3,



        d: 4,
    };

    return Stuff {
        .a = a,


        .b = b,


    };















}







