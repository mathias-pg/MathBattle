extends Control 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStreamPlayer.play()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_btn_quitter_button_down() -> void:
	get_tree().quit()
	$AudioStreamPlayer.stop()


func _on_btn_bot_button_down() -> void:
	get_tree().change_scene_to_file("res://SinglePlayer/SinglePlayer.tscn")
	$AudioStreamPlayer.stop()


func _on_btn_joueur_button_down() -> void:
	get_tree().change_scene_to_file("res://MultiPlayer/ChoiceHoteClient.tscn")
	$AudioStreamPlayer.stop()
