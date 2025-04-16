
{
  output = # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
    # {{CONTEXT}}
   let # {{CONTEXT}}
      l = { # {{CONTEXT}}
        a = false;
        b = false;
        c = false;

        # {{CURSOR}}
      }; #Succe
      m = {
        a = false;
        b = true;









        c = false;
      }; #Success
      n = {
        a = false;
        b = true;
        c = true;
      }; #Fail

      functions = {
        check = pkgs:
        list:
          let
            length = 








            builtins.length (pkgs.lib.remove false list);



            otherfunc = { a, b, c, ... }@nice: a + b + c;







            setFunc =
              { a
              , b
              , c
              , ...
              }@extras: (







                a * b * c










              );
          in
          (length == 0) || (length == 1);
      };
    in
    functions.check l;
}
