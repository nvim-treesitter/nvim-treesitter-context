#!/bin/bash

# {{TEST}}

foo() { # {{CONTEXT}}

  if [ 1 -eq 1 ]; then # {{CONTEXT}}
    echo 1


    # {{CURSOR}}
  fi

}


# {{TEST}}

bar() { # {{CONTEXT}}
  case "$i" in # {{CONTEXT}}
    1) echo 1 # {{CONTEXT}}



    # {{CURSOR}}
    ;;
    2|3) echo 2 or 3
    ;;
    *) echo default
    ;;
  esac
}


# {{TEST}}

baz() { # {{CONTEXT}}
  while [ $x -le 5 ] # {{CONTEXT}}
  do
    echo "Welcome $x times"

    x=$(( $x + 1 ))
    # {{CURSOR}}
  done
}

# {{TEST}}

baz2() { # {{CONTEXT}}
  # until is also a while loop
  until [ $x -gt 5 ] # {{CONTEXT}}
  do
    echo Counter: $x
    ((x++))
    # {{CURSOR}}
  done
}

# {{TEST}}

# select is a for statement
select character in Sheldon Leonard Penny Howard Raj  # {{CONTEXT}}
do
  echo "Selected character: $character"

  # {{CURSOR}}
done

# {{POPCONTEXT}}

for ((i=0; i<=10000; i++)); do # {{CONTEXT}}



    # {{CURSOR}}
    echo "$i"
done


