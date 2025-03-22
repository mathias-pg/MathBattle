extends Node

var battle_timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func opponent_turn():
	$"../Deck".draw_card()
	battle_timer.start()
	await battle_timer.timeout
	
