extends SceneTree
## Menu della Sfinge col pad: giù/su/destra spostano la selezione nel menu, nei Modificatori e nel
## Tesoro, e la lista scorre insieme alla selezione.
var frames := 0
var g = null
var step := 0

func _initialize() -> void:
	root.get_node("Run").trial = true
	change_scene_to_file("res://scenes/game.tscn")

func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _focus() -> String:
	var f := root.gui_get_focus_owner()
	if f == null:
		return "<nessuno>"
	return String(f.text).split("\n")[0] if f is Button else String(f.name)

func _scroll() -> int:
	var best := -1
	for n in root.find_children("*", "ScrollContainer", true, false):
		if (n as ScrollContainer).is_visible_in_tree():
			best = (n as ScrollContainer).scroll_vertical
	return best

func _process(_d: float) -> bool:
	frames += 1
	if frames == 30:
		g = current_scene
		root.get_node("Meta").sphinx["visits"] = 3
		g.trial.open_menu()
	if frames < 40 or g == null:
		return false
	if frames % 8 != 0:
		return false
	step += 1
	match step:
		1, 2, 3:
			_press("ui_accept")
		4:
			print("menu: ", _focus())
			_press("ui_down")
		5:
			print("menu dopo giù: ", _focus())
			_press("ui_right")
		6:
			print("menu dopo destra: ", _focus())
			_press("ui_up")
		7:
			print("menu dopo su: ", _focus())
			g.trial._menu_mods()
		9:
			print("modificatori: ", _focus(), " scorrimento ", _scroll())
			for i in range(6):
				_press("ui_down")
		10:
			print("modificatori dopo 6 giù: ", _focus(), " scorrimento ", _scroll())
			_press("ui_down")
			_press("ui_down")
			_press("ui_down")
		11:
			print("modificatori dopo 9 giù: ", _focus(), " scorrimento ", _scroll())
		12:
			for n in root.find_children("*", "CanvasLayer", true, false):
				if n.layer == 28:
					n.queue_free()
			g.trial._menu_shop()
		14:
			print("Tesoro: ", _focus(), " scorrimento ", _scroll())
			for i in range(9):
				_press("ui_down")
		15:
			print("Tesoro dopo 9 giù: ", _focus(), " scorrimento ", _scroll())
			_press("ui_right")
		16:
			print("Tesoro dopo destra: ", _focus())
			return true
	return false
