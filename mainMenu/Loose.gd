extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play("animation_lose")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_menu_button_down() -> void:
	get_tree().change_scene_to_file("res://MainMenu/PageAccueil.tscn") 
