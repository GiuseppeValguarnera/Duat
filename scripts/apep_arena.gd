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


## Il segno del tipo di stanza sul pavimento della caverna (blocco 21): ogni tipo si riconosce entrando.
static func paint_room_type(ci: CanvasItem, fr: Rect2, kind: String) -> void:
	var mid := fr.get_center()
	var gold := Color(0.94, 0.72, 0.3)
	match kind:
		"barca":
			# la scia della barca del sole: una strada chiara da ovest a est, con le coste dello scafo
			ci.draw_rect(Rect2(fr.position.x, mid.y - 34.0, fr.size.x, 68.0), Color(0.9, 0.75, 0.4, 0.07))
			ci.draw_line(Vector2(fr.position.x, mid.y - 34.0), Vector2(fr.end.x, mid.y - 34.0), Color(gold, 0.3), 1.4)
			ci.draw_line(Vector2(fr.position.x, mid.y + 34.0), Vector2(fr.end.x, mid.y + 34.0), Color(gold, 0.3), 1.4)
			var x := fr.position.x + 40.0
			while x < fr.end.x - 30.0:
				ci.draw_polyline(PackedVector2Array([Vector2(x - 10.0, mid.y - 22.0), Vector2(x + 6.0, mid.y), Vector2(x - 10.0, mid.y + 22.0)]), Color(gold, 0.16), 2.0)
				x += 64.0
		"pozze":
			# roccia spaccata: crepe viola che partono dal centro (da qui sale l'Isfet)
			var rng := RandomNumberGenerator.new()
			rng.seed = 2107
			for i in range(9):
				var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
				var p := mid
				var pts := PackedVector2Array([p])
				for k in range(6):
					a += rng.randf_range(-0.5, 0.5)
					p += Vector2.from_angle(a) * Vector2(34.0, 22.0)
					if not fr.grow(-6.0).has_point(p):
						break
					pts.append(p)
				if pts.size() >= 2:
					ci.draw_polyline(pts, Color(0.04, 0.02, 0.07, 0.9), 3.0)
					ci.draw_polyline(pts, Color(0.5, 0.25, 0.75, 0.45), 1.0)
		"pali":
			# il cerchio di Serket: un anello inciso, turchese e oro, con tre basi per i pali
			ci.draw_set_transform(mid, 0.0, Vector2(1.0, 66.0 / 92.0))
			ci.draw_circle(Vector2.ZERO, 100.0, Color(0.1, 0.16, 0.2, 0.35))
			ci.draw_arc(Vector2.ZERO, 100.0, 0.0, TAU, 56, Color(0.2, 0.62, 0.62, 0.6), 2.4)
			ci.draw_arc(Vector2.ZERO, 84.0, 0.0, TAU, 48, Color(gold, 0.35), 1.2)
			for i in range(24):
				var a2 := TAU * i / 24.0
				ci.draw_line(Vector2.from_angle(a2) * 86.0, Vector2.from_angle(a2) * 98.0, Color(0.2, 0.62, 0.62, 0.4), 1.2)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in range(3):
				var at := mid + Vector2.from_angle(-PI / 2.0 + TAU * i / 3.0) * Vector2(92.0, 66.0)
				ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
				ci.draw_circle(Vector2.ZERO, 16.0, Color(0.05, 0.08, 0.1, 0.8))
				ci.draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 20, Color(gold, 0.6), 1.4)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"torchio":
			# il telaio di pietra del torchio attorno alle sei piastre, e due canali di vino verso i lati
			var frame := Rect2(mid + Vector2(-90, -42), Vector2(180, 84))
			for sx in [-1.0, 1.0]:
				var a3 := mid + Vector2(sx * 90.0, 0)
				var b3 := Vector2(mid.x + sx * (fr.size.x / 2.0 - 10.0), mid.y)
				ci.draw_line(a3, b3, Color(0.05, 0.03, 0.05), 8.0)
				ci.draw_line(a3, b3, Color(0.42, 0.06, 0.1), 4.0)
			ci.draw_rect(frame.grow(5.0), Color(0.05, 0.03, 0.05))
			ci.draw_rect(frame, Color(0.2, 0.17, 0.2))
			ci.draw_rect(frame, Color(0.55, 0.12, 0.16, 0.7), false, 1.6)


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


## L'ARENA VIVA di Shezmu (blocco 22): sei piastre di pietra attorno alla vasca. Una alla volta si
## abbassa di colpo come il piano del torchio: prima diventa rossa per 0,9 s (l'avviso, con la misura
## vera della piastra), poi schiaccia chi c'è sopra (12, fonte «piastra»). Mai due insieme, mai la
## stessa due volte di fila, e ferme finché ci sono i grappoli (mai più di due cose da leggere).
class Plates extends Node2D:
	const SIZE := Vector2(48, 32)
	const WARN := 0.9
	const DOWN := 0.5
	const DMG := 12.0
	const SPOTS := [Vector2(-96, -34), Vector2(96, -34), Vector2(-96, 36), Vector2(96, 36), Vector2(-232, 0), Vector2(232, 0)]

	var center := Vector2.ZERO
	var spots: Array = SPOTS         ## le stanze «Camera del torchio» usano GRID (blocco 2×3)
	const GRID := [Vector2(-56, -20), Vector2(0, -20), Vector2(56, -20), Vector2(-56, 20), Vector2(0, 20), Vector2(56, 20)]
	var every := 3.0                 ## secondi tra una piastra e l'altra (Shezmu infuriato: meno)
	var paused := false
	var wait := 5.0                  ## la prima dopo 5 s: mai appena entri
	var active := -1
	var last := -1
	var st := 0.0
	var phase := ""                  ## "warn" → "down"
	var hit := false
	var t := 0.0

	func _ready() -> void:
		Hazards.ground.call_deferred(self)

	func _rect(i: int) -> Rect2:
		var s: Vector2 = spots[i]
		return Rect2(center + s - SIZE / 2.0, SIZE)

	func _process(delta: float) -> void:
		t += delta
		var p = get_tree().get_first_node_in_group("player")
		var gm = get_tree().current_scene
		if phase == "":
			if paused or (gm != null and gm.get("cleared") == true):
				queue_redraw()
				return
			wait -= delta
			if wait <= 0.0 and p != null and not p.dead:
				# di solito quella più vicina a te (così conta dove stai), a volte una a caso; mai l'ultima
				var order := range(spots.size())
				order.erase(last)
				order.sort_custom(func(a, b) -> bool: return _rect(a).get_center().distance_to(p.global_position) < _rect(b).get_center().distance_to(p.global_position))
				active = order[0] if randf() < 0.65 else order.pick_random()
				last = active
				phase = "warn"
				st = WARN
				hit = false
				Sfx.play_at("scorpion_windup", _rect(active).get_center(), 0.3)
		elif phase == "warn":
			st -= delta
			if st <= 0.0:
				phase = "down"
				st = DOWN
				Sfx.play_at("amheh_land", _rect(active).get_center(), 0.2)
				Fx.shake(4.0)
				if p != null and not p.dead and _rect(active).has_point(p.global_position):
					hit = p.take_damage(DMG, _rect(active).get_center(), null, "piastra")
		elif phase == "down":
			st -= delta
			if st <= 0.0:
				phase = ""
				active = -1
				wait = every
		queue_redraw()

	func peril(pos: Vector2) -> bool:
		for i in range(spots.size()):
			if _rect(i).grow(10.0).has_point(pos):
				return true
		return false

	## Per il bot e per chi vuole sapere se un punto sta per essere schiacciato.
	func danger(pos: Vector2) -> Vector2:
		if active < 0 or phase != "warn" or not _rect(active).grow(8.0).has_point(pos):
			return Vector2.ZERO
		var v := pos - _rect(active).get_center()
		return v.normalized() if v != Vector2.ZERO else Vector2.RIGHT

	func _draw() -> void:
		for i in range(spots.size()):
			var r := _rect(i)
			var lr := Rect2(r.position - global_position, r.size)
			var sunk := 0.0
			if i == active and phase == "down":
				sunk = 3.0
			draw_rect(lr.grow(1.5), Color(0.05, 0.03, 0.05))
			draw_rect(Rect2(lr.position + Vector2(0, sunk), lr.size), Color(0.36, 0.3, 0.32) if sunk == 0.0 else Color(0.24, 0.2, 0.22))
			draw_rect(Rect2(lr.position + Vector2(0, sunk), Vector2(lr.size.x, 3.0)), Color(0.5, 0.44, 0.44, 0.8 if sunk == 0.0 else 0.2))
			# il segno del torchio inciso: due tacche
			var c := lr.get_center() + Vector2(0, sunk)
			draw_line(c + Vector2(-8, -5), c + Vector2(-8, 5), Color(0.2, 0.15, 0.17), 1.4)
			draw_line(c + Vector2(8, -5), c + Vector2(8, 5), Color(0.2, 0.15, 0.17), 1.4)
			if i == active and phase == "warn":
				var k := 1.0 - st / WARN
				draw_rect(lr, Color(Enemy.WARN, 0.14))
				draw_rect(Rect2(lr.position, Vector2(lr.size.x, lr.size.y * k)), Color(Enemy.WARN, 0.2 + 0.18 * k))
				draw_rect(lr, Color(Enemy.WARN, 0.6 + 0.35 * k), false, 1.6)
			elif i == active and phase == "down":
				draw_rect(lr, Color(0, 0, 0, 0.3))
