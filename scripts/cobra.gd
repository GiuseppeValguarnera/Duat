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
				Sfx.play_at("priest_cast", global_position, 0.2)
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
	Sfx.play_at("orb", global_position, 0.25)
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


func _draw_body(flash: bool) -> void:
	if state == "under":
		for i in range(3):
			draw_circle(Vector2(sin(t * 10.0 + i * 2.0) * 4.0, 0), 2.5, Color(0.75, 0.62, 0.4, 0.8))
		return
	var skin := Color.WHITE if flash else Color(0.2, 0.22, 0.18)
	var belly := Color.WHITE if flash else Color(0.85, 0.7, 0.35)
	var rise := 1.0
	if state == "emerge":
		rise = clampf(1.0 - st / 0.6, 0.2, 1.0)
	elif state == "dive":
		rise = clampf(st / 0.5, 0.2, 1.0)
	# spire a terra
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, skin, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# collo e cappuccio
	var top := Vector2(0, -16 * rise)
	draw_line(Vector2(0, -2), top, skin, 4.0)
	var hood := 7.0 if state in ["hood", "spit"] else 4.5
	draw_set_transform(top, 0.0, Vector2(1.0, 1.3))
	draw_circle(Vector2.ZERO, hood, skin)
	draw_circle(Vector2(0, 1), hood * 0.5, belly)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var eye_col := Color(0.6, 1, 0.4) if state == "hood" else Color(1, 0.85, 0.3)
	draw_circle(top + Vector2(-1.5, -2), 1.0, eye_col)
	draw_circle(top + Vector2(1.5, -2), 1.0, eye_col)
	if state == "hood":
		draw_line(top, top + aim * 40.0, Color(0.5, 1, 0.35, 0.35), 1.5)
