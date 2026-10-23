extends Enemy
## Scarabeo: arriva in sciami, veloce e fragile. Si muove a zig-zag verso di te.
## Insegna a usare i colpi ampi e l'Occhio di Horus sui gruppi.

@export var zigzag := 0.8


func _behave(_delta: float, to: Vector2) -> Vector2:
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var u := to.normalized()
	var v := u + u.orthogonal() * sin(t * 7.0 + seed_offset) * zigzag
	return v.normalized() * speed


func _draw_body(flash: bool) -> void:
	var shell := Color.WHITE if flash else Color(0.11, 0.43, 0.4)
	var dark := Color.WHITE if flash else Color(0.05, 0.2, 0.18)
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	for i in range(3):
		var lx := -3.0 + i * 3.0
		var w := sin(t * 20.0 + i) * 1.5
		draw_line(Vector2(lx, -3), Vector2(lx + w, 1), dark, 1.0)
	draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.75))
	draw_circle(Vector2.ZERO, 6.0, shell)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(Vector2(-5 * dir, -4), Vector2(4 * dir, -4), Color(0.94, 0.72, 0.3), 1.0)
	draw_circle(Vector2(6.0 * dir, -4), 2.5, dark)
