class_name DoorEmblem
## Gli emblemi delle ricompense (blocco 26): al posto della pallina colorata davanti alle porte e
## sopra le ricompense, una piccola stele di pietra con il simbolo del dio o della ricompensa.
## Ogni dio ha il suo segno (disco di Ra, occhio di Horus, sciacallo di Anubi, ibis-luna di Thoth...),
## così una porta si riconosce anche senza leggere e anche per chi distingue male i colori.
## Tutto in linee, cerchi e pochi poligoni: tre porte per stanza, sul telefono il disegno conta.

const OUTL := Color(0.08, 0.05, 0.03)
const STONE := Color(0.2, 0.15, 0.11)
const GOLD := Color(0.94, 0.72, 0.3)


## Il colore di una ricompensa (come Door.reward_color).
static func color_of(kind: String, god: String) -> Color:
	match kind:
		"boon":
			return Boons.god_color(god) if god != "" else GOLD
		"set":
			return Boons.god_color("set")
		"ka":
			return GOLD
		"lapis":
			return Restorations.LAPIS_COLOR.lightened(0.15)
		"heal":
			return Color(0.95, 0.35, 0.3)
		"boss":
			return Color(0.9, 0.3, 0.25)
		"guardian":
			return Color(0.45, 0.9, 0.4)
		"region", "desert":
			return Color(0.95, 0.8, 0.45)
		"shop":
			return Color(0.6, 0.85, 0.95)
		"ptah":
			return Incisions.COLOR
	return Color(0.9, 0.9, 1.0)


## La stele: base squadrata, cima tonda, bordo d'oro, campo del colore della ricompensa e il simbolo.
## `c` è il centro del simbolo; `s` la scala (1 = alta circa 26 px).
static func draw_stele(ci: CanvasItem, kind: String, god: String, c: Vector2, s: float, t: float) -> void:
	var col := color_of(kind, god)
	var w := 9.0 * s
	var top := c.y - 6.0 * s
	var bot := c.y + 11.0 * s
	# alone a terra e luce che pulsa
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	ci.draw_circle(c, 14.0 * s, Color(col, 0.10 + 0.08 * pulse))
	var shape := PackedVector2Array()
	shape.append(Vector2(c.x - w, bot))
	shape.append(Vector2(c.x - w, top))
	for i in range(1, 12):
		var a := PI + PI * i / 12.0
		shape.append(Vector2(c.x + cos(a) * w, top + sin(a) * w))
	shape.append(Vector2(c.x + w, top))
	shape.append(Vector2(c.x + w, bot))
	var outer := PackedVector2Array()
	for p in shape:
		outer.append(c + (p - c) * 1.16)
	ci.draw_colored_polygon(outer, OUTL)
	ci.draw_colored_polygon(shape, STONE)
	# campo colorato all'interno
	var inner := PackedVector2Array()
	for p in shape:
		inner.append(c + (p - c) * 0.8)
	ci.draw_colored_polygon(inner, Color(col.darkened(0.55), 0.95))
	var rim := shape.duplicate()
	rim.append(shape[0])
	ci.draw_polyline(rim, Color(GOLD, 0.85), 1.0 * s)
	# il gradino della base
	ci.draw_rect(Rect2(c.x - w * 1.3, bot, w * 2.6, 2.4 * s), OUTL)
	ci.draw_rect(Rect2(c.x - w * 1.2, bot + 0.3 * s, w * 2.4, 1.6 * s), GOLD.darkened(0.3))
	draw_icon(ci, kind, god, c + Vector2(0, -1.0 * s), s, col.lightened(0.45))


## Il medaglione (le ricompense a terra): disco scuro, anello del colore e il simbolo.
static func draw_medal(ci: CanvasItem, kind: String, god: String, c: Vector2, s: float) -> void:
	var col := color_of(kind, god)
	ci.draw_circle(c, 10.0 * s, OUTL)
	ci.draw_circle(c, 9.0 * s, col.darkened(0.5))
	ci.draw_arc(c, 8.6 * s, 0.0, TAU, 28, GOLD, 1.3 * s)
	ci.draw_arc(c, 6.9 * s, 0.0, TAU, 24, Color(col, 0.6), 0.8 * s)
	draw_icon(ci, kind, god, c, s * 0.95, col.lightened(0.5))


## Il simbolo da solo.
static func draw_icon(ci: CanvasItem, kind: String, god: String, c: Vector2, s: float, col: Color) -> void:
	match kind:
		"boon":
			_god(ci, god, c, s, col)
		"set":
			_god(ci, "set", c, s, col)
		"ka":
			_ka(ci, c, s, col)
		"lapis":
			Restorations.draw_gem(ci, c, 0.8 * s)
		"heal":
			_ankh(ci, c, s, col)
		"shop":
			# la barca del Traghettatore
			var hull := PackedVector2Array()
			for i in range(11):
				var x := (i - 5) * 1.1 * s
				hull.append(c + Vector2(x, 2.0 * s + (x * x) / (24.0 * s) * -1.0 + 1.0 * s))
			ci.draw_polyline(hull, col, 1.6 * s)
			ci.draw_line(c + Vector2(-5.5, 1.0) * s, c + Vector2(-6.5, -1.4) * s, col, 1.2 * s)
			ci.draw_line(c + Vector2(5.5, 1.0) * s, c + Vector2(6.5, -1.4) * s, col, 1.2 * s)
			ci.draw_line(c + Vector2(0, 2.0) * s, c + Vector2(0, -5.0) * s, col, 1.0 * s)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.4, -5.0) * s, c + Vector2(4.0, -1.0) * s, c + Vector2(0.4, -0.6) * s]), Color(col, 0.8))
		"boss":
			# fauci del divoratore
			ci.draw_arc(c + Vector2(0, -0.5) * s, 5.0 * s, PI * 1.1, PI * 1.9, 12, col, 1.5 * s)
			ci.draw_arc(c + Vector2(0, 0.5) * s, 5.0 * s, PI * 0.1, PI * 0.9, 12, col, 1.5 * s)
			for i in range(4):
				var x := (i - 1.5) * 2.2 * s
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 0.8 * s, -3.6 * s), c + Vector2(x + 0.8 * s, -3.6 * s), c + Vector2(x, -1.0 * s)]), col)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 0.8 * s, 3.6 * s), c + Vector2(x + 0.8 * s, 3.6 * s), c + Vector2(x, 1.0 * s)]), col)
		"guardian":
			# l'ureo: il cobra col cappuccio
			var body := PackedVector2Array([c + Vector2(-1.6, 5.0) * s, c + Vector2(1.6, 5.0) * s, c + Vector2(1.2, -0.5) * s, c + Vector2(3.4, -2.8) * s, c + Vector2(2.0, -5.0) * s, c + Vector2(0, -5.6) * s, c + Vector2(-2.0, -5.0) * s, c + Vector2(-3.4, -2.8) * s, c + Vector2(-1.2, -0.5) * s])
			ci.draw_colored_polygon(body, col)
			ci.draw_circle(c + Vector2(0, -3.6) * s, 0.7 * s, OUTL)
		"region", "desert":
			# l'akhet: il sole tra due monti
			ci.draw_circle(c + Vector2(0, -0.6) * s, 2.6 * s, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6.0, 4.0) * s, c + Vector2(-3.4, -1.0) * s, c + Vector2(-1.0, 4.0) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(1.0, 4.0) * s, c + Vector2(3.4, -1.0) * s, c + Vector2(6.0, 4.0) * s]), col)
		"ptah":
			# il martello di Ptah sull'incudine
			ci.draw_line(c + Vector2(-3.6, 3.6) * s, c + Vector2(2.4, -2.4) * s, col, 1.4 * s)
			var hd := PackedVector2Array([c + Vector2(0.6, -5.4) * s, c + Vector2(5.4, -0.6) * s, c + Vector2(3.8, 1.0) * s, c + Vector2(-1.0, -3.8) * s])
			ci.draw_colored_polygon(hd, col)
			ci.draw_rect(Rect2(c + Vector2(-5.0, 4.0) * s, Vector2(10.0, 1.8) * s), col)
			ci.draw_circle(c + Vector2(4.8, -4.8) * s, 0.9 * s, Color(1, 0.95, 0.7))
		_:
			_ankh(ci, c, s, col)


static func _ka(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	# le due braccia alzate del Ka
	var w := 1.5 * s
	for sx in [-1.0, 1.0]:
		ci.draw_polyline(PackedVector2Array([c + Vector2(0.8 * sx, 3.6) * s, c + Vector2(4.6 * sx, 3.6) * s, c + Vector2(4.6 * sx, -4.6) * s]), col, w)
		ci.draw_line(c + Vector2(4.6 * sx, -4.6) * s, c + Vector2(5.6 * sx, -4.0) * s, col, w * 0.8)
	ci.draw_line(c + Vector2(-0.8, 3.6) * s, c + Vector2(0.8, 3.6) * s, col, w)


static func _ankh(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_arc(c + Vector2(0, -3.0) * s, 2.2 * s, 0.0, TAU, 14, col, 1.3 * s)
	ci.draw_line(c + Vector2(0, -0.8) * s, c + Vector2(0, 5.0) * s, col, 1.4 * s)
	ci.draw_line(c + Vector2(-3.4, 0.4) * s, c + Vector2(3.4, 0.4) * s, col, 1.4 * s)


## Il segno di ogni dio.
static func _god(ci: CanvasItem, god: String, c: Vector2, s: float, col: Color) -> void:
	var w := 1.3 * s
	match god:
		"ra":
			# il disco solare con l'ureo
			ci.draw_circle(c + Vector2(0, -0.6) * s, 3.6 * s, col)
			ci.draw_arc(c + Vector2(0, -0.6) * s, 4.8 * s, PI * 0.2, PI * 0.8, 10, col, w)
			ci.draw_line(c + Vector2(0, 3.0) * s, c + Vector2(0, 5.0) * s, col, w)
		"horus":
			# l'occhio udjat
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for i in range(9):
				var x := (i - 4) * 1.3 * s
				up.append(c + Vector2(x, -1.0 * s - sin(PI * i / 8.0) * 2.4 * s))
				dn.append(c + Vector2(x, -1.0 * s + sin(PI * i / 8.0) * 1.4 * s))
			ci.draw_polyline(up, col, w)
			ci.draw_polyline(dn, col, w)
			ci.draw_circle(c + Vector2(0, -1.2) * s, 1.3 * s, col)
			ci.draw_line(c + Vector2(-0.4, 0.6) * s, c + Vector2(-1.4, 4.6) * s, col, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(1.2, 0.4) * s, c + Vector2(3.2, 3.2) * s, c + Vector2(4.6, 2.6) * s]), col, w)
		"anubi":
			# lo sciacallo accucciato: orecchie alte e muso lungo
			var head := PackedVector2Array([c + Vector2(-3.6, 4.6) * s, c + Vector2(-3.0, -1.2) * s, c + Vector2(-2.6, -5.6) * s, c + Vector2(-1.4, -2.0) * s, c + Vector2(-0.6, -5.6) * s, c + Vector2(0.4, -1.6) * s, c + Vector2(4.8, -0.4) * s, c + Vector2(4.6, 0.8) * s, c + Vector2(0.6, 1.2) * s, c + Vector2(1.0, 4.6) * s])
			ci.draw_colored_polygon(head, col)
			ci.draw_circle(c + Vector2(-0.6, -0.6) * s, 0.55 * s, OUTL)
		"sekhmet":
			# la leonessa: muso con il disco sopra
			ci.draw_circle(c + Vector2(0, -4.0) * s, 1.8 * s, col)
			var face := PackedVector2Array([c + Vector2(-3.6, -1.6) * s, c + Vector2(-2.6, -2.8) * s, c + Vector2(2.6, -2.8) * s, c + Vector2(3.6, -1.6) * s, c + Vector2(3.0, 2.6) * s, c + Vector2(0, 4.8) * s, c + Vector2(-3.0, 2.6) * s])
			ci.draw_colored_polygon(face, col)
			ci.draw_line(c + Vector2(-1.6, 0.2) * s, c + Vector2(-0.6, 0.4) * s, OUTL, 0.8 * s)
			ci.draw_line(c + Vector2(1.6, 0.2) * s, c + Vector2(0.6, 0.4) * s, OUTL, 0.8 * s)
		"thoth":
			# la luna di Thoth: falce che regge il disco
			ci.draw_arc(c + Vector2(0, 0.4) * s, 4.4 * s, PI * 0.05, PI * 0.95, 14, col, 1.8 * s)
			ci.draw_circle(c + Vector2(0, -0.6) * s, 2.6 * s, col)
		"bastet":
			# la gatta: testa con orecchie a punta
			var cat := PackedVector2Array([c + Vector2(-4.0, -4.6) * s, c + Vector2(-1.6, -2.4) * s, c + Vector2(1.6, -2.4) * s, c + Vector2(4.0, -4.6) * s, c + Vector2(4.0, 1.2) * s, c + Vector2(0, 4.6) * s, c + Vector2(-4.0, 1.2) * s])
			ci.draw_colored_polygon(cat, col)
			ci.draw_line(c + Vector2(-2.4, -0.4) * s, c + Vector2(-1.0, -0.4) * s, OUTL, 0.9 * s)
			ci.draw_line(c + Vector2(1.0, -0.4) * s, c + Vector2(2.4, -0.4) * s, OUTL, 0.9 * s)
		"sobek":
			# le fauci del coccodrillo, di lato
			ci.draw_line(c + Vector2(-5.0, -1.0) * s, c + Vector2(5.0, -2.6) * s, col, 1.5 * s)
			ci.draw_line(c + Vector2(-5.0, 1.0) * s, c + Vector2(5.0, 2.0) * s, col, 1.5 * s)
			for i in range(5):
				var x := -3.6 + i * 2.0
				ci.draw_line(c + Vector2(x, -1.4 - i * 0.24) * s, c + Vector2(x + 0.6, 0.0) * s, col, 0.9 * s)
				ci.draw_line(c + Vector2(x + 1.0, 1.4 + i * 0.15) * s, c + Vector2(x + 0.4, 0.2) * s, col, 0.9 * s)
			ci.draw_circle(c + Vector2(-4.0, -2.6) * s, 1.0 * s, col)
		"iside":
			# il trono, il geroglifo del suo nome
			var th := PackedVector2Array([c + Vector2(-4.0, 4.6) * s, c + Vector2(-4.0, -4.6) * s, c + Vector2(-1.0, -4.6) * s, c + Vector2(-1.0, 0.4) * s, c + Vector2(4.0, 0.4) * s, c + Vector2(4.0, 4.6) * s])
			ci.draw_colored_polygon(th, col)
			ci.draw_rect(Rect2(c + Vector2(-3.0, 1.6) * s, Vector2(2.0, 2.0) * s), OUTL)
		"nefti":
			# la casa con il cesto sopra (il suo nome)
			ci.draw_arc(c + Vector2(0, -3.0) * s, 3.6 * s, 0.0, PI, 12, col, 1.6 * s)
			ci.draw_rect(Rect2(c + Vector2(-4.0, -0.6) * s, Vector2(8.0, 5.4) * s), col, false, 1.4 * s)
			ci.draw_rect(Rect2(c + Vector2(-1.2, 1.6) * s, Vector2(2.4, 3.2) * s), col)
		"shu":
			# la piuma di struzzo
			var f := PackedVector2Array([c + Vector2(0.2, 5.0) * s, c + Vector2(-1.6, 1.0) * s, c + Vector2(-2.2, -3.0) * s, c + Vector2(-0.6, -5.6) * s, c + Vector2(2.2, -4.2) * s, c + Vector2(1.6, -0.6) * s])
			ci.draw_colored_polygon(f, col)
			ci.draw_line(c + Vector2(0.2, 5.0) * s, c + Vector2(0.4, -4.6) * s, OUTL, 0.7 * s)
		"set":
			# lo scettro di Set: testa dell'animale e coda biforcuta
			ci.draw_line(c + Vector2(0, -3.0) * s, c + Vector2(0, 4.0) * s, col, w)
			ci.draw_line(c + Vector2(0, 4.0) * s, c + Vector2(-1.6, 5.4) * s, col, w)
			ci.draw_line(c + Vector2(0, 4.0) * s, c + Vector2(1.6, 5.4) * s, col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.8, -2.6) * s, c + Vector2(4.0, -3.6) * s, c + Vector2(3.6, -2.2) * s, c + Vector2(0.8, -1.6) * s]), col)
			ci.draw_line(c + Vector2(-0.4, -2.8) * s, c + Vector2(-1.0, -5.6) * s, col, w)
			ci.draw_line(c + Vector2(0.6, -3.0) * s, c + Vector2(0.6, -5.8) * s, col, w)
		"sfinge":
			var hd := PackedVector2Array([c + Vector2(-4.6, 4.6) * s, c + Vector2(-3.0, -2.6) * s, c + Vector2(0, -4.8) * s, c + Vector2(3.0, -2.6) * s, c + Vector2(4.6, 4.6) * s])
			ci.draw_colored_polygon(hd, col)
			ci.draw_circle(c + Vector2(0, 0.2) * s, 1.8 * s, OUTL)
		_:
			# doppio o sconosciuto: due dischi intrecciati
			ci.draw_arc(c + Vector2(-1.8, 0) * s, 3.0 * s, 0.0, TAU, 14, col, w)
			ci.draw_arc(c + Vector2(1.8, 0) * s, 3.0 * s, 0.0, TAU, 14, col, w)
