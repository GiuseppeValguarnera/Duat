extends Control
## La bilancia di Ma'at alla morte: il piatto del cuore scende, quello della piuma sale.
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var s := size.x / 120.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	var gold := Color(0.94, 0.72, 0.3)
	var tilt := clampf(t / 1.6, 0.0, 1.0)
	tilt = 1.0 - pow(1.0 - tilt, 3.0)
	var ang := 0.32 * tilt + sin(t * 2.0) * 0.015 * tilt
	var piv := Vector2(60, 16)
	draw_line(Vector2(60, 16), Vector2(60, 66), gold, 3.0)
	draw_line(Vector2(44, 66), Vector2(76, 66), gold, 3.0)
	draw_circle(piv, 3.0, gold)
	var lft := piv + Vector2(-40, 0).rotated(ang)
	var rgt := piv + Vector2(40, 0).rotated(ang)
	draw_line(lft, rgt, gold, 2.5)
	for end in [lft, rgt]:
		draw_line(end, end + Vector2(-8, 16), Color(gold, 0.7), 1.0)
		draw_line(end, end + Vector2(8, 16), Color(gold, 0.7), 1.0)
		draw_line(end + Vector2(-11, 16), end + Vector2(11, 16), gold, 2.5)
	# piatto sinistro: la piuma di Ma'at (sale)
	var fp := lft + Vector2(0, 10)
	draw_line(fp + Vector2(0, 5), fp + Vector2(2, -7), Color(0.95, 0.93, 0.85), 1.5)
	draw_colored_polygon(PackedVector2Array([fp + Vector2(1, 4), fp + Vector2(5, -2), fp + Vector2(3, -8), fp + Vector2(0, -2)]), Color(0.95, 0.93, 0.85))
	# piatto destro: il cuore (scende), che pulsa piano
	var hp := rgt + Vector2(0, 9)
	var beat := 1.0 + 0.08 * maxf(0.0, sin(t * 3.0))
	draw_circle(hp + Vector2(-2.5, -1) * beat, 3.5 * beat, Color(0.75, 0.12, 0.1))
	draw_circle(hp + Vector2(2.5, -1) * beat, 3.5 * beat, Color(0.75, 0.12, 0.1))
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-5.8, 0) * beat, hp + Vector2(5.8, 0) * beat, hp + Vector2(0, 7) * beat]), Color(0.75, 0.12, 0.1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Triangolo del riassunto delle carte (▲ vantaggio, ▼ prezzo).
