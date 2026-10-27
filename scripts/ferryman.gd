extends Node2D
## Mahaf, il Traghettatore (Libro dei Morti, capitolo 99): una stanza senza nemici dove
## spendi il Ka raccolto nella discesa. Il Ka speso qui non torna a casa con te:
## ogni acquisto è Ka in meno per il Libro dei Morti.

## Mahaf cambia con la storia (docs/storia.md): all'inizio è avido e burbero; dopo il primo boss
## diventa curioso e ambiguo; più avanti preoccupato. Non dice mai chi sei: lascia solo frasi che
## si capiscono dopo. E abbassa i prezzi, senza dirlo.
const LINES := [
	"«Ogni sponda ha il suo prezzo. Anche questa.»",
	"«Conosci il nome di ogni parte della mia barca? No? Allora paga.»",
	"«I costruttori di tombe muravano stanze senza porta, per il Ka dei re. Chi guarda bene le crepe, a volte trova chi gli risponde.»",
	"«I morti non portano nulla con sé. Tu porti Ka. Interessante.»",
	"«Non svegliarmi per niente, scriba. Compra, o passa oltre.»",
	"«Mi chiamano Colui che guarda indietro. Da qui vedo tutti quelli che sono caduti prima di te.»",
	"«Prima di un guardiano, tutti diventano generosi. Strano, vero?»",
	"«Il Ka è peso. Lascialo a me, e salirai più leggero.»",
]
const LINES_CURIOUS := [
	"«Ti ho già portato una volta, sai? No, non te lo ricordi. Nessuno se lo ricorda.»",
	"«Hai ancora quella scheggia sotto il pollice? ...Lascia stare. Compra.»",
	"«Un muro che perde polvere è un muro che nasconde qualcosa. Lo sanno i ladri di tombe. E ora lo sai anche tu.»",
	"«Guardo indietro, scriba. È il mio mestiere. E più guardo, meno capisco chi ho davanti.»",
	"«Oggi il prezzo è più basso. Non chiedermi perché.»",
	"«Gli scribi di solito hanno le dita macchiate d'inchiostro. Tu no. Curioso.»",
]
## Nella terra di Sokar (la quarta ora): Mahaf parla della barca trascinata, del sole che non passa
## più, e di Aker che "riconosce ciò che porta quel nome" (akhet vuol dire orizzonte: si capisce
## solo nel finale).
const LINES_SOKAR := [
	"«Su questa sabbia la mia barca non galleggia: la trascinano. Anche chi traghetta le anime, in quest'ora, deve lasciarsi portare.»",
	"«Aker veglia sull'orizzonte. Ciò che porta quel nome, egli lo riconosce al primo sguardo. ...Non so perché te lo dico. Compra.»",
	"«Il sole non passa più per questa terra. Un tempo era lui il mio carico. Ora sei tu.»",
	"«Le cose sepolte, qui, non dormono. Ascoltano.»",
]
const LINES_WORRIED := [
	"«Il tuo re aveva paura di questa barca. Anche da vivo, nelle feste del Fiume, saliva sempre per ultimo.»",
	"«Non guardarmi così. Io vedo solo il passato. E il tuo è... affollato.»",
	"«Più scendi, meno ti costa la mia merce. Non è generosità. È fretta.»",
	"«Ho fatto una promessa, molto tempo fa. La sto ancora pagando. Prendi, e va'.»",
]


## Quanto è avanzata la storia per Mahaf: 0 all'inizio, 1 dopo il primo boss, 2 dopo il terzo.
static func trust() -> int:
	if Meta.ammit_wins >= 3:
		return 2
	if Meta.ammit_wins >= 1:
		return 1
	return 0


## Una frase di Mahaf adatta al punto della storia (a volte una di quelle di prima).
static func line() -> String:
	if Run.region == 2 and randf() < 0.5:
		return Lang.t(LINES_SOKAR.pick_random())
	var pools := [LINES, LINES_CURIOUS, LINES_WORRIED]
	var k := trust()
	if k > 0 and randf() < 0.25:
		k -= 1
	return Lang.t((pools[k] as Array).pick_random())


## Le frasi che puoi già sentire (fino al punto della storia), con il loro id per ricordarle.
static func _available() -> Array:
	var pools := [LINES, LINES_CURIOUS, LINES_WORRIED]
	var out := []
	# a Sokar le frasi della quarta ora vengono prima: sono quelle che non hai ancora sentito
	if Run.region == 2:
		for i in range(LINES_SOKAR.size()):
			out.append(["mahaf_s_%d" % i, LINES_SOKAR[i]])
	for k in range(trust() + 1):
		var pool: Array = pools[k]
		for i in range(pool.size()):
			out.append(["mahaf_%d_%d" % [k, i], pool[i]])
	return out


## Mahaf ha una frase che non hai ancora sentito? (il punto esclamativo sopra la barca)
static func has_news() -> bool:
	for e in _available():
		if not Meta.dialogue_seen.has(e[0]):
			return true
	return false


## Quando gli parli: la prima frase che non hai ancora sentito, o una a caso se le sai tutte.
static func talk_line() -> String:
	for e in _available():
		if not Meta.dialogue_seen.has(e[0]):
			Meta.dialogue_seen.append(e[0])
			Meta.save()
			return Lang.t(e[1])
	return line()


## Il saluto quando entri: una frase già sentita (le nuove le dice solo se gli parli).
static func greeting() -> String:
	var known := _available().filter(func(e: Array) -> bool: return Meta.dialogue_seen.has(e[0]))
	if known.is_empty():
		return Lang.t("«Sali, scriba. O compra e scendi. Ma prima parlami: le mie parole sono gratis.»")
	return Lang.t(known.pick_random()[1])


## Lo sconto silenzioso: più Mahaf sa, meno ti fa pagare.
static func trust_discount() -> float:
	return [1.0, 0.9, 0.8][trust()]


var t := 0.0
var near := false                       ## il giocatore è abbastanza vicino per parlargli (game.gd)
var _news := false
var _news_t := 0.0
var _speech: Label


func _process(delta: float) -> void:
	t += delta
	if t >= _news_t:
		_news_t = t + 0.5
		_news = has_news()
	queue_redraw()


## Mahaf parla: la frase compare sopra la barca e svanisce dopo qualche secondo.
func say(text: String) -> void:
	if _speech != null and is_instance_valid(_speech):
		_speech.queue_free()
	_speech = Label.new()
	_speech.text = text
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech.size = Vector2(240, 0)
	_speech.position = Vector2(-120, -96)
	_speech.add_theme_font_override("font", UiStyle.body_font())
	_speech.add_theme_font_size_override("font_size", 11)
	_speech.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	_speech.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.06))
	_speech.add_theme_constant_override("outline_size", 4)
	_speech.z_index = 90
	add_child(_speech)
	_news = has_news()
	var tw := _speech.create_tween()
	tw.tween_interval(maxf(3.0, text.length() * 0.06))
	tw.tween_property(_speech, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_speech.queue_free)


func _draw() -> void:
	# la barca di papiro a fasci legati, con prua e poppa ricurve a ombrello di papiro; il
	# traghettatore incappucciato ha la testa girata all'indietro (Mahaf: "colui che guarda dietro")
	var bob := sin(t * 1.4) * 1.5
	var out := Color(0.12, 0.08, 0.05)
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 46.0, Color(0.1, 0.3, 0.4, 0.5))
	draw_arc(Vector2.ZERO, 40.0 + sin(t * 2.0) * 3.0, 0.0, TAU, 32, Color(0.5, 0.85, 0.95, 0.25), 1.5)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	var reed := Color(0.66, 0.56, 0.3)
	var reed_d := Color(0.46, 0.38, 0.18)
	var hull := PackedVector2Array([Vector2(-44, -3), Vector2(44, -3), Vector2(38, 4), Vector2(30, 8), Vector2(-30, 8), Vector2(-38, 4)])
	draw_colored_polygon(hull, reed)
	var hc := hull.duplicate()
	hc.append(hull[0])
	draw_polyline(hc, out, 1.0)
	draw_line(Vector2(-40, 2), Vector2(40, 2), reed_d, 1.0)
	for k in range(7):
		var x := -36.0 + k * 12.0
		draw_line(Vector2(x, -3), Vector2(x + 1.5, 8), Color(0.75, 0.2, 0.12), 1.2)        # le legature rosse
	for sx in [-1.0, 1.0]:
		var a := Vector2(44 * sx, -3)
		var b := Vector2(52 * sx, -14)
		draw_line(a, b, out, 5.0)
		draw_line(a, b, reed, 3.5)
		# l'ombrello di papiro in cima
		var u := PackedVector2Array([b, b + Vector2(5 * sx, -6), b + Vector2(1 * sx, -8), b + Vector2(-3 * sx, -6)])
		draw_colored_polygon(u, Color(0.42, 0.62, 0.3))
		u.append(b)
		draw_polyline(u, out, 0.8)
	# il traghettatore: mantello scuro, cappuccio, il remo
	var cloak := Color(0.17, 0.15, 0.24)
	var body := PackedVector2Array([Vector2(-8, -3), Vector2(8, -3), Vector2(5.5, -24), Vector2(-5.5, -24)])
	draw_colored_polygon(body, cloak)
	var bc := body.duplicate()
	bc.append(body[0])
	draw_polyline(bc, out, 0.9)
	draw_line(Vector2(-2, -22), Vector2(-4, -3), Color(0.1, 0.09, 0.15), 1.0)
	draw_arc(Vector2(0, -23), 5.0, 0.2, PI - 0.2, 8, Color(0.25, 0.62, 0.62), 1.6)          # collare turchese
	draw_line(Vector2(10, -31), Vector2(17, 7), out, 3.2)
	draw_line(Vector2(10, -31), Vector2(17, 7), Color(0.5, 0.36, 0.2), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(15.5, 1), Vector2(19.5, 0), Vector2(20, 9), Vector2(17, 10)]), Color(0.5, 0.36, 0.2))
	draw_circle(Vector2(0, -28), 6.6, out)
	draw_circle(Vector2(0, -28), 6.0, cloak)
	# la testa girata all'indietro: si vede solo un occhio, dalla parte sbagliata
	draw_colored_polygon(PackedVector2Array([Vector2(-5.5, -30), Vector2(-1, -31), Vector2(-1, -26), Vector2(-5, -25.5)]), Color(0.06, 0.05, 0.08))
	draw_circle(Vector2(-3.5, -28.5), 1.0, Color(0.6, 1, 0.9))
	draw_line(Vector2(-5.5, -28.6), Vector2(-1.5, -28.3), Color(0.6, 1, 0.9, 0.5), 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# i segni: si può parlare con lui, e il punto esclamativo se ha qualcosa di nuovo da dire
	UiStyle.sparkle(self, Vector2(0, -22 + bob), 22.0, t, near, 0.7)
	if _news:
		UiStyle.exclaim(self, Vector2(0, -50 + bob), t)



## Un oggetto in vendita su un piedistallo. Ci si avvicina e si preme E / Y per comprarlo.
class ShopItem extends Node2D:
	var kind := ""
	var title := ""
	var desc := ""
	var price := 0
	var sold := false
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func color() -> Color:
		match kind:
			"heal":
				return Color(0.35, 0.7, 0.95)
			"boon":
				return Color(0.94, 0.72, 0.3)
			_:
				return Color(0.62, 0.56, 0.92)

	func _draw() -> void:
		# piedistallo di pietra con il bordo dipinto
		var out := Color(0.12, 0.08, 0.05)
		draw_rect(Rect2(-12.5, -6.5, 25, 11), out)
		draw_rect(Rect2(-12, -6, 24, 10), Color(0.55, 0.45, 0.3))
		draw_rect(Rect2(-14.5, -9.5, 29, 5), out)
		draw_rect(Rect2(-14, -9, 28, 4), Color(0.7, 0.58, 0.4))
		draw_line(Vector2(-11, -1), Vector2(11, -1), Color(0.2, 0.45, 0.7), 1.0)
		if sold:
			return
		UiStyle.sparkle(self, Vector2(0, -22), 14.0, t, false, position.x * 0.05)
		var c := color()
		var y := -22.0 + sin(t * 2.5) * 2.0
		draw_circle(Vector2(0, y), 8.0, Color(c, 0.25))
		match kind:
			"heal":
				draw_colored_polygon(PackedVector2Array([Vector2(0, y - 7), Vector2(5, y + 1), Vector2(0, y + 5), Vector2(-5, y + 1)]), c)
			"boon":
				draw_circle(Vector2(0, y), 4.5, c)
				draw_arc(Vector2(0, y), 7.0, 0.0, TAU, 16, c, 1.0)
			_:
				draw_rect(Rect2(-2, y - 7, 4, 12), c)
				draw_rect(Rect2(-6, y - 3, 12, 3), c)
		var font := UiStyle.body_font()
		var label := Lang.t("%d Ka") % price
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var col := Color(0.94, 0.72, 0.3) if Run.ka >= price else Color(0.7, 0.4, 0.35)
		draw_string(font, Vector2(-w / 2.0, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
