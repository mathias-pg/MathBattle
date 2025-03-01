extends Node2D

const CARD_SCENE_PATH = "res://Cards/Card.tscn"
const CARD_DRAW_SPEED = 0.5

var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Cards/CardDataBase.gd")

func draw_card():
	var keys = card_database_reference.CARD_TEXTURES.keys()
	var random_index = randi() % keys.size() 
	var random_key = keys[random_index]
	var random_path = card_database_reference.CARD_TEXTURES[random_key]
	
	var card_scene = load(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var sprite_node = new_card.get_node("CardImage")
	sprite_node.texture = load(random_path)
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
