extends CharacterBody2D
## Lo Scriba delle Porte. Movimento, scatto, combo del khopesh e Occhio di Horus.
## Tutti i numeri che regolano la sensazione di gioco sono esportati:
## selezioni il nodo Player e li cambi dall'Ispettore mentre provi.

signal died
signal health_changed(hp: float, max_hp: float)

const EyeScript := preload("res://scripts/eye.gd")

@export_group("Vita")
@export var max_hp := 60.0
@export var hit_invuln := 0.8          ## secondi di invulnerabilità dopo un colpo subito

@export_group("Movimento")
@export var speed := 130.0
@export var attack_slowdown := 0.35    ## velocità mentre attacchi (0.35 = 35%)

@export_group("Scatto")
@export var dash_speed := 430.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.55

@export_group("Khopesh")
@export var attack_damage := 12.0
@export var aim_assist_degrees := 25.0

@export_group("Occhio di Horus")
@export var eye_damage := 24.0
@export var eye_cooldown := 2.5

## Le tre mosse della combo: portata, ampiezza in gradi, moltiplicatore danno,
## pausa prima del colpo successivo, piccolo slancio in avanti, spinta sul nemico.
const COMBO := [
	{"range": 28.0, "arc": 110.0, "mult": 1.0, "cd": 0.22, "lunge": 50.0, "knock": 90.0},
	{"range": 28.0, "arc": 110.0, "mult": 1.0, "cd": 0.22, "lunge": 50.0, "knock": 90.0},
	{"range": 36.0, "arc": 170.0, "mult": 1.8, "cd": 0.42, "lunge": 100.0, "knock": 230.0},
]

var hp := 0.0
var dead := false
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT

var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.ZERO
var invuln_t := 0.0
var flash_t := 0.0

var atk_t := 0.0
var atk_cd := 0.0
var combo := 0
var combo_window := 0.0
var swing_dir := Vector2.RIGHT
var swing_range := 0.0
var swing_arc := 0.0
var swing_index := 0

var eye_cd := 0.0
var knock := Vector2.ZERO
var walk := 0.0

@onready var camera: Camera2D = $Camera


func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	Fx.camera = camera


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick(delta)

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.15:
		facing = move.normalized()
	_update_aim()

	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and dash_t <= 0.0:
		_start_dash(move)
	if Input.is_action_pressed("attack") and atk_cd <= 0.0 and dash_t <= 0.0:
		_swing()
	if Input.is_action_just_pressed("special") and eye_cd <= 0.0:
		_fire_eye()

	if dash_t > 0.0:
		velocity = dash_dir * dash_speed
	else:
		var s := speed * (attack_slowdown if atk_t > 0.0 else 1.0)
		velocity = move * s + knock
		if move.length() > 0.1:
			walk += delta * 10.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	queue_redraw()


func _tick(delta: float) -> void:
	dash_t = maxf(0.0, dash_t - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	invuln_t = maxf(0.0, invuln_t - delta)
	flash_t = maxf(0.0, flash_t - delta)
	atk_t = maxf(0.0, atk_t - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	combo_window = maxf(0.0, combo_window - delta)
	eye_cd = maxf(0.0, eye_cd - delta)


## Mira: levetta destra se la usi, altrimenti mouse, altrimenti direzione di movimento.
func _update_aim() -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > 0.3:
		aim = stick.normalized()
	elif Fx.device == "mouse":
		var to := get_global_mouse_position() - (global_position + Vector2(0, -8))
		if to.length() > 4.0:
			aim = to.normalized()
	else:
		aim = facing


## Aiuto alla mira: se un nemico è entro pochi gradi, il colpo si orienta su di lui.
func _assisted(dir: Vector2, max_dist: float) -> Vector2:
	var best = null
	var best_angle := deg_to_rad(aim_assist_degrees)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > max_dist:
			continue
		var a := absf(dir.angle_to(to))
		if a < best_angle:
			best_angle = a
			best = to
	if best == null:
		return dir
	return (best as Vector2).normalized()


func _start_dash(move: Vector2) -> void:
	dash_dir = move.normalized() if move.length() > 0.15 else facing
	dash_t = dash_time
	dash_cd = dash_cooldown
	invuln_t = maxf(invuln_t, dash_time + 0.05)
	knock = Vector2.ZERO
	Fx.burst(global_position, Color(0.85, 0.75, 0.55), 8, 60.0)


func _swing() -> void:
	if combo_window <= 0.0:
		combo = 0
	var c: Dictionary = COMBO[combo]
	swing_index = combo
	combo = (combo + 1) % COMBO.size()
	combo_window = 0.55
	atk_t = 0.14
	atk_cd = c["cd"]
	swing_range = c["range"]
	swing_arc = deg_to_rad(c["arc"])
	swing_dir = _assisted(aim, swing_range + 24.0)
	knock = swing_dir * c["lunge"]

	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		var reach: float = swing_range + e.radius
		if to.length() > reach:
			continue
		if absf(swing_dir.angle_to(to)) <= swing_arc * 0.5 or to.length() < e.radius + 6.0:
			e.take_hit(attack_damage * c["mult"], to.normalized(), c["knock"])
			hit_any = true
	if hit_any:
		Fx.shake(3.0 if swing_index < 2 else 6.0)
		Fx.hitstop(0.04 if swing_index < 2 else 0.07)


func _fire_eye() -> void:
	eye_cd = eye_cooldown
	var eye: Area2D = EyeScript.new()
	eye.direction = aim
	eye.damage = eye_damage
	get_parent().add_child(eye)
	eye.global_position = global_position + Vector2(0, -8) + aim * 10.0


func take_damage(amount: float, from_pos: Vector2) -> void:
	if dead or invuln_t > 0.0 or dash_t > 0.0:
		return
	hp -= amount
	invuln_t = hit_invuln
	flash_t = 0.15
	knock = (global_position - from_pos).normalized() * 230.0
	Fx.shake(7.0)
	Fx.hitstop(0.08)
	Fx.damage_number(global_position, amount, Color(1, 0.4, 0.3))
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = 0.0
		dead = true
		Fx.burst(global_position, Color(0.9, 0.2, 0.15), 30, 160.0)
		queue_redraw()
		died.emit()


# ---------------------------------------------------------------- disegno provvisorio
# Forme semplici al posto degli sprite: servono solo a provare il combattimento.

func _draw() -> void:
	if dead:
		return
	var blink := invuln_t > 0.0 and dash_t <= 0.0 and int(Time.get_ticks_msec() / 60) % 2 == 0
	var a := 0.35 if blink else 1.0
	var bob := sin(walk) * 1.0

	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var skin := Color(0.75, 0.48, 0.25, a)
	var linen := Color(0.94, 0.89, 0.76, a)
	var blue := Color(0.19, 0.35, 0.77, a)
	var gold := Color(0.94, 0.72, 0.3, a)
	if flash_t > 0.0:
		skin = Color(1, 1, 1, a); linen = skin; blue = skin; gold = skin
	if dash_t > 0.0:
		linen = Color(0.94, 0.89, 0.76, 0.5)

	draw_rect(Rect2(-6, -8 + bob, 12, 8), linen)
	draw_rect(Rect2(-5, -15 + bob, 10, 8), skin)
	draw_rect(Rect2(-6, -9 + bob, 12, 2), gold)
	draw_circle(Vector2(0, -20 + bob), 5.0, skin)
	draw_rect(Rect2(-6, -25 + bob, 12, 4), blue)
	draw_rect(Rect2(-7, -22 + bob, 3, 8), blue)
	draw_rect(Rect2(4, -22 + bob, 3, 8), blue)
	draw_circle(Vector2(facing.x * 2.0 + 1.5, -20 + bob), 1.0, Color(0, 0, 0, a))

	# indicatore di mira
	var tip := Vector2(0, -8) + aim * 20.0
	var side := aim.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([tip + aim * 5.0, tip + side, tip - side]), Color(0.94, 0.72, 0.3, 0.8))

	# fendente: la zona disegnata è esattamente quella che colpisce
	if atk_t > 0.0:
		var pts := PackedVector2Array()
		var steps := 14
		var base := swing_dir.angle()
		for i in range(steps + 1):
			var ang := base - swing_arc * 0.5 + swing_arc * float(i) / steps
			pts.append(Vector2.from_angle(ang) * swing_range)
		for i in range(steps, -1, -1):
			var ang := base - swing_arc * 0.5 + swing_arc * float(i) / steps
			pts.append(Vector2.from_angle(ang) * swing_range * 0.4)
		draw_colored_polygon(pts, Color(1.0, 0.88, 0.55, 0.45 + atk_t * 2.0))
		if Fx.show_hitboxes:
			draw_polyline(pts, Color(1, 0.2, 0.2, 0.9), 1.0)
