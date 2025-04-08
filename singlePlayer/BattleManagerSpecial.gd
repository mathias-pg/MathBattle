extends Node

const DEFAULT_CARD_MOUV_SPEED = 0.1
var HAND_COUNT = 5

enum Turn { PLAYER, BOT }
enum BotLevel { EASY, MEDIUM, HARD }

var current_turn: Turn = Turn.PLAYER
@export var current_bot_level: BotLevel = BotLevel.HARD

@onready var battle_timer = $BattleTimer
@onready var label_diff = $"../LabelDifficulte"
@onready var label_tour = $"../LabelTour"
@onready var target_score_label = $"../LabelScore"
@onready var player_hand = $"../PlayerHandSpecial"
@onready var enemy_hand = $"../EnnemyHandSpecial"
@onready var player_slot = $"../CardSlotPlayerSpecial"
@onready var enemy_slot = $"../CardSlotOtherPlayerSpecial"
@onready var player_deck = $"../DeckSpecial"
@onready var enemy_deck = $"../OpponentDeckSpecial"

var target_score

func give_card_if_needed(hand, deck):
	# Donne une carte s'il y a moins de 5 cartes dans la main
	if hand.player_hand.size() < 5:
		for i in range(hand.player_hand.size(), 5):
			deck.draw_card()

func _ready():
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	randomize()
	target_score = randi() % (150 - 80 + 1) + 80
	target_score_label.text = "Score à atteindre : " + str(target_score)
	
	# Gestion de la difficulté globale à partir d'une variable globale (GlobalDifficulty)
	match GlobalDifficulty.difficulty:
		"easy":
			current_bot_level = BotLevel.EASY
			label_diff.text = "Easy"
			label_diff.add_theme_color_override("font_color", Color(0, 1, 0))
		"medium":
			current_bot_level = BotLevel.MEDIUM
			label_diff.text = "Medium"
			label_diff.add_theme_color_override("font_color", Color(1, 1, 0))
		"hard":
			current_bot_level = BotLevel.HARD
			label_diff.text = "Hard"
			label_diff.add_theme_color_override("font_color", Color(1, 0, 0))
	
	start_player_turn()

func start_player_turn():
	current_turn = Turn.PLAYER
	label_tour.text = "Tour du joueur"
	give_card_if_needed(player_hand, player_deck)
	set_player_cards_interaction(true)
	# Le joueur joue ; à la fin de son action, il appelle end_player_turn()

func end_player_turn():
	start_bot_turn()

func start_bot_turn():
	current_turn = Turn.BOT
	label_tour.text = "Tour du bot"
	set_player_cards_interaction(false)
	give_card_if_needed(enemy_hand, enemy_deck)
	
	await opponent_turn()
	
	var move = choose_bot_move()
	if move:
		var chosen_card = move.card
		var target_slot = move.slot
		enemy_hand.remove_card_from_hand(chosen_card)
		animate_bot_card_drop(chosen_card, target_slot)
	else:
		start_player_turn()

func opponent_turn() -> void:
	battle_timer.start()
	await battle_timer.timeout

func animate_bot_card_drop(card, slot):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", slot.position, 0.5)
	tween.tween_callback(Callable(self, "_on_bot_card_landed").bind(card, slot))
	await get_tree().create_timer(0.5).timeout
	$"../AudioStreamPlayerCardSound".play()

func _on_bot_card_landed(card, slot):
	slot.card_in_slot = true

	if card.has_node("CardImage"):
		card.get_node("CardImage").visible = true

	if card.card_sign == "?" or card.card_sign == "inverse" or card.card_sign == "swap_deck" or card.card_sign == "swap":
		var slot_score = int(slot.label_score_reference.text)
		if card.card_sign == "?":
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
			
		elif card.card_sign == "inverse":
			slot_score = -slot_score
			
		elif card.card_sign == "swap_deck":
			if slot.name == "CardSlotPlayerSpecial":
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
				
			elif slot.name == "CardSlotOtherPlayerSpecial":
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
		
			
		elif card.card_sign == "swap":
			if slot.name == "CardSlotPlayerSpecial":
				var tmp = slot_score
				slot_score = int($"../CardSlotOtherPlayerSpecial".label_score_reference.text)
				$"../CardSlotOtherPlayerSpecial".label_score_reference.text = str(tmp)
			elif slot.name == "CardSlotOtherPlayerSpecial":
				var tmp = slot_score
				slot_score = int($"../CardSlotPlayerSpecial".label_score_reference.text)
				$"../CardSlotPlayerSpecial".label_score_reference.text = str(tmp)
		
		slot.label_score_reference.text = str(slot_score)
	else:
		var current_score = int(slot.label_score_reference.text)
		var new_score = apply_operation(current_score, card.card_sign, card.card_value)
		slot.label_score_reference.text = str(new_score)

	var wait_tween = get_tree().create_tween()
	wait_tween.tween_interval(1.0)
	wait_tween.tween_callback(Callable(self, "_on_bot_card_disappear").bind(card))
	slot.card_in_slot = false
	
	var current_scene = get_tree().get_current_scene()
	var slot_score = int(slot.label_score_reference.text)
	if slot_score == current_scene.target_score:
		if self.name == "CardSlotPlayerSpecial":
			get_tree().change_scene_to_file("res://MainMenu/Victory.tscn")
		else:
			get_tree().change_scene_to_file("res://MainMenu/Loose.tscn")

func _on_bot_card_disappear(card):
	card.queue_free()
	start_player_turn()

func set_player_cards_interaction(active: bool) -> void:
	for card in player_hand.player_hand:
		if card.has_node("Area2D/CollisionShape2D"):
			var collision_shape = card.get_node("Area2D/CollisionShape2D")
			collision_shape.disabled = not active

# --- Classe interne pour représenter un coup ---
class BotMove:
	var card
	var slot
	func _init(card, slot):
		self.card = card
		self.slot = slot

func choose_random_move() -> BotMove:
	if enemy_hand.player_hand.size() == 0:
		return null
	var card = enemy_hand.player_hand[randi() % enemy_hand.player_hand.size()]
	if randi() % 2 == 0:
		return BotMove.new(card, enemy_slot)
	else:
		return BotMove.new(card, player_slot)

func choose_medium_move() -> BotMove:
	# Niveau moyen : évalue les coups en calculant l'amélioration sur sa table
	var enemy_score = int(enemy_slot.label_score_reference.text)
	var best_move: BotMove = null
	var best_improvement = 0
	for card in enemy_hand.player_hand:
		var new_enemy_score = apply_operation(enemy_score, card.card_sign, card.card_value)
		var improvement = abs(enemy_score - target_score) - abs(new_enemy_score - target_score)
		# Si la carte est spéciale, on ajoute un bonus léger au niveau medium
		if card.card_sign in ["?", "inverse", "swap_deck", "swap"]:
			improvement += 2
		if improvement > best_improvement:
			best_improvement = improvement
			best_move = BotMove.new(card, enemy_slot)
	if best_move:
		return best_move
	else:
		return choose_random_move()

func choose_hard_move() -> BotMove:
	# Niveau difficile : évalue en tenant compte de sa table et celle du joueur
	var enemy_score = int(enemy_slot.label_score_reference.text)
	var player_score = int(player_slot.label_score_reference.text)
	var best_move: BotMove = null
	var best_score = -INF  
	
	for card in enemy_hand.player_hand:
		# Hypothèse A : la jouer sur sa propre table
		var new_enemy_score = apply_operation(enemy_score, card.card_sign, card.card_value)
		var measure_a = evaluate_move(enemy_score, player_score, new_enemy_score, player_score, card.card_sign, true)
		if measure_a > best_score:
			best_score = measure_a
			best_move = BotMove.new(card, enemy_slot)
		
		# Hypothèse B : la jouer sur la table du joueur
		var new_player_score = apply_operation(player_score, card.card_sign, card.card_value)
		var measure_b = evaluate_move(enemy_score, player_score, enemy_score, new_player_score, card.card_sign, false)
		if measure_b > best_score:
			best_score = measure_b
			best_move = BotMove.new(card, player_slot)
	
	return best_move

func choose_bot_move() -> BotMove:
	match current_bot_level:
		BotLevel.EASY:
			return choose_random_move()
		BotLevel.MEDIUM:
			return choose_medium_move()
		BotLevel.HARD:
			return choose_hard_move()
		_:
			return choose_random_move()

func evaluate_move(old_enemy_score: int, old_player_score: int, new_enemy_score: int, new_player_score: int, card_sign: String, place_on_enemy_slot: bool) -> float:
	var old_diff_enemy = abs(old_enemy_score - target_score)
	var old_diff_player = abs(old_player_score - target_score)
	var new_diff_enemy = abs(new_enemy_score - target_score)
	var new_diff_player = abs(new_player_score - target_score)
	
	var delta_enemy = old_diff_enemy - new_diff_enemy  # positif si amélioration pour le bot
	var delta_player = new_diff_player - old_diff_player  # positif si le joueur s'éloigne
	var score = delta_enemy * 2.0 + delta_player
	
	# Bonus pour victoire immédiate
	if place_on_enemy_slot and new_diff_enemy == 0:
		score += 9999
	
	# Pénalité pour utiliser "-" ou "÷" sans gain
	if place_on_enemy_slot and (card_sign == "-" or card_sign == "÷") and new_diff_enemy != 0:
		score -= 10
	
	# Bonus additionnel pour l'utilisation de cartes spéciales
	if card_sign in ["?", "inverse", "swap_deck", "swap"]:
		match current_bot_level:
			BotLevel.HARD:
				score += 5
			BotLevel.MEDIUM:
				score += 2
	
	return score

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
