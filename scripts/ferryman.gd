extends Node2D
## Mahaf, il Traghettatore (Libro dei Morti, capitolo 99): una stanza senza nemici dove
## spendi il Ka raccolto nella discesa. Il Ka speso qui non torna a casa con te:
## ogni acquisto è Ka in meno per il Libro dei Morti.

const LINES := [
	"Mahaf, il Traghettatore: «Ogni sponda ha il suo prezzo. Anche questa.»",
	"Mahaf, il Traghettatore: «Conosci il nome di ogni parte della mia barca? No? Allora paga.»",
	"Mahaf, il Traghettatore: «I morti non portano nulla con sé. Tu porti Ka. Interessante.»",
	"Mahaf, il Traghettatore: «Non svegliarmi per niente, scriba. Compra, o passa oltre.»",
	"Mahaf, il Traghettatore: «Mi chiamano Colui che guarda indietro. Da qui vedo tutti quelli che sono caduti prima di te.»",
	"Mahaf, il Traghettatore: «Prima di un guardiano, tutti diventano generosi. Strano, vero?»",
	"Mahaf, il Traghettatore: «Il Ka è peso. Lascialo a me, e salirai più leggero.»",
]

var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	# la barca di papiro, con il traghettatore incappucciato che si volta all'indietro
	var bob := sin(t * 1.4) * 1.5
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 46.0, Color(0.1, 0.3, 0.4, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var reed := Color(0.62, 0.52, 0.28)
	var hull := PackedVector2Array([Vector2(-44, -2 + bob), Vector2(44, -2 + bob), Vector2(36, 8 + bob), Vector2(-36, 8 + bob)])
	draw_colored_polygon(hull, reed)
	draw_line(Vector2(-44, -2 + bob), Vector2(-52, -14 + bob), reed, 4.0)
	draw_line(Vector2(44, -2 + bob), Vector2(52, -14 + bob), reed, 4.0)
	for k in range(6):
		draw_line(Vector2(-34 + k * 13, -1 + bob), Vector2(-34 + k * 13, 7 + bob), reed.darkened(0.25), 1.0)
	var cloak := Color(0.15, 0.13, 0.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -2 + bob), Vector2(8, -2 + bob), Vector2(5, -26 + bob), Vector2(-5, -26 + bob)]), cloak)
	draw_circle(Vector2(0, -28 + bob), 6.0, cloak)
	draw_circle(Vector2(-2, -28 + bob), 1.0, Color(0.6, 1, 0.9))
	draw_circle(Vector2(2, -28 + bob), 1.0, Color(0.6, 1, 0.9))
	draw_line(Vector2(9, -30 + bob), Vector2(16, 6 + bob), Color(0.45, 0.32, 0.18), 2.0)


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
		draw_rect(Rect2(-12, -6, 24, 10), Color(0.55, 0.45, 0.3))
		draw_rect(Rect2(-14, -9, 28, 4), Color(0.7, 0.58, 0.4))
		if sold:
			return
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
		var font := ThemeDB.fallback_font
		var label := "%d Ka" % price
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var col := Color(0.94, 0.72, 0.3) if Run.ka >= price else Color(0.7, 0.4, 0.35)
		draw_string(font, Vector2(-w / 2.0, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
