enum TestEnum {








  foo @0;







  bar @1;







  baz @2;	







  qux @3;








  quux @4;








  corge @5;








  grault @6;








  garply @7;








}



struct TestAllTypes {
  voidField      @0  : Void;




  boolField      @1  : Bool;




  int8Field      @2  : Int8;




  int16Field     @3  : Int16;




  int32Field     @4  : Int32;




  int64Field     @5  : Int64;




  uInt8Field     @6  : UInt8;




  uInt16Field    @7  : UInt16;




  uInt32Field    @8  : UInt32;




  uInt64Field    @9  : UInt64;




  float32Field   @10 : Float32;




  float64Field   @11 : Float64;




  textField      @12 : Text;




  dataField      @13 : Data;




  structField    @14 : TestAllTypes;




  enumField      @15 : TestEnum;




  interfaceField @16 : Void;  # TODO




  voidList      @17 : List(Void);




  boolList      @18 : List(Bool);




  int8List      @19 : List(Int8);




  int16List     @20 : List(Int16);




  int32List     @21 : List(Int32);




  int64List     @22 : List(Int64);




  uInt8List     @23 : List(UInt8);




  uInt16List    @24 : List(UInt16);




  uInt32List    @25 : List(UInt32);




  uInt64List    @26 : List(UInt64);




  float32List   @27 : List(Float32);




  float64List   @28 : List(Float64);




  textList      @29 : List(Text);




  dataList      @30 : List(Data);




  structList    @31 : List(TestAllTypes);




  enumList      @32 : List(TestEnum);




  interfaceList @33 : List(Void);  # TODO




}

struct TestInterleavedGroups {





  group1 :group {





    foo @0 :UInt32;





    bar @2 :UInt64;





    union {





      qux @4 :UInt16;





      corge :group {





        grault @6 :UInt64;





        garply @8 :UInt16;





        plugh @14 :Text;





        xyzzy @16 :Text;





      }











      fred @12 :Text;





    }











    waldo @10 :Text;





  }











  group2 :group {





    foo @1 :UInt32;





    bar @3 :UInt64;





    union {





      qux @5 :UInt16;





      corge :group {





        grault @7 :UInt64;





        garply @9 :UInt16;





        plugh @15 :Text;





        xyzzy @17 :Text;





      }











      fred @13 :Text;





    }











    waldo @11 :Text;





  }





}

struct TestDefaults {




  voidField      @0  : Void    = void;




  boolField      @1  : Bool    = true;




  int8Field      @2  : Int8    = -123;




  int16Field     @3  : Int16   = -12345;




  int32Field     @4  : Int32   = -12345678;




  int64Field     @5  : Int64   = -123456789012345;




  uInt8Field     @6  : UInt8   = 234;




  uInt16Field    @7  : UInt16  = 45678;




  uInt32Field    @8  : UInt32  = 3456789012;




  uInt64Field    @9  : UInt64  = 12345678901234567890;




  float32Field   @10 : Float32 = 1234.5;




  float64Field   @11 : Float64 = -123e45;




  textField      @12 : Text    = "foo";




  dataField      @13 : Data    = 0x"62 61 72"; # "bar"




  structField    @14 : TestAllTypes = (




      voidField      = void,




      boolField      = true,




      int8Field      = -12,




      int16Field     = 3456,




      int32Field     = -78901234,




      int64Field     = 56789012345678,




      uInt8Field     = 90,




      uInt16Field    = 1234,




      uInt32Field    = 56789012,




      uInt64Field    = 345678901234567890,




      float32Field   = -1.25e-10,




      float64Field   = 345,




      textField      = "baz",




      dataField      = "qux",




      structField    = (




          textField = "nested",




          structField = (textField = "really nested")),




      enumField      = baz,




      # interfaceField can't have a default






      voidList      = [void, void, void],




      boolList      = [false, true, false, true, true],




      int8List      = [12, -34, -0x80, 0x7f],




      int16List     = [1234, -5678, -0x8000, 0x7fff],




      int32List     = [12345678, -90123456, -0x80000000, 0x7fffffff],




      int64List     = [123456789012345, -678901234567890, -0x8000000000000000, 0x7fffffffffffffff],




      uInt8List     = [12, 34, 0, 0xff],




      uInt16List    = [1234, 5678, 0, 0xffff],




      uInt32List    = [12345678, 90123456, 0, 0xffffffff],




      uInt64List    = [123456789012345, 678901234567890, 0, 0xffffffffffffffff],




      float32List   = [0, 1234567, 1e37, -1e37, 1e-37, -1e-37],




      float64List   = [0, 123456789012345, 1e306, -1e306, 1e-306, -1e-306],




      textList      = ["quux", "corge", "grault"],




      dataList      = ["garply", "waldo", "fred"],




      structList    = [




          (textField = "x " "structlist"




                       " 1"),




          (textField = "x structlist 2"),




          (textField = "x structlist 3")],




      enumList      = [qux, bar, grault]




      # interfaceList can't have a default
      );




  enumField      @15 : TestEnum = corge;




  interfaceField @16 : Void;  # TODO









  voidList      @17 : List(Void)    = [void, void, void, void, void, void];




  boolList      @18 : List(Bool)    = [true, false, false, true];




  int8List      @19 : List(Int8)    = [111, -111];




  int16List     @20 : List(Int16)   = [11111, -11111];




  int32List     @21 : List(Int32)   = [111111111, -111111111];




  int64List     @22 : List(Int64)   = [1111111111111111111, -1111111111111111111];




  uInt8List     @23 : List(UInt8)   = [111, 222] ;




  uInt16List    @24 : List(UInt16)  = [33333, 44444];




  uInt32List    @25 : List(UInt32)  = [3333333333];




  uInt64List    @26 : List(UInt64)  = [11111111111111111111];




  float32List   @27 : List(Float32) = [5555.5, inf, -inf, nan];




  float64List   @28 : List(Float64) = [7777.75, inf, -inf, nan];




  textList      @29 : List(Text)    = ["plugh", "xyzzy", "thud"];




  dataList      @30 : List(Data)    = ["oops", "exhausted", "rfc3092"];




  structList    @31 : List(TestAllTypes) = [




      (textField = "structlist 1"),




      (textField = "structlist 2"),




      (textField = "structlist 3")];




  enumList      @32 : List(TestEnum) = [foo, garply];




  interfaceList @33 : List(Void);  # TODO




}


struct TestUseGenerics $TestGenerics(Text, Data).ann("foo") {




  basic @0 :TestGenerics(TestAllTypes, TestAnyPointer);




  inner @1 :TestGenerics(TestAllTypes, TestAnyPointer).Inner;




  inner2 @2 :TestGenerics(TestAllTypes, TestAnyPointer).Inner2(Text);




  unspecified @3 :TestGenerics;




  unspecifiedInner @4 :TestGenerics.Inner2(Text);




  wrapper @8 :TestGenericsWrapper(TestAllTypes, TestAnyPointer);




  cap @18 :TestGenerics(TestInterface, Text);




  genericCap @19 :TestGenerics(TestAllTypes, List(UInt32)).Interface(Data);









  default @5 :TestGenerics(TestAllTypes, Text) =




      (foo = (int16Field = 123), rev = (foo = "text", rev = (foo = (int16Field = 321))));




  defaultInner @6 :TestGenerics(TestAllTypes, Text).Inner =




      (foo = (int16Field = 123), bar = "text");




  defaultUser @7 :TestUseGenerics = (basic = (foo = (int16Field = 123)));




  defaultWrapper @9 :TestGenericsWrapper(Text, TestAllTypes) =




      (value = (foo = "text", rev = (foo = (int16Field = 321))));




  defaultWrapper2 @10 :TestGenericsWrapper2 =




      (value = (value = (foo = "text", rev = (foo = (int16Field = 321)))));









  aliasFoo @11 :TestGenerics(TestAllTypes, TestAnyPointer).AliasFoo = (int16Field = 123);




  aliasInner @12 :TestGenerics(TestAllTypes, TestAnyPointer).AliasInner




      = (foo = (int16Field = 123));




  aliasInner2 @13 :TestGenerics(TestAllTypes, TestAnyPointer).AliasInner2




      = (innerBound = (foo = (int16Field = 123)));




  aliasInner2Bind @14 :TestGenerics(TestAllTypes, TestAnyPointer).AliasInner2(List(UInt32))




      = (baz = [12, 34], innerBound = (foo = (int16Field = 123)));




  aliasInner2Text @15 :TestGenerics(TestAllTypes, TestAnyPointer).AliasInner2Text




      = (baz = "text", innerBound = (foo = (int16Field = 123)));




  aliasRev @16 :TestGenerics(TestAnyPointer, Text).AliasRev.AliasFoo = "text";









  useAliases @17 :TestGenerics(TestAllTypes, List(UInt32)).UseAliases = (




      foo = (int16Field = 123),




      inner = (foo = (int16Field = 123)),




      inner2 = (innerBound = (foo = (int16Field = 123))),




      inner2Bind = (baz = "text", innerBound = (foo = (int16Field = 123))),




      inner2Text = (baz = "text", innerBound = (foo = (int16Field = 123))),




      revFoo = [12, 34, 56]);




}

interface TestMoreStuff extends(TestCallOrder) {




  # Catch-all type that contains lots of testing methods.

  callFoo @0 (cap :TestInterface) -> (s: Text);




  # Call `cap.foo()`, check the result, and return "bar".




  callFooWhenResolved @1 (cap :TestInterface) -> (s: Text);




  # Like callFoo but waits for `cap` to resolve first.




  neverReturn @2 (cap :TestInterface) -> (capCopy :TestInterface) $Cxx.allowCancellation;




  # Doesn't return.  You should cancel it.




  hold @3 (cap :TestInterface) -> ();




  # Returns immediately but holds on to the capability.





  callHeld @4 () -> (s: Text);




  # Calls the capability previously held using `hold` (and keeps holding it).




  getHeld @5 () -> (cap :TestInterface);




  # Returns the capability previously held using `hold` (and keeps holding it).






  echo @6 (cap :TestCallOrder) -> (cap :TestCallOrder);




  # Just returns the input cap.






  expectCancel @7 (cap :TestInterface) -> () $Cxx.allowCancellation;




  # evalLater()-loops forever, holding `cap`.  Must be canceled.


  methodWithDefaults @8 (a :Text, b :UInt32 = 123, c :Text = "foo") -> (d :Text, e :Text = "bar");









  methodWithNullDefault @12 (a :Text, b :TestInterface = null);









  getHandle @9 () -> (handle :TestHandle);




  # Get a new handle. Tests have an out-of-band way to check the current number of live handles, so
  # this can be used to test garbage collection.




  getNull @10 () -> (nullCap :TestMoreStuff);




  # Always returns a null capability.





  getEnormousString @11 () -> (str :Text);




  # Attempts to return an 100MB string. Should always fail.





  writeToFd @13 (fdCap1 :TestInterface, fdCap2 :TestInterface)




             -> (fdCap3 :TestInterface, secondFdPresent :Bool);




  # Expects fdCap1 and fdCap2 wrap socket file descriptors. Writes "foo" to the first and "bar" to
  # the second. Also creates a socketpair, writes "baz" to one end, and returns the other end.





  throwException @14 ();




  throwRemoteException @15 ();




}
