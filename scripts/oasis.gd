class_name Oasis
extends RefCounted
## L'Oasi della quarta ora: la sosta tra Wernes e il deserto di Sokar. Una sola stanza, di notte,
## senza nemici. Qui la discesa si ferma un momento: la fonte guarisce un poco (una volta sola),
## l'altare di Imhotep permette di cambiare amuleto, Mahaf ha la sua barca arenata sulla sabbia
## e la statua di Sokar parla. La porta si apre subito: nessuno è obbligato a fermarsi.

const STARS := Color(0.85, 0.92, 1.0)

const SOKAR_LINES := [
	"«Io dimoro nel sepolto. Ciò che discende fin qui non si perde: muta forma, come il seme sotto la sabbia.»",
	"«Nella quarta ora il sole attraversa il mio corpo e non vi porta luce. Anche la luce, per rinascere, ha bisogno del buio.»",
	"«Hai varcato l'acqua, ora varchi la terra. Dopo la terra non resta che il cielo.»",
	"«Chi cammina verso l'orizzonte porta con sé la propria alba. Custodiscila: qui nessuno potrà dartene un'altra.»",
	"«Le acque ti hanno ricordato. La sabbia ti metterà alla prova. Quale delle due sia più clemente, lo dirà la fine del viaggio.»",
]


## Il centro e i semiassi dello specchio d'acqua (a sinistra, sotto l'altare di Imhotep).
static func pool_center(r: Rect2, top: float) -> Vector2:
	return Vector2(r.size.x * 0.23, top + (r.size.y - top) * 0.6)


const POOL_RADII := Vector2(62.0, 30.0)


static func _oval(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Il pavimento: sabbia scura sotto le stelle, l'acqua con il cielo riflesso, palme e giunchi.
static func paint(ci: CanvasItem, r: Rect2, top: float, wall: float) -> void:
	var floor_r := Rect2(wall, top, r.size.x - wall * 2.0, r.size.y - wall - top)
	ci.draw_rect(floor_r, Color(0.3, 0.27, 0.36))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4417
	# dune basse, rischiarate dalla luna da un lato
	var yy := top + 8.0
	while yy < floor_r.end.y - 4.0:
		var pts := PackedVector2Array()
		var ph := rng.randf() * TAU
		var x := wall
		while x <= floor_r.end.x:
			pts.append(Vector2(x, yy + sin(x * 0.04 + ph) * 3.0))
			x += 8.0
		ci.draw_polyline(pts, Color(0.2, 0.18, 0.28, 0.55), 1.2)
		var hi := pts.duplicate()
		for i in range(hi.size()):
			hi[i] = hi[i] + Vector2(0, -1.5)
		ci.draw_polyline(hi, Color(0.55, 0.52, 0.66, 0.3), 1.0)
		yy += rng.randf_range(14.0, 22.0)
	for i in range(60):
		var p := Vector2(rng.randf_range(floor_r.position.x + 6, floor_r.end.x - 6), rng.randf_range(floor_r.position.y + 6, floor_r.end.y - 6))
		ci.draw_circle(p, rng.randf_range(0.7, 1.8), Color(0.18, 0.16, 0.24, 0.7))
	# lo specchio d'acqua: bordo di pietra, acqua scura, il cielo stellato riflesso
	var pc := pool_center(r, top)
	ci.draw_colored_polygon(_oval(pc + Vector2(2, 5), POOL_RADII.x + 8.0, POOL_RADII.y + 8.0), Color(0, 0, 0, 0.25))
	ci.draw_colored_polygon(_oval(pc, POOL_RADII.x + 7.0, POOL_RADII.y + 7.0), Color(0.16, 0.13, 0.17))
	ci.draw_colored_polygon(_oval(pc, POOL_RADII.x + 4.0, POOL_RADII.y + 4.0), Color(0.5, 0.45, 0.4))
	ci.draw_colored_polygon(_oval(pc, POOL_RADII.x, POOL_RADII.y), Color(0.06, 0.12, 0.26))
	ci.draw_colored_polygon(_oval(pc + Vector2(-6, -3), POOL_RADII.x * 0.72, POOL_RADII.y * 0.6), Color(0.08, 0.17, 0.34))
	for i in range(14):
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 0.85
		ci.draw_circle(pc + Vector2(cos(a) * POOL_RADII.x * d, sin(a) * POOL_RADII.y * d), rng.randf_range(0.6, 1.3), Color(STARS, 0.8))
	var rim := _oval(pc, POOL_RADII.x + 1.0, POOL_RADII.y + 1.0, 40)
	rim.append(rim[0])
	ci.draw_polyline(rim, Color(0.22, 0.7, 0.68, 0.55), 1.4)
	# fiori di loto sull'acqua, aperti alla notte
	for lp in [Vector2(-30, -8), Vector2(22, 10), Vector2(38, -12)]:
		var q: Vector2 = pc + lp
		ci.draw_colored_polygon(_oval(q + Vector2(1, 1), 7.0, 3.5, 12), Color(0.08, 0.26, 0.18))
		ci.draw_colored_polygon(_oval(q, 6.5, 3.2, 12), Color(0.2, 0.48, 0.3))
		for k in range(5):
			var pa := -PI / 2.0 + (k - 2) * 0.45
			ci.draw_circle(q + Vector2(cos(pa) * 2.6, sin(pa) * 2.6 - 1.5), 1.6, Color(0.95, 0.7, 0.8))
		ci.draw_circle(q + Vector2(0, -1.5), 1.1, Color(0.98, 0.85, 0.4))
	# giunchi di papiro sul bordo
	for i in range(9):
		var a := PI * 0.1 + i * PI * 0.14 + rng.randf() * 0.1
		var base := pc + Vector2(cos(a) * (POOL_RADII.x + 5.0), -sin(a) * (POOL_RADII.y + 5.0))
		_reed(ci, base, rng)
	# palme: tre intorno all'acqua, una per angolo in fondo
	for p in [pc + Vector2(-82, -8), pc + Vector2(78, -34), Vector2(r.size.x - wall - 28.0, top + 120.0), Vector2(wall + 26.0, r.size.y - wall - 22.0)]:
		_palm(ci, p, rng)
	# due bracieri di pietra ai lati della porta (il fuoco è un nodo a parte: Flame)
	for b in brazier_spots(r, top):
		_brazier(ci, b)
	# la stuoia con i cuscini accanto all'acqua: qui si riposa
	var mat := Rect2(pc + Vector2(POOL_RADII.x - 6.0, POOL_RADII.y + 4.0), Vector2(46, 22))
	ci.draw_rect(mat.grow(1.0), Color(0.12, 0.08, 0.05))
	ci.draw_rect(mat, Color(0.62, 0.22, 0.16))
	for k in range(3):
		ci.draw_line(Vector2(mat.position.x, mat.position.y + 5.0 + k * 6.0), Vector2(mat.end.x, mat.position.y + 5.0 + k * 6.0), [Color(0.94, 0.72, 0.3), Color(0.2, 0.36, 0.8), Color(0.94, 0.72, 0.3)][k], 1.2)
	for cu in [Vector2(10, 7), Vector2(32, 12)]:
		ci.draw_colored_polygon(_oval(mat.position + cu, 7.5, 4.5, 14), Color(0.12, 0.08, 0.05))
		ci.draw_colored_polygon(_oval(mat.position + cu, 6.8, 3.8, 14), Color(0.2, 0.55, 0.55))
	# giare d'acqua e d'olio ai piedi della statua di Sokar
	for jp in [Vector2(r.size.x * 0.5 + 92.0, top + 60.0), Vector2(r.size.x * 0.5 + 100.0, top + 70.0), Vector2(r.size.x * 0.5 + 86.0, top + 72.0)]:
		_jar(ci, jp)


## Dove stanno i bracieri accanto alla porta.
static func brazier_spots(r: Rect2, top: float) -> Array:
	return [Vector2(r.size.x * 0.5 - 70.0, top + 26.0), Vector2(r.size.x * 0.5 + 70.0, top + 26.0)]


static func _jar(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_colored_polygon(_oval(p + Vector2(2, 6), 6.0, 2.5, 12), Color(0, 0, 0, 0.3))
	ci.draw_colored_polygon(_oval(p, 6.0, 7.5, 14), Color(0.12, 0.08, 0.05))
	ci.draw_colored_polygon(_oval(p, 5.2, 6.7, 14), Color(0.62, 0.36, 0.22))
	ci.draw_rect(Rect2(p.x - 2.5, p.y - 10.0, 5, 4), Color(0.12, 0.08, 0.05))
	ci.draw_rect(Rect2(p.x - 2, p.y - 9.5, 4, 3), Color(0.7, 0.42, 0.26))
	ci.draw_line(Vector2(p.x - 4.5, p.y - 1), Vector2(p.x + 4.5, p.y - 1), Color(0.2, 0.36, 0.8), 1.0)
	ci.draw_circle(p + Vector2(-2, -3), 1.2, Color(1, 0.9, 0.7, 0.35))


static func _reed(ci: CanvasItem, base: Vector2, rng: RandomNumberGenerator) -> void:
	var h := rng.randf_range(9.0, 16.0)
	var lean := rng.randf_range(-3.0, 3.0)
	ci.draw_line(base, base + Vector2(lean, -h), Color(0.12, 0.3, 0.22), 1.5)
	ci.draw_line(base + Vector2(lean, -h), base + Vector2(lean + 3.0, -h - 3.0), Color(0.2, 0.45, 0.3), 1.2)
	ci.draw_line(base + Vector2(lean, -h), base + Vector2(lean - 3.0, -h - 3.0), Color(0.2, 0.45, 0.3), 1.2)


static func _palm(ci: CanvasItem, p: Vector2, rng: RandomNumberGenerator) -> void:
	ci.draw_colored_polygon(_oval(p + Vector2(4, 2), 14.0, 5.0, 12), Color(0, 0, 0, 0.28))
	var top_p := p + Vector2(rng.randf_range(-6.0, 6.0), -62.0)
	var trunk := PackedVector2Array([p, p.lerp(top_p, 0.4) + Vector2(3, 0), p.lerp(top_p, 0.75) + Vector2(-2, 0), top_p])
	ci.draw_polyline(trunk, Color(0.1, 0.07, 0.05), 6.0)
	ci.draw_polyline(trunk, Color(0.42, 0.3, 0.2), 4.0)
	for k in range(1, 6):
		var q := p.lerp(top_p, k / 6.0)
		ci.draw_line(q + Vector2(-2, 0), q + Vector2(2, 0), Color(0.28, 0.2, 0.14), 1.0)
	for i in range(8):
		var a := -PI + (i + 0.5) * PI / 8.0 - 0.1
		var tip := top_p + Vector2(cos(a) * 34.0, sin(a) * 14.0 + 12.0 + absf(cos(a)) * 8.0)
		var mid := top_p + Vector2(cos(a) * 20.0, sin(a) * 18.0 - 2.0)
		ci.draw_polyline(PackedVector2Array([top_p, mid, tip]), Color(0.05, 0.12, 0.1), 3.4)
		ci.draw_polyline(PackedVector2Array([top_p, mid, tip]), Color(0.16, 0.42, 0.3), 2.0)
		ci.draw_polyline(PackedVector2Array([mid, tip]), Color(0.3, 0.6, 0.4, 0.6), 0.8)


static func _brazier(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_rect(Rect2(p.x - 5.5, p.y - 2.5, 11, 14), Color(0.12, 0.08, 0.05))
	ci.draw_rect(Rect2(p.x - 5, p.y - 2, 10, 13), Color(0.5, 0.42, 0.34))
	ci.draw_rect(Rect2(p.x - 8.5, p.y - 6.5, 17, 6), Color(0.12, 0.08, 0.05))
	ci.draw_rect(Rect2(p.x - 8, p.y - 6, 16, 5), Color(0.62, 0.52, 0.4))
	ci.draw_line(Vector2(p.x - 4, p.y + 4), Vector2(p.x + 4, p.y + 4), Color(0.22, 0.7, 0.68), 1.0)


## Il fuoco dei bracieri: tre lingue che si muovono e qualche scintilla.
class Flame extends Node2D:
	var t := 0.0

	func _ready() -> void:
		t = randf() * 5.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2(0, -6), 9.0, Color(1.0, 0.55, 0.2, 0.12))
		for k in range(3):
			var h := 9.0 + 3.0 * sin(t * 9.0 + k * 2.1)
			var x := (k - 1) * 3.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, -6), Vector2(x + 3.0, -6), Vector2(x + sin(t * 7.0 + k) * 1.5, -6 - h)]), Color(1.0, 0.5 + 0.1 * k, 0.15, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -6), Vector2(2, -6), Vector2(sin(t * 8.0) * 1.0, -12 - sin(t * 11.0) * 2.0)]), Color(1.0, 0.92, 0.6))
		var ph := fmod(t * 0.8, 1.0)
		draw_circle(Vector2(sin(t * 3.0) * 4.0, -10.0 - ph * 16.0), 0.9, Color(1.0, 0.75, 0.3, 1.0 - ph))


## La fonte: si usa una volta sola. Cura il 25% della vita.
class Spring extends Node2D:
	var reach := 80.0
	var used := false
	var t := 0.0
	var title := ""
	var desc := ""

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if used:
			return
		# una colonna di luce lenta sopra l'acqua e qualche scintilla che sale
		var a := 0.12 + 0.05 * sin(t * 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(10, -64), Vector2(-10, -64)]), Color(0.5, 0.85, 1.0, a))
		UiStyle.sparkle(self, Vector2(0, -22), 26.0, t, false, position.x * 0.05)
		for i in range(3):
			var ph := fmod(t * 0.4 + i * 0.33, 1.0)
			draw_circle(Vector2(sin(i * 2.4 + t) * 10.0, -ph * 40.0), 1.4 * (1.0 - ph), Color(0.8, 0.95, 1.0, 0.8 * (1.0 - ph)))


## L'altare di Imhotep: un blocco di pietra con gli amuleti. Si usa una volta sola.
class Altar extends Node2D:
	var reach := 40.0
	var used := false
	var t := 0.0
	var title := ""
	var desc := ""

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var out := Color(0.12, 0.08, 0.05)
		draw_rect(Rect2(-22.5, -6.5, 45, 16), out)
		draw_rect(Rect2(-22, -6, 44, 15), Color(0.52, 0.45, 0.4))
		draw_rect(Rect2(-26.5, -12.5, 53, 8), out)
		draw_rect(Rect2(-26, -12, 52, 7), Color(0.68, 0.6, 0.5))
		draw_line(Vector2(-20, 2), Vector2(20, 2), Color(0.2, 0.45, 0.7), 1.2)
		draw_line(Vector2(-20, 5), Vector2(20, 5), Color(0.94, 0.72, 0.3, 0.7), 1.0)
		var shown: Array = []
		for id in Amulets.ALL_IT:
			if Amulets.owned(id):
				shown.append(id)
		if shown.is_empty():
			return
		var n := mini(shown.size(), 3)
		for i in range(n):
			var id: String = shown[i]
			var c := Vector2((i - (n - 1) / 2.0) * 16.0, -19.0 + sin(t * 2.0 + i) * 1.2)
			Amulets.draw_icon(self, id, Vector2(c.x * 1.3, c.y), 0.5, used)
		if not used:
			UiStyle.sparkle(self, Vector2(0, -24), 20.0, t, false, position.x * 0.05)


## La statua di Sokar: un uomo mummiforme con la testa di falco, in piedi sul suo piedistallo.
class Statue extends Node2D:
	var reach := 40.0
	var used := false
	var title := ""
	var desc := ""
	var t := 0.0
	var near := false

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var out := Color(0.12, 0.08, 0.05)
		var stone := Color(0.55, 0.5, 0.45)
		var light := Color(0.72, 0.66, 0.56)
		draw_rect(Rect2(-17.5, 0.5, 35, 9), out)
		draw_rect(Rect2(-17, 1, 34, 8), stone)
		# corpo avvolto
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 1), Vector2(-9, -26), Vector2(-6, -38), Vector2(6, -38), Vector2(9, -26), Vector2(10, 1)]), out)
		draw_colored_polygon(PackedVector2Array([Vector2(-8.6, 0), Vector2(-7.6, -26), Vector2(-4.8, -37), Vector2(4.8, -37), Vector2(7.6, -26), Vector2(8.6, 0)]), stone)
		draw_line(Vector2(-6, -14), Vector2(6, -14), Color(0.4, 0.35, 0.3), 1.0)
		draw_line(Vector2(-7, -8), Vector2(7, -8), Color(0.4, 0.35, 0.3), 1.0)
		draw_line(Vector2(-4, -26), Vector2(4, -26), Color(0.94, 0.72, 0.3), 2.0)
		# testa di falco con la parrucca azzurra
		draw_circle(Vector2(0, -44), 8.5, out)
		draw_circle(Vector2(0, -44), 7.5, light)
		draw_colored_polygon(PackedVector2Array([Vector2(3, -47), Vector2(13, -44), Vector2(4, -41)]), out)
		draw_colored_polygon(PackedVector2Array([Vector2(3.6, -46.2), Vector2(11, -44), Vector2(4.2, -42.2)]), Color(0.85, 0.64, 0.26))
		draw_circle(Vector2(1.5, -46), 1.6, Color(0.94, 0.72, 0.3))
		draw_polyline(PackedVector2Array([Vector2(-6, -48), Vector2(-9, -40), Vector2(-8, -33)]), Color(0.2, 0.36, 0.8), 3.0)
		# il disco d'oro sul capo, che brilla appena
		var g := 0.5 + 0.2 * sin(t * 1.6)
		draw_circle(Vector2(0, -55), 4.2, Color(0.94, 0.72, 0.3, 0.9))
		draw_circle(Vector2(0, -55), 7.0, Color(0.94, 0.72, 0.3, 0.12 * g))
		if near:
			UiStyle.sparkle(self, Vector2(0, -34), 22.0, t, false, position.x * 0.05)
