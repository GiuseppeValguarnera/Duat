extends Control
## Frecce sul bordo dello schermo verso le porte aperte che non si vedono: con il colore
## e il nome della ricompensa, così si capisce subito che le uscite sono più di una.
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var game: Node

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var vs := get_viewport().get_visible_rect().size
	var u: float = Fx.ui
	var margin := 22.0 * u
	var inner := Rect2(Vector2(margin, margin + 24.0 * u), vs - Vector2(margin * 2.0, margin * 2.0 + 24.0 * u))
	var font := UiStyle.title_font()
	var fs := Fx.fs(8)
	var bob := sin(Time.get_ticks_msec() / 180.0) * 3.0 * u
	for d in game.doors:
		if not is_instance_valid(d) or not d.open:
			continue
		var sp: Vector2 = d.get_global_transform_with_canvas().origin
		if Rect2(Vector2.ZERO, vs).grow(-8.0).has_point(sp):
			continue
		var center := vs / 2.0
		var dir := (sp - center).normalized()
		# punto sul bordo del rettangolo interno lungo la direzione della porta
		var tx := INF if dir.x == 0.0 else ((inner.end.x if dir.x > 0.0 else inner.position.x) - center.x) / dir.x
		var ty := INF if dir.y == 0.0 else ((inner.end.y if dir.y > 0.0 else inner.position.y) - center.y) / dir.y
		var pos := center + dir * minf(tx, ty) + dir * bob
		var col: Color = d.reward_color()
		var a := dir.angle()
		var r := 9.0 * u
		var tip := pos + Vector2.from_angle(a) * r
		var l := pos + Vector2.from_angle(a + 2.5) * r
		var rr := pos + Vector2.from_angle(a - 2.5) * r
		draw_circle(pos, r + 3.0 * u, Color(0, 0, 0, 0.55))
		draw_colored_polygon(PackedVector2Array([tip, l, pos - Vector2.from_angle(a) * r * 0.3, rr]), col)
		draw_polyline(PackedVector2Array([tip, l, pos - Vector2.from_angle(a) * r * 0.3, rr, tip]), Color(1, 0.95, 0.8), 1.2)
		var txt: String = d.reward_label()
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp := pos - Vector2.from_angle(a) * (r + 8.0 * u) - Vector2(tw / 2.0, -fs / 3.0)
		lp.x = clampf(lp.x, 4.0, vs.x - tw - 4.0)
		draw_string_outline(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
		draw_string(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.lightened(0.3))



## La bilancia di Ma'at alla morte: il piatto del cuore scende, quello della piuma sale.
