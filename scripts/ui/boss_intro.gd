extends CanvasLayer
## La presentazione di un boss o di un guardiano: il gioco si ferma, la telecamera va sul boss,
## entrano due bande nere, il nome grande, il titolo e una riga di consiglio; ruggito e musica
## partono qui. La prima volta dura di più, poi è corta. Un tocco, un clic o un tasto la saltano.

signal finished

var cam: Camera2D
var offset_to := Vector2.ZERO
var hold := 2.2
var _cam_mode := Node.PROCESS_MODE_INHERIT
var _ending := false
var _t := 0.0
var _top: ColorRect
var _bottom: ColorRect
var _box: VBoxContainer


## `cam` è la telecamera del personaggio; `to_boss` lo spostamento fino al boss.
func setup(camera: Camera2D, to_boss: Vector2, title: String, epithet: String, hint: String, color: Color, long_version: bool) -> void:
	cam = camera
	offset_to = to_boss
	hold = 2.2 if long_version else 1.2
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bar_h := 30.0 * Fx.ui
	_top = ColorRect.new()
	_top.color = Color(0, 0, 0, 0.92)
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_bottom = 0.0
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_bottom = ColorRect.new()
	_bottom.color = Color(0, 0, 0, 0.92)
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = 0.0
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bottom)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_top = -bar_h - 84.0 * Fx.ui
	_box.offset_bottom = -bar_h - 6.0
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.modulate.a = 0.0
	add_child(_box)
	var name_label := UiStyle.heading(title, 26, color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 6)
	_box.add_child(name_label)
	var epi := UiStyle.label(epithet, 12, Color(0.97, 0.9, 0.75), true)
	epi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epi.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	epi.add_theme_constant_override("outline_size", 4)
	_box.add_child(epi)
	if hint != "":
		var h := UiStyle.label(hint, 8, Color(0.85, 0.8, 0.7))
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		h.add_theme_constant_override("outline_size", 3)
		_box.add_child(h)


func _ready() -> void:
	get_tree().paused = true
	if cam != null:
		_cam_mode = cam.process_mode
		cam.process_mode = Node.PROCESS_MODE_ALWAYS       # la telecamera si muove anche a gioco fermo
	var bar_h := 30.0 * Fx.ui
	var tw := create_tween().set_parallel()
	tw.tween_property(_top, "offset_bottom", bar_h, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bottom, "offset_top", -bar_h, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if cam != null:
		tw.tween_property(cam, "offset", offset_to, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_box, "modulate:a", 1.0, 0.3).set_delay(0.25)
	tw.tween_property(_box, "position:x", 0.0, 0.35).from(-40.0).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.shake(4.0)


func _process(delta: float) -> void:
	_t += delta
	if not _ending and _t >= hold:
		_end()


func _input(event: InputEvent) -> void:
	if _ending or _t < 0.35:
		return
	var tap: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	var key: bool = event.is_action_pressed("attack") or event.is_action_pressed("dash") or event.is_action_pressed("ui_accept") or event.is_action_pressed("pause")
	if tap or key:
		get_viewport().set_input_as_handled()
		_end()


func _end() -> void:
	_ending = true
	var tw := create_tween().set_parallel()
	tw.tween_property(_top, "offset_bottom", 0.0, 0.25)
	tw.tween_property(_bottom, "offset_top", 0.0, 0.25)
	tw.tween_property(_box, "modulate:a", 0.0, 0.2)
	if cam != null:
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(func() -> void:
		get_tree().paused = false
		if cam != null and is_instance_valid(cam):
			cam.process_mode = _cam_mode
		finished.emit()
		queue_free())
