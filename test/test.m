if x < 0 &&
  y < 0


  y = 0;
elseif x < 1


  y = x;
else


  y = 1;
end

while x < 5
  print(x);


  x = x + 1;
end

try


  % do something
catch ME


  % do something else
end

switch x
  case 1


    y = 1;
  case 2


    y = 2;
  otherwise


    y = 0;
end

function [C] = myMatMult(A,
  B)
    [m,n] = size(A);
    [p,q] = size(B);
    if n ~=
      p
        error('Inner matrix dimensions must agree.');


    end
    C = zeros(m,q);
    for i =
      1:m



        for j = 1:q


            for k = 1:n
                C(i,j) = C(i,j) + A(i,k)*B(k,j);



            end
        end
    end
end






