class Test { // {{CONTEXT}}
  def hello(name: String, age: Int): Unit = { // {{CONTEXT}}
    println(s"Hello $name! You are $age years old.")



    // {{CURSOR}}
  }
}
