#!/usr/bin/env nu

# {{TEST}}

def foo [] { # {{CONTEXT}}
  let bar = [1,2,3,4,5]
  for n in $bar { # {{CONTEXT}}

    if true { # {{CONTEXT}}

      # {{CURSOR}}
    }

    # {{CURSOR}}
  }

  # {{CURSOR}}
}
# {{POPCONTEXT}}

# {{TEST}}

module bar { # {{CONTEXT}}

  # {{CURSOR}}
}


# {{TEST}}

export-env { # {{CONTEXT}}

  $env.FOO = "bar"

  # {{CURSOR}}
}

