extends Button

var dialogue:Dialogue = Dialogue.new()
var conversation_active = false
var end_conversation_on_next_input = false

func load_dialogue() -> void:
	dialogue.add("Hello, I am a button.")
	dialogue.add("I don't know how this will work but I hope it works great.")
	dialogue.add("Is 3 less than 4?")
	dialogue.jump_if( funcref(self, "check_condition" ), "LABEL_TRUE" )
	dialogue.label("LABEL_FALSE")
	dialogue.add("I guess not...", true)
	dialogue.label("LABEL_TRUE")
	dialogue.set_start_label("LABEL_PART_2")
	dialogue.add("It sure is.", true)
	
	dialogue.label("LABEL_PART_2")
	dialogue.set_start_label("LABEL_LADS")
	dialogue.add("Glad we figured that one out.")
	dialogue.label("LABEL_LADS")
	dialogue.run_func( funcref(self, "squirt_particle_lad" ) )
	dialogue.run_func( funcref(self, "squirt_particle_lad" ) )
	dialogue.run_func( funcref(self, "squirt_particle_lad" ) )
	dialogue.run_func( funcref(self, "squirt_particle_lad" ) )
	dialogue.add("Whoops, I dropped my particle lads")
	dialogue.validate()

func _ready():
	load_dialogue()

func check_condition() -> bool:
	return 3 < 4

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
