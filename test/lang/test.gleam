// {{TEST}}
pub type Shape { // {{CONTEXT}}
  Circle(radius: Float)
  Square(side: Float)
  Rectangle(width: Float, height: Float)
} // {{CURSOR}}

// {{TEST}}
pub opaque type Wrapper { // {{CONTEXT}}


  Wrapper(value: Int)

  Extra // {{CURSOR}}
}

// {{TEST}}
pub type Alias =
  Int

pub fn main() { // {{CONTEXT}}






  echo "hello" // {{CURSOR}}
}

// {{TEST}}
pub fn area( // {{CONTEXT}}
  shape: Shape,
) -> Float { // {{CONTEXT}}
  // function body




  case shape { // {{CONTEXT}}
    // case body





    Circle(radius) -> radius *. radius *. pi // {{CURSOR}}
    _ -> 0.0
  }
}

// {{TEST}}
pub fn describe(number: Int) { // {{CONTEXT}}
  // body





  case number > 0 { // {{CONTEXT}}
    // case body





    True -> { // {{CONTEXT}}
      // clause block





      let message = "positive"

      echo message // {{CURSOR}}
    }
    False -> todo as "negative"
  }
}

// {{TEST}}
pub fn loop(items: List(Int)) -> Int { // {{CONTEXT}}
  // body





  case items { // {{CONTEXT}}
    // case body





    [] -> 0
    [first, ..rest] -> { // {{CONTEXT}}
      // clause block





      let total = first

      case rest { // {{CONTEXT}}
        // nested case body





        [] -> total // {{CURSOR}}
        _ -> total
      }
    }
  }
}

// {{TEST}}
pub fn transform(value: Int) -> Int { // {{CONTEXT}}
  let double = fn(number: Int) -> Int { // {{CONTEXT}}
    // anonymous body





    number * 2 // {{CURSOR}}
  }

  double(value)
}

// {{TEST}}
pub fn with_use(path: String) -> Result(Int, Nil) { // {{CONTEXT}}
  // body




  use value <- result.try(path)
  let doubled = value * 2

  Ok(doubled) // {{CURSOR}}
}

// {{TEST}}
pub fn pair(first: Int, second: Int) { // {{CONTEXT}}
  // body





  case first, second { // {{CONTEXT}}
    // case body





    0, 0 -> echo "both zero" // {{CURSOR}}
    n, _ -> echo n
    _, m -> echo m
  }
}