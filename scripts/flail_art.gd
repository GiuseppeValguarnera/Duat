class_name FlailArt
## Le insegne del faraone: il flagello (nekhakha) e il pastorale (heka) di Osiride, a strisce d'oro
## e di lapislazzuli come sul sarcofago di Tutankhamon. Li usano il piedistallo del Cortile e la mano
## dell'eroe (player.gd): il flagello per le frustate, il pastorale per l'aggancio.

const GOLD := Color(0.95, 0.76, 0.3)
const BLUE := Color(0.2, 0.32, 0.78)
const DARK := Color(0.08, 0.06, 0.04)
const BEAD := Color(0.98, 0.86, 0.5)
const RED := Color(0.92, 0.26, 0.2)       ## il pastorale quando è l'eroe a essere tirato


## Un manico a strisce oro e blu da `a` a `b`.
static func _striped(ci: CanvasItem, a: Vector2, b: Vector2, w: float, tint: Color) -> void:
	ci.draw_line(a, b, DARK, w + 1.2)
	var n := 5
	for i in range(n):
		var p0 := a.lerp(b, float(i) / n)
		var p1 := a.lerp(b, float(i + 1) / n)
		ci.draw_line(p0, p1, (GOLD if i % 2 == 0 else BLUE) * tint, w)


## Il flagello in mano, a riposo: il manico verso `dir`, le tre code di perline che pendono.
static func draw_flail(ci: CanvasItem, hand: Vector2, dir: Vector2, s: float) -> void:
	var tip := hand + dir * 11.0 * s
	_striped(ci, hand - dir * 3.0 * s, tip, 2.0 * s, Color.WHITE)
	ci.draw_circle(tip, 1.8 * s, GOLD)
	var side := dir.orthogonal()
	for k: float in [-1.0, 0.0, 1.0]:
		var end := tip + side * k * 3.0 * s + Vector2(0, 8.0 * s) + dir * 2.0 * s
		ci.draw_line(tip, end, Color(BEAD, 0.9), 1.0 * s)
		for j in range(1, 4):
			ci.draw_circle(tip.lerp(end, j / 3.0), 0.9 * s, BLUE if j % 2 == 0 else BEAD)


## La frustata: tre code ondulate che si allungano da `from` lungo `dir` fino a `length`.
## `k` da 0 a 1 è l'avanzare del colpo (la punta arriva in fondo a metà, poi la scia svanisce).
static func draw_lash(ci: CanvasItem, from: Vector2, dir: Vector2, length: float, k: float, bright: Color) -> void:
	var reach := length * clampf(k * 2.0, 0.0, 1.0)
	var fade := 1.0 - clampf((k - 0.5) * 2.0, 0.0, 1.0)
	var side := dir.orthogonal()
	for strand: float in [-1.0, 0.0, 1.0]:
		var pts := PackedVector2Array()
		for i in range(13):
			var u := i / 12.0
			var wave := sin(u * 9.0 + k * 14.0 + strand) * 3.0 * (1.0 - u * 0.6)
			pts.append(from + dir * reach * u + side * (wave + strand * 2.2 * u))
		ci.draw_polyline(pts, Color(BEAD, 0.85 * fade), 1.3)
		ci.draw_circle(pts[pts.size() - 1], 1.6, Color(bright, fade))
	ci.draw_line(from, from + dir * reach, Color(bright, 0.25 * fade), 5.0)


## Il pastorale: un bastone a strisce lungo `dir` con il ricciolo in cima. `tint` oro o rosso.
static func draw_crook(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, tint: Color) -> void:
	var top := base + dir * length
	_striped(ci, base, top, 2.0, Color(tint.r * 1.05, tint.g * 1.05, tint.b * 1.05))
	var side := dir.orthogonal()
	var c := top + side * 3.5
	var pts := PackedVector2Array()
	for i in range(10):
		var a := -PI * 0.5 + PI * 1.3 * i / 9.0
		pts.append(c + (-side * cos(a) + dir * sin(a)) * -3.5)
	ci.draw_polyline(pts, DARK, 3.0)
	ci.draw_polyline(pts, tint, 1.8)
