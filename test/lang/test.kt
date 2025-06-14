// {{TEST}}


class Main(){ // {{CONTEXT}}




    // {{CURSOR}}

}

// {{TEST}}

@Test // {{CONTEXT}}
fun main(a: Int){ // {{CONTEXT}}




    // {{CURSOR}}

    if (a == 1) { // {{CONTEXT}}




        // {{CURSOR}}

    } else if (a == 2){ // {{CONTEXT}}




        // {{CURSOR}}
        
        for (i in 0..a){ // {{CONTEXT}}




            // {{CURSOR}}

            while( true ){ // {{CONTEXT}}




            // {{CURSOR}}

            }
        }
    }
}

// {{TEST}}
fun main(a: Int){ // {{CONTEXT}}
    try{ // {{CONTEXT}}

    



        // {{CURSOR}}

        when (a){ // {{CONTEXT}}
            1 -> { // {{CONTEXT}}

            



                // {{CURSOR}}
            }

        }
    } catch (e: Exception) {

    }
}
