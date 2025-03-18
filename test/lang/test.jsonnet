// {{TEST}}
local content = // {{CONTEXT}}
  local organizer(person) = // {{CONTEXT}}
    if person == 'Mary' then // {{CONTEXT}}



      'Mary will not be with us today, due to her health issue.' // {{CURSOR}}
    else
      std.format("Welcome %s as an honor guest for the party.", [person]);


      // {{POPCONTEXT}}
    // {{POPCONTEXT}}
  // {{CURSOR}}
  function(people) { // {{CONTEXT}}
    invited: [organizer(x) for x in people],
    participants: [ // {{CONTEXT}}
      std.format( // {{CONTEXT}}
      |||
        Welcome %s to the party!
        They're currently working as a %s for company %s.
      |||, [
        x.name,
        x.job,
        x.company, // {{CURSOR}}
      ]) // {{POPCONTEXT}}
      for x in [ // {{CONTEXT}}
        {
          name: 'Martin',
          job: 'Java Developer',
          company: 'A',

          // {{CURSOR}}
        },
        {
          name: 'Robert',
          job: 'DevOps Engineer',
          company: 'B',
        },
      ]
    ],
  };
// {{TEST}}
content([ // {{CONTEXT}}
  'Mary',
  'Peter',
  'James',
  'John',
  'Mathew', // {{CURSOR}}
])
