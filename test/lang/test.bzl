# {{TEST}}
def function_definition(): # {{CONTEXT}}
    """


    {{CURSOR}}"""
    if True: # {{CONTEXT}}




        "{{CURSOR}}"

# {{TEST}}
def function_definition_2(): # {{CONTEXT}}
    native.genrule( # {{CONTEXT}}
        name = "genrule",


        # {{CURSOR}}
    )

# {{TEST}}
LIST = [ # {{CONTEXT}}



    "{{CURSOR}}",
]
# {{TEST}}
DICT = { # {{CONTEXT}}
    "key": "value",
    "dict_key": { # {{CONTEXT}}
        "key": "value",
        "list_key": [ # {{CONTEXT}}



            "{{CURSOR}}",
        ],
    }
}
