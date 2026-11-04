extends Enemy
## Ombra di Sabbia (servitore di Aker, esce dalla porta del tramonto a ovest): uno spirito lento
## fatto della sabbia di Ieri. Ti viene addosso piano e lascia dietro di sé una scia di sabbie
## mobili. Ferisce a contatto. Non lascia ricompense. Valori in cima (blocco 11).

const TRAIL_STEP := 30.0               ## ogni quanti pixel lascia una macchia di sabbie mobili
const TRAIL_LIFE := 3.0
const TRAIL_RADII := Vector2(16, 9)

var trail_last := Vector2.ZERO


func _ready() -> void:
	no_reward = true
	add_to_group("aker_servants")
	super._ready()
	trail_last = global_position


func _behave(delta: float, to: Vector2) -> Vector2:
	if global_position.distance_to(trail_last) > TRAIL_STEP:
		trail_last = global_position
		var q := Hazards.Quicksand.new()
		q.radii = TRAIL_RADII
		q.life = TRAIL_LIFE
		q.position = global_position
		get_parent().add_child(q)
	if to == Vector2.ZERO:
		return Vector2.ZERO
	return _steer(to.normalized() * speed, delta)


func _draw_body(flash: bool) -> void:
	var a := 0.75 + 0.15 * sin(t * 4.0)
	var body := Color(0.78, 0.64, 0.4, a) if not flash else Color.WHITE
	var dark := Color(0.32, 0.36, 0.6, a)                 # il blu della notte di Ieri
	# un velo di sabbia che si sfrangia verso il basso
	var pts := PackedVector2Array()
	for i in range(13):
		var u := float(i) / 12.0
		var ang := PI + u * PI
		pts.append(Vector2(cos(ang) * 7.0, -10.0 + sin(ang) * 8.0))
	for i in range(6):
		var x := 7.0 - i * 2.8
		pts.append(Vector2(x, -1.0 + sin(t * 9.0 + i * 1.3) * 1.5))
	draw_colored_polygon(pts, body)
	draw_polyline(pts + PackedVector2Array([pts[0]]), dark, 1.0)
	# due occhi blu
	draw_circle(Vector2(-2.5, -12.0), 1.4, Color(0.55, 0.7, 1.0, a))
	draw_circle(Vector2(2.5, -12.0), 1.4, Color(0.55, 0.7, 1.0, a))
	for i in range(3):
		var k := fmod(t * 1.2 + i * 0.33, 1.0)
		draw_circle(Vector2(sin(i * 2.0 + t) * 5.0, -2.0 + k * 3.0), 1.2 * (1.0 - k), Color(0.78, 0.64, 0.4, 0.6 * (1.0 - k)))
