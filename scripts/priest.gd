extends Enemy
## Sacerdote di Set: resta a distanza e lancia sfere di energia.
## Prima di lanciare si ferma e la sfera cresce in mano per mezzo secondo.
## Negli ultimi 0,2 secondi la mira è bloccata: se ti sposti, la schivi.

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var keep_min := 110.0          ## sotto questa distanza si allontana
@export var keep_max := 170.0          ## sopra questa distanza si avvicina
@export var fire_every := 2.4
@export var windup := 0.6
@export var bolt_speed := 150.0
@export var bolt_damage := 12.0

var cd := 1.5
var casting := 0.0
var aim_dir := Vector2.RIGHT


func _behave(delta: float, to: Vector2) -> Vector2:
	cd -= delta
	if casting > 0.0:
		casting -= delta
		if casting > 0.2 and to != Vector2.ZERO:
			aim_dir = to.normalized()
		if casting <= 0.0:
			_fire()
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	if cd <= 0.0:
		casting = windup
		cd = fire_every + randf() * 0.6
		aim_dir = to.normalized()
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	var want := 0.0
	if d < keep_min:
		want = -1.0
	elif d > keep_max:
		want = 1.0
	var v := u * want + u.orthogonal() * sin(t * 0.9 + seed_offset) * 0.7
	if v.length() < 0.05:
		return Vector2.ZERO
	return v.normalized() * speed


func _on_hit(_dmg: float) -> void:
	# colpirlo mentre lancia lo interrompe
	if casting > 0.0:
		casting = 0.0
		cd = 1.0


func _fire() -> void:
	var bolt: Area2D = BoltScript.new()
	bolt.direction = aim_dir
	bolt.speed = bolt_speed
	bolt.damage = bolt_damage
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -10) + aim_dir * 10.0


func _draw_body(flash: bool) -> void:
	var robe := Color.WHITE if flash else Color(0.37, 0.22, 0.53)
	var head := Color.WHITE if flash else Color(0.17, 0.09, 0.22)
	var bob := sin(t * 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(3, -18 + bob), Vector2(-3, -18 + bob)]), robe)
	draw_rect(Rect2(-6, -8 + bob, 12, 2), Color(0.94, 0.72, 0.3))
	draw_circle(Vector2(0, -21 + bob), 4.5, head)
	draw_rect(Rect2(-4, -30 + bob, 2, 7), head)
	draw_rect(Rect2(2, -30 + bob, 2, 7), head)
	draw_rect(Rect2(-2, -22 + bob, 1.5, 1.5), Color(1, 0.3, 0.2))
	draw_rect(Rect2(1, -22 + bob, 1.5, 1.5), Color(1, 0.3, 0.2))
	if casting > 0.0:
		var k := 1.0 - casting / windup
		var p := Vector2(0, -10) + aim_dir * 10.0
		draw_circle(p, 3.0 + k * 5.0, Color(0.85, 0.4, 1.0, 0.35))
		draw_circle(p, 1.5 + k * 2.5, Color(1, 0.85, 1))
		draw_line(p, p + aim_dir * 40.0, Color(0.85, 0.4, 1.0, 0.25 + k * 0.4), 1.0)
