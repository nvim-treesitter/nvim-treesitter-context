// {{TEST}}

SinOsc { // {{CONTEXT}}
    var <f1;
    var <f2;





    // {{CURSOR}}
};


// {{TEST}}
( // {{CONTEXT}}
var a = 1;








// {{CURSOR}}
)


// {{TEST}}

var main = { | arg1,  // {{CONTEXT}}
         			 arg2,  // {{CONTEXT}}
               arg3 | // {{CONTEXT}}



  if ({ arg1 == 4 } // {{CONTEXT}}
      && { arg2 == arg3 }) { // {{CONTEXT}}


    // {{CURSOR}}

    (0..arg1).do { // {{CONTEXT}}




      // {{CURSOR}}
      while { 1 } { // {{CONTEXT}}




        // {{CURSOR}}
      }

    }
  } { // {{CONTEXT}}








		// {{CURSOR}}				
	}
}


// {{TEST}}

Ndef(\test) { // {{CONTEXT}}
  if (a) { // {{CONTEXT}}
      loop { // {{CONTEXT}}









        // {{CURSOR}}
      }
  }
}


// {{TEST}}

~test = { |a|   // {{CONTEXT}}
  switch { a }  // {{CONTEXT}}
		{ 0 } {     // {{CONTEXT}}









		}
		{ 1 } { // {{CONTEXT}}




      // {{CURSOR}}
    }
}

// {{TEST}}
d = [1, // {{CONTEXT}}
2,
3,
4,
5,





//{{CURSOR}}
];


// {{TEST}}
a + // {{CONTEXT}}
	b +
	c +
	d +



	




	e // {{CURSOR}}

















