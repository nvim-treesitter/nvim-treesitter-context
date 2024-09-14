with Ada.Text_IO; use Ada.Text_IO;

package Week is

   Mon : constant String := "Monday";
   Tue : constant String := "Tuesday";
   Wed : constant String := "Wednesday";
   Thu : constant String := "Thursday";
   Fri : constant String := "Friday";
   Sat : constant String := "Saturday";
   Sun : constant String := "Sunday";



end Week;

package Months
is

   Jan : constant String := "January";
   Feb : constant String := "February";










end Months;

procedure Show_Increment is
   A, B, C : Integer;

   procedure Display_Result is
   begin
      Put_Line ("Increment of "
                & Integer'Image (A)
                & " with "
                & Integer'Image (B)
                & " is "
                & Integer'Image (C));


   end Display_Result;

begin
   A := 10;
   B := 3;
   C := Increment_By (A, B);
   Display_Result;
   A := 20;
   B := 5;
   C := Increment_By (A, B);
   Display_Result;
end Show_Increment;


type Date is
  record
  Day : Integer range 1 .. 31;

  Month : Months := Jan;




end record;

procedure Greet is
begin

  X := 2;

  Ada.Text_IO.Put_Line ("Hello");


  for N in 1 .. 5 loop


    Put_Line("Hi");


  end loop;

  Y := 1;
  loop


    exit when Y = 5;


  end loop;

  while Y >= 0 loop
    Y := Y - 1;




  end loop;



  case Y is
    when 0 .. 10 =>
      Put_Line("foo");



    when others =>
      Put_Line("bar");
  end case;

end Greet;


function Foo
  (I : Integer := 0;)
  return Integer is
begin
  -- bar




  return I + 1;
end Foo;



