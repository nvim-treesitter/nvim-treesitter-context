// vim: ft=tact
struct S { // {{CONTEXT}}




    // {{CURSOR}}
}

message M {




    // comment
}

trait C {




    // comment
}

contract C {
    init() {




        // comment
    }

    receive() {




        // comment
    }

    external() {




        // comment
    }

    bounced(msg: bounced<M>) {




        // comment
    }

    fun someFunction() {




        // comment
    }
}

fun statements() {
    let a: map<Int, Int> = null;
    
    if (true) {




        // comment
    } else {




        // comment
    }

    try {




        // comment
    } catch (e) {
        



        // comment
    }

    while (true) {
        



        // comment
    }

    repeat (5) {
        



        // comment
    }

    do {
        



        // comment
    } until (true);

    foreach (k, v in a) {
        



        // comment
    }

    // expression_statement
    0




    // comment
    ;

    // return_statement
    return
    



    // comment
    0;

    // method_call_expression
    0.toString(




        // comment
    );

    // static_call_expression
    ton(




        "0.1" // comment
    );

    // instance_expression
    S {




        // comment
    };

    // initOf_expression
    initOf C(




        // comment
    );
}
