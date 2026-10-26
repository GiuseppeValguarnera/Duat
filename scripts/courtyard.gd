class_name Courtyard
extends Node2D
## Il Cortile di Neith, a cielo aperto: deve capirsi al primo sguardo che si è "fuori".
## - il pavimento è sabbia battuta, con i sentieri di lastre che portano da Neith, all'altare,
##   alla porta delle prove e al cancello della Sala;
## - un portico lungo il lato nord: le armi stanno lì sotto, all'ombra del tetto;
## - muri di mattoni crudi color fango, non le pareti dipinte delle tombe;
## - ombre nette del sole, in diagonale (il sole è in alto a sinistra);
## - palme, cespugli di papiro, un pozzo, l'arena di sabbia rastrellata per gli ushabti;
## - le chiome delle palme di fuori che sporgono oltre i muri, e ogni tanto l'ombra di un ibis.
##
## Il disegno di fondo è fermo: si fa una volta sola (nessun queue_redraw), costa zero dopo.
## Colonne, palme e tetto sono nodi a parte nel mondo, perché l'eroe ci passa davanti e dietro.

const SUN := Vector2(0.55, 0.32)            ## l'ombra di un oggetto alto h finisce a SUN * h
const SHADOW := Color(0.28, 0.14, 0.06, 0.26)
const SAND := Color(0.8, 0.66, 0.46)
const SLAB := Color(0.88, 0.82, 0.7)
const MUD := Color(0.6, 0.43, 0.3)
const STONE := Color(0.84, 0.76, 0.6)
const GOLD := Color(0.94, 0.72, 0.3)
const OUTL := Color(0.14, 0.09, 0.06)
const COLUMNS := [152.0, 245.0, 307.0, 431.0, 493.0, 586.0]
const COLUMN_Y := 132.0
const PALMS := [Vector2(62, 100), Vector2(66, 322), Vector2(268, 334)]
const WELL := Vector2(156, 318)
const RING := Vector2(436, 238)             ## l'arena degli ushabti
const RING_R := 70.0

var room := Rect2()
var top := 64.0
var wall := 32.0
var exit_y := Vector2(184, 236)              ## il varco del cancello a est
var shadows: Array = []                      ## [base, mezza larghezza, altezza] degli oggetti di armory.gd


## Mette nel mondo colonne, palme, tetto del portico, chiome di fuori e l'ibis; restituisce i
## rettangoli solidi (basi delle colonne, vasi delle palme, pozzo).
func build(world: Node2D, player: Node2D) -> Array:
	var solids: Array = []
	for x in COLUMNS:
		var c := CourtColumn.new()
		c.position = Vector2(x, COLUMN_Y)
		c.player = player
		world.add_child(c)
		solids.append(Rect2(c.position - Vector2(9, 5), Vector2(18, 8)))
	for p in PALMS:
		var palm := CourtPalm.new()
		palm.position = p
		palm.player = player
		world.add_child(palm)
		solids.append(Rect2(p - Vector2(11, 6), Vector2(22, 10)))
	solids.append(Rect2(WELL - Vector2(16, 8), Vector2(32, 14)))
	var roof := CourtRoof.new()
	roof.room = room
	roof.z_index = 3
	world.add_child(roof)
	var ibis := IbisShadow.new()
	ibis.room = room
	ibis.z_index = 4
	world.add_child(ibis)
	return solids


func _draw() -> void:
	var floor_r := Rect2(wall, top, room.size.x - wall * 2.0, room.size.y - wall - top)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4517
	# la sabbia battuta, con chiazze più chiare e più scure e qualche sassolino
	draw_rect(floor_r, SAND)
	var y := floor_r.position.y
	while y < floor_r.end.y:
		var x := floor_r.position.x
		while x < floor_r.end.x:
			var n := rng.randf()
			if n < 0.3:
				draw_rect(Rect2(x, y, 16, 16), Color(1, 0.95, 0.85, 0.07))
			elif n > 0.75:
				draw_rect(Rect2(x, y, 16, 16), Color(0.45, 0.3, 0.18, 0.07))
			x += 16.0
		y += 16.0
	for i in range(160):
		var p := Vector2(rng.randf_range(floor_r.position.x, floor_r.end.x), rng.randf_range(floor_r.position.y, floor_r.end.y))
		draw_circle(p, rng.randf_range(0.6, 1.4), Color(0.55, 0.42, 0.3, 0.6))
	# l'arena di sabbia rastrellata, bordata di pietre: qui si provano le armi sugli ushabti
	draw_set_transform(RING, 0.0, Vector2(1.0, 0.75))
	draw_circle(Vector2.ZERO, RING_R, SAND.lightened(0.08))
	for k in range(1, 6):
		draw_arc(Vector2.ZERO, RING_R * k / 6.0, 0, TAU, 48, Color(0.6, 0.47, 0.32, 0.35), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in range(36):
		var a := TAU * k / 36.0
		var sp := RING + Vector2(cos(a) * RING_R, sin(a) * RING_R * 0.75)
		draw_circle(sp + Vector2(1, 1), 3.2, Color(0.3, 0.2, 0.12, 0.35))
		draw_circle(sp, 3.0, STONE.darkened(rng.randf() * 0.15))
	# i sentieri di lastre: sotto il portico, da Neith al centro, dal centro alla porta delle prove,
	# dall'arena al cancello della Sala
	_slabs(Rect2(130, top, 476, 70), rng)
	_slabs(Rect2(124, 198, 194, 28), rng)
	_slabs(Rect2(314, 134, 36, room.size.y - wall - 134), rng)
	_slabs(Rect2(500, exit_y.x + 12, room.size.x - wall - 500, 28), rng)
	# ciuffi d'erba lungo i muri
	for i in range(40):
		var side := rng.randi() % 3
		var p: Vector2
		if side == 0:
			p = Vector2(wall + rng.randf_range(2, 10), rng.randf_range(top + 70, floor_r.end.y - 4))
		elif side == 1:
			p = Vector2(floor_r.end.x - rng.randf_range(2, 10), rng.randf_range(top + 70, floor_r.end.y - 4))
		else:
			p = Vector2(rng.randf_range(wall + 4, floor_r.end.x - 4), floor_r.end.y - rng.randf_range(2, 8))
		if p.y > exit_y.x - 4 and p.y < exit_y.y + 4 and side == 1:
			continue
		if absf(p.x - 330.0) < 34.0 and side == 2:
			continue
		_tuft(p, rng)
	# il pozzo
	_shadow(WELL + Vector2(0, 4), 16.0, 18.0)
	draw_set_transform(WELL, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 18.0, OUTL)
	draw_circle(Vector2.ZERO, 17.0, STONE.darkened(0.1))
	draw_circle(Vector2.ZERO, 11.0, Color(0.1, 0.18, 0.22))
	draw_circle(Vector2(-3, -2), 6.0, Color(0.25, 0.45, 0.55, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(WELL.x - 18, WELL.y, 36, 7), STONE.darkened(0.25))
	draw_rect(Rect2(WELL.x - 18, WELL.y + 7, 36, 1.2), OUTL)
	# le ombre del sole: muro ovest, palme, colonne (deboli, sotto il portico), e gli oggetti di armory.gd
	draw_colored_polygon(PackedVector2Array([Vector2(wall, top + 70), Vector2(wall + 14, top + 78), Vector2(wall + 14, floor_r.end.y), Vector2(wall, floor_r.end.y)]), SHADOW)
	for p in PALMS:
		_shadow(p + Vector2(0, 2), 9.0, 30.0)
		draw_set_transform(p + SUN * 90.0, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 26.0, Color(SHADOW, 0.14))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in shadows:
		_shadow(s[0], s[1], s[2])
	# l'ombra del tetto del portico, con il sole che entra tra una colonna e l'altra
	draw_rect(Rect2(130, top, 476, COLUMN_Y - top + 2), Color(0.2, 0.1, 0.12, 0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(130, COLUMN_Y + 2), Vector2(606, COLUMN_Y + 2), Vector2(606 + 10, COLUMN_Y + 8), Vector2(130 + 10, COLUMN_Y + 8)]), Color(0.2, 0.1, 0.12, 0.18))
	for x in COLUMNS:
		_shadow(Vector2(x, COLUMN_Y + 2), 9.0, 22.0)
	# il muro di fondo del portico: blocchi di calcare, il fregio khekher in alto
	draw_rect(Rect2(0, 0, room.size.x, top), STONE.darkened(0.08))
	var row := 0
	var by := 22.0
	while by < top:
		var off := 0.0 if row % 2 == 0 else 22.0
		draw_line(Vector2(0, by), Vector2(room.size.x, by), STONE.darkened(0.3), 1.0)
		var bx := off
		while bx < room.size.x:
			draw_line(Vector2(bx, by), Vector2(bx, minf(by + 14.0, top)), STONE.darkened(0.3), 1.0)
			bx += 44.0
		by += 14.0
		row += 1
	for k in range(int(room.size.x / 10.0)):
		var kx := k * 10.0
		var col: Color = [Color(0.72, 0.26, 0.15), Color(0.16, 0.3, 0.68), Color(0.26, 0.55, 0.32)][k % 3]
		draw_rect(Rect2(kx + 2, 6, 6, 12), col)
		draw_circle(Vector2(kx + 5, 6), 3.0, col)
	draw_rect(Rect2(0, 18, room.size.x, 2), GOLD)
	draw_rect(Rect2(0, top - 4, room.size.x, 4), STONE.darkened(0.35))
	# i muri di mattoni crudi (visti dall'alto): ovest, est e sud
	_mud(Rect2(0, top - 2, wall, room.size.y - top + 2), true)
	_mud(Rect2(room.size.x - wall, top - 2, wall, room.size.y - top + 2), true)
	_mud(Rect2(0, room.size.y - wall, room.size.x, wall), false)


## Lastre di calcare messe a correre, ognuna di un bianco un po' diverso.
func _slabs(r: Rect2, rng: RandomNumberGenerator) -> void:
	draw_rect(r, SLAB.darkened(0.25))
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var h := minf(14.0, r.end.y - y)
		var x := r.position.x - (9.0 if row % 2 == 1 else 0.0)
		while x < r.end.x:
			var x0 := maxf(x, r.position.x)
			var x1 := minf(x + 18.0, r.end.x)
			if x1 - x0 > 1.0:
				draw_rect(Rect2(x0 + 0.6, y + 0.6, x1 - x0 - 1.2, h - 1.2), SLAB.darkened(rng.randf() * 0.12))
				draw_rect(Rect2(x0 + 0.6, y + 0.6, x1 - x0 - 1.2, 1.0), Color(1, 1, 1, 0.18))
			x += 18.0
		y += 14.0
		row += 1


## Un ciuffo d'erba secca.
func _tuft(p: Vector2, rng: RandomNumberGenerator) -> void:
	var col := Color(0.42, 0.55, 0.24).lerp(Color(0.66, 0.6, 0.3), rng.randf())
	for k in range(4):
		var a := -PI / 2.0 + (k - 1.5) * 0.35 + rng.randf_range(-0.1, 0.1)
		draw_line(p, p + Vector2.from_angle(a) * rng.randf_range(4, 8), col, 1.0)


## Un muro di mattoni crudi visto dall'alto, con la copertina di malta sul bordo interno.
func _mud(r: Rect2, vertical: bool) -> void:
	draw_rect(r, MUD)
	var row := 0
	if vertical:
		var y := r.position.y
		while y < r.end.y:
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), MUD.darkened(0.25), 1.0)
			var x := r.position.x + (0.0 if row % 2 == 0 else 6.0)
			while x < r.end.x:
				draw_line(Vector2(x, y), Vector2(x, y + 7), MUD.darkened(0.25), 1.0)
				x += 12.0
			y += 7.0
			row += 1
	else:
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), MUD.darkened(0.25), 1.0)
			var y := r.position.y + (0.0 if row % 2 == 0 else 6.0)
			while y < r.end.y:
				draw_line(Vector2(x, y), Vector2(x + 7, y), MUD.darkened(0.25), 1.0)
				y += 12.0
			x += 7.0
			row += 1
	# la copertina chiara sul bordo verso il cortile, e l'ombra del muro
	if vertical:
		var inner := r.end.x - 4.0 if r.position.x < 1.0 else r.position.x
		draw_rect(Rect2(inner, r.position.y, 4, r.size.y), MUD.lightened(0.25))
	else:
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), MUD.lightened(0.25))


## L'ombra netta del sole: un parallelogramma che parte dalla base e va in basso a destra.
func _shadow(base: Vector2, half_w: float, h: float) -> void:
	var d := SUN * h
	draw_colored_polygon(PackedVector2Array([base + Vector2(-half_w, 0), base + Vector2(half_w, 0), base + Vector2(half_w, 0) + d, base + Vector2(-half_w, 0) + d]), SHADOW)


## Una foglia di palma lungo la sua nervatura: tratti sempre più larghi verso il centro (i poligoni
## piegati non si possono riempire, Godot non riesce a dividerli in triangoli).
static func _leaf(ci: CanvasItem, mid: PackedVector2Array, width: float, col: Color) -> void:
	var n := mid.size() - 1
	for s in range(n):
		var w := maxf(1.5, sin((s + 0.5) / n * PI) * width)
		ci.draw_line(mid[s], mid[s + 1], col, w)
	ci.draw_polyline(mid, col.lightened(0.35), 1.0)


## Una colonna del portico, papiriforme, in calcare chiaro al sole.
class CourtColumn extends Node2D:
	var player: Node2D

	func _process(_delta: float) -> void:
		if player != null and is_instance_valid(player):
			z_index = 1 if player.global_position.y < global_position.y else 0

	func _draw() -> void:
		var stone := Color(0.9, 0.82, 0.66)
		var shade := Color(0.7, 0.6, 0.44)
		var outl := Color(0.14, 0.09, 0.06)
		draw_rect(Rect2(-13.6, -4.6, 27.2, 7.2), outl)
		draw_rect(Rect2(-13, -4, 26, 6), shade)
		draw_rect(Rect2(-9.6, -86.6, 19.2, 83.2), outl)
		draw_rect(Rect2(-9, -86, 18, 82), stone)
		draw_rect(Rect2(3, -86, 6, 82), shade)          # il lato in ombra, a destra
		for k in range(3):
			draw_line(Vector2(-6 + k * 4, -84), Vector2(-6 + k * 4, -6), Color(shade, 0.7), 1.0)
		for b in [-74, -66]:
			draw_rect(Rect2(-10, b, 20, 3), Color(0.16, 0.3, 0.68))
			draw_rect(Rect2(-10, b + 3, 20, 1), Color(0.94, 0.72, 0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -84), Vector2(9, -84), Vector2(15, -94), Vector2(-15, -94)]), stone)
		for k in range(5):
			draw_line(Vector2(-12 + k * 6, -93), Vector2(-6 + k * 3, -85), Color(0.3, 0.55, 0.3), 1.0)


## Una palma da datteri in un vaso di pietra: tronco a scaglie, chioma di foglie lunghe.
class CourtPalm extends Node2D:
	var player: Node2D
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if player != null and is_instance_valid(player):
			z_index = 1 if player.global_position.y < global_position.y else 0
		if int(t * 10.0) % 3 == 0:
			queue_redraw()                         # le foglie si muovono appena, al vento

	func _draw() -> void:
		var outl := Color(0.14, 0.09, 0.06)
		# il vaso
		draw_rect(Rect2(-12.6, -10.6, 25.2, 15.2), outl)
		draw_rect(Rect2(-12, -10, 24, 14), Color(0.62, 0.38, 0.26))
		draw_rect(Rect2(-12, -10, 24, 3), Color(0.72, 0.48, 0.32))
		draw_rect(Rect2(-10, -5, 20, 1.5), Color(0.16, 0.3, 0.68))
		# il tronco, appena curvo, a scaglie
		var tip := Vector2(6, -84)
		var prev := Vector2(0, -10)
		for i in range(1, 11):
			var k := i / 10.0
			var p := Vector2(sin(k * 1.6) * 6.0, -10.0 - k * 74.0)
			draw_line(prev, p, outl, 7.0)
			draw_line(prev, p, Color(0.5, 0.36, 0.22), 5.0)
			draw_line(p + Vector2(-2.5, 0), p + Vector2(2.5, 1.5), Color(0.36, 0.25, 0.15), 1.0)
			prev = p
		# la chioma: foglie lunghe e piegate, con la nervatura chiara
		var sway := sin(t * 1.3) * 0.05
		for j in range(9):
			var a := -PI / 2.0 + (j - 4) * 0.42 + sway
			var droop := 0.6 + absf(j - 4) * 0.12
			var mid := PackedVector2Array()
			for s in range(7):
				var u := s / 6.0
				var dir := Vector2.from_angle(a + signf(cos(a)) * droop * u)
				mid.append(tip + dir * u * 40.0 + Vector2(0, u * u * 14.0))
			Courtyard._leaf(self, mid, 9.0, Color(0.2, 0.46, 0.22).lerp(Color(0.3, 0.58, 0.26), (j % 3) / 2.0))
		draw_circle(tip, 5.0, Color(0.42, 0.26, 0.14))
		for d in [Vector2(-3, 3), Vector2(3, 4), Vector2(0, 5)]:
			draw_circle(tip + d, 1.8, Color(0.66, 0.3, 0.12))   # i datteri


## Il tetto del portico (l'architrave sopra le colonne) e le chiome delle palme di fuori che
## sporgono oltre i muri: sta sopra a tutto, l'eroe non ci arriva mai.
class CourtRoof extends Node2D:
	var room := Rect2()
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if int(t * 10.0) % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		var stone := Color(0.86, 0.78, 0.62)
		var outl := Color(0.14, 0.09, 0.06)
		# l'architrave e la gola egizia sopra le colonne
		draw_rect(Rect2(129, 25, 480, 21), outl)
		draw_rect(Rect2(130, 34, 478, 11), stone)
		draw_rect(Rect2(130, 41, 478, 4), stone.darkened(0.2))
		draw_rect(Rect2(130, 26, 478, 8), stone.lightened(0.05))
		for k in range(40):
			var x := 132.0 + k * 12.0
			draw_rect(Rect2(x, 27, 6, 6), [Color(0.16, 0.3, 0.68), Color(0.26, 0.55, 0.32), Color(0.72, 0.26, 0.15)][k % 3])
		draw_rect(Rect2(130, 33, 478, 1.5), Color(0.94, 0.72, 0.3))
		# un disco solare alato al centro, sopra l'altare
		var c := Vector2(369, 36)
		for sx in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([c + Vector2(sx * 5, -4), c + Vector2(sx * 30, -6), c + Vector2(sx * 26, 2), c + Vector2(sx * 5, 4)]), Color(0.16, 0.3, 0.68))
			draw_line(c + Vector2(sx * 8, -1), c + Vector2(sx * 26, -2), Color(0.94, 0.72, 0.3), 1.0)
		draw_circle(c, 6.0, outl)
		draw_circle(c, 5.0, Color(0.86, 0.28, 0.12))
		# le chiome delle palme che crescono fuori dal cortile
		var sway := sin(t * 1.1) * 0.06
		for spec in [[Vector2(-6, 214), 0.0], [Vector2(-4, 340), 0.4], [Vector2(646, 290), PI], [Vector2(520, 392), -PI / 2.0], [Vector2(160, 394), -PI / 2.0]]:
			_crown(spec[0], spec[1] + sway)

	func _crown(c: Vector2, facing: float) -> void:
		for j in range(8):
			var a := facing + (j - 3.5) * 0.45
			var mid := PackedVector2Array()
			for s in range(6):
				var u := s / 5.0
				mid.append(c + Vector2.from_angle(a) * u * 44.0 + Vector2(0, u * u * 8.0))
			Courtyard._leaf(self, mid, 11.0, Color(0.18, 0.42, 0.2))


## L'ombra di un ibis che attraversa il cortile ogni tanto: il cielo c'è, anche se non si vede.
class IbisShadow extends Node2D:
	var room := Rect2()
	var t := 0.0
	var wait := 4.0
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var dur := 0.0

	func _process(delta: float) -> void:
		t += delta
		if dur <= 0.0:
			wait -= delta
			if wait <= 0.0:
				var y0 := randf_range(room.size.y * 0.15, room.size.y * 0.6)
				from = Vector2(-60, y0)
				to = Vector2(room.size.x + 60, y0 + randf_range(60, 160))
				dur = randf_range(3.2, 4.2)
				t = 0.0
			return
		if t >= dur:
			dur = 0.0
			wait = randf_range(9.0, 16.0)
			visible = false
			return
		visible = true
		position = from.lerp(to, t / dur)
		rotation = (to - from).angle()
		queue_redraw()

	func _draw() -> void:
		var col := Color(0.2, 0.1, 0.05, 0.2)
		var flap := sin(t * 9.0)
		# corpo, collo lungo e becco ricurvo
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 7.0, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(5, 0), Vector2(14, 0), col, 2.0)
		draw_arc(Vector2(14, 5), 5.0, -PI / 2.0, 0.2, 6, col, 1.5)
		draw_line(Vector2(-6, 0), Vector2(-14, 0), col, 1.5)
		for sx in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(-4, sx * (16 + 4 * flap)), Vector2(-10, sx * (14 + 4 * flap))]), col)
