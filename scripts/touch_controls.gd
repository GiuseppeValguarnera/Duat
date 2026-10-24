extends CanvasLayer
## Controlli touch per telefono e tablet. Compaiono da soli al primo tocco dello schermo.
## - Metà sinistra: levetta virtuale (appare dove appoggi il pollice).
## - Destra: khopesh (tieni premuto), scatto, Occhio di Horus, Forma Divina.
## - In alto a destra: pausa e doni.
## - Nella Sala del Giudizio e dal Traghettatore il pulsante grande diventa "Interagisci".
## Sul touch la mira va da sola verso il nemico più vicino (vedi player.gd).

const STICK_RADIUS := 42.0

var active := false
var stick_touch := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var held := {}                        # indice del dito -> azione premuta
var buttons: Array = []
var draw_node: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_node = Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_node.draw.connect(_draw_controls)
	add_child(draw_node)
	visible = false
	# nel browser del telefono i controlli ci sono subito, senza aspettare il primo tocco
	if OS.has_feature("web_ios") or OS.has_feature("web_android") or OS.has_feature("mobile"):
		active = true
		Fx.device = "touch"


func _layout() -> Array:
	var size := get_viewport().get_visible_rect().size
	var r := size.x
	var b := size.y
	var in_hub := Run.in_hub
	var scene = get_tree().current_scene
	var shop: bool = scene != null and "shop_items" in scene and not scene.shop_items.is_empty()
	var out := [
		{"action": "pause", "pos": Vector2(r - 22, 22), "r": 14.0, "label": "II"},
	]
	if in_hub:
		out.append({"action": "interact", "pos": Vector2(r - 58, b - 62), "r": 34.0, "label": "AZIONE"})
		out.append({"action": "dash", "pos": Vector2(r - 128, b - 40), "r": 24.0, "label": "SCATTO"})
		return out
	out.append({"action": "boons_menu", "pos": Vector2(r - 58, 22), "r": 14.0, "label": "DONI"})
	out.append({"action": "attack", "pos": Vector2(r - 58, b - 62), "r": 34.0, "label": "KHOPESH"})
	out.append({"action": "dash", "pos": Vector2(r - 128, b - 40), "r": 24.0, "label": "SCATTO"})
	out.append({"action": "special", "pos": Vector2(r - 108, b - 122), "r": 24.0, "label": "OCCHIO"})
	if Run.sekhem_unlocked():
		out.append({"action": "super", "pos": Vector2(r - 170, b - 100), "r": 20.0, "label": "SEKHEM"})
	if shop:
		out.append({"action": "interact", "pos": Vector2(r - 40, b - 140), "r": 20.0, "label": "COMPRA"})
	return out


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not active:
			active = true
			Fx.device = "touch"
		Fx.device = "touch"
	else:
		return
	visible = _should_show()
	if not visible:
		_release_all()
		return
	buttons = _layout()
	if event is InputEventScreenTouch:
		if event.pressed:
			for btn in buttons:
				if event.position.distance_to(btn["pos"]) <= btn["r"] + 8.0:
					held[event.index] = btn["action"]
					_send(btn["action"], true)
					get_viewport().set_input_as_handled()
					draw_node.queue_redraw()
					return
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and stick_touch == -1:
				stick_touch = event.index
				stick_origin = event.position
				stick_pos = event.position
				get_viewport().set_input_as_handled()
		else:
			if held.has(event.index):
				_send(held[event.index], false)
				held.erase(event.index)
			if event.index == stick_touch:
				stick_touch = -1
				_set_stick(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == stick_touch:
		stick_pos = event.position
		var v: Vector2 = (stick_pos - stick_origin) / STICK_RADIUS
		if v.length() > 1.0:
			v = v.normalized()
			stick_origin = stick_pos - v * STICK_RADIUS      # la levetta segue il pollice
		_set_stick(v)
		get_viewport().set_input_as_handled()
	draw_node.queue_redraw()


func _set_stick(v: Vector2) -> void:
	_axis("move_left", "move_right", v.x)
	_axis("move_up", "move_down", v.y)


func _axis(neg: String, pos_action: String, value: float) -> void:
	Input.action_release(neg)
	Input.action_release(pos_action)
	if value < -0.15:
		Input.action_press(neg, -value)
	elif value > 0.15:
		Input.action_press(pos_action, value)


## Un evento d'azione vero (non solo lo stato), così funzionano anche pausa, doni e interazione.
func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _release_all() -> void:
	for i in held:
		_send(held[i], false)
	held.clear()
	if stick_touch != -1:
		stick_touch = -1
		_set_stick(Vector2.ZERO)


## Nascosti durante menu e pause: lì si tocca direttamente lo schermo.
func _should_show() -> bool:
	if not active:
		return false
	if _portrait():
		return true
	var scene = get_tree().current_scene
	if scene == null or get_tree().paused:
		return false
	if "finished" in scene and scene.finished:
		return false
	if "talk_box" in scene and scene.talk_box.visible:
		return false
	if "book" in scene and scene.book != null:
		return false
	return true


func _process(_delta: float) -> void:
	var want := _should_show()
	if want != visible:
		visible = want
		if not want:
			_release_all()
	if visible:
		buttons = _layout()
		draw_node.queue_redraw()


func _portrait() -> bool:
	var s := DisplayServer.window_get_size()
	return active and s.y > s.x


func _draw_controls() -> void:
	var font := ThemeDB.fallback_font
	if _portrait():
		var vs := get_viewport().get_visible_rect().size
		draw_node.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.03, 0.08, 0.95))
		var msg := "Ruota il telefono in orizzontale"
		var w0 := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_node.draw_string(font, Vector2((vs.x - w0) / 2.0, vs.y / 2.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.94, 0.72, 0.3))
		return
	if stick_touch != -1:
		draw_node.draw_circle(stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.08))
		draw_node.draw_arc(stick_origin, STICK_RADIUS, 0.0, TAU, 32, Color(0.94, 0.72, 0.3, 0.5), 2.0)
		draw_node.draw_circle(stick_pos, 16.0, Color(0.94, 0.72, 0.3, 0.45))
	else:
		var hint := Vector2(70, get_viewport().get_visible_rect().size.y - 70)
		draw_node.draw_arc(hint, STICK_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.12), 1.5)
	for btn in buttons:
		var pressed: bool = held.values().has(btn["action"])
		var col := Color(0.94, 0.72, 0.3, 0.55 if pressed else 0.25)
		if btn["action"] == "special" and Fx.world != null:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and p.eye_cd > 0.0:
				col = Color(0.5, 0.5, 0.55, 0.2)
		if btn["action"] == "super" and not Run.sekhem_ready():
			col = Color(0.5, 0.5, 0.55, 0.2)
		draw_node.draw_circle(btn["pos"], btn["r"], col)
		draw_node.draw_arc(btn["pos"], btn["r"], 0.0, TAU, 32, Color(1, 0.9, 0.7, 0.6), 1.5)
		var fs := 7 if btn["r"] < 20.0 else 8
		var w := font.get_string_size(btn["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_node.draw_string(font, btn["pos"] + Vector2(-w / 2.0, fs / 2.0 - 1.0), btn["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.85, 0.9))
