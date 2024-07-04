#!/usr/bin/env fish
function foo

  while true




    echo 'foo'



  end

  switch (uname)
    case 'Linux'
      echo 'Linux'
    case 'Darwin'
      echo 'Mac'











    otherwise
      echo 'Windows'
  end

  if grep fish /etc/shells
    echo Found fish
  else if grep bash /etc/shells








    echo Found bash
  else
    echo Got nothing
  end

  for file in *.txt



    cp $file $file.bak











  end
end





