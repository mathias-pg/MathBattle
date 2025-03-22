extends Node2D

var target_score
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize() 
	target_score = randi() % (150 - 80 + 1) + 80
	$LabelScore.text = str(target_score)
