const



  C = 5
var



  v = 5
let



  l = 5
using



  u: int
type



  O = object of RootObj



    f: int
  T = tuple



    f: int
  E = enum



    F1
    F2

proc p[
    T
  ](
  a: int
  ):
  int 
  {.nimcall.}
  =







  discard

func f() =




  discard

method m(a: O) =




  discard

iterator i(): int =




  discard

converter c(a: int): int =




  discard

template t() =




  discard

macro ma(body: untyped) =




  discard

let pe = proc (): int =




  discard

let fe = func (): int =




  discard

let ie = iterator (): int =




  discard

import std/algorithm
var array1 = [3,2,1]
sort(array1) do (x, y: int) -> int:




  1

ma:


  ma:


    ma:


      ma:

        
        ma:


          discard


# Foot of Mount Doom
for x in 
  [0,1,2]:



  while 
    true:



    block label:



      static:



        try:



          discard

        except 
          ValueError as e:






          discard

        finally:



          if 
            true:




            discard

          elif 
            true:



            discard

          else:

            when 
              true:




              discard

            elif 
              true:




              discard

            else:
              let en = E.F2
              case en:
              of 
                F1:



                discard

              elif 
                true:



                discard

              else:



                echo "You have climbed Mount Doom!"

