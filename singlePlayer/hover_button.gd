extends Button

var tween: Tween
var original_scale := Vector2.ONE
var hover_scale := Vector2(1.1, 1.1) # Ajuste le zoom ici
var duration := 0.4

func _ready():
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	reset_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self,"scale",hover_scale,duration)

func _on_mouse_exited():
	reset_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self,"scale",Vector2.ONE,duration)

func reset_tween():
	if tween:
		tween.kill()
	tween=create_tween()
