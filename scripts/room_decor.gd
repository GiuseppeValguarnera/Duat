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
var wisps: Array = []                 # [posizione, fase, azzurro?] spiriti del Ka che fluttuano
const MOTIFS := ["sun", "eye", "scarab", "lotus", "nut"]
## I colori della pittura egizia: lapislazzuli, turchese, ocra rossa e gialla, malachite.
const LAPIS := Color(0.16, 0.3, 0.68)
const TURQ := Color(0.2, 0.62, 0.62)
const RED_OCHRE := Color(0.72, 0.26, 0.15)
const YELLOW_OCHRE := Color(0.9, 0.7, 0.3)
const MALACHITE := Color(0.26, 0.55, 0.32)
const WHITE_LIME := Color(0.95, 0.92, 0.84)
var t := 0.0
var glow: Node2D
var ambient: CanvasModulate             ## la penombra della stanza (il serdab la scurisce)
## Il disegno fermo della stanza, fatto una volta sola in una texture (vedi _bake).
var baked: Texture2D = null
var painter := false                    ## vero per la copia che disegna dentro la texture
## Chi disegna sotto l'arredamento (il pavimento e i muri della stanza, in game.gd): finisce
## anche lui nella texture.
var under: Callable
signal bake_done                        ## la texture è pronta (game.gd toglie il nero del passaggio)
var _vp: SubViewport
## Quanto è buia la stanza lontano dalle luci (la penombra cotta, vedi _draw_shade).
var SHADE := 0.52
## L'arena di un guardiano o di un boss (arenas.gd): "gate" o "lake". Niente arredamento da tomba:
## pavimento e pareti li disegna `under`, qui resta solo la penombra cotta. Da dare prima di build().
var arena := ""
## Bracieri spenti (nella Sala, finché non li restauri: vedi restorations.gd). Da dare prima di build().
var cold_braziers := false


func build(seed_value: int, room_rect: Rect2, top_y: float, wall_w: float, pillars: Array, boss: bool) -> Array:
	rng.seed = seed_value
	room = room_rect
	top = top_y
	wall = wall_w
	var solids: Array = []
	var cx := room.size.x / 2.0
	var mid_y := (top + room.size.y - wall) / 2.0
	if arena != "":
		ambient = CanvasModulate.new()
		ambient.color = Color(1.0, 0.84, 0.78) if arena == "lake" else Color(0.84, 0.88, 0.94)
		add_child(ambient)
		queue_redraw()
		_bake.call_deferred()
		return solids

	# pavimento
	# il motivo al centro del pavimento: ogni stanza il suo (le stanze tutte uguali annoiavano)
	mosaic = MOTIFS[rng.randi() % MOTIFS.size()] if not boss else "sun"
	# mattonelle di faience turchese e lapislazzuli incastonate nel pavimento
	for i in range(rng.randi_range(5, 9)):
		var gx := rng.randi_range(0, int((room.size.x - wall * 2.0) / 32.0) - 1)
		var gy := rng.randi_range(0, int((room.size.y - wall - top) / 32.0) - 1)
		floor_bits.append(["faience", Vector2(wall + gx * 32.0, top + gy * 32.0), rng.randi() % 3])
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
	# papiri lungo le pareti e una tavola delle offerte (non bloccano)
	for i in range(rng.randi_range(2, 4)):
		var px := rng.randf_range(wall + 16, room.size.x - wall - 16)
		var py: float = [top + 10.0, room.size.y - wall - 8.0].pick_random()
		if rng.randf() < 0.4:
			px = [wall + 10.0, room.size.x - wall - 10.0].pick_random()
			py = rng.randf_range(top + 40, room.size.y - wall - 40)
		if absf(px - cx) < 50.0 or _near_pillar(Vector2(px, py), pillars, 30.0):
			continue
		props.append(["papyrus", Vector2(px, py), rng.randf_range(0.85, 1.2)])
	if not boss and rng.randf() < 0.7:
		var ox := rng.randf_range(wall + 60, room.size.x - wall - 60)
		if absf(ox - cx) > 60.0 and not _near_pillar(Vector2(ox, top + 14.0), pillars, 40.0):
			props.append(["offering", Vector2(ox, top + 14.0), rng.randi() % 3])
	# spiriti del Ka: piccole luci azzurre e dorate che vagano nell'aria
	for i in range(rng.randi_range(5, 8)):
		wisps.append([Vector2(rng.randf_range(wall + 20, room.size.x - wall - 20), rng.randf_range(top + 20, room.size.y - wall - 20)), rng.randf() * TAU, rng.randf() < 0.7])
	# vasi a gruppetti (non bloccano)
	for i in range(rng.randi_range(2, 4)):
		var base := Vector2(rng.randf_range(wall + 20, room.size.x - wall - 20), [top + 12.0, room.size.y - wall - 12.0].pick_random())
		if absf(base.x - cx) < 60.0:
			continue
		for k in range(rng.randi_range(2, 3)):
			props.append(["urn", base + Vector2(k * 9.0 - 9.0, rng.randf_range(-3, 3)), rng.randf_range(0.8, 1.2)])

	var flames := Flames.new()
	flames.decor = self
	add_child(flames)
	glow = Glow.new()
	glow.decor = self
	add_child(glow)
	# la luce (scripts/atmos.gd): penombra di fondo, torce e bracieri fanno luce. Nelle stanze
	# sono tutte luci finte: le vere, con tanti nemici e colpi a schermo, facevano scattare il gioco.
	ambient = CanvasModulate.new()
	ambient.color = Atmos.AMBIENT_ROOM           # la Sala la cambia nella sua notte blu
	add_child(ambient)
	# le pozze di luce delle torce sono finte e ferme: finiscono nella texture (_bake)
	for pr in props:
		if pr[0] == "brazier" and not cold_braziers:
			Atmos.add_light(self, pr[1] + Vector2(0, -14), 140.0, Color(1.0, 0.55, 0.25), 1.2, false)
	Atmos.dust(self, Rect2(wall, top, room.size.x - wall * 2.0, room.size.y - wall - top))
	queue_redraw()
	_bake.call_deferred()
	return solids


## Pavimento, pareti dipinte, oggetti e pozze di luce delle torce non si muovono: si disegnano una
## volta in una texture e poi, a ogni fotogramma, si disegna solo quella (un quadrato). Prima la
## scheda grafica rifaceva centinaia di forme a ogni fotogramma, e di nuovo per ogni luce.
## La texture è più fitta dei pixel del gioco, così resta nitida anche sugli schermi grandi.
func _bake() -> void:
	if painter or not is_inside_tree():
		return
	# il doppio dei pixel del gioco basta: di più costava troppo al cambio di stanza sul telefono
	var s := 2.0
	var vp := SubViewport.new()
	vp.size = Vector2i(ceili(room.size.x * s), ceili(room.size.y * s))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var p: Node2D = get_script().new()
	p.painter = true
	p.room = room
	p.top = top
	p.wall = wall
	p.floor_bits = floor_bits
	p.props = props
	p.torches = torches
	p.mosaic = mosaic
	p.cold_braziers = cold_braziers
	p.under = under
	p.SHADE = SHADE
	p.arena = arena
	p.scale = Vector2(s, s)
	p.set_process(false)
	vp.add_child(p)
	for tc in torches:
		var pool := Atmos.add_glow(p, tc + Vector2(0, 2), 150.0, Atmos.TORCH, 1.5)
		pool.set_process(false)
	add_child(vp)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		return
	if _vp != null and is_instance_valid(_vp):
		_vp.queue_free()                   # la texture di prima (rebake)
	_vp = vp
	baked = vp.get_texture()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	material = Atmos.premult_mat()        # la texture ha l'alfa già moltiplicato
	queue_redraw()
	bake_done.emit()


func _near_pillar(pos: Vector2, pillars: Array, d: float) -> bool:
	for p in pillars:
		if p.distance_to(pos) < d:
			return true
	return false


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


## Il tempo passa, ma l'arredamento non si ridisegna: pavimento, pareti e oggetti sono fermi.
## Si muovono solo le fiamme e gli spiriti, disegnati da Flames e Glow. Ridisegnare tutto a ogni
## fotogramma, con le luci vere sopra, rallentava il gioco sul telefono.
func _process(delta: float) -> void:
	t += delta


## Rifà la texture (per esempio quando compare l'altare di Set): la vecchia resta finché la
## nuova non è pronta, così non si vede mai un fotogramma vuoto.
func rebake() -> void:
	_bake.call_deferred()


func _draw() -> void:
	if baked != null:
		draw_texture_rect(baked, Rect2(Vector2.ZERO, room.size), false)
		return
	if under.is_valid():
		under.call(self)
	if arena != "":
		if painter:
			_draw_shade()
		return
	_draw_floor()
	_draw_ao()
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
			"papyrus":
				_draw_papyrus(pr[1], pr[2])
			"offering":
				_draw_offering(pr[1], pr[2])
	if painter:
		_draw_shade()
	for tc in torches:
		_draw_torch(tc)
	# le fiamme sono in Flames, che si ridisegna da solo


## Luce e ombra cotte nella texture: la stanza è in penombra, tranne attorno alle torce, ai
## bracieri, alle porte e al centro, dove si combatte. Una griglia di quadratini con la
## trasparenza calcolata per ogni vertice: costa solo quando si cuoce, poi è gratis. I nemici e
## l'eroe stanno sopra e non vengono scuriti: si leggono sempre.
func _draw_shade() -> void:
	var lights: Array = []           # [posizione, raggio, forza]
	for tc in torches:
		lights.append([tc + Vector2(0, 14), 105.0, 1.0])
	for pr in props:
		if pr[0] == "brazier" and not cold_braziers:
			lights.append([pr[1], 115.0, 1.0])
	var mid := Vector2(room.size.x / 2.0, (top + room.size.y - wall) / 2.0)
	lights.append([mid, 175.0, 0.55])
	lights.append([Vector2(room.size.x / 2.0, top), 90.0, 0.8])                          # porta nord
	lights.append([Vector2(wall, mid.y), 80.0, 0.7])
	lights.append([Vector2(room.size.x - wall, mid.y), 80.0, 0.7])
	# una sola chiamata con tutti i triangoli (prima era un poligono per quadratino: più di mille
	# chiamate, e il cambio di stanza scattava)
	var cell := 20.0
	var nx := ceili(room.size.x / cell)
	var ny := ceili(room.size.y / cell)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var col := Color(0.03, 0.02, 0.05)
	for j in range(ny + 1):
		for i in range(nx + 1):
			var q := Vector2(i * cell, j * cell)
			var lit := 0.0
			for l in lights:
				var d: float = q.distance_to(l[0])
				var r: float = l[1]
				if d < r:
					var k := 1.0 - d / r
					lit += k * k * (3.0 - 2.0 * k) * float(l[2])
			pts.append(q)
			cols.append(Color(col, SHADE * (1.0 - clampf(lit, 0.0, 1.0))))
	var idx := PackedInt32Array()
	var w := nx + 1
	for j in range(ny):
		for i in range(nx):
			var v0 := j * w + i
			if cols[v0].a + cols[v0 + 1].a + cols[v0 + w].a + cols[v0 + w + 1].a < 0.01:
				continue
			idx.append_array(PackedInt32Array([v0, v0 + 1, v0 + w + 1, v0, v0 + w + 1, v0 + w]))
	if not idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)

func _draw_floor() -> void:
	var cx := room.size.x / 2.0
	var mid_y := (top + room.size.y - wall) / 2.0
	var c := Vector2(cx, mid_y)
	# bordo del pavimento con fregio di fiori di loto (aperti e in bocciolo), lapislazzuli e turchese
	var inner := Rect2(wall, top, room.size.x - wall * 2.0, room.size.y - wall - top)
	draw_rect(inner.grow(-2.0), Color(0.25, 0.17, 0.09, 0.5), false, 4.0)
	var i := 0
	var bx := inner.position.x + 10.0
	while bx < inner.end.x - 10.0:
		_lotus(Vector2(bx, inner.end.y - 6.0), i % 2 == 0, 0.8)
		bx += 14.0
		i += 1
	match mosaic:
		"sun":
			draw_circle(c, 64.0, Color(0.55, 0.38, 0.16, 0.35))
			for k in range(16):
				var a := k * TAU / 16.0
				draw_line(c + Vector2.from_angle(a) * 40.0, c + Vector2.from_angle(a) * 70.0, Color(YELLOW_OCHRE, 0.55), 3.0)
			draw_circle(c, 34.0, Color(RED_OCHRE, 0.6))
			draw_arc(c, 34.0, 0.0, TAU, 48, Color(0.95, 0.75, 0.3, 0.7), 2.0)
		"eye":
			_motif_eye(c)
		"scarab":
			_motif_scarab(c)
		"lotus":
			_motif_lotus(c)
		"nut":
			_motif_nut(c)
	for b in floor_bits:
		match b[0]:
			"sand":
				draw_set_transform(b[1], 0.0, Vector2(1.0, b[3] / b[2]))
				# sabbia scura portata dal vento: chiara sembrava una chiazza di luce
				draw_circle(Vector2.ZERO, b[2], Color(0.3, 0.22, 0.13, 0.16))
				draw_circle(Vector2.ZERO, b[2] * 0.6, Color(0.25, 0.18, 0.1, 0.12))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"crack":
				draw_polyline(b[1], Color(0.2, 0.13, 0.07, 0.55), 1.0)
			"stone":
				draw_circle(b[1], b[2], Color(0.42, 0.32, 0.2))
			"faience":
				var fc: Color = [TURQ, LAPIS, MALACHITE][b[2]]
				var fr := Rect2(b[1] + Vector2(4, 4), Vector2(24, 24))
				draw_rect(fr, Color(fc, 0.5))
				draw_rect(fr.grow(-4.0), Color(fc.lightened(0.25), 0.45))
				draw_rect(fr, Color(YELLOW_OCHRE, 0.55), false, 1.0)
				draw_circle(fr.get_center(), 2.0, Color(YELLOW_OCHRE, 0.6))


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
	# sotto i pannelli: fasce di colore (rosso, giallo, blu, verde) e un fregio kheker in cima
	var face_y := wall + 15.0
	for band in [[RED_OCHRE, 0.0], [YELLOW_OCHRE, 2.0], [LAPIS, 4.0], [MALACHITE, 6.0]]:
		draw_rect(Rect2(wall, face_y + band[1], room.size.x - wall * 2.0, 2.0), Color(band[0], 0.8))
	var kx := wall
	var kk := 0
	while kx < room.size.x - wall:
		var kc: Color = [RED_OCHRE, LAPIS, MALACHITE][kk % 3]
		draw_colored_polygon(PackedVector2Array([Vector2(kx + 1, wall + 1), Vector2(kx + 5, wall + 1), Vector2(kx + 4, wall - 4), Vector2(kx + 3, wall - 6), Vector2(kx + 2, wall - 4)]), Color(kc, 0.85))
		kx += 6.0
		kk += 1
	# figure dipinte di profilo tra i pannelli: portatori di offerte, alla maniera delle tombe
	var fx := wall + 64.0
	var fk := 0
	while fx < room.size.x - wall - 20.0:
		if absf(fx - cx) > 52.0:
			_painted_figure(Vector2(fx, wall + 13.0), fk)
		fx += 60.0
		fk += 1
	# sulle pareti laterali colonne di segni colorati (non più tutte d'oro)
	var y := top + 10.0
	var yk := 0
	while y < room.size.y - wall - 10.0:
		var sc: Color = [YELLOW_OCHRE, TURQ, RED_OCHRE, LAPIS][yk % 4]
		draw_rect(Rect2(wall - 6.0, y, 4, 10), Color(sc, 0.8))
		draw_rect(Rect2(room.size.x - wall + 2.0, y, 4, 10), Color(sc, 0.8))
		y += 22.0
		yk += 1


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


## Un fiore di loto (aperto) o un bocciolo, sul fregio del pavimento.
func _lotus(p: Vector2, open: bool, s: float) -> void:
	var col := LAPIS if open else TURQ
	draw_line(p + Vector2(0, 3) * s, p + Vector2(0, -1) * s, Color(MALACHITE, 0.6), 1.0)
	if open:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -1) * s, p + Vector2(-1.5, -5) * s, p + Vector2(0, -2) * s, p + Vector2(1.5, -5) * s, p + Vector2(4, -1) * s, p + Vector2(0, 0) * s]), Color(col, 0.65))
		draw_line(p + Vector2(0, -1) * s, p + Vector2(0, -6) * s, Color(WHITE_LIME, 0.55), 1.0)
	else:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -1) * s, p + Vector2(0, -5) * s, p + Vector2(2, -1) * s]), Color(col, 0.6))


## L'occhio udjat di Horus: bianco, iride nera, il trucco blu e il segno sotto.
func _motif_eye(c: Vector2) -> void:
	var e := PackedVector2Array()
	for k in range(25):
		var a := PI * k / 24.0
		e.append(c + Vector2(-60 + 120 * k / 24.0, -sin(a) * 22.0))
	for k in range(24, -1, -1):
		var a := PI * k / 24.0
		e.append(c + Vector2(-60 + 120 * k / 24.0, sin(a) * 16.0))
	draw_colored_polygon(e, Color(WHITE_LIME, 0.32))
	draw_polyline(e, Color(LAPIS, 0.7), 3.0)
	draw_circle(c, 13.0, Color(0.08, 0.07, 0.1, 0.6))
	draw_line(c + Vector2(-62, -24), c + Vector2(62, -30), Color(LAPIS, 0.6), 4.0)
	draw_line(c + Vector2(-10, 16), c + Vector2(-26, 42), Color(LAPIS, 0.6), 4.0)
	draw_arc(c + Vector2(28, 30), 12.0, -PI, 0.2, 16, Color(LAPIS, 0.6), 4.0)


## Lo scarabeo alato Khepri che spinge il sole: corpo turchese, ali a fasce colorate.
func _motif_scarab(c: Vector2) -> void:
	for side in [-1.0, 1.0]:
		for k in range(4):
			var col: Color = [LAPIS, TURQ, RED_OCHRE, YELLOW_OCHRE][k]
			var y0 := -8.0 + k * 6.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(side * 14, y0), c + Vector2(side * (78 - k * 10), y0 - 10 + k * 3), c + Vector2(side * (74 - k * 10), y0 - 4 + k * 3), c + Vector2(side * 14, y0 + 5)]), Color(col, 0.5))
	draw_circle(c + Vector2(0, -26), 11.0, Color(RED_OCHRE, 0.6))
	draw_set_transform(c + Vector2(0, 4), 0.0, Vector2(1.0, 1.35))
	draw_circle(Vector2.ZERO, 14.0, Color(TURQ, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(c + Vector2(0, -12), c + Vector2(0, 22), Color(0.1, 0.12, 0.1, 0.5), 1.5)
	draw_circle(c + Vector2(0, -12), 6.0, Color(TURQ.darkened(0.3), 0.65))


## Una rosa di loto vista dall'alto: petali blu e bianchi su un disco giallo.
func _motif_lotus(c: Vector2) -> void:
	for k in range(12):
		var a := k * TAU / 12.0
		var tip := c + Vector2.from_angle(a) * 56.0
		var l := c + Vector2.from_angle(a - 0.22) * 22.0
		var r := c + Vector2.from_angle(a + 0.22) * 22.0
		draw_colored_polygon(PackedVector2Array([l, tip, r]), Color(LAPIS if k % 2 == 0 else WHITE_LIME, 0.5))
	draw_circle(c, 20.0, Color(YELLOW_OCHRE, 0.6))
	draw_arc(c, 20.0, 0.0, TAU, 32, Color(RED_OCHRE, 0.6), 2.0)


## Il cielo di Nut, come sui soffitti delle tombe: blu notte con le stelle a cinque punte.
func _motif_nut(c: Vector2) -> void:
	var r := Rect2(c - Vector2(84, 44), Vector2(168, 88))
	draw_rect(r, Color(0.08, 0.12, 0.35, 0.55))
	draw_rect(r, Color(YELLOW_OCHRE, 0.6), false, 2.0)
	for k in range(14):
		var row := int(k / 7.0)
		var sp := r.position + Vector2(14 + (k % 7) * 23.0 + row * 11.0, 22 + row * 44.0)
		_star(sp, 5.0, Color(YELLOW_OCHRE, 0.75))


func _star(p: Vector2, rr: float, col: Color) -> void:
	for k in range(5):
		var a := -PI / 2.0 + k * TAU / 5.0
		draw_line(p, p + Vector2.from_angle(a) * rr, col, 1.5)


## Una figura dipinta di profilo sulla parete: un portatore di offerte con il gonnellino.
func _painted_figure(p: Vector2, k: int) -> void:
	var skin := Color(RED_OCHRE.lightened(0.1), 0.9)
	draw_circle(p + Vector2(0, -9), 1.8, Color(0.08, 0.06, 0.05, 0.9))          # capelli
	draw_circle(p + Vector2(0.6, -8.6), 1.4, skin)                               # viso
	draw_line(p + Vector2(0, -7), p + Vector2(0, -3), skin, 2.0)                  # torso
	draw_rect(Rect2(p.x - 1.5, p.y - 3, 3, 3), Color(WHITE_LIME, 0.9))           # gonnellino
	draw_line(p + Vector2(-0.6, 0), p + Vector2(-1.5, 3), skin, 1.0)
	draw_line(p + Vector2(0.6, 0), p + Vector2(1.8, 3), skin, 1.0)
	draw_line(p + Vector2(0, -6), p + Vector2(3, -8), skin, 1.0)                  # braccio alzato
	var gift: Color = [YELLOW_OCHRE, MALACHITE, LAPIS][k % 3]
	draw_circle(p + Vector2(3.5, -9), 1.4, Color(gift, 0.95))                    # l'offerta


## Un ciuffo di papiro: steli verdi con le infiorescenze a ventaglio.
func _draw_papyrus(p: Vector2, s: float) -> void:
	for k in range(5):
		var a := -PI / 2.0 + (k - 2) * 0.22
		var top_p := p + Vector2.from_angle(a) * (16.0 + (k % 2) * 4.0) * s
		draw_line(p, top_p, MALACHITE.darkened(0.15), 1.0)
		draw_colored_polygon(PackedVector2Array([top_p, top_p + Vector2.from_angle(a - 0.6) * 4.0 * s, top_p + Vector2.from_angle(a + 0.6) * 4.0 * s]), MALACHITE.lightened(0.15))
	draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0 * s, Color(0.2, 0.3, 0.15, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## La tavola delle offerte: pane, frutta, un fiore di loto e una brocca.
func _draw_offering(p: Vector2, k: int) -> void:
	_shadow(p + Vector2(1, 5), 13.0, 3.0, 0.28)
	draw_rect(Rect2(p.x - 12, p.y - 4, 24, 4), Color(0.62, 0.5, 0.32))
	draw_rect(Rect2(p.x - 2, p.y, 4, 6), Color(0.5, 0.4, 0.25))
	draw_rect(Rect2(p.x - 12, p.y - 4, 24, 1), YELLOW_OCHRE)
	draw_arc(p + Vector2(-6, -4), 3.5, PI, TAU, 8, Color(0.82, 0.6, 0.32), 2.5)   # pane
	draw_circle(p + Vector2(0, -6), 2.2, RED_OCHRE if k != 1 else MALACHITE)      # frutta
	draw_circle(p + Vector2(3, -5.5), 1.8, YELLOW_OCHRE)
	draw_rect(Rect2(p.x + 6, p.y - 10, 3, 6), LAPIS)                               # brocca
	_lotus(p + Vector2(-10, -6), true, 0.8)


const OUTL := Color(0.12, 0.08, 0.05)


func _op(pts: PackedVector2Array, fill: Color, w: float = 0.8) -> void:
	draw_colored_polygon(pts, fill)
	var c := pts.duplicate()
	c.append(pts[0])
	draw_polyline(c, OUTL, w)


## Ombra morbida a terra sotto un oggetto: è quella che lo fa stare sul pavimento.
func _shadow(p: Vector2, rx: float, ry: float, a: float = 0.32) -> void:
	draw_set_transform(p, 0.0, Vector2(1.0, ry / rx))
	draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, a * 0.6))
	draw_circle(Vector2.ZERO, rx * 0.7, Color(0, 0, 0, a * 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Penombra ai piedi dei muri (occlusione): sfumature con i vertici colorati, nessuna texture.
func _draw_ao() -> void:
	var l := wall
	var r := room.size.x - wall
	var b := room.size.y - wall
	var dark := Color(0.05, 0.03, 0.02, 0.5)
	var clear := Color(0.05, 0.03, 0.02, 0.0)
	draw_polygon(PackedVector2Array([Vector2(l, top), Vector2(r, top), Vector2(r, top + 26), Vector2(l, top + 26)]), PackedColorArray([dark, dark, clear, clear]))
	var side := Color(0.05, 0.03, 0.02, 0.38)
	draw_polygon(PackedVector2Array([Vector2(l, top), Vector2(l + 16, top), Vector2(l + 16, b), Vector2(l, b)]), PackedColorArray([side, clear, clear, side]))
	draw_polygon(PackedVector2Array([Vector2(r - 16, top), Vector2(r, top), Vector2(r, b), Vector2(r - 16, b)]), PackedColorArray([clear, side, side, clear]))
	var low := Color(0.05, 0.03, 0.02, 0.3)
	draw_polygon(PackedVector2Array([Vector2(l, b - 12), Vector2(r, b - 12), Vector2(r, b), Vector2(l, b)]), PackedColorArray([clear, clear, low, low]))
	# sabbia accumulata negli angoli e lungo i muri: il vento del deserto entra nelle tombe
	for c in [Vector2(l, top), Vector2(r, top), Vector2(l, b), Vector2(r, b)]:
		var k := Vector2(1.0 if c.x < room.size.x / 2.0 else -1.0, 1.0 if c.y < room.size.y / 2.0 else -1.0)
		var pile := PackedVector2Array([c, c + Vector2(34 * k.x, 0), c + Vector2(20 * k.x, 6 * k.y), c + Vector2(8 * k.x, 16 * k.y), c + Vector2(0, 26 * k.y)])
		draw_colored_polygon(pile, Color(0.66, 0.52, 0.32, 0.55))
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(18 * k.x, 0), c + Vector2(6 * k.x, 8 * k.y), c + Vector2(0, 14 * k.y)]), Color(0.74, 0.6, 0.38, 0.6))


## Il supporto della torcia: staffa di bronzo fissata al muro e la coppa dove brucia.
func _draw_torch(p: Vector2) -> void:
	_op(PackedVector2Array([Vector2(p.x - 1.5, p.y + 1), Vector2(p.x + 1.5, p.y + 1), Vector2(p.x + 1, p.y + 9), Vector2(p.x - 1, p.y + 9)]), Color(0.36, 0.24, 0.12), 0.6)
	_op(PackedVector2Array([Vector2(p.x - 5, p.y - 2), Vector2(p.x + 5, p.y - 2), Vector2(p.x + 3, p.y + 2), Vector2(p.x - 3, p.y + 2)]), Color(0.86, 0.64, 0.26), 0.7)
	draw_line(Vector2(p.x - 4, p.y - 1.2), Vector2(p.x + 4, p.y - 1.2), Color(1, 0.6, 0.2), 0.8)
	draw_rect(Rect2(p.x - 3, p.y + 9, 6, 2), Color(0.7, 0.5, 0.2))


## Anubi sdraiato sul suo sacrario, come quello della tomba di Tutankhamon: lo sciacallo nero
## col collare d'oro, la cassa dorata con i pannelli blu e rossi.
func _draw_statue(p: Vector2) -> void:
	_shadow(p + Vector2(2, 5), 15.0, 5.0)
	var gold := Color(0.88, 0.66, 0.26)
	var gold_d := Color(0.62, 0.44, 0.16)
	# la cassa
	_op(PackedVector2Array([Vector2(p.x - 12, p.y - 9), Vector2(p.x + 12, p.y - 9), Vector2(p.x + 12, p.y + 5), Vector2(p.x - 12, p.y + 5)]), gold)
	draw_rect(Rect2(p.x - 12, p.y - 9, 24, 3), gold_d)
	for k in range(3):
		var px := p.x - 10 + k * 7.0
		draw_rect(Rect2(px, p.y - 5, 5, 8), LAPIS if k % 2 == 0 else RED_OCHRE)
		draw_rect(Rect2(px, p.y - 5, 5, 8), gold_d, false, 0.6)
		draw_line(Vector2(px + 2.5, p.y - 4), Vector2(px + 2.5, p.y + 2), gold, 0.6)
	# lo sciacallo sdraiato
	var black := Color(0.09, 0.08, 0.11)
	var body := PackedVector2Array([Vector2(p.x - 10, p.y - 9), Vector2(p.x - 9, p.y - 15), Vector2(p.x - 2, p.y - 17), Vector2(p.x + 5, p.y - 16), Vector2(p.x + 8, p.y - 10), Vector2(p.x + 13, p.y - 10), Vector2(p.x + 13, p.y - 9)])
	_op(body, black)
	draw_line(Vector2(p.x - 10, p.y - 10), Vector2(p.x - 13, p.y - 9.5), black, 1.5)       # la coda
	# il collo alzato, la testa col muso lungo e le orecchie dritte
	var head := PackedVector2Array([Vector2(p.x + 3, p.y - 16), Vector2(p.x + 5, p.y - 25), Vector2(p.x + 8, p.y - 27), Vector2(p.x + 14, p.y - 25), Vector2(p.x + 14, p.y - 23.5), Vector2(p.x + 9, p.y - 22.5), Vector2(p.x + 8, p.y - 15)])
	_op(head, black)
	for ex in [5.5, 8.0]:
		_op(PackedVector2Array([Vector2(p.x + ex, p.y - 26), Vector2(p.x + ex + 1, p.y - 33), Vector2(p.x + ex + 2.5, p.y - 26.5)]), black, 0.6)
	draw_line(Vector2(p.x + 4, p.y - 19), Vector2(p.x + 9, p.y - 19.5), gold, 1.2)                # collare
	draw_line(Vector2(p.x + 7, p.y - 25.5), Vector2(p.x + 10.5, p.y - 25.8), gold, 0.7)          # l'occhio dorato
	draw_circle(Vector2(p.x + 10, p.y - 25.7), 0.6, Color(1, 0.9, 0.5))


## Il braciere: tre piedi di bronzo, la coppa e le braci (la fiamma è in Flames).
func _draw_brazier(p: Vector2) -> void:
	_shadow(p + Vector2(1, 4), 10.0, 3.5)
	var bronze := Color(0.7, 0.48, 0.2)
	for lx in [-5.0, 0.0, 5.0]:
		draw_line(Vector2(p.x + lx * 0.5, p.y - 6), Vector2(p.x + lx, p.y + 4), OUTL, 2.6)
		draw_line(Vector2(p.x + lx * 0.5, p.y - 6), Vector2(p.x + lx, p.y + 4), bronze, 1.4)
	_op(PackedVector2Array([Vector2(p.x - 9, p.y - 12), Vector2(p.x + 9, p.y - 12), Vector2(p.x + 6, p.y - 6), Vector2(p.x - 6, p.y - 6)]), Color(0.86, 0.62, 0.22))
	draw_line(Vector2(p.x - 8, p.y - 10), Vector2(p.x + 8, p.y - 10), RED_OCHRE, 0.8)
	draw_set_transform(p + Vector2(0, -12), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 8.5, OUTL)
	if cold_braziers:
		draw_circle(Vector2.ZERO, 7.5, Color(0.3, 0.28, 0.27))          # cenere fredda
		draw_circle(Vector2(-2, 0), 3.0, Color(0.42, 0.4, 0.38))
	else:
		draw_circle(Vector2.ZERO, 7.5, Color(0.55, 0.15, 0.05))
		draw_circle(Vector2(-2, 0), 3.5, Color(1, 0.5, 0.15))
		draw_circle(Vector2(3, 1), 2.0, Color(1, 0.7, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Il sarcofago antropoide, visto dall'alto: il volto d'oro col nemes a righe, le braccia
## incrociate, le ali di Iside dipinte sul petto e la colonna di geroglifici fino ai piedi.
func _draw_sarcophagus(p: Vector2) -> void:
	_shadow(p + Vector2(3, 4), 15.0, 26.0, 0.3)
	var wood := Color(0.78, 0.56, 0.22)
	var shape := PackedVector2Array([Vector2(p.x - 6, p.y - 22), Vector2(p.x + 6, p.y - 22), Vector2(p.x + 10, p.y - 15), Vector2(p.x + 11, p.y - 6), Vector2(p.x + 9, p.y + 8), Vector2(p.x + 7, p.y + 20), Vector2(p.x + 3, p.y + 22), Vector2(p.x - 3, p.y + 22), Vector2(p.x - 7, p.y + 20), Vector2(p.x - 9, p.y + 8), Vector2(p.x - 11, p.y - 6), Vector2(p.x - 10, p.y - 15)])
	_op(shape, wood, 1.0)
	# il nemes blu e oro attorno al volto
	_op(PackedVector2Array([Vector2(p.x - 8, p.y - 20), Vector2(p.x + 8, p.y - 20), Vector2(p.x + 9, p.y - 8), Vector2(p.x - 9, p.y - 8)]), LAPIS, 0.6)
	for k in range(4):
		draw_line(Vector2(p.x - 8.5, p.y - 18 + k * 3), Vector2(p.x + 8.5, p.y - 18 + k * 3), YELLOW_OCHRE, 0.7)
	_op(_ell(Vector2(p.x, p.y - 15), 4.2, 5.0), Color(0.94, 0.74, 0.32), 0.6)
	draw_line(Vector2(p.x - 2.8, p.y - 16), Vector2(p.x - 0.8, p.y - 16), OUTL, 0.6)
	draw_line(Vector2(p.x + 0.8, p.y - 16), Vector2(p.x + 2.8, p.y - 16), OUTL, 0.6)
	draw_line(Vector2(p.x, p.y - 10), Vector2(p.x, p.y - 7), Color(0.3, 0.2, 0.1), 1.2)          # la barba
	# collare e braccia incrociate con il pastorale e il flagello
	draw_arc(Vector2(p.x, p.y - 8), 7.5, 0.2, PI - 0.2, 10, TURQ, 2.0)
	draw_line(Vector2(p.x - 7, p.y - 3), Vector2(p.x + 5, p.y + 1), Color(0.94, 0.74, 0.32), 1.6)
	draw_line(Vector2(p.x + 7, p.y - 3), Vector2(p.x - 5, p.y + 1), Color(0.94, 0.74, 0.32), 1.6)
	# le ali sul petto
	for sx in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(p.x, p.y + 3), Vector2(p.x + 9 * sx, p.y + 1), Vector2(p.x + 8 * sx, p.y + 5), Vector2(p.x + 1 * sx, p.y + 7)])
		draw_colored_polygon(wing, Color(RED_OCHRE, 0.9))
		draw_line(Vector2(p.x + 1 * sx, p.y + 4.5), Vector2(p.x + 8 * sx, p.y + 3), YELLOW_OCHRE, 0.6)
	# la colonna di geroglifici fino ai piedi
	draw_rect(Rect2(p.x - 2.5, p.y + 8, 5, 12), Color(0.95, 0.88, 0.7))
	for k in range(3):
		draw_circle(Vector2(p.x, p.y + 10 + k * 3.8), 0.9, [LAPIS, RED_OCHRE, MALACHITE][k])


func _ell(c: Vector2, rx: float, ry: float, n: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Un vaso d'argilla col collo stretto, le fasce dipinte e un riflesso.
func _draw_urn(p: Vector2, s: float) -> void:
	_shadow(p + Vector2(1, 0.5), 5.5 * s, 2.2 * s, 0.3)
	draw_set_transform(p, 0.0, Vector2(s, s))
	var clay := Color(0.66, 0.4, 0.21)
	var body := PackedVector2Array([Vector2(-2.5, -11), Vector2(2.5, -11), Vector2(3, -8.5), Vector2(5, -6), Vector2(4.6, -2), Vector2(2.4, 0), Vector2(-2.4, 0), Vector2(-4.6, -2), Vector2(-5, -6), Vector2(-3, -8.5)])
	_op(body, clay, 0.7)
	_op(PackedVector2Array([Vector2(-3.6, -12.5), Vector2(3.6, -12.5), Vector2(3.2, -11), Vector2(-3.2, -11)]), clay.darkened(0.25), 0.6)
	draw_line(Vector2(-4.6, -5.5), Vector2(4.6, -5.5), TURQ, 1.2)
	draw_line(Vector2(-4.2, -3.5), Vector2(4.2, -3.5), RED_OCHRE, 0.8)
	draw_line(Vector2(-3.2, -8.0), Vector2(-3.8, -4.0), Color(1, 1, 1, 0.22), 1.0)
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
		# solo il bagliore della fiamma: la luce sul pavimento la fanno le luci vere (Atmos)
		for tc in decor.torches:
			_halo(tc + Vector2(0, -6), 12.0 + sin(tt * 9.0 + tc.x) * 1.5, Color(1, 0.6, 0.25, 0.5))
		for pr in decor.props:
			if pr[0] == "brazier" and not decor.cold_braziers:
				_halo(pr[1] + Vector2(0, -16), 16.0 + sin(tt * 8.0 + pr[1].y) * 2.0, Color(1, 0.55, 0.2, 0.55))
		# gli spiriti del Ka vagano piano e pulsano: azzurri i più, qualcuno d'oro
		for w in decor.wisps:
			var ph: float = w[1]
			var wp: Vector2 = w[0] + Vector2(sin(tt * 0.45 + ph) * 18.0, cos(tt * 0.33 + ph * 1.3) * 10.0 - fmod(tt * 3.0 + ph * 9.0, 12.0))
			var pulse := 0.6 + 0.4 * sin(tt * 2.2 + ph * 3.0)
			var wc := Color(0.45, 0.85, 1.0) if w[2] else Color(1.0, 0.8, 0.4)
			_halo(wp, 11.0 * pulse + 4.0, Color(wc, 0.5 * pulse))
			_halo(wp, 3.0, Color(wc.lightened(0.4), 1.0 * pulse))

	func _halo(p: Vector2, r: float, c: Color) -> void:
		draw_texture_rect(tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, c)


## Le fiamme delle torce e dei bracieri: le uniche cose dell'arredamento che si muovono, in un
## nodo a parte che si ridisegna a ogni fotogramma (pochi triangoli).
class Flames extends Node2D:
	var decor: Node2D

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for tc in decor.torches:
			_flame(tc + Vector2(0, -2), 1.0)
		for pr in decor.props:
			if pr[0] == "brazier" and not decor.cold_braziers:
				_flame(pr[1] + Vector2(0, -12), 1.4)

	func _flame(p: Vector2, s: float) -> void:
		var tt: float = decor.t
		var f := sin(tt * 13.0 + p.x) * 0.8 + sin(tt * 7.0 + p.y) * 0.6
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3.5, 0) * s, p + Vector2(3.5, 0) * s, p + Vector2(f, -10.0 - f) * s]), Color(1, 0.55, 0.15))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-1.8, 0) * s, p + Vector2(1.8, 0) * s, p + Vector2(f * 0.5, -6.0) * s]), Color(1, 0.92, 0.55))


## Le colonne papiriformi della stanza: fusto di arenaria in luce da sinistra, scanalature,
## un cartiglio dipinto, le fasce colorate sotto il capitello a boccio di papiro e l'abaco in cima.
## Sono un nodo a parte, sopra l'arredamento del pavimento: Ammit le fa crollare, e quando una
## crolla si ridisegna solo questo.
class Pillars extends Node2D:
	var list: Array = []                  # lo stesso Array delle colonne della stanza (game.gd)
	const OUTL := Color(0.12, 0.08, 0.05)
	const STONE := Color(0.8, 0.64, 0.42)
	const STONE_D := Color(0.55, 0.4, 0.24)

	func _draw() -> void:
		for p in list:
			_column(p)

	func _op(pts: PackedVector2Array, fill: Color, w: float = 1.0) -> void:
		draw_colored_polygon(pts, fill)
		var c := pts.duplicate()
		c.append(pts[0])
		draw_polyline(c, OUTL, w)

	func _column(p: Vector2) -> void:
		# ombra a terra, verso destra e in basso (la luce viene dalle torce in alto)
		draw_set_transform(p + Vector2(6, 6), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# base: un disco di pietra
		draw_set_transform(p + Vector2(0, 4), 0.0, Vector2(1.0, 0.38))
		draw_circle(Vector2.ZERO, 16.5, OUTL)
		draw_circle(Vector2.ZERO, 15.5, STONE_D)
		draw_circle(Vector2(-1, -2), 13.5, STONE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# il fusto, più chiaro a sinistra (vertici colorati: una sfumatura senza texture)
		var top := p.y - 40.0
		var bot := p.y + 3.0
		var l := p.x - 11.0
		var rr := p.x + 11.0
		draw_rect(Rect2(l - 1, top, 24, bot - top), OUTL)
		var mid := p.x - 3.0
		draw_polygon(PackedVector2Array([Vector2(l, top), Vector2(mid, top), Vector2(mid, bot), Vector2(l, bot)]),
			PackedColorArray([STONE.lightened(0.12), STONE, STONE, STONE.lightened(0.12)]))
		draw_polygon(PackedVector2Array([Vector2(mid, top), Vector2(rr, top), Vector2(rr, bot), Vector2(mid, bot)]),
			PackedColorArray([STONE, STONE_D, STONE_D, STONE]))
		for fx in [-6.0, -1.0, 4.0, 8.0]:
			draw_line(Vector2(p.x + fx, top + 2), Vector2(p.x + fx, bot - 1), Color(STONE_D, 0.6), 0.8)
		# il cartiglio dipinto sul fusto
		var cart := Rect2(p.x - 4.5, p.y - 30, 9, 20)
		draw_rect(cart, Color(0.95, 0.9, 0.75))
		draw_rect(cart, RED_OCHRE, false, 1.0)
		draw_line(Vector2(cart.position.x, cart.end.y + 1.5), Vector2(cart.end.x, cart.end.y + 1.5), RED_OCHRE, 1.0)
		draw_circle(Vector2(p.x, p.y - 26), 1.6, RED_OCHRE)                           # il sole
		draw_line(Vector2(p.x - 2.5, p.y - 21.5), Vector2(p.x + 2.5, p.y - 21.5), LAPIS, 1.2)   # l'acqua
		draw_line(Vector2(p.x - 2.0, p.y - 17.5), Vector2(p.x + 2.0, p.y - 15.5), MALACHITE, 1.2)
		draw_circle(Vector2(p.x, p.y - 13), 1.2, LAPIS)
		# le fasce colorate sotto il capitello
		var cols := [LAPIS, YELLOW_OCHRE, RED_OCHRE, YELLOW_OCHRE, MALACHITE]
		for k in range(cols.size()):
			draw_rect(Rect2(l, top - 1.0 - k * 1.8, 22, 1.8), cols[k])
		# il capitello a boccio di papiro: si allarga e si richiude, verde con i sepali d'oro
		var cy := top - 9.0
		var cap := PackedVector2Array([Vector2(l, cy + 1), Vector2(l - 3, cy - 5), Vector2(l - 1, cy - 11), Vector2(rr + 1, cy - 11), Vector2(rr + 3, cy - 5), Vector2(rr, cy + 1)])
		_op(cap, Color(0.24, 0.52, 0.4))
		for k in range(5):
			var sx := l + 2.0 + k * 4.5
			draw_colored_polygon(PackedVector2Array([Vector2(sx - 2, cy + 0.5), Vector2(sx + 2, cy + 0.5), Vector2(sx, cy - 8)]), Color(YELLOW_OCHRE, 0.9))
		draw_line(Vector2(l - 2, cy - 5), Vector2(l + 6, cy - 9), Color(1, 1, 1, 0.2), 1.0)
		# l'abaco in cima
		_op(PackedVector2Array([Vector2(l - 1, cy - 11), Vector2(rr + 1, cy - 11), Vector2(rr + 1, cy - 16), Vector2(l - 1, cy - 16)]), STONE_D)
		draw_line(Vector2(l, cy - 15.5), Vector2(rr, cy - 15.5), STONE, 1.0)
