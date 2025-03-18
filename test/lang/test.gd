# {{TEST}}
enum Test { # {{CONTEXT}}


	VALUE1,



	VALUE2,



	VALUE3,

    # {{CURSOR}}
}
# {{TEST}}
func test_function(): # {{CONTEXT}}
	


	var test_value = Test.Value1


	if test_value = Test.VALUE1: # {{CONTEXT}}
		
		
		
		

		# {{CURSOR}}
		pass
	
	elif test_value = Test.VALUE2: # {{CONTEXT}}
		
		
		


		for i in 5: # {{CONTEXT}}
			
			
			
			

			# {{CURSOR}}
			pass # {{POPCONTEXT}}
		# {{POPCONTEXT}}
	else: # {{CONTEXT}}
		
		
		
		
		# {{CURSOR}}
		while true: # {{CONTEXT}}
			
			
			
			
			# {{CURSOR}}
			pass # {{POPCONTEXT}}
		# {{POPCONTEXT}}
	# {{POPCONTEXT}}
	match test_value: # {{CONTEXT}}
		Test.VALUE1: # {{CONTEXT}}
			
			
			
			
			
			
			print("foo") # {{CURSOR}}
			# {{POPCONTEXT}}
		Test.VALUE2: # {{CONTEXT}}
			
			
			
			
			print("bar") # {{CURSOR}}
# {{TEST}}
class HelpClass: # {{CONTEXT}}
	
	
	
	
	
	var class_variable
	func class_function(): # {{CONTEXT}}
		
		
		
		
		
		
		print("foobar") # {{CURSOR}}










