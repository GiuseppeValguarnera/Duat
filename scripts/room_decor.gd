extends Node2D
## Arredamento di una stanza: pavimento (sabbia, crepe, mosaici), pareti dipinte,
## torce, statue di Anubi, bracieri, sarcofagi e vasi. Tutto disegnato con forme
## semplici, in attesa degli sprite veri. build() restituisce i rettangoli solidi.

var rng := RandomNumberGenerator.new()
var room := Rect2()
var top := 64.0
var wall := 32.0
var floor_bits: Array = []            # [tipo, dati...] disegnati sul pavimento
var props: Array = []                 # [tipo, posizione, extra]
var torches: Array[Vector2] = []
var mosaic := ""
var t := 0.0
var glow: Node2D


func build(seed_value: int, room_rect: Rect2, top_y: float, wall_w: float, pillars: Array, boss: bool) -> Array:
	rng.seed = seed_value
	room = room_rect
	top = top_y
	wall = wall_w
	var solids: Array = []
	var cx := room.size.x / 2.0
	var mid_y := (top + room.size.y - wall) / 2.0

	# pavimento
	mosaic = ["sun", "eye", "", ""][rng.randi() % 4] if not boss else "sun"
	for i in range(rng.randi_range(5, 8)):
		var corner := Vector2(rng.randf_range(wall + 20, room.size.x - wall - 20), rng.randf_range(top + 10, room.size.y - wall - 10))
		floor_bits.append(["sand", corner, rng.randf_range(30, 70), rng.randf_range(12, 26)])
	for i in range(rng.randi_range(6, 11)):
		var p := Vector2(rng.randf_range(wall + 10, room.size.x - wall - 10), rng.randf_range(top + 10, room.size.y - wall - 10))
		var pts := PackedVector2Array([p])
		for k in range(rng.randi_range(2, 4)):
			p += Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12))
			pts.append(p)
		floor_bits.append(["crack", pts])
	for i in range(rng.randi_range(4, 9)):
		floor_bits.append(["stone", Vector2(rng.randf_range(wall + 8, room.size.x - wall - 8), rng.randf_range(top + 8, room.size.y - wall - 8)), rng.randf_range(1.5, 3.0)])

	# torce sulla parete in alto (non davanti alla porta)
	var x := wall + 70.0
	while x < room.size.x - wall - 40.0:
		if absf(x - cx) > 70.0:
			torches.append(Vector2(x, top - 14.0))
		x += 150.0
	torches.append(Vector2(wall - 6.0, top + 60.0))
	torches.append(Vector2(room.size.x - wall + 6.0, top + 60.0))
	torches.append(Vector2(wall - 6.0, room.size.y - wall - 50.0))
	torches.append(Vector2(room.size.x - wall + 6.0, room.size.y - wall - 50.0))

	# statue di Anubi ai lati della porta nord
	for sx in [cx - 92.0, cx + 92.0]:
		_try_prop("statue", Vector2(sx, top + 16.0), Vector2(18, 12), pillars, solids)
	# bracieri negli angoli
	var corners := [Vector2(wall + 26, top + 26), Vector2(room.size.x - wall - 26, top + 26), Vector2(wall + 26, room.size.y - wall - 26), Vector2(room.size.x - wall - 26, room.size.y - wall - 26)]
	corners.shuffle()
	for c in corners.slice(0, rng.randi_range(2, 4)):
		_try_prop("brazier", c, Vector2(14, 10), pillars, solids)
	# sarcofago lungo una parete laterale
	if not boss and rng.randf() < 0.6:
		var left := rng.randf() < 0.5
		var sy := mid_y + (-110.0 if rng.randf() < 0.5 else 110.0)
		_try_prop("sarcophagus", Vector2(wall + 20.0 if left else room.size.x - wall - 20.0, sy), Vector2(22, 44), pillars, solids)
	# vasi a gruppetti (non bloccano)
	for i in range(rng.randi_range(2, 4)):
		var base := Vector2(rng.randf_range(wall + 20, room.size.x - wall - 20), [top + 12.0, room.size.y - wall - 12.0].pick_random())
		if absf(base.x - cx) < 60.0:
			continue
		for k in range(rng.randi_range(2, 3)):
			props.append(["urn", base + Vector2(k * 9.0 - 9.0, rng.randf_range(-3, 3)), rng.randf_range(0.8, 1.2)])

	glow = Glow.new()
	glow.decor = self
	add_child(glow)
	queue_redraw()
	return solids


## Aggiunge un oggetto solido se non è sopra una colonna o davanti a una porta.
func _try_prop(kind: String, pos: Vector2, size: Vector2, pillars: Array, solids: Array) -> void:
	for p in pillars:
		if p.distance_to(pos) < 44.0:
			return
	var cx := room.size.x / 2.0
	var mid_y := (top + room.size.y - wall) / 2.0
	if absf(pos.x - cx) < 40.0 and (pos.y < top + 40.0 or pos.y > room.size.y - wall - 50.0):
		return
	if absf(pos.y - mid_y) < 50.0 and (pos.x < wall + 40.0 or pos.x > room.size.x - wall - 40.0):
		return
	props.append([kind, pos, size])
	solids.append(Rect2(pos - size / 2.0, size))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	_draw_floor()
	_draw_walls()
	for pr in props:
		match pr[0]:
			"statue":
				_draw_statue(pr[1])
			"brazier":
				_draw_brazier(pr[1])
			"sarcophagus":
				_draw_sarcophagus(pr[1])
			"urn":
				_draw_urn(pr[1], pr[2])
	for tc in torches:
		_draw_torch(tc)


func _draw_floor() -> void:
	var cx := room.size.x / 2.0
	var mid_y := (top + room.size.y - wall) / 2.0
	var c := Vector2(cx, mid_y)
	# bordo del pavimento con fregio azzurro e oro
	var inner := Rect2(wall, top, room.size.x - wall * 2.0, room.size.y - wall - top)
	draw_rect(inner.grow(-2.0), Color(0.25, 0.17, 0.09, 0.5), false, 4.0)
	var i := 0
	var bx := inner.position.x + 6.0
	while bx < inner.end.x - 6.0:
		var col := Color(0.2, 0.5, 0.55, 0.45) if i % 2 == 0 else Color(0.85, 0.65, 0.25, 0.45)
		draw_rect(Rect2(bx, inner.end.y - 8.0, 8, 4), col)
		bx += 12.0
		i += 1
	if mosaic == "sun":
		draw_circle(c, 64.0, Color(0.55, 0.38, 0.16, 0.35))
		for k in range(16):
			var a := k * TAU / 16.0
			draw_line(c + Vector2.from_angle(a) * 40.0, c + Vector2.from_angle(a) * 70.0, Color(0.85, 0.6, 0.2, 0.35), 3.0)
		draw_circle(c, 34.0, Color(0.75, 0.28, 0.16, 0.35))
		draw_arc(c, 34.0, 0.0, TAU, 48, Color(0.95, 0.75, 0.3, 0.5), 2.0)
	elif mosaic == "eye":
		var e := PackedVector2Array()
		for k in range(25):
			var a := PI * k / 24.0
			e.append(c + Vector2(-60 + 120 * k / 24.0, -sin(a) * 22.0))
		for k in range(24, -1, -1):
			var a := PI * k / 24.0
			e.append(c + Vector2(-60 + 120 * k / 24.0, sin(a) * 16.0))
		draw_colored_polygon(e, Color(0.2, 0.42, 0.5, 0.25))
		draw_circle(c, 13.0, Color(0.12, 0.1, 0.12, 0.45))
		draw_line(c + Vector2(-10, 16), c + Vector2(-26, 42), Color(0.12, 0.1, 0.12, 0.4), 4.0)
		draw_arc(c + Vector2(28, 30), 12.0, -PI, 0.2, 16, Color(0.12, 0.1, 0.12, 0.4), 4.0)
	for b in floor_bits:
		match b[0]:
			"sand":
				draw_set_transform(b[1], 0.0, Vector2(1.0, b[3] / b[2]))
				draw_circle(Vector2.ZERO, b[2], Color(0.86, 0.72, 0.48, 0.22))
				draw_circle(Vector2.ZERO, b[2] * 0.6, Color(0.9, 0.78, 0.55, 0.18))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"crack":
				draw_polyline(b[1], Color(0.2, 0.13, 0.07, 0.55), 1.0)
			"stone":
				draw_circle(b[1], b[2], Color(0.42, 0.32, 0.2))


func _draw_walls() -> void:
	# pannelli dipinti con geroglifici sulla parete in alto
	var cx := room.size.x / 2.0
	var x := wall + 10.0
	var k := 0
	while x < room.size.x - wall - 60.0:
		if absf(x + 26.0 - cx) > 46.0:
			draw_rect(Rect2(x, wall + 2.0, 52, 10), Color(0.17, 0.32, 0.55))
			draw_rect(Rect2(x, wall + 2.0, 52, 10), Color(0.85, 0.65, 0.25), false, 1.0)
			_glyph(k % 5, Vector2(x + 12, wall + 7.0))
			_glyph((k + 2) % 5, Vector2(x + 26, wall + 7.0))
			_glyph((k + 4) % 5, Vector2(x + 40, wall + 7.0))
		x += 60.0
		k += 1
	# fasce verticali sulle pareti laterali
	var y := top + 10.0
	while y < room.size.y - wall - 10.0:
		draw_rect(Rect2(wall - 6.0, y, 4, 10), Color(0.85, 0.65, 0.25, 0.7))
		draw_rect(Rect2(room.size.x - wall + 2.0, y, 4, 10), Color(0.85, 0.65, 0.25, 0.7))
		y += 22.0


## Piccoli geroglifici: ankh, occhio, piuma, acqua, uccello.
func _glyph(kind: int, p: Vector2) -> void:
	var gold := Color(0.95, 0.78, 0.35)
	match kind:
		0:
			draw_arc(p + Vector2(0, -2), 1.8, 0.0, TAU, 8, gold, 1.0)
			draw_line(p + Vector2(0, 0), p + Vector2(0, 4), gold, 1.0)
			draw_line(p + Vector2(-2, 1), p + Vector2(2, 1), gold, 1.0)
		1:
			draw_line(p + Vector2(-4, 0), p + Vector2(4, 0), gold, 1.0)
			draw_circle(p, 1.4, gold)
			draw_line(p + Vector2(-1, 1), p + Vector2(-2, 4), gold, 1.0)
		2:
			draw_line(p + Vector2(0, -4), p + Vector2(0, 4), gold, 1.0)
			draw_line(p + Vector2(0, -4), p + Vector2(2, -1), gold, 1.0)
		3:
			for j in range(2):
				draw_polyline(PackedVector2Array([p + Vector2(-4, -1 + j * 3), p + Vector2(-2, -2 + j * 3), p + Vector2(0, -1 + j * 3), p + Vector2(2, -2 + j * 3), p + Vector2(4, -1 + j * 3)]), gold, 1.0)
		4:
			draw_circle(p + Vector2(-1, -2), 1.2, gold)
			draw_line(p + Vector2(-1, -1), p + Vector2(3, 3), gold, 1.0)
			draw_line(p + Vector2(-2, 3), p + Vector2(3, 3), gold, 1.0)


func _draw_torch(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 2, p.y, 4, 8), Color(0.3, 0.2, 0.1))
	draw_rect(Rect2(p.x - 4, p.y - 1, 8, 3), Color(0.85, 0.65, 0.25))
	_flame(p + Vector2(0, -2), 1.0)


func _flame(p: Vector2, s: float) -> void:
	var f := sin(t * 13.0 + p.x) * 0.8 + sin(t * 7.0 + p.y) * 0.6
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3.5, 0) * s, p + Vector2(3.5, 0) * s, p + Vector2(f, -10.0 - f) * s]), Color(1, 0.55, 0.15))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-1.8, 0) * s, p + Vector2(1.8, 0) * s, p + Vector2(f * 0.5, -6.0) * s]), Color(1, 0.92, 0.55))


func _draw_statue(p: Vector2) -> void:
	# statua di Anubi seduto su un piedistallo
	draw_rect(Rect2(p.x - 11, p.y - 4, 22, 10), Color(0.62, 0.5, 0.32))
	draw_rect(Rect2(p.x - 11, p.y - 4, 22, 2), Color(0.85, 0.65, 0.25))
	var black := Color(0.1, 0.09, 0.12)
	draw_rect(Rect2(p.x - 8, p.y - 22, 16, 18), black)
	draw_rect(Rect2(p.x - 4, p.y - 34, 9, 13), black)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 4, p.y - 33), Vector2(p.x - 2, p.y - 33), Vector2(p.x - 4, p.y - 43)]), black)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x + 2, p.y - 33), Vector2(p.x + 4, p.y - 33), Vector2(p.x + 3, p.y - 43)]), black)
	draw_rect(Rect2(p.x + 4, p.y - 30, 7, 4), black)
	draw_rect(Rect2(p.x - 8, p.y - 22, 16, 3), Color(0.85, 0.65, 0.25))
	draw_circle(Vector2(p.x + 2, p.y - 30), 0.9, Color(0.95, 0.78, 0.35))


func _draw_brazier(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 2, p.y - 6, 4, 10), Color(0.35, 0.25, 0.12))
	draw_rect(Rect2(p.x - 6, p.y + 2, 12, 3), Color(0.35, 0.25, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 8, p.y - 12), Vector2(p.x + 8, p.y - 12), Vector2(p.x + 5, p.y - 6), Vector2(p.x - 5, p.y - 6)]), Color(0.85, 0.62, 0.22))
	_flame(Vector2(p.x, p.y - 12), 1.4)


func _draw_sarcophagus(p: Vector2) -> void:
	var r := Rect2(p.x - 11, p.y - 22, 22, 44)
	draw_rect(r, Color(0.78, 0.56, 0.2))
	draw_rect(Rect2(p.x - 9, p.y - 20, 18, 14), Color(0.17, 0.32, 0.55))
	draw_rect(Rect2(p.x - 6, p.y - 18, 12, 10), Color(0.75, 0.48, 0.25))
	for k in range(4):
		draw_line(Vector2(p.x - 9, p.y - 2 + k * 5), Vector2(p.x + 9, p.y - 2 + k * 5), Color(0.17, 0.32, 0.55), 1.5)
	draw_rect(r, Color(0.35, 0.22, 0.08), false, 1.5)


func _draw_urn(p: Vector2, s: float) -> void:
	draw_set_transform(p, 0.0, Vector2(s, s))
	draw_circle(Vector2(0, -4), 4.5, Color(0.62, 0.38, 0.2))
	draw_rect(Rect2(-2.5, -11, 5, 4), Color(0.62, 0.38, 0.2))
	draw_rect(Rect2(-3.5, -12, 7, 1.5), Color(0.45, 0.27, 0.14))
	draw_line(Vector2(-4, -4), Vector2(4, -4), Color(0.2, 0.42, 0.45), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Bagliore delle fiamme: cerchi sfumati sommati alla scena (illuminazione finta).
class Glow extends Node2D:
	var decor: Node2D
	var tex: GradientTexture2D

	func _ready() -> void:
		z_index = 20
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var tt: float = decor.t
		for tc in decor.torches:
			_halo(tc + Vector2(0, -6), 56.0 + sin(tt * 9.0 + tc.x) * 3.0, Color(1, 0.55, 0.2, 0.32))
		for pr in decor.props:
			if pr[0] == "brazier":
				_halo(pr[1] + Vector2(0, -16), 72.0 + sin(tt * 8.0 + pr[1].y) * 4.0, Color(1, 0.5, 0.15, 0.38))

	func _halo(p: Vector2, r: float, c: Color) -> void:
		draw_texture_rect(tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, c)
