// {{TEST}}

struct Bert { // {{CONTEXT}}
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
} Myenum;


// {{TEST}}

int main(int arg1, // {{CONTEXT}}
         char **arg2,
         char **arg3)
{

  if (arg1 == 4 // {{CONTEXT}}
      && arg2 == arg3) {

    // {{CURSOR}}

    for (int i = 0; i < arg1; i++) { // {{CONTEXT}}

      // {{CURSOR}}
      while (1) { // {{CONTEXT}}


        // {{CURSOR}}
      }

    }
  }
}


// {{TEST}}

void foo(int a) { // {{CONTEXT}}
  if (a) { // {{CONTEXT}}
      do { // {{CONTEXT}}



        // {{CURSOR}}
      } while (1);
  }
}


// {{TEST}}

void bar(int a) { // {{CONTEXT}}
  if (a) { // {{CONTEXT}}

  } else if (a == 4) { // {{CONTEXT}}
    // comment
  } else { // {{CONTEXT}}



    // {{CURSOR}}
  }
}


// {{TEST}}

void baz(int a) { // {{CONTEXT}}
  switch (a) { // {{CONTEXT}}
    case 0:
      break;
    case 1: { // {{CONTEXT}}



      // {{CURSOR}}
    } break;
  }
}

// {{TEST}}
void declaration() { // {{CONTEXT}}
  struct Bert foo = { // {{CONTEXT}}
    .f1 = 0,


    // {{CURSOR}}
    .f2 = 0,

  };
}
