extends Node2D

const CARD_SCENE_PATH = "res://Cards/Card.tscn"
const CARD_DRAW_SPEED = 0.5
const MAX_CARDS = 5


var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Cards/CardDataBase.gd")

func draw_card():
	var card_scene = preload(CARD_SCENE_PATH)
	
	if $"../PlayerHand".player_hand.size() < MAX_CARDS :
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
		$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
		new_card.get_node("AnimationPlayer").play("card_flip")
		$"../AudioStreamPlayerFlipCard".play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
