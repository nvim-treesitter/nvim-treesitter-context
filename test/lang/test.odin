package main

import "core:fmt"

demo_struct :: struct($T: typeid) {
  name: string,
  payload: T,
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment
  // comment

}


main :: proc() {

  a := 1

  if a > 0 {
    a = do_stuff(a)

  }


  //comment
  //comment
  //comment
  //comment
  //comment
  //comment
  //comment
  //commen
  for x:=0; x<100; x+=1 {
  //comment
  //comment
  //comment
  //comment
  //comment
  //comment
  //comment
  //comment
    fmt.printf("{0}\n", x)
  }
  //comment
  fmt.printf("{0}\n", a)
}

do_stuff :: proc(x: int) -> int {
  switch x {
    case 1:
      return 42











    case 0:
      return 420
  }
  return 0
}
