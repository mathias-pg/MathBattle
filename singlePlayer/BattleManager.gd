extends Node

enum Turn { PLAYER, BOT }
var current_turn: Turn = Turn.PLAYER

@onready var battle_timer = $BattleTimer

@onready var label_tour = $"../LabelTour"
@onready var target_score_label = $"../LabelScore"
@onready var player_hand = $"../PlayerHand"
@onready var enemy_hand = $"../EnnemyHand"
@onready var player_slot = $"../CardSlotPlayer"
@onready var enemy_slot = $"../CardSlotOtherPlayer"
@onready var player_deck = $"../Deck"
@onready var enemy_deck = $"../OpponentDeck"

var target_score

func give_card_if_needed(hand, deck):
	if hand.player_hand.size() < 5:
		deck.draw_card()

func _ready():
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	randomize()
	target_score = randi() % (150 - 80 + 1) + 80
	target_score_label.text = "Score à atteindre : " + str(target_score)

	start_player_turn()


func start_player_turn():
	current_turn = Turn.PLAYER
	label_tour.text = "Tour du joueur"
	give_card_if_needed(player_hand, player_deck)
	set_player_cards_interaction(true)

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

func _on_bot_card_landed(card, slot):
	slot.card_in_slot = true

	if card.has_node("CardImage"):
		card.get_node("CardImage").visible = true

	var current_score = int(slot.label_score_reference.text)
	var new_score = apply_operation(current_score, card.card_sign, card.card_value)
	slot.label_score_reference.text = str(new_score)

	if check_win(slot):
		win_bot()
		return

	var wait_tween = get_tree().create_tween()
	wait_tween.tween_interval(1.0)
	wait_tween.tween_callback(Callable(self, "_on_bot_card_disappear").bind(card))
	slot.card_in_slot = false


func _on_bot_card_disappear(card):
	card.queue_free()
	start_player_turn()

func set_player_cards_interaction(active: bool) -> void:
	for card in player_hand.player_hand:
		if card.has_node("Area2D/CollisionShape2D"):
			var collision_shape = card.get_node("Area2D/CollisionShape2D")
			collision_shape.disabled = not active

class BotMove:
	var card
	var slot
	func _init(card, slot):
		self.card = card
		self.slot = slot

func choose_bot_move() -> BotMove:
	var enemy_score = int(enemy_slot.label_score_reference.text)
	var player_score = int(player_slot.label_score_reference.text)

	var best_move: BotMove = null
	var best_score = -INF  
	
	for card in enemy_hand.player_hand:
		var new_enemy_score = apply_operation(enemy_score, card.card_sign, card.card_value)
		var measure_a = evaluate_move(enemy_score, player_score, new_enemy_score, player_score, card.card_sign, true)
		if measure_a > best_score:
			best_score = measure_a
			best_move = BotMove.new(card, enemy_slot)

		var new_player_score = apply_operation(player_score, card.card_sign, card.card_value)
		var measure_b = evaluate_move(enemy_score, player_score, enemy_score, new_player_score, card.card_sign, false)
		if measure_b > best_score:
			best_score = measure_b
			best_move = BotMove.new(card, player_slot)

	return best_move

func evaluate_move(old_enemy_score: int, old_player_score: int, new_enemy_score: int, new_player_score: int, card_sign: String, place_on_enemy_slot: bool) -> float:

	var old_diff_enemy = abs(old_enemy_score - target_score)
	var old_diff_player = abs(old_player_score - target_score)
	var new_diff_enemy = abs(new_enemy_score - target_score)
	var new_diff_player = abs(new_player_score - target_score)

	var delta_enemy = old_diff_enemy - new_diff_enemy  
	var delta_player = new_diff_player - old_diff_player 

	var score = delta_enemy * 2.0 + delta_player

	if place_on_enemy_slot and new_diff_enemy == 0:
		score += 9999

	if place_on_enemy_slot and (card_sign == "-" or card_sign == "÷") and new_diff_enemy != 0:
		score -= 10

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


func check_win(slot) -> bool:
	var score = int(slot.label_score_reference.text)
	return score == target_score

func win_bot():
	set_player_cards_interaction(false)
	get_tree().change_scene_to_file("res://MainMenu/Loose.tscn")
