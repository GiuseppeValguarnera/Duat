class_name SphinxUI
extends RefCounted
## Le finestre della Sfinge (blocco 17): il dialogo (testo a macchina da scrivere veloce, un tocco o un
## tasto lo completa, poi il menu), i modificatori e il Tesoro della Sfinge con l'anteprima.
## Tutte mettono il gioco in pausa e su telefono si rimpiccioliscono fino a stare nello schermo.

const SAND := Color(0.93, 0.78, 0.45)
const SEAL_COL := Color(0.98, 0.86, 0.4)


## Uno strato sopra a tutto, attivo anche col gioco in pausa.
static func layer(parent: Node, z: int = 28) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.layer = z
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(l)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.add_child(dim)
	return l


## Rimpicciolisce e mette il riquadro `pap` dentro lo schermo; `bottom` = attaccato in basso.
static func fit(pap: Control, vs: Vector2, bottom: bool = false) -> void:
	if not is_instance_valid(pap):
		return
	var sz := pap.get_combined_minimum_size()
	pap.size = sz
	var k := minf(1.0, minf((vs.y - 10.0) / maxf(1.0, sz.y), (vs.x - 10.0) / maxf(1.0, sz.x)))
	pap.scale = Vector2(k, k)
	pap.position = Vector2((vs.x - sz.x * k) / 2.0, (vs.y - sz.y * k - 6.0) if bottom else (vs.y - sz.y * k) / 2.0)


static func button(text: String, accent: Color = SAND, fs: int = 10) -> Button:
	var b := Button.new()
	b.text = text
	UiStyle.papyrus_button(b, accent)
	b.add_theme_font_size_override("font_size", Fx.fs(fs))
	return b


static func seals_text() -> String:
	return Lang.t("Sigilli della Sfinge: %d") % SphinxShop.seals()


## Il dialogo della Sfinge: righe a macchina da scrivere, poi (se ci sono) i pulsanti del menu.
## `entries` = [[testo, Callable], ...]; senza pulsanti, l'ultimo tocco chiama `done`.
class TalkBox extends Control:
	const CPS := 80.0
	var lines: Array = []
	var entries: Array = []
	var done := Callable()
	var statue: SphinxStatue = null
	var i := 0
	var shown := 0.0
	var text: Label
	var grid: GridContainer
	var pap: PanelContainer
	var hint: Label
	var vs := Vector2.ZERO
	var closing := false

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		process_mode = Node.PROCESS_MODE_ALWAYS
		vs = get_viewport().get_visible_rect().size
		var u: float = Fx.ui
		pap = PanelContainer.new()
		pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.6, 0.46, 0.2)))
		pap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pap)
		var w := minf(560.0 * u, vs.x - 20.0)
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(w, 0)
		col.add_theme_constant_override("separation", int(4 * u))
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pap.add_child(col)
		var head := HBoxContainer.new()
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(head)
		var nm := UiStyle.label(Lang.t("LA SFINGE"), 11, UiStyle.INK_RED, true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		head.add_child(UiStyle.label(SphinxUI.seals_text(), 8, UiStyle.INK_SOFT))
		text = UiStyle.label("", 10, UiStyle.INK, false, w)
		text.custom_minimum_size.y = 34.0 * u
		col.add_child(text)
		hint = UiStyle.label("▼", 9, UiStyle.INK_SOFT)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		col.add_child(hint)
		grid = GridContainer.new()
		grid.columns = 2 if vs.x < 520.0 else 3
		grid.add_theme_constant_override("h_separation", int(6 * u))
		grid.add_theme_constant_override("v_separation", int(4 * u))
		grid.visible = false
		col.add_child(grid)
		for e in entries:
			var b := SphinxUI.button(String(e[0]), SphinxUI.SAND, 9)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(_pick.bind(e[1]))
			grid.add_child(b)
		_show_line()

	func _show_line() -> void:
		text.text = String(lines[i]) if i < lines.size() else ""
		text.visible_characters = 0
		shown = 0.0
		hint.visible = false
		grid.visible = false
		if statue != null and is_instance_valid(statue):
			statue.speak(clampf(text.text.length() / CPS, 0.6, 2.4), i == 0 and randf() < 0.35)
		SphinxUI.fit.call_deferred(pap, vs, true)

	func _process(delta: float) -> void:
		if text.visible_characters >= 0 and text.visible_characters < text.text.length():
			shown += delta * CPS
			text.visible_characters = int(shown)
			if text.visible_characters >= text.text.length():
				_line_complete()

	func _line_complete() -> void:
		text.visible_characters = -1
		var last := i >= lines.size() - 1
		hint.visible = not (last and not entries.is_empty())
		if last and not entries.is_empty():
			grid.visible = true
			(grid.get_child(0) as Button).grab_focus.call_deferred()
		SphinxUI.fit.call_deferred(pap, vs, true)

	func _advance() -> void:
		if closing:
			return
		if text.visible_characters != -1:
			_line_complete()                  # un tocco completa subito la riga
			return
		if i < lines.size() - 1:
			i += 1
			Sfx.play("page", 0.05, -6.0)
			_show_line()
		elif entries.is_empty():
			_close(done)

	func _gui_input(event: InputEvent) -> void:
		var press: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
		if press:
			accept_event()
			_advance()

	func _input(event: InputEvent) -> void:
		if closing or grid.visible:
			return
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("attack"):
			get_viewport().set_input_as_handled()
			_advance()

	func _pick(cb: Callable) -> void:
		Sfx.play("ui", 0.0)
		_close(cb)

	func _close(cb: Callable) -> void:
		closing = true
		var l := get_parent()
		l.queue_free()
		if cb.is_valid():
			cb.call()


## Apre il dialogo; restituisce lo strato (si chiude da solo).
static func talk(parent: Node, lines: Array, entries: Array, done: Callable, statue: SphinxStatue) -> CanvasLayer:
	var l := layer(parent)
	var box := TalkBox.new()
	box.lines = lines
	box.entries = entries
	box.done = done
	box.statue = statue
	l.add_child(box)
	return l


# --- modificatori ------------------------------------------------------------------------------

static func open_mods(parent: Node, statue: SphinxStatue, on_close: Callable) -> void:
	var l := layer(parent)
	var vs := l.get_viewport().get_visible_rect().size
	var u: float = Fx.ui
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.6, 0.46, 0.2)))
	l.add_child(pap)
	var w := minf(500.0 * u, vs.x - 20.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(3 * u))
	pap.add_child(col)
	var h := UiStyle.label(Lang.t("Modificatori"), 13, UiStyle.INK, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var say := UiStyle.label("«" + SphinxLines.pick("mods") + "»", 8, UiStyle.INK_SOFT, false, w)
	say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(say)
	if statue != null:
		statue.speak(1.2)
	var total := UiStyle.label("", 10, UiStyle.INK_RED, true)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(total)
	if vs.y >= 450.0:                         # sul telefono lo spazio va alla lista
		col.add_child(UiStyle.label(Lang.t("Valgono per tutta la prova (massimo 3) e alzano il moltiplicatore del punteggio. I premi della settimana dipendono solo dall'ondata."), 8, UiStyle.INK_SOFT, false, w))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w, minf(190.0 * u, vs.y * 0.5))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	col.add_child(sc)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", int(3 * u))
	sc.add_child(rows)
	var refresh := func() -> void:
		var k := SphinxShop.mult(SphinxShop.mods_on())
		total.text = Lang.t("Moltiplicatore del punteggio: %s · attivi %d di %d") % [SphinxShop.mult_text(k), SphinxShop.mods_on().size(), SphinxShop.MAX_MODS]
		for b in rows.get_children():
			var m: String = b.get_meta("mod")
			var md: Dictionary = SphinxShop.mods()[m]
			var on := SphinxShop.has_mod(m)
			var lock := not SphinxShop.mod_unlocked(m)
			var bonus := ("+%.2f" % float(md["bonus"])).replace(".", ",") if Lang.code() == "it" else "+%.2f" % float(md["bonus"])
			var mark := "◆ " if on else ("▣ " if lock else "◇ ")
			var tail := (Lang.t("nel Tesoro · %d sigilli") % int(SphinxShop.MODS_IT[m]["shop"])) if lock else bonus
			(b as Button).text = "%s%s   %s" % [mark, md["name"], tail] + "\n" + String(md["desc"])
			(b as Button).modulate = Color(1, 1, 1, 0.55 if lock else 1.0)
	for m in SphinxShop.MOD_ORDER:
		var b := button("", Color(0.86, 0.4, 0.3), 8)
		b.set_meta("mod", m)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = w - 14.0
		b.pressed.connect(func() -> void:
			if not SphinxShop.toggle_mod(m):
				Fx.shake(2.0)
				Sfx.play("ui", 0.3, -4.0)
			else:
				Sfx.play("ui", 0.0)
			refresh.call())
		rows.add_child(b)
	refresh.call()
	var close := button(Lang.t("Fatto"))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void:
		l.queue_free()
		on_close.call())
	col.add_child(close)
	(rows.get_child(0) as Button).grab_focus.call_deferred()
	fit.call_deferred(pap, vs)


# --- Tesoro della Sfinge -------------------------------------------------------------------------

static func open_shop(parent: Node, statue: SphinxStatue, on_close: Callable) -> void:
	var l := layer(parent)
	var vs := l.get_viewport().get_visible_rect().size
	var u: float = Fx.ui
	var narrow := vs.x < vs.y                 # due colonne ogni volta che lo schermo è largo (telefono in orizzontale compreso)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.6, 0.46, 0.2)))
	l.add_child(pap)
	var w := minf(600.0 * u, vs.x - 20.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(3 * u))
	pap.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var h := UiStyle.label(Lang.t("Il Tesoro della Sfinge"), 13, UiStyle.INK, true)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h)
	var seals := UiStyle.label(seals_text(), 9, UiStyle.INK_RED, true)
	head.add_child(seals)
	col.add_child(UiStyle.label("«" + SphinxLines.pick("shop") + "»", 8, UiStyle.INK_SOFT, false, w))
	if statue != null:
		statue.speak(1.2)
	var body: BoxContainer = null
	if narrow:
		body = VBoxContainer.new()
	else:
		body = HBoxContainer.new()
	body.add_theme_constant_override("separation", int(6 * u))
	col.add_child(body)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w if narrow else w * 0.48, minf(200.0 * u, vs.y * (0.32 if narrow else 0.55)))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	body.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(w if narrow else w * 0.48, 0)
	detail.add_theme_constant_override("separation", int(3 * u))
	body.add_child(detail)
	var prev := Preview.new()
	prev.custom_minimum_size = Vector2(1, 56) * u
	detail.add_child(prev)
	var dn := UiStyle.label("", 11, UiStyle.INK, true, w * (1.0 if narrow else 0.46))
	detail.add_child(dn)
	var dd := UiStyle.label("", 8, UiStyle.INK_SOFT, false, w * (1.0 if narrow else 0.46))
	detail.add_child(dd)
	var ds := UiStyle.label("", 8, UiStyle.INK_GREEN, false, w * (1.0 if narrow else 0.46))
	detail.add_child(ds)
	var act := button(" ", SEAL_COL, 9)
	act.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail.add_child(act)
	var sel := [""]
	var labels := {}
	var row_text := func(id: String) -> String:
		var it: Dictionary = SphinxShop.items()[id]
		var state := ""
		if SphinxShop.owns(id):
			state = Lang.t("in uso") if SphinxShop.in_use(id) else Lang.t("tuo")
		else:
			state = Lang.t("%d sigilli") % int(it["cost"])
		return "%s   [%s]" % [it["name"], state]
	var show_item := func(id: String) -> void:
		sel[0] = id
		var it: Dictionary = SphinxShop.items()[id]
		prev.kind = String(it["kind"])
		prev.id = id
		prev.queue_redraw()
		dn.text = String(it["name"])
		dd.text = String(it["desc"])
		var kind := String(it["kind"])
		var owned := SphinxShop.owns(id)
		act.disabled = false
		if not owned:
			var miss := int(it["cost"]) - SphinxShop.seals()
			ds.text = Lang.t("Costa %d sigilli.") % int(it["cost"]) if miss <= 0 else Lang.t("Costa %d sigilli: te ne mancano %d.") % [int(it["cost"]), miss]
			act.text = Lang.t("Compra")
			act.disabled = miss > 0
		elif kind in ["ornament", "title", "frame"]:
			ds.text = Lang.t("È tuo.")
			act.text = Lang.t("Togli") if SphinxShop.in_use(id) else (Lang.t("Indossa") if kind == "ornament" else Lang.t("Usa"))
		else:
			ds.text = Lang.t("È tuo.")
			act.text = Lang.t("Preso")
			act.disabled = true
		if Fx.device == "touch" and not act.disabled:
			ds.text += "  " + Lang.t("(tocca di nuovo per confermare)")
	var do_act := func() -> void:
		var id: String = sel[0]
		if id == "":
			return
		var it: Dictionary = SphinxShop.items()[id]
		if not SphinxShop.owns(id):
			if SphinxShop.buy(id):
				Sfx.play("boon", 0.0)
				Fx.shake(2.0)
				if statue != null:
					statue.say(Lang.t("Un buon acquisto. Lo dico a tutti, ma con te lo penso."), 3.0, true)
			else:
				Fx.shake(2.0)
				return
		else:
			match String(it["kind"]):
				"ornament":
					SphinxShop.toggle_ornament(id)
				"title", "frame":
					SphinxShop.select(id)
				_:
					return
			Sfx.play("ui", 0.0)
		seals.text = SphinxUI.seals_text()
		for k in labels:
			(labels[k] as Button).text = row_text.call(k)
		show_item.call(id)
	act.pressed.connect(do_act)
	var first: Button = null
	for id in SphinxShop.ITEM_ORDER:
		var b := button(row_text.call(id), SEAL_COL, 8)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = (w if narrow else w * 0.48) - 14.0
		labels[id] = b
		b.focus_entered.connect(show_item.bind(id))
		b.mouse_entered.connect(show_item.bind(id))
		b.pressed.connect(func() -> void:
			# tocco: la prima volta mostra, la seconda conferma (come nelle altre finestre del gioco)
			if sel[0] == id:
				do_act.call()
			else:
				show_item.call(id))
		list.add_child(b)
		if first == null:
			first = b
	var close := button(Lang.t("Chiudi"))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void:
		l.queue_free()
		on_close.call())
	col.add_child(close)
	show_item.call(SphinxShop.ITEM_ORDER[0])
	first.grab_focus.call_deferred()
	fit.call_deferred(pap, vs)


## L'anteprima di un oggetto del Tesoro.
class Preview extends Control:
	var kind := ""
	var id := ""

	func _draw() -> void:
		var c := size / 2.0
		var k := size.y / 56.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.09, 0.06, 0.85))
		draw_set_transform(c, 0.0, Vector2(k, k))
		var gold := Color(0.95, 0.74, 0.3)
		var lapis := Color(0.2, 0.33, 0.72)
		match kind:
			"ornament":
				# la testa della Sfinge con l'ornamento
				draw_colored_polygon(PackedVector2Array([Vector2(-18, 18), Vector2(-14, -10), Vector2(0, -16), Vector2(14, -10), Vector2(18, 18)]), Color(0.86, 0.72, 0.42))
				for i in range(4):
					draw_line(Vector2(-13 + i, -6 + i * 6), Vector2(13 - i, -6 + i * 6), lapis, 1.4)
				draw_rect(Rect2(-8, -8, 16, 18), Color(0.88, 0.77, 0.57))
				draw_circle(Vector2(-4, -1), 1.2, Color(0.15, 0.1, 0.06))
				draw_circle(Vector2(4, -1), 1.2, Color(0.15, 0.1, 0.06))
				match id:
					"o_collare":
						for i in range(3):
							draw_arc(Vector2(0, 12), 8.0 + i * 3.0, 0.3, PI - 0.3, 14, [gold, lapis, gold][i], 2.2)
					"o_gioielli":
						draw_circle(Vector2(0, -12), 2.2, lapis)
						draw_arc(Vector2(-10, 4), 2.0, 0.0, TAU, 8, gold, 1.2)
						draw_arc(Vector2(10, 4), 2.0, 0.0, TAU, 8, gold, 1.2)
					"o_loti":
						for x in [-20.0, 20.0]:
							draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 22), Vector2(x - 2, 17), Vector2(x, 21), Vector2(x + 2, 17), Vector2(x + 4, 22)]), Color(0.97, 0.94, 0.88))
					"o_bracieri":
						for x in [-24.0, 24.0]:
							draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 10), Vector2(x + 5, 10), Vector2(x, 0)]), Color(1.0, 0.6, 0.22))
					"o_stendardi":
						for x in [-26.0, 26.0]:
							draw_rect(Rect2(x - 4, -22, 8, 24), lapis)
							draw_line(Vector2(x - 4, -20), Vector2(x + 4, -20), gold, 1.2)
			"mod":
				draw_circle(Vector2.ZERO, 16.0, Color(0.55, 0.15, 0.1))
				draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, gold, 1.5)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -10), Vector2(8, 6), Vector2(-8, 6)]), gold)
			"riddles":
				draw_rect(Rect2(-18, -12, 36, 24), Color(0.9, 0.82, 0.62))
				for i in range(4):
					draw_line(Vector2(-12, -6 + i * 5), Vector2(12, -6 + i * 5), Color(0.3, 0.2, 0.1), 1.0)
				draw_string(UiStyle.title_font(), Vector2(10, -16), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, gold)
			"title":
				draw_rect(Rect2(-24, -8, 48, 16), Color(0.25, 0.18, 0.1))
				draw_rect(Rect2(-24, -8, 48, 16), gold, false, 1.5)
				draw_line(Vector2(-16, 0), Vector2(16, 0), gold, 2.0)
			"frame":
				var fc := gold if id == "f_oro" else lapis
				draw_rect(Rect2(-22, -16, 44, 32), fc, false, 3.0)
				draw_rect(Rect2(-17, -11, 34, 22), Color(0.9, 0.82, 0.62))
				if id == "f_oro":
					for p in [Vector2(-22, -16), Vector2(22, -16), Vector2(-22, 16), Vector2(22, 16)]:
						draw_circle(p, 2.5, Color(0.85, 0.2, 0.2))
			"talk":
				draw_rect(Rect2(-20, -12, 40, 20), Color(0.97, 0.92, 0.8))
				draw_colored_polygon(PackedVector2Array([Vector2(-4, 8), Vector2(4, 8), Vector2(0, 14)]), Color(0.97, 0.92, 0.8))
				for i in range(3):
					draw_circle(Vector2(-8 + i * 8, -2), 1.8, Color(0.3, 0.2, 0.1))
			"tale":
				for i in range(3):
					draw_set_transform(c, 0.0, Vector2(k, k * 0.45))
					draw_arc(Vector2.ZERO, 6.0 + i * 6.0, 0.0, TAU, 24, Color(0.6, 0.85, 1.0, 0.9 - i * 0.25), 1.5)
				draw_set_transform(c, 0.0, Vector2(k, k))
			"favor":
				draw_arc(Vector2(0, 2), 14.0, PI, TAU, 16, gold, 2.5)
				draw_circle(Vector2(0, 2), 4.0, gold)
				draw_line(Vector2(-2, 6), Vector2(-6, 18), gold, 2.0)
				draw_line(Vector2(4, 6), Vector2(12, 14), gold, 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
