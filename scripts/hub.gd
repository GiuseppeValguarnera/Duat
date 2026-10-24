extends Node2D
## La Sala del Giudizio: dove ti risvegli tra una discesa e l'altra.
## - Anubi: parla con te, e le sue battute cambiano con le tue morti e vittorie.
## - Il Libro dei Morti: compri e attivi i capitoli con il Ka custodito.
## - La bilancia di Ma'at: mostra i tuoi progressi.
## - Il cancello a nord: inizia una nuova discesa.

const ROOM := Rect2(0, 0, 800, 400)       # larga come le stanze: niente bordi neri sugli schermi larghi
const WALL := 32.0
const TOP := 64.0
const PlayerScene := preload("res://scenes/player.tscn")
const DecorScript := preload("res://scripts/room_decor.gd")

var player
var spots := {}                       # nome -> posizione dei punti con cui interagire
var near := ""
var talk_lines: Array = []
var commented := false
var book: CanvasLayer = null           # finestra aperta (Libro dei Morti o Papiri di Thoth)
var book_kind := ""
var page_title: Label
var page_body: Label
var page_lore: Label
var page_action: Button                 ## pulsante sulla pagina di destra (per esempio: potenzia il capitolo)
var page_action_cb := Callable()
var papiri_entries: VBoxContainer
var codex: Array = []
var t := 0.0

@onready var world: Node2D = $World
@onready var hud: Label = $UI/Hud
@onready var prompt: Label = $UI/Prompt
@onready var help: Label = $UI/Help
@onready var talk_box: PanelContainer = $UI/Talk
@onready var talk_name: Label = $UI/Talk/Box/Name
@onready var talk_text: Label = $UI/Talk/Box/Text


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	# una discesa rimasta a metà (gioco chiuso, telefono che chiude la pagina): si riprende da lì
	if Run.has_saved_descent():
		var d := Run.load_descent()
		if not d.is_empty():
			Run.resume = d
			get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
			return
		Run.clear_descent()
	Run.in_hub = true
	Music.play("hub")
	Run.new_run()
	Fx.world = world
	var cx := ROOM.size.x / 2.0
	spots = {
		"anubi": Vector2(cx - 120.0, 200.0),
		"libro": Vector2(cx + 120.0, 200.0),
		"bilancia": Vector2(cx, 190.0),
		"cancello": Vector2(cx, TOP + 4.0),
		"papiri": Vector2(cx + 150.0, 322.0),
	}
	_build()
	Fx.scale_labels($UI)
	talk_box.visible = false
	if Meta.runs == 0 or Meta.last_end != "":
		_start_talk()


func _build() -> void:
	_solid(Rect2(0, 0, ROOM.size.x, TOP))
	_solid(Rect2(0, ROOM.size.y - WALL, ROOM.size.x, WALL))
	_solid(Rect2(0, 0, WALL, ROOM.size.y))
	_solid(Rect2(ROOM.size.x - WALL, 0, WALL, ROOM.size.y))
	_solid(Rect2(spots["anubi"] - Vector2(10, 8), Vector2(20, 12)))
	_solid(Rect2(spots["libro"] - Vector2(12, 6), Vector2(24, 12)))
	_solid(Rect2(spots["bilancia"] - Vector2(14, 6), Vector2(28, 12)))
	_solid(Rect2(spots["papiri"] - Vector2(20, 8), Vector2(40, 12)))
	var decor := DecorScript.new()
	world.add_child(decor)
	for r in decor.build(424242, ROOM, TOP, WALL, [], true):
		_solid(r)
	# nella Sala niente sabbia sul pavimento: è un luogo curato, non una tomba abbandonata
	decor.floor_bits = decor.floor_bits.filter(func(b: Array) -> bool: return b[0] != "sand")
	# colonne papiriformi, stendardi degli dèi, luce dal cancello, polvere sospesa
	for cpos in [Vector2(100, 150), Vector2(ROOM.size.x - 100, 150), Vector2(100, 285), Vector2(ROOM.size.x - 100, 285)]:
		var col := HubColumn.new()
		col.position = cpos
		world.add_child(col)
		_solid(Rect2(cpos - Vector2(11, 6), Vector2(22, 10)))
	var banners := HubBanners.new()
	world.add_child(banners)
	_add_dust()
	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - WALL - 30.0)
	world.add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM.size.x)
	cam.limit_bottom = int(ROOM.size.y)
	cam.reset_smoothing()
	var light := HubLight.new()
	light.position = spots["cancello"]
	world.add_child(light)
	for c in world.get_children():
		if c is HubColumn:
			c.player = player
	queue_redraw()


func _add_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 45
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(ROOM.size.x / 2.0 - WALL, (ROOM.size.y - TOP - WALL) / 2.0)
	dust.position = Vector2(ROOM.size.x / 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
	dust.direction = Vector2(0.3, -1)
	dust.spread = 40.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 7.0
	dust.scale_amount_min = 0.8
	dust.scale_amount_max = 1.8
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 0.85, 0.55, 0.0))
	ramp.set_color(1, Color(1, 0.85, 0.55, 0.0))
	ramp.add_point(0.3, Color(1, 0.85, 0.55, 0.45))
	ramp.add_point(0.7, Color(1, 0.85, 0.55, 0.35))
	dust.color_ramp = ramp
	dust.z_index = 2
	world.add_child(dust)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.position = rect.get_center()
	world.add_child(body)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if player == null:
		return
	hud.text = "Sala del Giudizio    Ka custodito %d    Discese %d    Vittorie su Ammit %d" % [Meta.ka_bank, Meta.runs, Meta.ammit_wins]
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = "Levetta muovi · LB/A scatto · Y interagisci · Start opzioni"
	else:
		help.text = "WASD muovi · Spazio scatto · E interagisci · Esc opzioni"

	if talk_box.visible or book != null:
		prompt.visible = false
		return
	# il cancello si attraversa camminandoci dentro
	if player.global_position.y < TOP + 14.0 and absf(player.global_position.x - spots["cancello"].x) < 22.0:
		_start_run()
		return
	near = ""
	for k in ["anubi", "libro", "bilancia", "papiri"]:
		if player.global_position.distance_to(spots[k]) < 40.0:
			near = k
	var key := "Y" if Fx.device == "pad" else "E"
	match near:
		"anubi":
			prompt.text = "%s · Parla con Anubi" % key
		"libro":
			prompt.text = "%s · Apri il Libro dei Morti" % key
		"papiri":
			var n := Lore.count_seen()
			prompt.text = "%s · Leggi i Papiri di Thoth (%d su %d)" % [key, n.x, n.y]
		"bilancia":
			if Weights.unlocked():
				prompt.text = "%s · Il Peso del Cuore (peso attuale %d, Ka +%d%%)" % [key, Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0))]
			else:
				prompt.text = "La bilancia di Ma'at · Sconfiggi Ammit per poter posare i tuoi pesi"
		_:
			prompt.text = "Il cancello del Duat è a nord" if player.global_position.y < TOP + 90.0 else ""
	prompt.visible = prompt.text != ""


func _unhandled_input(event: InputEvent) -> void:
	if book != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") or (book_kind == "opzioni" and event.is_action_pressed("pause")):
			_close_book()
			get_viewport().set_input_as_handled()
		return
	if talk_box.visible:
		var tap: bool = event is InputEventScreenTouch and event.pressed
		if tap or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
			_advance_talk()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if near == "anubi":
			_start_talk()
		elif near == "libro":
			_open_book("libro")
		elif near == "papiri":
			_open_book("papiri")
		elif near == "bilancia" and Weights.unlocked():
			_open_book("pesi")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_open_book("opzioni")
		get_viewport().set_input_as_handled()


func _start_run() -> void:
	Meta.last_end = ""
	Meta.save()
	Sfx.play("door")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------- dialoghi

func _start_talk() -> void:
	talk_lines = Dialogue.next_lines(not commented)
	commented = true
	Meta.last_end = ""
	Meta.save()
	player.set_physics_process(false)
	talk_box.visible = true
	_advance_talk()


func _advance_talk() -> void:
	if talk_lines.is_empty():
		talk_box.visible = false
		player.set_physics_process(true)
		return
	Sfx.play("ui", 0.0)
	talk_name.text = "Anubi"
	talk_text.text = talk_lines.pop_front()


# ---------------------------------------------------------------- finestre (Libro dei Morti e Papiri di Thoth)

## Apre una finestra a tutto schermo. `kind` è "libro" o "papiri".
func _open_book(kind: String = "libro") -> void:
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("book", 0.0)
	book_kind = kind
	book = CanvasLayer.new()
	book.layer = 20
	add_child(book)
	if kind == "libro":
		_fill_book()
	elif kind == "pesi":
		_fill_weights()
	elif kind == "opzioni":
		_fill_options()
	else:
		_fill_papiri()


## Struttura comune: titolo, sottotitolo, una colonna di pulsanti a sinistra e un riquadro di testo a destra.
func _frame(title_text: String, sub_text: String, left_width: float) -> VBoxContainer:
	for c in book.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	book.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	book.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	margin.add_child(outer)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Fx.fs(16))
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	outer.add_child(title)
	var sub := Label.new()
	sub.text = sub_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", Fx.fs(9))
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	outer.add_child(sub)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	outer.add_child(row)
	# elenco a sinistra dentro uno scorrimento: i capitoli sono tanti e il telefono è basso
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(left_width, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	row.add_child(scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 3)
	scroll.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	page_title = _text_label(right, 12, Color(0.94, 0.72, 0.3))
	page_body = _text_label(right, 10, Color(0.95, 0.9, 0.78))
	page_lore = _text_label(right, 9, Color(0.72, 0.68, 0.9))
	page_action = Button.new()
	page_action.visible = false
	page_action.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	page_action.add_theme_font_size_override("font_size", Fx.fs(10))
	page_action.pressed.connect(func() -> void:
		if page_action_cb.is_valid():
			page_action_cb.call())
	right.add_child(page_action)
	var close := Button.new()
	close.text = "Chiudi"
	close.add_theme_font_size_override("font_size", Fx.fs(10))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_book)
	outer.add_child(close)
	var hint := Label.new()
	hint.text = "E / Y / B per chiudere"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", Fx.fs(8))
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	outer.add_child(hint)
	return left


func _text_label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	l.add_theme_font_size_override("font_size", Fx.fs(font_size))
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _list_button(parent: Control, text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", Fx.fs(9))
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_focus_color", Color(0.94, 0.72, 0.3))
	b.add_theme_color_override("font_hover_color", Color(0.94, 0.72, 0.3))
	b.focus_entered.connect(Sfx.play.bind("ui", 0.0))
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- Libro dei Morti

func _fill_book(focus_id: String = "") -> void:
	var left := _frame("Il Libro dei Morti", "Ka custodito: %d    ·    Lacrime di Iside: %d    ·    Capitoli attivi: %d di %d" % [Meta.ka_bank, Meta.tears, Meta.chapters_equipped.size(), Chapters.slots()], 260)
	var first: Button = null
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		var lvl := Chapters.level(id)
		var cost := Chapters.next_cost(id)
		var state := "%d Ka" % cost[0]
		var col := Color(0.95, 0.9, 0.78)
		if Chapters.is_equipped(id):
			state = "ATTIVO"
			col = Color(0.62, 0.95, 0.7)
		elif lvl > 0:
			state = "comprato"
		elif Meta.ka_bank < cost[0]:
			col = Color(0.6, 0.55, 0.48)
		var stars := ""
		if Chapters.max_level(id) > 1 and lvl > 0:
			stars = "  " + "●".repeat(lvl) + "○".repeat(Chapters.max_level(id) - lvl)
		var b := _list_button(left, "%d · %s%s   [%s]" % [c["num"], c["name"], stars, state], col)
		b.pressed.connect(_on_chapter_pressed.bind(id))
		b.focus_entered.connect(_show_chapter.bind(id))
		b.mouse_entered.connect(_show_chapter.bind(id))
		if first == null or id == focus_id:
			first = b
	# un posto in più nel Libro, con le Lacrime di Iside
	var sc := Chapters.slot_cost()
	if sc > 0:
		var sb := _list_button(left, "Un posto in più nel Libro   [%d Lacrime]" % sc, Color(0.7, 0.8, 1.0) if Meta.tears >= sc else Color(0.5, 0.52, 0.6))
		sb.pressed.connect(_on_slot_pressed)
		sb.focus_entered.connect(_show_slot)
		sb.mouse_entered.connect(_show_slot)
		if focus_id == "slot":
			first = sb
	first.grab_focus.call_deferred()


func _show_chapter(id: String) -> void:
	var c: Dictionary = Chapters.ALL[id]
	var lvl := Chapters.level(id)
	var maxl := Chapters.max_level(id)
	page_title.text = "Capitolo %d · %s%s" % [c["num"], c["name"], "" if maxl == 1 else "  (livello %d di %d)" % [maxi(lvl, 1), maxl]]
	var lines := [Chapters.text(id, maxi(lvl, 1))]
	var cost := Chapters.next_cost(id)
	if lvl > 0 and cost[0] >= 0:
		lines.append("Livello %d: %s" % [lvl + 1, Chapters.text(id, lvl + 1)])
	var action := ""
	if Chapters.is_equipped(id):
		action = "Attivo. Premi per toglierlo."
	elif lvl > 0:
		action = "Comprato. Premi per attivarlo (posti liberi: %d)." % (Chapters.slots() - Meta.chapters_equipped.size())
	elif Meta.ka_bank >= cost[0]:
		action = "Premi per comprarlo: %d Ka." % cost[0]
	else:
		action = "Costa %d Ka: te ne mancano %d." % [cost[0], cost[0] - Meta.ka_bank]
	lines.append(action)
	page_body.text = "\n\n".join(lines)
	page_lore.text = c["lore"]
	# potenziamento: pulsante a parte, così premere il capitolo resta "attiva / togli"
	page_action.visible = lvl > 0 and cost[0] >= 0
	if page_action.visible:
		var price := "%d Ka" % cost[0] + (" + 1 Lacrima di Iside" if cost[1] > 0 else "")
		page_action.text = "Potenzia al livello %d  ·  %s" % [lvl + 1, price]
		page_action.disabled = Meta.ka_bank < cost[0] or Meta.tears < cost[1]
		page_action_cb = func() -> void:
			if Chapters.buy(id):
				Sfx.play("boon", 0.0)
				Fx.shake(2.0)
				_fill_book(id)


func _show_slot() -> void:
	page_title.text = "Un posto in più nel Libro"
	page_body.text = "Puoi tenere attivo un capitolo in più a ogni discesa.\n\nCosta %d Lacrime di Iside: ne hai %d." % [Chapters.slot_cost(), Meta.tears]
	page_lore.text = "Le Lacrime di Iside: la dea pianse Osiride così a lungo che le sue lacrime fecero crescere il Nilo. Ogni anno, quando il fiume esondava, gli Egizi dicevano che Iside piangeva ancora. Le lasciano il Serpente della Porta (1) e Ammit (2)."
	page_action.visible = false


func _on_slot_pressed() -> void:
	if Chapters.buy_slot():
		Sfx.play("boon", 0.0)
	else:
		Fx.shake(2.0)
	_fill_book("slot")


func _on_chapter_pressed(id: String) -> void:
	if Chapters.is_unlocked(id):
		if Chapters.toggle(id):
			Sfx.play("page", 0.0)
		else:
			Fx.shake(2.0)
	elif Chapters.buy(id):
		Sfx.play("boon", 0.0)
	_fill_book(id)


# ---------------------------------------------------------------- Opzioni (Esc / Start nella Sala)

const OPTION_TEXT := {
	"feather": ["Piuma di Ma'at", "Una modalità per chi vuole un aiuto. Subisci il 10% di danni in meno, e un altro 2% in meno a ogni morte, fino al 50%. In cambio custodisci solo il 40% del Ka a fine discesa, e il Peso del Cuore non conta finché è attiva."],
	"shake": ["Scuotimento dello schermo", "La telecamera trema quando colpisci o vieni colpito. Spegnilo se ti dà fastidio agli occhi."],
	"hitstop": ["Pausa sui colpi", "Il gioco si ferma per un istante quando un colpo va a segno: dà peso ai colpi. Spegnila se preferisci un'azione sempre fluida."],
	"tutorial": ["Rifai l'addestramento", "Alla prossima discesa la prima stanza torna a essere l'addestramento di Anubi: movimento, khopesh, scatto, Occhio, Ka e porte."],
	"vol": ["Volume generale", "Premi per cambiare. Le altre categorie di suoni si regolano dal menu di pausa durante una discesa."],
	"music": ["Musica", "Premi per cambiare."],
	"quit": ["Esci dal gioco", "Chiude il gioco. I progressi della Sala sono già salvati."],
}


func _fill_options(focus_id: String = "") -> void:
	var left := _frame("Opzioni", "Esc / Start / B per tornare alla Sala", 270)
	var first: Button = null
	for id in ["feather", "shake", "hitstop", "tutorial", "vol", "music", "quit"]:
		var label: String = OPTION_TEXT[id][0]
		match id:
			"feather":
				label += ":  " + ("ATTIVA" if Meta.feather else "spenta")
			"shake", "hitstop":
				label += ":  " + ("sì" if Meta.options.get(id, true) else "no")
			"tutorial":
				label += ":  " + ("sì, alla prossima" if not Meta.tutorial_done else "no")
			"vol":
				label += ":  %d%%" % roundi(Sfx.volumes.get("generale", 1.0) * 100.0)
			"music":
				label += ":  %d%%" % roundi(Sfx.volumes.get("musica", 0.7) * 100.0)
		var col := Color(0.62, 0.95, 0.7) if id == "feather" and Meta.feather else Color(0.95, 0.9, 0.78)
		var b := _list_button(left, label, col)
		b.pressed.connect(_on_option_pressed.bind(id))
		b.focus_entered.connect(_show_option.bind(id))
		b.mouse_entered.connect(_show_option.bind(id))
		if first == null or id == focus_id:
			first = b
	first.grab_focus.call_deferred()


func _show_option(id: String) -> void:
	page_title.text = OPTION_TEXT[id][0]
	page_body.text = OPTION_TEXT[id][1]
	page_lore.text = ""
	if id == "feather" and Meta.feather:
		page_lore.text = "Ora subisci il %d%% di danni in meno." % roundi(Run.feather_guard() * 100.0)


func _on_option_pressed(id: String) -> void:
	match id:
		"feather":
			Meta.feather = not Meta.feather
		"shake", "hitstop":
			Meta.options[id] = not Meta.options.get(id, true)
		"tutorial":
			Meta.tutorial_done = not Meta.tutorial_done
		"vol":
			var v: float = Sfx.volumes.get("generale", 1.0)
			Sfx.set_volume("generale", 0.0 if v >= 0.99 else minf(1.0, v + 0.2))
		"music":
			var m: float = Sfx.volumes.get("musica", 0.7)
			Sfx.set_volume("musica", 0.0 if m >= 0.99 else minf(1.0, m + 0.1))
		"quit":
			Meta.save()
			get_tree().quit()
			return
	Meta.save()
	Sfx.play("ui", 0.0)
	_fill_options(id)


# ---------------------------------------------------------------- Il Peso del Cuore

func _fill_weights(focus_id: String = "") -> void:
	var record := "nessuno" if Meta.best_weight < 0 else str(Meta.best_weight)
	var left := _frame("Il Peso del Cuore", "Peso totale: %d    ·    Ka a fine discesa: +%d%%    ·    Record contro Ammit: %s" % [Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0)), record], 250)
	var first: Button = null
	for id in Weights.ALL:
		var w: Dictionary = Weights.ALL[id]
		var r := Weights.rank(id)
		var pips := ""
		for i in range(int(w["max"])):
			pips += "●" if i < r else "○"
		var b := _list_button(left, "%s   %s" % [pips, w["name"]], Color(0.95, 0.55, 0.45) if r > 0 else Color(0.95, 0.9, 0.78))
		b.pressed.connect(_on_weight_pressed.bind(id))
		b.focus_entered.connect(_show_weight.bind(id))
		b.mouse_entered.connect(_show_weight.bind(id))
		if first == null or id == focus_id:
			first = b
	first.grab_focus.call_deferred()


func _show_weight(id: String) -> void:
	var w: Dictionary = Weights.ALL[id]
	page_title.text = w["name"]
	page_body.text = "%s\n\nLivello %d di %d. Premi per cambiarlo." % [w["desc"], Weights.rank(id), w["max"]]
	page_lore.text = "Ogni livello di peso rende la discesa più dura e ti fa custodire il 10% di Ka in più. Anubi osserva: più pesante è il cuore che riesce a passare, più forte è chi lo porta."


func _on_weight_pressed(id: String) -> void:
	Weights.cycle(id)
	Sfx.play("page" if Weights.rank(id) > 0 else "ui", 0.0)
	_fill_weights(id)


# ---------------------------------------------------------------- Papiri di Thoth

func _fill_papiri() -> void:
	var count := Lore.count_seen()
	var left := _frame("I Papiri di Thoth", "Tutto ciò che gli dèi ti hanno raccontato    ·    %d papiri su %d" % [count.x, count.y], 300)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	left.add_child(cols)
	var cats := VBoxContainer.new()
	cats.custom_minimum_size = Vector2(150, 0)
	cats.add_theme_constant_override("separation", 2)
	cols.add_child(cats)
	papiri_entries = VBoxContainer.new()
	papiri_entries.custom_minimum_size = Vector2(140, 0)
	papiri_entries.add_theme_constant_override("separation", 2)
	cols.add_child(papiri_entries)
	codex = Lore.codex()
	var first: Button = null
	for i in range(codex.size()):
		var cat: Dictionary = codex[i]
		var seen := 0
		for e in cat["entries"]:
			if e["seen"]:
				seen += 1
		var b := _list_button(cats, "%s  %d/%d" % [cat["title"], seen, cat["entries"].size()], Color(0.95, 0.9, 0.78) if seen > 0 else Color(0.6, 0.55, 0.48))
		b.focus_entered.connect(_show_category.bind(i))
		b.mouse_entered.connect(_show_category.bind(i))
		if first == null:
			first = b
	first.grab_focus.call_deferred()


func _show_category(i: int) -> void:
	for c in papiri_entries.get_children():
		papiri_entries.remove_child(c)
		c.queue_free()
	var cat: Dictionary = codex[i]
	for e in cat["entries"]:
		var b := _list_button(papiri_entries, e["title"], Color(0.95, 0.9, 0.78) if e["seen"] else Color(0.5, 0.46, 0.4))
		b.focus_entered.connect(_show_entry.bind(cat["title"], e))
		b.mouse_entered.connect(_show_entry.bind(cat["title"], e))
	_show_entry(cat["title"], cat["entries"][0])


func _show_entry(category: String, e: Dictionary) -> void:
	page_title.text = category
	page_body.text = e["title"]
	page_lore.text = e["text"]


func _close_book() -> void:
	Sfx.play("page", 0.0)
	book.queue_free()
	book = null
	player.set_physics_process(true)


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	if spots.is_empty():
		return
	var r := ROOM
	var y := TOP
	while y < r.end.y - WALL:
		var x := WALL
		while x < r.end.x - WALL:
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
			draw_rect(Rect2(x + 1, y + 1, 30, 30), Color(0.16, 0.18, 0.32).darkened(n * 0.15))
			x += 32.0
		y += 32.0
	var dark := Color(0.07, 0.07, 0.14)
	draw_rect(Rect2(0, 0, r.size.x, WALL), dark)
	draw_rect(Rect2(0, WALL, r.size.x, WALL), Color(0.2, 0.22, 0.4))
	draw_rect(Rect2(0, r.end.y - WALL, r.size.x, WALL), dark)
	draw_rect(Rect2(0, 0, WALL, r.size.y), dark)
	draw_rect(Rect2(r.end.x - WALL, 0, WALL, r.size.y), dark)
	# tappeto processionale dall'ingresso al cancello
	var cx := r.size.x / 2.0
	draw_rect(Rect2(cx - 22, TOP, 44, r.end.y - WALL - TOP), Color(0.42, 0.1, 0.1))
	draw_rect(Rect2(cx - 22, TOP, 3, r.end.y - WALL - TOP), Color(0.85, 0.62, 0.25))
	draw_rect(Rect2(cx + 19, TOP, 3, r.end.y - WALL - TOP), Color(0.85, 0.62, 0.25))
	var ky := TOP + 10.0
	while ky < r.end.y - WALL - 8.0:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, ky), Vector2(cx + 7, ky + 7), Vector2(cx, ky + 14), Vector2(cx - 7, ky + 7)]), Color(0.75, 0.5, 0.2, 0.7))
		draw_rect(Rect2(cx - 16, ky + 6, 4, 2), Color(0.25, 0.55, 0.6, 0.8))
		draw_rect(Rect2(cx + 12, ky + 6, 4, 2), Color(0.25, 0.55, 0.6, 0.8))
		ky += 22.0
	# cancello del Duat: un portale luminoso nella parete nord
	var g: Vector2 = spots["cancello"]
	var pulse := 0.5 + 0.5 * sin(t * 2.0)
	draw_rect(Rect2(g.x - 22, WALL, 44, TOP - WALL + 4), Color(0.02, 0.02, 0.05))
	draw_rect(Rect2(g.x - 20, WALL + 2, 40, TOP - WALL), Color(0.3, 0.85, 0.8, 0.25 + 0.2 * pulse))
	draw_rect(Rect2(g.x - 26, WALL - 4, 52, 4), Color(0.94, 0.72, 0.3))
	draw_rect(Rect2(g.x - 26, WALL - 4, 4, TOP - WALL + 8), Color(0.94, 0.72, 0.3))
	draw_rect(Rect2(g.x + 22, WALL - 4, 4, TOP - WALL + 8), Color(0.94, 0.72, 0.3))
	_draw_scale(spots["bilancia"])
	_draw_anubi(spots["anubi"])
	_draw_book(spots["libro"])
	_draw_papiri(spots["papiri"])


func _draw_scale(p: Vector2) -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var tilt := sin(t * 0.8) * 3.0 - minf(Weights.total(), 8) * 1.2   # i pesi abbassano il piatto del cuore
	draw_rect(Rect2(p.x - 12, p.y - 2, 24, 6), Color(0.6, 0.45, 0.2))
	draw_rect(Rect2(p.x - 1.5, p.y - 34, 3, 32), gold)
	draw_line(Vector2(p.x - 22, p.y - 32 - tilt), Vector2(p.x + 22, p.y - 32 + tilt), gold, 2.0)
	for s in [-1.0, 1.0]:
		var hp := Vector2(p.x + 22 * s, p.y - 32 + tilt * s)
		draw_line(hp, hp + Vector2(-6, 12), gold, 1.0)
		draw_line(hp, hp + Vector2(6, 12), gold, 1.0)
		draw_line(hp + Vector2(-8, 12), hp + Vector2(8, 12), gold, 2.0)
		if s < 0.0:
			draw_circle(hp + Vector2(0, 8), 3.5, Color(0.8, 0.2, 0.2))
		else:
			draw_line(hp + Vector2(0, 3), hp + Vector2(1, 11), Color(0.95, 0.95, 0.9), 2.0)


func _draw_anubi(p: Vector2) -> void:
	var black := Color(0.08, 0.08, 0.11)
	var gold := Color(0.94, 0.72, 0.3)
	var bob := sin(t * 1.5) * 0.8
	draw_set_transform(Vector2(p.x, p.y + 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 7, p.y - 10, 14, 12), Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(p.x - 6, p.y - 26 + bob, 12, 16), black)
	draw_rect(Rect2(p.x - 7, p.y - 22 + bob, 14, 3), gold)
	draw_rect(Rect2(p.x - 4, p.y - 36 + bob, 9, 11), black)
	draw_rect(Rect2(p.x + 4, p.y - 32 + bob, 7, 4), black)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 4, p.y - 35 + bob), Vector2(p.x - 1, p.y - 35 + bob), Vector2(p.x - 3, p.y - 46 + bob)]), black)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x + 1, p.y - 35 + bob), Vector2(p.x + 4, p.y - 35 + bob), Vector2(p.x + 3, p.y - 46 + bob)]), black)
	draw_circle(Vector2(p.x + 2, p.y - 32 + bob), 1.0, gold)
	# bastone was
	draw_line(Vector2(p.x + 10, p.y - 30), Vector2(p.x + 10, p.y + 2), gold, 1.5)
	draw_rect(Rect2(p.x + 9, p.y - 32, 5, 2), gold)
	if near == "anubi" and not talk_box.visible:
		draw_arc(Vector2(p.x, p.y - 20), 22.0, 0.0, TAU, 32, Color(0.62, 0.56, 0.92, 0.5 + 0.3 * sin(t * 4.0)), 1.5)


func _draw_book(p: Vector2) -> void:
	var wood := Color(0.42, 0.28, 0.14)
	draw_rect(Rect2(p.x - 3, p.y - 16, 6, 18), wood)
	draw_rect(Rect2(p.x - 10, p.y, 20, 4), wood)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 14, p.y - 20), Vector2(p.x + 14, p.y - 20), Vector2(p.x + 10, p.y - 14), Vector2(p.x - 10, p.y - 14)]), wood)
	draw_rect(Rect2(p.x - 12, p.y - 26, 11, 7), Color(0.92, 0.86, 0.7))
	draw_rect(Rect2(p.x + 1, p.y - 26, 11, 7), Color(0.92, 0.86, 0.7))
	for k in range(3):
		draw_line(Vector2(p.x - 10, p.y - 24 + k * 2), Vector2(p.x - 3, p.y - 24 + k * 2), Color(0.2, 0.2, 0.3), 1.0)
		draw_line(Vector2(p.x + 3, p.y - 24 + k * 2), Vector2(p.x + 10, p.y - 24 + k * 2), Color(0.2, 0.2, 0.3), 1.0)
	var glow := 0.3 + 0.2 * sin(t * 3.0)
	draw_circle(Vector2(p.x, p.y - 24), 16.0, Color(0.95, 0.75, 0.35, glow * 0.3))
	if near == "libro" and book == null:
		draw_arc(Vector2(p.x, p.y - 14), 22.0, 0.0, TAU, 32, Color(0.94, 0.72, 0.3, 0.5 + 0.3 * sin(t * 4.0)), 1.5)


func _draw_papiri(p: Vector2) -> void:
	var wood := Color(0.42, 0.28, 0.14)
	var dark := Color(0.3, 0.2, 0.1)
	draw_rect(Rect2(p.x - 20, p.y - 34, 40, 36), dark)
	for shelf in range(3):
		var sy := p.y - 32 + shelf * 12
		draw_rect(Rect2(p.x - 20, sy + 9, 40, 2), wood)
		for k in range(5):
			var roll := Color(0.92, 0.86, 0.7).darkened(0.08 * ((k + shelf) % 3))
			draw_rect(Rect2(p.x - 17 + k * 7, sy + 2, 6, 7), roll)
			draw_rect(Rect2(p.x - 15 + k * 7, sy + 4, 2, 3), Color(0.55, 0.3, 0.2))
	draw_rect(Rect2(p.x - 22, p.y - 36, 44, 3), wood)
	if near == "papiri" and book == null:
		draw_arc(Vector2(p.x, p.y - 16), 26.0, 0.0, TAU, 32, Color(0.72, 0.68, 0.9, 0.5 + 0.3 * sin(t * 4.0)), 1.5)



## Colonna papiriforme: fusto a fasci con capitello a ombrello. Passa davanti al giocatore
## quando lui ci cammina dietro.
class HubColumn extends Node2D:
	var player: Node2D

	func _process(_delta: float) -> void:
		if player != null and is_instance_valid(player):
			z_index = 1 if player.global_position.y < global_position.y else 0

	func _draw() -> void:
		var stone := Color(0.78, 0.68, 0.5)
		var shade := Color(0.6, 0.5, 0.36)
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(-13, -4, 26, 6), shade)
		draw_rect(Rect2(-9, -66, 18, 62), stone)
		for k in range(4):
			draw_line(Vector2(-6 + k * 4, -64), Vector2(-6 + k * 4, -6), shade, 1.0)
		for b in [-56, -48]:
			draw_rect(Rect2(-10, b, 20, 3), Color(0.25, 0.55, 0.6))
			draw_rect(Rect2(-10, b + 3, 20, 1), Color(0.85, 0.62, 0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -66), Vector2(9, -66), Vector2(16, -80), Vector2(-16, -80)]), stone)
		draw_rect(Rect2(-17, -84, 34, 5), shade)
		for k in range(5):
			draw_line(Vector2(-12 + k * 6, -80), Vector2(-6 + k * 3, -67), Color(0.35, 0.55, 0.3), 1.0)


## Stendardi delle sei divinità sulla parete nord: si colorano quando il dio ti ha parlato.
class HubBanners extends Node2D:
	const ORDER := [["ra", 130.0], ["sekhmet", 166.0], ["thoth", 202.0], ["horus", 278.0], ["bastet", 534.0], ["sobek", 570.0], ["iside", 662.0]]
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for entry in ORDER:
			var god: String = entry[0]
			var x: float = entry[1]
			var met := Meta.dialogue_seen.has(god + "_0")
			var col := Boons.god_color(god) if met else Color(0.3, 0.3, 0.36)
			var sway := sin(t * 1.3 + x) * 1.2
			draw_rect(Rect2(x - 13, 36, 26, 3), Color(0.55, 0.4, 0.2))
			var cloth := col.darkened(0.35)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 10, 39), Vector2(x + 10, 39), Vector2(x + 10 + sway, 90), Vector2(x + sway, 98), Vector2(x - 10 + sway, 90)]), cloth)
			draw_rect(Rect2(x - 10, 39, 20, 2), Color(0.85, 0.62, 0.25) if met else Color(0.4, 0.4, 0.45))
			var c := Vector2(x + sway * 0.5, 62)
			var sym := col.lightened(0.35) if met else Color(0.45, 0.45, 0.5)
			match god:
				"ra":
					draw_circle(c, 6.0, sym)
					draw_arc(c, 8.5, 0.0, TAU, 20, Color(0.95, 0.85, 0.4) if met else sym, 1.0)
				"sekhmet":
					draw_circle(c + Vector2(0, -4), 4.0, sym)
					draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(6, 0), c + Vector2(4, 9), c + Vector2(-4, 9)]), sym)
				"thoth":
					draw_arc(c, 7.0, PI * 0.6, PI * 1.9, 16, sym, 3.0)
				"bastet":
					draw_circle(c + Vector2(0, 2), 5.0, sym)
					draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -1), c + Vector2(-3, -9), c + Vector2(-1, -2)]), sym)
					draw_colored_polygon(PackedVector2Array([c + Vector2(5, -1), c + Vector2(3, -9), c + Vector2(1, -2)]), sym)
				"sobek":
					for k in range(3):
						var yy := c.y - 5 + k * 5
						draw_polyline(PackedVector2Array([Vector2(c.x - 7, yy), Vector2(c.x - 3, yy - 2), Vector2(c.x + 1, yy), Vector2(c.x + 5, yy - 2), Vector2(c.x + 7, yy)]), sym, 1.5)
				"horus":
					# l'occhio wedjat
					draw_arc(c, 6.0, PI, TAU, 12, sym, 1.5)
					draw_circle(c + Vector2(0, 1), 2.5, sym)
					draw_line(c + Vector2(-1, 3), c + Vector2(-3, 8), sym, 1.5)
					draw_line(c + Vector2(3, 3), c + Vector2(6, 6), sym, 1.5)
				"iside":
					draw_rect(Rect2(c.x - 5, c.y - 8, 10, 4), sym)
					draw_rect(Rect2(c.x - 2, c.y - 4, 4, 12), sym)
					draw_rect(Rect2(c.x - 6, c.y + 6, 12, 3), sym)


## Fascio di luce che scende dal cancello del Duat.
class HubLight extends Node2D:
	var t := 0.0

	func _ready() -> void:
		z_index = 2
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.13 + 0.04 * sin(t * 1.7)
		var top_c := Color(0.35, 0.85, 0.8, a)
		var bottom_c := Color(0.35, 0.85, 0.8, 0.0)
		var pts := PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(70, 170), Vector2(-70, 170)])
		draw_polygon(pts, PackedColorArray([top_c, top_c, bottom_c, bottom_c]))
