class_name InteractCue
extends Node2D
## Il segnale comune di "qui puoi fare qualcosa" (blocco 23). Quando sei abbastanza vicino a una cosa
## che si usa (PNG, altare, negozio, porta aperta, barca, vasca...), sotto compare un anello d'oro che
## pulsa e sopra una bolla col tasto giusto: E sulla tastiera, Y sul pad, una mano sul telefono.
## Prima la cosa usabile si capiva solo dalla scritta in basso, che sul telefono si perde.
## La scena lo aggiorna a ogni fotogramma con point(pos) o clear().

const GOLD := Color(0.94, 0.72, 0.3)

var target := Vector2.ZERO
var height := 44.0               ## quanto sopra il punto sta la bolla
var ring := 18.0                 ## raggio dell'anello a terra
var k := 0.0                     ## dissolvenza
var want := false
var t := 0.0


func _ready() -> void:
	z_index = 9
	process_mode = Node.PROCESS_MODE_PAUSABLE


func point(pos: Vector2, h: float = 44.0, r: float = 18.0) -> void:
	if not want or pos.distance_to(target) > 4.0:
		target = pos
	want = true
	height = h
	ring = r


func clear() -> void:
	want = false


func _process(delta: float) -> void:
	t += delta
	k = move_toward(k, 1.0 if want else 0.0, delta * 6.0)
	visible = k > 0.01
	if visible:
		queue_redraw()


func _draw() -> void:
	var a := k
	var pulse := 0.5 + 0.5 * sin(t * 5.0)
	var c := target
	# l'anello a terra, schiacciato in prospettiva
	draw_set_transform(c, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, ring + 2.0 * pulse, Color(GOLD, 0.10 * a))
	draw_arc(Vector2.ZERO, ring + 2.0 * pulse, 0.0, TAU, 32, Color(GOLD, 0.75 * a), 1.6)
	draw_arc(Vector2.ZERO, ring * 0.65, 0.0, TAU, 24, Color(1, 0.95, 0.75, 0.35 * a * pulse), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# la bolla col tasto, che sobbalza piano
	var b := c + Vector2(0, -height - 3.0 * sin(t * 3.2))
	var r := 7.5
	draw_colored_polygon(PackedVector2Array([b + Vector2(-3, r - 1), b + Vector2(3, r - 1), b + Vector2(0, r + 4)]), Color(0.06, 0.04, 0.08, 0.9 * a))
	draw_circle(b, r + 1.0, Color(0.06, 0.04, 0.08, 0.9 * a))
	match Fx.device:
		"pad":
			draw_circle(b, r - 0.5, Color(0.86, 0.68, 0.12, a))          # il tasto Y, giallo
			_letter(b, "Y", Color(0.08, 0.06, 0.02, a))
		"touch":
			# il tocco: un polpastrello e due cerchi che si allargano (prima sembrava un punto esclamativo)
			draw_circle(b, r - 0.5, Color(GOLD, 0.3 * a))
			draw_circle(b, 2.4, Color(1, 0.95, 0.85, a))
			draw_arc(b, 4.0 + pulse * 1.2, 0.0, TAU, 14, Color(1, 0.95, 0.85, 0.8 * a), 1.0)
			draw_arc(b, 6.0 + pulse * 0.8, 0.0, TAU, 16, Color(1, 0.95, 0.85, 0.35 * a), 0.8)
		_:
			draw_rect(Rect2(b - Vector2(r - 1.5, r - 1.5), Vector2(r - 1.5, r - 1.5) * 2.0), Color(0.9, 0.86, 0.78, a))
			draw_rect(Rect2(b - Vector2(r - 1.5, r - 1.5), Vector2(r - 1.5, r - 1.5) * 2.0), Color(0.3, 0.24, 0.18, a), false, 1.0)
			_letter(b, "E", Color(0.1, 0.08, 0.06, a))
	draw_arc(b, r + 1.0, 0.0, TAU, 24, Color(GOLD, (0.6 + 0.4 * pulse) * a), 1.2)


func _letter(c: Vector2, s: String, col: Color) -> void:
	var font := UiStyle.title_font()
	var fs := 9
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, 3.4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
