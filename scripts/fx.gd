extends Node
## Effetti globali: tremolio della telecamera, hitstop, numeri del danno, particelle.
## Tiene anche traccia del dispositivo usato (mouse o controller) per la mira.

var camera: Camera2D
var world: Node2D
var device := "mouse"          # "mouse", "pad" oppure "touch"
var show_hitboxes := false

## Su telefono e tablet il gioco si avvicina un po' (la risoluzione di base scende) e
## l'interfaccia usa testi più grandi: `ui` è il moltiplicatore dei caratteri.
var mobile := false
var ui := 1.0

var _shake := 0.0
var _hitstops := 0
var _punch := Vector2.ZERO			  ## contraccolpo della telecamera nella direzione del colpo


func _ready() -> void:
	mobile = OS.has_feature("web_ios") or OS.has_feature("web_android") or OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile")
	if mobile:
		ui = 1.3
		get_window().content_scale_size = Vector2i(544, 306)


## Dimensione di un carattere, ingrandita sul telefono.
func fs(size: int) -> int:
	return roundi(size * ui)


## Ingrandisce i testi già impostati in una scena (le etichette dell'HUD e dei dialoghi).
func scale_labels(root: Node) -> void:
	if ui == 1.0:
		return
	for c in root.find_children("*", "Label", true, false):
		if c.has_theme_font_size_override("font_size"):
			c.add_theme_font_size_override("font_size", fs(c.get_theme_font_size("font_size")))


func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and event.device != InputEvent.DEVICE_ID_EMULATION:
		device = "mouse"
	elif event is InputEventJoypadButton:
		device = "pad"
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		device = "pad"


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var off := _punch
	_punch = _punch.move_toward(Vector2.ZERO, 60.0 * delta)
	if _shake > 0.0:
		off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = maxf(0.0, _shake - 40.0 * delta)
	camera.offset = off


func shake(amount: float) -> void:
	if not Meta.options.get("shake", true):
		return
	_shake = maxf(_shake, amount)


## Ferma il tempo per una frazione di secondo: dà peso ai colpi.
func hitstop(duration: float = 0.05) -> void:
	if not Meta.options.get("hitstop", true):
		return
	_hitstops += 1
	Engine.time_scale = 0.05
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	_hitstops -= 1
	if _hitstops <= 0:
		_hitstops = 0
		Engine.time_scale = 1.0


## La telecamera si sposta un poco nella direzione del colpo e torna: il colpo "spinge".
func punch(dir: Vector2, amount: float) -> void:
	if not Meta.options.get("shake", true):
		return
	_punch = dir.normalized() * amount


func damage_number(pos: Vector2, value: float, color: Color = Color(1, 0.95, 0.8), size: int = 11) -> void:
	float_text(pos, str(int(round(value))), color, size)


## Scintilla d'impatto dove la lama tocca: raggi bianchi e un anello che si allarga.
func impact(pos: Vector2, dir: Vector2, big: bool = false) -> void:
	if world == null or not is_instance_valid(world):
		return
	var n := Impact.new()
	n.dir = dir
	n.big = big
	n.z_index = 60
	world.add_child(n)
	n.global_position = pos


## L'anima del nemico abbattuto: un piccolo Ba (uccello dal volto umano) che sale e svanisce.
func soul(pos: Vector2, color: Color = Color(0.95, 0.85, 0.55)) -> void:
	if world == null or not is_instance_valid(world):
		return
	var n := Soul.new()
	n.color = color
	n.z_index = 55
	world.add_child(n)
	n.global_position = pos


func float_text(pos: Vector2, text: String, color: Color = Color(1, 0.95, 0.8), size: int = 11) -> void:
	if world == null or not is_instance_valid(world):
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
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


class Impact extends Node2D:
	var dir := Vector2.RIGHT
	var big := false
	var t := 0.0
	const LIFE := 0.16

	func _process(delta: float) -> void:
		t += delta
		if t > LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := t / LIFE
		var r := (10.0 if big else 6.0) + (16.0 if big else 10.0) * k
		var a := 1.0 - k
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(1, 0.95, 0.8, 0.8 * a), 2.0 if big else 1.4)
		# raggi soprattutto nella direzione del colpo
		var n := 7 if big else 5
		for i in range(n):
			var ang := dir.angle() + (i - (n - 1) / 2.0) * 0.45 + sin(i * 7.3) * 0.15
			var l0 := r * 0.4
			var l1 := r * (1.3 + 0.4 * sin(i * 3.1))
			draw_line(Vector2.from_angle(ang) * l0, Vector2.from_angle(ang) * l1, Color(1, 1, 0.9, a), 2.0 if big else 1.4)
		draw_circle(Vector2.ZERO, (5.0 if big else 3.0) * a, Color(1, 1, 1, a))


class Soul extends Node2D:
	var color := Color(0.95, 0.85, 0.55)
	var t := 0.0
	const LIFE := 0.9

	func _process(delta: float) -> void:
		t += delta
		position.y -= 38.0 * delta
		position.x += sin(t * 9.0) * 12.0 * delta
		if t > LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - t / LIFE, 0.0, 1.0) * 0.85
		var c := Color(color, a)
		var flap := sin(t * 18.0) * 3.0
		# corpo d'uccello, due ali che battono, testa umana tonda
		draw_circle(Vector2(0, -8), 2.6, c)
		draw_circle(Vector2(0, -12), 2.0, c)
		draw_colored_polygon(PackedVector2Array([Vector2(-1, -8), Vector2(-8, -10 - flap), Vector2(-5, -6)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -8), Vector2(8, -10 - flap), Vector2(5, -6)]), c)
		draw_circle(Vector2(0, -8), 7.0, Color(color, a * 0.15))
