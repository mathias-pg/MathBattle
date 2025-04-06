extends Button

var tween: Tween
var original_scale := Vector2.ONE
var hover_scale := Vector2(1.1, 1.1) # Ajuste le zoom ici
var duration := 0.1

func _ready():
	original_scale = scale
	tween = create_tween()
	pivot_offset=size/2
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", original_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
