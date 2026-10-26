class_name Arenas
extends RefCounted
## Le arene dei guardiani e dei boss: luoghi disegnati apposta, diversi da ogni altra stanza.
## Entrando si deve capire "questo è un altro posto" prima ancora di vedere il nemico.
##
## - "gate", la Porta (il Serpente): nel Libro delle Porte ogni porta tra un'ora e l'altra sta
##   sul fiume della notte ed è custodita da un serpente. In fondo il pilone gigante che esce
##   dall'acqua, con i battenti a serpente e il disco alato; davanti, il cortile allagato dalle
##   acque di Wernes: il Serpente si immerge e ti insegue sott'acqua. La grata d'ingresso cade
##   alle tue spalle. (Niente sabbia: la sabbia è del deserto di Sokar, la seconda tappa.)
## - "lake", il Lago di Fuoco (Am-heh, Libro dei Morti cap. 126): un'isola di basalto con le
##   crepe roventi, il lago che arde su tre lati, i quattro babbuini di pietra che lo custodiscono
##   e davanti a ognuno la sua pozza: l'acqua che il lago dà al giusto. Braci nell'aria.
##
## Il disegno fermo (pavimento, pareti, lago) finisce nella texture cotta della stanza
## (room_decor.gd, `under`); qui ci sono anche i pezzi che si muovono o fanno ostacolo.

const LAKE_W := 30.0                       ## quanto è largo il lago di fuoco lungo i bordi
const DEEP_RADII := Vector2(170, 92)       ## l'acqua alta al centro della Porta (rallenta, il Serpente ci si tuffa)


## Il centro dell'acqua alta della Porta.
static func deep_center(room: Rect2, top: float, wall: float) -> Vector2:
	return Vector2(room.size.x / 2.0, (top + room.size.y - wall) / 2.0 + 6.0)
## Le pozze di Am-heh, ognuna davanti al suo babbuino (frazioni del pavimento, raggi).
const LAKE_POOLS := [[Vector2(0.2, 0.33), Vector2(50, 28)], [Vector2(0.8, 0.33), Vector2(50, 28)], [Vector2(0.24, 0.8), Vector2(46, 26)], [Vector2(0.76, 0.8), Vector2(46, 26)]]


## L'isola di Am-heh: il pavimento meno il lago di fuoco su tre lati (in basso c'è la riva).
static func island(room: Rect2, top: float, wall: float) -> Rect2:
	return Rect2(wall + LAKE_W, top + LAKE_W, room.size.x - (wall + LAKE_W) * 2.0, room.size.y - wall - top - LAKE_W)


## Rettangoli solidi dell'arena (il lago, le statue).
static func solids(kind: String, room: Rect2, top: float, wall: float, pools: Array) -> Array:
	var out := []
	if kind == "lake":
		out.append(Rect2(wall, top, LAKE_W, room.size.y - wall - top))
		out.append(Rect2(room.size.x - wall - LAKE_W, top, LAKE_W, room.size.y - wall - top))
		out.append(Rect2(wall, top, room.size.x - wall * 2.0, LAKE_W))
		for b in baboons(pools):
			out.append(Rect2(b - Vector2(11, 6), Vector2(22, 10)))
	return out


## Dove stanno i babbuini: dietro ogni pozza, verso l'angolo.
static func baboons(pools: Array) -> Array:
	var out := []
	for p in pools:
		var c: Vector2 = p
		out.append(c + Vector2(-58.0 if c.x < 400.0 else 58.0, -18.0))
	return out


# ---------------------------------------------------------------- la Porta (il Serpente)

static func paint_gate(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var cx := r.size.x / 2.0
	var mid := Vector2(cx, (top + r.size.y - wall) / 2.0 + 6.0)
	var floor_r := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	# lastre grandi di pietra grigia, consumate
	ci.draw_rect(floor_r, Color(0.16, 0.13, 0.11))
	var y := top
	var row := 0
	while y < floor_r.end.y:
		var x := wall - (24.0 if row % 2 == 1 else 0.0)
		while x < floor_r.end.x:
			var x0 := maxf(x, wall)
			var x1 := minf(x + 48.0, floor_r.end.x)
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			var c := Color(0.4, 0.35, 0.3).darkened(n * 0.18)
			ci.draw_rect(Rect2(x0 + 1, y + 1, x1 - x0 - 2, 30), c)
			ci.draw_rect(Rect2(x0 + 1, y + 1, x1 - x0 - 2, 1.5), c.lightened(0.12))
			x += 48.0
		y += 32.0
		row += 1
	# le acque di Wernes allagano il cortile: le lastre si vedono sotto, verdi e blu; al centro
	# l'acqua è più profonda, ed è lì che il Serpente si immerge
	ci.draw_rect(floor_r, Color(0.14, 0.42, 0.52, 0.45))
	var rad := DEEP_RADII
	ci.draw_set_transform(mid, 0.0, Vector2(1.0, rad.y / rad.x))
	# l'acqua alta: più scura, con il bordo dove il fondo scende di colpo
	ci.draw_circle(Vector2.ZERO, rad.x + 6.0, Color(0.1, 0.32, 0.42, 0.5))
	ci.draw_circle(Vector2.ZERO, rad.x, Color(0.03, 0.13, 0.22, 0.8))
	ci.draw_circle(Vector2.ZERO, rad.x * 0.6, Color(0.01, 0.07, 0.13, 0.6))
	ci.draw_arc(Vector2.ZERO, rad.x, 0.0, TAU, 64, Color(0.6, 0.85, 0.95, 0.35), 2.0)
	for k in range(1, 4):
		ci.draw_arc(Vector2.ZERO, rad.x * k / 3.5, 0.0, TAU, 64, Color(0.55, 0.8, 0.95, 0.1), 1.2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	# riflessi chiari sull'acqua
	for i in range(60):
		var p := Vector2(rng.randf_range(floor_r.position.x + 8, floor_r.end.x - 8), rng.randf_range(floor_r.position.y + 8, floor_r.end.y - 8))
		ci.draw_line(p, p + Vector2(rng.randf_range(6, 14), 0), Color(0.7, 0.9, 1.0, 0.18), 1.0)
	# foglie di loto e qualche fiore, lontano dal centro
	for i in range(16):
		var p := Vector2(rng.randf_range(floor_r.position.x + 20, floor_r.end.x - 20), rng.randf_range(floor_r.position.y + 20, floor_r.end.y - 20))
		if ((p - mid) / rad).length() < 1.25:
			continue
		var lr := rng.randf_range(5.0, 8.0)
		var gap_a := rng.randf() * TAU
		ci.draw_colored_polygon(_pad(p, lr, gap_a), Color(0.13, 0.3, 0.26))      # scure: non si confondono col veleno
		ci.draw_line(p, p + Vector2.from_angle(gap_a) * lr, Color(0.07, 0.18, 0.14), 1.0)
		if rng.randf() < 0.6:
			ci.draw_circle(p + Vector2(1, -2), 2.5, Color(0.95, 0.75, 0.85))
			ci.draw_circle(p + Vector2(1, -2), 1.0, Color(1.0, 0.85, 0.4))
	# canne di papiro lungo i muri
	for i in range(30):
		var bx := rng.randf_range(floor_r.position.x + 4, floor_r.end.x - 4)
		var by := floor_r.end.y - rng.randf_range(2, 8) if i % 2 == 0 else floor_r.position.y + rng.randf_range(4, 10)
		if absf(bx - cx) < 70.0:
			continue
		ci.draw_line(Vector2(bx, by), Vector2(bx + rng.randf_range(-2, 2), by - 12), Color(0.3, 0.5, 0.22), 1.0)
		ci.draw_circle(Vector2(bx, by - 13), 2.0, Color(0.5, 0.66, 0.3))
	# le pareti: grandi blocchi scuri, con il fregio del serpente che corre lungo i lati
	var dark := Color(0.12, 0.1, 0.09)
	ci.draw_rect(Rect2(0, 0, r.size.x, top), dark)
	ci.draw_rect(Rect2(0, r.size.y - wall, r.size.x, wall), dark)
	ci.draw_rect(Rect2(0, 0, wall, r.size.y), dark)
	ci.draw_rect(Rect2(r.size.x - wall, 0, wall, r.size.y), dark)
	for side in [wall * 0.5, r.size.x - wall * 0.5]:
		var pts := PackedVector2Array()
		var yy := top
		while yy < r.size.y - wall:
			pts.append(Vector2(side + sin(yy * 0.08) * 7.0, yy))
			yy += 4.0
		ci.draw_polyline(pts, Color(0.12, 0.3, 0.14), 6.0)
		ci.draw_polyline(pts, Color(0.3, 0.62, 0.3), 3.0)
		ci.draw_polyline(pts, Color(0.94, 0.72, 0.3, 0.6), 1.0)
	# il pilone: due torri a scarpa ai lati della porta, con la cornice e le insegne
	for sx in [-1.0, 1.0]:
		var inner: float = cx + sx * 56.0
		var outer: float = cx + sx * 250.0
		var tower := PackedVector2Array([Vector2(inner, top + 2), Vector2(outer, top + 2), Vector2(outer - sx * 16.0, 0), Vector2(inner, 0)])
		# la luce viene da sinistra: la torre di sinistra è più chiara, la faccia esterna in ombra
		var lit_c := Color(0.6, 0.5, 0.37) if sx < 0 else Color(0.46, 0.38, 0.28)
		var dark_c := lit_c.darkened(0.35)
		ci.draw_polygon(tower, PackedColorArray([lit_c, dark_c, dark_c, lit_c]))
		ci.draw_polyline(PackedVector2Array([tower[0], tower[1], tower[2], tower[3], tower[0]]), Color(0.2, 0.15, 0.1), 1.5)
		for k in range(4):
			var ly := 12.0 + k * 12.0
			ci.draw_line(Vector2(inner, ly), Vector2(outer - sx * (16.0 - ly / 4.0), ly), Color(0.5, 0.41, 0.3), 1.0)
		ci.draw_rect(Rect2(minf(inner, outer - sx * 16.0), 0, absf(outer - sx * 16.0 - inner), 5), Color(0.16, 0.3, 0.68))
		# il serpente inciso sulla torre, eretto
		var sc := Vector2(cx + sx * 150.0, top - 30.0)
		ci.draw_arc(sc + Vector2(0, 10), 8.0, PI, TAU, 10, Color(0.3, 0.62, 0.3), 3.0)
		ci.draw_line(sc + Vector2(8, 10), sc + Vector2(8, 20), Color(0.3, 0.62, 0.3), 3.0)
		ci.draw_circle(sc + Vector2(-8, 9), 4.0, Color(0.3, 0.62, 0.3))
		ci.draw_circle(sc + Vector2(-9, 8), 1.0, Color(0.94, 0.72, 0.3))
	# due obelischi ai lati del pilone, con la punta d'oro
	for ox in [cx - 300.0, cx + 300.0]:
		var ob := PackedVector2Array([Vector2(ox - 8, top + 2), Vector2(ox + 8, top + 2), Vector2(ox + 5, 6), Vector2(ox, 0), Vector2(ox - 5, 6)])
		ci.draw_polygon(ob, PackedColorArray([Color(0.62, 0.5, 0.42), Color(0.4, 0.32, 0.27), Color(0.4, 0.32, 0.27), Color(0.94, 0.72, 0.3), Color(0.62, 0.5, 0.42)]))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ox - 5, 6), Vector2(ox, 0), Vector2(ox + 5, 6)]), Color(0.94, 0.72, 0.3))
		for k in range(4):
			ci.draw_rect(Rect2(ox - 2, 14 + k * 11, 4, 6), Color(0.25, 0.18, 0.12, 0.7))
	# la porta chiusa: due battenti di legno scuro con le borchie e il serpente che li attraversa
	var door := Rect2(cx - 52, 2, 104, top - 2)
	ci.draw_rect(door.grow(3), Color(0.94, 0.72, 0.3))
	ci.draw_rect(door, Color(0.24, 0.14, 0.08))
	ci.draw_line(Vector2(cx, 2), Vector2(cx, top), Color(0.1, 0.06, 0.03), 2.0)
	for k in range(5):
		for sx2 in [-1.0, 1.0]:
			ci.draw_circle(Vector2(cx + sx2 * 40.0, 10.0 + k * 11.0), 1.6, Color(0.8, 0.6, 0.3))
	var coil := PackedVector2Array()
	for i in range(30):
		var u := i / 29.0
		coil.append(Vector2(cx - 44.0 + u * 88.0, top * 0.55 + sin(u * TAU * 1.5) * 9.0))
	ci.draw_polyline(coil, Color(0.3, 0.62, 0.3), 3.0)
	# il disco alato sopra la porta
	var dc := Vector2(cx, 8)
	for sx3 in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([dc + Vector2(sx3 * 6, -3), dc + Vector2(sx3 * 46, -4), dc + Vector2(sx3 * 40, 4), dc + Vector2(sx3 * 6, 4)]), Color(0.16, 0.3, 0.68))
	ci.draw_circle(dc, 6.0, Color(0.86, 0.28, 0.12))


# ---------------------------------------------------------------- il tempio di Serket

const DAIS_RADII := Vector2(118, 62)       ## il piano di pietra al centro del tempio (Serket non ci scava)
## I cumuli di sabbia da cui escono gli scorpioni (frazioni del pavimento): lontani dalle colonne
## e dalle porte, intorno al piano di pietra.
const MOUNDS := [Vector2(0.1, 0.2), Vector2(0.9, 0.2), Vector2(0.07, 0.56), Vector2(0.93, 0.56), Vector2(0.25, 0.93), Vector2(0.75, 0.93)]


static func temple_mounds(room: Rect2, top: float, wall: float) -> Array:
	var out := []
	for m in MOUNDS:
		var f: Vector2 = m
		out.append(Vector2(lerpf(wall, room.size.x - wall, f.x), lerpf(top, room.size.y - wall, f.y)))
	return out


## Il tempio di Serket, semisepolto dal deserto di Sokar: pavimento di sabbia con le onde del
## vento, al centro il piano di pietra con lo scorpione inciso (lì la dea non può scavare),
## i cumuli da cui escono i suoi scorpioni. In fondo la facciata del santuario: la porta chiusa
## sotto il disco alato e le due statue della dea seduta, con lo scorpione sul capo. Lungo le
## pareti il fregio degli scorpioni, turchese e oro.
static func paint_temple(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var cx := r.size.x / 2.0
	var mid := deep_center(r, top, wall)
	var floor_r := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	var sand := Color(0.68, 0.53, 0.32)
	ci.draw_rect(floor_r, sand)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	# le onde lasciate dal vento sulla sabbia
	var yy := top + 10.0
	while yy < floor_r.end.y - 4.0:
		var pts := PackedVector2Array()
		var x := wall
		var ph := rng.randf() * TAU
		while x <= floor_r.end.x:
			pts.append(Vector2(x, yy + sin(x * 0.045 + ph) * 3.0))
			x += 8.0
		ci.draw_polyline(pts, Color(0.56, 0.42, 0.24, 0.5), 1.2)
		var hi := pts.duplicate()
		for i in range(hi.size()):
			hi[i] = hi[i] + Vector2(0, -1.5)
		ci.draw_polyline(hi, Color(0.84, 0.7, 0.47, 0.35), 1.0)
		yy += rng.randf_range(14.0, 22.0)
	# sassi e frammenti di pietra
	for i in range(50):
		var p := Vector2(rng.randf_range(floor_r.position.x + 6, floor_r.end.x - 6), rng.randf_range(floor_r.position.y + 6, floor_r.end.y - 6))
		ci.draw_circle(p, rng.randf_range(0.8, 2.0), Color(0.45, 0.34, 0.22, 0.7))
	# il piano di pietra: lastre a raggiera intorno allo scorpione inciso
	var rad := DAIS_RADII
	ci.draw_set_transform(mid, 0.0, Vector2(1.0, rad.y / rad.x))
	ci.draw_circle(Vector2(4, 8), rad.x + 4.0, Color(0, 0, 0, 0.25))
	ci.draw_circle(Vector2.ZERO, rad.x + 4.0, Color(0.3, 0.24, 0.17))
	ci.draw_circle(Vector2.ZERO, rad.x, Color(0.62, 0.55, 0.45))
	ci.draw_circle(Vector2(-6, -6), rad.x * 0.92, Color(0.68, 0.61, 0.5))
	for k in range(1, 3):
		ci.draw_arc(Vector2.ZERO, rad.x * k / 3.0, 0.0, TAU, 48, Color(0.38, 0.32, 0.25), 1.6)
	for i in range(16):
		var a := TAU * i / 16.0
		ci.draw_line(Vector2.from_angle(a) * rad.x / 3.0, Vector2.from_angle(a) * rad.x, Color(0.38, 0.32, 0.25), 1.4)
	ci.draw_arc(Vector2.ZERO, rad.x - 6.0, 0.0, TAU, 64, Color(0.22, 0.7, 0.68, 0.7), 2.5)
	ci.draw_arc(Vector2.ZERO, rad.x - 10.0, 0.0, TAU, 64, Color(0.94, 0.72, 0.3, 0.6), 1.2)
	# lo scorpione inciso al centro, d'oro
	var gold := Color(0.85, 0.64, 0.26)
	ci.draw_set_transform(mid, 0.0, Vector2(1.0, 0.75))
	ci.draw_colored_polygon(_oval(Vector2(0, 0), 14.0, 8.0), gold)
	for sx in [-1.0, 1.0]:
		for k in range(3):
			var ly: float = -4.0 + k * 4.0
			ci.draw_line(Vector2(sx * 10.0, ly), Vector2(sx * 20.0, ly + sx * 0.0 + 4.0), gold, 2.0)
		ci.draw_line(Vector2(sx * 6.0, -6.0), Vector2(sx * 12.0, -18.0), gold, 2.5)
		ci.draw_arc(Vector2(sx * 14.0, -21.0), 4.0, 0.0, TAU, 10, gold, 2.0)
	var tail := PackedVector2Array()
	for k in range(9):
		var u := k / 8.0
		tail.append(Vector2(sin(u * PI) * 10.0 * (1.0 - u * 0.4), 8.0 + u * 26.0))
	ci.draw_polyline(tail, gold, 3.0)
	ci.draw_circle(tail[tail.size() - 1], 3.5, Color(0.22, 0.7, 0.68))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# la sabbia che invade il bordo del piano
	for i in range(10):
		var a := rng.randf() * TAU
		var p := mid + Vector2(cos(a) * rad.x, sin(a) * rad.y)
		ci.draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
		ci.draw_circle(Vector2.ZERO, rng.randf_range(10.0, 20.0), Color(sand, 0.85))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# i cumuli: sabbia ammucchiata, con il buco scuro da cui escono gli scorpioni
	for m in temple_mounds(r, top, wall):
		var mp: Vector2 = m
		ci.draw_set_transform(mp, 0.0, Vector2(1.0, 0.5))
		ci.draw_circle(Vector2(3, 6), 22.0, Color(0, 0, 0, 0.18))
		ci.draw_circle(Vector2.ZERO, 22.0, Color(0.55, 0.42, 0.25))
		ci.draw_circle(Vector2(-4, -5), 16.0, Color(0.76, 0.61, 0.38))
		ci.draw_circle(Vector2(-6, -8), 8.0, Color(0.86, 0.72, 0.48))
		ci.draw_circle(Vector2(2, 2), 4.5, Color(0.18, 0.12, 0.08))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# le pareti di arenaria scura, con il fregio degli scorpioni
	var dark := Color(0.2, 0.15, 0.11)
	ci.draw_rect(Rect2(0, 0, r.size.x, top), dark)
	ci.draw_rect(Rect2(0, r.size.y - wall, r.size.x, wall), dark)
	ci.draw_rect(Rect2(0, 0, wall, r.size.y), dark)
	ci.draw_rect(Rect2(r.size.x - wall, 0, wall, r.size.y), dark)
	for side in [wall * 0.5, r.size.x - wall * 0.5]:
		var sx2: float = side
		ci.draw_line(Vector2(sx2 - 9.0, top), Vector2(sx2 - 9.0, r.size.y - wall), Color(0.22, 0.7, 0.68, 0.7), 2.0)
		ci.draw_line(Vector2(sx2 + 9.0, top), Vector2(sx2 + 9.0, r.size.y - wall), Color(0.22, 0.7, 0.68, 0.7), 2.0)
		var y2 := top + 24.0
		while y2 < r.size.y - wall - 12.0:
			_glyph_scorpion(ci, Vector2(sx2, y2), 0.55, gold)
			y2 += 40.0
	# sabbia accumulata contro le pareti
	for i in range(28):
		var bx := rng.randf_range(floor_r.position.x, floor_r.end.x)
		var on_top := i % 2 == 0
		if absf(bx - cx) < 60.0:
			continue
		var p := Vector2(bx, floor_r.position.y + 2.0 if on_top else floor_r.end.y - 2.0)
		ci.draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
		ci.draw_circle(Vector2.ZERO, rng.randf_range(14.0, 28.0), Color(0.76, 0.61, 0.38, 0.9))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# la facciata del santuario: blocchi chiari, la cornice a gola, la porta chiusa
	var face := Rect2(cx - 230.0, 0, 460.0, top + 2.0)
	ci.draw_rect(face, Color(0.56, 0.45, 0.32))
	for k in range(4):
		ci.draw_line(Vector2(face.position.x, 14.0 + k * 13.0), Vector2(face.end.x, 14.0 + k * 13.0), Color(0.44, 0.34, 0.24), 1.0)
	ci.draw_rect(Rect2(face.position.x, 0, face.size.x, 6), Color(0.16, 0.3, 0.68))
	ci.draw_rect(Rect2(face.position.x, 6, face.size.x, 2), Color(0.94, 0.72, 0.3))
	var door := Rect2(cx - 34.0, 14.0, 68.0, top - 12.0)
	ci.draw_rect(door.grow(3.0), Color(0.94, 0.72, 0.3))
	ci.draw_rect(door, Color(0.1, 0.07, 0.05))
	# lo scorpione sopra la porta e il disco alato
	_glyph_scorpion(ci, Vector2(cx, 34.0), 0.8, Color(0.22, 0.7, 0.68))
	var dc := Vector2(cx, 10.0)
	for sx3 in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([dc + Vector2(sx3 * 6, -3), dc + Vector2(sx3 * 40, -4), dc + Vector2(sx3 * 34, 3), dc + Vector2(sx3 * 6, 3)]), Color(0.16, 0.3, 0.68))
	ci.draw_circle(dc, 5.0, Color(0.86, 0.28, 0.12))
	# le due statue della dea seduta, ai lati della porta
	for sx4 in [-1.0, 1.0]:
		_statue_serket(ci, Vector2(cx + sx4 * 130.0, top + 2.0), sx4)


## Un piccolo scorpione stilizzato, come nei geroglifici (il segno di Serket).
static func _glyph_scorpion(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_colored_polygon(_oval(c, 7.0 * s, 4.0 * s), col)
	ci.draw_line(c + Vector2(-6, 0) * s, c + Vector2(-13, -7) * s, col, 2.0 * s)
	ci.draw_arc(c + Vector2(-11, -12) * s, 4.0 * s, PI * 0.2, PI * 1.5, 8, col, 2.0 * s)
	for k in range(3):
		ci.draw_line(c + Vector2(-2 + k * 3, 3) * s, c + Vector2(-4 + k * 3, 8) * s, col, 1.4 * s)
	ci.draw_line(c + Vector2(6, -1) * s, c + Vector2(11, -5) * s, col, 1.6 * s)
	ci.draw_line(c + Vector2(6, 1) * s, c + Vector2(11, 4) * s, col, 1.6 * s)


## Serket seduta sul trono, di profilo, rivolta verso la porta: la parrucca nera, la veste
## bianca, lo scorpione sul capo.
static func _statue_serket(ci: CanvasItem, base: Vector2, side: float) -> void:
	var f := -side            # guarda verso il centro
	var stone := Color(0.72, 0.6, 0.44)
	var stone_d := Color(0.44, 0.34, 0.24)
	var o := Color(0.12, 0.08, 0.05)
	# il trono
	ci.draw_rect(Rect2(base.x - 14.0, base.y - 26.0, 28.0, 26.0), o)
	ci.draw_rect(Rect2(base.x - 13.0, base.y - 25.0, 26.0, 24.0), stone_d)
	ci.draw_rect(Rect2(base.x - 13.0, base.y - 10.0, 26.0, 3.0), Color(0.22, 0.7, 0.68))
	# il corpo seduto: le gambe in avanti, il busto eretto
	var body := PackedVector2Array([
		base + Vector2(-6 * f, -26), base + Vector2(6 * f, -26), base + Vector2(8 * f, -14),
		base + Vector2(18 * f, -14), base + Vector2(18 * f, -1), base + Vector2(12 * f, -1),
		base + Vector2(12 * f, -8), base + Vector2(-6 * f, -8)])
	ci.draw_colored_polygon(body, Color(0.9, 0.86, 0.76))
	var cl := body.duplicate()
	cl.append(body[0])
	ci.draw_polyline(cl, o, 1.0)
	# la testa con la parrucca
	var h := base + Vector2(1 * f, -33)
	ci.draw_circle(h, 7.5, o)
	ci.draw_circle(h, 6.5, Color(0.08, 0.07, 0.1))
	ci.draw_circle(h + Vector2(3 * f, 0.5), 3.5, stone)
	ci.draw_line(h + Vector2(-6, -3), h + Vector2(6, -3), Color(0.94, 0.72, 0.3), 1.2)
	# lo scorpione sul capo
	_glyph_scorpion(ci, h + Vector2(0, -11), 0.45, Color(0.94, 0.72, 0.3))


static func _oval(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU * i / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## La sabbia che cola dalle crepe del soffitto del tempio, a fili sottili.
class TempleDust extends Node2D:
	var room := Rect2()
	var top := 64.0
	var wall := 32.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in range(7):
			var x := lerpf(wall + 30.0, room.size.x - wall - 30.0, fmod(i * 0.413 + 0.07, 1.0))
			var y1 := lerpf(top + 40.0, room.size.y - wall - 30.0, fmod(i * 0.29 + 0.3, 1.0))
			var on := sin(t * 0.7 + i * 1.9) > 0.2
			if not on:
				continue
			for k in range(10):
				var f := fmod(t * 1.6 + k * 0.1, 1.0)
				var p := Vector2(x + sin(k * 3.1) * 0.8, lerpf(y1 - 120.0, y1, f))
				draw_circle(p, 0.9, Color(0.86, 0.72, 0.48, 0.55 * (1.0 - f * 0.5)))
			draw_set_transform(Vector2(x, y1), 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 5.0, Color(0.82, 0.68, 0.44, 0.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Una foglia di loto: un disco con la tacca.
static func _pad(c: Vector2, r: float, gap_a: float) -> PackedVector2Array:
	var pts := PackedVector2Array([c])
	for i in range(15):
		var a := gap_a + 0.35 + (TAU - 0.7) * i / 14.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6))
	return pts


## L'acqua del cortile della Porta che si muove: righe di luce che scorrono piano.
class GateShimmer extends Node2D:
	var room := Rect2()
	var top := 64.0
	var wall := 32.0
	var t := 0.0

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := room.size.x - wall * 2.0
		for i in range(14):
			var f := fmod(t * 0.05 + i * 0.137, 1.0)
			var y := lerpf(top + 6.0, room.size.y - wall - 6.0, fmod(i * 0.37, 1.0))
			var x := wall + f * w
			draw_line(Vector2(x, y), Vector2(minf(x + 18.0, room.size.x - wall), y), Color(0.5, 0.8, 1.0, 0.14 * sin(f * PI)), 1.5)


## La grata d'ingresso che cade alle tue spalle: non si torna indietro.
class GateBars extends Node2D:
	var t := 0.0
	var width := 96.0
	var dropped := false

	func _process(delta: float) -> void:
		t += delta
		if t > 0.7 and not dropped:
			dropped = true
			Sfx.play("jar_break", 0.0)
			Sfx.play("door", 0.0)
			Fx.shake(5.0)
			Fx.burst(global_position, Color(0.6, 0.55, 0.45), 18, 90.0)
		if t > 1.2:
			set_process(false)
		queue_redraw()

	func _draw() -> void:
		var k := clampf((t - 0.45) / 0.25, 0.0, 1.0)
		var h := 30.0 * k
		draw_rect(Rect2(-width / 2.0 - 4, -34, width + 8, 6), Color(0.3, 0.24, 0.18))
		for i in range(9):
			var x := -width / 2.0 + i * width / 8.0
			draw_rect(Rect2(x - 2, -30, 4, h), Color(0.22, 0.2, 0.2))
			draw_rect(Rect2(x - 1, -30, 1, h), Color(0.45, 0.42, 0.4))
		if k >= 1.0:
			draw_rect(Rect2(-width / 2.0, -6, width, 3), Color(0.22, 0.2, 0.2))


# ---------------------------------------------------------------- il Lago di Fuoco (Am-heh)

static func paint_lake(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var floor_r := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	var isl := island(r, top, wall)
	# pareti di roccia vulcanica, col bagliore rosso del lago sotto
	ci.draw_rect(Rect2(Vector2.ZERO, r.size), Color(0.1, 0.06, 0.06))
	# il lago di fuoco, su tre lati: dal giallo vicino alla riva al rosso cupo
	ci.draw_rect(floor_r, Color(0.5, 0.08, 0.03))
	for k in range(5):
		var g := isl.grow(LAKE_W * (1.0 - k / 5.0))
		ci.draw_rect(g, Color(1.0, 0.35 + 0.1 * k, 0.08, 0.25))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9126
	for i in range(70):
		var side := rng.randi() % 3
		var p := Vector2.ZERO
		if side == 0:
			p = Vector2(rng.randf_range(floor_r.position.x, isl.position.x), rng.randf_range(top, floor_r.end.y))
		elif side == 1:
			p = Vector2(rng.randf_range(isl.end.x, floor_r.end.x), rng.randf_range(top, floor_r.end.y))
		else:
			p = Vector2(rng.randf_range(wall, floor_r.end.x), rng.randf_range(top, isl.position.y))
		ci.draw_circle(p, rng.randf_range(2.0, 6.0), Color(0.25, 0.05, 0.03, 0.8))          # croste che galleggiano
		ci.draw_circle(p + Vector2(1, -1), rng.randf_range(0.8, 2.0), Color(1.0, 0.8, 0.3, 0.6))
	# l'isola di basalto: lastre nere con le crepe roventi
	ci.draw_rect(isl, Color(0.07, 0.05, 0.05))
	var y := isl.position.y
	var row := 0
	while y < isl.end.y:
		var x := isl.position.x - (20.0 if row % 2 == 1 else 0.0)
		while x < isl.end.x:
			var x0 := maxf(x, isl.position.x)
			var x1 := minf(x + 40.0, isl.end.x)
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			var c := Color(0.3, 0.25, 0.25).darkened(n * 0.25)
			ci.draw_rect(Rect2(x0 + 1, y + 1, x1 - x0 - 2, 26), c)
			ci.draw_rect(Rect2(x0 + 1, y + 1, x1 - x0 - 2, 1.2), c.lightened(0.1))
			x += 40.0
		y += 28.0
		row += 1
	for i in range(22):
		var p := Vector2(rng.randf_range(isl.position.x + 10, isl.end.x - 10), rng.randf_range(isl.position.y + 10, isl.end.y - 10))
		var pts := PackedVector2Array([p])
		for k in range(rng.randi_range(2, 5)):
			p += Vector2(rng.randf_range(-16, 16), rng.randf_range(-10, 10))
			pts.append(p)
		ci.draw_polyline(pts, Color(1.0, 0.35, 0.08, 0.35), 3.0)
		ci.draw_polyline(pts, Color(1.0, 0.7, 0.25, 0.9), 1.0)
	# la riva dell'isola: un bordo di pietra più chiaro, appena arrossato dal lago
	ci.draw_rect(Rect2(isl.position.x - 2, isl.position.y - 2, isl.size.x + 4, 3), Color(0.55, 0.25, 0.15))
	ci.draw_rect(Rect2(isl.position.x - 2, isl.position.y, 3, isl.size.y), Color(0.55, 0.25, 0.15))
	ci.draw_rect(Rect2(isl.end.x - 1, isl.position.y, 3, isl.size.y), Color(0.55, 0.25, 0.15))
	# la parete nord: il volto del Divoratore scolpito nella roccia, gli occhi accesi
	var cx := r.size.x / 2.0
	var face := Vector2(cx, top * 0.5)
	ci.draw_colored_polygon(PackedVector2Array([face + Vector2(-34, 30), face + Vector2(-26, -12), face + Vector2(-34, -30), face + Vector2(-14, -18), face + Vector2(14, -18), face + Vector2(34, -30), face + Vector2(26, -12), face + Vector2(34, 30)]), Color(0.18, 0.11, 0.1))
	ci.draw_colored_polygon(PackedVector2Array([face + Vector2(-16, 6), face + Vector2(16, 6), face + Vector2(8, 30), face + Vector2(-8, 30)]), Color(0.14, 0.08, 0.08))
	for sx in [-1.0, 1.0]:
		ci.draw_circle(face + Vector2(sx * 12.0, -4), 4.0, Color(1.0, 0.45, 0.1))
		ci.draw_circle(face + Vector2(sx * 12.0, -4), 1.8, Color(1.0, 0.9, 0.5))
	for k in range(6):
		ci.draw_line(Vector2(80 + k * 40, top - 4), Vector2(96 + k * 40, top - 20), Color(0.2, 0.12, 0.1), 2.0)
		ci.draw_line(Vector2(r.size.x - 80 - k * 40, top - 4), Vector2(r.size.x - 96 - k * 40, top - 20), Color(0.2, 0.12, 0.1), 2.0)


## Il lago che respira: bagliori che pulsano sulla lava e braci che salgono. Leggero: pochi
## rettangoli sommati e una manciata di particelle.
class LakeGlow extends Node2D:
	var room := Rect2()
	var top := 64.0
	var wall := 32.0
	var t := 0.0
	var surge := 0.0                       ## la marea di fuoco gonfia il lago (Am-heh la alza)

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		var embers := CPUParticles2D.new()
		embers.amount = 40
		embers.lifetime = 3.5
		embers.preprocess = 3.5
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		embers.emission_rect_extents = Vector2(room.size.x / 2.0 - wall, (room.size.y - top - wall) / 2.0)
		embers.position = Vector2(room.size.x / 2.0, (top + room.size.y - wall) / 2.0)
		embers.direction = Vector2(0, -1)
		embers.spread = 25.0
		embers.gravity = Vector2.ZERO
		embers.initial_velocity_min = 10.0
		embers.initial_velocity_max = 26.0
		embers.scale_amount_min = 1.0
		embers.scale_amount_max = 2.2
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(1.0, 0.75, 0.3, 0.0), Color(1.0, 0.6, 0.2, 0.9), Color(1.0, 0.3, 0.1, 0.0)])
		ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		embers.color_ramp = ramp
		embers.z_index = 3
		add_child(embers)

	func _process(delta: float) -> void:
		t += delta
		surge = maxf(0.0, surge - delta * 0.5)
		queue_redraw()

	func _draw() -> void:
		var isl := Arenas.island(room, top, wall)
		var floor_r := Rect2(wall, top, room.size.x - wall * 2.0, room.size.y - wall - top)
		var a := 0.12 + 0.06 * sin(t * 1.7) + 0.25 * surge
		var c := Color(1.0, 0.45, 0.12, a)
		draw_rect(Rect2(floor_r.position, Vector2(isl.position.x - floor_r.position.x, floor_r.size.y)), c)
		draw_rect(Rect2(Vector2(isl.end.x, floor_r.position.y), Vector2(floor_r.end.x - isl.end.x, floor_r.size.y)), c)
		draw_rect(Rect2(Vector2(isl.position.x, floor_r.position.y), Vector2(isl.size.x, isl.position.y - floor_r.position.y)), c)
		# onde lente di luce che corrono sul lago
		for i in range(6):
			var f := fmod(t * 0.12 + i / 6.0, 1.0)
			var y := lerpf(floor_r.position.y, floor_r.end.y, f)
			draw_rect(Rect2(floor_r.position.x, y, isl.position.x - floor_r.position.x, 3), Color(1.0, 0.8, 0.3, 0.18))
			draw_rect(Rect2(isl.end.x, floor_r.end.y - (y - floor_r.position.y), floor_r.end.x - isl.end.x, 3), Color(1.0, 0.8, 0.3, 0.18))


## Un babbuino di pietra, seduto, con le braccia alzate in adorazione e il disco lunare sul capo:
## i quattro custodi del lago (cap. 126). La pozza davanti è l'acqua che concede al giusto.
class Baboon extends Node2D:
	var player: Node2D
	var pool: Node2D                       ## la sua vasca: ci versa l'acqua finché non è prosciugata
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if player == null or not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player")
		if player != null and is_instance_valid(player):
			z_index = 1 if player.global_position.y < global_position.y else 0

	func _draw() -> void:
		var stone := Color(0.42, 0.36, 0.34)
		var shade := Color(0.28, 0.23, 0.22)
		var outl := Color(0.08, 0.05, 0.05)
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# il piedistallo
		draw_rect(Rect2(-12.6, -8.6, 25.2, 11.2), outl)
		draw_rect(Rect2(-12, -8, 24, 10), shade)
		draw_rect(Rect2(-12, -8, 24, 2), Color(0.94, 0.72, 0.3, 0.7))
		# il corpo seduto, la criniera a mantello
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -8), Vector2(9, -8), Vector2(8, -26), Vector2(0, -32), Vector2(-8, -26)]), outl)
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -9), Vector2(8, -9), Vector2(7, -25), Vector2(0, -31), Vector2(-7, -25)]), stone)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -25), Vector2(7, -25), Vector2(9, -16), Vector2(-9, -16)]), stone.lightened(0.08))
		# le braccia alzate
		for sx in [-1.0, 1.0]:
			draw_line(Vector2(sx * 7, -22), Vector2(sx * 13, -34), outl, 3.4)
			draw_line(Vector2(sx * 7, -22), Vector2(sx * 13, -34), stone, 2.2)
		# la testa col muso lungo
		draw_circle(Vector2(0, -34), 5.6, outl)
		draw_circle(Vector2(0, -34), 5.0, stone)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -33), Vector2(3, -33), Vector2(2, -27), Vector2(-2, -27)]), shade)
		draw_circle(Vector2(-2, -35), 0.9, Color(1.0, 0.5, 0.15))
		draw_circle(Vector2(2, -35), 0.9, Color(1.0, 0.5, 0.15))
		# l'acqua che versa dalle mani alzate nella sua vasca: l'acqua che il lago dà al giusto
		if pool != null and is_instance_valid(pool) and float(pool.get("dry")) < 0.4:
			var hand := Vector2(13.0 * signf(pool.global_position.x - global_position.x), -34.0)
			var to: Vector2 = pool.global_position - global_position + Vector2(0, -6)
			var pts := PackedVector2Array()
			for i in range(9):
				var u := i / 8.0
				pts.append(hand.lerp(to, u) + Vector2(0, -sin(u * PI) * 16.0))
			draw_polyline(pts, Color(0.5, 0.85, 1.0, 0.75), 2.0)
			for i in range(4):
				var u := fmod(t * 1.6 + i * 0.25, 1.0)
				draw_circle(hand.lerp(to, u) + Vector2(0, -sin(u * PI) * 16.0), 1.4, Color(0.9, 1.0, 1.0, 0.9))
		# il disco lunare sul capo, con la falce
		draw_circle(Vector2(0, -44), 4.5, Color(0.9, 0.88, 0.8))
		draw_arc(Vector2(0, -43), 6.0, PI * 0.15, PI * 0.85, 10, Color(0.94, 0.72, 0.3), 1.6)
