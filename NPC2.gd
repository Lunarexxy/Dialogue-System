extends Button

var dialogue:Dialogue = Dialogue.new()
var conversation_active = false
var end_conversation_on_next_input = false

var check_value = 1

func load_dialogue() -> void:
	dialogue.add("Hello, I am a conditional jump chain button.")
	dialogue.add("I exist to test conditional jump chains.")
	dialogue.add("I will use conditional jumps to count up from 1")
	dialogue.add("until I get to the value 6.")
	dialogue.add("You should only see the final line of the chain.")
	# The chain is intentionally confusing, but trust me, it works. Probably
	dialogue.jump_if( funcref(self, "is_value_six" ), "", "LABEL_TWO" )
	dialogue.add("Skip: This dialogue should never be displayed, as the jump should pass over it.")
	dialogue.label("LABEL_TWO")
	dialogue.jump_if( funcref(self, "is_value_six" ), "", "LABEL_THREE" )
	dialogue.add("2: This dialogue should never be displayed, as the jump should pass over it.")
	dialogue.label("LABEL_BROKEN")
	dialogue.add("This line should never be reached at all, but protects against an out-of-bounds auto advance on the last conditional jump.", true)
	dialogue.label("LABEL_FOUR")
	dialogue.jump_if( funcref(self, "is_value_six" ), "", "LABEL_FIVE" )
	dialogue.add("4: This dialogue should never be displayed, as the jump should pass over it.")
	dialogue.label("LABEL_SIX")
	dialogue.run_func( funcref(self, "squirt_particle_lad") )
	dialogue.add("6: The jump chain is finished.", true)
	dialogue.label("LABEL_THREE")
	dialogue.jump_if( funcref(self, "is_value_six" ), "", "LABEL_FOUR" )
	dialogue.add("3: This dialogue should never be displayed, as the jump should pass over it.")
	dialogue.label("LABEL_FIVE")
	dialogue.jump_if( funcref(self, "is_value_six" ), "LABEL_SIX", "LABEL_BROKEN")
	dialogue.add("5: This dialogue should never be displayed, as the jump should pass over it.")
	dialogue.validate()

func _ready():
	load_dialogue()

func is_value_six() -> bool:
	if check_value == 6: check_value = 1 #Wrap around
	check_value += 1
	return check_value == 6

func squirt_particle_lad() -> void:
	var particle_lad = preload("res://ParticleLad.tscn").instance()
	add_child(particle_lad)
	pass

func display_dialogue(line_data:Array) -> void:
	text = line_data[0]
	end_conversation_on_next_input = line_data[1]
	

func _on_pressed():
	if !conversation_active:
		display_dialogue( dialogue.start_conversation() )
		conversation_active = true
	else:
		if end_conversation_on_next_input:
			text = "(Conversation ended)"
			conversation_active = false
			end_conversation_on_next_input = false
		else:
			display_dialogue( dialogue.advance() )
