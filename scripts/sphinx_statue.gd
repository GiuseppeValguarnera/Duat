class_name SphinxStatue
extends Node2D
## La Sfinge nell'arena della prova (blocco 17): una statua enorme di pietra, vista di fronte, sdraiata
## contro la parete nord. È viva: gli occhi seguono piano il giocatore quando è nella sua zona, ogni
## tanto sbatte le palpebre, quando parla le cade polvere di dosso e gli occhi si accendono; quando è
## divertita o infastidita si sente un rumore sordo. Le frasi brevi compaiono in un fumetto sopra la
## testa (say), senza fermare il gioco. Gli ornamenti comprati nel Tesoro (SphinxShop) la cambiano.
## Origine = centro del bordo anteriore del basamento.

const STONE := Color(0.79, 0.67, 0.47)
const STONE_L := Color(0.88, 0.77, 0.57)
const STONE_D := Color(0.55, 0.45, 0.31)
const OUTL := Color(0.18, 0.12, 0.07)
const GOLD := Color(0.95, 0.74, 0.3)
const LAPIS := Color(0.2, 0.33, 0.72)
const ZONE := 240.0                       ## entro questa distanza gli occhi ti seguono

var t := 0.0
var target := Vector2.ZERO                ## la posizione del giocatore (globale)
var watching := false
var look := Vector2.ZERO                  ## dove guardano gli occhi (-1..1), si muove piano
var blink_t := 0.0
var next_blink := 3.0
var talk_t := 0.0                         ## polvere e occhi accesi mentre parla
var bubble := ""
var bubble_t := 0.0
var dust: Array = []                      ## [pos, vel, vita]


func _ready() -> void:
	z_index = 1
	process_mode = Node.PROCESS_MODE_ALWAYS    # resta viva anche mentre parla (gioco in pausa)


func _process(delta: float) -> void:
	t += delta
	var to := target - global_position - Vector2(0, -84)
	watching = target != Vector2.ZERO and to.length() < ZONE
	var want := Vector2(clampf(to.x / 120.0, -1.0, 1.0), clampf(to.y / 120.0, -0.4, 1.0)) if watching else Vector2(0, 0.3)
	look = look.lerp(want, minf(1.0, delta * 2.2))         # lenta, come si addice alla pietra
	next_blink -= delta
	if next_blink <= 0.0:
		blink_t = 0.14
		next_blink = randf_range(2.5, 6.0)
	blink_t = maxf(0.0, blink_t - delta)
	talk_t = maxf(0.0, talk_t - delta)
	bubble_t = maxf(0.0, bubble_t - delta)
	if talk_t > 0.0 and randf() < delta * 14.0:
		var sx := randf_range(-30.0, 30.0)
		dust.append([Vector2(sx, -60.0 + randf_range(-30.0, 10.0)), Vector2(randf_range(-6, 6), randf_range(10, 30)), randf_range(0.6, 1.1)])
	for d in dust:
		d[0] = d[0] + d[1] * delta
		d[1] = d[1] + Vector2(0, 40.0 * delta)
		d[2] = float(d[2]) - delta
	dust = dust.filter(func(d: Array) -> bool: return float(d[2]) > 0.0)
	queue_redraw()


## Parla: polvere, occhi accesi. `thud` = il rumore sordo (divertita o infastidita).
func speak(secs: float = 1.2, thud: bool = false) -> void:
	talk_t = maxf(talk_t, secs)
	if thud:
		Sfx.play("amheh_land", 0.05, -10.0)
		Fx.shake(1.5)


## Una frase breve nel fumetto sopra la testa (reazioni senza dialogo: non ferma il gioco).
func say(text: String, secs: float = 3.6, thud: bool = false) -> void:
	bubble = text
	bubble_t = secs
	speak(1.0, thud)


func _draw() -> void:
	_draw_banners()
	_draw_braziers()
	# l'ombra e il basamento con la fascia di geroglifi
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 92.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-84, -10, 168, 18), STONE_D)
	draw_rect(Rect2(-84, -10, 168, 18), OUTL, false, 1.0)
	draw_line(Vector2(-83, -9), Vector2(83, -9), Color(1, 0.95, 0.85, 0.25), 1.0)
	for k in range(9):
		var gx := -72.0 + k * 18.0
		_glyph(Vector2(gx, -1), k % 4)
	# le anche del leone, dietro, ai lati
	for sx in [-1.0, 1.0]:
		var hip := PackedVector2Array([Vector2(sx * 80, -10), Vector2(sx * 76, -38), Vector2(sx * 56, -54), Vector2(sx * 34, -50), Vector2(sx * 30, -10)])
		draw_colored_polygon(hip, STONE_D.lerp(STONE, 0.5))
		draw_polyline(hip, OUTL, 1.0)
		# la coscia tonda e la luce sul dorso: è un leone accovacciato, non due blocchi
		draw_arc(Vector2(sx * 56, -18), 20.0, PI * (1.05 if sx > 0 else 1.35), PI * (1.65 if sx > 0 else 1.95), 12, Color(STONE_D, 0.9), 1.4)
		draw_line(Vector2(sx * 74, -38), Vector2(sx * 56, -53), Color(STONE_L, 0.8), 1.4)
		draw_line(Vector2(sx * 55, -53), Vector2(sx * 36, -49.5), Color(STONE_L, 0.8), 1.4)
		for k in range(2):
			draw_line(Vector2(sx * (40 + k * 16), -10), Vector2(sx * (40 + k * 16), -14 - k * 2), Color(STONE_D, 0.7), 1.0)   # le giunture dei blocchi
	# la coda che gira sul basamento, a destra
	draw_polyline(PackedVector2Array([Vector2(78, -12), Vector2(86, -6), Vector2(80, 2), Vector2(64, 4)]), STONE_D, 2.0)
	# il petto
	var chest := PackedVector2Array([Vector2(-32, -10), Vector2(-36, -52), Vector2(-20, -62), Vector2(20, -62), Vector2(36, -52), Vector2(32, -10)])
	draw_colored_polygon(chest, STONE)
	draw_polyline(chest, OUTL, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -61), Vector2(-6, -61), Vector2(-10, -11), Vector2(-28, -11), Vector2(-33, -51)]), Color(STONE_L, 0.35))    # luce da sinistra
	draw_line(Vector2(-14, -40), Vector2(-10, -16), Color(STONE_D, 0.6), 1.0)
	draw_line(Vector2(14, -40), Vector2(10, -16), Color(STONE_D, 0.6), 1.0)
	if SphinxShop.ornament_on("o_collare"):
		_collar()
	# le zampe anteriori, distese verso di te
	for px in [-34.0, 12.0]:
		var paw := Rect2(px, -16, 22, 20)
		draw_rect(paw, STONE_L)
		draw_rect(paw, OUTL, false, 1.0)
		for k in range(3):
			draw_line(Vector2(px + 6 + k * 5, 0), Vector2(px + 6 + k * 5, 4), OUTL, 1.0)
	if SphinxShop.ornament_on("o_loti"):
		_lotuses()
	_head()
	for d in dust:
		draw_circle(d[0], 1.1, Color(0.7, 0.6, 0.42, clampf(float(d[2]), 0.0, 1.0)))
	if bubble_t > 0.0 and bubble != "":
		_bubble()


func _head() -> void:
	var h := Vector2(0, -84)
	# il nemes a righe d'oro e di lapislazzuli, con le bande che scendono sulle spalle
	var nemes := PackedVector2Array([h + Vector2(-32, 26), h + Vector2(-24, -14), h + Vector2(0, -22), h + Vector2(24, -14), h + Vector2(32, 26)])
	draw_colored_polygon(nemes, Color(0.86, 0.72, 0.42))
	for k in range(6):
		var y := -12.0 + k * 6.5
		var half := 22.0 + k * 1.6
		draw_line(h + Vector2(-half, y), h + Vector2(half, y), Color(LAPIS, 0.8), 2.0)
	draw_polyline(nemes, OUTL, 1.0)
	for sx in [-1.0, 1.0]:
		var lap := PackedVector2Array([h + Vector2(sx * 22, 10), h + Vector2(sx * 30, 24), h + Vector2(sx * 28, 42), h + Vector2(sx * 18, 40)])
		draw_colored_polygon(lap, Color(0.86, 0.72, 0.42))
		draw_line(h + Vector2(sx * 24, 26), h + Vector2(sx * 26, 34), Color(LAPIS, 0.8), 2.0)
		draw_polyline(lap, OUTL, 1.0)
	# il volto
	var face := PackedVector2Array([h + Vector2(-14, -10), h + Vector2(14, -10), h + Vector2(15, 8), h + Vector2(8, 20), h + Vector2(-8, 20), h + Vector2(-15, 8)])
	draw_colored_polygon(face, STONE_L)
	draw_polyline(face, OUTL, 1.0)
	# gli occhi: orbite scure, pupille che seguono, palpebre che si chiudono
	for sx in [-1.0, 1.0]:
		var e := h + Vector2(sx * 7, 0)
		draw_colored_polygon(PackedVector2Array([e + Vector2(-5, 0), e + Vector2(0, -2.6), e + Vector2(5, 0), e + Vector2(0, 2.4)]), Color(0.12, 0.09, 0.06))
		var lit := talk_t > 0.0
		var pupil := Color(0.98, 0.8, 0.38) if lit else Color(0.93, 0.88, 0.76)
		draw_circle(e + Vector2(look.x * 2.2, look.y * 1.0), 1.6, pupil)
		if lit:
			draw_circle(e + Vector2(look.x * 2.2, look.y * 1.0), 3.2, Color(1.0, 0.8, 0.4, 0.25))
		if blink_t > 0.0:
			draw_colored_polygon(PackedVector2Array([e + Vector2(-5.5, -0.5), e + Vector2(0, -3.2), e + Vector2(5.5, -0.5), e + Vector2(0, 3)]), STONE_L)
			draw_line(e + Vector2(-5, 1), e + Vector2(5, 1), OUTL, 1.0)
		draw_line(e + Vector2(-5, -4.5), e + Vector2(4, -5.5) if sx < 0 else e + Vector2(5, -4.5), OUTL, 1.2)     # il sopracciglio dipinto
	draw_line(h + Vector2(0, 2), h + Vector2(-2, 10), OUTL, 1.0)        # il naso (consumato)
	draw_line(h + Vector2(-5, 14), h + Vector2(5, 14), OUTL, 1.0)        # la bocca, con un mezzo sorriso
	draw_line(h + Vector2(5, 14), h + Vector2(7, 12.5), OUTL, 1.0)
	draw_rect(Rect2(h.x - 3, h.y + 20, 6, 10), STONE_D)                  # la barba posticcia
	draw_rect(Rect2(h.x - 3, h.y + 20, 6, 10), OUTL, false, 1.0)
	# l'ureo sulla fronte (di lapislazzuli con i gioielli) e gli orecchini
	var jewels := SphinxShop.ornament_on("o_gioielli")
	var ur := h + Vector2(0, -17)
	draw_circle(ur, 2.4, LAPIS if jewels else GOLD)
	draw_line(ur + Vector2(0, 2), ur + Vector2(0, 6), GOLD, 1.4)
	if jewels:
		draw_circle(ur, 1.0, Color(0.6, 0.85, 1.0))
		for sx in [-1.0, 1.0]:
			draw_arc(h + Vector2(sx * 17, 6), 2.4, 0.0, TAU, 10, GOLD, 1.4)
			draw_circle(h + Vector2(sx * 17, 9), 1.2, LAPIS)


## Il collare usekh: file di perline d'oro e di lapislazzuli a mezzaluna sul petto.
func _collar() -> void:
	var c := Vector2(0, -62)
	var cols := [GOLD, LAPIS, Color(0.85, 0.3, 0.25), GOLD, LAPIS]
	for k in range(cols.size()):
		draw_arc(c, 12.0 + k * 3.2, 0.25, PI - 0.25, 20, cols[k], 2.6)
	draw_arc(c, 28.5, 0.25, PI - 0.25, 20, OUTL, 1.0)


## Mazzi di loti bianchi e blu ai piedi.
func _lotuses() -> void:
	for p in [Vector2(-62, 6), Vector2(-48, 9), Vector2(48, 9), Vector2(62, 6), Vector2(0, 10)]:
		var q: Vector2 = p
		draw_line(q, q + Vector2(0, 5), Color(0.3, 0.55, 0.3), 1.0)
		var blue := int(q.x) % 2 == 0
		var col := Color(0.55, 0.65, 0.98) if blue else Color(0.97, 0.94, 0.88)
		draw_colored_polygon(PackedVector2Array([q + Vector2(-3.5, 0), q + Vector2(-2.4, -4), q + Vector2(-0.8, -1.2), q + Vector2(0, -5), q + Vector2(0.8, -1.2), q + Vector2(2.4, -4), q + Vector2(3.5, 0)]), col)
		draw_circle(q + Vector2(0, -0.6), 0.9, Color(0.98, 0.85, 0.35))


## Due bracieri di bronzo accesi ai lati (ornamento «Bracieri accesi»).
func _draw_braziers() -> void:
	if not SphinxShop.ornament_on("o_bracieri"):
		return
	for sx in [-1.0, 1.0]:
		var b := Vector2(sx * 118, 4)
		draw_set_transform(b + Vector2(0, 3), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(b, b + Vector2(-6, -2), Color(0.45, 0.3, 0.15), 2.0)
		draw_line(b, b + Vector2(6, -2), Color(0.45, 0.3, 0.15), 2.0)
		draw_line(b, b + Vector2(0, -14), Color(0.55, 0.38, 0.18), 2.4)
		draw_colored_polygon(PackedVector2Array([b + Vector2(-9, -16), b + Vector2(9, -16), b + Vector2(6, -11), b + Vector2(-6, -11)]), Color(0.6, 0.42, 0.2))
		var fl := sin(t * 9.0 + sx) * 1.2
		for k in range(3):
			draw_circle(b + Vector2(0, -22), 18.0 - k * 5.0, Color(1.0, 0.6, 0.25, 0.05 + 0.02 * k))
		draw_colored_polygon(PackedVector2Array([b + Vector2(-6, -16), b + Vector2(6, -16), b + Vector2(fl, -30 - absf(fl) * 2.0)]), Color(1.0, 0.62, 0.22))
		draw_colored_polygon(PackedVector2Array([b + Vector2(-3, -16), b + Vector2(3, -16), b + Vector2(fl * 0.5, -24)]), Color(1.0, 0.9, 0.55))


## Due stendardi blu e oro appesi alla parete, dietro la Sfinge (ornamento «Stendardi»).
func _draw_banners() -> void:
	if not SphinxShop.ornament_on("o_stendardi"):
		return
	for sx in [-1.0, 1.0]:
		var top := Vector2(sx * 150, -104)
		var sway := sin(t * 1.3 + sx) * 1.5
		draw_line(top + Vector2(-12, 0), top + Vector2(12, 0), GOLD, 2.0)
		var cloth := PackedVector2Array([top + Vector2(-10, 1), top + Vector2(10, 1), top + Vector2(10 + sway, 46), top + Vector2(sway, 54), top + Vector2(-10 + sway, 46)])
		draw_colored_polygon(cloth, LAPIS)
		draw_polyline(cloth, OUTL, 1.0)
		draw_line(top + Vector2(-8, 8), top + Vector2(8, 8), GOLD, 1.4)
		draw_line(top + Vector2(-8 + sway * 0.5, 40), top + Vector2(8 + sway * 0.5, 40), GOLD, 1.4)
		# un occhio di Horus dipinto al centro
		var e := top + Vector2(sway * 0.5, 24)
		draw_arc(e, 4.0, PI, TAU, 8, GOLD, 1.2)
		draw_circle(e + Vector2(0, 0.5), 1.4, GOLD)
		draw_line(e + Vector2(-1, 2), e + Vector2(-2, 7), GOLD, 1.0)


## Un geroglifo inciso sul basamento: acqua, occhio, ankh, piuma.
func _glyph(p: Vector2, kind: int) -> void:
	var ink := Color(0.24, 0.3, 0.52)
	match kind:
		0:
			draw_polyline(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(-2, -1.4), p + Vector2(0, 0), p + Vector2(2, -1.4), p + Vector2(4, 0)]), ink, 1.0)
		1:
			draw_arc(p, 2.4, PI, TAU, 6, ink, 1.0)
			draw_circle(p + Vector2(0, 0.2), 0.8, ink)
		2:
			draw_arc(p + Vector2(0, -2), 1.4, 0.0, TAU, 6, ink, 1.0)
			draw_line(p + Vector2(0, -0.6), p + Vector2(0, 3), ink, 1.0)
			draw_line(p + Vector2(-2, 0.2), p + Vector2(2, 0.2), ink, 1.0)
		_:
			draw_line(p + Vector2(-1, 3), p + Vector2(1, -3), ink, 1.0)
			draw_line(p + Vector2(1, -3), p + Vector2(2, -1), ink, 1.0)


## Il fumetto sopra la testa: riquadro chiaro, testo scuro, a capo da solo.
func _bubble() -> void:
	var font := UiStyle.title_font()
	var fs := 8
	var w := 230.0
	var a := clampf(bubble_t / 0.4, 0.0, 1.0)
	var lines := font.get_multiline_string_size(bubble, HORIZONTAL_ALIGNMENT_CENTER, w, fs)
	var box := Rect2(-w / 2.0 - 6.0, -118.0 - lines.y, w + 12.0, lines.y + 8.0)
	draw_rect(box, Color(0.97, 0.92, 0.8, 0.95 * a))
	draw_rect(box, Color(0.35, 0.25, 0.12, a), false, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, box.end.y), Vector2(5, box.end.y), Vector2(0, box.end.y + 5)]), Color(0.97, 0.92, 0.8, 0.95 * a))
	draw_multiline_string(font, Vector2(box.position.x + 6.0, box.position.y + 4.0 + fs), bubble, HORIZONTAL_ALIGNMENT_CENTER, w, fs, -1, Color(0.2, 0.13, 0.06, a))
