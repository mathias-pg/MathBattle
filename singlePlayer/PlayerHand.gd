extends Node2D

const HAND_COUNT = 0
const CARD_SCENE_PATH = "res://Cards/Card.tscn"
const CARD_WIDTH = 200
const HAND_Y_POSITION = 890
const DEFAULT_CARD_MOUV_SPEED = 0.1

var player_hand = []
var center_screen_x
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Cards/CardDataBase.gd")
	center_screen_x = get_viewport().size.x / 2

	var card_scene = preload(CARD_SCENE_PATH)

	for i in range(HAND_COUNT):
		# Tirage pondéré
		var weighted_keys := []
		for key in card_database_reference.CARD_TEXTURES.keys():
			if key.begins_with("+") or key.begins_with("-"):
				# 3 chances sur 5
				weighted_keys.append(key)
				weighted_keys.append(key)
				weighted_keys.append(key)
			elif key.begins_with("x") or key.begins_with("÷"):
				# 1 chance sur 5
				weighted_keys.append(key)

		var random_index = randi() % weighted_keys.size()
		var random_key = weighted_keys[random_index]
		var random_path = card_database_reference.CARD_TEXTURES[random_key]

		var new_card = card_scene.instantiate()
		var sprite_node = new_card.get_node("CardImage")
		sprite_node.texture = load(random_path)
		$"../CardManager".add_child(new_card)

		new_card.name = "Card"
		new_card.card_value = card_database_reference.CARD_VALUES[random_key]
		new_card.card_sign = card_database_reference.CARD_SIGNS[random_key]
		add_card_to_hand(new_card, DEFAULT_CARD_MOUV_SPEED)

		
func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOUV_SPEED)

func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position, speed)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index  * CARD_WIDTH - total_width / 2
	return x_offset
	
func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOUV_SPEED)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
