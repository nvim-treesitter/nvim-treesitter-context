with Ada.Text_IO; use Ada.Text_IO;

-- {{TEST}}
package Week is -- {{CONTEXT}}

   Mon : constant String := "Monday";
   Tue : constant String := "Tuesday";
   Wed : constant String := "Wednesday";
   Thu : constant String := "Thursday";
   Fri : constant String := "Friday";
   Sat : constant String := "Saturday";
   Sun : constant String := "Sunday"; -- {{CURSOR}}



end Week;

-- {{TEST}}
package Months -- {{CONTEXT}}
is

   Jan : constant String := "January";
   Feb : constant String := "February"; -- {{CURSOR}}










end Months;

-- {{TEST}}
procedure Show_Increment is -- {{CONTEXT}}
   A, B, C : Integer;

   procedure Display_Result is -- {{CONTEXT}}
   begin
      Put_Line ("Increment of "
                & Integer'Image (A)
                & " with "
                & Integer'Image (B)
                & " is "
                & Integer'Image (C)); -- {{CURSOR}}


   end Display_Result;

   -- {{POPCONTEXT}}
begin
   A := 10;
   B := 3;
   C := Increment_By (A, B);
   Display_Result;
   A := 20;
   B := 5;
   C := Increment_By (A, B); -- {{CURSOR}}
   Display_Result;
end Show_Increment;


-- {{TEST}}
type Date is -- {{CONTEXT}}
  record -- {{CONTEXT}}
  Day : Integer range 1 .. 31;

  Month : Months := Jan;



  -- {{CURSOR}}
end record;

-- {{TEST}}
procedure Greet is -- {{CONTEXT}}
begin

  X := 2;

  Ada.Text_IO.Put_Line ("Hello");


  for N in 1 .. 5 loop -- {{CONTEXT}}


    Put_Line("Hi");

    -- {{CURSOR}}
  end loop;
  -- {{POPCONTEXT}}
  Y := 1;
  loop -- {{CONTEXT}}


    exit when Y = 5;

    -- {{CURSOR}}
  end loop;
  -- {{POPCONTEXT}}
  while Y >= 0 loop -- {{CONTEXT}}
    Y := Y - 1;



    -- {{CURSOR}}
  end loop;


  -- {{POPCONTEXT}}
  case Y is -- {{CONTEXT}}
    when 0 .. 10 =>
      Put_Line("foo");



    when others =>
      Put_Line("bar"); -- {{CURSOR}}
  end case;

end Greet;


-- {{TEST}}
function Foo -- {{CONTEXT}}
  (I : Integer := 0;)
  return Integer is
begin
  -- bar




  return I + 1; -- {{CURSOR}}
end Foo;



