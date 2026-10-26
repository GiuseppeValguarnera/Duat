extends Node2D
## Il serdab: nelle tombe egizie, una stanzetta murata e senza porta che custodiva la statua
## del Ka del defunto. Qui è la stanza segreta della discesa: a stanza ripulita, ogni tanto,
## un tratto del muro in alto ha una crepa e un geroglifico storto (e se ti avvicini cade un
## filo di polvere). Tre colpi d'arma e il muro crolla: dietro c'è il serdab, buio, con le
## pareti piene di geroglifici, la statua del Ka e un piccolo tesoro (Ka, a volte un cuore).
## Niente trappole e niente nemici. Si esce dallo stesso buco e si prosegue come prima.
##
## Il nodo sta sulla crepa (sul bordo basso del muro in alto); la stanzetta è disegnata sopra
## il muro, fuori dalla stanza: quando il muro crolla la telecamera può salire fin lassù.

const HOLE_W := 30.0                    ## larghezza del varco nel muro
const SIZE := Vector2(220, 170)         ## la stanzetta
const HITS := 3                         ## colpi per far crollare il muro
const DARK := Color(0.58, 0.55, 0.65)     ## quanto si fa buio dentro
const INK := Color(0.62, 0.5, 0.3)      ## colore dei geroglifici incisi
const SAND := Color(0.78, 0.66, 0.46)
const KA_MIN := 10                       ## il Ka del serdab, quando il premio è il Ka: sempre meno di una porta del tesoro (25), è un di più
const KA_MAX := 15

## Iscrizioni sulla statua: formule d'offerta e maledizioni come quelle vere delle tombe.
## Parlano "del re" in generale: nessun indizio sulla storia.
const INSCRIPTIONS := [
	"Un'offerta che il re dà: mille pani e mille brocche di birra per il Ka del signore di questa casa.",
	"O tu che passi davanti a questa statua, di' «pane e birra» per il Ka del re.",
	"Il re è un falco d'oro. Il re vola verso il cielo, e il cielo lo accoglie.",
	"Chi tocca questa immagine, il coccodrillo lo afferri nell'acqua e il serpente sulla terra.",
	"Lo scultore Ptahmose ha fatto questa immagine del re. Sia ricordato il suo lavoro.",
	"Questa è la casa del Ka. Il re siede qui e guarda il mondo dei vivi da una fessura.",
]

var g: Game
var hits := 0
var open := false
var broken := false                     ## per il gruppo "breakables" (vero quando il muro è crollato)
var t := 0.0
var dust_t := 0.0
var shake_t := 0.0                      ## il muro trema un poco a ogni colpo
var inside := false
var visited := false
var treasures: Array = []               ## [tipo, posizione nel mondo, quantità, preso]
var glyphs: Array = []                  ## [tipo, posizione locale, scala]
var inscription := ""
var shade: CanvasModulate
var lit := Color.WHITE                  ## la penombra della stanza, a cui si torna uscendo
var rng := RandomNumberGenerator.new()


func setup(game: Game, x: float) -> void:
	g = game
	position = Vector2(x, g.TOP - 4.0)
	rng.seed = randi()
	inscription = Lang.t(INSCRIPTIONS[rng.randi() % INSCRIPTIONS.size()])
	add_to_group("breakables")
	# le pareti della stanzetta: righe di geroglifici in alto e colonne ai lati
	var top_y := _local(Vector2(0, -SIZE.y)).y
	for row in range(2):
		var gx := -SIZE.x / 2.0 + 14.0
		while gx < SIZE.x / 2.0 - 10.0:
			glyphs.append([rng.randi() % 8, Vector2(gx, top_y + 10.0 + row * 13.0), rng.randf_range(0.85, 1.1)])
			gx += rng.randf_range(11.0, 15.0)
	for side in [-1.0, 1.0]:
		var gy := top_y + 44.0
		while gy < -(g.TOP - 4.0) - 14.0:
			glyphs.append([rng.randi() % 8, Vector2(side * (SIZE.x / 2.0 - 8.0), gy), rng.randf_range(0.8, 1.0)])
			gy += rng.randf_range(13.0, 17.0)


## Da coordinate del mondo a coordinate del nodo.
func _local(world_pos: Vector2) -> Vector2:
	return world_pos - position


## Il colpo dell'arma (chiamato da player.gd come per le giare). Il fuoco non conta.
func smash(delay: float = 0.0) -> void:
	if open or delay > 0.0:
		return
	hits += 1
	shake_t = 0.18
	Fx.shake(1.5 + hits)
	Sfx.play("hit", 0.1)
	Fx.burst(global_position + Vector2(0, -6), SAND, 8 + hits * 4, 60.0)
	if hits >= HITS:
		_collapse()


func _collapse() -> void:
	open = true
	broken = true
	remove_from_group("breakables")
	Sfx.play("jar_break", 0.0)
	Fx.shake(5.0)
	Fx.burst(global_position + Vector2(0, -14), SAND, 34, 120.0)
	Fx.burst(global_position + Vector2(0, -14), Color(0.35, 0.28, 0.2), 18, 80.0)
	# il muro in alto si apre: al posto del pezzo unico due pezzi ai lati del varco
	var r := g.ROOM
	var hx := position.x
	if g.top_wall != null and is_instance_valid(g.top_wall):
		g.top_wall.queue_free()
	g.top_wall = null
	g.rooms.solid(Rect2(r.position.x, r.position.y, hx - HOLE_W / 2.0 - r.position.x, g.TOP))
	g.rooms.solid(Rect2(hx + HOLE_W / 2.0, r.position.y, r.end.x - hx - HOLE_W / 2.0, g.TOP))
	# le pareti della stanzetta, oltre il muro
	var x0 := hx - SIZE.x / 2.0
	var x1 := hx + SIZE.x / 2.0
	g.rooms.solid(Rect2(x0 - 16.0, -SIZE.y - 16.0, 16.0, SIZE.y + 16.0))
	g.rooms.solid(Rect2(x1, -SIZE.y - 16.0, 16.0, SIZE.y + 16.0))
	g.rooms.solid(Rect2(x0 - 16.0, -SIZE.y - 16.0, SIZE.x + 32.0, 16.0 + 24.0))   # la parete in alto, con lo spessore delle incisioni
	g.rooms.solid(Rect2(hx - 14.0, -SIZE.y + 30.0, 28.0, 16.0))                   # la statua del Ka
	# la telecamera può salire fin dentro
	if g.player != null and is_instance_valid(g.player):
		var cam: Camera2D = g.player.get_node("Camera")
		cam.limit_top = int(-SIZE.y - 16.0)
	# il tesoro: un solo premio, a sorte, così aprire il muro è una sorpresa. Un cuore, qualche
	# lapislazzuli ai piedi della statua oppure un po' di Ka sparso (più di una porta del tesoro,
	# perché trovare il serdab deve valere la pena)
	match rng.randi_range(0, 2):
		0:
			treasures.append(["heart", Vector2(hx + rng.randf_range(-30, 30), -SIZE.y * 0.42), 10.0, false])
		1:
			treasures.append(["lapis", Vector2(hx + rng.randf_range(-20, 20), -SIZE.y * 0.6), rng.randi_range(2, 3), false])
		_:
			var total := roundi(rng.randi_range(KA_MIN, KA_MAX) * Run.treasure_mult())
			var coins := 3
			for i in range(coins):
				var at := Vector2(hx + (i - 1) * 34.0 + rng.randf_range(-6, 6), -SIZE.y * 0.42 + rng.randf_range(-10, 14))
				treasures.append(["ka", at, int(total / float(coins)) + (total - int(total / float(coins)) * coins if i == 0 else 0), false])
	# il buio dentro
	# il buio dentro: si scurisce la penombra della stanza (una sola per scena, in Godot)
	var found := g.world.find_children("*", "CanvasModulate", true, false)
	shade = null if found.is_empty() else found[0] as CanvasModulate
	if shade == null:
		shade = CanvasModulate.new()
		shade.color = Color.WHITE
		add_child(shade)
	lit = shade.color


func _process(delta: float) -> void:
	t += delta
	shake_t = maxf(0.0, shake_t - delta)
	var p = g.player if g != null else null
	if p == null or not is_instance_valid(p):
		return
	if not open:
		# avvicinandosi alla crepa cade un filo di polvere: l'indizio per chi guarda bene
		if p.global_position.distance_to(global_position) < 80.0:
			dust_t -= delta
			if dust_t <= 0.0:
				dust_t = rng.randf_range(0.5, 1.1)
				Fx.burst(global_position + Vector2(rng.randf_range(-6, 6), -26.0), SAND, 3, 22.0)
		queue_redraw()
		return
	var now_inside: bool = p.global_position.y < 4.0
	if now_inside != inside:
		inside = now_inside
		shade.create_tween().tween_property(shade, "color", lit * DARK if inside else lit, 0.45)
		if inside and not visited:
			visited = true
			Challenges.on_serdab()
			Sfx.play("soul", 0.0)
			g._banner(Lang.t("Un serdab"), inscription, Color(0.85, 0.75, 0.55), 4.5)
	for loot in treasures:
		if loot[3] or p.global_position.distance_to(loot[1]) > 15.0:
			continue
		loot[3] = true
		if loot[0] == "ka":
			Run.ka += int(loot[2])
			Sfx.play("pickup", 0.1)
			Fx.float_text(loot[1], Lang.t("+%d Ka") % int(loot[2]), Color(0.94, 0.72, 0.3))
			Fx.burst(loot[1] + Vector2(0, -4), Color(0.95, 0.75, 0.3), 10, 60.0)
		elif loot[0] == "lapis":
			Restorations.gain(int(loot[2]), loot[1])
		else:
			p.heal(float(loot[2]))
			Sfx.play("pickup", 0.1)
			Fx.burst(loot[1] + Vector2(0, -4), Color(0.95, 0.3, 0.3), 10, 60.0)
	queue_redraw()


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	var jitter := Vector2(rng.randf_range(-1, 1), 0) * (shake_t * 10.0)
	if not open:
		_draw_crack(jitter)
		return
	_draw_chamber()
	_draw_hole()


## La crepa sulla faccia del muro e un geroglifico storto, inclinato come se fosse scivolato.
func _draw_crack(off: Vector2) -> void:
	var c := Color(0.16, 0.11, 0.07)
	# Occhio Udjat: la crepa brilla d'oro, si vede da lontano
	if Run.amulet == "udjat":
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		draw_circle(Vector2(0, -12) + off, 18.0 + pulse * 4.0, Color(1.0, 0.82, 0.4, 0.12 + 0.1 * pulse))
		UiStyle.star4(self, Vector2(6, -24) + off, 3.0 + pulse * 2.0, Color(1.0, 0.9, 0.5, 0.8))
	var pts := PackedVector2Array([Vector2(1, 2), Vector2(-3, -6), Vector2(2, -12), Vector2(-2, -19), Vector2(3, -27)])
	for i in range(pts.size()):
		pts[i] += off
	draw_polyline(pts, c, 1.6)
	draw_line(pts[1], pts[1] + Vector2(-7, -3), c, 1.0)
	draw_line(pts[2], pts[2] + Vector2(6, -2), c, 1.0)
	draw_line(pts[3], pts[3] + Vector2(-5, -5), c, 1.0)
	# dopo i colpi la crepa si allarga
	if hits >= 1:
		draw_line(pts[0] + Vector2(1, 0), pts[4] + Vector2(1, 0), Color(0.1, 0.07, 0.05), 1.0)
	if hits >= 2:
		draw_line(pts[2], pts[2] + Vector2(-9, 6), c, 1.2)
		draw_line(pts[3], pts[3] + Vector2(8, 4), c, 1.2)
	draw_set_transform(Vector2(-11, -15) + off, 0.45, Vector2.ONE)
	_glyph(1, Vector2.ZERO, 1.0, Color(0.3, 0.2, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hole() -> void:
	var dark := Color(0.05, 0.04, 0.04)
	var top := -(g.TOP - 4.0)
	draw_rect(Rect2(-HOLE_W / 2.0, top, HOLE_W, g.TOP), dark)
	# bordi spezzati del muro
	var edge := Color(0.3, 0.22, 0.14)
	for i in range(5):
		var y := top + 8.0 + i * 11.0
		draw_rect(Rect2(-HOLE_W / 2.0 - 2.0, y, 4.0, 5.0), edge)
		draw_rect(Rect2(HOLE_W / 2.0 - 2.0, y + 4.0, 4.0, 5.0), edge)
	# macerie davanti al varco
	for k in range(7):
		var s := Vector2(-20.0 + k * 6.5, 4.0 + float((k * 7) % 5))
		draw_circle(s, 2.0 + (k % 3), Color(0.5, 0.38, 0.24))


func _draw_chamber() -> void:
	var top_y := _local(Vector2(0, -SIZE.y)).y
	var bottom := -(g.TOP - 4.0)
	var floor_rect := Rect2(-SIZE.x / 2.0, top_y, SIZE.x, bottom - top_y)
	# tutto attorno roccia: sopra il muro della stanza non c'è altro (niente vuoto blu)
	var rock := Color(0.09, 0.07, 0.06)
	draw_rect(Rect2(-position.x - 400.0, top_y - 400.0, g.ROOM.size.x + 800.0, bottom - top_y + 400.0), rock)
	draw_rect(floor_rect, Color(0.14, 0.1, 0.08))
	# pavimento: pietre scure
	var tile := 22.0
	var y := top_y
	while y < bottom:
		var x := -SIZE.x / 2.0
		while x < SIZE.x / 2.0:
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			draw_rect(Rect2(x + 1, y + 1, tile - 2, tile - 2), Color(0.27, 0.2, 0.15).darkened(n * 0.25))
			x += tile
		y += tile
	# le pareti: in alto una fascia incisa, ai lati pietra scura
	var wall := Color(0.17, 0.12, 0.09)
	draw_rect(Rect2(floor_rect.position.x - 16.0, top_y - 16.0, SIZE.x + 32.0, 16.0), wall.darkened(0.3))
	draw_rect(Rect2(floor_rect.position.x, top_y, SIZE.x, 36.0), Color(0.36, 0.27, 0.17))
	draw_rect(Rect2(floor_rect.position.x - 16.0, top_y - 16.0, 16.0, bottom - top_y + 16.0), wall)
	draw_rect(Rect2(floor_rect.end.x, top_y - 16.0, 16.0, bottom - top_y + 16.0), wall)
	draw_line(Vector2(floor_rect.position.x, top_y + 36.0), Vector2(floor_rect.end.x, top_y + 36.0), Color(0.2, 0.14, 0.09), 1.5)
	for gl in glyphs:
		_glyph(gl[0], gl[1], gl[2], INK)
	# la statua del Ka: il re seduto, con il segno del Ka (due braccia alzate) sopra la testa
	var sc := Vector2(0, top_y + 46.0)
	var stone := Color(0.55, 0.46, 0.34)
	draw_rect(Rect2(sc.x - 14.0, sc.y - 2.0, 28.0, 14.0), stone.darkened(0.25))       # il trono
	draw_rect(Rect2(sc.x - 7.0, sc.y - 18.0, 14.0, 20.0), stone)                    # il corpo
	draw_circle(sc + Vector2(0, -23.0), 5.0, stone)                                 # la testa
	draw_rect(Rect2(sc.x - 6.0, sc.y - 27.0, 12.0, 4.0), stone.darkened(0.15))       # il copricapo
	var arms := Color(0.75, 0.6, 0.35)
	draw_polyline(PackedVector2Array([sc + Vector2(-8, -36), sc + Vector2(-8, -30), sc + Vector2(8, -30), sc + Vector2(8, -36)]), arms, 2.0)
	draw_line(sc + Vector2(-8, -36), sc + Vector2(-6, -40), arms, 2.0)
	draw_line(sc + Vector2(8, -36), sc + Vector2(6, -40), arms, 2.0)
	# un filo di luce sulla statua, che pulsa piano
	var glow := 0.08 + 0.04 * sin(t * 2.0)
	draw_circle(sc + Vector2(0, -14), 26.0, Color(1.0, 0.85, 0.5, glow))
	# il tesoro
	for loot in treasures:
		if loot[3]:
			continue
		var at: Vector2 = loot[1] - position
		var bob := sin(t * 3.0 + at.x) * 1.5
		if loot[0] == "lapis":
			draw_circle(at + Vector2(0, -4 + bob), 9.0, Color(0.3, 0.5, 1.0, 0.2))
			Restorations.draw_gem(self, at + Vector2(0, -4 + bob), 1.2)
		elif loot[0] == "ka":
			draw_circle(at + Vector2(0, -4 + bob), 8.0, Color(1.0, 0.8, 0.35, 0.18))
			draw_circle(at + Vector2(0, -4 + bob), 4.0, Color(0.96, 0.76, 0.3))
			draw_circle(at + Vector2(-1, -5 + bob), 1.5, Color(1, 0.95, 0.75))
		else:
			var hc := at + Vector2(0, -5 + bob)
			draw_circle(hc + Vector2(-2.5, -1), 3.0, Color(0.9, 0.25, 0.25))
			draw_circle(hc + Vector2(2.5, -1), 3.0, Color(0.9, 0.25, 0.25))
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-5.4, 0), hc + Vector2(5.4, 0), hc + Vector2(0, 6)]), Color(0.9, 0.25, 0.25))


## Geroglifici semplici, incisi: canna, occhio, ankh, uccello, acqua, sole, serpente, pane.
func _glyph(kind: int, at: Vector2, s: float, col: Color) -> void:
	match kind:
		0:   # canna fiorita
			draw_line(at + Vector2(0, 5) * s, at + Vector2(0, -4) * s, col, 1.2)
			draw_line(at + Vector2(0, -4) * s, at + Vector2(2, -6) * s, col, 1.2)
		1:   # occhio
			draw_arc(at, 4.0 * s, PI, TAU, 8, col, 1.2)
			draw_circle(at + Vector2(0, -1) * s, 1.2 * s, col)
			draw_line(at + Vector2(-1, 1) * s, at + Vector2(-2, 4) * s, col, 1.0)
		2:   # ankh
			draw_arc(at + Vector2(0, -3) * s, 2.2 * s, 0, TAU, 8, col, 1.1)
			draw_line(at + Vector2(0, -1) * s, at + Vector2(0, 5) * s, col, 1.2)
			draw_line(at + Vector2(-3, 1) * s, at + Vector2(3, 1) * s, col, 1.2)
		3:   # uccello
			draw_line(at + Vector2(-4, 2) * s, at + Vector2(2, 2) * s, col, 1.2)
			draw_line(at + Vector2(2, 2) * s, at + Vector2(3, -2) * s, col, 1.2)
			draw_circle(at + Vector2(3, -3) * s, 1.2 * s, col)
			draw_line(at + Vector2(-1, 2) * s, at + Vector2(-1, 5) * s, col, 1.0)
		4:   # acqua
			draw_polyline(PackedVector2Array([at + Vector2(-4, 0) * s, at + Vector2(-2, -2) * s, at + Vector2(0, 0) * s, at + Vector2(2, -2) * s, at + Vector2(4, 0) * s]), col, 1.1)
		5:   # sole
			draw_arc(at, 3.0 * s, 0, TAU, 10, col, 1.1)
			draw_circle(at, 0.9 * s, col)
		6:   # serpente
			draw_polyline(PackedVector2Array([at + Vector2(-4, 3) * s, at + Vector2(-1, 3) * s, at + Vector2(0, 0) * s, at + Vector2(2, -2) * s, at + Vector2(1, -5) * s]), col, 1.2)
		_:   # pane
			draw_arc(at + Vector2(0, 2) * s, 3.5 * s, PI, TAU, 8, col, 1.2)
			draw_line(at + Vector2(-3.5, 2) * s, at + Vector2(3.5, 2) * s, col, 1.2)
