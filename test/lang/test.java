package mymod;

import stuff1;
import stuff2;

@class_annot_1
@class_annot_2
public class MyClass { // {{CONTEXT}}



    // {{CURSOR}}
    @method_annot_1
    @method_annot_2
    public void my_method(int param) { // {{CONTEXT}}



        // {{CURSOR}}
        if (true) { // {{CONTEXT}}



            // {{CURSOR}}
            for (int i = 0; i < 10; i++) { // {{CONTEXT}}
                


                // {{CURSOR}}
                for (int var : iterable) { // {{CONTEXT}}
                    


                    // {{CURSOR}}
                    System. // {{CONTEXT}}



                        out.println("a message"); // {{CURSOR}}
                }
            }
        }
    }
}
