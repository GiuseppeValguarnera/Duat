class_name GodPortrait
extends Control
## Ritratto animato della divinità che ti parla: busto di profilo, alla maniera dei rilievi
## egizi, con l'alone del suo colore. Mentre parla gli occhi brillano e l'alone pulsa.
## Ogni dio ha la sua testa: Ra e Horus il falco, Sekhmet la leonessa, Thoth l'ibis,
## Bastet la gatta, Sobek il coccodrillo, Iside con il trono sul capo, Set il suo animale,
## Anubi lo sciacallo.

var god := "anubi"
var talking := true
var t := 0.0

const BLACK := Color(0.09, 0.08, 0.12)
const GOLD := Color(0.94, 0.72, 0.3)
const LAPIS := Color(0.16, 0.3, 0.68)
const LINEN := Color(0.95, 0.91, 0.8)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var s := size.x / 100.0                 # disegnato su una griglia di 100x100
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	var col: Color = Boons.god_color(god)
	var pulse := 0.5 + 0.5 * sin(t * (5.0 if talking else 1.5))
	# alone e cornice
	draw_circle(Vector2(50, 50), 48, Color(col, 0.14 + 0.1 * pulse))
	for i in range(12):
		var a := TAU * i / 12.0 + t * 0.2
		draw_line(Vector2(50, 50) + Vector2.from_angle(a) * 40, Vector2(50, 50) + Vector2.from_angle(a) * (46 + 2 * pulse), Color(col, 0.35), 2.0)
	draw_arc(Vector2(50, 50), 46, 0, TAU, 48, GOLD, 2.5)
	var bob := sin(t * 1.6) * 1.2
	# spalle e collare usekh (comuni a tutti)
	draw_colored_polygon(PackedVector2Array([Vector2(22, 96), Vector2(78, 96), Vector2(70, 74), Vector2(30, 74)]), _skin())
	for r in range(3):
		draw_arc(Vector2(50, 70 + bob), 20 - r * 4, 0.15 * PI, 0.85 * PI, 16, [GOLD, LAPIS, col][r], 3.5)
	var eye := Color(1, 0.95, 0.75).lerp(col.lightened(0.4), 0.5) if talking else Color(0.95, 0.9, 0.75)
	match god:
		"ra", "horus":
			_falcon(bob, eye)
			if god == "ra":
				draw_circle(Vector2(52, 14 + bob), 12, Color(1, 0.6, 0.15))
				draw_arc(Vector2(52, 14 + bob), 12, 0, TAU, 24, GOLD, 2)
				draw_colored_polygon(PackedVector2Array([Vector2(50, 26 + bob), Vector2(54, 26 + bob), Vector2(52, 20 + bob)]), Color(0.2, 0.6, 0.3))
			else:
				# doppia corona dell'Alto e del Basso Egitto
				draw_colored_polygon(PackedVector2Array([Vector2(40, 26 + bob), Vector2(62, 26 + bob), Vector2(58, 8 + bob), Vector2(48, 4 + bob), Vector2(44, 12 + bob)]), LINEN)
				draw_colored_polygon(PackedVector2Array([Vector2(36, 30 + bob), Vector2(66, 30 + bob), Vector2(64, 18 + bob), Vector2(38, 18 + bob)]), Color(0.75, 0.15, 0.12))
		"sekhmet":
			_lioness(bob, eye, Color(0.86, 0.6, 0.28))
			draw_circle(Vector2(48, 12 + bob), 10, Color(0.95, 0.35, 0.2))
		"bastet":
			_cat(bob, eye)
		"thoth":
			_ibis(bob, eye)
			draw_arc(Vector2(50, 14 + bob), 9, 0.6 * PI, 2.4 * PI, 16, Color(0.85, 0.9, 1.0), 3)
		"sobek":
			_croc(bob, eye)
		"iside":
			_woman(bob, eye)
		"set":
			_set_animal(bob, eye)
		_:
			_jackal(bob, eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _skin() -> Color:
	match god:
		"iside":
			return Color(0.78, 0.52, 0.3)
		_:
			return Color(0.7, 0.45, 0.25)


func _wig(bob: float, color: Color = LAPIS) -> void:
	# parrucca a strisce che scende sulle spalle
	draw_colored_polygon(PackedVector2Array([Vector2(30, 30 + bob), Vector2(58, 26 + bob), Vector2(62, 66 + bob), Vector2(34, 72 + bob)]), color)
	for i in range(5):
		draw_line(Vector2(34 + i * 6, 32 + bob), Vector2(36 + i * 6, 70 + bob), color.lightened(0.25), 1.5)


func _eye_at(p: Vector2, eye: Color) -> void:
	draw_circle(p, 3.2, eye)
	draw_circle(p + Vector2(0.8, 0), 1.4, BLACK)
	draw_line(p + Vector2(3, 0), p + Vector2(8, 1), BLACK, 1.5)       # linea di kohl


func _falcon(bob: float, eye: Color) -> void:
	_wig(bob, Color(0.35, 0.24, 0.16))
	var head := Color(0.42, 0.3, 0.2)
	draw_circle(Vector2(50, 40 + bob), 15, head)
	draw_colored_polygon(PackedVector2Array([Vector2(62, 36 + bob), Vector2(76, 42 + bob), Vector2(66, 50 + bob), Vector2(60, 46 + bob)]), Color(0.25, 0.2, 0.15))
	draw_line(Vector2(48, 44 + bob), Vector2(44, 56 + bob), LINEN, 2.0)   # segno sotto l'occhio del falco
	_eye_at(Vector2(56, 38 + bob), eye)


func _lioness(bob: float, eye: Color, fur: Color) -> void:
	_wig(bob, fur.darkened(0.35))
	draw_circle(Vector2(50, 42 + bob), 16, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(60, 40 + bob), Vector2(72, 46 + bob), Vector2(64, 54 + bob)]), fur.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(40, 30 + bob), Vector2(44, 20 + bob), Vector2(48, 30 + bob)]), fur.darkened(0.2))
	_eye_at(Vector2(57, 40 + bob), eye)


func _cat(bob: float, _eye: Color) -> void:
	var fur := BLACK.lightened(0.15)
	draw_circle(Vector2(50, 46 + bob), 15, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(38, 38 + bob), Vector2(40, 20 + bob), Vector2(48, 34 + bob)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(52, 34 + bob), Vector2(58, 18 + bob), Vector2(62, 36 + bob)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(60, 46 + bob), Vector2(70, 50 + bob), Vector2(62, 56 + bob)]), fur)
	draw_circle(Vector2(42, 56 + bob), 2.5, GOLD)                           # orecchino d'oro
	_eye_at(Vector2(57, 44 + bob), Color(0.6, 1, 0.5) if talking else Color(0.8, 0.95, 0.6))


func _ibis(bob: float, eye: Color) -> void:
	_wig(bob)
	draw_circle(Vector2(50, 40 + bob), 12, Color(0.92, 0.9, 0.86))
	# il lungo becco ricurvo
	var beak := PackedVector2Array()
	for i in range(12):
		var k := i / 11.0
		beak.append(Vector2(58 + k * 30, 40 + bob + k * k * 22))
	draw_polyline(beak, BLACK, 4.0)
	_eye_at(Vector2(54, 38 + bob), eye)


func _croc(bob: float, eye: Color) -> void:
	_wig(bob)
	var skin := Color(0.38, 0.48, 0.24)
	draw_circle(Vector2(48, 40 + bob), 13, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 34 + bob), Vector2(86, 42 + bob), Vector2(86, 48 + bob), Vector2(56, 50 + bob)]), skin)
	for i in range(5):
		draw_line(Vector2(62 + i * 5, 48 + bob), Vector2(63 + i * 5, 51 + bob), LINEN, 1.0)
	# piume e disco sul capo
	draw_colored_polygon(PackedVector2Array([Vector2(42, 28 + bob), Vector2(46, 6 + bob), Vector2(50, 28 + bob)]), LINEN)
	draw_circle(Vector2(46, 24 + bob), 5, Color(0.95, 0.5, 0.2))
	_eye_at(Vector2(52, 36 + bob), eye)


func _woman(bob: float, eye: Color) -> void:
	_wig(bob, BLACK)
	draw_circle(Vector2(52, 42 + bob), 12, _skin())
	draw_colored_polygon(PackedVector2Array([Vector2(62, 42 + bob), Vector2(66, 47 + bob), Vector2(61, 48 + bob)]), _skin())
	# il trono, geroglifico del suo nome, sul capo
	draw_rect(Rect2(42, 12 + bob, 16, 5), GOLD)
	draw_rect(Rect2(52, 2 + bob, 6, 12), GOLD)
	draw_rect(Rect2(40, 26 + bob, 24, 3), GOLD)
	_eye_at(Vector2(56, 40 + bob), eye)


func _set_animal(bob: float, eye: Color) -> void:
	var fur := Color(0.62, 0.22, 0.16)
	_wig(bob, fur.darkened(0.4))
	draw_circle(Vector2(48, 42 + bob), 13, fur)
	# muso lungo e ricurvo
	draw_colored_polygon(PackedVector2Array([Vector2(56, 38 + bob), Vector2(80, 46 + bob), Vector2(78, 52 + bob), Vector2(56, 48 + bob)]), fur)
	# orecchie squadrate
	draw_rect(Rect2(38, 12 + bob, 6, 18), fur)
	draw_rect(Rect2(48, 12 + bob, 6, 18), fur)
	draw_rect(Rect2(36, 10 + bob, 10, 4), fur.darkened(0.2))
	draw_rect(Rect2(46, 10 + bob, 10, 4), fur.darkened(0.2))
	_eye_at(Vector2(54, 40 + bob), Color(1, 0.5, 0.35) if talking else eye)


func _jackal(bob: float, _eye: Color) -> void:
	_wig(bob)
	draw_circle(Vector2(48, 42 + bob), 13, BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 38 + bob), Vector2(78, 46 + bob), Vector2(76, 50 + bob), Vector2(56, 50 + bob)]), BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(40, 32 + bob), Vector2(44, 6 + bob), Vector2(50, 30 + bob)]), BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(48, 30 + bob), Vector2(54, 8 + bob), Vector2(56, 32 + bob)]), BLACK)
	draw_line(Vector2(40, 54 + bob), Vector2(58, 54 + bob), GOLD, 2.5)
	_eye_at(Vector2(56, 40 + bob), Color(1, 0.85, 0.35))
