// {TEST}
type A {  // {{CONTEXT}}
  Aa
  Ab(x: Int, y: Int) // {{CURSOR}}
}

// {TEST}
fn func_a( // {CONTEXT}
  param: A,
) -> A { // {{CONTEXT}}
  echo 5
  let a = "test" // {{CURSOR}}
}

// {TEST}
fn func_b() -> A { // {{CONTEXT}}
  case 5 { // {{CONTEXT}}
    0 -> panic
    1 -> panic // {{CURSOR}}
    _ -> echo "ok"
  }
}
