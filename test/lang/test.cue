package main
// {{TEST}}
import ( // {{CONTEXT}}




	"strings"



	"encoding/json" // {{CURSOR}}
)
// {{TEST}}
jsonVal: json.Marshal({ // {{CONTEXT}}





	hello: strings.ToUpper("world")





	list: [1, 2]
	nested: foo: "bar" // {{CURSOR}}
})

apps: ["nginx", "express", "postgres"]
#labels: [string]: string
// {{TEST}}
stack: { // {{CONTEXT}}
	let local = { // {{CONTEXT}}







		name: "Alice"

	    // {{CURSOR}}
	} // {{POPCONTEXT}}
	local	

	injected: _ @tag(inj, type=int)



	for i, app in apps
		if app != "nginx" {









			"\(app)": {
				if app == "postgres" {








					isPostgres: true
				}


				name:   app
				labels: #labels & {





					app:  "foo"
					tier: "\(i)"
				}
			}
		}
}
