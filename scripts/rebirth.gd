class_name Rebirth
extends RefCounted
## La rinascita: ogni notte il sole muore a ovest, attraversa il Duat e all'alba lo scarabeo Kheper
## lo spinge fuori dalle acque del Nun, rinato. L'eroe fa lo stesso a ogni discesa.
## 1. muori: dal corpo si alza il Ba, l'anima-uccello con la testa umana, e vola via (BaSoul);
## 2. il passaggio: sul nero, lo scarabeo spinge un piccolo sole che si accende (Passage);
## 3. nella Sala il disco solare dipinto sul pavimento si accende, sale un raggio di luce e
##    l'eroe riemerge dal disco (Emergence).
## Tutto sotto i 3 secondi: la scena si vede centinaia di volte. Dalla seconda volta il passaggio
## si salta con un tasto.

const GOLD := Color(1.0, 0.8, 0.4)


## Lascia la discesa: il passaggio dello scarabeo, poi la Sala con la riemersione.
static func to_hub(from: Node, victory: bool) -> void:
	Run.rebirth = "win" if victory else "death"
	Meta.stats["rinascite"] = int(Meta.stats.get("rinascite", 0)) + 1
	Meta.save()
	var p := Passage.new()
	p.victory = victory
	p.skippable = int(Meta.stats["rinascite"]) > 1
	from.get_tree().root.add_child(p)


## Il Ba: un uccello con la testa umana, d'oro pallido, che si alza dal corpo e sale piano.
class BaSoul extends Node2D:
	var t := 0.0
	var start := Vector2.ZERO
	var _t0 := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 20
		start = position
		_t0 = Time.get_ticks_msec()

	func _process(_delta: float) -> void:
		# tempo vero: intorno il gioco rallenta e poi si ferma, il Ba no
		t = (Time.get_ticks_msec() - _t0) / 1000.0
		position = start + Vector2(sin(t * 3.0) * 6.0, -30.0 * t - 10.0 * t * t)
		if t > 2.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(t * 3.0, 0.0, 1.0) * clampf((2.6 - t) / 0.8, 0.0, 1.0)
		var flap := sin(t * 10.0)
		var gold := Color(1.0, 0.85, 0.5, a)
		draw_circle(Vector2(0, -2), 14.0, Color(1.0, 0.85, 0.5, 0.15 * a))
		# ali
		for sx in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(sx * 2, 0), Vector2(sx * 13, -4 - 5 * flap), Vector2(sx * 11, 2 - 2 * flap), Vector2(sx * 3, 3)]), Color(0.95, 0.72, 0.35, a))
		# corpo d'uccello e coda
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(0.7, 1.0))
		draw_circle(Vector2.ZERO, 4.0, gold)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 5), Vector2(2, 5), Vector2(0, 10)]), gold)
		# la testa umana, con la parrucca scura
		draw_circle(Vector2(0, -5), 3.0, Color(0.72, 0.46, 0.27, a))
		draw_colored_polygon(PackedVector2Array([Vector2(-3.2, -6), Vector2(3.2, -6), Vector2(3, -2), Vector2(-3, -2)]), Color(0.1, 0.08, 0.12, a))
		draw_circle(Vector2(1.2, -5), 0.6, Color(0.05, 0.04, 0.06, a))


## Il passaggio sul nero: lo scarabeo spinge il sole da sinistra a destra, il sole si accende,
## poi tutto diventa luce e si apre la Sala.
class Passage extends CanvasLayer:
	const DUR := 1.9
	var t := 0.0
	var victory := false
	var skippable := false
	var art: Control
	var done := false

	func _ready() -> void:
		layer = 60
		process_mode = Node.PROCESS_MODE_ALWAYS
		art = Control.new()
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_STOP
		art.draw.connect(_paint)
		add_child(art)
		Sfx.play("soul", 0.0)

	func _process(delta: float) -> void:
		t += delta
		art.queue_redraw()
		if t >= DUR and not done:
			_finish()
		if done and t >= DUR + 0.45:
			queue_free()

	func _input(event: InputEvent) -> void:
		if done or not skippable or t < 0.25:
			return
		var pressed: bool = (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed) or (event is InputEventJoypadButton and event.pressed)
		if pressed:
			get_viewport().set_input_as_handled()
			_finish()

	func _finish() -> void:
		done = true
		t = maxf(t, DUR)                     # saltato: si va dritti al bianco dell'alba, che poi svanisce
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

	func _paint() -> void:
		var vs := art.get_viewport_rect().size
		var u := minf(vs.x, vs.y) / 360.0 * 1.6
		var k := clampf(t / (DUR - 0.3), 0.0, 1.0)
		# il nero della notte, che alla fine si scioglie nella luce dell'alba
		var fade_in := clampf(t / 0.2, 0.0, 1.0)
		var white := clampf((t - (DUR - 0.35)) / 0.35, 0.0, 1.0)
		var out := clampf((t - DUR) / 0.45, 0.0, 1.0)
		var a := fade_in * (1.0 - out)
		art.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.01, 0.01, 0.03, a))
		# il fiume del Nun: una linea d'acqua appena accennata
		var y := vs.y * 0.6
		art.draw_line(Vector2(0, y + 18 * u), Vector2(vs.x, y + 18 * u), Color(0.2, 0.35, 0.5, 0.4 * a), 1.5 * u)
		# il sole che viene spinto, sempre più grande e acceso
		var sx := lerpf(vs.x * 0.25, vs.x * 0.62, k)
		var sr := (9.0 + 9.0 * k) * u
		var sun := Vector2(sx, y - sr + 16 * u)
		var hot := Color(1.0, 0.45 + 0.4 * k, 0.15 + 0.3 * k, a)
		for i in range(4):
			art.draw_circle(sun, sr * (1.6 + i * 0.5) * (0.6 + k), Color(1.0, 0.7, 0.3, 0.06 * a * (0.4 + k)))
		art.draw_circle(sun, sr, hot)
		art.draw_circle(sun + Vector2(-sr * 0.3, -sr * 0.3), sr * 0.45, Color(1, 0.95, 0.7, 0.5 * a * k))
		# lo scarabeo, dietro al sole, che spinge con le zampe
		var b := sun + Vector2(-sr - 13 * u, sr - 7 * u)
		var step := sin(t * 14.0)
		var col := Color(0.12, 0.4, 0.42, a) if not victory else Color(0.9, 0.7, 0.3, a)
		for i in range(3):
			var lx := b.x + (-4 + i * 5) * u
			art.draw_line(Vector2(lx, b.y + 4 * u), Vector2(lx + (2 + step * (1 if i % 2 == 0 else -1) * 2) * u, b.y + 10 * u), Color(0.05, 0.05, 0.05, a), 1.4 * u)
		var body := PackedVector2Array()
		for i in range(16):
			var ang := TAU * i / 16.0
			body.append(b + Vector2(cos(ang) * 9.0, sin(ang) * 6.5) * u)
		art.draw_colored_polygon(body, col)
		art.draw_line(b + Vector2(-8, 0) * u, b + Vector2(8, 0) * u, Color(0.05, 0.05, 0.05, a), 1.0 * u)
		art.draw_circle(b + Vector2(9, -1) * u, 3.0 * u, col.darkened(0.3))
		art.draw_line(b + Vector2(10, -2) * u, sun + Vector2(-sr * 0.8, sr * 0.2), Color(0.05, 0.05, 0.05, a), 1.4 * u)
		# l'alba: tutto si fa bianco-oro, e la Sala si apre sotto
		if white > 0.0 or out > 0.0:
			art.draw_rect(Rect2(Vector2.ZERO, vs), Color(1.0, 0.92, 0.75, white * (1.0 - out)))


## Nella Sala: il raggio di luce dal disco solare e l'eroe che ne riemerge.
class Emergence extends Node2D:
	const DUR := 1.3
	var t := 0.0
	var player: Node2D
	var victory := false
	signal finished

	func _ready() -> void:
		z_index = 3
		if player != null:
			player.set_physics_process(false)
			player.modulate.a = 0.0
		Sfx.play("boon", 0.0)

	func _process(delta: float) -> void:
		t += delta
		if player != null and is_instance_valid(player):
			var k := clampf((t - 0.35) / 0.7, 0.0, 1.0)
			player.modulate.a = k
			player.scale = Vector2.ONE * lerpf(0.6, 1.0, k)
			if t - delta < 0.6 and t >= 0.6:
				Fx.burst(global_position + Vector2(0, -10), GOLD, 30, 140.0)
				Fx.shake(3.0)
		if t >= DUR:
			if player != null and is_instance_valid(player):
				player.modulate.a = 1.0
				player.scale = Vector2.ONE
				player.set_physics_process(true)
			finished.emit()
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var rise := clampf(t / 0.35, 0.0, 1.0)
		var fall := clampf((DUR - t) / 0.5, 0.0, 1.0)
		var a := rise * fall
		var gold := GOLD if not victory else Color(1.0, 0.88, 0.5)
		# il disco sul pavimento che si accende
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		for i in range(4):
			draw_circle(Vector2.ZERO, 22.0 + i * 10.0, Color(gold, 0.16 * a))
		draw_arc(Vector2.ZERO, 26.0 + rise * 6.0, 0, TAU, 40, Color(1, 0.95, 0.75, 0.7 * a), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# il raggio che sale verso l'alto
		var h := 220.0 * rise
		for i in range(3):
			var w := 16.0 - i * 5.0
			draw_rect(Rect2(-w, -h, w * 2.0, h), Color(gold, (0.12 + i * 0.1) * a))
