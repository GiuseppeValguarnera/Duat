class_name OptionsMenu
extends CanvasLayer
## Le Opzioni, in un menu solo, raggiungibile dalla pausa ovunque: Sala, Casa della Vita, Armeria,
## stanze, Oasi, boss. Sullo stile di Hades 2: un pannello scuro, una riga per voce con il valore a
## destra tra due frecce, la riga scelta illuminata d'oro e la spiegazione in fondo.
## Pad e tastiera: su e giù per scegliere, sinistra e destra (o conferma) per cambiare, Esc / B per
## chiudere. Telefono e mouse: si toccano le frecce o la riga.
## Mentre è aperto il gioco è fermo; alla chiusura torna come era (in pausa o no) e salva.

signal closed

## Voci in più in fondo, [[testo, Callable]]: la Sala ci mette aggiornamento, feedback e uscita.
var extra: Array = []

const GOLD := Color(0.94, 0.72, 0.3)
const TEXT := Color(0.95, 0.9, 0.8)
const SOFT := Color(0.66, 0.6, 0.5)
const TEXT_SIZES := ["Normale", "Grande", "Molto grande"]

var rows: Array = []                    # una voce per riga: {"id", "btn", "value"}
var desc: Label
var was_paused := false
var focus_id := ""
var root: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	was_paused = get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()


## Le voci: id, nome, spiegazione.
func _items() -> Array:
	var out := [
		["musica", Lang.t("Volume della musica"), Lang.t("Quanto è forte la musica.")],
		["effetti", Lang.t("Volume degli effetti"), Lang.t("Colpi, passi, nemici, ricompense: tutti i suoni tranne la musica.")],
		["autoaim", Lang.t("Mira automatica"), Lang.t("Con il telefono e con il pad i colpi vanno da soli verso il nemico più vicino. Con il mouse non agisce: si colpisce dove punta il mouse.")],
		["vibration", Lang.t("Vibrazione"), Lang.t("Il telefono o il pad vibrano quando vieni colpito e nei colpi più forti.")],
		["text", Lang.t("Grandezza del testo"), Lang.t("Ingrandisce le scritte delle finestre e dell'interfaccia. Le finestre già aperte cambiano subito, il resto alla prossima stanza.")],
		["lang", Lang.t("Lingua"), Lang.t("Italiano o inglese.")],
		["tutorial", Lang.t("Suggerimenti del tutorial"), Lang.t("I consigli che compaiono le prime volte, in una pergamena a lato dello schermo.")],
		["feather", Lang.t("Piuma di Ma'at"), Lang.t("Una modalità per chi vuole un aiuto. Un quarto di nemici in meno nelle ondate, nemici più lenti del 10%, e subisci il 10% di danni in meno, un altro 2% a ogni morte, fino al 30%. In cambio custodisci il 40% del Ka, e lapislazzuli, cuori, premi del serdab e Lacrime valgono la metà; niente Lacrime per la prima vittoria con un'arma. Il Peso del Cuore non conta finché è attiva. La storia va avanti comunque.")],
		["shake", Lang.t("Scossa dello schermo"), Lang.t("La telecamera trema ai colpi forti. Spegnila se ti dà fastidio.")],
		["hitstop", Lang.t("Pausa d'impatto"), Lang.t("Il gioco si ferma per un istante quando un colpo va a segno.")],
	]
	# l'ultimo crash registrato nella versione web (scripts/diag.gd): premendo si cancella
	var problem := Diag.last_problem()
	if problem != "":
		out.append(["problema", Lang.t("Ultimo problema"), problem + "\n" + Lang.t("Premi per cancellarlo.")])
	for i in range(extra.size()):
		out.append(["extra%d" % i, extra[i][0], ""])
	return out


## Il valore scritto a destra della riga.
func _value(id: String) -> String:
	match id:
		"musica":
			return "%d%%" % roundi(Sfx.volumes.get("musica", 0.7) * 100.0)
		"effetti":
			return "%d%%" % roundi(Sfx.volumes.get("effetti", 1.0) * 100.0)
		"autoaim":
			return _onoff(Meta.options.get("autoaim", true))
		"vibration":
			return _onoff(Meta.options.get("vibration", true))
		"text":
			return Lang.t(TEXT_SIZES[clampi(int(Meta.options.get("text", 0)), 0, 2)])
		"lang":
			return "English" if Lang.is_en() else "Italiano"
		"tutorial":
			return _onoff(not Meta.tutorial_done)
		"feather":
			return Lang.t("ATTIVA  (-%d%% danni)") % roundi(Run.feather_guard() * 100.0) if Meta.feather else Lang.t("spenta")
		"shake":
			return _onoff(Meta.options.get("shake", true))
		"hitstop":
			return _onoff(Meta.options.get("hitstop", true))
		"problema":
			return Diag.last_problem_short()
	return ""


func _onoff(on: bool) -> String:
	return Lang.t("sì") if on else Lang.t("no")


## Cambia il valore: `dir` -1 o +1 (conferma = +1). Le voci in più si eseguono.
func _change(id: String, dir: int) -> void:
	var rebuild := false
	match id:
		"musica", "effetti":
			var v: float = Sfx.volumes.get(id, 0.7 if id == "musica" else 1.0)
			Sfx.set_volume(id, snappedf(clampf(v + 0.1 * dir, 0.0, 1.0), 0.01))
			if id == "effetti":
				Sfx.play("ui", 0.0)
		"autoaim", "vibration", "shake", "hitstop":
			Meta.options[id] = not Meta.options.get(id, true)
			if id == "vibration" and Meta.options[id]:
				Fx.vibrate(0.12, 0.6)
		"text":
			Meta.options["text"] = posmod(int(Meta.options.get("text", 0)) + dir, 3)
			Fx.apply_text_scale()
			rebuild = true
		"lang":
			var next := "it" if Lang.is_en() else "en"
			Meta.options["lang"] = next
			Lang.apply(next)
			rebuild = true
		"tutorial":
			Meta.tutorial_done = not Meta.tutorial_done
		"feather":
			Meta.feather = not Meta.feather
		"problema":
			Diag.clear()
			rebuild = true
		_:
			if id.begins_with("extra"):
				var i := int(id.substr(5))
				var cb: Callable = extra[i][1]
				_close()
				cb.call()
				return
	Sfx.play("ui", 0.0)
	Meta.save()
	if rebuild:
		focus_id = id
		_build()
		return
	_refresh()


func _refresh() -> void:
	for r in rows:
		(r["value"] as Label).text = _value(r["id"])


func _build() -> void:
	if root != null:
		root.queue_free()
	rows.clear()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var vs := get_viewport().get_visible_rect().size
	var w := minf(440.0 * Fx.ui, vs.x - 24.0)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.08, 0.94)
	sb.border_color = Color(GOLD, 0.55)
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.set_content_margin_all(10.0 * Fx.ui)
	sb.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(w, 0)
	root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(2 * Fx.ui))
	panel.add_child(col)
	var title := UiStyle.heading(Lang.t("Opzioni"), 15, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	col.add_child(_rule(w * 0.7))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, minf(vs.y * 0.62, 11 * 22.0 * Fx.ui))
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", int(1 * Fx.ui))
	scroll.add_child(list)
	var first: Button = null
	var want: Button = null
	for it in _items():
		var row := _row(it[0], it[1], w - 24.0 * Fx.ui)
		list.add_child(row["btn"])
		rows.append(row)
		if first == null:
			first = row["btn"]
		if it[0] == focus_id:
			want = row["btn"]
	col.add_child(_rule(w * 0.7))
	desc = UiStyle.label("", 8, SOFT, false, w - 24.0 * Fx.ui)
	desc.custom_minimum_size = Vector2(0, 30.0 * Fx.ui)
	col.add_child(desc)
	var hint := UiStyle.label(Lang.t("Tocca le frecce per cambiare · tocca fuori per chiudere") if Fx.device == "touch" else Lang.t("Su e giù per scegliere · sinistra e destra per cambiare · Esc / B per chiudere"), 7, Color(SOFT, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	# tocco o clic fuori dal pannello: chiude
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_close())
	# se non entra nello schermo (telefono, testo grande) si accorcia la lista, che scorre
	var over := panel.get_combined_minimum_size().y - (vs.y - 8.0)
	if over > 0.0:
		scroll.custom_minimum_size.y = maxf(40.0 * Fx.ui, scroll.custom_minimum_size.y - over)
	panel.reset_size()
	panel.position = (vs - panel.get_combined_minimum_size()) / 2.0
	var focus_btn: Button = want if want != null else first
	focus_btn.grab_focus.call_deferred()


func _rule(width: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(GOLD, 0.45)
	r.custom_minimum_size = Vector2(width, 1.0 * Fx.ui)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Una riga: il nome a sinistra, a destra "‹ valore ›". La riga è un pulsante (il fuoco del pad e
## della tastiera), le frecce sono pulsanti a parte per il dito e il mouse.
func _row(id: String, text: String, width: float) -> Dictionary:
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(width, 22.0 * Fx.ui)
	btn.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxEmpty.new()
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(GOLD, 0.16)
	focus.border_color = Color(GOLD, 0.8)
	focus.border_width_left = 3
	for st in ["normal", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(st, normal)
	btn.add_theme_stylebox_override("hover", focus)
	btn.add_theme_stylebox_override("focus", focus)
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 8.0 * Fx.ui
	hb.offset_right = -4.0 * Fx.ui
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)
	var name_lbl := UiStyle.label(text, 9, TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(name_lbl)
	var value := UiStyle.label(_value(id), 9, GOLD)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_extra := id.begins_with("extra")
	if not is_extra:
		hb.add_child(_arrow("‹", id, -1))
		value.custom_minimum_size = Vector2(110.0 * Fx.ui, 0)
		hb.add_child(value)
		hb.add_child(_arrow("›", id, 1))
	btn.pressed.connect(_change.bind(id, 1))
	btn.focus_entered.connect(func() -> void:
		var sc := btn.get_parent().get_parent() as ScrollContainer
		if sc != null:
			sc.ensure_control_visible(btn)
		focus_id = id
		desc.text = _desc_of(id)
		Sfx.play("ui", 0.0))
	btn.mouse_entered.connect(btn.grab_focus)
	return {"id": id, "btn": btn, "value": value}


func _arrow(sym: String, id: String, dir: int) -> Button:
	var a := Button.new()
	a.text = sym
	a.flat = true
	a.focus_mode = Control.FOCUS_NONE
	a.mouse_filter = Control.MOUSE_FILTER_STOP
	a.custom_minimum_size = Vector2(22.0 * Fx.ui, 20.0 * Fx.ui)     # abbastanza grandi per il dito
	a.add_theme_font_size_override("font_size", Fx.fs(13))
	a.add_theme_color_override("font_color", GOLD)
	a.pressed.connect(_change.bind(id, dir))
	return a


func _desc_of(id: String) -> String:
	for it in _items():
		if it[0] == id:
			return it[2]
	return ""


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if focus_id == "" or focus_id.begins_with("extra"):
		return
	var dir := 0
	if event.is_action_pressed("ui_left"):
		dir = -1
	elif event.is_action_pressed("ui_right"):
		dir = 1
	if dir != 0:
		get_viewport().set_input_as_handled()
		_change(focus_id, dir)


func _close() -> void:
	if not is_inside_tree():
		return
	Meta.save()
	get_tree().paused = was_paused
	closed.emit()
	queue_free()
