class_name ArrowArt
## Il disegno dell'Arco di Satet e delle sue frecce: legno scuro ricurvo con le punte d'oro,
## corda di lino, frecce di canna con la punta di selce e le penne bianche.
## Lo usano il piedistallo del Cortile, la mano dell'eroe (player.gd) e le frecce in volo (arrow.gd).

const WOOD := Color(0.42, 0.26, 0.13)
const WOOD_LIGHT := Color(0.62, 0.42, 0.22)
const GOLD := Color(0.94, 0.74, 0.32)
const STRING := Color(0.93, 0.9, 0.8)
const REED := Color(0.78, 0.66, 0.4)
const FLINT := Color(0.86, 0.86, 0.9)
const FEATHER := Color(0.98, 0.96, 0.9)


## L'arco: guarda verso `angle` (la direzione del tiro); `pull` da 0 a 1 è quanto è tesa la corda
## (con una freccia incoccata se è più di zero).
static func draw_bow(ci: CanvasItem, c: Vector2, angle: float, s: float, pull: float) -> void:
	ci.draw_set_transform(c, angle, Vector2(s, s))
	var limb := PackedVector2Array()
	for i in range(13):
		var u := -1.0 + i / 6.0
		limb.append(Vector2(6.0 * (1.0 - u * u) - 1.5 * pull * (1.0 - u * u), u * 14.0))
	ci.draw_polyline(limb, Color(0.1, 0.06, 0.03), 3.4)
	ci.draw_polyline(limb, WOOD, 2.2)
	# il riflesso sul dorso del legno
	ci.draw_polyline(limb.slice(3, 10), WOOD_LIGHT, 0.8)
	# le punte ricurve d'oro, e l'impugnatura fasciata
	ci.draw_line(Vector2(0, -14), Vector2(2.2, -16.5), GOLD, 1.6)
	ci.draw_line(Vector2(0, 14), Vector2(2.2, 16.5), GOLD, 1.6)
	var gx := 6.0 - 1.5 * pull
	ci.draw_rect(Rect2(gx - 1.6, -2.5, 3.2, 5.0), GOLD)
	# la corda, tirata indietro quanto serve
	var nock := Vector2(-pull * 9.0, 0)
	ci.draw_polyline(PackedVector2Array([Vector2(0, -14), nock, Vector2(0, 14)]), STRING, 0.8)
	if pull > 0.0:
		draw_arrow(ci, nock + Vector2(9.0, 0), Vector2.RIGHT, 1.0, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Una freccia: `p` è il centro, `dir` la direzione del volo. `big` > 1 per il tiro carico.
static func draw_arrow(ci: CanvasItem, p: Vector2, dir: Vector2, big: float, alpha: float) -> void:
	var d := dir.normalized()
	var n := d.orthogonal()
	var half := 8.0 * big
	var tail := p - d * half
	var tip := p + d * half
	ci.draw_line(tail, tip, Color(0.12, 0.08, 0.04, alpha), 2.2 * big)
	ci.draw_line(tail, tip, Color(REED, alpha), 1.1 * big)
	ci.draw_colored_polygon(PackedVector2Array([tip + d * 4.5 * big, tip + n * 2.2 * big, tip - n * 2.2 * big]), Color(FLINT, alpha))
	# le penne bianche in coda
	for side in [1.0, -1.0]:
		ci.draw_line(tail + d * 3.0 * big, tail - d * 0.5 * big + n * side * 2.6 * big, Color(FEATHER, alpha), 1.2 * big)
