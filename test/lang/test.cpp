// # {{TEST}}
struct Struct { // {{CONTEXT}}
    int *f1;
    int *f2;



    // {{CURSOR}}
};







// {{TEST}}
class Class { // {{CONTEXT}}
    int *f1;
    int *f2;



    // {{CURSOR}}
};








// {{TEST}}
typedef enum { // {{CONTEXT}}
  E1,
  E2,
  E3


  // {{CURSOR}}
} myenum;









// {{TEST}}
int main(int arg1, // {{CONTEXT}}
         char **arg2, // {{CONTEXT}}
         char **arg3 // {{CONTEXT}}
         ) // {{CONTEXT}}
{ // {{CONTEXT}}
  if (arg1 == 4 // {{CONTEXT}}
      && arg2 == arg3) { // {{CONTEXT}}
    for (int i = 0; i < arg1; i++) { // {{CONTEXT}}
      while (1) { // {{CONTEXT}}





        // {{CURSOR}}
      }
    }
  }
  // {{POPCONTEXT}}
  // {{POPCONTEXT}}
  // {{POPCONTEXT}}
  // {{POPCONTEXT}}


  do { // {{CONTEXT}}
    int array[1];
    for (auto value : array) { // {{CONTEXT}}





      // {{CURSOR}}
    }
  } while (1);
}
