class_name AkerArt
extends RefCounted
## Il disegno dei leoni di Aker, in comune tra il leone doppio (aker.gd) e Ieri e Domani
## (aker_lion.gd). Leoni egizi: corpo snello, criniera stilizzata a raggi, occhio dipinto.
## Ieri (ovest, il tramonto): ocra della sabbia, criniera blu notte.
## Domani (est, l'alba): rosso e oro, criniera di fiamma che si accende quando attacca.

const OUT := Color(0.12, 0.08, 0.05)

const IERI := {"body": Color(0.78, 0.6, 0.34), "body_d": Color(0.55, 0.4, 0.2), "mane": Color(0.16, 0.22, 0.45), "accent": Color(0.94, 0.72, 0.3)}
const DOMANI := {"body": Color(0.82, 0.38, 0.18), "body_d": Color(0.55, 0.2, 0.1), "mane": Color(0.95, 0.62, 0.18), "accent": Color(1.0, 0.9, 0.5)}


static func _c(c: Color, flash: bool) -> Color:
	return Color(1, 1, 1, c.a) if flash else c


static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w: float) -> void:
	ci.draw_colored_polygon(pts, fill)
	var cl := pts.duplicate()
	cl.append(pts[0])
	ci.draw_polyline(cl, OUT, w)


static func _ell(c: Vector2, rx: float, ry: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _leg(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, OUT, w + 1.2)
	ci.draw_line(a, b, col, w)


## Un leone visto di lato, con la testa verso `sx` (+1 destra, -1 sinistra), in scala `s`.
## pose: "lying" (accucciato, il leone doppio), "stand" (fermo), "walk" (passo), "leap" (balzo).
## `mouth` 0..1: le fauci aperte (avviso); `glow`: la criniera di Domani che arde.
static func lion(ci: CanvasItem, o: Vector2, sx: float, s: float, pal: Dictionary, pose: String, t: float, mouth: float, glow: float, flash: bool, with_tail: bool = true) -> void:
	var body: Color = _c(pal["body"], flash)
	var body_d: Color = _c(pal["body_d"], flash)
	var mane: Color = _c(pal["mane"], flash)
	var accent: Color = _c(pal["accent"], flash)
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x * sx, y) * s
	var lying := pose == "lying"
	var lift := 0.0 if lying else 5.5
	var step := sin(t * 10.0) * 2.0 if pose == "walk" else 0.0
	# la coda, che sale dietro e finisce col ciuffo
	if with_tail:
		var tail := PackedVector2Array()
		for k in range(7):
			var u := k / 6.0
			tail.append(P.call(-14.0 - u * 6.0, -5.0 - lift - u * 7.0 + sin(t * 3.0 + u * 2.0) * 1.2))
		ci.draw_polyline(tail, OUT, 3.0 * s * 0.6 + 1.0)
		ci.draw_polyline(tail, body_d, 1.6 * s * 0.6)
		ci.draw_circle(tail[6], 2.0 * s, OUT)
		ci.draw_circle(tail[6], 1.5 * s, mane)
	# le zampe di dietro e di davanti
	if lying:
		_leg(ci, P.call(-12, -3), P.call(-5, -1), body_d, 2.6 * s)
		_leg(ci, P.call(5, -3), P.call(17, -1), body, 2.4 * s)
		_leg(ci, P.call(4, -1.5), P.call(15, 0.5), body_d, 2.4 * s)
		ci.draw_circle(P.call(17.5, -1), 1.6 * s, body)
	else:
		# zampe: quelle lontane più scure, la coscia larga che si stringe verso la zampa
		var legs := [[-8.0, -step, true], [9.0, step, true], [-11.5, step, false], [6.0, -step, false]]
		for lg in legs:
			var x: float = lg[0]
			var dx: float = lg[1]
			var far: bool = lg[2]
			var foot_y := -1.0 if pose != "leap" else -4.0
			var fx := x + dx + (2.5 if pose == "leap" and x > 0.0 else 0.0)
			var col := body_d if far else body
			var top_p: Vector2 = P.call(x, -lift - 3.0)
			var knee: Vector2 = P.call(x + dx * 0.5 + (0.8 if x < 0.0 else -0.4), (-lift - 3.0 + foot_y) * 0.5)
			var foot: Vector2 = P.call(fx, foot_y)
			_leg(ci, top_p, knee, col, 2.6 * s)
			_leg(ci, knee, foot, col, 1.5 * s)
			ci.draw_circle(foot + Vector2(0.6 * sx, 0) * s, 1.4 * s, OUT)
			ci.draw_circle(foot + Vector2(0.6 * sx, 0) * s, 1.0 * s, col)
	# il corpo snello, con la pancia più chiara
	var torso := _ell(P.call(-3, -6.5 - lift), 13.0 * s, 5.5 * s, 18)
	_poly(ci, torso, body, 1.0)
	ci.draw_arc(P.call(-3, -4.0 - lift), 9.0 * s, 0.4, PI - 0.4, 10, body_d, 1.2)
	# la criniera a raggi, come nelle statue: un disco e le ciocche che si aprono
	var mc: Vector2 = P.call(9, -12 - lift)
	var mr := 7.5 * s
	if glow > 0.0:
		ci.draw_circle(mc, mr + 4.0 * s * glow, Color(1.0, 0.6, 0.2, 0.25 * glow))
	for k in range(15):
		var a := -PI * 0.95 + PI * 1.55 * k / 14.0
		var dir := Vector2(cos(a) * sx, sin(a))
		_leg(ci, mc + dir * mr * 0.6, mc + dir * (mr + 0.9 * s), mane, 1.1 * s)
	ci.draw_circle(mc, mr + 0.6, OUT)
	ci.draw_circle(mc, mr, mane)
	ci.draw_arc(mc, mr * 0.7, 0.0, TAU, 16, accent, 0.8)
	# la testa: muso allungato, orecchio tondo, occhio dipinto con il kohl
	var hc: Vector2 = P.call(12.5, -13.5 - lift)
	_poly(ci, _ell(hc, 4.6 * s, 4.2 * s, 14), body, 0.9)
	_poly(ci, _ell(P.call(16.5, -12.5 - lift), 3.0 * s, 2.3 * s, 10), body, 0.8)
	ci.draw_circle(P.call(19.0, -13.2 - lift), 0.9 * s, OUT)
	ci.draw_circle(P.call(11.0, -18.0 - lift), 1.4 * s, OUT)
	ci.draw_circle(P.call(11.0, -18.0 - lift), 1.0 * s, body_d)
	var eye: Vector2 = P.call(14.0, -15.0 - lift)
	ci.draw_circle(eye, 1.0 * s, Color(0.98, 0.95, 0.85) if not flash else Color.WHITE)
	ci.draw_circle(eye + Vector2(0.3 * sx, 0) * s, 0.55 * s, OUT)
	ci.draw_line(eye + Vector2(-1.0 * sx, -0.2) * s, eye + Vector2(-2.6 * sx, -0.8) * s, OUT, 0.5 * s)
	# le fauci che si aprono prima dell'attacco
	if mouth > 0.0:
		var m0: Vector2 = P.call(14.5, -11.0 - lift)
		_poly(ci, PackedVector2Array([m0, P.call(19.5, -11.5 - lift), P.call(18.5, -11.5 - lift + 3.0 * mouth)]), Color(0.6, 0.12, 0.1), 0.6)
		ci.draw_line(P.call(16.5, -11.4 - lift), P.call(16.8, -10.6 - lift), Color.WHITE, 0.6 * s)
