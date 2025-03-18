// {{TEST}}
public class MyClass {





    public void my_method(Integer param) { // {{CONTEXT}}




        if (true) { // {{CONTEXT}}




            for (Integer i = 0; i < 10; i++) { // {{CONTEXT}}
                



                for (Integer v : values) { // {{CONTEXT}}
                    



                    System. // {{CONTEXT}}



                        debug('a message'); // {{CURSOR}}
                }
            }
        }
    }
}
// vim: ft=apex
