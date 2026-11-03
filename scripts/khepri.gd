extends Enemy
## Scarabeo di Khepri: un grande scarabeo stercorario, sacro al sole che rinasce. Lento, spinge una
## sfera di sabbia e pietra che rotola dritta e rimbalza sui muri e sulle colonne: ferisce chi trova,
## anche gli altri nemici. Va evitata più che combattuta; lo scarabeo, senza sfera, è vulnerabile.

@export var push_every := 5.0
@export var windup := 0.7
@export var ball_speed := 170.0

var cd := 1.5
var winding := 0.0
var ball: Node2D = null
var aim := Vector2.RIGHT


func _behave(delta: float, to: Vector2) -> Vector2:
	cd -= delta
	if to != Vector2.ZERO:
		aim = aim.lerp(to.normalized(), 0.08).normalized()
	if winding > 0.0:
		winding -= delta
		if winding <= 0.0:
			_push()
		return Vector2.ZERO
	var has_ball := ball != null and is_instance_valid(ball)
	if cd <= 0.0 and not has_ball and to != Vector2.ZERO:
		winding = windup
		aim = to.normalized()
		cd = push_every + randf()
		Sfx.play_at("scarab_step", global_position, 0.1)
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	# cammina piano verso di te, di sbieco
	var v := to.normalized() + to.normalized().orthogonal() * sin(t * 0.6 + seed_offset) * 0.5
	return _steer(v.normalized() * speed, delta)


func _push() -> void:
	var b := KhepriBall.new()
	b.vel = aim * ball_speed
	b.owner_scarab = self
	get_parent().add_child(b)
	b.global_position = global_position + aim * (radius + 9.0) + Vector2(0, -2)
	ball = b
	Fx.burst(b.global_position, Color(0.8, 0.65, 0.4), 10, 60.0)


func _draw_body(flash: bool) -> void:
	var shell := _f(Color(0.12, 0.3, 0.32), flash)
	var shell_l := _f(Color(0.2, 0.48, 0.45), flash)
	var leg := _f(Color(0.08, 0.06, 0.05), flash)
	var ang := aim.angle()
	draw_set_transform(Vector2(0, -5), ang, Vector2.ONE)
	for i in range(3):
		var lx := -5.0 + i * 5.0
		for sy in [-1.0, 1.0]:
			_limb(Vector2(lx, sy * 5.0), Vector2(lx + 2.0 + sin(t * 10.0 + i) * 1.5, sy * 11.0), leg, 1.4)
	_op(_ell(Vector2(-1, 0), 10.0, 7.5, 16), shell)
	draw_line(Vector2(-11, 0), Vector2(5, 0), _out(), 0.9)
	_op(_ell(Vector2(-3, -3), 4.5, 2.2, 10), shell_l, 0.4)
	_op(_ell(Vector2(9, 0), 4.0, 4.5, 10), shell)                          # la testa
	# le zampe davanti, protese verso la sfera
	var k := 0.0 if winding <= 0.0 else 1.0 - winding / windup
	for sy in [-1.0, 1.0]:
		_limb(Vector2(11, sy * 2.5), Vector2(16.0 + 3.0 * k, sy * 4.0), leg, 1.4)
	draw_circle(Vector2(12, 0), 1.6, _f(GOLD, flash))                     # il sole di Khepri sulla fronte
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## La sfera di Khepri: rotola dritta, rimbalza sui muri della stanza e sulle colonne, ferisce
## giocatore e nemici (ognuno una volta ogni tanto). Dura qualche secondo, poi si sfalda.
class KhepriBall extends Node2D:
	const R := 12.0                      ## blocco 12: più grande, con un alone; ferisce solo se la tocchi
	var vel := Vector2.RIGHT * 170.0
	var owner_scarab: Node = null
	var life := 7.0
	var t := 0.0
	var roll := 0.0
	var _cool := {}

	func _ready() -> void:
		add_to_group("khepri_balls")

	func _physics_process(delta: float) -> void:
		t += delta
		life -= delta
		if life <= 0.0:
			Fx.burst(global_position, Color(0.75, 0.6, 0.38), 16, 70.0)
			queue_free()
			return
		var g = get_tree().current_scene
		var next := global_position + vel * delta
		if g != null and "ROOM" in g:
			var lo := Vector2(g.WALL + R, g.TOP + R)
			var hi := Vector2(g.ROOM.size.x - g.WALL - R, g.ROOM.size.y - g.WALL - R)
			if next.x < lo.x or next.x > hi.x:
				vel.x = -vel.x
				Sfx.play_at("hit", global_position, 0.2)
			if next.y < lo.y or next.y > hi.y:
				vel.y = -vel.y
				Sfx.play_at("hit", global_position, 0.2)
			for p in g.pillars:
				var d: Vector2 = next - p
				if d.length() < R + 13.0:
					vel = vel.bounce(d.normalized())
					break
		global_position += vel * delta * Run.thoth_time()
		roll += vel.length() * delta / R
		for k in _cool.keys():
			_cool[k] -= delta
			if _cool[k] <= 0.0:
				_cool.erase(k)
		var pl = get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and not _cool.has(pl) and pl.global_position.distance_to(global_position) < R + Enemy.PLAYER_R:
			_cool[pl] = 0.8
			pl.hit_age = t
			pl.take_damage(10.0, global_position, null, "khepri_ball")
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == owner_scarab or e.dead or e.is_boss or _cool.has(e):
				continue
			if e.global_position.distance_to(global_position) < R + e.radius:
				_cool[e] = 0.8
				e.take_hit(8.0, vel.normalized(), 120.0)
		queue_redraw()

	func _draw() -> void:
		# la traiettoria: una fila di frecce rosse davanti alla sfera, e l'alone
		var dv := vel.normalized()
		for i in range(4):
			var c := dv * (R + 14.0 + i * 16.0 + fmod(t * 40.0, 16.0))
			var sd := dv.orthogonal() * 4.0
			draw_polyline(PackedVector2Array([c - dv * 5.0 + sd, c, c - dv * 5.0 - sd]), Color(Enemy.WARN, 0.75 - i * 0.15), 2.0)
		draw_circle(Vector2.ZERO, R + 5.0, Color(1.0, 0.75, 0.35, 0.18 + 0.06 * sin(t * 8.0)))
		if Run.show_zones():
			draw_arc(Vector2.ZERO, R + Enemy.PLAYER_R, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.7), 1.0)
		draw_set_transform(Vector2(0, R * 0.9), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, R + 1.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2.ZERO, R + 1.0, Color(0.12, 0.08, 0.05))
		draw_circle(Vector2.ZERO, R, Color(0.58, 0.45, 0.3))
		# le pietre incastrate girano con la sfera
		for i in range(5):
			var a := roll + i * TAU / 5.0
			draw_circle(Vector2.from_angle(a) * R * 0.55, 1.6, Color(0.4, 0.3, 0.2))
		draw_circle(Vector2(-3, -3), 2.5, Color(0.75, 0.62, 0.45, 0.6))
		if life < 1.5:
			draw_circle(Vector2.ZERO, R, Color(0.9, 0.8, 0.6, (1.5 - life) * 0.3))
