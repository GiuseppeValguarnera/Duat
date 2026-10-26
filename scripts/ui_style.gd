class_name UiStyle
## Stile egizio dell'interfaccia: un solo carattere, Aref Ruqaa (il tratto ruvido di una penna di
## giunco su papiro), per titoli e testi; e "papiro" per carte, menu e riquadri. Prima i caratteri
## erano tre (Cinzel, Cinzel Decorative, Macondo) e lo stile non stava insieme.
## La trama del papiro è generata qui (fibre orizzontali e verticali, bordi bruniti), così non
## serve nessuna immagine esterna.

const INK := Color(0.2, 0.12, 0.05)              ## inchiostro scuro per il testo sul papiro
const INK_SOFT := Color(0.36, 0.25, 0.12)
const INK_RED := Color(0.55, 0.12, 0.08)         ## prezzi e maledizioni
const INK_GREEN := Color(0.12, 0.38, 0.16)       ## vantaggi
const GOLD := Color(0.94, 0.72, 0.3)

static var _font: Font
static var _font_regular: Font
static var _body: Font
static var _deco: Font
static var _shimmer: Shader
static var _textures := {}


## Il grassetto, per titoli e nomi.
static func title_font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/aref-ruqaa-bold.woff2")
	return _font


## Il carattere dei testi.
static func body_font() -> Font:
	if _body == null:
		_body = load("res://assets/fonts/aref-ruqaa.woff2")
	return _body


## Per i titoli grandi (il dio che parla, la morte, gli annunci): il grassetto.
static func deco_font() -> Font:
	if _deco == null:
		_deco = load("res://assets/fonts/aref-ruqaa-bold.woff2")
	return _deco


## Riflesso d'oro che scorre sul testo: i titoli non restano mai fermi.
static func shimmer(c: CanvasItem, strength: float = 0.75) -> void:
	if _shimmer == null:
		_shimmer = Shader.new()
		_shimmer.code = """
shader_type canvas_item;
uniform float strength = 0.75;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float p = fract((FRAGCOORD.x - FRAGCOORD.y * 0.7) / 520.0 - TIME * 0.28);
	float band = smoothstep(0.0, 0.06, p) * (1.0 - smoothstep(0.06, 0.13, p));
	c.rgb = mix(c.rgb, vec3(1.0, 0.97, 0.86), band * strength * step(0.35, c.a));
	COLOR = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _shimmer
	m.set_shader_parameter("strength", strength)
	c.material = m


static func title_font_regular() -> Font:
	if _font_regular == null:
		_font_regular = load("res://assets/fonts/aref-ruqaa.woff2")
	return _font_regular


## Trama di papiro con il bordo del colore indicato (in cache: si genera una volta sola).
static func papyrus_texture(border: Color, dark: bool = false) -> Texture2D:
	var key := border.to_html() + ("d" if dark else "")
	if _textures.has(key):
		return _textures[key]
	var w := 64
	var h := 64
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var base := Color(0.9, 0.81, 0.6) if not dark else Color(0.78, 0.66, 0.45)
	var rows := []
	for y in range(h):
		rows.append(rng.randf_range(-0.05, 0.05))
	var cols := []
	for x in range(w):
		cols.append(rng.randf_range(-0.025, 0.025))
	for y in range(h):
		for x in range(w):
			var c := base
			var v: float = rows[y] + cols[x] + rng.randf_range(-0.015, 0.015)
			c = c.lightened(v) if v > 0.0 else c.darkened(-v)
			# bordi bruniti: più scuri verso l'esterno
			var edge := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if edge < 6:
				c = c.darkened(0.06 * (6 - edge))
			if edge < 2:
				c = border
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


static func papyrus_box(border: Color = Color(0.5, 0.34, 0.15), dark: bool = false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = papyrus_texture(border, dark)
	sb.texture_margin_left = 8
	sb.texture_margin_right = 8
	sb.texture_margin_top = 8
	sb.texture_margin_bottom = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


## Riquadro scuro con il bordo d'oro (HUD, finestre sopra il gioco).
static func dark_box(alpha: float = 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.1, alpha)
	sb.border_color = Color(0.7, 0.52, 0.22)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Pulsante di papiro: inchiostro scuro, bordo del colore `accent` quando è selezionato.
static func papyrus_button(b: Button, accent: Color = GOLD) -> void:
	b.add_theme_stylebox_override("normal", papyrus_box())
	b.add_theme_stylebox_override("hover", papyrus_box(accent.darkened(0.15)))
	b.add_theme_stylebox_override("focus", papyrus_box(accent.darkened(0.15)))
	b.add_theme_stylebox_override("pressed", papyrus_box(accent.darkened(0.3), true))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_font_override("font", title_font())


## Etichetta già pronta: `title` usa il grassetto.
static func label(text: String, size: int, color: Color, title: bool = false, wrap_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", Fx.fs(size if title else size + 1))    # il testo un punto più grande dei titoli: si legge meglio
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", title_font() if title else body_font())
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_width, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Il riquadro del dialogo (Anubi nella Sala, Neith nel Cortile): papiro come le carte dei doni,
## nome in grassetto del colore del dio, testo in inchiostro. Prima era un rettangolo grigio.
static func talk_style(box: PanelContainer, name_label: Label, text_label: Label, accent: Color) -> void:
	box.add_theme_stylebox_override("panel", papyrus_box(accent.darkened(0.35)))
	name_label.add_theme_font_override("font", title_font())
	name_label.add_theme_color_override("font_color", accent.darkened(0.5))
	text_label.add_theme_font_override("font", body_font())
	text_label.add_theme_color_override("font_color", INK)
	text_label.add_theme_font_size_override("font_size", text_label.get_theme_font_size("font_size") + 1)


## Titolo grande: il grassetto con il riflesso d'oro che scorre.
static func heading(text: String, size: int, color: Color) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", deco_font())
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
	shimmer(l)
	return l
