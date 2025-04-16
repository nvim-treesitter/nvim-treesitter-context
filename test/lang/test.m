% {{TEST}}
if x < 0 && % {{CONTEXT}}
  y < 0 % {{CONTEXT}}



  y = 0; % {{CURSOR}}
elseif x < 1 % {{CONTEXT}}




  y = x; % {{CURSOR}}
  % {{POPCONTEXT}}
else % {{CONTEXT}}



  y = 1; % {{CURSOR}}
end

% {{TEST}}
while x < 5 % {{CONTEXT}}
  print(x);


  x = x + 1; % {{CURSOR}}
end % {{POPCONTEXT}}

% {{TEST}}
try


  % do something
catch ME


  % {{CURSOR}}
end

% {{TEST}}
switch x % {{CONTEXT}}
  case 1


    y = 1;
  case 2


    y = 2;
  otherwise % {{CONTEXT}}



    y = 0; % {{CURSOR}}
  % {{POPCONTEXT}}
end % {{POPCONTEXT}}

% {{TEST}}
function [C] = myMatMult(A, % {{CONTEXT}}
  B) % {{CONTEXT}}
    [m,n] = size(A);
    [p,q] = size(B);
    if n ~= % {{CONTEXT}}
      p % {{CONTEXT}}
        error('Inner matrix dimensions must agree.');



      % {{CURSOR}}
    end % {{POPCONTEXT}}
    % {{POPCONTEXT}}
    C = zeros(m,q); % {{CURSOR}}
    for i =
      1:m



        for j = 1:q


            for k = 1:n
                C(i,j) = C(i,j) + A(i,k)*B(k,j);



            end
        end
    end
end






