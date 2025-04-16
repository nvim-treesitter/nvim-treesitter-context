// {{TEST}}
@Deprecated('') // {{CONTEXT}}
abstract // {{CONTEXT}}
class User // {{CONTEXT}}
    extends // {{CONTEXT}}
      Object { // {{CONTEXT}}
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
) { // {{CONTEXT}}
  if (magicalNumber == "69" // {{CONTEXT}}
      // {{CONTEXT}}
      || // {{CONTEXT}}
      magicalNumber == "420") { // {{CONTEXT}}
    return 'pretty nice';



    // {{CURSOR}}
  } else if (magicalNumber == "420" // {{CONTEXT}}
      && // {{CONTEXT}}
      magicalNumber == "69") { // {{CONTEXT}}






















    return 'pretty high'; // {{CURSOR}}
  } // {{POPCONTEXT}}

  return 'just decent'; // BUG: should mark cursor here
}

// {{TEST}}
void catching() { // {{CONTEXT}}
  try // {{CONTEXT}}
    // {{CONTEXT}}
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
        i < 10; // {{CONTEXT}}
        i++) { // {{CONTEXT}}













    // {{CURSOR}}
  } // {{POPCONTEXT}}
  // {{POPCONTEXT}}
  // {{POPCONTEXT}}

  while (true // {{CONTEXT}}
  == false) { // {{CONTEXT}}
















    // {{CURSOR}}

} // {{POPCONTEXT}}
// {{POPCONTEXT}}

  do { // {{CONTEXT}}













  // {{CURSOR}}
} while (true);
}
// {{TEST}}
extension ext // {{CONTEXT}}
on int { // {{CONTEXT}}








  // {{CURSOR}}
}
