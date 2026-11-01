extends RefCounted
## Le carte di papiro delle finestre di scelta (doni, Anubi, patti di Set, altare dell'Oasi,
## Seconda Barca). `c` = {"tag", "name", "body", "cost", "gain", "loss", "sections", "color", "heavy"}.
##
## La carta si adatta allo spazio che ha (`max_h`): prima rimpicciolisce il testo fino a un minimo
## leggibile; se non basta, la parte centrale (descrizione, prezzo, sezioni) scorre, con le
## freccette ▲ ▼ che dicono che c'è dell'altro (si trascina col dito, o su/giù con tastiera e pad).
## La carta scorrevole è salvata nei metadati "scroll" (game.gd la usa per i tasti).

const TriIcon := preload("res://scripts/ui/tri_icon.gd")
const BODY_SIZES := [9, 8, 7]                 ## dal più grande al minimo leggibile
const NAME_SIZES := [12, 11, 10]


static func _h(text: String, font: Font, size_px: int, width: float) -> float:
	if text == "":
		return 0.0
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px).y


## Una carta di papiro. Il testo completo resta anche nei metadati (lo usa il bot di playtest).
static func make(c: Dictionary, card_w: float, max_h: float = 0.0) -> Button:
	var accent: Color = c["color"]
	var btn := Button.new()
	UiStyle.papyrus_button(btn, accent)
	btn.custom_minimum_size = Vector2(card_w, 0)
	btn.pivot_offset = Vector2(card_w / 2.0, 0)
	btn.set_meta("text", "%s\n%s\n%s\n%s\n%s\n%s" % [c.get("tag", ""), c["name"], c.get("body", ""), c.get("cost", ""), c.get("gain", ""), c.get("loss", "")])
	for sec in c.get("sections", []):
		btn.set_meta("text", String(btn.get_meta("text")) + Lang.t("\n%s: %s") % [sec[0], sec[1]])
	var mx := 9.0 * Fx.ui
	var my := 7.0 * Fx.ui
	var sep := 3.0 * Fx.ui
	var inner := card_w - 2.0 * mx
	var bf := UiStyle.body_font()
	var tf := UiStyle.title_font()
	# quanto spazio serve con ogni grandezza del testo: si sceglie la più grande che ci sta
	var name_size: int = NAME_SIZES[0]
	var body_size: int = BODY_SIZES[0] if not Fx.mobile else BODY_SIZES[1]
	var fixed := 0.0
	var mid := 0.0
	var arrows_w := 7.0 * Fx.ui
	for step in range(NAME_SIZES.size() + BODY_SIZES.size()):
		fixed = 2.0 * my + 16.0 * Fx.ui
		if c.get("tag", "") != "":
			fixed += _h(c["tag"], tf, Fx.fs(7), inner) + sep
		fixed += _h(c["name"], tf, Fx.fs(name_size), inner) + sep + 1.5 * Fx.ui + sep
		for k in ["gain", "loss"]:
			if c.get(k, "") != "":
				fixed += tf.get_height(Fx.fs(9)) + sep
		mid = _mid_h(c, bf, tf, body_size, inner, sep)
		if max_h <= 0.0 or fixed + mid <= max_h:
			break
		# prima il testo, poi il titolo, fino al minimo
		var bi := BODY_SIZES.find(body_size)
		if bi < BODY_SIZES.size() - 1:
			body_size = BODY_SIZES[bi + 1]
		else:
			var ni := NAME_SIZES.find(name_size)
			if ni < NAME_SIZES.size() - 1:
				name_size = NAME_SIZES[ni + 1]
	var scrolls := max_h > 0.0 and fixed + mid > max_h
	var mid_w := inner - (arrows_w if scrolls else 0.0)
	if scrolls:
		mid = _mid_h(c, bf, tf, body_size, mid_w, sep)

	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, int(mx))
	pad.add_theme_constant_override("margin_top", int(my))
	pad.add_theme_constant_override("margin_bottom", int(my))
	btn.add_child(pad)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", int(sep))
	pad.add_child(col)
	if c.get("tag", "") != "":
		var tag := UiStyle.label(c["tag"], 7, (UiStyle.INK_RED if c.get("heavy", false) else accent.darkened(0.45)), true, inner)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(tag)
	var nm := UiStyle.label(c["name"], name_size, UiStyle.INK, true, inner)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(nm)
	var rule := ColorRect.new()
	rule.color = accent.darkened(0.25)
	rule.custom_minimum_size = Vector2(inner * 0.6, 1.5 * Fx.ui)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)
	# la parte centrale: descrizione, prezzo, sezioni dei patti; se non ci sta, scorre
	var mid_box := VBoxContainer.new()
	mid_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid_box.add_theme_constant_override("separation", int(sep))
	_fill_mid(mid_box, c, body_size, mid_w)
	if scrolls:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 0)
		col.add_child(row)
		var sc := ScrollContainer.new()
		sc.mouse_filter = Control.MOUSE_FILTER_IGNORE         # i tocchi vanno alla carta, il trascinamento a DragScroll
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		sc.custom_minimum_size = Vector2(mid_w, maxf(24.0 * Fx.ui, max_h - fixed))
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sc)
		sc.add_child(mid_box)
		var arrows := VBoxContainer.new()
		arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrows.custom_minimum_size = Vector2(arrows_w, 0)
		row.add_child(arrows)
		var up := TriIcon.new()
		up.up = true
		up.color = accent.darkened(0.3)
		up.custom_minimum_size = Vector2(6, 6) * Fx.ui
		up.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrows.add_child(up)
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrows.add_child(gap)
		var down := TriIcon.new()
		down.up = false
		down.color = accent.darkened(0.3)
		down.custom_minimum_size = Vector2(6, 6) * Fx.ui
		down.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrows.add_child(down)
		var bar := sc.get_v_scroll_bar()
		var sc_ref: WeakRef = weakref(sc)
		var refresh := func(_v: float = 0.0) -> void:
			var s: ScrollContainer = sc_ref.get_ref()
			if s == null:
				return
			var b := s.get_v_scroll_bar()
			up.modulate.a = 1.0 if b.value > 0.5 else 0.15
			down.modulate.a = 1.0 if b.value < b.max_value - b.page - 0.5 else 0.15
		bar.value_changed.connect(refresh)
		bar.changed.connect(refresh)
		refresh.call_deferred()
		btn.set_meta("scroll", sc)
	else:
		col.add_child(mid_box)
	# riassunto in fondo
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	if c.get("gain", "") != "":
		col.add_child(summary_row(c["gain"], true, inner))
	if c.get("loss", "") != "":
		col.add_child(summary_row(c["loss"], false, inner))
	# l'altezza giusta si conosce solo dopo che il testo è andato a capo (riferimenti deboli: se
	# il menu si chiude subito la carta sparisce prima che la chiamata arrivi)
	var btn_ref: WeakRef = weakref(btn)
	var col_ref: WeakRef = weakref(col)
	var fit := func() -> void:
		var b: Button = btn_ref.get_ref()
		var cc: Control = col_ref.get_ref()
		if b != null and cc != null:
			var h := cc.get_combined_minimum_size().y + 2.0 * my + 2.0 * Fx.ui
			b.custom_minimum_size.y = minf(h, max_h) if max_h > 0.0 else h
	col.minimum_size_changed.connect(fit)
	fit.call_deferred()
	return btn


static func _mid_h(c: Dictionary, bf: Font, tf: Font, body_size: int, w: float, sep: float) -> float:
	var h := 0.0
	if c.get("body", "") != "":
		h += _h(c["body"], bf, Fx.fs(body_size + 1), w) + sep
	if c.get("cost", "") != "":
		h += _h(Lang.t("Prezzo: ") + c["cost"], bf, Fx.fs(body_size), w) + sep
	for sec in c.get("sections", []):
		h += _h(sec[0], tf, Fx.fs(7), w) + sep
		h += _h(sec[1], bf, Fx.fs(body_size + 1), w) + sep
	return h


static func _fill_mid(box: VBoxContainer, c: Dictionary, body_size: int, w: float) -> void:
	if c.get("body", "") != "":
		var body := UiStyle.label(c["body"], body_size, UiStyle.INK_SOFT, false, w)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(body)
	if c.get("cost", "") != "":
		var cost := UiStyle.label(Lang.t("Prezzo: ") + c["cost"], body_size - 1, UiStyle.INK_RED, false, w)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(cost)
	# i patti di Set hanno due sezioni scritte per esteso: la maledizione e il potere
	for sec in c.get("sections", []):
		var head := UiStyle.label(sec[0], 7, sec[2], true, w)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(head)
		var txt := UiStyle.label(sec[1], body_size, sec[2].darkened(0.1), false, w)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(txt)


## La carta scelta (prima del secondo tocco): cornice accesa e leggermente più grande.
static func set_selected(btn: Button, accent: Color, on: bool) -> void:
	if on:
		btn.add_theme_stylebox_override("normal", UiStyle.papyrus_box(accent.lightened(0.1)))
		btn.add_theme_stylebox_override("hover", UiStyle.papyrus_box(accent.lightened(0.1)))
		btn.z_index = 1
	else:
		btn.add_theme_stylebox_override("normal", UiStyle.papyrus_box())
		btn.add_theme_stylebox_override("hover", UiStyle.papyrus_box(accent.darkened(0.15)))
		btn.z_index = 0
	btn.pivot_offset = btn.size / 2.0
	btn.create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05) if on else Vector2.ONE, 0.12)


## Riga del riassunto in fondo alla carta: un triangolo disegnato (▲ vantaggio, ▼ prezzo) e il
## testo. Il triangolo è disegnato perché il carattere delle carte non ha quei simboli, e nel
## browser del telefono comparirebbero dei quadratini.
static func summary_row(text: String, gain: bool, inner: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(3 * Fx.ui))
	var col := UiStyle.INK_GREEN if gain else UiStyle.INK_RED
	var tri := TriIcon.new()
	tri.up = gain
	tri.color = col
	tri.custom_minimum_size = Vector2(6, 6) * Fx.ui
	tri.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tri)
	# su una riga sola, se serve con il carattere un po' più piccolo; solo se non basta va a capo,
	# e allora il triangolo resta accanto alla prima riga
	var avail := inner - 10.0 * Fx.ui
	var font := UiStyle.title_font()
	var sz := 9
	while sz > 7 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Fx.fs(sz)).x > avail:
		sz -= 1
	var l := UiStyle.label(text, sz, col, true)
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Fx.fs(sz)).x
	if tw > avail:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = avail
		tri.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		tri.custom_minimum_size.y = font.get_height(Fx.fs(sz)) * 0.8
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(l)
	return row


## Riceve i tasti e i tocchi mentre la finestra è aperta (il gioco è in pausa): li passa a game.gd.
class Keys extends Node:
	var game: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		if game != null and is_instance_valid(game):
			game._choice_input(event)
