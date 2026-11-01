extends Enemy
## Lanciatore di giavellotti di Sokar: un guerriero del deserto, avvolto nel lino color sabbia, con
## il volto coperto. Sta lontano; prima di lanciare si ferma e una linea rossa mostra dove andrà il
## giavellotto (negli ultimi 0,25 s la mira è bloccata: spostandoti lo schivi). Se lo avvicini,
## arretra di corsa: va inseguito o colpito da lontano.

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var keep_min := 120.0
@export var keep_max := 190.0
@export var flee_dist := 85.0
@export var fire_every := 3.0
@export var windup := 0.8
@export var bolt_speed := 270.0
@export var bolt_damage := 12.0

var cd := 1.6
var casting := 0.0
var aim_dir := Vector2.RIGHT


func _behave(delta: float, to: Vector2) -> Vector2:
	cd -= delta
	if casting > 0.0:
		casting -= delta
		if casting > 0.25 and to != Vector2.ZERO:
			aim_dir = to.normalized()
		if casting <= 0.0:
			_throw()
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	if d < flee_dist:
		return _steer(-u * speed * 1.35, delta)       # troppo vicino: scappa all'indietro
	if cd <= 0.0 and d < 300.0:
		casting = windup
		cd = fire_every + randf() * 0.8
		aim_dir = u
		Sfx.play_at("priest_cast", global_position, 0.1)
		return Vector2.ZERO
	var want := 0.0
	if d < keep_min:
		want = -1.0
	elif d > keep_max:
		want = 1.0
	var v := u * want + u.orthogonal() * sin(t * 0.8 + seed_offset) * 0.6
	if v.length() < 0.05:
		return Vector2.ZERO
	return _steer(v.normalized() * speed, delta)


func _on_hit(_dmg: float) -> void:
	if casting > 0.0:
		casting = 0.0                 # colpito mentre mira: il lancio salta
		cd = 1.0


func _throw() -> void:
	Sfx.play_at("dart", global_position, 0.1)
	var bolt: Area2D = BoltScript.new()
	bolt.direction = aim_dir
	bolt.speed = bolt_speed
	bolt.damage = bolt_damage
	bolt.shooter = self
	bolt.style = "javelin"
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -10) + aim_dir * 10.0


func _draw_body(flash: bool) -> void:
	var linen := _f(Color(0.82, 0.7, 0.5), flash)
	var linen_d := _f(Color(0.6, 0.48, 0.32), flash)
	var skin := _f(Color(0.5, 0.32, 0.2), flash)
	var cloth := _f(Color(0.62, 0.2, 0.14), flash)
	var dir := 1.0 if aim_dir.x >= 0.0 else -1.0
	var bob := sin(t * 6.0) * 0.6
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(dir, 1.0))
	# gambe e tunica corta
	_limb(Vector2(-2, -6), Vector2(-3, 0), skin, 2.2)
	_limb(Vector2(2, -6), Vector2(3, 0), skin, 2.2)
	_op(PackedVector2Array([Vector2(-5.5, -6), Vector2(5.5, -6), Vector2(4.5, -18), Vector2(-4.5, -18)]), linen)
	draw_line(Vector2(-5, -10), Vector2(5, -10), cloth, 1.4)
	draw_line(Vector2(0, -18), Vector2(-1.5, -6), linen_d, 0.8)
	# testa avvolta nel lino, solo gli occhi scoperti
	var hc := Vector2(0, -22)
	_op(_ell(hc, 4.0, 4.0, 12), linen)
	draw_rect(Rect2(hc.x - 1.0, hc.y - 1.5, 4.5, 1.6), _out())
	draw_circle(hc + Vector2(2.4, -0.7), 0.6, Color(0.95, 0.85, 0.6) if not flash else Color.WHITE)
	_limb(hc + Vector2(-3.5, 1), hc + Vector2(-6.5, 6), linen_d, 1.4)       # il lembo che scende sulla schiena
	# il braccio e il giavellotto: alzato e tirato indietro mentre mira
	var k := 0.0 if casting <= 0.0 else 1.0 - casting / windup
	var hand := Vector2(4.0 - 4.0 * k, -16.0 - 4.0 * k)
	_limb(Vector2(2.5, -16), hand, skin, 1.6)
	if casting > 0.0 or cd > fire_every * 0.5:
		var sp := Vector2(1.0, -0.15).normalized()
		draw_line(hand - sp * 10.0, hand + sp * 12.0, _out(), 2.0)
		draw_line(hand - sp * 10.0, hand + sp * 12.0, _f(Color(0.62, 0.44, 0.24), flash), 1.1)
		draw_colored_polygon(PackedVector2Array([hand + sp * 16.0, hand + sp * 12.0 + sp.orthogonal() * 1.8, hand + sp * 12.0 - sp.orthogonal() * 1.8]), _f(Color(0.8, 0.55, 0.25), flash))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# la linea rossa d'avviso
	if casting > 0.0:
		var locked := casting <= 0.25
		var col := Color(1.0, 0.25, 0.15, 0.35 + 0.45 * k)
		var from := Vector2(0, -10)
		draw_line(from, from + aim_dir * 260.0, col, 1.0 if not locked else 2.0)
