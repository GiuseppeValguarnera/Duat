extends Control
## HUD in alto a sinistra, in stile egizio: riquadro scuro con il bordo d'oro, l'ankh accanto
## alla vita (con la scia rossa del danno appena subito), il segno del Ka con il suo numero,
## la stanza, e l'Occhio di Horus che si riempie mentre si ricarica (con un pallino per carica).
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var game: Node
var shown_hp := -1.0            # la scia del danno scende piano dietro la barra vera
var last_ka := -1
var ka_pop := 0.0
var eye_was_ready := true
var eye_pop := 0.0

const GOLD := Color(0.94, 0.72, 0.3)
const GOLD_DARK := Color(0.55, 0.38, 0.14)
const LAPIS := Color(0.2, 0.36, 0.78)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	var p = game.player
	if p != null and is_instance_valid(p):
		if shown_hp < 0.0 or p.hp > shown_hp:
			shown_hp = p.hp
		else:
			shown_hp = move_toward(shown_hp, p.hp, maxf(8.0, (shown_hp - p.hp) * 2.5) * delta)
		if last_ka >= 0 and Run.ka != last_ka:
			ka_pop = 1.0
		last_ka = Run.ka
		var ready_now: bool = p.eye_ready()
		if ready_now and not eye_was_ready:
			eye_pop = 1.0
		eye_was_ready = ready_now
	ka_pop = maxf(0.0, ka_pop - delta * 3.0)
	eye_pop = maxf(0.0, eye_pop - delta * 2.5)
	queue_redraw()

func _draw() -> void:
	var p = game.player
	if p == null or not is_instance_valid(p):
		return
	var u: float = 0.85 if Fx.mobile else 0.9    # compatto: sul telefono lo schermo è già ingrandito
	hu = u
	var font := UiStyle.body_font()
	var title := UiStyle.title_font()
	var sek: bool = Run.sekhem_unlocked()
	var o := Vector2(6, 6) * u
	var touch := Fx.device == "touch"     # sul telefono l'Occhio sta sul suo pulsante
	var pw := (170.0 if touch else 206.0) * u
	var ph := (44.0 if sek else 38.0) * u
	# riquadro
	draw_rect(Rect2(o, Vector2(pw, ph)), Color(0.05, 0.04, 0.09, 0.78))
	draw_rect(Rect2(o, Vector2(pw, ph)), GOLD_DARK, false, 1.5 * u)
	draw_rect(Rect2(o + Vector2(2, 2) * u, Vector2(pw, ph) - Vector2(4, 4) * u), Color(GOLD, 0.35), false, 1.0)
	# fregio a denti in basso
	for i in range(int(pw / (8.0 * u))):
		var fx := o.x + 4.0 * u + i * 8.0 * u
		draw_rect(Rect2(fx, o.y + ph - 3.0 * u, 4.0 * u, 2.0 * u), Color(LAPIS if i % 2 == 0 else GOLD, 0.6))
	# ankh
	_ankh(o + Vector2(14, 17) * u, u, Color(1, 0.4, 0.3) if p.hp / maxf(1.0, p.max_hp) < 0.33 and int(Time.get_ticks_msec() / 250.0) % 2 == 0 else GOLD)
	# vita: cartiglio con la barra
	var bx := o.x + 26.0 * u
	var by := o.y + 6.0 * u
	var bw := 128.0 * u
	var bh := 12.0 * u
	var frac := clampf(p.hp / maxf(1.0, p.max_hp), 0.0, 1.0)
	var trail := clampf(shown_hp / maxf(1.0, p.max_hp), 0.0, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.04, 0.05)
	sb.set_corner_radius_all(int(6 * u))
	sb.border_color = GOLD
	sb.set_border_width_all(maxi(1, int(1.5 * u)))
	draw_style_box(sb, Rect2(bx - 2 * u, by - 2 * u, bw + 4 * u, bh + 4 * u))
	if trail > frac:
		draw_rect(Rect2(bx + bw * frac, by, bw * (trail - frac), bh), Color(1, 0.85, 0.6))
	var hp_col := Color(0.82, 0.16, 0.14) if frac > 0.33 else Color(1.0, 0.3, 0.2)
	draw_rect(Rect2(bx, by, bw * frac, bh), hp_col)
	draw_rect(Rect2(bx, by, bw * frac, bh * 0.35), hp_col.lightened(0.35))
	if p.shield > 0.0:
		draw_rect(Rect2(bx, by + bh - 3 * u, bw * clampf(p.shield / maxf(1.0, p.max_hp), 0.0, 1.0), 3 * u), Boons.god_color("iside"))
	if p.poison_t > 0.0:
		draw_rect(Rect2(bx, by, bw * frac, bh), Color(0.45, 0.95, 0.35, 0.35 + 0.15 * sin(Time.get_ticks_msec() / 90.0)))
	var hp_txt := "%d / %d" % [ceili(p.hp), int(p.max_hp)]
	var fs := _fs(9)
	var tw := font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, Vector2(bx + (bw - tw) / 2.0, by + bh - 2.0 * u), hp_txt, fs, Color(1, 0.96, 0.9))
	var row := by + bh + 5.0 * u
	# Sekhem
	if sek:
		var sf := clampf(Run.sekhem / Run.SEKHEM_MAX, 0.0, 1.0)
		draw_rect(Rect2(bx, row - 1 * u, bw, 4 * u), Color(0, 0, 0, 0.7))
		var sc := Color(1, 0.85, 0.35) if sf < 1.0 else Color(1, 0.95, 0.6).lerp(Color.WHITE, 0.4 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 100.0)))
		draw_rect(Rect2(bx, row - 1 * u, bw * sf, 4 * u), sc)
		row += 6.0 * u
	# Ka: il geroglifico delle due braccia alzate, con il numero
	var ky := row + 9.0 * u
	var kp := 1.0 + 0.35 * ka_pop
	_ka_glyph(Vector2(bx + 5 * u, ky - 4 * u), u * kp)
	var ka_txt := "%d" % Run.ka
	_text(title, Vector2(bx + 14 * u, ky), ka_txt, _fs(10 + int(3 * ka_pop)), GOLD.lerp(Color.WHITE, ka_pop * 0.6))
	var rx := bx + 18 * u + title.get_string_size(ka_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(10)).x + 10 * u
	_text(title, Vector2(rx, ky), game.hud_room, _fs(8), Color(0.95, 0.88, 0.72))
	# l'amuleto al collo, accanto al riquadro: icona, livello (pallini) e, per lo Scettro
	# Was, le stanze pulite contate. Se non lo vedi, ti dimentichi di averlo.
	if Run.amulet != "" and not Run.training:
		var ac := o + Vector2(pw + 14.0 * u, 13.0 * u)
		draw_circle(ac, 9.5 * u, Color(0.05, 0.04, 0.09, 0.85))
		draw_arc(ac, 9.5 * u, 0, TAU, 24, GOLD, 1.3 * u)
		Amulets.draw_icon(self, Run.amulet, ac + Vector2(0, 1) * u, 0.75 * u)
		for i in range(Run.amulet_level):
			draw_circle(ac + Vector2((i - (Run.amulet_level - 1) / 2.0) * 4.0, 12.5) * u, 1.4 * u, GOLD)
		if Run.amulet == "was" and Run.was_stacks > 0:
			_text(title, ac + Vector2(-9, 25) * u, "+%d%%" % int(Run.was_stacks * Amulets.val()), _fs(8), GOLD)
	# Occhio di Horus
	if touch:
		return
	var c := o + Vector2(pw - 24.0 * u, ph / 2.0 - 1.0 * u)
	var r := 14.0 * u * (1.0 + 0.15 * eye_pop)
	var charges: int = p.eye_charges
	var max_ch: int = Run.eye_charges()
	var full: bool = charges >= max_ch
	draw_circle(c, r, Color(0.02, 0.03, 0.08, 0.9))
	if not full:
		var k := 1.0 - clampf(p.eye_cd / maxf(0.1, p.eye_cd_max()), 0.0, 1.0)
		var pts := PackedVector2Array([c])
		for i in range(25):
			pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * k * i / 24.0) * (r - 1.5 * u))
		if k > 0.01:
			draw_colored_polygon(pts, Color(LAPIS, 0.55))
	if p.eye_ready():
		draw_circle(c, r - 1.5 * u, Color(0.25, 0.55, 0.95, 0.35 + 0.25 * eye_pop))
	draw_arc(c, r, 0, TAU, 32, GOLD if p.eye_ready() else GOLD_DARK, 1.5 * u)
	_wedjat(c, u * 0.9, Color(1, 0.95, 0.8) if p.eye_ready() else Color(0.55, 0.5, 0.45))
	if max_ch > 1:
		for i in range(max_ch):
			var pp := c + Vector2((i - (max_ch - 1) / 2.0) * 6.0 * u, r + 3.0 * u)
			draw_circle(pp, 2.2 * u, Color(0, 0, 0, 0.8))
			draw_circle(pp, 1.6 * u, GOLD if i < charges else Color(0.3, 0.25, 0.2))

var hu := 1.0

func _fs(n: int) -> int:
	return maxi(7, roundi(n * hu * 1.1))

func _ankh(c: Vector2, u: float, col: Color) -> void:
	draw_arc(c + Vector2(0, -6) * u, 3.8 * u, 0, TAU, 16, col, 2.2 * u)
	draw_line(c + Vector2(-6, -1) * u, c + Vector2(6, -1) * u, col, 2.4 * u)
	draw_line(c + Vector2(0, -2) * u, c + Vector2(0, 11) * u, col, 2.6 * u)

func _ka_glyph(c: Vector2, u: float) -> void:
	# due braccia alzate unite in basso
	var col := GOLD
	draw_line(c + Vector2(-4, 4) * u, c + Vector2(4, 4) * u, col, 1.8 * u)
	draw_line(c + Vector2(-4, 4) * u, c + Vector2(-4, -3) * u, col, 1.8 * u)
	draw_line(c + Vector2(4, 4) * u, c + Vector2(4, -3) * u, col, 1.8 * u)
	draw_line(c + Vector2(-4, -3) * u, c + Vector2(-5.5, -4.5) * u, col, 1.5 * u)
	draw_line(c + Vector2(4, -3) * u, c + Vector2(5.5, -4.5) * u, col, 1.5 * u)

func _wedjat(c: Vector2, u: float, col: Color) -> void:
	# l'Occhio di Horus: sopracciglio, occhio, pupilla, la goccia e la spirale sotto
	draw_line(c + Vector2(-8, -6) * u, c + Vector2(8, -6.5) * u, col, 1.6 * u)
	var eye := PackedVector2Array()
	for i in range(13):
		var k := i / 12.0
		eye.append(c + Vector2(lerpf(-8, 8, k), -sin(k * PI) * 4.0) * u)
	for i in range(13):
		var k := 1.0 - i / 12.0
		eye.append(c + Vector2(lerpf(-8, 8, k), sin(k * PI) * 2.5) * u)
	draw_polyline(eye, col, 1.3 * u)
	draw_circle(c + Vector2(0, -0.5) * u, 2.2 * u, col)
	draw_line(c + Vector2(-2, 2.5) * u, c + Vector2(-3, 8) * u, col, 1.4 * u)
	draw_arc(c + Vector2(3, 6) * u, 2.5 * u, -PI * 0.9, PI * 0.6, 10, col, 1.3 * u)

func _text(font: Font, pos: Vector2, text: String, font_size: int, col: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)



## Anello di luce che si allarga attorno al giocatore quando prende un dono.
