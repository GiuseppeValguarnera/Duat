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
		Sfx.play_at("priest_cast", global_position, 0.1)
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
	Sfx.play_at("orb", global_position, 0.15)
	var bolt: Area2D = BoltScript.new()
	bolt.direction = aim_dir
	bolt.speed = bolt_speed
	bolt.damage = bolt_damage
	bolt.shooter = self
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -10) + aim_dir * 10.0


## Il sacerdote di Set: tunica viola lunga fino ai piedi con la fascia rossa del dio, sulle spalle
## la pelle di leopardo dei sacerdoti, e il volto coperto dalla maschera dell'animale di Set
## (muso lungo e ricurvo, orecchie diritte e tagliate in cima, occhi rossi). In mano lo scettro
## uas. Quando lancia, la sfera viola cresce in punta allo scettro e la mira si vede.
func _draw_body(flash: bool) -> void:
	var robe := _f(Color(0.36, 0.2, 0.52), flash)
	var robe_d := _f(Color(0.22, 0.12, 0.34), flash)
	var red := _f(Color(0.7, 0.18, 0.12), flash)
	var pelt_c := _f(Color(0.88, 0.66, 0.3), flash)
	var mask := _f(Color(0.2, 0.12, 0.2), flash)
	var skin := _f(Color(0.62, 0.4, 0.24), flash)
	var dir := 1.0 if aim_dir.x >= 0.0 else -1.0
	var bob := sin(t * 3.0)
	draw_set_transform(Vector2(0, bob * 0.4), 0.0, Vector2(dir, 1.0))
	# tunica a campana con le pieghe
	var robe_p := PackedVector2Array([Vector2(-8.5, 0), Vector2(8.5, 0), Vector2(5.5, -14), Vector2(4.5, -21), Vector2(-4.5, -21), Vector2(-5.5, -14)])
	_op(robe_p, robe)
	draw_line(Vector2(-2.5, -13), Vector2(-4.5, 0), robe_d, 0.9)
	draw_line(Vector2(2.0, -13), Vector2(3.5, 0), robe_d, 0.9)
	# la fascia rossa con le frange
	_op(PackedVector2Array([Vector2(-5.6, -13.5), Vector2(5.6, -13.5), Vector2(5.8, -11.8), Vector2(-5.8, -11.8)]), red, 0.6)
	draw_line(Vector2(0.5, -11.8), Vector2(1.5, -6.5), red, 1.4)
	# la pelle di leopardo su una spalla, a macchie
	var pelt := PackedVector2Array([Vector2(-5.0, -21), Vector2(3.0, -21), Vector2(1.0, -15), Vector2(-4.0, -16.5)])
	_op(pelt, pelt_c, 0.6)
	for sp in [Vector2(-2.8, -19.5), Vector2(-0.5, -18.0), Vector2(1.2, -20.0), Vector2(-3.0, -17.2)]:
		draw_circle(sp, 0.5, OUT)
	# lo scettro uas: asta, testa dell'animale di Set e la forcella in basso
	var hand := Vector2(7.0, -14.0)
	_limb(Vector2(3.5, -19.5), hand, skin, 1.6)
	_limb(Vector2(8.0, 1.0), Vector2(8.0, -25.0), Color(0.45, 0.3, 0.15) if not flash else Color.WHITE, 0.9)
	draw_line(Vector2(8.0, -25.0), Vector2(10.5, -24.0), OUT, 1.6)
	draw_line(Vector2(8.0, 1.0), Vector2(7.0, 2.2), OUT, 0.8)
	draw_line(Vector2(8.0, 1.0), Vector2(9.0, 2.2), OUT, 0.8)
	# la maschera di Set: muso lungo e ricurvo, orecchie diritte tagliate in cima
	var hc := Vector2(0.0, -24.5)
	_op(_ell(hc, 4.2, 3.8, 12), mask)
	_op(PackedVector2Array([hc + Vector2(2.5, -1.8), hc + Vector2(7.5, -0.6), hc + Vector2(8.4, 1.4), hc + Vector2(6.8, 1.0), hc + Vector2(2.8, 1.6)]), mask, 0.6)
	for ex in [-2.4, 0.6]:
		_op(PackedVector2Array([hc + Vector2(ex - 0.8, -3.0), hc + Vector2(ex + 0.8, -3.0), hc + Vector2(ex + 1.6, -9.5), hc + Vector2(ex - 0.4, -9.5)]), mask, 0.6)
	draw_line(hc + Vector2(-0.5, -1.0), hc + Vector2(3.0, -0.6), _f(GOLD, flash), 0.6)
	var eye := Color(1, 0.3, 0.2) if not flash else Color.WHITE
	draw_circle(hc + Vector2(2.2, -0.2), 0.8, eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if casting > 0.0:
		var k := 1.0 - casting / windup
		var p := Vector2(8.0 * dir, -25.0) + aim_dir * 4.0
		draw_circle(p, 3.0 + k * 5.0, Color(0.85, 0.4, 1.0, 0.35))
		draw_circle(p, 1.5 + k * 2.5, Color(1, 0.85, 1))
		draw_line(p, p + aim_dir * 40.0, Color(0.85, 0.4, 1.0, 0.25 + k * 0.4), 1.0)
