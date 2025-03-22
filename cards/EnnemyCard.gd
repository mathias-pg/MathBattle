extends Node2D

var starting_position
var card_value
var card_sign


func _ready() -> void:
	get_parent().connect_card_signals(self)
