extends Node2D

var target_score

func _ready():
	randomize()  
	target_score = randi() % (150 - 80 + 1) + 80
	$LabelScore.text = str(target_score)
