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
const ARMORY_Y := 218.0                   ## la porta del Cortile di Neith, nella parete ovest

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
var shown_option := ""                 # l'opzione mostrata sulla pagina di destra
var option_buttons := {}               # id -> pulsante delle Opzioni
var page_extra: VBoxContainer          ## spazio sulla pagina di destra per i comandi (le barre del volume)
var list_scroll: ScrollContainer = null
var frame_title := ""
var drag_from := Vector2.ZERO
var drag_scroll0 := 0
var drag_active := false
var drag_moved := false
var armed_key := ""                   ## sul telefono: la voce già selezionata col primo tocco
var update_tag: Button                 ## «Nuova versione, aggiorna!» in basso a destra (solo web)
var update_label_state := ""           # com'era il controllo della versione quando le Opzioni sono state disegnate
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
	_build_update_tag()
	talk_box.visible = false
	if Meta.runs == 0 or Meta.last_end != "":
		_start_talk()


func _build() -> void:
	_solid(Rect2(0, 0, ROOM.size.x, TOP))
	_solid(Rect2(0, ROOM.size.y - WALL, ROOM.size.x, WALL))
	_solid(Rect2(0, 0, WALL, ROOM.size.y))
	_solid(Rect2(ROOM.size.x - WALL, 0, WALL, ROOM.size.y))
	_solid(Rect2(spots["anubi"] - Vector2(18, 6), Vector2(36, 10)))
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
	if Run.from_armory:
		Run.from_armory = false
		player.position = Vector2(WALL + 26.0, ARMORY_Y)
	world.add_child(player)
	# il Cortile di Neith si è appena aperto: una freccia lo indica finché non ci entri a prendere la lancia
	if Meta.serpent_wins > 0 and not Meta.weapons_unlocked.has("lancia"):
		var mark := Node2D.new()
		mark.position = Vector2(WALL + 4.0, ARMORY_Y)
		world.add_child(mark)
		var arrow := NewRoomArrow.new()
		arrow.target = mark
		$UI.add_child(arrow)
		$UI.move_child(arrow, 0)
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


## La scritta che avvisa della versione nuova: piccola, lampeggia piano, in basso a destra
## (sul telefono sopra il pulsante AZIONE). Toccarla apre le Opzioni su «Aggiorna il gioco».
## Solo nella Sala: aggiornare a metà discesa la farebbe perdere.
func _build_update_tag() -> void:
	update_tag = Button.new()
	update_tag.text = "Nuova versione, aggiorna!"
	update_tag.flat = true
	update_tag.focus_mode = Control.FOCUS_NONE
	update_tag.visible = false
	update_tag.add_theme_font_size_override("font_size", Fx.fs(8))
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		update_tag.add_theme_color_override(st, Color(0.98, 0.8, 0.35))
	update_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	update_tag.add_theme_constant_override("outline_size", 3)
	update_tag.add_to_group("touch_tap")      # sul telefono il tocco arriva da touch_controls.gd
	update_tag.pressed.connect(func() -> void:
		if book != null or talk_box.visible:
			return
		_open_book("opzioni")
		_fill_options("update")
		_show_option("update"))
	$UI.add_child(update_tag)


func _update_update_tag() -> void:
	if update_tag == null:
		return
	update_tag.visible = (Updater.available() or OS.get_environment("DUAT_FAKE_UPDATE") != "") and book == null and not talk_box.visible
	if not update_tag.visible:
		return
	update_tag.modulate.a = 0.55 + 0.45 * absf(sin(t * 2.6))
	update_tag.reset_size()
	var vs := get_viewport().get_visible_rect().size
	var above := 104.0 if Fx.device == "touch" else 22.0    # sopra il pulsante AZIONE, o sopra la riga dei comandi
	update_tag.position = Vector2(vs.x - update_tag.size.x - 6.0, vs.y - above - update_tag.size.y)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if player == null:
		return
	# le Opzioni aperte si aggiornano da sole quando arriva la risposta sulla versione nuova
	if book_kind == "opzioni" and Updater.supported() and int(t * 2.0) != int((t - delta) * 2.0):
		if Updater.check_state() + str(Updater.available()) != update_label_state:
			var keep := shown_option
			_fill_options(keep)
			_show_option(keep)
	hud.text = "Sala del Giudizio\nKa custodito %d · Discese %d · Vittorie %d" % [Meta.ka_bank, Meta.runs, Meta.ammit_wins]
	_update_update_tag()
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
	# la porta del Cortile di Neith si attraversa camminandoci dentro (aperta dopo il primo Serpente)
	var at_door: bool = player.global_position.x < WALL + 14.0 and absf(player.global_position.y - ARMORY_Y) < 24.0
	if at_door and Meta.serpent_wins > 0:
		Sfx.play("door")
		get_tree().change_scene_to_file("res://scenes/armory.tscn")
		return
	near = ""
	if player.global_position.x < WALL + 40.0 and absf(player.global_position.y - ARMORY_Y) < 30.0:
		near = "cortile"
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
			if Lore.unread_ricordi() > 0:
				prompt.text += " · un ricordo nuovo"
		"bilancia":
			if Weights.unlocked():
				prompt.text = "%s · Il Peso del Cuore (peso attuale %d, Ka +%d%%)" % [key, Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0))]
			else:
				prompt.text = "La bilancia di Ma'at · Sconfiggi Am-heh per poter posare i tuoi pesi"
		"cortile":
			if Meta.serpent_wins > 0:
				prompt.text = "Il Cortile di Neith · le armi · entra dalla porta"
			else:
				prompt.text = "Il Cortile di Neith · si aprirà quando avrai battuto il Serpente della Porta"
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
	# se si ridisegna la stessa finestra (hai appena premuto una voce), lo scorrimento resta dov'era
	var keep_scroll := 0
	if list_scroll != null and is_instance_valid(list_scroll) and frame_title == title_text:
		keep_scroll = list_scroll.scroll_vertical
	frame_title = title_text
	option_buttons.clear()
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
	scroll.follow_focus = keep_scroll == 0
	row.add_child(scroll)
	list_scroll = scroll
	scroll.gui_input.connect(_on_list_drag.bind(scroll))
	if keep_scroll > 0:
		get_tree().create_timer(0.03, true, false, true).timeout.connect(func() -> void:
			if is_instance_valid(scroll):
				scroll.scroll_vertical = keep_scroll
				scroll.follow_focus = true)
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
	page_extra = VBoxContainer.new()
	page_extra.add_theme_constant_override("separation", 4)
	right.add_child(page_extra)
	var close := Button.new()
	close.text = "Chiudi"
	close.add_theme_font_size_override("font_size", Fx.fs(10))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_book)
	outer.add_child(close)
	var hint := Label.new()
	hint.text = "Tocca una voce per leggerla, toccala di nuovo per sceglierla" if Fx.device == "touch" else "E / Y / B per chiudere"
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


## Trascinare la lista con il dito (o con il mouse premuto) la fa scorrere. Se il dito si è
## mosso, il tocco non preme la voce su cui è finito.
func _on_list_drag(event: InputEvent, scroll: ScrollContainer) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_from = event.global_position
			drag_scroll0 = scroll.scroll_vertical
			drag_active = true
			drag_moved = false
		else:
			drag_active = false
			if drag_moved:
				scroll.accept_event()
				# la voce sotto il dito riceve il rilascio subito dopo: per un istante si ignora
				get_tree().create_timer(0.05, true, false, true).timeout.connect(func() -> void: drag_moved = false)
	elif event is InputEventMouseMotion and drag_active:
		var dy: float = event.global_position.y - drag_from.y
		if absf(dy) > 8.0 * Fx.ui:
			drag_moved = true
		if drag_moved:
			scroll.scroll_vertical = drag_scroll0 - int(dy)
			scroll.accept_event()


## Collega la voce di una lista: il tocco conta solo se non stavi trascinando la lista.
## Sul telefono il primo tocco seleziona la voce e la spiega a destra; solo il secondo tocco
## sulla stessa voce la sceglie. Così si può leggere cosa fa una voce senza cambiarla.
## Con mouse, tastiera e pad la spiegazione compare già passandoci sopra: lì basta un clic.
func _tap(b: Button, cb: Callable) -> void:
	b.pressed.connect(func() -> void:
		if drag_moved:
			return
		if Fx.device == "touch":
			var key := frame_title + "|" + cb.get_method() + str(cb.get_bound_arguments())
			if armed_key != key:
				armed_key = key
				b.grab_focus()
				Sfx.play("ui", 0.0)
				return
		cb.call())


func _list_button(parent: Control, text: String, color: Color) -> Button:
	var b := Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS	 # il trascinamento arriva anche alla lista
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# un testo lungo non allarga la colonna (spingerebbe la pagina di destra fuori schermo): si accorcia
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_theme_font_size_override("font_size", Fx.fs(9))
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_focus_color", Color(0.94, 0.72, 0.3))
	b.add_theme_color_override("font_hover_color", Color(0.94, 0.72, 0.3))
	b.focus_entered.connect(Sfx.play.bind("ui", 0.0))
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- Libro dei Morti

func _fill_book(focus_id: String = "") -> void:
	var left := _frame("Il Libro dei Morti", "Ka custodito: %d    ·    Capitoli attivi: %d di %d" % [Meta.ka_bank, Meta.chapters_equipped.size(), Chapters.slots()], 260)
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
			stars = "  · liv. %d/%d" % [lvl, Chapters.max_level(id)]    # niente ●○: il telefono non li ha
		var b := _list_button(left, "%d · %s%s   [%s]" % [c["num"], c["name"], stars, state], col)
		_tap(b, _on_chapter_pressed.bind(id))
		b.focus_entered.connect(_show_chapter.bind(id))
		b.mouse_entered.connect(_show_chapter.bind(id))
		if first == null or id == focus_id:
			first = b
	# un posto in più nel Libro, con le Lacrime di Iside
	var sc := Chapters.slot_cost()
	if sc > 0:
		var sb := _list_button(left, "Un posto in più nel Libro   [%d Ka]" % sc, Color(0.7, 0.8, 1.0) if Meta.ka_bank >= sc else Color(0.5, 0.52, 0.6))
		_tap(sb, _on_slot_pressed)
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
	page_body.text = "Puoi tenere attivo un capitolo in più a ogni discesa.\n\nCosta %d Ka: ne hai %d." % [Chapters.slot_cost(), Meta.ka_bank]
	page_lore.text = "Un papiro più lungo per formule in più. I più ricchi si facevano dipingere Libri dei Morti di decine di metri: quello di Ani supera i ventitré."
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
	"autoaim": ["Mira automatica (telefono)", "Sul telefono, quando sei fermo, l'arma e l'Occhio mirano da soli al nemico più vicino. Quando ti muovi colpisci sempre nella direzione in cui vai, con un piccolo aiuto se c'è un nemico più o meno davanti. Spegnila se preferisci mirare sempre con il movimento."],
	"tutorial": ["Rifai l'addestramento", "Alla prossima discesa la prima stanza torna a essere l'addestramento di Anubi: movimento, khopesh, scatto, Occhio, Ka e porte."],
	"audio": ["Volume", "Trascina le barre. Le trovi anche nella pausa della discesa."],
	"update": ["Aggiorna il gioco", "Scarica l'ultima versione del gioco e la riapre. I tuoi progressi restano: non serve cancellare l'app dalla schermata Home."],
	"quit": ["Esci dal gioco", "Chiude il gioco. I progressi della Sala sono già salvati."],
}


func _fill_options(focus_id: String = "") -> void:
	update_label_state = Updater.check_state() + str(Updater.available())
	var left := _frame("Opzioni", "Esc / Start / B per tornare alla Sala", 270)
	var first: Button = null
	var ids := ["feather", "shake", "hitstop", "autoaim", "tutorial", "audio"]
	if Updater.supported():
		ids.append("update")		  # solo nella versione web: l'app installata non si aggiorna da sola
	ids.append("quit")
	for id in ids:
		var label: String = OPTION_TEXT[id][0]
		match id:
			"feather":
				label += ":  " + ("ATTIVA" if Meta.feather else "spenta")
			"shake", "hitstop", "autoaim":
				label += ":  " + ("sì" if Meta.options.get(id, true) else "no")
			"tutorial":
				label += ":  " + ("sì, alla prossima" if not Meta.tutorial_done else "no")
			"audio":
				label += ":  generale %d%%, musica %d%%" % [roundi(Sfx.volumes.get("generale", 1.0) * 100.0), roundi(Sfx.volumes.get("musica", 0.7) * 100.0)]
			"update":
				if Updater.available():
					label += ":  NUOVA VERSIONE"
				elif Updater.check_state() == "ok":
					label += ":  aggiornato"
				else:
					label += ":  controllo..."
		var col := Color(0.62, 0.95, 0.7) if id == "feather" and Meta.feather else Color(0.95, 0.9, 0.78)
		var b := _list_button(left, label, col)
		option_buttons[id] = b
		_tap(b, _on_option_pressed.bind(id))
		b.focus_entered.connect(_show_option.bind(id))
		b.mouse_entered.connect(_show_option.bind(id))
		if first == null or id == focus_id:
			first = b
	first.grab_focus.call_deferred()


func _show_option(id: String) -> void:
	if shown_option == id and id == "audio" and page_extra.get_child_count() > 0:
		return						  # le barre sono già lì: non ricrearle mentre le trascini
	shown_option = id
	for c in page_extra.get_children():
		c.queue_free()
	# nella pagina del volume la riga di testo in fondo è vuota: via, così le barre entrano tutte
	page_lore.visible = id != "audio"
	if id == "audio":
		_volume_sliders()
	page_title.text = OPTION_TEXT[id][0]
	page_body.text = OPTION_TEXT[id][1]
	page_lore.text = ""
	if id == "feather" and Meta.feather:
		page_lore.text = "Ora subisci il %d%% di danni in meno." % roundi(Run.feather_guard() * 100.0)
	if id == "update":
		page_lore.text = _update_status()


## Una barra per ogni tipo di suono, sulla pagina di destra, su due colonne: una sotto l'altra
## non entravano nello schermo del telefono.
func _volume_sliders() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 0)
	page_extra.add_child(grid)
	for c in Sfx.CATEGORIES:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		grid.add_child(cell)
		var name_label := Label.new()
		name_label.text = c[1]
		name_label.add_theme_font_size_override("font_size", Fx.fs(8))
		name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
		cell.add_child(name_label)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		cell.add_child(row)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sfx.volumes.get(c[0], 0.7 if c[0] == "musica" else 1.0)
		# alta abbastanza da prenderla con il dito
		slider.custom_minimum_size = Vector2(50, 15 * Fx.ui)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(slider.value * 100.0)
		pct.custom_minimum_size = Vector2(30, 0) * Fx.ui
		pct.add_theme_font_size_override("font_size", Fx.fs(8))
		pct.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
		row.add_child(pct)
		slider.value_changed.connect(_on_volume_slider.bind(c[0], pct))
		slider.drag_ended.connect(func(_changed: bool) -> void: Meta.save())


func _on_volume_slider(value: float, category: String, pct: Label) -> void:
	Sfx.set_volume(category, value)
	pct.text = "%d%%" % roundi(value * 100.0)
	# un suono di prova della categoria, così senti subito il risultato
	for snd in Sfx.SOUNDS:
		if category == "generale" or Sfx.SOUNDS[snd][1] == category:
			Sfx.play(snd, 0.0)
			break
	if option_buttons.has("audio") and is_instance_valid(option_buttons["audio"]):
		option_buttons["audio"].text = OPTION_TEXT["audio"][0] + ":  generale %d%%, musica %d%%" % [roundi(Sfx.volumes.get("generale", 1.0) * 100.0), roundi(Sfx.volumes.get("musica", 0.7) * 100.0)]


## Le versioni, per la pagina di "Aggiorna il gioco".
func _update_status() -> String:
	var txt := "Versione installata: %s" % Updater.current()
	match Updater.check_state():
		"ok":
			txt += "\nUltima versione pubblicata: %s" % Updater.latest()
			txt += "\n\nC'è una versione nuova: premi per scaricarla." if Updater.available() else "\n\nHai già l'ultima versione."
		"pending":
			txt += "\n\nSto controllando se c'è una versione nuova..."
		_:
			txt += "\n\nNon riesco a controllare: forse il telefono non è connesso. Premi per riprovare."
	return txt


func _on_option_pressed(id: String) -> void:
	match id:
		"feather":
			Meta.feather = not Meta.feather
		"shake", "hitstop", "autoaim":
			Meta.options[id] = not Meta.options.get(id, true)
		"tutorial":
			Meta.tutorial_done = not Meta.tutorial_done
		"audio":
			# le barre sono già sulla pagina: il tocco sulla voce porta il dito lì
			if page_extra.get_child_count() > 0:
				var first_slider := page_extra.find_children("*", "HSlider", true, false)
				if not first_slider.is_empty():
					first_slider[0].grab_focus()
			return
		"quit":
			Meta.save()
			get_tree().quit()
			return
		"update":
			if Updater.available():
				page_body.text = "Aggiornamento in corso... il gioco si riapre da solo tra un momento."
				page_lore.text = ""
				await Updater.update_now(get_tree())
				return
			# niente da scaricare: si controlla di nuovo e si mostra l'esito, senza ricaricare
			Updater.recheck()
			page_lore.text = "Controllo in corso..."
			await get_tree().create_timer(1.5, true, false, true).timeout
			if book_kind == "opzioni":
				_fill_options("update")
				_show_option("update")
			return
	Meta.save()
	Sfx.play("ui", 0.0)
	_fill_options(id)


# ---------------------------------------------------------------- Il Peso del Cuore

func _fill_weights(focus_id: String = "") -> void:
	var record := "nessuno" if Meta.best_weight < 0 else str(Meta.best_weight)
	var left := _frame("Il Peso del Cuore", "Peso totale: %d    ·    Ka a fine discesa: +%d%%    ·    Record contro Am-heh: %s" % [Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0)), record], 250)
	var first: Button = null
	for id in Weights.ALL:
		var w: Dictionary = Weights.ALL[id]
		var r := Weights.rank(id)
		var pips := "%d/%d" % [r, int(w["max"])]
		var b := _list_button(left, "%s   %s" % [pips, w["name"]], Color(0.95, 0.55, 0.45) if r > 0 else Color(0.95, 0.9, 0.78))
		_tap(b, _on_weight_pressed.bind(id))
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
	# si apre sul primo ricordo nuovo, se c'è
	var shown_e: Dictionary = cat["entries"][0]
	for e in cat["entries"]:
		if e.get("new", false):
			shown_e = e
			break
	_show_entry(cat["title"], shown_e)


func _show_entry(category: String, e: Dictionary) -> void:
	page_title.text = category
	page_body.text = e["title"]
	page_lore.text = e["text"]
	# un ricordo nuovo diventa "letto" quando lo apri
	if e.get("new", false) and not Meta.dialogue_seen.has(e["id"]):
		Meta.dialogue_seen.append(e["id"])
		e["new"] = false
		Meta.save()


func _close_book() -> void:
	Sfx.play("page", 0.0)
	book.queue_free()
	book = null
	armed_key = ""
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
	# porta del Cortile di Neith, a ovest: chiusa da un telo finché non batti il Serpente
	var open_door := Meta.serpent_wins > 0
	draw_rect(Rect2(0, ARMORY_Y - 26, WALL, 52), Color(0.03, 0.02, 0.05))
	if open_door:
		draw_rect(Rect2(2, ARMORY_Y - 24, WALL - 4, 48), Color(0.86, 0.32, 0.26, 0.18 + 0.12 * pulse))
	else:
		draw_rect(Rect2(4, ARMORY_Y - 24, WALL - 8, 48), Color(0.7, 0.64, 0.52))
		draw_line(Vector2(8, ARMORY_Y - 20), Vector2(WALL - 8, ARMORY_Y + 18), Color(0.45, 0.4, 0.32), 1.0)
	draw_rect(Rect2(WALL - 3, ARMORY_Y - 30, 3, 60), Color(0.94, 0.72, 0.3))
	# lo scudo con le frecce incrociate di Neith sopra la porta
	var ec := Vector2(WALL + 12, ARMORY_Y - 40)
	draw_line(ec + Vector2(-7, -7), ec + Vector2(7, 7), Color(0.94, 0.72, 0.3, 0.8), 1.5)
	draw_line(ec + Vector2(7, -7), ec + Vector2(-7, 7), Color(0.94, 0.72, 0.3, 0.8), 1.5)
	_draw_cartouche(Vector2(g.x, 15.0))
	_draw_scale(spots["bilancia"])
	_draw_anubi(spots["anubi"])
	_draw_book(spots["libro"])
	_draw_papiri(spots["papiri"])


## Il cartiglio del faraone Akhet, sopra il cancello. I segni del nome (ibis, placenta, pane,
## orizzonte) tornano uno per volta con le vittorie sui boss; l'orizzonte solo nel finale.
## Vedi docs/storia.md.
func _draw_cartouche(c: Vector2) -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var shown := mini(Meta.ammit_wins, 3)
	var w := 76.0
	var h := 22.0
	var r := Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h)
	# l'anello di corda: un ovale allungato con la barra di chiusura a destra
	var pts := PackedVector2Array()
	var rr := h / 2.0
	var cr := c + Vector2(w / 2.0 - rr - 3.0, 0)
	var cl := c - Vector2(w / 2.0 - rr - 3.0, 0)
	for i in range(13):
		pts.append(cr + Vector2.from_angle(-PI / 2.0 + PI * i / 12.0) * rr)
	for i in range(13):
		pts.append(cl + Vector2.from_angle(PI / 2.0 + PI * i / 12.0) * rr)
	pts.append(pts[0])
	draw_colored_polygon(pts, Color(0.1, 0.09, 0.16))
	draw_polyline(pts, gold, 1.6)
	draw_line(Vector2(r.end.x - 1.0, r.position.y + 2.0), Vector2(r.end.x - 1.0, r.end.y - 2.0), gold, 2.0)
	var slots := [c + Vector2(-25, 0), c + Vector2(-9, 0), c + Vector2(7, 0), c + Vector2(23, 0)]
	for i in range(4):
		var p: Vector2 = slots[i]
		if i >= shown:
			# segno ancora scalpellato: graffi chiari sulla pietra
			var sc := Color(0.5, 0.45, 0.4, 0.45)
			draw_line(p + Vector2(-4, -5), p + Vector2(3, 4), sc, 1.0)
			draw_line(p + Vector2(2, -6), p + Vector2(-3, 5), sc, 1.0)
			continue
		match i:
			0:  # ibis crestato
				draw_line(p + Vector2(-4, 6), p + Vector2(-1, 1), gold, 1.2)
				draw_line(p + Vector2(1, 6), p + Vector2(0, 1), gold, 1.2)
				draw_circle(p + Vector2(0, -1), 3.0, gold)
				draw_line(p + Vector2(2, -3), p + Vector2(3, -6), gold, 1.4)
				draw_line(p + Vector2(3, -6), p + Vector2(6, -2), gold, 1.0)
				draw_line(p + Vector2(2, -6), p + Vector2(0, -8), gold, 1.0)
			1:  # placenta: cerchio con linee
				draw_arc(p, 5.0, 0.0, TAU, 20, gold, 1.4)
				for k in range(3):
					var yy := -2.5 + k * 2.5
					draw_line(p + Vector2(-3.5, yy), p + Vector2(3.5, yy), gold, 1.0)
			2:  # pane: una piccola cupola
				draw_arc(p + Vector2(0, 4), 5.0, PI, TAU, 12, gold, 1.6)
				draw_line(p + Vector2(-5, 4), p + Vector2(5, 4), gold, 1.4)
			3:  # orizzonte: il sole tra due monti
				draw_circle(p + Vector2(0, 0), 2.5, gold)
				draw_arc(p + Vector2(-4, 5), 4.0, PI, TAU, 10, gold, 1.4)
				draw_arc(p + Vector2(4, 5), 4.0, PI, TAU, 10, gold, 1.4)
	if shown > 0:
		draw_rect(r.grow(3.0), Color(gold, 0.06 + 0.04 * sin(t * 1.5)))


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


## Anubi nella Sala: in piedi su un basamento, alto il doppio di te, con lo scettro was e
## l'ankh. Respira, muove le orecchie, ti segue con lo sguardo, e quando parla alza la mano,
## gli occhi brillano e l'aura viola si accende.
func _draw_anubi(p: Vector2) -> void:
	var black := Color(0.07, 0.06, 0.1)
	var black_hi := Color(0.2, 0.17, 0.27)
	var gold := Color(0.94, 0.72, 0.3)
	var gold_dk := Color(0.62, 0.42, 0.14)
	var lapis := Color(0.16, 0.3, 0.68)
	var turq := Color(0.2, 0.62, 0.6)
	var linen := Color(0.93, 0.9, 0.82)
	var aura := Color(0.62, 0.56, 0.92)
	var talking: bool = talk_box.visible
	var face := 1.0
	if player != null and is_instance_valid(player) and player.global_position.x < p.x - 6.0:
		face = -1.0
	var breath := sin(t * 1.6)
	var bob := breath * 0.6
	var pulse := 0.5 + 0.5 * sin(t * (5.0 if talking else 1.5))
	# aura e scintille che salgono
	draw_circle(p + Vector2(0, -30), 30.0 + 2.0 * pulse, Color(aura, 0.06 + (0.1 if talking else 0.04) * pulse))
	draw_circle(p + Vector2(0, -34), 18.0, Color(aura, 0.05 + 0.05 * pulse))
	for i in range(6):
		var k := fmod(t * 0.35 + i / 6.0, 1.0)
		var mx := sin(i * 2.1 + t) * 16.0
		draw_circle(p + Vector2(mx, -6 - k * 60.0), 1.2 * (1.0 - k), Color(aura.lightened(0.3), 0.7 * (1.0 - k)))
	# basamento
	draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 18, p.y - 4, 36, 6), Color(0.18, 0.16, 0.24))
	draw_rect(Rect2(p.x - 18, p.y - 4, 36, 1.5), gold)
	draw_rect(Rect2(p.x - 16, p.y + 2, 32, 2), Color(0.12, 0.1, 0.16))
	# da qui in poi la figura guarda verso di te (destra o sinistra)
	draw_set_transform(p, 0.0, Vector2(face, 1.0))
	var o := Vector2(0, -4)
	# scettro was, nella mano dietro: asta, forcella in basso, testa d'animale in cima
	var sx := -11.0
	draw_line(o + Vector2(sx, 0), o + Vector2(sx, -60 + bob), gold_dk, 2.2)
	draw_line(o + Vector2(sx, 0), o + Vector2(sx - 2, 3), gold_dk, 1.5)
	draw_line(o + Vector2(sx, 0), o + Vector2(sx + 2, 3), gold_dk, 1.5)
	draw_colored_polygon(PackedVector2Array([o + Vector2(sx - 1, -60 + bob), o + Vector2(sx + 5, -63 + bob), o + Vector2(sx + 4, -60 + bob), o + Vector2(sx + 1, -58 + bob)]), gold)
	draw_circle(o + Vector2(sx, -60 + bob), 4.0, Color(gold, 0.15 + 0.2 * pulse))
	# gambe
	draw_colored_polygon(PackedVector2Array([o + Vector2(-5, -16), o + Vector2(-1, -16), o + Vector2(-2, 0), o + Vector2(-5, 0)]), black)
	draw_colored_polygon(PackedVector2Array([o + Vector2(1, -16), o + Vector2(5, -16), o + Vector2(6, 0), o + Vector2(2, 0)]), black)
	draw_rect(Rect2(o.x - 6, o.y - 1, 5, 1.5), gold)
	draw_rect(Rect2(o.x + 2, o.y - 1, 5, 1.5), gold)
	# gonnellino di lino con la cintura d'oro e il grembiule
	draw_colored_polygon(PackedVector2Array([o + Vector2(-7, -27 + bob), o + Vector2(7, -27 + bob), o + Vector2(9, -14), o + Vector2(-8, -14)]), linen)
	for i in range(5):
		draw_line(o + Vector2(-5 + i * 3, -25 + bob), o + Vector2(-6 + i * 3.4, -15), linen.darkened(0.18), 0.8)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -26 + bob), o + Vector2(5, -26 + bob), o + Vector2(4, -15), o + Vector2(1, -15)]), gold)
	draw_rect(Rect2(o.x - 7.5, o.y - 28 + bob, 15, 2.5), gold)
	# busto
	var sh := -44.0 + bob
	draw_colored_polygon(PackedVector2Array([o + Vector2(-9, sh), o + Vector2(9, sh), o + Vector2(6, -27 + bob), o + Vector2(-6, -27 + bob)]), black)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-2, sh + 2), o + Vector2(7, sh + 2), o + Vector2(4, -30 + bob)]), black_hi)
	# parrucca a strisce di lapislazzuli dietro la testa
	draw_colored_polygon(PackedVector2Array([o + Vector2(-6, (sh - 9.0 + bob * 0.5) - 4), o + Vector2(1, (sh - 9.0 + bob * 0.5) - 6), o + Vector2(2, sh + 5), o + Vector2(-7, sh + 6)]), lapis)
	for i in range(4):
		draw_line(o + Vector2(-6, (sh - 9.0 + bob * 0.5) - 1 + i * 3.4), o + Vector2(1.5, (sh - 9.0 + bob * 0.5) - 1 + i * 3.4), gold, 0.8)
	# braccio dietro (tiene lo scettro)
	draw_line(o + Vector2(-8, sh + 2), o + Vector2(sx, -32 + bob), black, 3.2)
	draw_circle(o + Vector2(sx, -31 + bob), 1.8, black)
	draw_line(o + Vector2(-9.5, sh + 6), o + Vector2(-10.5, sh + 8), gold, 2.0)
	# collare usekh
	for r in range(4):
		var col: Color = [gold, lapis, turq, gold][r]
		draw_arc(o + Vector2(0, sh - 1), 4.0 + r * 2.2, 0.08 * PI, 0.92 * PI, 14, col, 2.0)
	# braccio davanti: tiene l'ankh lungo il fianco; quando parla si alza verso di te
	var lift := 0.0
	if talking:
		lift = 0.6 + 0.25 * sin(t * 3.0)
	var shoulder := o + Vector2(8, sh + 2)
	var elbow := shoulder + Vector2(2 + 4 * lift, 9 - 6 * lift)
	var hand := elbow + Vector2(1 + 7 * lift, 8 - 12 * lift)
	draw_line(shoulder, elbow, black, 3.2)
	draw_line(elbow, hand, black, 3.0)
	draw_line(shoulder + Vector2(1, 5), shoulder + Vector2(1.5, 7), gold, 2.0)
	draw_circle(hand, 1.9, black)
	# l'ankh nella mano
	var ak := hand + Vector2(0.5, 2.5 - 2.0 * lift)
	draw_arc(ak + Vector2(0, -4), 2.0, 0, TAU, 10, gold, 1.3)
	draw_line(ak + Vector2(-2.5, -1.5), ak + Vector2(2.5, -1.5), gold, 1.3)
	draw_line(ak + Vector2(0, -2), ak + Vector2(0, 5), gold, 1.4)
	var hy := sh - 9.0 + bob * 0.5
	# testa di sciacallo: cranio, muso lungo, orecchie alte che a volte si muovono
	var twitch := 0.0
	var tw := fmod(t, 4.3)
	if tw < 0.18:
		twitch = sin(tw / 0.18 * PI) * 2.0
	draw_colored_polygon(PackedVector2Array([o + Vector2(-3, hy - 3), o + Vector2(-1, hy - 21 - twitch), o + Vector2(3, hy - 4)]), black)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-1.5, hy - 4), o + Vector2(-0.8, hy - 16 - twitch), o + Vector2(1.5, hy - 5)]), gold_dk)
	draw_colored_polygon(PackedVector2Array([o + Vector2(1, hy - 4), o + Vector2(5, hy - 22), o + Vector2(6, hy - 3)]), black)
	draw_colored_polygon(PackedVector2Array([o + Vector2(2.5, hy - 5), o + Vector2(4.8, hy - 17), o + Vector2(5, hy - 5)]), Color(0.55, 0.16, 0.14))
	draw_circle(o + Vector2(1, hy), 5.5, black)
	draw_colored_polygon(PackedVector2Array([o + Vector2(3, hy - 3), o + Vector2(15, hy + 1), o + Vector2(15, hy + 3), o + Vector2(3, hy + 4)]), black)
	draw_line(o + Vector2(4, hy - 2.5), o + Vector2(14, hy + 1), black_hi, 1.0)
	draw_circle(o + Vector2(15, hy + 2), 1.2, Color(0.02, 0.02, 0.03))
	draw_line(o + Vector2(7, hy + 3.5), o + Vector2(14, hy + 2.5), Color(0.25, 0.2, 0.3), 0.8)
	# occhio d'oro con il kohl: brilla di più quando parla
	var eye := o + Vector2(4, hy - 1)
	draw_circle(eye, 3.0 + 1.5 * pulse, Color(1, 0.8, 0.3, (0.25 if talking else 0.1) * pulse))
	draw_colored_polygon(PackedVector2Array([eye + Vector2(-2, 0), eye + Vector2(0, -1.2), eye + Vector2(2.2, 0), eye + Vector2(0, 1)]), Color(1, 0.85, 0.35))
	draw_line(eye + Vector2(-2, 0), eye + Vector2(-5, 0.6), gold, 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if near == "anubi" and not talk_box.visible:
		draw_arc(Vector2(p.x, p.y - 30), 30.0, 0.0, TAU, 40, Color(aura, 0.5 + 0.3 * sin(t * 4.0)), 1.5)


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
	# un ricordo nuovo da leggere: il leggio brilla d'oro anche da lontano
	if Lore.unread_ricordi() > 0 and book == null:
		var glow := 0.5 + 0.5 * sin(t * 3.0)
		draw_circle(Vector2(p.x, p.y - 18), 30.0 + glow * 4.0, Color(0.94, 0.72, 0.3, 0.08 + 0.08 * glow))
		draw_arc(Vector2(p.x, p.y - 18), 30.0 + glow * 4.0, 0.0, TAU, 32, Color(0.94, 0.72, 0.3, 0.45 + 0.35 * glow), 1.5)



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


## Freccia che indica una stanza appena aperta (il Cortile di Neith). Se la porta è sullo
## schermo la freccia le danza accanto; se è fuori, resta sul bordo e punta verso di lei.
class NewRoomArrow extends Control:
	var target: Node2D

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(target):
			return
		var vs := get_viewport().get_visible_rect().size
		var u: float = Fx.ui
		var sp: Vector2 = target.get_global_transform_with_canvas().origin
		var bob := sin(Time.get_ticks_msec() / 160.0) * 4.0 * u
		var col := Color(0.98, 0.8, 0.32)
		var pos: Vector2
		var a: float
		if Rect2(Vector2.ZERO, vs).grow(-12.0).has_point(sp):
			# sulla porta: la freccia sta a destra e punta a sinistra, verso l'ingresso
			a = PI
			pos = sp + Vector2(34.0 * u + bob, 0)
		else:
			var center := vs / 2.0
			var dir := (sp - center).normalized()
			var m := 26.0 * u
			var inner := Rect2(Vector2(m, m + 24.0 * u), vs - Vector2(m * 2.0, m * 2.0 + 24.0 * u))
			var tx := INF if dir.x == 0.0 else ((inner.end.x if dir.x > 0.0 else inner.position.x) - center.x) / dir.x
			var ty := INF if dir.y == 0.0 else ((inner.end.y if dir.y > 0.0 else inner.position.y) - center.y) / dir.y
			a = dir.angle()
			pos = center + dir * minf(tx, ty) + dir * bob
		var r := 11.0 * u
		var tip := pos + Vector2.from_angle(a) * r
		var l := pos + Vector2.from_angle(a + 2.5) * r
		var rr := pos + Vector2.from_angle(a - 2.5) * r
		var back := pos - Vector2.from_angle(a) * r * 0.3
		draw_circle(pos, r + 4.0 * u, Color(0, 0, 0, 0.55))
		draw_colored_polygon(PackedVector2Array([tip, l, back, rr]), col)
		draw_polyline(PackedVector2Array([tip, l, back, rr, tip]), Color(1, 0.96, 0.85), 1.3)
		var font := UiStyle.title_font()
		var fs := Fx.fs(8)
		var txt := "NUOVO · Cortile di Neith"
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := pos + Vector2(-tw / 2.0, r + 14.0 * u)
		tp.x = clampf(tp.x, 6.0, vs.x - tw - 6.0)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8))
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
