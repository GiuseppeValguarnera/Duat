extends Node
## Crea i comandi di gioco all'avvio: tastiera, mouse e controller.
## Così non serve configurarli a mano in Progetto > Impostazioni > Mappa input.

func _ready() -> void:
	_keys("move_left", [KEY_A, KEY_LEFT])
	_keys("move_right", [KEY_D, KEY_RIGHT])
	_keys("move_up", [KEY_W, KEY_UP])
	_keys("move_down", [KEY_S, KEY_DOWN])
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)

	_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	_keys("attack", [KEY_J])
	_mouse("attack", MOUSE_BUTTON_LEFT)
	_button("attack", JOY_BUTTON_RIGHT_SHOULDER)
	_button("attack", JOY_BUTTON_X)

	_keys("dash", [KEY_SPACE, KEY_SHIFT, KEY_K])
	_button("dash", JOY_BUTTON_A)
	_button("dash", JOY_BUTTON_LEFT_SHOULDER)

	_keys("special", [KEY_L])
	_mouse("special", MOUSE_BUTTON_RIGHT)
	_axis("special", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button("special", JOY_BUTTON_Y)

	_keys("super", [KEY_Q])
	_axis("super", JOY_AXIS_TRIGGER_LEFT, 1.0)

	_keys("boons_menu", [KEY_TAB])
	_button("boons_menu", JOY_BUTTON_BACK)

	# menu: A conferma, B annulla, croce direzionale e levetta per spostarsi tra le scelte
	_button("ui_accept", JOY_BUTTON_A)
	_button("ui_cancel", JOY_BUTTON_B)
	_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)

	_keys("debug_hitbox", [KEY_F1])
	_keys("restart", [KEY_R])
	_button("restart", JOY_BUTTON_START)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)


func _keys(action: String, keys: Array) -> void:
	_ensure(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _mouse(action: String, button: MouseButton) -> void:
	_ensure(action)
	var e := InputEventMouseButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


func _button(action: String, button: JoyButton) -> void:
	_ensure(action)
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


func _axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure(action)
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)
