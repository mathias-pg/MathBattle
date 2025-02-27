extends TextureRect

var card_type = "+"
var card_value = 1
var card_texture_path = ""

func _ready():
	if card_texture_path != "":
		texture = load(card_texture_path)
	update_display()

func update_display():
	# Si tu veux afficher en plus un label indiquant +1, -1 etc.
	if has_node("Label"):
		$Label.text = "%s%d" % [card_type, card_value]
