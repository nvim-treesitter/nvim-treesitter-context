// {{TEST}}
@Deprecated('') // {{CONTEXT}}
abstract // BUG: there should be context here
class User 
    extends 
      Object {
  User(this.age);
  int age;










  // {{CURSOR}}

  void printAge() { // {{CONTEXT}}
  













    print(age); // {{CURSOR}}
  }

}
// {{TEST}}
String(
  int magicalNumber,
) { // {{CONTEXT}
  if (magicalNumber == "69" // {{CONTEXT}}
      // --
      ||
      magicalNumber == "420") {
    return 'pretty nice';



    // {{CURSOR}}
  } else if (magicalNumber == "420" // {{CONTEXT}}
      &&
      magicalNumber == "69") {






















    return 'pretty high'; // {{CURSOR}}
  } // {{POPCONTEXT}}

  return 'just decent'; // BUG: should mark cursor here
}

// {{TEST}}
void catching() { // {{CONTEXT}}
  try // {{CONTEXT}}
    // --
  {













    // {{CURSOR}}
  } catch (e) {








    // {{CURSOR}}

  } finally {










    // {{CURSOR}}

  }
}
// {{TEST}}
void foring() { // {{CONTEXT}}
  for (int i = 0; // {{CONTEXT}}
        i < 10;
        i++) {













    // {{CURSOR}}
  } // {{POPCONTEXT}}

  while (true // {{CONTEXT}}
  == false) {
















    // {{CURSOR}}

} // {{POPCONTEXT}}

  do { // {{CONTEXT}}













  // {{CURSOR}}
} while (true);
}
// {{TEST}}
extension ext // {{CONTEXT}}
on int {








  // {{CURSOR}}
}
