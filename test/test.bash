#!/bin/bash
foo() {

  if [ 1 -eq 1 ]; then
    echo 1








  fi

  case "$i" in
    1) echo 1







    ;;
    2|3) echo 2 or 3
    ;;
    *) echo default
    ;;
  esac


  while [ $x -le 5 ]
  do
    echo "Welcome $x times"





    x=$(( $x + 1 ))
  done

  # until is also a while loop
  until [ $x -gt 5 ]
  do
    echo Counter: $x






    ((x++))
  done

  # select is a for statement
  select character in Sheldon Leonard Penny Howard Raj
  do
    echo "Selected character: $character"





    echo "Selected number: $REPLY"
  done


}















