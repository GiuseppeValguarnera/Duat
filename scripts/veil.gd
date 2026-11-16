extends Enemy
## Portatore del velo (blocco 21): una figura curva che porta sulle spalle un telo di buio. Attorno a
## sé stende una zona d'ombra (cerchio rosso scuro, raggio 70): lì dentro i nemici con le scaglie non
## le aprono MAI, nemmeno nel fascio di Ra. Non attacca, si muove piano, ha poca vita: va tolto di
## mezzo per primo. Cerca di stare vicino ai suoi compagni e lontano da te. Al massimo uno per stanza.

const KEEP := 120.0                ## se sei più vicino di così, si allontana

var drift := Vector2.ZERO
var drift_t := 0.0


func _ready() -> void:
	super._ready()
	add_to_group("veils")


func _behave(delta: float, to: Vector2) -> Vector2:
	drift_t -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	if drift_t <= 0.0:
		drift_t = 0.6
		# verso il compagno con le scaglie più vicino (per coprirlo), ma non addosso a te
		var best: Node2D = null
		var best_d := 1e9
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == self or e.dead or not e.scales:
				continue
			var dd: float = e.global_position.distance_to(global_position)
			if dd < best_d:
				best_d = dd
				best = e
		drift = Vector2.ZERO
		if to.length() < KEEP:
			drift = -to.normalized()
		elif best != null and best_d > RaLight.VEIL_R * 0.5:
			drift = (best.global_position - global_position).normalized()
	return _steer(drift * speed, delta) if drift != Vector2.ZERO else Vector2.ZERO


func _contact_damage() -> float:
	return 0.0


func _draw_body(flash: bool) -> void:
	# la zona d'ombra: disco scuro e bordo rosso scuro, sempre visibile
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	draw_circle(Vector2.ZERO, RaLight.VEIL_R, Color(0.12, 0.02, 0.06, 0.34))
	draw_arc(Vector2.ZERO, RaLight.VEIL_R, 0.0, TAU, 40, Color(0.62, 0.1, 0.14, 0.75 + 0.2 * pulse), 2.0)
	for i in range(12):
		var a := TAU * i / 12.0 + t * 0.4
		draw_line(Vector2.from_angle(a) * (RaLight.VEIL_R - 6.0), Vector2.from_angle(a) * RaLight.VEIL_R, Color(0.62, 0.1, 0.14, 0.8), 1.4)
	var skin := _f(Color(0.3, 0.26, 0.34), flash)
	var cloth := _f(Color(0.1, 0.03, 0.07), flash)
	var step := sin(t * 5.0) * 1.2 if velocity.length() > 4.0 else 0.0
	_limb(Vector2(-2.5, -6), Vector2(-3.0 - step, 0), skin, 1.8)
	_limb(Vector2(2.5, -6), Vector2(3.0 + step, 0), skin, 1.8)
	_op(_ell(Vector2(0, -11), 5.0, 6.0, 10), skin)
	_op(_ell(Vector2(0, -19), 3.6, 3.6, 10), skin)
	draw_circle(Vector2(-1.3, -19.4), 0.8, Color(0.9, 0.2, 0.2))
	draw_circle(Vector2(1.3, -19.4), 0.8, Color(0.9, 0.2, 0.2))
	# il telo: un drappo scuro tenuto alto sopra la testa, che ondeggia
	var w := sin(t * 3.0) * 2.0
	var pts := PackedVector2Array([Vector2(-12, -24 + w), Vector2(0, -31 - w * 0.5), Vector2(12, -24 - w), Vector2(14, -8 + w), Vector2(9, -14), Vector2(-9, -14), Vector2(-14, -8 - w)])
	_op(pts, cloth, 1.0)
	draw_line(Vector2(-12, -24 + w), Vector2(12, -24 - w), Color(0.62, 0.1, 0.14), 1.4)
	_limb(Vector2(-4.5, -14), Vector2(-9, -22 + w), skin, 1.5)
	_limb(Vector2(4.5, -14), Vector2(9, -22 - w), skin, 1.5)
