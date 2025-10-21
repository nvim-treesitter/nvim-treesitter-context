// {{TEST}}

import ( // {{CONTEXT}}
    "errors"


    "fmt"

    // {{CURSOR}}
)

// {{TEST}}

func (r *rect) area(a int, // {{CONTEXT}}
b int) int { // {{CONTEXT}}
    return r.width * r.height



// {{CURSOR}}
}

// {{TEST}}
var bigstruct = struct{ // {{CONTEXT}}
  a, b, c, d, e, f, g, h, i, j, k, l, m, n int // {{CONTEXT}}
}{ // {{CONTEXT}}
  a: 0,
  b: 0,
  c: 0,
  d: 0,
  e: 0,
  f: 0,
  g: 0,
  h: 0,
  i: 0,
  j: 0,
  k: 0,
  l: 0,
  m: 0,
  // {{CURSOR}}
  n: 0,
}

// {{TEST}}
var bigslice = []int{ // {{CONTEXT}}
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  // {{CURSOR}}
  15,
}

var b
  ,c
  ,d int = 1, 2

// {{TEST}}

func foo(a int, // {{CONTEXT}}
  b int) (int, // {{CONTEXT}}
  int) { // {{CONTEXT}}

    i := 1

  select { // {{CONTEXT}}
    case msg1 := <-c1:
      fmt.Println("received", msg1)
    case msg2 := <-c2: // {{CONTEXT}}




      // {{CURSOR}}
      fmt.Println("received", msg2)
  }


  for n := 0;
  n <= 5; n++ {
    if num := 9;
    num < 0 {
      fmt.Println(num, "is negative")





    } else if num < 10 {
      fmt.Println(num, "has 1 digit")







    } else {
      fmt.Println(num, "has multiple digits")








    }
    fmt.Println(n)
  }

  switch i {
    case 1:
      fmt.Println("one")
    case 2:
      fmt.Println("two")
    case 3:
      fmt.Println("three")






		default:










			fmt.Println("Not valid")
  }
}






var _ = Describe("something", func() {



  When("it works", func() {



    It("works!", func() {
      Expect(thing).To(Work())



    })
  })
})
