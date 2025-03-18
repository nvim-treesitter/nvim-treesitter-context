<?php
/*
 * {{TEST}}
 */
#[ReturnTypeWillChange]
function foo($a, $b) { // {{CONTEXT}}
  //loop, between low & high
  while ($a <= $b) { // {{CONTEXT}}
    // comment
    $index = $low + floor(($high - $low) * $delta);
    // comment
    $indexValue = $a;
    if ($indexValue === $a) { // {{CONTEXT}}



      $position = $index;
      return (int) $position; // {{CURSOR}}
    }
    if ($indexValue < $key) {
      // comment

      $low = $index + 1;
    }
    if ($indexValue > $key) {
      // comment
      do {
        // comment
        echo "The number is: $x <br>";
        $x++;




      } while ($x <= 5);

      for ($x = 0; $x <= 10; $x++) {
        echo "The number is: $x <br>";











      }



      foreach ($colors as $value) {
        echo "$value <br>";






      }

      $high = $index - 1;
    }
  }



  //when key not found in array or array not sorted
  return null;
}

#[Attribute]
class Fruit {




    #[ReturnTypeWillChange]
    public function rot(): void
    {


        return;
    }



 // comment




}
