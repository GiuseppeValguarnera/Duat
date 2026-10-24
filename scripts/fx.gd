extends Node
## Effetti globali: tremolio della telecamera, hitstop, numeri del danno, particelle.
## Tiene anche traccia del dispositivo usato (mouse o controller) per la mira.

var camera: Camera2D
var world: Node2D
var device := "mouse"          # "mouse" oppure "pad"
var show_hitboxes := true

var _shake := 0.0
var _hitstops := 0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		device = "mouse"
	elif event is InputEventJoypadButton:
		device = "pad"
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		device = "pad"


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if _shake > 0.0:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = maxf(0.0, _shake - 40.0 * delta)
	else:
		camera.offset = Vector2.ZERO


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Ferma il tempo per una frazione di secondo: dà peso ai colpi.
func hitstop(duration: float = 0.05) -> void:
	_hitstops += 1
	Engine.time_scale = 0.05
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	_hitstops -= 1
	if _hitstops <= 0:
		_hitstops = 0
		Engine.time_scale = 1.0


func damage_number(pos: Vector2, value: float, color: Color = Color(1, 0.95, 0.8)) -> void:
	float_text(pos, str(int(round(value))), color)


func float_text(pos: Vector2, text: String, color: Color = Color(1, 0.95, 0.8)) -> void:
	if world == null or not is_instance_valid(world):
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.z_index = 100
	world.add_child(l)
	l.position = pos + Vector2(randf_range(-10.0, 2.0), -30.0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16.0, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(l.queue_free)


func burst(pos: Vector2, color: Color, amount: int = 16, speed: float = 120.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.damping_min = 120.0
	p.damping_max = 200.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = color
	p.z_index = 50
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Mostra o nasconde le hitbox (tasto F1).
func set_hitboxes(on: bool) -> void:
	show_hitboxes = on
	get_tree().debug_collisions_hint = on
	if world != null and is_instance_valid(world):
		_redraw(world)


func _redraw(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for c in n.get_children():
		_redraw(c)
