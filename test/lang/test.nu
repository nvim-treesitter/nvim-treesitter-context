#!/usr/bin/env nu

def foo [] {
  # comment
}

module bar {
  # comment
}

export-env {
  # comment
}

if true {
  # comment
}

try {
  # comment
} catch {
}

match "A" {
  # comment
  "A" => "B"
}

for x in 0..10 {
  # comment
}

while true {
  # comment
}

do {||
  print "foo"
  # comment
}

let foo = (
  ls
  | # context
  get name
  | # context
  first
)
