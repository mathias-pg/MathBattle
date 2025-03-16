extends Window

signal calculation_done(success: bool)

var current_slot_score = 0
var card_sign
var card_value
var total_time = 10.0  
var full_width = 0.0  

func _ready():
	$timer_countdown.connect("timeout", Callable(self, "_on_timer_timeout"))
	$btn_confirm.connect("pressed", Callable(self, "_on_btn_confirm_pressed"))
	var current_size = $TimeBar.size
	full_width = current_size.x
	hide() 

func start_calculation(slot_score: int, sign: String, value: int) -> void:
	current_slot_score = slot_score
	card_sign = sign
	card_value = value
	
	var question_text = ""
	match sign:
		"+":
			question_text = "Combien vaut %d + %d ?" % [slot_score, value]
		"-":
			question_text = "Combien vaut %d - %d ?" % [slot_score, value]
		"x":
			question_text = "Combien vaut %d x %d ?" % [slot_score, value]
		"÷":
			question_text = "Combien vaut %d ÷ %d ?" % [slot_score, value]
	
	$lbl_question.text = question_text
	$txt_answer.text = ""
	
	$timer_countdown.wait_time = 10.0
	$timer_countdown.start()
	
	show()

func _process(delta: float) -> void:
	if not $timer_countdown.is_stopped():
		var time_left = $timer_countdown.time_left
		var rounded_time = round(time_left * 10) / 10
		$lbl_timer.text = str(rounded_time)
		
		var ratio = time_left / total_time
		$TimeBar.size.x = full_width * ratio
		
func _on_btn_confirm_pressed():
	var user_input_str = $txt_answer.text
	if user_input_str == "":
		_end_calculation(false)
		return
	
	var user_input_int = int(user_input_str)
	var expected = 0
	match card_sign:
		"+":
			expected = current_slot_score + card_value
		"-":
			expected = current_slot_score - card_value
		"x":
			expected = current_slot_score * card_value
		"÷":
			if card_value != 0:
				expected = current_slot_score / card_value
			else:
				expected = current_slot_score
	
	if user_input_int == expected:
		_end_calculation(true)
	else:
		_end_calculation(false)

func _on_timer_timeout():
	_end_calculation(false)

func _end_calculation(success: bool):
	$timer_countdown.stop()
	hide()
	emit_signal("calculation_done", success)
