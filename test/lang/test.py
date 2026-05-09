# {{TEST}}
def hello(name: str, age: int) -> None: # {{CONTEXT}}
    print(f"Hello {name}! You are {age} years old.")



    # {{CURSOR}}

# {{TEST}}
def hello2(                # {{CONTEXT}}
        name: str,         # {{CONTEXT}}
        age: int) -> None: # {{CONTEXT}}
    # comment




    name = 'barry' # {{CURSOR}}
