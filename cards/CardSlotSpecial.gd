extends Node2D

var card_in_slot = false
var label_score_reference
const DEFAULT_CARD_MOUV_SPEED = 0.1
var HAND_COUNT = 5

func _ready():
	label_score_reference = $Area2D/LabelScore

func on_card_dropped(card):
	var slot_score = int(label_score_reference.text)
	var sign = card.card_sign
	var value = card.card_value

	var popup_scene = load("res://Calculs/CalculationPopUp.tscn")
	var popup = popup_scene.instantiate()
	
	if sign == "?" or sign == "inverse" or sign == "swap_deck" or sign == "swap":
		
		if sign == "?":
			var ops = [
				"+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9",
				"-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9",
				"x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9",
				"÷2", "÷3", "÷4", "÷5", "÷6", "÷7", "÷8", "÷9"
			]
			var random_index = randi() % ops.size()
			var random_op = ops[random_index]
			var op_sign = random_op.substr(0,1)
			var op_value = int(random_op.substr(1, random_op.length()-1))
			slot_score = apply_operation(slot_score, op_sign, op_value)
			
		elif sign == "inverse":
			slot_score = -slot_score
			
		elif sign == "swap_deck":
			if self.name == "CardSlotPlayerSpecial":
				var player_hand_node = get_node("../PlayerHandSpecial")
				var current_cards = player_hand_node.player_hand.duplicate()
				for c in current_cards:
					c.queue_free()
				player_hand_node.player_hand.clear()
				
				var card_database_reference = preload("res://Cards/CardDataBaseSpecial.gd")
				var card_scene = preload("res://Cards/Card.tscn")
				
				for i in range(HAND_COUNT):
					var weighted_keys := []
					for key in card_database_reference.CARD_TEXTURES.keys():
						if key.begins_with("+"):
							for j in range(4):
								weighted_keys.append(key)
						elif key.begins_with("-"):
							for j in range(2):
								weighted_keys.append(key)
						elif key.begins_with("x") or key.begins_with("÷"):
							for j in range(2):
								weighted_keys.append(key)
						elif key == "?" or key == "deck_swap" or key == "swap" or key == "inverse":
							weighted_keys.append(key)
					
					var random_index = randi() % weighted_keys.size()
					var random_key = weighted_keys[random_index]
					var random_path = card_database_reference.CARD_TEXTURES[random_key]
					
					var new_card = card_scene.instantiate()
					var sprite_node = new_card.get_node("CardImage")
					sprite_node.texture = load(random_path)
					get_node("../CardManagerSpecial").add_child(new_card)
					
					new_card.name = "Card"
					new_card.card_value = card_database_reference.CARD_VALUES[random_key]
					new_card.card_sign = card_database_reference.CARD_SIGNS[random_key]
					player_hand_node.add_card_to_hand(new_card, DEFAULT_CARD_MOUV_SPEED)
				player_hand_node.update_hand_positions(DEFAULT_CARD_MOUV_SPEED)
				
			elif self.name == "CardSlotOtherPlayerSpecial":
				var enemy_hand_node = get_node("../EnnemyHandSpecial")
				var current_cards = enemy_hand_node.player_hand.duplicate()
				for c in current_cards:
					c.queue_free()
				enemy_hand_node.player_hand.clear()
				
				var card_database_reference = preload("res://Cards/CardDataBaseSpecial.gd")
				var card_scene = preload("res://Cards/EnnemyCard.tscn")
				
				for i in range(HAND_COUNT):
					var weighted_keys := []
					for key in card_database_reference.CARD_TEXTURES.keys():
						if key.begins_with("+"):
							for j in range(4):
								weighted_keys.append(key)
						elif key.begins_with("-"):
							for j in range(2):
								weighted_keys.append(key)
						elif key.begins_with("x") or key.begins_with("÷"):
							for j in range(2):
								weighted_keys.append(key)
						elif key == "?" or key == "deck_swap" or key == "swap" or key == "inverse":
							weighted_keys.append(key)
					
					var random_index = randi() % weighted_keys.size()
					var random_key = weighted_keys[random_index]
					var random_path = card_database_reference.CARD_TEXTURES[random_key]
					
					var new_card = card_scene.instantiate()
					var sprite_node = new_card.get_node("CardImage")
					sprite_node.visible = false
					sprite_node.texture = load(random_path)
					get_node("../CardManagerSpecial").add_child(new_card)
					
					new_card.name = "Card"
					new_card.card_value = card_database_reference.CARD_VALUES[random_key]
					new_card.card_sign = card_database_reference.CARD_SIGNS[random_key]
					enemy_hand_node.add_card_to_hand(new_card, DEFAULT_CARD_MOUV_SPEED)
				enemy_hand_node.update_hand_positions(DEFAULT_CARD_MOUV_SPEED)
		
			
		if sign == "swap":
			if self.name == "CardSlotPlayerSpecial":
				var tmp = slot_score
				slot_score = int($"../CardSlotOtherPlayerSpecial".label_score_reference.text)
				$"../CardSlotOtherPlayerSpecial".label_score_reference.text = str(tmp)
			elif self.name == "CardSlotOtherPlayerSpecial":
				var tmp = slot_score
				slot_score = int($"../CardSlotPlayerSpecial".label_score_reference.text)
				$"../CardSlotPlayerSpecial".label_score_reference.text = str(tmp)
		
		label_score_reference.text = str(slot_score)

		var current_scene = get_tree().get_current_scene()

		if slot_score == current_scene.target_score:
			if self.name == "CardSlotPlayerSpecial":
				get_tree().change_scene_to_file("res://MainMenu/Victory.tscn")
			else:
				get_tree().change_scene_to_file("res://MainMenu/Loose.tscn")

		fade_out_and_remove_card(card)
		var battle_manager = $"../BattleManagerSpecial"
		await get_tree().create_timer(1).timeout
		battle_manager.end_player_turn()
	else:
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
			if self.name == "CardSlotPlayerSpecial":
				get_tree().change_scene_to_file("res://MainMenu/Victory.tscn")
			else:
				get_tree().change_scene_to_file("res://MainMenu/Loose.tscn")

	fade_out_and_remove_card(card)
	
	var battle_manager = $"../BattleManagerSpecial"
	battle_manager.end_player_turn()


func fade_out_and_remove_card(card):
	card.queue_free()
	card_in_slot = false
	
func apply_operation(current: int, sign: String, value: int) -> int:
	match sign:
		"+":
			return current + value
		"-":
			return current - value
		"x":
			return current * value
		"÷":
			if value != 0:
				return int(current / value)
			else:
				return current
	return current
