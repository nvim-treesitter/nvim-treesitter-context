class UserAccount { // {{CONTEXT}}
  name;
  id;



  // {{CURSOR}}
  constructor(name, id) { // {{CONTEXT}}
    this.name = name;
    this.id = id;

    // {{CURSOR}}
    for (let i = 0; i < 3; i++) { // {{CONTEXT}}
      console.log("hello");


      // {{CURSOR}}
    } // {{POPCONTEXT}}



    // {{CURSOR}}
  }
}
