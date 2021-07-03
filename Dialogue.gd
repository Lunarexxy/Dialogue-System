class_name Dialogue
extends Reference

# Holds all the lines of dialogue as an array of arrays.
# Each inner array is the line data for a given line.
# Line data looks like ["Line of dialogue", finish_conversation_bool]
# If choices are appended to the line, it will add two values per choice:
# ["Line text", finish, "Choice 1 text", "Choice 1 target label", "Choice 2 text", "Choice 2 target label"]
var line_tree:Array

# Holds all the labels.
# key=label_name:String, value=line_index:int
var label_list:Dictionary
# Stores all the lines where conditional jumps should run, their functions, and their target labels.
# key=line_index, value=Array[function:FuncRef, target_label_if_true:String, target_label_if_false:String]
var conditional_jump_list:Dictionary
# Stores all the lines where custom functions need to run, and the FuncRefs to them.
# Each line may have any amount of functions to run.
# key=line_index, value=Array[function:FuncRef...]
var functions_to_run_list:Dictionary
# Holds all the lines where a start label needs to change.
# key=line_index, value="Target label"
var start_label_list:Dictionary

# Where to start the next conversation from
var start_line:int = 0
# Which line is currently being read. Gets reset by start_conversation.
var current_line:int = 0




### Writer facing functions (for the person writing the dialogue tree)

# Add a line of dialogue.
# The Dialogue class doesn't handle the finish_conversation bool,
# that's for the dialogue renderer or some other state manager to handle.
func add( line_text:String, finish_conversation:bool = false ) -> void:
	var new_line:Array = [line_text, finish_conversation]
	line_tree.append(new_line)

# Add a single choice to the PREVIOUS line of dialogue.
# The choice and its target label will be appended to the previous line's data.
# This lets you chain as many choices as you want,
# adding them to only one line of dialogue.
func choice( choice_text:String, target_label:String = "" ) -> void:
	var line_to_append_to = line_tree.size() - 1
	line_tree[line_to_append_to].append(choice_text)
	line_tree[line_to_append_to].append(target_label)

# Add a named label to the NEXT line of dialogue.
# There must be a line of dialogue after it, or the label will be invalid.
func label( label_name:String ) -> void:
	assert( !label_list.has(label_name), "Dialogue Error on line "+str(line_tree.size())+": Two or more labels are using the same name ("+label_name+") in the same dialogue tree!" )
	label_list[label_name] = line_tree.size()

# Conditional jump.
# Set a given function to be run when advancing to the next line, and
# jump to specified labels if the function returns true or false.
# A jump target of "" is interpreted as "advance to the next line as normal."
func jump_if( expression_func:FuncRef, jump_to_if_true:String, jump_to_if_false:String="" ):
	assert( !conditional_jump_list.has( line_tree.size() ), "Dialogue Error on line "+str(line_tree.size())+": Only one conditional jump may exist per line." )
	conditional_jump_list[line_tree.size()] = [expression_func, jump_to_if_true, jump_to_if_false]

# Custom function.
# Set a given function to be run when advancing to the next line
# It's good practice to ensure that the function is defined inside the
# script that holds the Dialogue instance, if possible. If not, just be careful.
func run_func( function:FuncRef ) -> void:
	assert( function.is_valid(), "Dialogue Error on line "+str(line_tree.size())+". Attempted to add invalid function "+str(function) )
	if !functions_to_run_list.has(line_tree.size()):
		functions_to_run_list[line_tree.size()] = []
	functions_to_run_list[line_tree.size()].append(function)

# Sets the given label to be the new starting position for new conversations.
func set_start_label( label_name:String ) -> void:
	start_label_list[line_tree.size()] = label_name





### Non-writer facing functions (internal stuff and data retrieval mostly)
### (Anything prepended with _ is for internal use only.

# Gets the data at the current line, as a reference
# For internal use only, should not be called by other objects.
func _get_line_data() -> Array:
	return line_tree[current_line]

# Sets start positions, runs custom functions, and conditional jumps, in that order.
# After all that is done, it will return line data from whichever line it ends up on.
# For internal use only, should not be called by other objects.
func _run_currrent_line() -> Array:
	
	# TODO: Needs testing
	# Set the new start line, if any is specified for this line.
	if start_label_list.has(current_line):
		if !label_list.has( start_label_list[current_line] ):
			push_error( "Dialogue Runtime Error: Attempted to set a new start label at nonexistent label "+start_label_list[current_line]+". Attempt was discarded." )
		else:
			start_line = label_list[ start_label_list[current_line] ]
	
	# Run all the functions marked for this line (if any)
	if functions_to_run_list.has(current_line):
		for func_ref in functions_to_run_list[current_line]:
			if !func_ref.is_valid():
				push_error( "Dialogue Runtime Error: Attempted to run invalidated FuncRef function \""+func_ref.function+"\" on line "+str(current_line)+". Function not called." )
			else:
				func_ref.call_func()
	
	# Run the jump and do the jump (if any)
	if conditional_jump_list.has(current_line):
		var func_ref = conditional_jump_list[current_line][0]
		var jump_to_if_true = conditional_jump_list[current_line][1]
		var jump_to_if_false = conditional_jump_list[current_line][2]
		
		if jump_to_if_true != "" and !label_list.has(jump_to_if_true):
			push_error( "Dialogue Runtime Error: The target label \""+jump_to_if_true+"\" on line "+str(current_line)+" has not been defined! Ignoring target.")
			jump_to_if_true = ""
		if jump_to_if_false != "" and !label_list.has(jump_to_if_false):
			push_error( "Dialogue Runtime Error: The target label \""+jump_to_if_false+"\" on line "+str(current_line)+" has not been defined! Ignoring target.")
			jump_to_if_false = ""
		
		if !func_ref.is_valid():
			push_error( "Dialogue Runtime Error: Attempted to run invalidated FuncRef function \""+func_ref.function+"\" in conditional jump on line "+str(current_line)+". Ignoring jump." )
			return _get_line_data()
		else:
			var result:bool = func_ref.call_func()
			
			if result:
				if jump_to_if_true != "":
					current_line = label_list[jump_to_if_true]
				else:
					current_line += 1
				return _run_currrent_line()
			else:
				if jump_to_if_false != "":
					current_line = label_list[jump_to_if_false]
				else:
					current_line += 1
				return _run_currrent_line()
	else:
		# If this is the last line, it should finish the conversation.
		if current_line == line_tree.size()-1:
			line_tree[current_line][1] = true
		
		return _get_line_data()

# Advances the dialogue by one line.
# This is what should be used by user input handlers to advance dialogue.
func advance() -> Array:
	current_line += 1
	return _run_currrent_line().duplicate(true)

# Validates that the dialogue tree is functional.
# It crashes if the validation fails, as a broken dialogue tree means a broken game.
# Put this at the end of whatever you use to load in the dialogue.
func validate() -> void:
	# Asserts don't work in released builds, so no point validating there.
	# This means you REALLY should run validate() from the editor before releasing.
	if !OS.is_debug_build(): return
	
	# Fail if any labels are pointed out of bounds
	for label in label_list:
		assert(label_list[label] < line_tree.size(), "Dialogue Validation Error: Label \""+str(label)+"\" was out of bounds." )
		
	# Fail if any start label doesn't exist
	for start_label in start_label_list.values():
		assert(label_list.has(start_label), "Dialogue Validation Error: Cannot set start position at label \""+str(start_label)+"\" because the label doesn't exist!" )
	
	# Fail if any choice label doesn't exist 
	for line in line_tree:
		# Any line data with more than 2 entries (text and finish_convo bool)
		# must contain at least one choice. Those choices may have invalid labels.
		if line.size() > 2:
			# The first choice label is at index 3, then every other from there.
			for line_data_index in range(3, line_tree.size(), 2):
				var label = line[line_data_index]
				if label == "":
					continue
				assert( !label_list.has(line[line_data_index]), "Dialogue Validation Error: A choice is pointed at nonexistent label "+label )
					
			pass
	
	# Fail if the last conditional jump has an auto-advance that would go out of bounds
	if conditional_jump_list.size() > 0 and conditional_jump_list.has(line_tree.size()-1):
		assert( conditional_jump_list[line_tree.size()-1][1] != ""
		    and conditional_jump_list[line_tree.size()-1][2] != "",
			"Dialogue Validation Error: The last line of dialogue has a conditional jump that may advance out of bounds! It must have a target label for both true and false.")



func start_conversation( at_label:String="" ) -> Array:
	if at_label == "":
		current_line = start_line
	else:
		if !label_list.has( at_label ):
			push_error( "Dialogue Runtime Error: Attempted to start conversation at undefined label \""+at_label+"\". Label parameter will be ignored and conversation will start at the current start position." )
			current_line = start_line
		else:
			current_line = label_list[at_label]
	return _run_currrent_line().duplicate(true)

func jump_to_label( label_name:String ) -> Array:
	if !label_list.has( label_name ):
		push_error( "Dialogue Runtime Error: Attempted to jump to undefined label \""+label_name+"\". Label parameter will be ignored and conversation will advance as normal." )
		return advance().duplicate(true)
	else:
		current_line = label_list[label_name]
		return _run_currrent_line().duplicate(true)


# Functions useful for save games.
# Since all other dialogue data is created at runtime and never really changes,
# only start_line and current_line need to be saved.
func serialize() -> Array:
	return [str(start_line), str(current_line)]
func deserialize(set_start_line:int, set_current_line:int) -> void:
	start_line = set_start_line
	current_line = set_current_line
