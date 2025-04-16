// {{TEST}}
struct S // {{CONTEXT}}
{ // {{CONTEXT}}



    int i; // {{CURSOR}}
}
// {{TEST}}
template t(T: int) { // {{CONTEXT}}



    // {{CURSOR}}
}
// {{TEST}}
unittest { // {{CONTEXT}}



    // {{CURSOR}}
}

// {{TEST}}
enum Things { // {{CONTEXT}}
    A,


    B,
    C, // {{CURSOR}}
}
// {{TEST}}
union U // {{CONTEXT}}
{ // {{CONTEXT}}
    ubyte i;




    char c; // {{CURSOR}}
}
// {{TEST}}
interface Bar // {{CONTEXT}}
{ // {{CONTEXT}}



    // {{CURSOR}}
}
// {{TEST}}
class Foo : Bar // {{CONTEXT}}
{ // {{CONTEXT}}



    // {{CURSOR}}
    void bar (int a, // {{CONTEXT}}
        int b) // {{CONTEXT}}
    { // {{CONTEXT}}

    try { // {{CONTEXT}}



        // {{CURSOR}}
    } catch (Exception e) { // {{CONTEXT}}



        // {{CURSOR}}
    }
    // BUG: Should keep class context
    asm
    {


        mov EAX, dword ptr 0x1234;
        mov EAX, dword ptr 0x1234;
    }

    with (S) {


        //stuff
    }

    for (int i = a;
    i < b; i++)
    {



        // stuff
    }

    char[] a = ['h', 'i'];

    foreach (i,
        char c; a)
    {




        // stuff
    }

    if (
        a < b) {



        // stuff
    } else if (
        b < a) {



        // stuff
    } else {






        // stuff
    }


    while (
        true) {





        // stuff
    }

    switch (i)
    {
        default:    // valid: ends with 'throw'
            throw new Exception("unknown number");

        case 3:     // valid: ends with 'break' (break out of the 'switch' only)
            message ~= "three";




            break;

        case 4:     // valid: ends with 'continue' (continue the enclosing loop)
            message ~= "four";
            continue; // don't append a comma

        case 1:
            message ~= ">";
            goto case;

        case 2:     // valid: this is the last case in the switch statement.
            message ~= "one or two";
    }

        writeln("hello!");  // calls std.stdio.writeln
    }

}










