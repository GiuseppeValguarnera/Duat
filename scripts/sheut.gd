extends Enemy
## Sheut, l'ombra senza padrone (la parte dell'anima che Apopi ha staccato dai dannati). Ti segue
## piano; ogni tanto si scioglie nel pavimento (non si può colpire) e riaffiora ALLE TUE SPALLE: un
## cerchio rosso dice dove (0,6 s), poi un colpo d'artigli in quel cerchio. Dopo resta ferma: è il
## momento di colpirla. Insegna a muoversi appena sparisce.

const SINK := 0.4
const WARN_T := 0.6
const SLASH_R := 26.0
const SLASH := 10.0
const BEHIND := 30.0

var state := "walk"
var st := 0.0
var spot := Vector2.ZERO
var hidden_now := false


func _ready() -> void:
	super._ready()
	st = randf_range(2.0, 3.5)


func _set_hidden(on: bool) -> void:
	hidden_now = on
	if on:
		remove_from_group("enemies")
		collision_layer = 0
	else:
		add_to_group("enemies")
		collision_layer = 4


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"walk":
			if st <= 0.0 and d > 40.0:
				state = "sink"
				st = SINK
				Sfx.play_at("soul", global_position, 0.3)
				return Vector2.ZERO
			return _steer(u * speed, delta)
		"sink":
			if st <= 0.0:
				var p = get_tree().get_first_node_in_group("player")
				var back: Vector2 = -u
				if p != null and p.velocity.length() > 10.0:
					back = -p.velocity.normalized()          # alle spalle rispetto a dove sta andando
				spot = global_position + to + back * BEHIND
				var g = get_tree().current_scene
				if g != null and g.has_method("_in_floor") and not g._in_floor(spot, 10.0):
					spot = global_position + to - back * BEHIND
				_set_hidden(true)
				global_position = spot
				reset_physics_interpolation()
				state = "warn"
				st = WARN_T
			return Vector2.ZERO
		"warn":
			if st <= 0.0:
				_set_hidden(false)
				state = "slash"
				st = 0.18
				Sfx.play_at("swing", global_position, 0.3)
				var p2 = get_tree().get_first_node_in_group("player")
				if p2 != null and not p2.dead and p2.global_position.distance_to(global_position) < SLASH_R:
					p2.take_damage(SLASH, global_position, self)
			return Vector2.ZERO
		"slash":
			if st <= 0.0:
				state = "recover"
				st = 1.1
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				state = "walk"
				st = randf_range(2.6, 4.2)
			return Vector2.ZERO
	return Vector2.ZERO


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if hidden_now:
		return
	super.take_hit(dmg, dir, kb, can_burn)


func _contact_damage() -> float:
	return 0.0


func _zones() -> void:
	draw_arc(Vector2.ZERO, SLASH_R, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.6), 1.0)


## Una sagoma d'uomo fatta d'ombra, con due occhi bianchi; i bordi tremano. Quando affonda si
## schiaccia a terra, quando riaffiora sale dal cerchio.
func _draw() -> void:
	if state == "warn":
		Enemy.warn_circle(self, Vector2.ZERO, SLASH_R, 1.0 - st / WARN_T)
		draw_circle(Vector2.ZERO, 5.0 + 3.0 * (1.0 - st / WARN_T), Color(0.05, 0.02, 0.08, 0.85))
		return
	super._draw()


func _draw_body(flash: bool) -> void:
	var k := 1.0
	if state == "sink":
		k = clampf(st / SINK, 0.05, 1.0)
	var body := _f(Color(0.07, 0.04, 0.11, 0.92), flash)
	var edge := Color(0.55, 0.3, 0.8, 0.8)
	var pts := PackedVector2Array()
	var n := 16
	for i in range(n):
		var a := TAU * i / n
		var wob := 1.0 + 0.08 * sin(t * 7.0 + i * 1.9)
		pts.append(Vector2(cos(a) * 7.0 * wob, -11.0 * k + sin(a) * 11.0 * k * wob))
	draw_colored_polygon(pts, body)
	var cl := pts.duplicate()
	cl.append(pts[0])
	draw_polyline(cl, ELITE_RIM if elite else edge, 1.0)
	# braccia lunghe
	var sw := 0.0
	if state == "slash":
		sw = 1.0
	for sx in [-1.0, 1.0]:
		var a0 := Vector2(sx * 6.0, -13.0 * k)
		var a1 := Vector2(sx * (11.0 + 9.0 * sw), (-6.0 - 8.0 * sw) * k)
		draw_line(a0, a1, body, 2.6)
		for c in range(3):
			draw_line(a1, a1 + Vector2(sx * 3.0, -2.0 + c * 2.0), Color(0.85, 0.75, 0.95) if sw > 0.0 else edge, 0.9)
	var ey := -15.0 * k
	draw_circle(Vector2(-2.4, ey), 1.3, Color(1, 1, 1))
	draw_circle(Vector2(2.4, ey), 1.3, Color(1, 1, 1))
