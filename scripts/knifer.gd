extends Enemy
## Portatore di coltelli: uno dei demoni che nel Libro dei Morti custodiscono le porte col coltello in
## mano. Sta a distanza e lancia TRE coltelli a ventaglio: prima alza le braccia e tre linee rosse
## mostrano dove andranno (0,6 s). Se ti avvicini indietreggia. Fragile: va raggiunto.

const BoltScript := preload("res://scripts/enemy_bolt.gd")
const WINDUP := 0.6
const SPREAD := 20.0                ## gradi tra un coltello e l'altro
const KNIFE_SPEED := 215.0
const KNIFE_LIFE := 1.25            ## ~270 px
const KNIFE_DMG := 6.0
const KEEP_MIN := 110.0
const KEEP_MAX := 170.0

var state := "move"
var st := 0.0
var aim := Vector2.RIGHT


func _ready() -> void:
	super._ready()
	st = randf_range(1.0, 2.2)


func _dirs() -> Array:
	var n := 5 if elite else 3
	var out := []
	for i in range(n):
		out.append(aim.rotated(deg_to_rad(SPREAD * (i - (n - 1) / 2.0))))
	return out


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"move":
			aim = u
			if st <= 0.0 and d < 250.0:
				state = "windup"
				st = WINDUP
				Sfx.play_at("mummy_windup", global_position, 0.3)
				return Vector2.ZERO
			if d < KEEP_MIN:
				return _steer(-u * speed * 1.15, delta)
			if d > KEEP_MAX:
				return _steer(u * speed, delta)
			return _steer(u.orthogonal() * _side * speed * 0.6, delta)
		"windup":
			if st > WINDUP * 0.45:
				aim = u
			if st <= 0.0:
				_throw()
				state = "recover"
				st = 0.5
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				state = "move"
				st = randf_range(2.6, 3.6)
			return Vector2.ZERO
	return Vector2.ZERO


func _throw() -> void:
	Sfx.play_at("dart", global_position, 0.2)
	for dr in _dirs():
		var bolt: Area2D = BoltScript.new()
		bolt.direction = dr
		bolt.speed = KNIFE_SPEED
		bolt.damage = KNIFE_DMG
		bolt.shooter = self
		bolt.style = "knife"
		bolt.life = KNIFE_LIFE
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -8) + dr * 10.0


func _contact_damage() -> float:
	return 0.0


func _lines(k: float) -> void:
	for dr in _dirs():
		var v: Vector2 = dr
		Enemy.warn_strip(self, Vector2(0, -8) + v * 10.0, v, KNIFE_SPEED * KNIFE_LIFE, 5.0, k)


func _zones() -> void:
	_lines(0.0)


## Un demone magro dalla pelle blu-notte con la testa di lepre (come nei papiri: orecchie lunghe),
## gonnellino rosso, un coltello di selce per mano. Nell'avviso alza le braccia.
func _draw_body(flash: bool) -> void:
	if state == "windup":
		_lines(1.0 - st / WINDUP)
	var skin := _f(Color(0.16, 0.2, 0.42), flash)
	var kilt := _f(Color(0.7, 0.18, 0.16), flash)
	var up := 0.0
	if state == "windup":
		up = 1.0 - st / WINDUP
	var step := sin(t * 10.0) * 2.0 if velocity.length() > 10.0 else 0.0
	_limb(Vector2(-2.5, -6), Vector2(-3.0 - step, 0), skin, 1.8)
	_limb(Vector2(2.5, -6), Vector2(3.0 + step, 0), skin, 1.8)
	_op(PackedVector2Array([Vector2(-5, -9), Vector2(5, -9), Vector2(6, -4), Vector2(-6, -4)]), kilt)
	_op(PackedVector2Array([Vector2(-4.5, -17), Vector2(4.5, -17), Vector2(4, -9), Vector2(-4, -9)]), skin)
	draw_line(Vector2(-4, -15.5), Vector2(4, -15.5), _f(GOLD, flash), 1.4)
	for sx in [-1.0, 1.0]:
		var hand := Vector2(sx * (8.0 - 2.0 * up), -12.0 - 10.0 * up)
		_limb(Vector2(sx * 4.5, -16), hand, skin, 1.6)
		var kd := Vector2(sx * 0.3, -1.0).normalized()
		draw_line(hand, hand + kd * 7.0, _out(), 2.4)
		draw_line(hand, hand + kd * 6.5, Color(0.9, 0.88, 0.95) if up < 0.6 else Color(1.0, 0.5, 0.4), 1.3)
	# testa di lepre: muso lungo e due orecchie
	var h := Vector2(0, -20.5)
	_op(_ell(h, 3.6, 3.2, 10), skin)
	for sx in [-1.0, 1.0]:
		_op(PackedVector2Array([h + Vector2(sx * 1.0, -2.5), h + Vector2(sx * 2.4, -10.0), h + Vector2(sx * 3.2, -2.0)]), skin)
	var eye := Color(1.0, 0.3, 0.15) if state == "windup" else Color(1.0, 0.9, 0.4)
	draw_circle(h + Vector2(-1.5, -0.3), 0.9, eye)
	draw_circle(h + Vector2(1.5, -0.3), 0.9, eye)
