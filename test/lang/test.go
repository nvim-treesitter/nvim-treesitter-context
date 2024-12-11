// {{TEST}}

import ( // {{CONTEXT}}
    "errors"


    "fmt"

    // {{CURSOR}}
)

// {{TEST}}

func (r *rect) area(a int, // {{CONTEXT}}
b int) int {
    return r.width * r.height

// {{CURSOR}}


}

var b
  ,c
  ,d int = 1, 2

// {{TEST}}

func foo(a int, // {{CONTEXT}}
  b int) (int,
  int) {

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
