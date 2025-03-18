#!/usr/bin/env fish
# {{TEST}}
function foo # {{CONTEXT}}

  while true # {{CONTEXT}}




    echo 'foo'


    # {{CURSOR}}
  end # {{POPCONTEXT}}

  switch (uname) # {{CONTEXT}}
    case 'Linux' # {{CONTEXT}}



      echo 'Linux' # {{CURSOR}}
    # {{POPCONTEXT}}
    case 'Darwin' # {{CONTEXT}}
      echo 'Mac'








      # {{CURSOR}}


    otherwise



      echo 'Windows' # {{CURSOR}}
    # {{POPCONTEXT}}
  end # {{POPCONTEXT}}

  if grep fish /etc/shells # {{CONTEXT}}



    echo Found fish # {{CURSOR}}
  else if grep bash /etc/shells # {{CONTEXT}}








    echo Found bash # {{CURSOR}}
    # {{POPCONTEXT}}
  else # {{CONTEXT}}




    echo Got nothing # {{CURSOR}}
  end # {{POPCONTEXT}}
  # {{POPCONTEXT}}

  for file in *.txt # {{CONTEXT}}



    cp $file $file.bak










    # {{CURSOR}}
  end
end





