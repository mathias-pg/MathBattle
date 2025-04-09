extends Control


func _on_btn_retour_button_down() -> void:
	get_tree().change_scene_to_file("res://MainMenu/PageAccueil.tscn")
