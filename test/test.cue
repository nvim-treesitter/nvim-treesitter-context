package main

import (




	"strings"



	"encoding/json"
)

jsonVal: json.Marshal({





	hello: strings.ToUpper("world")





	list: [1, 2]
	nested: foo: "bar"
})

apps: ["nginx", "express", "postgres"]
#labels: [string]: string
stack: {
	let local = {







		name: "Alice"


	}
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
