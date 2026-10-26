extends Enemy
## Scarabeo: arriva in sciami, veloce e fragile. Si muove a zig-zag verso di te.
## Insegna a usare i colpi ampi e l'Occhio di Horus sui gruppi.

@export var zigzag := 0.8


var step_t := 0.0


func _behave(delta: float, to: Vector2) -> Vector2:
	if to == Vector2.ZERO:
		return Vector2.ZERO
	# zampettio: un passetto ogni tanto, sfasato tra uno scarabeo e l'altro
	step_t -= delta
	if step_t <= 0.0:
		step_t = randf_range(0.16, 0.3)
		Sfx.play_at("scarab_step", global_position, 0.25)
	var u := to.normalized()
	var v := u + u.orthogonal() * sin(t * 7.0 + seed_offset) * zigzag
	return _steer(v.normalized() * speed, delta)


## Lo scarabeo sacro di Khepri visto di tre quarti: elitre verde-turchese con il riflesso,
## la linea d'oro dove si aprono le ali, lo scudo della testa col pettine e sei zampe che corrono.
func _draw_body(flash: bool) -> void:
	var shell := _f(Color(0.1, 0.4, 0.4), flash)
	var shell_d := _f(Color(0.05, 0.24, 0.26), flash)
	var shine := _f(Color(0.45, 0.85, 0.75), flash)
	var leg := _f(Color(0.12, 0.16, 0.13), flash)
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# zampe: tre per lato, a passi alternati (quelle dietro più scure)
	for i in range(3):
		var lx := -3.5 + i * 3.4
		var w := sin(t * 22.0 + i * 2.1) * 1.6
		_limb(Vector2(lx, -4.0), Vector2(lx - 1.0 - w, -0.3), leg, 0.8)
		_limb(Vector2(lx + 0.6, -3.2), Vector2(lx + 0.4 + w, 0.8), leg, 0.9)
	# elitre
	_op(_ell(Vector2(-1.0, -5.0), 6.0, 4.2, 16), shell)
	draw_colored_polygon(_ell(Vector2(-1.0, -3.6), 5.0, 2.4, 12), shell_d)
	draw_line(Vector2(-6.6, -5.3), Vector2(3.6, -5.3), _f(GOLD, flash), 0.9)
	draw_arc(Vector2(-2.0, -6.2), 3.4, PI * 1.05, PI * 1.6, 6, shine, 1.0)
	# scudo della testa con il pettine (lo "scavo" di Khepri) e gli occhi
	var head := PackedVector2Array([Vector2(4.0, -8.0), Vector2(7.2, -7.0), Vector2(8.4, -4.8), Vector2(7.2, -2.8), Vector2(4.0, -2.4)])
	_op(head, shell_d)
	for k in range(3):
		var y := -6.6 + k * 1.6
		draw_line(Vector2(8.0, y), Vector2(9.4, y - 0.4), OUT, 0.8)
	draw_circle(Vector2(6.4, -6.0), 0.6, _f(Color(0.9, 0.75, 0.35), flash))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
