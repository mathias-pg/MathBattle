extends Node2D

var card_in_slot = false
var label_score_reference

func _ready():
	label_score_reference = $Area2D/LabelScore

func on_card_dropped(card):
	var slot_score = int(label_score_reference.text)
	var sign = card.card_sign
	var value = card.card_value

	var popup_scene = load("res://Calculs/CalculationPopUp.tscn")
	var popup = popup_scene.instantiate()
	
	popup.connect("calculation_done", Callable(self, "_on_calculation_done").bind(card), CONNECT_ONE_SHOT)
	
	get_tree().get_current_scene().add_child(popup)
	
	popup.start_calculation(slot_score, sign, value)


func _on_calculation_done(success: bool, card):
	if success:
		var slot_score = int(label_score_reference.text)

		match card.card_sign:
			"+":
				slot_score += card.card_value
			"-":
				slot_score -= card.card_value
			"x":
				slot_score *= card.card_value
			"÷":
				if card.card_value != 0:
					slot_score = int(slot_score / card.card_value)

		label_score_reference.text = str(slot_score)

		var current_scene = get_tree().get_current_scene()

		if slot_score == current_scene.target_score:
			if self.name == "CardSlotPlayer":
				get_tree().change_scene_to_file("res://MainMenu/Victory.tscn")
			else:
				get_tree().change_scene_to_file("res://MainMenu/Loose.tscn")

	fade_out_and_remove_card(card)


func fade_out_and_remove_card(card):
	card.queue_free()
	card_in_slot = false
