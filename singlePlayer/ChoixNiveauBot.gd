extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("show_buttons")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_easy_button_down() -> void:
	$AudioStreamPlayer.stop()
	GlobalDifficulty.difficulty = "easy"
	get_tree().change_scene_to_file("res://SinglePlayer/SinglePlayer.tscn")


func _on_btn_medium_button_down() -> void:
	$AudioStreamPlayer.stop()
	GlobalDifficulty.difficulty = "medium"
	get_tree().change_scene_to_file("res://SinglePlayer/SinglePlayer.tscn")


func _on_btn_hard_button_down() -> void:
	$AudioStreamPlayer.stop()
	GlobalDifficulty.difficulty = "hard"
	get_tree().change_scene_to_file("res://SinglePlayer/SinglePlayer.tscn")
