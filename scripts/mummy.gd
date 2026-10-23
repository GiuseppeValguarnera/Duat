extends CharacterBody2D
## Mummia: lenta e resistente. Ti insegue, e quando sei vicino carica un affondo.
## Prima dell'affondo diventa rossa e mostra la direzione: è il segnale per schivare.

signal killed

@export var max_hp := 40.0
@export var speed := 40.0
@export var contact_damage := 10.0
@export var lunge_range := 70.0
@export var windup_time := 0.5         ## quanto dura l'avviso prima dell'affondo
@export var lunge_speed := 260.0
@export var lunge_time := 0.28

var hp := 0.0
var radius := 8.0
var dead := false
var state := "chase"
var st := 0.0
var lunge_dir := Vector2.RIGHT
var knock := Vector2.ZERO
var flash_t := 0.0
var t := 0.0

@onready var contact: Area2D = $ContactArea


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	t = randf() * 3.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	t += delta
	flash_t = maxf(0.0, flash_t - delta)
	st -= delta

	var player = get_tree().get_first_node_in_group("player")
	var to := Vector2.ZERO
	if player != null and not player.dead:
		to = player.global_position - global_position

	var v := Vector2.ZERO
	match state:
		"chase":
			if to != Vector2.ZERO:
				v = to.normalized() * speed * (0.85 + 0.2 * sin(t * 3.0))
				if to.length() < lunge_range and st <= 0.0:
					state = "windup"
					st = windup_time
					lunge_dir = to.normalized()
		"windup":
			# segue il giocatore solo nella prima parte dell'avviso, poi la direzione è fissa
			if st > windup_time * 0.4 and to != Vector2.ZERO:
				lunge_dir = to.normalized()
			if st <= 0.0:
				state = "lunge"
				st = lunge_time
		"lunge":
			v = lunge_dir * lunge_speed
			if st <= 0.0:
				state = "recover"
				st = 0.6
		"recover":
			if st <= 0.0:
				state = "chase"
				st = 0.8

	velocity = v + knock
	knock = knock.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()

	for a in contact.get_overlapping_areas():
		var owner_node = a.get_parent()
		if owner_node.is_in_group("player"):
			var dmg := contact_damage * (1.5 if state == "lunge" else 1.0)
			owner_node.take_damage(dmg, global_position)
	queue_redraw()


func take_hit(dmg: float, dir: Vector2, kb: float) -> void:
	if dead:
		return
	hp -= dmg
	flash_t = 0.1
	knock = dir * kb * (0.3 if state == "lunge" else 1.0)
	# un colpo pesante interrompe l'avviso: premia chi attacca al momento giusto
	if state == "windup" and dmg >= 20.0:
		state = "recover"
		st = 0.5
	Fx.damage_number(global_position, dmg)
	Fx.burst(global_position + Vector2(0, -8), Color(1, 0.9, 0.6), 5, 70.0)
	if hp <= 0.0:
		_die()


func _die() -> void:
	dead = true
	Fx.burst(global_position + Vector2(0, -8), Color(0.94, 0.72, 0.3), 20, 140.0)
	killed.emit()
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var body := Color(0.86, 0.81, 0.67)
	if state == "windup":
		var k := 1.0 - st / windup_time
		body = body.lerp(Color(1, 0.25, 0.15), 0.4 + 0.5 * k)
		# linea dell'affondo: mostra dove colpirà
		draw_line(Vector2(0, -6), Vector2(0, -6) + lunge_dir * lunge_speed * lunge_time, Color(1, 0.2, 0.15, 0.5), 2.0)
	if flash_t > 0.0:
		body = Color.WHITE
	var bob := sin(t * 6.0) * 1.0
	draw_rect(Rect2(-8, -24 + bob, 16, 24), body)
	for i in range(5):
		draw_line(Vector2(-8, -20 + i * 5 + bob), Vector2(8, -17 + i * 5 + bob), Color(0.45, 0.35, 0.2, 0.5), 1.0)
	draw_rect(Rect2(-4, -19 + bob, 2, 2), Color(0.65, 1, 0.45))
	draw_rect(Rect2(2, -19 + bob, 2, 2), Color(0.65, 1, 0.45))
	if hp < max_hp:
		draw_rect(Rect2(-10, -32, 20, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-10, -32, 20.0 * hp / max_hp, 3), Color(0.85, 0.2, 0.15))
