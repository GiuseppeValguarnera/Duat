extends Enemy
## Cobra: resta a distanza, alza il cappuccio (avviso) e sputa tre gocce di veleno in fila.
## Poi si nasconde sotto la sabbia e riemerge da un'altra parte: va colpito quando è fuori.
## Il cobra (l'ureo) era il simbolo del faraone: sputava fuoco contro i suoi nemici.

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var keep_min := 110.0
@export var keep_max := 190.0
@export var spit_windup := 0.55
@export var spit_damage := 9.0

var state := "emerge"
var st := 0.6
var aim := Vector2.RIGHT
var shots := 0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	match state:
		"emerge":
			if st <= 0.0:
				state = "watch"
				st = randf_range(0.6, 1.1)
			return Vector2.ZERO
		"watch":
			if to == Vector2.ZERO:
				return Vector2.ZERO
			aim = to.normalized()
			if st <= 0.0:
				state = "hood"
				st = spit_windup
				Sfx.play_at("cobra_hiss", global_position, 0.2)
				return Vector2.ZERO
			var d := to.length()
			if d < keep_min:
				return -aim * speed
			if d > keep_max:
				return aim * speed
			return Vector2.ZERO
		"hood":
			if st > spit_windup * 0.4 and to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				state = "spit"
				st = 0.0
				shots = 3
			return Vector2.ZERO
		"spit":
			if st <= 0.0 and shots > 0:
				_spit()
				shots -= 1
				st = 0.14
			elif shots == 0 and st <= 0.0:
				state = "dive"
				st = 0.5
			return Vector2.ZERO
		"dive":
			if st <= 0.0:
				_hide(true)
				Sfx.play_at("serpent_burrow", global_position, 0.3)
				state = "under"
				st = 1.1
			return Vector2.ZERO
		"under":
			if st <= 0.0:
				_hide(false)
				state = "emerge"
				st = 0.5
				Fx.burst(global_position, Color(0.85, 0.72, 0.45), 14, 80.0)
				return Vector2.ZERO
			# sotto la sabbia scivola di lato rispetto al giocatore
			if to == Vector2.ZERO:
				return Vector2.ZERO
			return to.normalized().orthogonal() * speed * 2.2
	return Vector2.ZERO


func _spit() -> void:
	Sfx.play_at("cobra_spit", global_position, 0.25)
	var bolt: Area2D = BoltScript.new()
	bolt.direction = aim
	bolt.speed = 210.0
	bolt.damage = spit_damage
	bolt.shooter = self
	bolt.style = "venom"
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -12) + aim * 8.0


func _hide(on: bool) -> void:
	if on:
		remove_from_group("enemies")
		collision_layer = 0
		if contact != null:
			contact.monitoring = false
	else:
		add_to_group("enemies")
		collision_layer = 4
		if contact != null:
			contact.monitoring = true


## Il cobra egizio, l'ureo: spire a terra a fasce scure e d'oro, il collo che si alza, il
## cappuccio largo con il disegno sul davanti e la lingua biforcuta. Avviso: il cappuccio si
## apre e gli occhi diventano verdi. Sotto la sabbia si vede solo una gobba che si muove.
func _draw_body(flash: bool) -> void:
	if state == "under":
		var sand := Color(0.66, 0.5, 0.3)
		_op(_ell(Vector2(0, -1.0), 7.0, 2.6, 14), sand, 0.6)
		for i in range(3):
			draw_circle(Vector2(sin(t * 10.0 + i * 2.0) * 5.0, -2.0 - absf(cos(t * 8.0 + i)) * 2.0), 1.2, Color(0.82, 0.68, 0.45, 0.9))
		return
	var skin := _f(Color(0.17, 0.19, 0.15), flash)
	var band := _f(Color(0.78, 0.6, 0.28), flash)
	var belly := _f(Color(0.88, 0.74, 0.42), flash)
	var rise := 1.0
	if state == "emerge":
		rise = clampf(1.0 - st / 0.6, 0.2, 1.0)
	elif state == "dive":
		rise = clampf(st / 0.5, 0.2, 1.0)
	var dir := 1.0 if aim.x >= 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# spire a terra, con le fasce
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(dir, 0.5))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, _out(), 4.6)
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, skin, 3.0)
	for k in range(6):
		var a := k * TAU / 6.0 + t * 0.5
		draw_arc(Vector2.ZERO, 7.0, a, a + 0.25, 3, band, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# collo che sale con il ventre chiaro
	var top := Vector2(1.0, -16.0 * rise)
	var neck := PackedVector2Array([Vector2(-2.5, -1.5), Vector2(2.5, -1.5), top + Vector2(2.0, 3.0), top + Vector2(-2.0, 3.0)])
	_op(neck, skin)
	draw_line(Vector2(1.0, -2.0), top + Vector2(0.6, 3.0), belly, 1.2)
	# il cappuccio: più largo nell'avviso e quando sputa
	var open := state in ["hood", "spit"]
	var hw := 6.5 if open else 4.0
	var hood := PackedVector2Array([top + Vector2(0, -6.5), top + Vector2(hw * 0.8, -4.0), top + Vector2(hw, 1.0), top + Vector2(hw * 0.5, 5.0), top + Vector2(-hw * 0.5, 5.0), top + Vector2(-hw, 1.0), top + Vector2(-hw * 0.8, -4.0)])
	_op(hood, skin)
	_op(PackedVector2Array([top + Vector2(0, -3.0), top + Vector2(hw * 0.35, 0.0), top + Vector2(hw * 0.25, 4.0), top + Vector2(-hw * 0.25, 4.0), top + Vector2(-hw * 0.35, 0.0)]), belly, 0.5)
	for k in range(3):
		draw_line(top + Vector2(-hw * 0.25, 0.5 + k * 1.2), top + Vector2(hw * 0.25, 0.5 + k * 1.2), band, 0.5)
	# la testa, il muso verso di te
	_op(_ell(top + Vector2(1.5, -5.5), 2.6, 1.9, 10), skin, 0.6)
	var eye_col := Color(0.6, 1, 0.4) if state == "hood" else Color(1, 0.85, 0.3)
	if flash:
		eye_col = Color.WHITE
	draw_circle(top + Vector2(2.6, -6.0), 0.75, eye_col)
	if fmod(t, 1.2) < 0.25:
		var tg := top + Vector2(4.0, -5.0)
		draw_line(tg, tg + Vector2(2.0, 0.3), Color(0.85, 0.2, 0.2), 0.5)
		draw_line(tg + Vector2(2.0, 0.3), tg + Vector2(2.8, -0.4), Color(0.85, 0.2, 0.2), 0.4)
		draw_line(tg + Vector2(2.0, 0.3), tg + Vector2(2.8, 0.9), Color(0.85, 0.2, 0.2), 0.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "hood":
		draw_line(top * Vector2(dir, 1.0), top * Vector2(dir, 1.0) + aim * 40.0, Color(0.5, 1, 0.35, 0.35), 1.5)
