class_name HubHud
extends Control
## L'HUD dei luoghi tranquilli (Sala del Giudizio, Casa della Vita, Cortile di Neith): lo stesso
## riquadro egizio della discesa (hud_bars.gd) al posto della riga di testo. In alto il nome del luogo,
## sotto le tue ricchezze, ognuna con il suo segno: il Ka (le braccia alzate), i lapislazzuli (la gemma
## blu), le Lacrime di Iside (la goccia), i sigilli della Sfinge (lo scarabeo). Quando un numero cambia
## scatta e si illumina. Sotto, una riga piccola: discese e vittorie, o quello che il luogo vuole dire.

const GOLD := Color(0.94, 0.72, 0.3)
const GOLD_DARK := Color(0.55, 0.38, 0.14)
const LAPIS := Color(0.2, 0.36, 0.78)

var title := ""
var line := ""                   ## riga piccola sotto (cambia chi usa l'HUD)
var hidden_now := false
var _last := {}
var _pop := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 0


func _process(delta: float) -> void:
	for k in _pop.keys():
		_pop[k] = maxf(0.0, float(_pop[k]) - delta * 2.5)
	queue_redraw()


func _items() -> Array:
	var out := [["ka", Meta.ka_bank], ["lapis", Meta.lapis]]
	if Meta.tears > 0 or Meta.ammit_wins > 0:
		out.append(["tears", Meta.tears])
	if Sphinx.is_open():
		out.append(["seals", SphinxShop.seals()])
	return out


func _draw() -> void:
	if hidden_now:
		return
	var u: float = 0.85 if Fx.mobile else 0.9
	var body := UiStyle.body_font()
	var tf := UiStyle.title_font()
	var o := Vector2(6, 6) * u
	var items := _items()
	var fs_t := maxi(8, roundi(11 * u * 1.1))
	var fs_n := maxi(8, roundi(11 * u * 1.1))
	var fs_s := maxi(7, roundi(7 * u * 1.1))
	# larghezza: il più largo tra titolo, contatori e riga piccola
	var cw := 0.0
	var widths := []
	for it in items:
		var w := 16.0 * u + tf.get_string_size(str(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs_n).x + 12.0 * u
		widths.append(w)
		cw += w
	var pw := maxf(maxf(cw + 10.0 * u, tf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_t).x + 20.0 * u), body.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_s).x + 16.0 * u)
	var ph := (44.0 if line != "" else 35.0) * u
	draw_rect(Rect2(o, Vector2(pw, ph)), Color(0.05, 0.04, 0.09, 0.8))
	draw_rect(Rect2(o, Vector2(pw, ph)), GOLD_DARK, false, 1.5 * u)
	draw_rect(Rect2(o + Vector2(2, 2) * u, Vector2(pw, ph) - Vector2(4, 4) * u), Color(GOLD, 0.35), false, 1.0)
	for i in range(int(pw / (8.0 * u))):
		draw_rect(Rect2(o.x + 4.0 * u + i * 8.0 * u, o.y + ph - 3.0 * u, 4.0 * u, 2.0 * u), Color(LAPIS if i % 2 == 0 else GOLD, 0.6))
	_text(tf, o + Vector2(8, 12) * u, title, fs_t, Color(0.98, 0.9, 0.7))
	draw_line(o + Vector2(8, 15.5) * u, o + Vector2(pw / u - 8.0, 15.5) * u, Color(GOLD, 0.4), 1.0)
	var x := o.x + 9.0 * u
	var y := o.y + 26.0 * u
	for i in range(items.size()):
		var id: String = items[i][0]
		var val: int = int(items[i][1])
		if _last.has(id) and int(_last[id]) != val:
			_pop[id] = 1.0
		_last[id] = val
		var pop: float = _pop.get(id, 0.0)
		var c := Vector2(x + 5.0 * u, y - 3.5 * u)
		_icon(id, c, u * (1.0 + 0.35 * pop))
		_text(tf, Vector2(x + 14.0 * u, y), str(val), fs_n + int(3 * pop), _col(id).lerp(Color.WHITE, 0.3 + 0.5 * pop))
		x += float(widths[i])
	if line != "":
		_text(body, o + Vector2(8, 38.5) * u, line, fs_s, Color(0.85, 0.8, 0.7))


func _col(id: String) -> Color:
	match id:
		"lapis":
			return Color(0.45, 0.62, 1.0)
		"tears":
			return Color(0.6, 0.9, 1.0)
		"seals":
			return Color(0.95, 0.8, 0.5)
	return GOLD


func _icon(id: String, c: Vector2, u: float) -> void:
	match id:
		"ka":
			draw_line(c + Vector2(-4, 4) * u, c + Vector2(4, 4) * u, GOLD, 1.8 * u)
			draw_line(c + Vector2(-4, 4) * u, c + Vector2(-4, -3) * u, GOLD, 1.8 * u)
			draw_line(c + Vector2(4, 4) * u, c + Vector2(4, -3) * u, GOLD, 1.8 * u)
			draw_line(c + Vector2(-4, -3) * u, c + Vector2(-5.5, -4.5) * u, GOLD, 1.5 * u)
			draw_line(c + Vector2(4, -3) * u, c + Vector2(5.5, -4.5) * u, GOLD, 1.5 * u)
		"lapis":
			var g := PackedVector2Array([c + Vector2(0, -5.5) * u, c + Vector2(4.5, -1.5) * u, c + Vector2(0, 5.5) * u, c + Vector2(-4.5, -1.5) * u])
			draw_colored_polygon(g, LAPIS)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5.5) * u, c + Vector2(4.5, -1.5) * u, c + Vector2(0, -1.5) * u]), Color(0.42, 0.6, 1.0))
			g.append(g[0])
			draw_polyline(g, Color(0.05, 0.05, 0.15), 1.0)
			draw_circle(c + Vector2(-1.5, -2.2) * u, 0.8 * u, GOLD)          # la venatura d'oro del lapislazzuli
		"tears":
			draw_circle(c + Vector2(0, 1.5) * u, 3.4 * u, Color(0.55, 0.85, 1.0))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3.0, 0.4) * u, c + Vector2(3.0, 0.4) * u, c + Vector2(0, -6.0) * u]), Color(0.55, 0.85, 1.0))
			draw_circle(c + Vector2(-1.0, 1.0) * u, 1.0 * u, Color(1, 1, 1, 0.8))
		"seals":
			draw_circle(c, 4.2 * u, Color(0.3, 0.2, 0.08))
			draw_circle(c, 3.3 * u, Color(0.85, 0.66, 0.3))
			draw_line(c + Vector2(0, -3.0) * u, c + Vector2(0, 3.0) * u, Color(0.3, 0.2, 0.08), 1.0)
			draw_line(c + Vector2(-2.6, -1.0) * u, c + Vector2(2.6, -1.0) * u, Color(0.3, 0.2, 0.08), 1.0)


func _text(font: Font, pos: Vector2, text: String, font_size: int, col: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
