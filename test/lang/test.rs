impl Foo {




    fn bar(&self) {





        if condition {






            for i in 0..100 {






                foo(async move {






                    // comment






                })
            }
        }





        try {






            let Foo::Bar {
                texts,
                values,
            } = foo().bar() else {





                let a = if b {





                    // comment





                } else {




                    // comment




                };
            }
        }




        short_call_site(a, b);

        long_call_site(
            a,

            b,

            c,

            d,

            e,
        );




        macro_rules! x {


            // comment
            () => {};


        }




        x! {



            // comment



        }



        unsafe {


            *0  // run


        }




        let short_array = [];

        let long_array = [
            1,

            2,

            3,

            4,
        ];

        let (short, tuple) = (1, 2);

        let (
            a,

            rather,

            long,

            tuple,
        ) = (
            1,

            2,

            3,

            4,
        );
    }

    let s = BigStruct {

        a,

        b,

        c,

        d,
    };
}

pub extern "C" {



    pub fn foobar(_: *u8);



}

struct Foo {

    active: bool,

    username: String,

    email: String,

    sign_in_count: u64,

}

union Bar {

    a: u8,

    b: u16,

    c: u32,

}
