local content =
  local organizer(person) =
    if person == 'Mary' then
      'Mary will not be with us today, due to her health issue.'
    else
      std.format("Welcome %s as an honor guest for the party.", [person]);

  function(people) {
    invited: [organizer(x) for x in people],
    participants: [
      std.format(|||
        Welcome %s to the party!
        They're currently working as a %s for company %s.
      |||, [
        x.name,
        x.job,
        x.company,
      ])
      for x in [
        {
          name: 'Martin',
          job: 'Java Developer',
          company: 'A',
        },
        {
          name: 'Robert',
          job: 'DevOps Engineer',
          company: 'B',
        },
      ]
    ],
  };

content([
  'Mary',
  'Peter',
  'James',
  'John',
  'Mathew',
])
