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
const CASA_Y := 218.0                     ## la porta della Casa della Vita, nella parete est
const SPHINX_X := 616.0                   ## la porta della Sfinge, nella parete nord (blocco 15)

var player
var emerging: Rebirth.Emergence = null           ## la riemersione dal disco solare, finché dura (rebirth.gd)
var spots := {}                       # nome -> posizione dei punti con cui interagire
var near := ""
var talk_lines: Array = []
var commented := false
var talk_who := "anubi"                  ## chi sta parlando: "anubi" o "neith" (quando viene a offrirti l'arco)
var _news := [false, false, false, false, false, false]   ## Anubi, Libro, Papiri, cassa: c'è qualcosa di nuovo? (_draw_markers)
var bastet_cat: Node2D = null           ## il gatto di Bastet (restauro)
var _news_t := 0.0
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
var sphinx_board: CanvasLayer = null      ## la classifica della Sfinge, se aperta
var tales_box: CanvasLayer = null         ## i «Racconti dell'acqua», se aperti
var tale_list: Array = []
var tale_i := 0
var hub_art: Node2D = null
var scale_glow := 0.0                     ## la luce calda della bilancia quando ti avvicini

@onready var world: Node2D = $World
@onready var hud: Label = $UI/Hud
@onready var prompt: Label = $UI/Prompt
@onready var help: Label = $UI/Help
@onready var talk_box: PanelContainer = $UI/Talk
@onready var talk_name: Label = $UI/Talk/Box/Name
@onready var talk_text: Label = $UI/Talk/Box/Text


func _ready() -> void:
	Diag.record.call_deferred("Sala")
	Engine.time_scale = 1.0
	get_tree().paused = false
	Run.trial = false                       # di ritorno dalla prova della Sfinge
	# una discesa rimasta a metà (gioco chiuso, telefono che chiude la pagina): si riprende da lì
	# (sul web "Esci" porta qui: allora la discesa aspetta al cancello, vedi _start_run)
	if Run.has_saved_descent() and not Run.hold_descent:
		var d := Run.load_descent()
		if not d.is_empty():
			Run.resume = d
			get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
			return
		Run.clear_descent()
	Run.in_hub = true
	Fx.fs_hint.call_deferred(self)          # la prima volta sul PC: "Premi F per lo schermo intero"
	Music.play("hub")
	Run.new_run()
	Fx.world = world
	# l'interpolazione fisica (project.godot) solo per chi si muove a ogni passo della fisica:
	# eroe e nemici (vedi i loro _ready). Il resto (scintille, numeri, proiettili) no.
	world.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var cx := ROOM.size.x / 2.0
	spots = {
		"anubi": Vector2(cx - 120.0, 200.0),
		"libro": Vector2(cx + 120.0, 200.0),
		"bilancia": Vector2(cx, 190.0),
		"cancello": Vector2(cx, TOP + 4.0),
		"papiri": Vector2(cx + 150.0, 322.0),
		"cassa": Vector2(cx - 150.0, 322.0),       # la cassa dello scalpellino: i restauri
		# Neith, quando porta l'arco: nello spazio libero tra la porta del Cortile e Anubi, lontana
		# dalle colonne (x 100) e dal tappeto che porta al cancello
		"neith": Vector2(cx - 172.0, 236.0),
		# la vasca del Nilo (restauro) e i suoi «Racconti dell'acqua» (tales.gd)
		"vasca": Vector2(cx - 246.0, 328.0),
	}
	_build()
	Fx.scale_labels($UI)
	_build_update_tag()
	talk_box.visible = false
	UiStyle.talk_style(talk_box, talk_name, talk_text, Boons.god_color("anubi"))
	if Meta.runs == 0 or Meta.last_end != "":
		if emerging != null:
			emerging.finished.connect(_start_talk)
		else:
			_start_talk()


func _build() -> void:
	_solid(Rect2(0, 0, ROOM.size.x, TOP))
	_solid(Rect2(0, ROOM.size.y - WALL, ROOM.size.x, WALL))
	_solid(Rect2(0, 0, WALL, ROOM.size.y))
	_solid(Rect2(ROOM.size.x - WALL, 0, WALL, ROOM.size.y))
	_solid(Rect2(spots["anubi"] - Vector2(18, 6), Vector2(36, 10)))
	_solid(Rect2(spots["libro"] - Vector2(12, 6), Vector2(24, 12)))
	_solid(Rect2(spots["bilancia"] - Vector2(20, 7), Vector2(40, 13)))      # la base a gradini
	_solid(Rect2(spots["vasca"] - Vector2(38, 14), Vector2(76, 28)))         # la vasca incassata
	_solid(Rect2(spots["papiri"] - Vector2(20, 8), Vector2(40, 12)))
	_solid(Rect2(spots["cassa"] - Vector2(18, 7), Vector2(36, 12)))
	var decor := DecorScript.new()
	decor.cold_braziers = not Restorations.has("bracieri")
	world.add_child(decor)
	for r in decor.build(424242, ROOM, TOP, WALL, [], true):
		_solid(r)
	decor.ambient.color = Atmos.AMBIENT_HUB
	# i bracieri restaurati scaldano davvero la Sala: la notte blu si fa più chiara e calda, e da
	# ogni angolo arriva una luce ampia (vera sul computer, finta sul telefono). Il prima e dopo
	# deve vedersi subito: è il premio del restauro.
	if not decor.cold_braziers:
		decor.ambient.color = Atmos.AMBIENT_HUB_LIT
		for pr in decor.props:
			if pr[0] == "brazier":
				Atmos.add_light(decor, pr[1] + Vector2(0, -10), 380.0, Color(1.0, 0.64, 0.34), 1.0, false, true)
	# si illumina ciò che conta: una luce di luna dal cancello sulla bilancia, lampade calde su
	# Anubi, sul Libro e sui Papiri; il resto della Sala resta nella notte blu
	Atmos.add_light(decor, spots["bilancia"] + Vector2(0, 30), 260.0, Color(0.6, 0.8, 1.0), 1.0, false, true).set_process(false)
	Atmos.add_light(decor, spots["cancello"] + Vector2(0, 40), 160.0, Color(0.45, 0.9, 0.85), 0.9, false, true).set_process(false)
	for k in ["anubi", "libro", "papiri"]:
		Atmos.add_light(decor, spots[k] + Vector2(0, -10), 120.0, Color(1.0, 0.7, 0.4), 1.1, true, true)
	Atmos.vignette(self, 1.0)
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
	var art := HubArt.new()
	art.spots = spots
	world.add_child(art)
	hub_art = art
	_add_dust()
	var floor_arrows := HubDoorArrows.new()
	floor_arrows.hub = self
	world.add_child(floor_arrows)
	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - WALL - 30.0)
	if Run.from_armory:
		Run.from_armory = false
		player.position = Vector2(WALL + 26.0, ARMORY_Y)
	if Run.from_casa:
		Run.from_casa = false
		player.position = Vector2(ROOM.size.x - WALL - 26.0, CASA_Y)
	if Run.from_sphinx:
		Run.from_sphinx = false
		player.position = Vector2(SPHINX_X, TOP + 30.0)
	if Run.from_restore:
		Run.from_restore = false
		player.position = spots["cassa"] + Vector2(0, 30)
	# di ritorno da una discesa: l'eroe riemerge dal disco solare al centro della Sala, come il
	# sole all'alba (rebirth.gd). Anubi parla dopo.
	var reborn := Run.rebirth
	Run.rebirth = ""
	if reborn != "":
		player.position = Vector2(ROOM.size.x / 2.0, 238.0)
	world.add_child(player)
	if reborn != "":
		emerging = Rebirth.Emergence.new()
		emerging.player = player
		emerging.victory = reborn == "win"
		emerging.position = Vector2(ROOM.size.x / 2.0, 226.0)
		world.add_child(emerging)
	if Restorations.has("gatto"):
		bastet_cat = HubCat.new()
		bastet_cat.position = player.position + Vector2(-40, 6)
		bastet_cat.player = player
		world.add_child(bastet_cat)
		# ogni tanto il gatto ti ha portato qualcosa: lo trovi davanti al cancello
		if Meta.runs > 0 and randf() < 0.35:
			var gift := CatGift.new()
			gift.position = spots["cancello"] + Vector2(28, 54)
			world.add_child(gift)
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
	# il numero di versione, piccolo in basso a sinistra: chi segnala un problema sa dire quale
	var ver := Label.new()
	ver.text = "v" + Updater.label()
	ver.add_theme_font_size_override("font_size", Fx.fs(7))
	ver.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7, 0.7))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.offset_left = 6.0
	ver.offset_top = -14.0 * Fx.ui
	ver.offset_bottom = -2.0
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ver.visible = OS.get_environment("DUAT_TRAILER") == ""
	$UI.add_child(ver)
	update_tag = Button.new()
	update_tag.text = Lang.t("Nuova versione, aggiorna!") if Updater.channel() == "dev" else Lang.t("Nuova versione: ricarica la pagina!")
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
	hud.text = Lang.t("Sala del Giudizio\nKa custodito %d · Lapislazzuli %d · Discese %d · Vittorie %d") % [Meta.ka_bank, Meta.lapis, Meta.runs, Meta.ammit_wins]
	if Run.hold_descent:
		hud.text += "\n" + Lang.t("La tua discesa ti aspetta oltre il cancello")
	_update_update_tag()
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = Lang.t("Levetta muovi · LB/A scatto · Y interagisci · Start opzioni")
	else:
		help.text = Lang.t("WASD muovi · Spazio scatto · E interagisci · Esc opzioni")
	if OS.get_environment("DUAT_TRAILER") != "":
		help.text = ""                       # riprese per trailer e screenshot
		hud.text = ""

	scale_glow = move_toward(scale_glow, 1.0 if player.global_position.distance_to(spots["bilancia"]) < 70.0 else 0.0, delta * 1.5)
	if talk_box.visible or book != null or sphinx_board != null or tales_box != null:
		prompt.visible = false
		return
	# il cancello si attraversa camminandoci dentro
	if player.global_position.y < TOP + 14.0 and absf(player.global_position.x - spots["cancello"].x) < 22.0:
		_start_run()
		return
	# la porta del Cortile di Neith si attraversa camminandoci dentro (aperta dopo il primo Serpente)
	var at_door: bool = player.global_position.x < WALL + 14.0 and absf(player.global_position.y - ARMORY_Y) < 24.0
	if at_door and Meta.serpent_wins > 0:
		Meta.use_door("cortile")
		Sfx.play("door")
		get_tree().change_scene_to_file("res://scenes/armory.tscn")
		return
	# la porta della Sfinge, a nord: si attraversa quando è aperta (Sphinx.COST lapislazzuli)
	if Sphinx.is_open() and player.global_position.y < TOP + 14.0 and absf(player.global_position.x - SPHINX_X) < 16.0:
		_start_sphinx()
		return
	# la porta della Casa della Vita, a est: si attraversa quando è aperta (30 lapislazzuli)
	if Meta.casa and player.global_position.x > ROOM.size.x - WALL - 14.0 and absf(player.global_position.y - CASA_Y) < 24.0:
		Meta.use_door("casa")
		Sfx.play("door")
		get_tree().change_scene_to_file("res://scenes/casa.tscn")
		return
	near = ""
	if player.global_position.x < WALL + 40.0 and absf(player.global_position.y - ARMORY_Y) < 30.0:
		near = "cortile"
	if player.global_position.x > ROOM.size.x - WALL - 40.0 and absf(player.global_position.y - CASA_Y) < 30.0:
		near = "casa"
	if player.global_position.y < TOP + 44.0 and absf(player.global_position.x - SPHINX_X) < 30.0:
		near = "sfinge"
	if Rect2(spots["vasca"] - Vector2(40, 16), Vector2(80, 32)).grow(18.0).has_point(player.global_position):
		near = "vasca"
	for k in ["anubi", "libro", "bilancia", "papiri", "cassa"]:
		if player.global_position.distance_to(spots[k]) < 40.0:
			near = k
	if bastet_cat != null and is_instance_valid(bastet_cat) and near == "" and player.global_position.distance_to(bastet_cat.position) < 26.0:
		near = "gatto"
	if _neith_here() and player.global_position.distance_to(spots["neith"]) < 34.0:
		near = "neith"
	var key := "Y" if Fx.device == "pad" else "E"
	match near:
		"anubi":
			prompt.text = Lang.t("%s · Parla con Anubi") % key
		"libro":
			prompt.text = Lang.t("%s · Apri il Libro dei Morti") % key
		"papiri":
			var n := Lore.count_seen()
			prompt.text = Lang.t("%s · Leggi i Papiri di Thoth (%d su %d)") % [key, n.x, n.y]
			if Lore.unread_ricordi() > 0:
				prompt.text += Lang.t(" · un ricordo nuovo")
		"bilancia":
			if Weights.unlocked():
				prompt.text = Lang.t("%s · Il Peso del Cuore (peso attuale %d, Ka +%d%%)") % [key, Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0))]
			else:
				prompt.text = Lang.t("La bilancia di Ma'at · Sconfiggi Am-heh per poter posare i tuoi pesi")
		"cassa":
			prompt.text = Lang.t("%s · La cassa dello scalpellino: restauri e grazie degli dèi (lapislazzuli: %d)") % [key, Meta.lapis]
		"gatto":
			prompt.text = Lang.t("%s · Accarezza il gatto") % key
		"vasca":
			var tn := Tales.unlocked().size()
			prompt.text = Lang.t("%s · Racconti dell'acqua (%d su %d)") % [key, tn, Tales.all().size()]
			if Tales.unread() > 0:
				prompt.text += Lang.t(" · un racconto nuovo")
		"neith":
			prompt.text = Lang.t("%s · Parla con Neith") % key
		"casa":
			if Meta.casa:
				prompt.text = Lang.t("La Casa della Vita · amuleti e sfide · entra dalla porta")
			else:
				prompt.text = Lang.t("%s · Apri la Casa della Vita: amuleti e sfide (%d lapislazzuli, ne hai %d)") % [key, CASA_COST, Meta.lapis]
		"sfinge":
			if Sphinx.is_open():
				prompt.text = Lang.t("%s · La scala dell'enigma: classifica e premi · arma del giorno: %s · entra dalla porta") % [key, Sphinx.weapon_name(Sphinx.weapon_of_day())]
			else:
				prompt.text = Lang.t("%s · Apri la porta della Sfinge: una prova a ondate (%d lapislazzuli, ne hai %d)") % [key, Sphinx.COST, Meta.lapis]
		"cortile":
			if Meta.serpent_wins > 0:
				prompt.text = Lang.t("Il Cortile di Neith · le armi · entra dalla porta")
			else:
				prompt.text = Lang.t("Il Cortile di Neith · si aprirà quando avrai battuto il Serpente della Porta")
		_:
			prompt.text = Lang.t("Il cancello del Duat è a nord") if player.global_position.y < TOP + 90.0 else ""
	prompt.visible = prompt.text != ""


func _unhandled_input(event: InputEvent) -> void:
	if tales_box != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") or event.is_action_pressed("pause"):
			_close_tales()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			_turn_tale(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			_turn_tale(1)
			get_viewport().set_input_as_handled()
		return
	if sphinx_board != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") or event.is_action_pressed("pause"):
			_close_sphinx_board()
			get_viewport().set_input_as_handled()
		return
	if book != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact") or event.is_action_pressed("pause"):
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
		elif near == "cassa":
			_open_book("restauri")
		elif near == "gatto":
			bastet_cat.pet()
		elif near == "vasca":
			_open_tales()
		elif near == "neith":
			_start_neith()
		elif near == "casa" and not Meta.casa:
			_open_casa()
		elif near == "sfinge":
			if Sphinx.is_open():
				_show_sphinx_board()
			else:
				_open_sphinx()
		elif near == "bilancia" and Weights.unlocked():
			_open_book("pesi")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_open_options()


## Esc / Start nella Sala: le Opzioni (scripts/ui/options_menu.gd). In fondo le voci della Sala:
## aggiornamento (solo web), il modulo per i commenti, l'uscita dal gioco (non sul web).
func _open_options() -> void:
	player.set_physics_process(false)
	var m := OptionsMenu.new()
	if Updater.supported():
		m.extra.append([Lang.t("Aggiornamento del gioco"), func() -> void:
			_open_book("opzioni")
			_fill_options("update")
			_show_option("update")])
	if FEEDBACK_URL != "":
		m.extra.append([Lang.t("Lascia un commento"), func() -> void: OS.shell_open(FEEDBACK_URL)])
	if not OS.has_feature("web"):
		m.extra.append([Lang.t("Esci dal gioco"), func() -> void:
			Meta.save()
			get_tree().quit()])
	m.closed.connect(func() -> void:
		if book == null:
			player.set_physics_process(true))
	add_child(m)


const CASA_COST := 30

## Si apre la Casa della Vita: i lapislazzuli spesi, la porta murata che crolla.
func _open_casa() -> void:
	if Meta.lapis < CASA_COST:
		Fx.float_text(player.global_position + Vector2(0, -20), Lang.t("Servono %d lapislazzuli") % CASA_COST, Color(0.9, 0.4, 0.35))
		Fx.shake(2.0)
		return
	Meta.lapis -= CASA_COST
	Meta.casa = true
	Meta.save()
	Sfx.play("jar_break", 0.0)
	Sfx.play("boon", 0.0)
	Fx.shake(6.0)
	Fx.burst(Vector2(ROOM.size.x - WALL, CASA_Y), Color(0.78, 0.66, 0.46), 40, 140.0)
	Fx.burst(Vector2(ROOM.size.x - WALL, CASA_Y), Restorations.LAPIS_COLOR, 20, 110.0)
	queue_redraw()


## Si apre la porta della Sfinge: i lapislazzuli spesi, la lastra col lucchetto che scivola via.
func _open_sphinx() -> void:
	if Meta.lapis < Sphinx.COST:
		Fx.float_text(player.global_position + Vector2(0, -20), Lang.t("Servono %d lapislazzuli") % Sphinx.COST, Color(0.9, 0.4, 0.35))
		Fx.shake(2.0)
		return
	Meta.lapis -= Sphinx.COST
	Sphinx.open()
	Sfx.play("jar_break", 0.0)
	Sfx.play("boon", 0.0)
	Fx.shake(5.0)
	Fx.burst(Vector2(SPHINX_X, TOP - 6.0), Color(0.93, 0.78, 0.45), 36, 130.0)
	Fx.burst(Vector2(SPHINX_X, TOP - 6.0), Restorations.LAPIS_COLOR, 18, 100.0)
	Fx.float_text(player.global_position + Vector2(0, -26), Lang.t("La porta della Sfinge è aperta"), Color(0.93, 0.78, 0.45), 10)
	queue_redraw()


func _start_sphinx() -> void:
	Meta.use_door("sfinge")
	Run.trial = true
	Meta.save()
	Sfx.play("door")
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


## La classifica della Sfinge (i 10 migliori punteggi di questo dispositivo), i premi della
## settimana e l'arma del giorno.
func _show_sphinx_board() -> void:
	player.set_physics_process(false)
	var u := Fx.ui
	var vs := get_viewport().get_visible_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	sphinx_board = layer
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var pap := PanelContainer.new()
	# la cornice comprata nel Tesoro della Sfinge
	var fr := SphinxShop.frame()
	var border := Color(0.6, 0.46, 0.2)
	if fr == "f_lapis":
		border = Color(0.2, 0.33, 0.72)
	elif fr == "f_oro":
		border = Color(0.95, 0.74, 0.3)
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(border))
	center.add_child(pap)
	var w := minf(430.0 * u, vs.x - 36.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(3 * u))
	pap.add_child(col)
	var h := UiStyle.label(Lang.t("La scala dell'enigma"), 13, UiStyle.INK, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var who := SphinxUI.seals_text()
	if SphinxShop.title_text() != "":
		who = Lang.t("Il tuo titolo: %s") % SphinxShop.title_text() + "   ·   " + who
	var whol := UiStyle.label(who, 8, UiStyle.INK_RED, true)
	whol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(whol)
	col.add_child(UiStyle.label(Lang.t("Oggi l'arma è %s: la stessa per tutti. Vita normale, nessun dono, capitolo o amuleto: ogni 3 ondate la Sfinge si ferma per un enigma e un dono. Morire qui non tocca la discesa.") % Sphinx.weapon_name(Sphinx.weapon_of_day()), 8, UiStyle.INK_SOFT, false, w))
	var c := Sphinx.claimed()
	var parts := []
	for th in Sphinx.WEEKLY:
		var r: Array = Sphinx.WEEKLY[th]
		parts.append((Lang.t("ondata %d: preso") % th) if c.has(th) else (Lang.t("ondata %d: %d Ka + %d lapislazzuli") % [th, r[0], r[1]]))
	if Sphinx.clock_ok():
		col.add_child(UiStyle.label(Lang.t("Premi della settimana (si rinnovano tra %s): ") % Sphinx.reset_text() + " · ".join(parts), 8, UiStyle.INK_GREEN, false, w))
	else:
		col.add_child(UiStyle.label(Lang.t("I premi della settimana non sono disponibili: controlla la data del dispositivo."), 8, UiStyle.INK_SOFT, false, w))
	var list := Sphinx.scores()
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w, minf(120.0 * u, vs.y * 0.36))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(rows)
	if list.is_empty():
		rows.add_child(UiStyle.label(Lang.t("Nessun punteggio, per ora. La scala aspetta."), 9, UiStyle.INK_SOFT, false, w))
	for i in range(list.size()):
		var e: Dictionary = list[i]
		var line := Lang.t("%d. %d punti · ondata %d · %s · %s") % [i + 1, int(e["score"]), int(e["wave"]), Sphinx.weapon_name(String(e["weapon"])), String(e["date"])]
		var em: Array = e.get("mods", [])
		if not em.is_empty():
			line += "\n" + "    " + Lang.t("modificatori: %s (%s)") % [SphinxShop.mod_names(em), SphinxShop.mult_text(SphinxShop.mult(em))]
		rows.add_child(UiStyle.label(line, 9, UiStyle.INK if i > 0 else UiStyle.INK_RED, i == 0, w))
	var b := Button.new()
	b.text = Lang.t("Chiudi")
	UiStyle.papyrus_button(b, Color(0.93, 0.78, 0.45))
	b.add_theme_font_size_override("font_size", Fx.fs(9))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_close_sphinx_board)
	col.add_child(b)
	b.grab_focus.call_deferred()


func _close_sphinx_board() -> void:
	if sphinx_board != null:
		sphinx_board.queue_free()
		sphinx_board = null
	player.set_physics_process(true)


## I «Racconti dell'acqua» (tales.gd): un racconto per pagina, con le frecce (anche sul telefono);
## si parte dal primo non ancora letto. L'acqua si increspa e fa il suo suono.
func _open_tales() -> void:
	tale_list = Tales.unlocked()
	if tale_list.is_empty():
		return
	player.set_physics_process(false)
	Sfx.play("splash", 0.1, -6.0)
	if hub_art != null and is_instance_valid(hub_art):
		hub_art.ripple(player.global_position)
	tale_i = 0
	for i in range(tale_list.size()):
		if Tales.is_new(String(tale_list[i][0])):
			tale_i = i
			break
	tales_box = CanvasLayer.new()
	tales_box.layer = 20
	add_child(tales_box)
	_fill_tale()


func _fill_tale() -> void:
	for c in tales_box.get_children():
		c.queue_free()
	var u := Fx.ui
	var vs := get_viewport().get_visible_rect().size
	var e: Array = tale_list[tale_i]
	var fresh := Tales.is_new(String(e[0]))
	Tales.mark_read(String(e[0]))
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	tales_box.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	tales_box.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.2, 0.42, 0.55)))
	center.add_child(pap)
	var w := minf(420.0 * u, vs.x - 40.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(4 * u))
	pap.add_child(col)
	var sub := UiStyle.label(Lang.t("Racconti dell'acqua · %d di %d") % [tale_i + 1, tale_list.size()] + ("   ·   " + Lang.t("NUOVO") if fresh else ""), 8, UiStyle.INK_SOFT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var h := UiStyle.label(String(e[1]), 13, UiStyle.INK, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var body := UiStyle.label(String(e[2]), 9, UiStyle.INK, false, w)
	col.add_child(body)
	var hint := Tales.next_hint()
	if hint != "" and tale_i == tale_list.size() - 1:
		var hl := UiStyle.label(Lang.t("Il prossimo racconto: %s") % hint, 8, UiStyle.INK_SOFT, false, w)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(hl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(10 * u))
	col.add_child(row)
	var accent := Color(0.3, 0.62, 0.75)
	var prev := Button.new()
	prev.text = "◀"
	UiStyle.papyrus_button(prev, accent)
	prev.add_theme_font_size_override("font_size", Fx.fs(12))
	prev.custom_minimum_size = Vector2(44, 26) * u
	prev.disabled = tale_i == 0
	prev.pressed.connect(_turn_tale.bind(-1))
	row.add_child(prev)
	var close := Button.new()
	close.text = Lang.t("Chiudi")
	UiStyle.papyrus_button(close, accent)
	close.add_theme_font_size_override("font_size", Fx.fs(10))
	close.pressed.connect(_close_tales)
	row.add_child(close)
	var nxt := Button.new()
	nxt.text = "▶"
	UiStyle.papyrus_button(nxt, accent)
	nxt.add_theme_font_size_override("font_size", Fx.fs(12))
	nxt.custom_minimum_size = Vector2(44, 26) * u
	nxt.disabled = tale_i >= tale_list.size() - 1
	nxt.pressed.connect(_turn_tale.bind(1))
	row.add_child(nxt)
	(nxt if not nxt.disabled else close).grab_focus.call_deferred()


func _turn_tale(dir: int) -> void:
	var j := clampi(tale_i + dir, 0, tale_list.size() - 1)
	if j == tale_i or tales_box == null:
		return
	tale_i = j
	Sfx.play("ui", 0.0)
	_fill_tale()


func _close_tales() -> void:
	if tales_box != null:
		tales_box.queue_free()
		tales_box = null
	player.set_physics_process(true)


## Anubi offre la Piuma di Ma'at: sì o no, subito, senza cercarla nelle Opzioni.
func _offer_feather() -> void:
	player.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.62, 0.56, 0.92).darkened(0.3)))
	center.add_child(pap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(5 * Fx.ui))
	col.custom_minimum_size = Vector2(minf(420.0 * Fx.ui, get_viewport().get_visible_rect().size.x - 40.0), 0)
	pap.add_child(col)
	var h := UiStyle.label(Lang.t("La piuma di Ma'at"), 13, UiStyle.INK, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	col.add_child(UiStyle.label(Lang.t("Un quarto di nemici in meno, più lenti del 10%, e il 10% di danni in meno (un altro 2% a ogni morte, fino al 30%). In cambio custodisci il 40% del Ka, e lapislazzuli, cuori, serdab e Lacrime valgono la metà. Il Peso del Cuore non conta. La storia va avanti comunque. Puoi toglierla quando vuoi dalle Opzioni."), 8, UiStyle.INK_SOFT, false, col.custom_minimum_size.x))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(10 * Fx.ui))
	col.add_child(row)
	var close := func(take: bool) -> void:
		if take:
			Meta.feather = true
			Meta.save()
			Sfx.play("boon", 0.0)
			Fx.burst(player.global_position + Vector2(0, -14), Color(0.9, 0.9, 1.0), 24, 100.0)
		layer.queue_free()
		player.set_physics_process(true)
	for opt in [[Lang.t("Accetto la piuma"), true], [Lang.t("No, ci riprovo così"), false]]:
		var b := Button.new()
		b.text = opt[0]
		UiStyle.papyrus_button(b, Color(0.62, 0.56, 0.92))
		b.add_theme_font_size_override("font_size", Fx.fs(9))
		b.pressed.connect(close.bind(opt[1]))
		row.add_child(b)
		if opt[1]:
			b.grab_focus.call_deferred()


func _start_run() -> void:
	if Run.hold_descent:
		Run.hold_descent = false
		if Run.has_saved_descent():
			Run.resume = Run.load_descent()
	Meta.last_end = ""
	Meta.use_door("cancello")
	Meta.save()
	Sfx.play("door")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------- dialoghi

func _start_talk() -> void:
	_talk_as("anubi")
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
		if talk_who == "neith":
			_offer_bow.call_deferred()
			return
		if Dialogue.offer_feather:
			Dialogue.offer_feather = false
			_offer_feather.call_deferred()
		return
	Sfx.play("ui", 0.0)
	talk_name.text = Lang.t("Neith") if talk_who == "neith" else (Lang.t("Thoth") if talk_who == "thoth" else Lang.t("Anubi"))
	talk_text.text = UiStyle.next_talk_page(talk_lines)


func _talk_as(who: String) -> void:
	talk_who = who
	var col := Boons.god_color("anubi")
	if who == "neith":
		col = NeithArt.NEITH_COLOR
	elif who == "thoth":
		col = Boons.god_color("thoth")
	UiStyle.talk_style(talk_box, talk_name, talk_text, col)


# ---------------------------------------------------------------- Neith e l'Arco di Satet

## Neith lascia il suo cortile e viene nella Sala dopo la terza vittoria sul Serpente, finché
## non prendi l'arco (si compra anche al suo piedistallo nel Cortile).
func _neith_here() -> bool:
	return Weapons.requirement_met("arco") and not Weapons.is_unlocked("arco")


func _start_neith() -> void:
	_talk_as("neith")
	var cost := Weapons.unlock_cost("arco")
	if not Meta.neith_seen.has("arco_sala"):
		Meta.neith_seen.append("arco_sala")
		Meta.save()
		talk_lines = [
			Lang.t("Scriba. Tre volte il Serpente della Porta è caduto sotto la tua mano, e le sue spire ne portano ancora il segno."),
			Lang.t("Ho lasciato il mio cortile per dirtelo qui, davanti al giudice dei morti: ora sei degno di un'arma che colpisce da lontano."),
			Lang.t("Questo è l'arco di Satet, signora della cataratta. Le sue frecce aprono ogni anno la piena del fiume. Nella notte apriranno la tua strada."),
			Lang.t("Ma il legno di Satet non si dona: chiede pietra del cielo. Posa ai miei piedi %d lapislazzuli, e la corda sarà tua per sempre.") % cost,
		]
	else:
		talk_lines = [Lang.t("L'arco di Satet ti attende ancora. %d lapislazzuli, e la corda risponderà alla tua mano.") % cost]
	player.set_physics_process(false)
	talk_box.visible = true
	_advance_talk()


## La finestra di Neith: prendi l'arco ora (con i lapislazzuli) o più tardi, anche nel Cortile.
func _offer_bow() -> void:
	_talk_as("anubi")
	player.set_physics_process(false)
	var cost := Weapons.unlock_cost("arco")
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(NeithArt.NEITH_COLOR.darkened(0.3)))
	center.add_child(pap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(5 * Fx.ui))
	col.custom_minimum_size = Vector2(minf(420.0 * Fx.ui, get_viewport().get_visible_rect().size.x - 40.0), 0)
	pap.add_child(col)
	var h := UiStyle.label(Weapons.ALL["arco"]["name"], 13, NeithArt.NEITH_COLOR.darkened(0.25), true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	col.add_child(UiStyle.label(Weapons.ALL["arco"]["desc"], 8, UiStyle.INK_SOFT, false, col.custom_minimum_size.x))
	var price := UiStyle.label(Lang.t("Costa %d lapislazzuli · ne hai %d. Potrai prenderlo anche al suo piedistallo, nel Cortile di Neith.") % [cost, Meta.lapis], 8, UiStyle.INK, false, col.custom_minimum_size.x)
	col.add_child(price)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(10 * Fx.ui))
	col.add_child(row)
	var close := func(take: bool) -> void:
		if take and Weapons.buy("arco"):
			Weapons.choose("arco")
			Sfx.play("boon", 0.0)
			Fx.burst(spots["neith"] + Vector2(0, -20), NeithArt.NEITH_COLOR, 30, 120.0)
			Fx.burst(player.global_position + Vector2(0, -14), Restorations.LAPIS_COLOR, 18, 90.0)
			Fx.float_text(player.global_position + Vector2(0, -34), Weapons.ALL["arco"]["name"], NeithArt.GOLD)
		layer.queue_free()
		player.set_physics_process(true)
	var can := Meta.lapis >= cost
	for opt in [[Lang.t("Prendo l'arco (%d lapislazzuli)") % cost, true], [Lang.t("Più tardi"), false]]:
		var b := Button.new()
		b.text = opt[0]
		UiStyle.papyrus_button(b, NeithArt.NEITH_COLOR)
		b.add_theme_font_size_override("font_size", Fx.fs(9))
		b.add_theme_color_override("font_disabled_color", Color(UiStyle.INK, 0.4))
		b.disabled = opt[1] and not can
		b.pressed.connect(close.bind(opt[1]))
		row.add_child(b)
		if opt[1] == can:
			b.grab_focus.call_deferred()


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
	elif kind == "restauri":
		_fill_restorations()
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
	# anche la pagina a destra scorre: i capitoli del Libro hanno testi lunghi e sul telefono
	# spingevano "Chiudi" fuori dallo schermo (non si capiva come uscire)
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.gui_input.connect(_on_list_drag.bind(page_scroll))
	row.add_child(page_scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	page_scroll.add_child(right)
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
	close.text = Lang.t("Chiudi")
	close.add_theme_font_size_override("font_size", Fx.fs(10))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_book)
	outer.add_child(close)
	var hint := Label.new()
	hint.text = Lang.t("Tocca una voce per leggerla, toccala di nuovo per sceglierla · × per chiudere") if Fx.device == "touch" else Lang.t("E / Esc / B per chiudere")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", Fx.fs(8))
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	outer.add_child(hint)
	# la X in alto a destra, grande: si trova subito, anche con il pollice
	var x := Button.new()
	x.text = "×"
	x.tooltip_text = Lang.t("Chiudi")
	x.focus_mode = Control.FOCUS_NONE        # non ruba lo spostamento con tastiera e pad
	x.add_theme_font_size_override("font_size", Fx.fs(18))
	x.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var xs := 30.0 * Fx.ui if not Fx.mobile else 40.0
	x.offset_left = -xs - 6.0
	x.offset_right = -6.0
	x.offset_top = 6.0
	x.offset_bottom = 6.0 + xs
	x.pressed.connect(_close_book)
	book.add_child(x)
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
	var sub := Lang.t("Ka custodito: %d    ·    Capitoli attivi: %d di %d") % [Meta.ka_bank, Meta.chapters_equipped.size(), Chapters.slots()]
	if Meta.amulet != "" and Amulets.owned(Meta.amulet):
		# tutto l'"equipaggiamento" in un posto solo: anche l'amuleto che porterai giù
		sub += Lang.t("    ·    Amuleto: %s (livello %d)") % [Amulets.data()[Meta.amulet]["name"], Amulets.level(Meta.amulet)]
		if Favors.has("collana") and Meta.amulet2 != "" and Amulets.owned(Meta.amulet2):
			sub += " + %s (%d)" % [Amulets.data()[Meta.amulet2]["name"], Amulets.level(Meta.amulet2)]
	var left := _frame(Lang.t("Il Libro dei Morti"), sub, 260)
	var first: Button = null
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		var lvl := Chapters.level(id)
		var cost := Chapters.next_cost(id)
		var state := Lang.t("%d Ka") % cost[0]
		var col := Color(0.95, 0.9, 0.78)
		if Chapters.is_equipped(id):
			state = Lang.t("ATTIVO")
			col = Color(0.62, 0.95, 0.7)
		elif lvl > 0:
			state = Lang.t("comprato")
		elif Meta.ka_bank < cost[0]:
			col = Color(0.6, 0.55, 0.48)
		var stars := ""
		if Chapters.max_level(id) > 1 and lvl > 0:
			stars = Lang.t("  · liv. %d/%d") % [lvl, Chapters.max_level(id)]    # niente ●○: il telefono non li ha
		var b := _list_button(left, "%d · %s%s   [%s]" % [c["num"], c["name"], stars, state], col)
		_tap(b, _on_chapter_pressed.bind(id))
		b.focus_entered.connect(_show_chapter.bind(id))
		b.mouse_entered.connect(_show_chapter.bind(id))
		if first == null or id == focus_id:
			first = b
	# un posto in più nel Libro, con le Lacrime di Iside
	var sc := Chapters.slot_cost()
	if sc > 0:
		var sb := _list_button(left, Lang.t("Un posto in più nel Libro   [%d Ka]") % sc, Color(0.7, 0.8, 1.0) if Meta.ka_bank >= sc else Color(0.5, 0.52, 0.6))
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
	page_title.text = Lang.t("Capitolo %d · %s%s") % [c["num"], c["name"], "" if maxl == 1 else Lang.t("  (livello %d di %d)") % [maxi(lvl, 1), maxl]]
	var lines := [Chapters.text(id, maxi(lvl, 1))]
	var cost := Chapters.next_cost(id)
	if lvl > 0 and cost[0] >= 0:
		lines.append(Lang.t("Livello %d: %s") % [lvl + 1, Chapters.text(id, lvl + 1)])
	var action := ""
	if Chapters.is_equipped(id):
		action = Lang.t("Attivo. Premi per toglierlo.")
	elif lvl > 0:
		action = Lang.t("Comprato. Premi per attivarlo (posti liberi: %d).") % (Chapters.slots() - Meta.chapters_equipped.size())
	elif Meta.ka_bank >= cost[0]:
		action = Lang.t("Premi per comprarlo: %d Ka.") % cost[0]
	else:
		action = Lang.t("Costa %d Ka: te ne mancano %d.") % [cost[0], cost[0] - Meta.ka_bank]
	lines.append(action)
	page_body.text = "\n\n".join(lines)
	page_lore.text = c["lore"]
	# potenziamento: pulsante a parte, così premere il capitolo resta "attiva / togli"
	page_action.visible = lvl > 0 and cost[0] >= 0
	if page_action.visible:
		var price := Lang.t("%d Ka") % cost[0] + (Lang.t(" + 1 Lacrima di Iside") if cost[1] > 0 else "")
		page_action.text = Lang.t("Potenzia al livello %d  ·  %s") % [lvl + 1, price]
		page_action.disabled = Meta.ka_bank < cost[0] or Meta.tears < cost[1]
		page_action_cb = func() -> void:
			if Chapters.buy(id):
				Sfx.play("boon", 0.0)
				Fx.shake(2.0)
				_fill_book(id)


func _show_slot() -> void:
	page_title.text = Lang.t("Un posto in più nel Libro")
	page_body.text = Lang.t("Puoi tenere attivo un capitolo in più a ogni discesa.\n\nCosta %d Ka: ne hai %d.") % [Chapters.slot_cost(), Meta.ka_bank]
	page_lore.text = Lang.t("Un papiro più lungo per formule in più. I più ricchi si facevano dipingere Libri dei Morti di decine di metri: quello di Ani supera i ventitré.")
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


# ---------------------------------------------------------------- Restauri (la cassa dello scalpellino)

func _fill_restorations(focus_id: String = "") -> void:
	var done := Meta.restorations.size()
	var left := _frame(Lang.t("I restauri della Sala"), Lang.t("Lapislazzuli: %d    ·    Restauri fatti: %d di %d") % [Meta.lapis, done, Restorations.ALL_IT.size()], 260)
	var first: Button = null
	var data := Restorations.data()
	for id in Restorations.ALL_IT:
		var r: Dictionary = data[id]
		var state := Lang.t("restaurato") if Restorations.has(id) else Lang.t("%d lapislazzuli") % int(r["cost"])
		var col := Color(0.62, 0.95, 0.7) if Restorations.has(id) else (Color(0.95, 0.9, 0.78) if Restorations.can_buy(id) else Color(0.6, 0.55, 0.48))
		var b := _list_button(left, "%s   [%s]" % [r["name"], state], col)
		_tap(b, _on_restoration_pressed.bind(id))
		b.focus_entered.connect(_show_restoration.bind(id))
		b.mouse_entered.connect(_show_restoration.bind(id))
		if first == null or id == focus_id:
			first = b
	# le grazie degli dèi: più scelta nella discesa, nessuna potenza (favors.gd)
	var head := Label.new()
	head.text = Lang.t("— Grazie degli dèi —")
	head.add_theme_font_size_override("font_size", Fx.fs(9))
	head.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	left.add_child(head)
	var fdata := Favors.data()
	for id in Favors.SHOP:
		if not Favors.visible(id):
			continue
		var f: Dictionary = fdata[id]
		var state := Lang.t("presa") if Favors.has(id) else Lang.t("%d lapislazzuli") % int(f["cost"])
		if f.get("seals", false) and not Favors.has(id):
			state = Lang.t("%d sigilli · nel Tesoro della Sfinge") % int(f["cost"])
		var col := Color(0.62, 0.95, 0.7) if Favors.has(id) else (Color(0.95, 0.9, 0.78) if Favors.can_buy(id) else Color(0.6, 0.55, 0.48))
		var b := _list_button(left, "%s   [%s]" % [f["name"], state], col)
		_tap(b, _on_favor_pressed.bind(id))
		b.focus_entered.connect(_show_favor.bind(id))
		b.mouse_entered.connect(_show_favor.bind(id))
		if id == focus_id:
			first = b
	first.grab_focus.call_deferred()


func _show_favor(id: String) -> void:
	var f: Dictionary = Favors.data()[id]
	page_title.text = f["name"]
	var action := ""
	if Favors.has(id):
		action = Lang.t("Già tua.")
	elif f.get("seals", false):
		action = Lang.t("Si ottiene nel Tesoro della Sfinge: %d sigilli (ne hai %d).") % [int(f["cost"]), Sphinx.seals()]
	elif Favors.can_buy(id):
		action = Lang.t("Premi per prenderla: %d lapislazzuli.") % int(f["cost"])
	else:
		action = Lang.t("Costa %d lapislazzuli: te ne mancano %d.") % [int(f["cost"]), int(f["cost"]) - Meta.lapis]
	page_body.text = ("(" + String(f["sub"]) + ")\n" if f.has("sub") else "") + f["desc"] + "\n\n" + action
	page_lore.text = f["lore"]
	page_action.visible = false


## Una grazia presa: chi la consegna (Anubi o Thoth dai Papiri) dice la sua battuta.
func _on_favor_pressed(id: String) -> void:
	if Favors.ALL_IT[id].get("seals", false):
		_show_favor(id)                       # il Favore della Sfinge si prende nel Tesoro della Sfinge
		return
	if not Favors.buy(id):
		Fx.shake(2.0)
		_fill_restorations(id)
		return
	Sfx.play("boon", 0.0)
	_close_book()
	Fx.burst(spots["cassa"] + Vector2(0, -14), Restorations.LAPIS_COLOR, 30, 140.0)
	var who: String = Favors.ALL_IT[id]["speaker"]
	_talk_as(who)
	if who == "thoth":
		Fx.burst(spots["papiri"] + Vector2(0, -16), Boons.god_color("thoth"), 26, 110.0)
	talk_lines = (Favors.data()[id]["lines"] as Array).duplicate()
	player.set_physics_process(false)
	talk_box.visible = true
	_advance_talk()


func _show_restoration(id: String) -> void:
	var r: Dictionary = Restorations.data()[id]
	page_title.text = r["name"]
	var action := ""
	if Restorations.has(id):
		action = Lang.t("Già restaurato.")
	elif Restorations.can_buy(id):
		action = Lang.t("Premi per restaurarlo: %d lapislazzuli.") % int(r["cost"])
	else:
		action = Lang.t("Costa %d lapislazzuli: te ne mancano %d. Li lasciano il Serpente della Porta, Am-heh e le stanze segrete.") % [int(r["cost"]), int(r["cost"]) - Meta.lapis]
	page_body.text = r["desc"] + "\n\n" + action
	page_lore.text = r["lore"]
	page_action.visible = false


## Un restauro fatto: la finestra si chiude, la Sala si oscura un istante e si riapre rinnovata.
func _on_restoration_pressed(id: String) -> void:
	if not Restorations.buy(id):
		Fx.shake(2.0)
		_fill_restorations(id)
		return
	Sfx.play("boon", 0.0)
	_close_book()
	Fx.shake(4.0)
	Fx.burst(spots["cassa"] + Vector2(0, -14), Restorations.LAPIS_COLOR, 30, 140.0)
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.015, 0.04)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.modulate.a = 0.0
	layer.add_child(veil)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(veil, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		Run.from_restore = true
		get_tree().reload_current_scene())


# ---------------------------------------------------------------- Opzioni (Esc / Start nella Sala)

## Il modulo per le opinioni dei giocatori (vuoto: la voce non compare nelle Opzioni).
const FEEDBACK_URL := ""

const OPTION_TEXT := {
	"feather": ["Piuma di Ma'at", "Una modalità per chi vuole un aiuto. Un quarto di nemici in meno nelle ondate, nemici più lenti del 10%, e subisci il 10% di danni in meno, un altro 2% a ogni morte, fino al 30%. In cambio custodisci il 40% del Ka, e lapislazzuli, cuori, premi del serdab e Lacrime valgono la metà; niente Lacrime per la prima vittoria con un'arma. Il Peso del Cuore non conta finché è attiva. La storia va avanti comunque."],
	"shake": ["Scuotimento dello schermo", "La telecamera trema quando colpisci o vieni colpito. Spegnilo se ti dà fastidio agli occhi."],
	"hitstop": ["Pausa sui colpi", "Il gioco si ferma per un istante quando un colpo va a segno: dà peso ai colpi. Spegnila se preferisci un'azione sempre fluida."],
	"autoaim": ["Mira automatica (telefono)", "Sul telefono, quando sei fermo, l'arma e l'Occhio mirano da soli al nemico più vicino. Quando ti muovi colpisci sempre nella direzione in cui vai, con un piccolo aiuto se c'è un nemico più o meno davanti. Spegnila se preferisci mirare sempre con il movimento."],
	"tutorial": ["Rifai l'addestramento", "Alla prossima discesa la prima stanza torna a essere l'addestramento di Anubi: movimento, khopesh, scatto, Occhio, Ka e porte."],
	"audio": ["Volume", "Trascina le barre. Le trovi anche nella pausa della discesa."],
	"lang": ["Lingua · Language", "La lingua del gioco. All'inizio segue quella del telefono o del computer.\nThe language of the game. At first it follows your phone or computer."],
	"update": ["Aggiorna il gioco", "Scarica l'ultima versione del gioco e la riapre. I tuoi progressi restano: non serve cancellare l'app dalla schermata Home."],
	"feedback": ["Lascia un'opinione", "Cinque domande veloci su cosa ti è piaciuto, cosa ti ha frustrato e dove sei caduto. Ogni risposta finisce davvero nel gioco: si apre una pagina nel browser."],
	"quit": ["Esci dal gioco", "Chiude il gioco. I progressi della Sala sono già salvati."],
}


func _fill_options(focus_id: String = "") -> void:
	update_label_state = Updater.check_state() + str(Updater.available())
	var left := _frame(Lang.t("Opzioni"), Lang.t("Esc / Start / B per tornare alla Sala"), 270)
	var first: Button = null
	var ids := ["feather", "shake", "hitstop", "autoaim", "tutorial", "audio", "lang"]
	if Updater.supported():
		ids.append("update")		  # solo nella versione web: l'app installata non si aggiorna da sola
	if FEEDBACK_URL != "":
		ids.append("feedback")
	if not OS.has_feature("web"):
		ids.append("quit")            # nel browser il gioco non può chiudere la pagina: si bloccava
	for id in ids:
		var label: String = Lang.t(OPTION_TEXT[id][0])
		match id:
			"feather":
				label += ":  " + (Lang.t("ATTIVA") if Meta.feather else Lang.t("spenta"))
			"shake", "hitstop", "autoaim":
				label += ":  " + (Lang.t("sì") if Meta.options.get(id, true) else Lang.t("no"))
			"tutorial":
				label += ":  " + (Lang.t("sì, alla prossima") if not Meta.tutorial_done else Lang.t("no"))
			"lang":
				label += ":  " + Lang.NAMES.get(Lang.code(), "Italiano")
			"audio":
				label += Lang.t(":  generale %d%%, musica %d%%") % [roundi(Sfx.volumes.get("generale", 1.0) * 100.0), roundi(Sfx.volumes.get("musica", 0.7) * 100.0)]
			"update":
				if Updater.available():
					label += Lang.t(":  NUOVA VERSIONE")
				elif Updater.check_state() == "ok":
					label += Lang.t(":  aggiornato")
				else:
					label += Lang.t(":  controllo...")
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
	page_title.text = Lang.t(OPTION_TEXT[id][0])
	page_body.text = Lang.t(OPTION_TEXT[id][1])
	page_lore.text = ""
	if id == "feather" and Meta.feather:
		page_lore.text = Lang.t("Ora subisci il %d%% di danni in meno.") % roundi(Run.feather_guard() * 100.0)
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
		# con tastiera e pad la barra scelta si riconosce dal nome in oro; uscendo si salva
		slider.focus_entered.connect(func() -> void: name_label.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3)))
		slider.focus_exited.connect(func() -> void:
			name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
			Meta.save())
	# Con tastiera e pad su e giù scorrono le barre in ordine di lettura. Prima la seconda colonna
	# non si raggiungeva (destra e sinistra cambiano il volume) e giù dall'ultima finiva su
	# «Esci dal gioco». Su dalla prima barra si torna alla voce Volume; giù dall'ultima si resta.
	var sliders := grid.find_children("*", "HSlider", true, false)
	for i in range(sliders.size()):
		var sl: HSlider = sliders[i]
		var up: Control = sliders[i - 1] if i > 0 else option_buttons.get("audio", sl)
		var down: Control = sliders[i + 1] if i < sliders.size() - 1 else sl
		sl.focus_neighbor_top = sl.get_path_to(up)
		sl.focus_previous = sl.focus_neighbor_top
		sl.focus_neighbor_bottom = sl.get_path_to(down)
		sl.focus_next = sl.focus_neighbor_bottom


func _on_volume_slider(value: float, category: String, pct: Label) -> void:
	Sfx.set_volume(category, value)
	pct.text = "%d%%" % roundi(value * 100.0)
	# un suono di prova della categoria, così senti subito il risultato
	for snd in Sfx.SOUNDS:
		if category == "generale" or Sfx.SOUNDS[snd][1] == category:
			Sfx.play(snd, 0.0)
			break
	if option_buttons.has("audio") and is_instance_valid(option_buttons["audio"]):
		option_buttons["audio"].text = Lang.t(OPTION_TEXT["audio"][0]) + Lang.t(":  generale %d%%, musica %d%%") % [roundi(Sfx.volumes.get("generale", 1.0) * 100.0), roundi(Sfx.volumes.get("musica", 0.7) * 100.0)]


## Le versioni, per la pagina di "Aggiorna il gioco".
func _update_status() -> String:
	var txt := Lang.t("Versione installata: %s") % Updater.label()
	match Updater.check_state():
		"ok":
			txt += Lang.t("\nUltima versione pubblicata: %s") % Updater.latest()
			txt += Lang.t("\n\nC'è una versione nuova: premi per scaricarla.") if Updater.available() else Lang.t("\n\nHai già l'ultima versione.")
		"pending":
			txt += Lang.t("\n\nSto controllando se c'è una versione nuova...")
		_:
			txt += Lang.t("\n\nNon riesco a controllare: forse il telefono non è connesso. Premi per riprovare.")
	return txt


func _on_option_pressed(id: String) -> void:
	match id:
		"feather":
			Meta.feather = not Meta.feather
		"shake", "hitstop", "autoaim":
			Meta.options[id] = not Meta.options.get(id, true)
		"tutorial":
			Meta.tutorial_done = not Meta.tutorial_done
		"lang":
			var next := "it" if Lang.is_en() else "en"
			Meta.options["lang"] = next
			Lang.apply(next)
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
		"feedback":
			OS.shell_open(FEEDBACK_URL)
			return
		"update":
			if Updater.available() and Updater.channel() == "stable":
				# su itch.io il gioco sta dentro la pagina di itch: basta ricaricarla
				page_lore.text = Lang.t("C'è una versione nuova: ricarica la pagina di itch.io (i progressi restano).")
				return
			if Updater.available():
				page_body.text = Lang.t("Aggiornamento in corso... il gioco si riapre da solo tra un momento.")
				page_lore.text = ""
				await Updater.update_now(get_tree())
				return
			# niente da scaricare: si controlla di nuovo e si mostra l'esito, senza ricaricare
			Updater.recheck()
			page_lore.text = Lang.t("Controllo in corso...")
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
	var record := Lang.t("nessuno") if Meta.best_weight < 0 else str(Meta.best_weight)
	var left := _frame(Lang.t("Il Peso del Cuore"), Lang.t("Peso totale: %d    ·    Ka a fine discesa: +%d%%    ·    Record contro Am-heh: %s") % [Weights.total(), int(round((Weights.ka_mult() - 1.0) * 100.0)), record], 250)
	var first: Button = null
	for id in Weights.ALL:
		if id == "ira_aker" and Run.max_region() < 2:
			continue                  # il peso di Aker si vede solo quando Sokar è aperta
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
	page_body.text = Lang.t("%s\n\nLivello %d di %d. Premi per cambiarlo.") % [w["desc"], Weights.rank(id), w["max"]]
	page_lore.text = Lang.t("Ogni livello di peso rende la discesa più dura e ti fa custodire il 10% di Ka in più. Anubi osserva: più pesante è il cuore che riesce a passare, più forte è chi lo porta.")


func _on_weight_pressed(id: String) -> void:
	Weights.cycle(id)
	Sfx.play("page" if Weights.rank(id) > 0 else "ui", 0.0)
	_fill_weights(id)


# ---------------------------------------------------------------- Papiri di Thoth

func _fill_papiri() -> void:
	var count := Lore.count_seen()
	var left := _frame(Lang.t("I Papiri di Thoth"), Lang.t("Tutto ciò che gli dèi ti hanno raccontato    ·    %d papiri su %d") % [count.x, count.y], 300)
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
	if Restorations.has("registro"):
		codex.append(_registro())
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


## Il registro dello scriba (restauro): le tue imprese, in quattro pagine.
func _registro() -> Dictionary:
	var names := {"mummy": Lang.t("le mummie"), "scarab": Lang.t("gli scarabei"), "priest": Lang.t("i sacerdoti di Set"), "scorpion": Lang.t("gli scorpioni"), "crocodile": Lang.t("i coccodrilli"), "jackal": Lang.t("gli sciacalli"), "vulture": Lang.t("gli avvoltoi"), "sokar_guard": Lang.t("i guardiani di Sokar"), "damned_ba": Lang.t("i Ba dannati"),
		"cobra": Lang.t("i cobra"), "serpent": Lang.t("il Serpente della Porta"), "serket": Lang.t("Serket"), "aker": Lang.t("Aker"), "aker_lion": Lang.t("i leoni di Aker"), "aker_pietra": Lang.t("le pietre di Aker"), "aker_raggio": Lang.t("il raggio dell'alba"), "amheh": Lang.t("Am-heh"), "ammit": Lang.t("Ammit"),
		"trappola": Lang.t("le trappole"), "grata": Lang.t("le grate di fuoco"), "olio": Lang.t("l'olio in fiamme"), "ureo": Lang.t("le statue dell'ureo")}
	var time_txt := Lang.t("nessuna vittoria ancora") if Meta.best_time < 0 else "%d:%02d" % [floori(Meta.best_time / 60.0), Meta.best_time % 60]
	var descents := Lang.t("Discese: %d\nVittorie su Am-heh: %d\nSerpenti della Porta battuti: %d\nIl piano più profondo: %d\nLa vittoria più rapida: %s") % [Meta.runs, Meta.ammit_wins, Meta.serpent_wins, Meta.best_room, time_txt]
	var ks := Meta.killers.keys()
	ks.sort_custom(func(x: Variant, y: Variant) -> bool: return int(Meta.killers[x]) > int(Meta.killers[y]))
	var killers_txt := ""
	for k in ks.slice(0, 6):
		var nm: String = names.get(k, k)
		killers_txt += "%s: %d\n" % [nm.substr(0, 1).to_upper() + nm.substr(1), int(Meta.killers[k])]
	if killers_txt == "":
		killers_txt = Lang.t("Nessuno ti ha ancora fermato.")
	var gs := Meta.god_picks.keys()
	gs.sort_custom(func(x: Variant, y: Variant) -> bool: return int(Meta.god_picks[x]) > int(Meta.god_picks[y]))
	var gods_txt := ""
	for g in gs:
		gods_txt += Lang.t("%s: %d doni\n") % [Boons.god_name(g), int(Meta.god_picks[g])]
	if gods_txt == "":
		gods_txt = Lang.t("Nessun dono ancora.")
	return {"title": Lang.t("Il registro dello scriba"), "entries": [
		{"title": Lang.t("Le discese"), "text": descents, "seen": true},
		{"title": Lang.t("Chi ti ha fermato"), "text": killers_txt.strip_edges(), "seen": true},
		{"title": Lang.t("Gli dèi che hai scelto"), "text": gods_txt.strip_edges(), "seen": true},
		{"title": Lang.t("I nemici abbattuti"), "text": Lang.t("In tutte le discese: %d") % Meta.total_kills, "seen": true},
	]}


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
	# porta della Casa della Vita, a est: murata finché non la apri con i lapislazzuli
	var ex := ROOM.size.x - WALL
	draw_rect(Rect2(ex, CASA_Y - 26, WALL, 52), Color(0.03, 0.02, 0.05))
	if Meta.casa:
		draw_rect(Rect2(ex + 2, CASA_Y - 24, WALL - 4, 48), Color(0.3, 0.62, 0.66, 0.18 + 0.12 * pulse))
	else:
		for by in range(4):
			for bx in range(2):
				var off := 0.0 if by % 2 == 0 else 6.0
				draw_rect(Rect2(ex + 3 + bx * 13 + off * 0.5, CASA_Y - 24 + by * 12, 12, 11), Color(0.6, 0.52, 0.42))
	draw_rect(Rect2(ex, CASA_Y - 30, 3, 60), Color(0.94, 0.72, 0.3))
	# l'ankh sopra la porta: la Casa della Vita
	var ac := Vector2(ex - 12, CASA_Y - 42)
	draw_arc(ac + Vector2(0, -4), 3.5, 0, TAU, 12, Color(0.3, 0.62, 0.66, 0.9), 1.5)
	draw_line(ac + Vector2(0, -1), ac + Vector2(0, 9), Color(0.3, 0.62, 0.66, 0.9), 1.5)
	draw_line(ac + Vector2(-5, 1), ac + Vector2(5, 1), Color(0.3, 0.62, 0.66, 0.9), 1.5)
	_draw_sphinx_door(pulse)
	_draw_cartouche(Vector2(g.x, 15.0))
	_draw_door_names()
	_draw_scale(spots["bilancia"])
	if Restorations.has("trono"):
		_draw_throne(spots["anubi"])
	_draw_anubi(spots["anubi"])
	_draw_crate(spots["cassa"])
	_draw_book(spots["libro"])
	_draw_papiri(spots["papiri"])
	if _neith_here():
		var np: Vector2 = spots["neith"]
		NeithArt.draw(self, np, t, talk_box.visible and talk_who == "neith", 1.0)    # rivolta verso il centro della Sala
	_draw_markers()


## I segni: stelline su ciò con cui si può interagire, un punto esclamativo dove c'è qualcosa di
## nuovo (Anubi ha battute nuove, un capitolo nuovo si può comprare, un ricordo da leggere).
func _draw_markers() -> void:
	if book != null or talk_box.visible:
		return
	var a: Vector2 = spots["anubi"]
	var l: Vector2 = spots["libro"]
	var s: Vector2 = spots["bilancia"]
	var pp: Vector2 = spots["papiri"]
	UiStyle.sparkle(self, a + Vector2(0, -34), 20.0, t, near == "anubi", 0.3)
	UiStyle.sparkle(self, l + Vector2(0, -16), 16.0, t, near == "libro", 1.9)
	UiStyle.sparkle(self, pp + Vector2(0, -18), 22.0, t, near == "papiri", 3.1)
	if Weights.unlocked():
		UiStyle.sparkle(self, s + Vector2(0, -22), 20.0, t, near == "bilancia", 4.4)
	UiStyle.sparkle(self, spots["cancello"] + Vector2(0, 16), 18.0, t, false, 5.2)
	if Meta.serpent_wins > 0:
		UiStyle.sparkle(self, Vector2(WALL + 6.0, ARMORY_Y), 16.0, t, near == "cortile", 2.6)
	UiStyle.sparkle(self, Vector2(ROOM.size.x - WALL - 6.0, CASA_Y), 16.0, t, near == "casa", 3.7)
	UiStyle.sparkle(self, spots["vasca"] + Vector2(0, -6), 20.0, t, near == "vasca", 8.2)
	# le novità si ricontrollano due volte al secondo, non a ogni fotogramma (la storia è lunga)
	if t >= _news_t:
		_news_t = t + 0.5
		_news = [Dialogue.has_news(not commented), Chapters.something_affordable(), Lore.unread_ricordi() > 0, Restorations.something_affordable() or Favors.something_affordable(),
			(Meta.casa and (Challenges.to_claim() > 0 or Amulets.something_to_forge())) or (not Meta.casa and Meta.lapis >= CASA_COST),
			Tales.unread() > 0]
	if _news[0]:
		UiStyle.exclaim(self, a + Vector2(0, -82), t)
	if _news[1]:
		UiStyle.exclaim(self, l + Vector2(0, -36), t)
	if _news[2]:
		UiStyle.exclaim(self, pp + Vector2(0, -46), t)
	var cs: Vector2 = spots["cassa"]
	UiStyle.sparkle(self, cs + Vector2(0, -12), 18.0, t, near == "cassa", 6.1)
	if _news[3]:
		UiStyle.exclaim(self, cs + Vector2(0, -36), t)
	if _news[4]:
		UiStyle.exclaim(self, Vector2(ROOM.size.x - WALL - 12.0, CASA_Y - 66.0), t)
	if _news[5]:
		UiStyle.exclaim(self, spots["vasca"] + Vector2(0, -34), t)
	if _neith_here():
		UiStyle.sparkle(self, spots["neith"] + Vector2(0, -40), 18.0, t, near == "neith", 7.3)
		if not Meta.neith_seen.has("arco_sala"):
			UiStyle.exclaim(self, spots["neith"] + Vector2(0, -80), t)


## Il cartiglio del faraone Akhet, sopra il cancello. Ogni boss di regione restituisce un segno del
## nome: l'ibis Am-heh, la placenta Aker, il pane Apopi (regione 3, da fare); l'orizzonte solo nel finale.
## Vedi docs/storia.md.
func _draw_cartouche(c: Vector2) -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var signs := [Meta.ammit_wins >= 1, Meta.aker_wins >= 1, false, false]     # pane: Apopi; orizzonte: il finale
	var shown := 0
	for sg in signs:
		if sg:
			shown += 1
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
		if not signs[i]:
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


## La porta della Sfinge nella parete nord: un varco con la testa di sfinge in rilievo sopra.
## Chiusa: una lastra di pietra con il lucchetto e il prezzo in lapislazzuli.
func _draw_sphinx_door(pulse: float) -> void:
	var x := SPHINX_X
	var gold := Color(0.94, 0.72, 0.3)
	draw_rect(Rect2(x - 16, WALL + 6, 32, TOP - WALL - 2), Color(0.02, 0.02, 0.05))
	if Sphinx.is_open():
		draw_rect(Rect2(x - 14, WALL + 8, 28, TOP - WALL - 4), Color(0.93, 0.78, 0.45, 0.16 + 0.12 * pulse))
	else:
		draw_rect(Rect2(x - 14, WALL + 8, 28, TOP - WALL - 4), Color(0.62, 0.55, 0.45))
		draw_line(Vector2(x - 14, WALL + 18), Vector2(x + 14, WALL + 18), Color(0.45, 0.4, 0.32), 1.0)
		_draw_padlock(Vector2(x, WALL + 20), 1.0)
		var font := UiStyle.title_font()
		var txt := str(Sphinx.COST)
		var fw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_circle(Vector2(x - fw / 2.0 - 4, TOP - 4), 2.6, Restorations.LAPIS_COLOR)
		draw_string(font, Vector2(x - fw / 2.0 + 1, TOP - 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(x - 19, WALL + 3, 38, 3), gold)
	draw_rect(Rect2(x - 19, WALL + 3, 3, TOP - WALL), gold)
	draw_rect(Rect2(x + 16, WALL + 3, 3, TOP - WALL), gold)
	# la testa della sfinge sopra il varco: nemes a righe e il volto
	var hc := Vector2(x, WALL - 5)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-9, 7), hc + Vector2(-7, -5), hc + Vector2(0, -8), hc + Vector2(7, -5), hc + Vector2(9, 7)]), Color(0.86, 0.72, 0.42))
	draw_line(hc + Vector2(-8, 0), hc + Vector2(8, 0), Color(0.22, 0.34, 0.6), 1.2)
	draw_line(hc + Vector2(-8, 4), hc + Vector2(8, 4), Color(0.22, 0.34, 0.6), 1.2)
	draw_rect(Rect2(hc.x - 4, hc.y - 3, 8, 9), Color(0.78, 0.66, 0.46))
	var eye := Color(0.98, 0.82, 0.4, 0.5 + 0.5 * pulse) if Sphinx.is_open() else Color(0.2, 0.15, 0.1)
	draw_rect(Rect2(hc.x - 3, hc.y, 2, 1), eye)
	draw_rect(Rect2(hc.x + 1, hc.y, 2, 1), eye)


## Il nome sopra ogni porta della Sala (blocco 15): oro se aperta, pietra se ancora chiusa.
func _draw_door_names() -> void:
	var font := UiStyle.title_font()
	var fs := 8 if Fx.mobile else 7
	var cx := ROOM.size.x / 2.0
	var names := [
		[Lang.t("Discesa nel Duat"), Vector2(cx, WALL + 11.0), 0, true],
		[Lang.t("La Sfinge"), Vector2(SPHINX_X, 13.0), 0, Sphinx.is_open()],
		[Lang.t("Cortile di Neith"), Vector2(WALL + 3.0, ARMORY_Y - 54.0), -1, Meta.serpent_wins > 0],
		[Lang.t("Casa della Vita"), Vector2(ROOM.size.x - WALL - 3.0, CASA_Y - 56.0), 1, Meta.casa],
	]
	for n in names:
		var txt: String = n[0]
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p: Vector2 = n[1]
		var x := p.x - w / 2.0
		if int(n[2]) < 0:
			x = p.x
		elif int(n[2]) > 0:
			x = p.x - w
		var col := Color(0.97, 0.82, 0.45) if n[3] else Color(0.66, 0.62, 0.56)
		draw_string_outline(font, Vector2(x, p.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0.04, 0.03, 0.06, 0.9))
		draw_string(font, Vector2(x, p.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Un lucchetto: arco e corpo d'oro scuro, col buco della chiave.
func _draw_padlock(c: Vector2, s: float) -> void:
	_draw_padlock_on(self, c, s)


func _draw_padlock_on(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -3) * s, 3.2 * s, PI, TAU, 10, Color(0.25, 0.2, 0.15), 2.2 * s)
	ci.draw_arc(c + Vector2(0, -3) * s, 3.2 * s, PI, TAU, 10, Color(0.85, 0.7, 0.4), 1.2 * s)
	ci.draw_rect(Rect2(c.x - 4.5 * s, c.y - 3 * s, 9 * s, 7 * s), Color(0.25, 0.2, 0.15))
	ci.draw_rect(Rect2(c.x - 3.8 * s, c.y - 2.4 * s, 7.6 * s, 5.8 * s), Color(0.85, 0.7, 0.4))
	ci.draw_circle(c + Vector2(0, 0.3) * s, 1.0 * s, Color(0.25, 0.2, 0.15))


## La bilancia di Ma'at (blocco 15): base di pietra a gradini con i geroglifi, asta d'oro con la
## piuma in cima, giogo con due piatti appesi. Su uno il cuore, sull'altro la piuma. I piatti
## oscillano piano e si inclinano con i progressi: all'inizio il cuore pesa, a ogni guardiano e boss
## battuto (e con i restauri) la bilancia va verso l'equilibrio; i Pesi del Cuore lo riappesantiscono.
## Avvicinandoti si accende una luce calda, sopra la luce di luna del cancello.
func _scale_balance() -> float:
	var k := 0.0
	if Meta.serpent_wins > 0:
		k += 0.2
	if Meta.ammit_wins > 0:
		k += 0.3
	if Meta.serket_wins > 0:
		k += 0.15
	if Meta.aker_wins > 0:
		k += 0.2
	if not Restorations.ALL.is_empty():
		k += 0.15 * clampf(Meta.restorations.size() / float(Restorations.ALL.size()), 0.0, 1.0)
	return clampf(k, 0.0, 1.0)


func _draw_scale(p: Vector2) -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var gold_d := Color(0.62, 0.42, 0.14)
	var outl := Color(0.14, 0.09, 0.05)
	if scale_glow > 0.01:
		for k in range(4):
			draw_circle(p + Vector2(0, -26), 58.0 - k * 12.0, Color(1.0, 0.7, 0.35, 0.05 * scale_glow))
	# l'ombra e la base a gradini
	draw_set_transform(p + Vector2(0, 5), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var steps := [[Rect2(p.x - 20, p.y - 2, 40, 8), Color(0.5, 0.44, 0.36)], [Rect2(p.x - 15, p.y - 7, 30, 5), Color(0.6, 0.53, 0.43)], [Rect2(p.x - 10, p.y - 11, 20, 4), Color(0.68, 0.6, 0.48)]]
	for st in steps:
		draw_rect(st[0], st[1])
		draw_rect(st[0], outl, false, 1.0)
		draw_line(st[0].position + Vector2(1, 1), st[0].position + Vector2(st[0].size.x - 1, 1), Color(1, 0.95, 0.85, 0.25), 1.0)
	# geroglifi incisi sul gradino più basso: acqua, occhio, ankh, piuma, acqua
	var gy := p.y + 2.0
	var ink := Color(0.24, 0.32, 0.55)
	draw_polyline(PackedVector2Array([Vector2(p.x - 17, gy), Vector2(p.x - 15.5, gy - 1.2), Vector2(p.x - 14, gy), Vector2(p.x - 12.5, gy - 1.2), Vector2(p.x - 11, gy)]), ink, 1.0)
	draw_arc(Vector2(p.x - 6, gy - 0.5), 1.8, PI, TAU, 6, ink, 1.0)
	draw_circle(Vector2(p.x - 6, gy - 0.3), 0.7, ink)
	draw_arc(Vector2(p.x, gy - 1.6), 1.1, 0.0, TAU, 6, ink, 0.9)
	draw_line(Vector2(p.x, gy - 0.5), Vector2(p.x, gy + 2.0), ink, 0.9)
	draw_line(Vector2(p.x - 1.4, gy - 0.2), Vector2(p.x + 1.4, gy - 0.2), ink, 0.9)
	draw_line(Vector2(p.x + 6, gy + 2), Vector2(p.x + 7, gy - 2), ink, 1.0)
	draw_polyline(PackedVector2Array([Vector2(p.x + 11, gy), Vector2(p.x + 12.5, gy - 1.2), Vector2(p.x + 14, gy), Vector2(p.x + 15.5, gy - 1.2), Vector2(p.x + 17, gy)]), ink, 1.0)
	# l'asta, con gli anelli, e la piuma di Ma'at in cima
	var pivot := Vector2(p.x, p.y - 42)
	draw_rect(Rect2(p.x - 1.8, pivot.y, 3.6, p.y - 11 - pivot.y), gold)
	draw_line(Vector2(p.x + 1.2, pivot.y + 2), Vector2(p.x + 1.2, p.y - 12), Color(1, 0.92, 0.65, 0.6), 1.0)
	for ry in [p.y - 16.0, p.y - 26.0, p.y - 36.0]:
		draw_rect(Rect2(p.x - 2.6, ry, 5.2, 1.6), gold_d)
	draw_colored_polygon(PackedVector2Array([pivot + Vector2(0, -2), pivot + Vector2(-2.2, -7), pivot + Vector2(0, -13), pivot + Vector2(2.2, -7)]), Color(0.97, 0.95, 0.88))
	draw_line(pivot + Vector2(0, -2), pivot + Vector2(0.8, -12), Color(0.7, 0.62, 0.45), 0.8)
	# il giogo: inclinato dal cuore (all'inizio pesa) e dai Pesi, oscilla piano
	var heavy := (1.0 - _scale_balance()) * 12.0 + minf(Weights.total(), 8) * 1.5
	var ang := deg_to_rad(heavy + sin(t * 0.7) * 2.2)
	var arm := Vector2(cos(ang), sin(ang)) * 23.0
	var lft := pivot + Vector2(-arm.x, arm.y)        # il cuore, più in basso quando pesa
	var rgt := pivot + Vector2(arm.x, -arm.y)
	draw_line(lft, rgt, outl, 3.4)
	draw_line(lft, rgt, gold, 2.0)
	draw_circle(pivot, 2.4, gold_d)
	for side in [-1.0, 1.0]:
		var hp: Vector2 = lft if side < 0.0 else rgt
		var swing := sin(t * 1.1 + side) * 1.0
		var bowl := hp + Vector2(swing, 13.0)
		draw_line(hp, bowl + Vector2(-6, 0), Color(gold, 0.8), 0.8)
		draw_line(hp, bowl + Vector2(6, 0), Color(gold, 0.8), 0.8)
		draw_line(hp, bowl, Color(gold, 0.6), 0.6)
		draw_colored_polygon(PackedVector2Array([bowl + Vector2(-8, 0), bowl + Vector2(8, 0), bowl + Vector2(5, 3), bowl + Vector2(-5, 3)]), gold)
		draw_line(bowl + Vector2(-8, 0), bowl + Vector2(8, 0), outl, 1.0)
		if side < 0.0:
			# il cuore (ib): un vaso rosso con le due anse
			var hc := bowl + Vector2(0, -3.5)
			draw_circle(hc + Vector2(-1.4, -0.6), 2.0, Color(0.72, 0.14, 0.12))
			draw_circle(hc + Vector2(1.4, -0.6), 2.0, Color(0.72, 0.14, 0.12))
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-3.2, -0.2), hc + Vector2(3.2, -0.2), hc + Vector2(0, 3.2)]), Color(0.72, 0.14, 0.12))
			draw_circle(hc + Vector2(-1.6, -1.2), 0.6, Color(1, 0.6, 0.55, 0.8))
		else:
			# la piuma di Ma'at, ricurva in cima
			var fb := bowl + Vector2(0, -0.5)
			var tip := fb + Vector2(2.0 + swing * 0.5, -10.0)
			draw_colored_polygon(PackedVector2Array([fb, fb + Vector2(-2.2, -5), tip, fb + Vector2(2.0, -5)]), Color(0.97, 0.95, 0.88))
			draw_line(fb, tip, Color(0.7, 0.62, 0.45), 0.8)


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


## Il trono di Anubi (restauro): schienale dorato con le piume dipinte e le zampe di leone,
## alle spalle del dio.
func _draw_throne(p: Vector2) -> void:
	var gold := Color(0.9, 0.68, 0.26)
	var gold_d := Color(0.6, 0.42, 0.14)
	var outl := Color(0.12, 0.08, 0.05)
	var back := Rect2(p.x - 17, p.y - 56, 34, 50)
	draw_rect(back.grow(1.0), outl)
	draw_rect(back, gold)
	for k in range(5):
		var x := back.position.x + 4 + k * 6.6
		draw_colored_polygon(PackedVector2Array([Vector2(x, back.position.y + 6), Vector2(x + 3, back.position.y + 2), Vector2(x + 6, back.position.y + 6), Vector2(x + 3, back.end.y - 10)]), [Color(0.16, 0.3, 0.68), Color(0.72, 0.26, 0.15), Color(0.2, 0.62, 0.62)][k % 3])
	draw_rect(Rect2(back.position.x, back.end.y - 8, back.size.x, 3), gold_d)
	for sx in [-1.0, 1.0]:
		# le zampe di leone e i braccioli
		draw_rect(Rect2(p.x + sx * 19 - 3, p.y - 22, 6, 24), outl)
		draw_rect(Rect2(p.x + sx * 19 - 2.4, p.y - 21.4, 4.8, 22.8), gold)
		draw_circle(Vector2(p.x + sx * 19, p.y + 1), 3.0, gold_d)


## La cassa dello scalpellino: legno, pietre di lapislazzuli, scalpello e mazzuolo.
func _draw_crate(p: Vector2) -> void:
	var wood := Color(0.5, 0.33, 0.16)
	var outl := Color(0.12, 0.08, 0.05)
	draw_set_transform(p + Vector2(3, 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 24.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var box := Rect2(p.x - 18, p.y - 14, 36, 16)
	draw_rect(box.grow(1.0), outl)
	draw_rect(box, wood)
	for k in range(3):
		draw_line(Vector2(box.position.x, box.position.y + 5 + k * 5), Vector2(box.end.x, box.position.y + 5 + k * 5), wood.darkened(0.3), 1.0)
	draw_rect(Rect2(box.position.x + 2, box.position.y, 3, box.size.y), wood.darkened(0.2))
	draw_rect(Rect2(box.end.x - 5, box.position.y, 3, box.size.y), wood.darkened(0.2))
	# le pietre blu che spuntano dalla cassa
	Restorations.draw_gem(self, Vector2(p.x - 7, p.y - 16), 0.9)
	Restorations.draw_gem(self, Vector2(p.x + 4, p.y - 18), 1.1)
	Restorations.draw_gem(self, Vector2(p.x + 12, p.y - 15), 0.7)
	# scalpello e mazzuolo appoggiati
	draw_line(Vector2(p.x - 24, p.y + 2), Vector2(p.x - 16, p.y - 20), outl, 2.6)
	draw_line(Vector2(p.x - 24, p.y + 2), Vector2(p.x - 16, p.y - 20), Color(0.62, 0.62, 0.66), 1.4)
	draw_rect(Rect2(p.x + 18, p.y - 6, 8, 6), wood.lightened(0.15))
	draw_line(Vector2(p.x + 22, p.y - 3), Vector2(p.x + 28, p.y + 4), Color(0.4, 0.28, 0.14), 1.6)


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
	# un ricordo nuovo da leggere: lo segnala il punto esclamativo (_draw_markers)



## Colonna papiriforme: fusto a fasci con capitello a ombrello. Passa davanti al giocatore
## quando lui ci cammina dietro.
class HubColumn extends Node2D:
	var player: Node2D

	func _ready() -> void:
		Atmos.occluder(self, Rect2(-9, -5, 18, 8))      # la colonna fa ombra

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
			if Restorations.has("stendardi"):
				draw_colored_polygon(PackedVector2Array([Vector2(x - 10, 39), Vector2(x + 10, 39), Vector2(x + 10 + sway, 90), Vector2(x + sway, 98), Vector2(x - 10 + sway, 90)]), cloth)
				# le frange d'oro in fondo
				for k in range(5):
					var fx := x - 8 + k * 4 + sway
					draw_line(Vector2(fx, 90 + absf(k - 2) * -2.0 + 6), Vector2(fx, 96 + absf(k - 2) * -2.0 + 6), Color(0.94, 0.72, 0.3), 1.0)
			else:
				# strappati: più corti, sbiaditi e sfilacciati in fondo (si restaurano con i lapislazzuli)
				cloth = cloth.darkened(0.3)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 10, 39), Vector2(x + 10, 39), Vector2(x + 9 + sway, 70), Vector2(x + 5 + sway, 76), Vector2(x + 2 + sway, 68), Vector2(x - 3 + sway, 79), Vector2(x - 6 + sway, 69), Vector2(x - 10 + sway, 74)]), cloth)
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
		var txt := Lang.t("NUOVO · Cortile di Neith")
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := pos + Vector2(-tw / 2.0, r + 14.0 * u)
		tp.x = clampf(tp.x, 6.0, vs.x - tw - 6.0)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8))
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)



## Le opere d'arte della Sala che si restaurano (restorations.gd): le pitture del giudizio sulla
## parete in alto e la vasca del Nilo. Prima del restauro si vedono rovinate (intonaco scrostato,
## una vasca secca): si capisce che lì c'è qualcosa da rimettere a posto.
class HubArt extends Node2D:
	var spots := {}
	var t := 0.0
	var ripples: Array = []              ## [posizione, età]: l'acqua toccata (Racconti dell'acqua)
	const OUTL := Color(0.12, 0.08, 0.05)

	func _process(delta: float) -> void:
		t += delta
		for r in ripples:
			r[1] += delta
		ripples = ripples.filter(func(r: Array) -> bool: return r[1] < 1.6)
		queue_redraw()                     # l'acqua, i pesci, le lampade

	func ripple(at: Vector2) -> void:
		var c: Vector2 = spots["vasca"]
		var p := Vector2(clampf(at.x, c.x - 26.0, c.x + 26.0), clampf(at.y, c.y - 6.0, c.y + 6.0))
		ripples.append([p, 0.0])
		ripples.append([p + Vector2(6, 2), -0.25])

	func _draw() -> void:
		var cx: float = spots["cancello"].x
		_panel(Rect2(cx - 102, 38, 70, 22), true)
		_panel(Rect2(cx + 32, 38, 70, 22), false)
		_pool(spots["vasca"])

	func _panel(r: Rect2, left: bool) -> void:
		if not Restorations.has("pitture"):
			# intonaco scrostato, con qualche traccia di colore e le crepe
			draw_rect(r, Color(0.5, 0.46, 0.42, 0.55))
			draw_rect(Rect2(r.position + Vector2(8, 5), Vector2(14, 10)), Color(0.35, 0.3, 0.28, 0.6))
			draw_rect(Rect2(r.position + Vector2(40, 9), Vector2(18, 8)), Color(0.42, 0.22, 0.16, 0.35))
			draw_polyline(PackedVector2Array([r.position + Vector2(20, 0), r.position + Vector2(26, 9), r.position + Vector2(22, 15), r.position + Vector2(30, 22)]), Color(0.2, 0.17, 0.15, 0.7), 1.0)
			return
		draw_rect(r.grow(1.0), OUTL)
		draw_rect(r, Color(0.93, 0.87, 0.7))
		draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), Color(0.16, 0.3, 0.68))
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), Color(0.72, 0.26, 0.15))
		var base := r.end.y - 3.0
		if left:
			# Anubi alla bilancia: il cuore su un piatto, la piuma sull'altro
			var a := r.position + Vector2(14, 0)
			draw_rect(Rect2(a.x - 2, base - 13, 4, 9), Color(0.08, 0.07, 0.1))
			draw_circle(Vector2(a.x, base - 15), 2.4, Color(0.08, 0.07, 0.1))
			draw_line(Vector2(a.x + 1, base - 16), Vector2(a.x + 4, base - 15.5), Color(0.08, 0.07, 0.1), 1.2)
			draw_line(Vector2(a.x, base - 4), Vector2(a.x - 1, base), Color(0.08, 0.07, 0.1), 1.2)
			var sc := r.position + Vector2(44, 0)
			draw_line(Vector2(sc.x, base), Vector2(sc.x, base - 15), Color(0.6, 0.42, 0.14), 1.2)
			draw_line(Vector2(sc.x - 12, base - 14), Vector2(sc.x + 12, base - 14), Color(0.6, 0.42, 0.14), 1.2)
			draw_circle(Vector2(sc.x - 12, base - 9), 2.2, Color(0.8, 0.2, 0.15))      # il cuore
			draw_line(Vector2(sc.x + 12, base - 13), Vector2(sc.x + 12, base - 6), Color(0.94, 0.85, 0.6), 1.6)   # la piuma
			draw_line(Vector2(sc.x - 12, base - 14), Vector2(sc.x - 12, base - 11), Color(0.6, 0.42, 0.14), 0.6)
			draw_line(Vector2(sc.x + 12, base - 14), Vector2(sc.x + 12, base - 13), Color(0.6, 0.42, 0.14), 0.6)
		else:
			# Thoth che scrive il verdetto, Ammit che aspetta
			var th := r.position + Vector2(18, 0)
			draw_rect(Rect2(th.x - 2, base - 12, 4, 8), Color(0.25, 0.4, 0.75))
			draw_circle(Vector2(th.x, base - 14), 2.2, Color(0.95, 0.95, 0.92))
			draw_line(Vector2(th.x + 1, base - 14), Vector2(th.x + 6, base - 11), Color(0.15, 0.12, 0.1), 1.0)   # il becco dell'ibis
			draw_rect(Rect2(th.x + 4, base - 9, 4, 3), Color(0.82, 0.68, 0.42))                            # la tavolozza
			var am := r.position + Vector2(50, 0)
			draw_colored_polygon(PackedVector2Array([Vector2(am.x - 9, base - 1), Vector2(am.x - 8, base - 8), Vector2(am.x + 2, base - 9), Vector2(am.x + 10, base - 8), Vector2(am.x + 10, base - 6), Vector2(am.x + 3, base - 5), Vector2(am.x + 3, base - 1)]), Color(0.3, 0.45, 0.25))
			draw_circle(Vector2(am.x - 3, base - 7), 3.2, Color(0.82, 0.6, 0.28))

	## La vasca del Nilo (blocco 15): incassata nel pavimento, con il bordo di pietra scolpito a
	## fiori di loto, l'acqua che ondeggia piano con il riflesso della luna, foglie e fiori di loto,
	## ciuffi di papiro agli angoli, due lampade ai lati; ogni tanto passa un pesce o si apre un
	## cerchio sull'acqua. Prima del restauro è secca: fango crepato e papiri appassiti.
	func _pool(c: Vector2) -> void:
		var full := Restorations.has("vasca")
		var outer := Rect2(c - Vector2(40, 16), Vector2(80, 32))
		draw_rect(Rect2(outer.position + Vector2(2, 3), outer.size), Color(0, 0, 0, 0.28))
		# il bordo di pietra
		draw_rect(outer, Color(0.62, 0.54, 0.42))
		draw_rect(outer, OUTL, false, 1.0)
		draw_line(outer.position + Vector2(1, 1), Vector2(outer.end.x - 1, outer.position.y + 1), Color(1, 0.95, 0.85, 0.3), 1.0)
		# lo scolpito: piccoli fiori di loto a ventaglio sul bordo alto e basso
		for i in range(7):
			var x := outer.position.x + 8.0 + i * 10.7
			for yy in [outer.position.y + 2.6, outer.end.y - 2.4]:
				var lc := Vector2(x, yy)
				draw_line(lc + Vector2(-1.6, 0.8), lc + Vector2(0, -0.9), Color(0.4, 0.33, 0.24), 0.9)
				draw_line(lc + Vector2(1.6, 0.8), lc + Vector2(0, -0.9), Color(0.4, 0.33, 0.24), 0.9)
				draw_line(lc + Vector2(0, 0.9), lc + Vector2(0, -1.2), Color(0.4, 0.33, 0.24), 0.9)
		# il gradino interno: la vasca è più bassa del pavimento
		var step := outer.grow(-5.0)
		draw_rect(step, Color(0.42, 0.36, 0.27))
		var water := Rect2(step.position + Vector2(2, 2), step.size - Vector2(4, 3))
		for lx in [outer.position.x - 9.0, outer.end.x + 9.0]:
			_lamp(Vector2(lx, c.y + 4.0), full)
		if not full:
			# secca: fango crepato e papiri appassiti
			draw_rect(water, Color(0.36, 0.28, 0.2))
			var crack := Color(0.2, 0.15, 0.1)
			draw_polyline(PackedVector2Array([c + Vector2(-24, -2), c + Vector2(-10, 2), c + Vector2(0, -3), c + Vector2(14, 3), c + Vector2(26, -1)]), crack, 1.0)
			draw_polyline(PackedVector2Array([c + Vector2(-10, 2), c + Vector2(-6, 6)]), crack, 1.0)
			draw_polyline(PackedVector2Array([c + Vector2(14, 3), c + Vector2(12, -5)]), crack, 1.0)
			_papyrus(outer.position + Vector2(-2, 2), false)
			_papyrus(Vector2(outer.end.x + 2, outer.position.y + 2), false)
			return
		# l'acqua: più scura sotto il bordo, onde lente
		draw_rect(water, Color(0.1, 0.3, 0.44))
		draw_rect(Rect2(water.position, Vector2(water.size.x, 3)), Color(0.04, 0.15, 0.26, 0.85))
		draw_rect(Rect2(water.position.x, water.position.y, 2, water.size.y), Color(0.04, 0.15, 0.26, 0.5))
		for k in range(3):
			var yy := water.position.y + 6.0 + k * 5.0
			var pts := PackedVector2Array()
			var x := water.position.x + 2.0
			while x <= water.end.x - 2.0:
				pts.append(Vector2(x, yy + sin(x * 0.22 + t * 1.1 + k * 1.7) * 0.8))
				x += 4.0
			draw_polyline(pts, Color(0.55, 0.82, 0.95, 0.18), 1.0)
		# il riflesso della luna: tratti chiari che si spezzano con l'acqua
		var moon := Vector2(c.x + 10.0, c.y - 1.0)
		for k in range(4):
			var mw := 9.0 - k * 1.8 + sin(t * 1.7 + k * 1.3) * 1.6
			var my := moon.y - 3.0 + k * 2.4
			draw_line(Vector2(moon.x - mw / 2.0 + sin(t + k) * 0.8, my), Vector2(moon.x + mw / 2.0 + sin(t + k) * 0.8, my), Color(0.88, 0.94, 1.0, 0.55 - k * 0.1), 1.2)
		# un pesce, ogni tanto: un'ombra arancione che attraversa la vasca sott'acqua
		var cyc := fmod(t, 9.0)
		if cyc < 3.2:
			var u := cyc / 3.2
			var fp := Vector2(lerpf(water.position.x + 4.0, water.end.x - 4.0, u), water.position.y + 9.0 + sin(u * 6.0) * 2.0)
			var fa := sin(u * PI) * 0.7
			draw_set_transform(fp, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, 2.6, Color(0.95, 0.5, 0.2, fa))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([fp + Vector2(-2, 0), fp + Vector2(-5, -1.6 + sin(t * 12.0)), fp + Vector2(-5, 1.6 + sin(t * 12.0))]), Color(0.95, 0.5, 0.2, fa))
		# un cerchio che si apre da solo ogni tanto (una goccia, un insetto)
		var rc := fmod(t + 4.5, 6.0)
		if rc < 1.4:
			var rp := Vector2(c.x - 14.0 + fmod(floorf((t + 4.5) / 6.0) * 17.0, 30.0), c.y + 2.0)
			_ring(rp, rc)
		for r in ripples:
			if r[1] >= 0.0:
				_ring(r[0], r[1])
		# foglie di loto (con la tacca) e fiori
		for lp in [Vector2(-22, 3), Vector2(-14, -4), Vector2(18, 4), Vector2(25, -3)]:
			var bob := sin(t * 0.9 + lp.x) * 0.5
			var q: Vector2 = c + lp + Vector2(0, bob)
			draw_set_transform(q, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, 4.6, Color(0.18, 0.46, 0.26))
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(4.8, -1.4), Vector2(4.8, 1.4)]), Color(0.1, 0.3, 0.44))
			draw_arc(Vector2.ZERO, 3.2, 0.4, 5.9, 10, Color(0.3, 0.6, 0.34, 0.6), 0.6)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for fp2 in [Vector2(-20, 1), Vector2(20, 2)]:
			var f: Vector2 = c + fp2 + Vector2(0, sin(t * 0.9 + fp2.x) * 0.5)
			draw_colored_polygon(PackedVector2Array([f + Vector2(-3.4, 0), f + Vector2(-2.2, -4), f + Vector2(-0.6, -1.2), f + Vector2(0, -5), f + Vector2(0.6, -1.2), f + Vector2(2.2, -4), f + Vector2(3.4, 0)]), Color(0.97, 0.8, 0.88))
			draw_circle(f + Vector2(0, -0.6), 0.9, Color(0.98, 0.85, 0.35))
		_papyrus(outer.position + Vector2(-2, 2), true)
		_papyrus(Vector2(outer.end.x + 2, outer.position.y + 2), true)
		_papyrus(Vector2(outer.end.x - 4, outer.end.y + 1), true)

	func _ring(p: Vector2, age: float) -> void:
		var k := clampf(age / 1.4, 0.0, 1.0)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 2.0 + k * 11.0, 0.0, TAU, 20, Color(0.75, 0.92, 1.0, 0.55 * (1.0 - k)), 1.0)
		if k > 0.25:
			draw_arc(Vector2.ZERO, k * 7.0, 0.0, TAU, 16, Color(0.75, 0.92, 1.0, 0.35 * (1.0 - k)), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## Un ciuffo di papiro: steli verdi con l'ombrella a ventaglio (o secco, prima del restauro).
	func _papyrus(base: Vector2, alive: bool) -> void:
		var stem := Color(0.3, 0.55, 0.26) if alive else Color(0.5, 0.44, 0.28)
		var head := Color(0.45, 0.68, 0.3) if alive else Color(0.58, 0.5, 0.32)
		for k in range(3):
			var lean := (k - 1) * 3.0 + sin(t * 0.8 + base.x + k) * (0.8 if alive else 0.0)
			var h := 15.0 + k * 3.0 if alive else 9.0 + k * 2.0
			var top := base + Vector2(lean, -h)
			draw_line(base + Vector2((k - 1) * 1.2, 0), top, stem, 1.0)
			if alive:
				for f in range(5):
					var a := -PI / 2.0 + (f - 2) * 0.35
					draw_line(top, top + Vector2.from_angle(a) * 4.0, head, 1.0)
			else:
				draw_line(top, top + Vector2(2.5, 2.5), head, 1.0)

	## Una lampada a olio su un piedistallo di bronzo, con la fiamma che trema (spenta se secca).
	func _lamp(p: Vector2, lit: bool) -> void:
		var bronze := Color(0.55, 0.38, 0.18)
		draw_rect(Rect2(p.x - 3, p.y - 1, 6, 2), bronze.darkened(0.3))
		draw_line(p, p + Vector2(0, -12), bronze, 1.6)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -12), p + Vector2(4, -12), p + Vector2(2.5, -9.5), p + Vector2(-2.5, -9.5)]), bronze)
		if not lit:
			return
		var fl := sin(t * 11.0 + p.x) * 0.6 + sin(t * 7.3) * 0.4
		for k in range(3):
			draw_circle(p + Vector2(0, -15), 9.0 - k * 2.8, Color(1.0, 0.65, 0.3, 0.06 + 0.02 * k))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-1.6, -12.5), p + Vector2(1.6, -12.5), p + Vector2(fl * 0.6, -17.5 - absf(fl))]), Color(1.0, 0.72, 0.3))
		draw_circle(p + Vector2(0, -13.4), 0.9, Color(1.0, 0.95, 0.7))


## Il gatto di Bastet (restauro, ridisegnato nel blocco 15): un gatto nero lucido senza pelo, alla
## maniera delle statuette di Bastet: orecchie grandi, corpo magro, coda lunga e sottile, collare
## d'oro con lo scarabeo e un piccolo orecchino. Ti segue da lontano, si siede quando ti fermi, e si
## lascia accarezzare. Il riflesso sulla pelle (una linea chiara) dice che è lucido, non peloso.
class HubCat extends Node2D:
	var player: Node2D
	var t := 0.0
	var walk := 0.0
	var moving := false
	var face := 1.0
	var happy := 0.0

	func _process(delta: float) -> void:
		t += delta
		happy = maxf(0.0, happy - delta)
		moving = false
		if player != null and is_instance_valid(player):
			var to := player.global_position + Vector2(-30.0 * face, 8) - position
			if to.length() > 42.0:
				moving = true
				position += to.normalized() * 72.0 * delta
				walk += delta * 12.0
				if absf(to.x) > 4.0:
					face = signf(to.x)
		queue_redraw()

	func pet() -> void:
		happy = 1.6
		Sfx.play("ui", 0.0)
		Fx.float_text(global_position + Vector2(0, -18), Lang.t("Mrrr..."), Color(1.0, 0.8, 0.9), 10)
		Fx.burst(global_position + Vector2(0, -12), Color(1.0, 0.55, 0.7), 8, 40.0)

	func _draw() -> void:
		var skin := Color(0.07, 0.065, 0.09)
		var shine := Color(0.5, 0.48, 0.62, 0.75)       # il riflesso sulla pelle nuda e lucida
		var gold := Color(0.95, 0.75, 0.3)
		var scarab := Color(0.16, 0.58, 0.62)
		var eye_c := Color(0.72, 0.9, 0.35)
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
		if moving:
			var w := sin(walk)
			# zampe lunghe e sottili
			for lp in [[-6.0, w], [-3.5, -w], [4.5, -w], [7.0, w]]:
				var lx: float = lp[0]
				var sw: float = lp[1]
				draw_line(Vector2(lx, -7), Vector2(lx + sw * 1.6, 0), skin, 1.3)
			# corpo magro, la schiena un po' arcuata, la pancia rientrante
			var body := PackedVector2Array([Vector2(-8, -7), Vector2(-6, -10.5), Vector2(1, -10), Vector2(6, -11), Vector2(8.5, -8.5), Vector2(6, -6.2), Vector2(0, -6.6), Vector2(-6, -5.8)])
			draw_colored_polygon(body, skin)
			draw_polyline(PackedVector2Array([Vector2(-6, -10.2), Vector2(1, -9.7), Vector2(5.5, -10.6)]), shine, 0.8)
			# coda lunga e sottile, alta e ricurva in punta
			draw_polyline(PackedVector2Array([Vector2(-8, -8), Vector2(-12, -11), Vector2(-14, -15 + w * 0.6), Vector2(-13, -18 + w), Vector2(-11, -18.5 + w)]), skin, 1.1)
			_head(Vector2(9.5, -13.5), skin, shine, gold, scarab, eye_c)
		else:
			# seduto, come le statuette di Bastet: dritto, magro, le zampe davanti unite
			draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(3, 0), Vector2(3.5, -6), Vector2(2.5, -12), Vector2(0, -15), Vector2(-2.5, -13), Vector2(-5, -7)]), skin)
			draw_line(Vector2(2.0, -9), Vector2(2.4, 0), skin, 1.5)
			draw_line(Vector2(3.4, -9), Vector2(3.8, 0), skin, 1.4)
			draw_polyline(PackedVector2Array([Vector2(-3.5, -11), Vector2(-4.6, -6), Vector2(-4.4, -2)]), shine, 0.8)
			# la coda lunga che gira davanti alle zampe
			draw_polyline(PackedVector2Array([Vector2(-5.5, -0.5), Vector2(-8, -1), Vector2(-8.5, 0.8), Vector2(-4, 1.6), Vector2(2, 1.4), Vector2(5.5, 0.6)]), skin, 1.1)
			_head(Vector2(1.0, -18.0), skin, shine, gold, scarab, eye_c)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if happy > 0.0:
			var hp := Vector2(0, -30 - (1.6 - happy) * 8.0)
			draw_circle(hp + Vector2(-1.5, 0), 1.6, Color(1.0, 0.5, 0.65, happy / 1.6))
			draw_circle(hp + Vector2(1.5, 0), 1.6, Color(1.0, 0.5, 0.65, happy / 1.6))
			draw_colored_polygon(PackedVector2Array([hp + Vector2(-3, 0.5), hp + Vector2(3, 0.5), hp + Vector2(0, 3.5)]), Color(1.0, 0.5, 0.65, happy / 1.6))

	## La testa: a cuneo, con le orecchie grandi (l'interno appena più chiaro), gli occhi a mandorla
	## verde-oro (socchiusi quando lo accarezzi), il collare d'oro con lo scarabeo e l'orecchino.
	func _head(hc: Vector2, skin: Color, shine: Color, gold: Color, scarab: Color, eye_c: Color) -> void:
		# il collo e il collare con lo scarabeo
		draw_line(hc + Vector2(-1.5, 2), hc + Vector2(-2.5, 6), skin, 3.0)
		draw_line(hc + Vector2(-4.2, 4.6), hc + Vector2(0.6, 3.6), gold, 1.4)
		draw_circle(hc + Vector2(-1.4, 5.0), 1.2, scarab)
		draw_circle(hc + Vector2(-1.4, 5.0), 0.5, gold)
		# la testa a cuneo
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-3, -2.5), hc + Vector2(2, -3), hc + Vector2(4.5, 0), hc + Vector2(2.8, 2.2), hc + Vector2(-2.2, 2.4), hc + Vector2(-3.6, 0)]), skin)
		# orecchie grandi, dritte
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-3.2, -1.8), hc + Vector2(-4.4, -9.5), hc + Vector2(-0.6, -2.8)]), skin)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(0.2, -2.9), hc + Vector2(2.6, -10.0), hc + Vector2(3.4, -1.8)]), skin)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-2.9, -2.6), hc + Vector2(-3.8, -7.6), hc + Vector2(-1.4, -3.0)]), Color(0.32, 0.2, 0.26))
		draw_colored_polygon(PackedVector2Array([hc + Vector2(1.0, -3.0), hc + Vector2(2.5, -8.2), hc + Vector2(2.9, -2.4)]), Color(0.32, 0.2, 0.26))
		draw_line(hc + Vector2(-2.4, -2.6), hc + Vector2(1.6, -2.9), shine, 0.7)       # il riflesso sulla fronte
		# l'orecchino d'oro all'orecchio sinistro
		draw_arc(hc + Vector2(-3.9, -3.6), 0.9, 0.0, TAU, 8, gold, 0.7)
		if happy <= 0.0:
			draw_colored_polygon(PackedVector2Array([hc + Vector2(0.6, -0.6), hc + Vector2(1.8, -1.2), hc + Vector2(3.0, -0.6), hc + Vector2(1.8, 0.0)]), eye_c)
			draw_line(hc + Vector2(1.8, -1.0), hc + Vector2(1.8, -0.2), Color(0.05, 0.05, 0.05), 0.6)
		else:
			draw_arc(hc + Vector2(1.8, -0.2), 1.0, PI, TAU, 5, eye_c, 0.7)          # occhi socchiusi
		draw_circle(hc + Vector2(4.2, 0.6), 0.5, Color(0.3, 0.2, 0.25))             # il naso


## Il regalo del gatto: una moneta di Ka con l'impronta di una zampa, davanti al cancello.
class CatGift extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		var p = get_tree().get_first_node_in_group("player")
		if p != null and p.global_position.distance_to(global_position) < 16.0:
			Meta.ka_bank += 5
			Meta.save()
			Sfx.play("pickup", 0.0)
			Fx.float_text(global_position + Vector2(0, -16), Lang.t("Il gatto ti ha portato 5 Ka"), Color(0.94, 0.72, 0.3), 10)
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var bob := sin(t * 3.0) * 1.0
		draw_circle(Vector2(0, -3 + bob), 7.0, Color(1.0, 0.8, 0.35, 0.18))
		draw_circle(Vector2(0, -3 + bob), 3.6, Color(0.96, 0.76, 0.3))
		draw_circle(Vector2(0, -2.4 + bob), 1.1, Color(0.6, 0.42, 0.14))
		for k in range(3):
			draw_circle(Vector2(-1.6 + k * 1.6, -4.8 + bob), 0.55, Color(0.6, 0.42, 0.14))


## Le frecce a terra verso le porte principali (blocco 15): discesa (la più evidente), Casa della
## Vita, Cortile di Neith, Sfinge. Chevron che scivolano piano verso la porta; per le porte ancora
## chiuse sono di pietra, con il lucchetto e il prezzo. Spariscono dopo il primo passaggio dalla porta
## (Meta.doors_used), a meno che nelle Opzioni «Mostra le frecce» sia acceso. Sul telefono più grandi
## e con il contorno chiaro. Stanno a terra: i personaggi ci passano sopra.
class HubDoorArrows extends Node2D:
	var hub
	var t := 0.0

	func _ready() -> void:
		z_index = 0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _door_list() -> Array:
		var cx: float = hub.ROOM.size.x / 2.0
		var top: float = hub.TOP
		var wall: float = hub.WALL
		var rw: float = hub.ROOM.size.x
		# id, inizio, fine, aperta, prezzo (lapislazzuli; -1 = condizione), evidente
		return [
			["cancello", Vector2(cx, 152.0), Vector2(cx, top + 16.0), true, 0, true],
			["cancello", Vector2(cx, 330.0), Vector2(cx, 236.0), true, 0, true],
			["sfinge", Vector2(hub.SPHINX_X, 138.0), Vector2(hub.SPHINX_X, top + 18.0), Sphinx.is_open(), Sphinx.COST, false],
			["cortile", Vector2(wall + 110.0, hub.ARMORY_Y), Vector2(wall + 16.0, hub.ARMORY_Y), Meta.serpent_wins > 0, -1, false],
			["casa", Vector2(rw - wall - 110.0, hub.CASA_Y), Vector2(rw - wall - 16.0, hub.CASA_Y), Meta.casa, hub.CASA_COST, false],
		]

	func _draw() -> void:
		var always: bool = Meta.options.get("arrows", false)
		var big := 1.45 if Fx.mobile else 1.0
		for d in _door_list():
			if not always and Meta.doors_used.has(d[0]):
				continue
			var from: Vector2 = d[1]
			var to: Vector2 = d[2]
			var open: bool = d[3]
			var strong: bool = d[5]
			var dir := (to - from).normalized()
			var length := from.distance_to(to)
			var step := 26.0 * big
			var n := maxi(2, floori(length / step))
			var s := (7.0 if strong else 5.5) * big
			var base := Color(1.0, 0.82, 0.38) if open else Color(0.62, 0.6, 0.58)
			var flow := fmod(t * 9.0, step)             # piano: scivolano di 9 pixel al secondo
			for i in range(n):
				var dist := i * step + flow
				if dist > length:
					continue
				var p := from + dir * dist
				# si accendono avvicinandosi alla porta e sfumano alle estremità
				var k := dist / length
				var a := clampf(minf(dist, length - dist) / (step * 0.9), 0.0, 1.0) * (0.35 + 0.45 * k)
				if strong:
					a = minf(1.0, a * 1.3)
				_chevron(p, dir, s, Color(base, a), open, big)
			if not open:
				_lock(to - dir * 22.0 * big + Vector2(0, -6) * big, int(d[4]), big)

	func _chevron(p: Vector2, dir: Vector2, s: float, col: Color, open: bool, big: float) -> void:
		var side := dir.orthogonal()
		var tip := p + dir * s
		var l := p - dir * s * 0.2 + side * s
		var r := p - dir * s * 0.2 - side * s
		var mid := p + dir * s * 0.25
		var pts := PackedVector2Array([l, tip, r, mid])
		if Fx.mobile or big > 1.0:
			# sul telefono: contorno chiaro, si vedono anche sul pavimento scuro
			draw_polyline(PackedVector2Array([l, tip, r]), Color(1, 0.97, 0.88, col.a * 0.8), 5.0 * big)
		draw_colored_polygon(pts, col if open else Color(col, col.a * 0.9))
		if not open:
			draw_line(l.lerp(tip, 0.5), r.lerp(tip, 0.5), Color(0.35, 0.33, 0.3, col.a), 1.0)   # crepa: è di pietra

	func _lock(c: Vector2, price: int, big: float) -> void:
		var bob := sin(t * 2.0) * 1.2
		c.y += bob
		var font := UiStyle.title_font()
		var fs := roundi(7.0 * big)
		var txt := Lang.t("batti il Serpente") if price < 0 else str(price)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var w := 14.0 * big + tw + (6.0 * big if price > 0 else 0.0)
		var r := Rect2(c.x - w / 2.0, c.y - 7.0 * big, w, 14.0 * big)
		draw_rect(r, Color(0.06, 0.05, 0.08, 0.78))
		draw_rect(r, Color(1, 0.97, 0.88, 0.7) if Fx.mobile else Color(0.62, 0.6, 0.58, 0.8), false, 1.0)
		hub._draw_padlock_on(self, Vector2(r.position.x + 7.0 * big, c.y + 1.0 * big), 0.85 * big)
		var x := r.position.x + 13.0 * big
		if price > 0:
			draw_circle(Vector2(x + 2.5 * big, c.y), 2.4 * big, Restorations.LAPIS_COLOR)
			x += 6.0 * big
		draw_string(font, Vector2(x, c.y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.92, 0.85))
