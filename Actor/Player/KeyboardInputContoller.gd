extends MotionController

func get_x_axis() -> float:
	if Globals.terminal_ref.is_active():
		return 0.0
	return float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left"))

func get_y_axis() -> float:
	if Globals.terminal_ref.is_active():
		return 0.0
	return float(Input.is_action_pressed("move_down")) - float(Input.is_action_pressed("move_up"))

func get_fire_button() -> bool:
	if Globals.terminal_ref.is_active():
		return false
	return Input.is_action_pressed("fire")

func get_interact_button() -> bool:
	if Globals.terminal_ref.is_active():
		return false
	return Input.is_action_just_pressed("interact")
