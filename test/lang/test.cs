// # {{TEST}}
namespace hello_world // {{CONTEXT}}
{
    interface IInterface // {{CONTEXT}}
    {








        // {{CURSOR}}
    }
    // {{POPCONTEXT}}
    public enum Direction // {{CONTEXT}}
    {
        Left,
        Right,
        Up,
        Down


        // {{CURSOR}}
    }
    // {{POPCONTEXT}}
    class Cls // {{CONTEXT}}
    {
        // Constructor
        public Cls () // {{CONTEXT}}
        {











            // {{CURSOR}}
        }
        // {{POPCONTEXT}}
        // Destructor
        ~Cls() // {{CONTEXT}}
        {











            // {{CURSOR}}
        } // {{POPCONTEXT}}
    } // {{POPCONTEXT}}

    record Record // {{CONTEXT}}
    {













        // {{CURSOR}}
    } // {{POPCONTEXT}}

    record struct RecordStruct // {{CONTEXT}}
    {















        // {{CURSOR}}
    } // {{POPCONTEXT}}

    public struct Test // {{CONTEXT}}
    {
        public void Test1() // {{CONTEXT}}
        {
            if (true) // {{CONTEXT}}
            {












                // {{CURSOR}}
            }
            else
            {
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine();
                Console.WriteLine(); // {{CURSOR}}
            } // {{POPCONTEXT}}
            var arr = new[] { 1, 2, 3 };

            foreach (var item in arr) // {{CONTEXT}}
            {






                // {{CURSOR}}
            } // {{POPCONTEXT}}

            for (int i = 0; i < arr.Length; i++) // {{CONTEXT}}
            {
                try // {{CONTEXT}}
                {
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine(); // {{CURSOR}}
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                    Console.WriteLine();
                }
                catch // {{CONTEXT}}
                {












                    // {{CURSOR}}

                } // {{POPCONTEXT}}
                finally // {{CONTEXT}}
                {












                    // {{CURSOR}}


                } // {{POPCONTEXT}}
            // {{POPCONTEXT}}
            } // {{POPCONTEXT}}
        } // {{POPCONTEXT}}

        int Switch(int key) // {{CONTEXT}}
        {
            switch (key) // {{CONTEXT}}
            {
                case 0:













                    return 1; // {{CURSOR}}
                case 1:








                    return 2; // {{CURSOR}}
                case 2:






                    return 12;
                case 3:
                    return 444;
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:
                case 11:
                case 12:
                case 13:
                case 14:
                case 15:
                case 16:
                case 17:
                case 18:
                case 19:
                case 20:
                case 21:
                case 22:

                    
















                    return 1234444;
                default: throw new Exception(); // {{CURSOR}}

            } // {{POPCONTEXT}}













            // {{CURSOR}}

        }
    }
}


































