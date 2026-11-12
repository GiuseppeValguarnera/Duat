class_name ApepArena
extends RefCounted
## Il Banco di Apopi (terza regione): i pavimenti. Tutto disegnato una volta nella texture della stanza.
## - paint_cave_floor: le stanze normali. Roccia nera-viola bagnata, vene di caos che pulsano di viola,
##   pozzanghere d'acqua nera, ossa e scaglie enormi: la caverna dove il serpente dorme di giorno.
## - paint_press: l'arena di Shezmu. Il torchio: una grande vasca rotonda di pietra macchiata di vino,
##   canali che portano il rosso ai quattro angoli, giare.
## - paint_bank: l'arena di Apopi. Il banco di sabbia grigia in mezzo all'acqua nera, la barca di Ra
##   arenata a sud, le spire del serpente che affiorano tutto intorno.

const ROCK := Color(0.13, 0.1, 0.17)
const ROCK_HI := Color(0.22, 0.17, 0.28)
const VEIN := Color(0.55, 0.25, 0.8)
const WATER := Color(0.03, 0.04, 0.09)


static func paint_cave_floor(ci: CanvasItem, fr: Rect2, room: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = room * 1319 + 71
	ci.draw_rect(fr, ROCK)
	# lastroni irregolari: chiazze più chiare e più scure
	for i in range(46):
		var c := Vector2(rng.randf_range(fr.position.x, fr.end.x), rng.randf_range(fr.position.y, fr.end.y))
		var rad := Vector2(rng.randf_range(22, 70), rng.randf_range(12, 32))
		ci.draw_set_transform(c, rng.randf_range(-0.3, 0.3), Vector2(1.0, rad.y / rad.x))
		var light := i % 3 != 0
		ci.draw_circle(Vector2.ZERO, rad.x, Color(ROCK_HI, 0.5) if light else Color(0.07, 0.05, 0.1, 0.55))
		if light:
			ci.draw_arc(Vector2.ZERO, rad.x, PI * 1.05, PI * 1.9, 14, Color(0.34, 0.28, 0.42, 0.55), 1.2)
			ci.draw_arc(Vector2.ZERO, rad.x, 0.1, PI * 0.9, 14, Color(0.04, 0.03, 0.06, 0.6), 1.4)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# crepe
	for i in range(18):
		var p := Vector2(rng.randf_range(fr.position.x + 10, fr.end.x - 10), rng.randf_range(fr.position.y + 10, fr.end.y - 10))
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([p])
		for k in range(rng.randi_range(3, 6)):
			a += rng.randf_range(-0.7, 0.7)
			p += Vector2.from_angle(a) * rng.randf_range(8.0, 18.0)
			pts.append(p)
		ci.draw_polyline(pts, Color(0.03, 0.02, 0.05, 0.9), 1.4)
	# vene di caos: linee viola luminose (poche: devono restare un accento)
	for i in range(5):
		var p := Vector2(rng.randf_range(fr.position.x + 20, fr.end.x - 20), rng.randf_range(fr.position.y + 20, fr.end.y - 20))
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([p])
		for k in range(rng.randi_range(5, 9)):
			a += rng.randf_range(-0.5, 0.5)
			p += Vector2.from_angle(a) * rng.randf_range(10.0, 20.0)
			if fr.grow(-6.0).has_point(p):
				pts.append(p)
		if pts.size() >= 2:
			ci.draw_polyline(pts, Color(VEIN, 0.16), 5.0)
			ci.draw_polyline(pts, Color(VEIN, 0.5), 1.3)
	# pozzanghere d'acqua: poche, piccole e AZZURRE, per non confonderle con le pozze di Isfet (nere e viola)
	for i in range(3):
		var c := Vector2(rng.randf_range(fr.position.x + 30, fr.end.x - 30), rng.randf_range(fr.position.y + 24, fr.end.y - 24))
		var rx := rng.randf_range(9.0, 15.0)
		ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		ci.draw_circle(Vector2.ZERO, rx + 1.5, Color(0.2, 0.2, 0.3))
		ci.draw_circle(Vector2.ZERO, rx, Color(0.12, 0.22, 0.36))
		ci.draw_arc(Vector2.ZERO, rx * 0.6, PI * 1.1, PI * 1.6, 8, Color(0.6, 0.75, 0.95, 0.6), 1.2)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# scaglie cadute (grandi come scudi) e ossa
	for i in range(7):
		var c := Vector2(rng.randf_range(fr.position.x + 16, fr.end.x - 16), rng.randf_range(fr.position.y + 16, fr.end.y - 16))
		if i % 2 == 0:
			ci.draw_set_transform(c, rng.randf() * TAU, Vector2(1.0, 0.6))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(0, -5), Vector2(7, 0), Vector2(0, 5)]), Color(0.26, 0.12, 0.34))
			ci.draw_polyline(PackedVector2Array([Vector2(-7, 0), Vector2(0, -5), Vector2(7, 0)]), Color(0.5, 0.3, 0.62), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var a := rng.randf() * TAU
			var d := Vector2.from_angle(a) * 6.0
			ci.draw_line(c - d, c + d, Color(0.72, 0.68, 0.6, 0.8), 1.6)
			ci.draw_circle(c - d, 1.5, Color(0.72, 0.68, 0.6, 0.8))
			ci.draw_circle(c + d, 1.5, Color(0.72, 0.68, 0.6, 0.8))


## Le spire che affiorano lungo il bordo: archi di serpente (decorazione, stanno sui muri).
static func _coil(ci: CanvasItem, c: Vector2, w: float, h: float) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var u := i / 16.0
		pts.append(c + Vector2(lerpf(-w, w, u), -sin(u * PI) * h))
	ci.draw_polyline(pts, Color(0.03, 0.02, 0.05), 17.0)
	ci.draw_polyline(pts, Color(0.12, 0.07, 0.17), 14.0)
	for i in range(2, 15, 2):
		ci.draw_arc(pts[i], 4.5, PI, TAU, 6, Color(0.36, 0.16, 0.48), 1.6)
	var hi := PackedVector2Array()
	for q in pts:
		hi.append(q + Vector2(0, -5))
	ci.draw_polyline(hi, Color(0.5, 0.35, 0.65, 0.35), 1.2)


static func paint_press(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var fr := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	paint_cave_floor(ci, fr, 505)
	var mid := fr.get_center()
	var rad := Vector2(150.0, 92.0)
	# i canali del vino verso i quattro angoli
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var a := mid + Vector2(sx * rad.x * 0.7, sy * rad.y * 0.7)
			var b := Vector2(mid.x + sx * (fr.size.x / 2.0 - 26.0), mid.y + sy * (fr.size.y / 2.0 - 22.0))
			ci.draw_line(a, b, Color(0.05, 0.03, 0.05), 9.0)
			ci.draw_line(a, b, Color(0.42, 0.06, 0.1), 5.0)
			ci.draw_line(a + Vector2(0, -1.5), b + Vector2(0, -1.5), Color(0.7, 0.16, 0.2, 0.6), 1.0)
			# la giara che raccoglie
			ci.draw_circle(b + Vector2(0, 3), 9.0, Color(0, 0, 0, 0.3))
			ci.draw_circle(b, 8.0, Color(0.5, 0.3, 0.2))
			ci.draw_circle(b, 5.0, Color(0.35, 0.05, 0.08))
			ci.draw_arc(b, 8.0, 0.0, TAU, 16, Color(0.2, 0.12, 0.08), 1.2)
	# la vasca del torchio
	ci.draw_set_transform(mid, 0.0, Vector2(1.0, rad.y / rad.x))
	ci.draw_circle(Vector2(4, 8), rad.x + 8.0, Color(0, 0, 0, 0.3))
	ci.draw_circle(Vector2.ZERO, rad.x + 8.0, Color(0.2, 0.17, 0.2))
	ci.draw_circle(Vector2.ZERO, rad.x, Color(0.4, 0.34, 0.36))
	ci.draw_circle(Vector2(-6, -6), rad.x * 0.93, Color(0.46, 0.4, 0.4))
	for k in range(1, 4):
		ci.draw_arc(Vector2.ZERO, rad.x * k / 4.0, 0.0, TAU, 48, Color(0.26, 0.2, 0.22), 1.4)
	for i in range(12):
		var a := TAU * i / 12.0
		ci.draw_line(Vector2.from_angle(a) * rad.x / 4.0, Vector2.from_angle(a) * rad.x, Color(0.26, 0.2, 0.22), 1.2)
	# macchie di vino
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(16):
		var p := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, rad.x * 0.9)
		ci.draw_circle(p, rng.randf_range(4.0, 15.0), Color(0.45, 0.06, 0.1, rng.randf_range(0.25, 0.55)))
	ci.draw_arc(Vector2.ZERO, rad.x - 5.0, 0.0, TAU, 64, Color(0.7, 0.14, 0.18, 0.7), 2.5)
	# il segno di Shezmu al centro: il torchio (due pali e il sacco ritorto)
	ci.draw_set_transform(mid, 0.0, Vector2.ONE)
	var g := Color(0.85, 0.64, 0.26, 0.8)
	ci.draw_line(Vector2(-16, -10), Vector2(-16, 10), g, 2.5)
	ci.draw_line(Vector2(16, -10), Vector2(16, 10), g, 2.5)
	for i in range(5):
		ci.draw_line(Vector2(-14 + i * 6.0, -4), Vector2(-10 + i * 6.0, 4), g, 2.0)
	ci.draw_line(Vector2(-16, 0), Vector2(16, 0), g, 1.4)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func paint_bank(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var fr := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	# l'acqua nera tutto intorno (si cammina ovunque: è bassa), il banco di sabbia grigia al centro
	ci.draw_rect(fr, WATER)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7707
	for i in range(40):
		var p := Vector2(rng.randf_range(fr.position.x + 8, fr.end.x - 8), rng.randf_range(fr.position.y + 6, fr.end.y - 6))
		ci.draw_line(p, p + Vector2(rng.randf_range(10.0, 26.0), 0), Color(0.35, 0.4, 0.65, 0.25), 1.0)
	var mid := fr.get_center()
	var rad := Vector2(fr.size.x * 0.44, fr.size.y * 0.4)
	ci.draw_set_transform(mid, 0.0, Vector2(1.0, rad.y / rad.x))
	ci.draw_circle(Vector2.ZERO, rad.x + 10.0, Color(0.12, 0.12, 0.2))
	ci.draw_circle(Vector2.ZERO, rad.x + 4.0, Color(0.3, 0.28, 0.32))
	ci.draw_circle(Vector2.ZERO, rad.x, Color(0.46, 0.42, 0.42))
	ci.draw_circle(Vector2(-10, -8), rad.x * 0.9, Color(0.52, 0.47, 0.46))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# le onde che l'acqua ha lasciato ritirandosi: anelli sulla sabbia
	for k in range(1, 5):
		var pts := PackedVector2Array()
		for i in range(49):
			var a := TAU * i / 48.0
			var wob := 1.0 + 0.03 * sin(a * 7.0 + k)
			pts.append(mid + Vector2(cos(a) * rad.x, sin(a) * rad.y) * (k / 5.0) * wob)
		ci.draw_polyline(pts, Color(0.36, 0.32, 0.34, 0.5), 1.2)
	for i in range(40):
		var a := rng.randf() * TAU
		var p := mid + Vector2(cos(a) * rad.x, sin(a) * rad.y) * sqrt(rng.randf()) * 0.95
		ci.draw_circle(p, rng.randf_range(0.8, 2.2), Color(0.3, 0.27, 0.3, 0.7))
	# vene di caos sotto la sabbia
	for i in range(4):
		var p := mid + Vector2(rng.randf_range(-rad.x, rad.x) * 0.6, rng.randf_range(-rad.y, rad.y) * 0.6)
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([p])
		for k in range(7):
			a += rng.randf_range(-0.5, 0.5)
			p += Vector2.from_angle(a) * 16.0
			pts.append(p)
		ci.draw_polyline(pts, Color(VEIN, 0.14), 5.0)
		ci.draw_polyline(pts, Color(VEIN, 0.45), 1.2)
	# la barca di Ra arenata, a sud: scafo d'oro inclinato, la cabina, il disco spento
	var bc := Vector2(mid.x, fr.end.y - 30.0)
	ci.draw_set_transform(bc, -0.08, Vector2.ONE)
	var hull := PackedVector2Array()
	for i in range(21):
		var u := i / 20.0
		hull.append(Vector2(lerpf(-78.0, 78.0, u), -absf(u - 0.5) * 2.0 * 18.0 + 10.0))
	for i in range(20, -1, -1):
		var u := i / 20.0
		hull.append(Vector2(lerpf(-70.0, 70.0, u), -absf(u - 0.5) * 2.0 * 10.0 + 22.0))
	ci.draw_colored_polygon(hull, Color(0.62, 0.46, 0.16))
	var hl := hull.duplicate()
	hl.append(hull[0])
	ci.draw_polyline(hl, Color(0.12, 0.08, 0.05), 1.4)
	ci.draw_line(Vector2(-66, 14), Vector2(66, 14), Color(0.85, 0.68, 0.3), 1.5)
	ci.draw_rect(Rect2(-16, -8, 32, 18), Color(0.3, 0.22, 0.3))
	ci.draw_rect(Rect2(-16, -8, 32, 18), Color(0.85, 0.68, 0.3), false, 1.2)
	ci.draw_circle(Vector2(0, -18), 9.0, Color(0.12, 0.08, 0.05))
	ci.draw_circle(Vector2(0, -18), 7.5, Color(0.5, 0.25, 0.14))          # il sole spento
	ci.draw_arc(Vector2(0, -18), 7.5, 0.0, TAU, 20, Color(0.8, 0.45, 0.2, 0.6), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# le spire di Apopi che affiorano ai bordi
	_coil(ci, Vector2(fr.position.x + 60.0, fr.position.y + 18.0), 44.0, 16.0)
	_coil(ci, Vector2(fr.end.x - 70.0, fr.position.y + 20.0), 50.0, 18.0)
	_coil(ci, Vector2(fr.position.x + 34.0, mid.y + 30.0), 26.0, 22.0)
	_coil(ci, Vector2(fr.end.x - 34.0, mid.y - 20.0), 26.0, 22.0)
