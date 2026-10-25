extends RefCounted
## Le carte di papiro delle finestre di scelta (doni, Anubi, patti di Set). Prima stavano in
## game.gd: sono state spostate qui nel riordino del codice, uguali.
## `c` = {"tag", "name", "body", "cost", "gain", "loss", "sections", "color", "heavy"}.

const TriIcon := preload("res://scripts/ui/tri_icon.gd")


## Una carta di papiro. Il testo completo resta anche nei metadati (lo usa il bot di playtest).
static func make(c: Dictionary, card_w: float) -> Button:
	var accent: Color = c["color"]
	var btn := Button.new()
	UiStyle.papyrus_button(btn, accent)
	btn.custom_minimum_size = Vector2(card_w, 0)
	btn.pivot_offset = Vector2(card_w / 2.0, 0)
	btn.set_meta("text", "%s\n%s\n%s\n%s\n%s\n%s" % [c.get("tag", ""), c["name"], c.get("body", ""), c.get("cost", ""), c.get("gain", ""), c.get("loss", "")])
	for sec in c.get("sections", []):
		btn.set_meta("text", String(btn.get_meta("text")) + "\n%s: %s" % [sec[0], sec[1]])
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, int(9 * Fx.ui))
	pad.add_theme_constant_override("margin_top", int(7 * Fx.ui))
	pad.add_theme_constant_override("margin_bottom", int(7 * Fx.ui))
	btn.add_child(pad)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", int(3 * Fx.ui))
	pad.add_child(col)
	var inner := card_w - 18.0 * Fx.ui
	if c.get("tag", "") != "":
		var tag := UiStyle.label(c["tag"], 7, (UiStyle.INK_RED if c.get("heavy", false) else accent.darkened(0.45)), true, inner)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(tag)
	var nm := UiStyle.label(c["name"], 12, UiStyle.INK, true, inner)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(nm)
	var rule := ColorRect.new()
	rule.color = accent.darkened(0.25)
	rule.custom_minimum_size = Vector2(inner * 0.6, 1.5 * Fx.ui)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)
	if c.get("body", "") != "":
		var body := UiStyle.label(c["body"], 8 if Fx.mobile else 9, UiStyle.INK_SOFT, false, inner)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(body)
	# sul telefono lo spazio in altezza è poco: il prezzo resta nel riassunto ▼ in fondo
	if c.get("cost", "") != "":
		var cost := UiStyle.label("Prezzo: " + c["cost"], 7 if Fx.mobile else 8, UiStyle.INK_RED, false, inner)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(cost)
	# i patti di Set hanno due sezioni scritte per esteso: la maledizione e il potere
	for sec in c.get("sections", []):
		var head := UiStyle.label(sec[0], 7, sec[2], true, inner)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(head)
		var txt := UiStyle.label(sec[1], 8 if Fx.mobile else 9, sec[2].darkened(0.1), false, inner)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(txt)
	# riassunto in fondo
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var lines := []
	if c.get("gain", "") != "":
		lines.append(summary_row(c["gain"], true, inner))
	if c.get("loss", "") != "":
		lines.append(summary_row(c["loss"], false, inner))
	for ln in lines:
		col.add_child(ln)
	# l'altezza giusta si conosce solo dopo che il testo è andato a capo
	var fit := func() -> void:
		if is_instance_valid(btn) and is_instance_valid(col):
			btn.custom_minimum_size.y = col.get_combined_minimum_size().y + 16.0 * Fx.ui
	col.minimum_size_changed.connect(fit)
	fit.call_deferred()
	return btn


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
