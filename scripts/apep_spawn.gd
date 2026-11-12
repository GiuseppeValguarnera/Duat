extends Enemy
## Figlio di Apopi: una serpe del caos. Striscia verso di te ondeggiando (non arriva mai dritta), poi
## si raccoglie (striscia rossa: la zona vera del morso) e scatta in linea. Quando muore lascia una
## pozza di Isfet per qualche secondo: conta DOVE la uccidi.

const WINDUP := 0.5
const LUNGE_SPEED := 300.0
const LUNGE_TIME := 0.36
const LUNGE_FROM := 96.0
const BITE := 9.0
const POOL_LIFE := 4.0
const POOL_R := 15.0

var state := "chase"
var st := 0.0
var aim := Vector2.RIGHT
var bit := false
var trail: Array[Vector2] = []


func _ready() -> void:
	super._ready()
	st = randf_range(0.6, 1.4)
	for i in range(9):
		trail.append(global_position)


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	trail.push_front(global_position)
	if trail.size() > 9:
		trail.pop_back()
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"chase":
			aim = u
			if st <= 0.0 and d < LUNGE_FROM:
				state = "windup"
				st = WINDUP
				Sfx.play_at("cobra_hiss", global_position, 0.25)
				return Vector2.ZERO
			var wob := u.orthogonal() * sin(t * 6.0 + seed_offset) * 0.7
			return _steer((u + wob).normalized() * speed, delta)
		"windup":
			if st > WINDUP * 0.5:
				aim = u
			if st <= 0.0:
				state = "lunge"
				st = LUNGE_TIME
				bit = false
				Sfx.play_at("serpent_strike", global_position, 0.3)
			return -aim * 18.0
		"lunge":
			var p = get_tree().get_first_node_in_group("player")
			if not bit and p != null and touches(p):
				bit = true
				p.take_damage(BITE, global_position, self)
			if st <= 0.0:
				state = "recover"
				st = 0.7
			return aim * LUNGE_SPEED
		"recover":
			if st <= 0.0:
				state = "chase"
				st = randf_range(0.8, 1.5)
			return Vector2.ZERO
	return Vector2.ZERO


func _contact_damage() -> float:
	return 0.0


func _stagger_time() -> float:
	return 0.22


func die() -> void:
	if not dead and not no_reward and is_inside_tree():
		var pool := Chaos.Isfet.new()
		pool.r = POOL_R
		pool.life = POOL_LIFE
		pool.position = position
		get_parent().add_child.call_deferred(pool)
	super.die()


func _strip(k: float) -> void:
	Enemy.warn_strip(self, Vector2.ZERO, aim, LUNGE_SPEED * LUNGE_TIME + touch_dist(), touch_dist(), k)


func _zones() -> void:
	_strip(0.0)


## Una serpe nera con il ventre rosso e gli occhi gialli: il corpo segue la testa (le posizioni passate).
func _draw_body(flash: bool) -> void:
	if state == "windup":
		_strip(1.0 - st / WINDUP)
	var dark := _f(Color(0.14, 0.08, 0.18), flash)
	var belly := _f(Color(0.62, 0.16, 0.18), flash)
	var pts := PackedVector2Array()
	for i in range(trail.size()):
		var q: Vector2 = trail[i] - global_position
		var side := Vector2(0, sin(t * 9.0 + i * 0.9) * 1.6)
		pts.append(q + side + Vector2(0, -4))
	if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) > 2.0:
		draw_polyline(pts, _out(), 6.6)
		draw_polyline(pts, dark, 5.0)
		draw_polyline(pts, belly, 1.4)
	else:
		# ferma: raccolta a spirale
		draw_arc(Vector2(0, -4), 5.0, 0.0, TAU, 14, _out(), 6.2)
		draw_arc(Vector2(0, -4), 5.0, 0.0, TAU, 14, dark, 4.6)
	var h := Vector2(0, -5) + aim * (4.0 - (3.0 * (1.0 - st / WINDUP) if state == "windup" else 0.0))
	_op(PackedVector2Array([h + aim * 6.0, h + aim.orthogonal() * 3.6, h - aim * 3.0, h - aim.orthogonal() * 3.6]), dark)
	var eye := Color(1.0, 0.3, 0.15) if state == "windup" else Color(1.0, 0.85, 0.25)
	draw_circle(h + aim * 1.5 + aim.orthogonal() * 1.9, 1.0, eye)
	draw_circle(h + aim * 1.5 - aim.orthogonal() * 1.9, 1.0, eye)
	if state == "windup" or state == "lunge":
		draw_line(h + aim * 6.0, h + aim * 9.5 + aim.orthogonal() * 1.5, belly, 0.9)
		draw_line(h + aim * 6.0, h + aim * 9.5 - aim.orthogonal() * 1.5, belly, 0.9)
