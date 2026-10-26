extends Node2D
## Il Cortile di Neith: dove si scelgono e si provano le armi. Si apre dalla Sala del Giudizio
## dopo la prima vittoria sul Serpente della Porta.
## - Neith, la dea guerriera di Sais: ti consegna la lancia e commenta le tue armi.
## - I piedistalli: le armi come offerte votive; quelle non ancora forgiate restano coperte.
## - L'altare: con le Lacrime di Iside risvegli gli aspetti delle armi e li potenzi.
## - Gli ushabti: statuine d'argilla da colpire, che si ricompongono da sole.
## - La stele: misura l'ultimo colpo, la combinazione e i danni al secondo.
## - La porta delle prove: fa uscire i nemici che vuoi, per provare l'arma senza rischi.

const CourtyardScript := preload("res://scripts/courtyard.gd")
const ROOM := Rect2(0, 0, 640, 380)
const WALL := 32.0
const TOP := 64.0
const PlayerScene := preload("res://scenes/player.tscn")
const DummyScript := preload("res://scripts/dummy.gd")
const ENEMIES := {
	"mummy": preload("res://scenes/mummy.tscn"),
	"scarab": preload("res://scenes/scarab.tscn"),
	"priest": preload("res://scenes/priest.tscn"),
	"scorpion": preload("res://scenes/scorpion.tscn"),
	"cobra": preload("res://scenes/cobra.tscn"),
}
const TRIALS := [
	{"name": "Sciame di scarabei", "list": ["scarab", "scarab", "scarab", "scarab", "scarab", "scarab"]},
	{"name": "Due mummie", "list": ["mummy", "mummy"]},
	{"name": "Un sacerdote", "list": ["priest"]},
	{"name": "Scorpioni di Serket", "list": ["scorpion", "scorpion"]},
	{"name": "Un cobra", "list": ["cobra"]},
	{"name": "Tutti insieme", "list": ["mummy", "priest", "scarab", "scarab", "scarab", "scorpion"]},
]
const NEITH_COLOR := Color(0.86, 0.32, 0.26)
const GOLD := Color(0.94, 0.72, 0.3)

var is_armory := true                  # i comandi touch mostrano anche il pulsante Azione
var player
var spots := {}
var pedestals: Array = []              # [{id, name, pos}] — id "" = arma non ancora forgiata
var near := ""
var t := 0.0
var menu: CanvasLayer = null
var talk_lines: Array = []
var _news := false                      ## Neith ha battute nuove (_draw)
var _altar_news := false                ## con le Lacrime puoi risvegliare o potenziare qualcosa
var _news_t := 0.0
var last_dealt := 0.0
var hits: Array = []                   # [tempo, danni] degli ultimi secondi
var last_hit := 0.0
var combo_dmg := 0.0
var combo_t := -9.0
var trial_enemies: Array = []

@onready var world: Node2D = $World
@onready var hud: Label = $UI/Hud
@onready var prompt: Label = $UI/Prompt
@onready var help: Label = $UI/Help
@onready var talk_box: PanelContainer = $UI/Talk
@onready var talk_name: Label = $UI/Talk/Box/Name
@onready var talk_text: Label = $UI/Talk/Box/Text


func _ready() -> void:
	# niente bordi scuri: il Cortile è a cielo aperto e si fanno le prove, bisogna vedere bene
	Engine.time_scale = 1.0
	get_tree().paused = false
	Run.in_hub = false
	Run.training = true
	Music.play("hub")
	Run.new_run()
	Fx.world = world
	# l'interpolazione fisica (project.godot) solo per chi si muove a ogni passo della fisica:
	# eroe e nemici (vedi i loro _ready). Il resto (scintille, numeri, proiettili) no.
	world.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	spots = {
		"neith": Vector2(104, 186),
		# al centro, sotto le armi: l'altare dove le potenzi sta con loro, e ci passi davanti
		# ogni volta che entri (prima era in un angolo e sembrava un pezzo d'arredo)
		"altare": Vector2(369, 158),
		"prove": Vector2(330, ROOM.size.y - WALL),
		"stele": Vector2(566, 300),
	}
	var ids := Weapons.ALL.keys()
	for i in range(6):
		var pos := Vector2(214 + i * 62, TOP + 34)
		if i < ids.size():
			pedestals.append({"id": ids[i], "name": Weapons.ALL[ids[i]]["name"], "pos": pos})
		else:
			pedestals.append({"id": "", "name": Weapons.FUTURE[i - ids.size()]["name"], "pos": pos})
	_build()
	Fx.scale_labels($UI)
	talk_box.visible = false
	UiStyle.talk_style(talk_box, talk_name, talk_text, NEITH_COLOR)
	last_dealt = Run.damage_dealt
	if not Meta.weapons_unlocked.has("lancia"):
		_start_talk()


func _exit_tree() -> void:
	Run.training = false


func _build() -> void:
	_solid(Rect2(0, 0, ROOM.size.x, TOP))
	_solid(Rect2(0, ROOM.size.y - WALL, ROOM.size.x, WALL))
	_solid(Rect2(0, 0, WALL, ROOM.size.y))
	_solid(Rect2(ROOM.size.x - WALL, 0, WALL, 180))
	_solid(Rect2(ROOM.size.x - WALL, 240, WALL, ROOM.size.y - 240))
	_solid(Rect2(spots["neith"] - Vector2(16, 6), Vector2(32, 10)))
	_solid(Rect2(spots["altare"] - Vector2(22, 8), Vector2(44, 14)))
	_solid(Rect2(spots["stele"] - Vector2(12, 6), Vector2(24, 10)))
	for p in pedestals:
		_solid(Rect2(p["pos"] - Vector2(12, 4), Vector2(24, 10)))
	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x - 70.0, 210.0)
	world.add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM.size.x)
	cam.limit_bottom = int(ROOM.size.y)
	cam.reset_smoothing()
	# il cortile a cielo aperto (scripts/courtyard.gd): disegnato sotto a tutto ciò che disegna
	# questo nodo (piedistalli, Neith, altare), con colonne, palme e tetto nel mondo
	var court := CourtyardScript.new()
	court.room = ROOM
	court.top = TOP
	court.wall = WALL
	court.show_behind_parent = true
	court.shadows = [[spots["neith"] + Vector2(0, 2), 8.0, 60.0], [spots["altare"] + Vector2(0, 6), 24.0, 22.0], [spots["stele"] + Vector2(0, 4), 22.0, 52.0]]
	add_child(court)
	move_child(court, 0)
	for r in court.build(world, player):
		_solid(r)
	for pos in [Vector2(372, 238), Vector2(436, 226), Vector2(500, 246)]:
		_spawn_target(pos)


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


# ---------------------------------------------------------------- bersagli e stele

func _spawn_target(pos: Vector2) -> void:
	var d: Enemy = DummyScript.new()
	d.ushabti = true
	d.position = pos
	world.add_child(d)
	d.killed.connect(func(_e) -> void:
		# l'ushabti si ricompone poco dopo: "Eccomi!"
		get_tree().create_timer(1.3).timeout.connect(func() -> void:
			if is_inside_tree():
				Fx.burst(pos + Vector2(0, -12), Color(0.3, 0.68, 0.72), 16, 70.0)
				Fx.float_text(pos + Vector2(0, -30), Lang.t("Eccomi!"), Color(0.6, 0.9, 0.9))
				_spawn_target(pos)))


func _measure() -> void:
	var d := Run.damage_dealt - last_dealt
	last_dealt = Run.damage_dealt
	if d <= 0.0:
		return
	hits.append([t, d])
	last_hit = d
	if t - combo_t > 1.0:
		combo_dmg = 0.0
	combo_dmg += d
	combo_t = t


func _dps() -> float:
	hits = hits.filter(func(h: Array) -> bool: return t - float(h[0]) <= 3.0)
	var s := 0.0
	for h in hits:
		s += float(h[1])
	return s / 3.0


# ---------------------------------------------------------------- ogni frame

func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if player == null:
		return
	_measure()
	var w: Dictionary = Weapons.ALL[Run.weapon]
	hud.text = Lang.t("Cortile di Neith    Arma: %s · %s    Lacrime di Iside: %d") % [w["name"], w["aspects"][Run.aspect]["name"], Meta.tears]
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = Lang.t("Levetta muovi · X attacca · LB/A scatto · Y interagisci · B chiudi")
	else:
		help.text = Lang.t("WASD muovi · clic attacca · Spazio scatto · clic destro Occhio · E interagisci")
	trial_enemies = trial_enemies.filter(func(e) -> bool: return is_instance_valid(e) and not e.dead)
	if talk_box.visible or menu != null:
		prompt.visible = false
		return
	# l'uscita a est riporta nella Sala del Giudizio
	if player.global_position.x > ROOM.size.x - WALL - 12.0 and absf(player.global_position.y - 210.0) < 26.0:
		_leave()
		return
	near = ""
	var best := 34.0
	for k in ["neith", "altare", "prove", "stele"]:
		var dd: float = player.global_position.distance_to(spots[k])
		if dd < best:
			best = dd
			near = k
	for i in range(pedestals.size()):
		var dd: float = player.global_position.distance_to(pedestals[i]["pos"] + Vector2(0, 14))
		if dd < best:
			best = dd
			near = "ped%d" % i
	var key := "Y" if Fx.device == "pad" else (Lang.t("AZIONE") if Fx.device == "touch" else "E")
	match near:
		"neith":
			prompt.text = Lang.t("%s · Parla con Neith") % key
		"altare":
			prompt.text = Lang.t("%s · L'altare degli aspetti (Lacrime di Iside: %d)") % [key, Meta.tears]
		"prove":
			prompt.text = Lang.t("%s · La porta delle prove") % key if trial_enemies.is_empty() else Lang.t("%s · La porta delle prove (nemici in campo: %d)") % [key, trial_enemies.size()]
		"stele":
			prompt.text = Lang.t("La stele misura i tuoi colpi sugli ushabti e sui nemici delle prove")
		"":
			prompt.text = ""
		_:
			var p: Dictionary = pedestals[int(near.substr(3))]
			if p["id"] == "":
				prompt.text = Lang.t("%s · arma non ancora forgiata") % p["name"]
			elif not Weapons.is_unlocked(p["id"]):
				prompt.text = Lang.t("%s · parla con Neith") % p["name"]
			elif Run.weapon == p["id"]:
				prompt.text = Lang.t("%s · è l'arma che impugni") % p["name"]
			else:
				prompt.text = Lang.t("%s · Prendi: %s") % [key, p["name"]]
	prompt.visible = prompt.text != ""


func _physics_process(_delta: float) -> void:
	# nel cortile non si muore: le prove servono a imparare
	if player != null and is_instance_valid(player):
		player.hp = player.max_hp
		Run.hp = Run.max_hp


func _unhandled_input(event: InputEvent) -> void:
	if menu != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_close_menu()
			get_viewport().set_input_as_handled()
		return
	if talk_box.visible:
		var tap: bool = event is InputEventScreenTouch and event.pressed
		if tap or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			_advance_talk()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		match near:
			"neith":
				_start_talk()
			"altare":
				_open_aspects()
			"prove":
				_open_trials()
			"stele", "":
				pass
			_:
				_take_weapon(int(near.substr(3)))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_open_pause()


## Start / Esc: la pausa, con la scelta di restare o di tornare nella Sala. Prima Start faceva
## uscire subito (e cambiando scena durante l'input il gioco dava errore e si bloccava).
func _open_pause() -> void:
	var col := _window(Lang.t("Pausa"), "")
	var resume := _button(col, Lang.t("Riprendi"), true, _close_menu)
	_button(col, Lang.t("Torna nella Sala del Giudizio"), true, func() -> void:
		_close_menu()
		_leave.call_deferred())
	resume.grab_focus.call_deferred()


func _leave() -> void:
	Run.training = false
	Run.from_armory = true
	Sfx.play("door")
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


func _take_weapon(i: int) -> void:
	var p: Dictionary = pedestals[i]
	if p["id"] == "" or not Weapons.is_unlocked(p["id"]) or Run.weapon == p["id"]:
		Fx.shake(1.5)
		return
	Weapons.choose(p["id"])
	Run.new_run()
	Sfx.play("boon", 0.0)
	Fx.burst(player.global_position + Vector2(0, -12), NEITH_COLOR, 24, 110.0)
	Fx.float_text(player.global_position + Vector2(0, -30), p["name"], GOLD)


# ---------------------------------------------------------------- Neith

func _neith_lines() -> Array:
	if not Meta.weapons_unlocked.has("lancia"):
		return [
			Lang.t("Fermati, mortale. Questo è il mio cortile, e chi entra viene misurato."),
			Lang.t("Io sono Neith di Sais. Ero già antica quando Ra aprì gli occhi per la prima volta."),
			Lang.t("Hai abbattuto il guardiano della porta con una spada ricurva. Non basta. Chi attraversa la notte deve conoscere più di una lama."),
			Lang.t("Prendi questa lancia. L'ho forgiata io. Colpisce lontano, e non perdona chi la impugna male. Se attacchi appena dopo uno scatto, affonda il doppio più lontano."),
			Lang.t("Le armi qui dormono. Le Lacrime di Iside le risvegliano: Iside piange solo sui grandi signori della notte, come Am-heh, quando cadono sotto un'arma che non li ha mai toccati. Portamele all'altare."),
			Lang.t("I fantocci d'argilla sono ushabti: rispondono per te. Colpiscili quanto vuoi. La porta laggiù fa uscire le creature del Duat, se vuoi metterti alla prova."),
		]
	for b in _neith_beats():
		if b[1] and not Meta.neith_seen.has(b[0]):
			Meta.neith_seen.append(b[0])
			Meta.save()
			return b[2]
	return [[Lang.t("Misura la distanza. Poi accorciala."), Lang.t("Un'arma che non conosci ti tradirà nel momento peggiore."), Lang.t("Torna quando avrai qualcosa da mostrarmi."), Lang.t("Colpisci i fantocci. Loro non si lamentano. Io sì, quando colpisci male.")].pick_random()]


## Neith ha qualcosa di nuovo da dirti? (il punto esclamativo sopra di lei)
func _neith_has_news() -> bool:
	if not Meta.weapons_unlocked.has("lancia"):
		return true
	for b in _neith_beats():
		if b[1] and not Meta.neith_seen.has(b[0]):
			return true
	return false


## I pezzi di storia di Neith: [id, condizione, battute].
func _neith_beats() -> Array:
	return [
		["lancia_amheh", Meta.first_kills.has("amheh|lancia|0"), [Lang.t("La mia lancia ha spento il fuoco di Am-heh. La impugni come se l'avessi sempre fatto. Strano, per uno scriba.")]],
		["khopesh_amheh", Meta.first_kills.has("amheh|khopesh|0"), [Lang.t("Il khopesh dei re ha vinto il Divoratore di Milioni. Ma vincere ancora con la stessa lama non ti insegna niente di nuovo, e non ti porta altre Lacrime.")]],
		["aspetto", Meta.aspect_levels.size() > 0, [Lang.t("Hai risvegliato un volto nuovo della tua arma. Dietro ogni volto c'è un dio: impara il suo nome, e saprai come colpire.")]],
		["senza_lacrime", Meta.tears == 0 and Meta.serpent_wins >= 3, [Lang.t("Non hai Lacrime. Il pianto di Iside cade solo sui grandi signori della notte, battuti con un'arma che non li ha ancora conosciuti. Il Serpente della Porta non è degno delle sue lacrime. Cambia lama.")]],
		["teli", Meta.serpent_wins >= 2, [Lang.t("Sotto quei teli dormono altre armi. Non sono ancora pronte. Nemmeno tu.")]],
		["sais", true, [Lang.t("A Sais mi chiamavano madre di Ra. Molto più tardi i Greci mi confusero con la loro Atena. Lasciali confondere: le dee antiche non si offendono per così poco.")]],
		["tessitrice", true, [Lang.t("Si dice che io abbia tessuto il mondo come una tela, e che lo tessa ancora ogni giorno. Una lancia è come un filo: dritta, tesa, e taglia solo se sai dove tirarla.")]],
	]


func _start_talk() -> void:
	talk_lines = _neith_lines()
	player.set_physics_process(false)
	talk_box.visible = true
	_advance_talk()


func _advance_talk() -> void:
	if talk_lines.is_empty():
		talk_box.visible = false
		player.set_physics_process(true)
		if not Meta.weapons_unlocked.has("lancia"):
			Meta.weapons_unlocked.append("lancia")
			Meta.save()
			Sfx.play("boon", 0.0)
			Fx.burst(pedestals[1]["pos"] + Vector2(0, -16), NEITH_COLOR, 30, 120.0)
			Fx.float_text(pedestals[1]["pos"] + Vector2(0, -34), Lang.t("Lancia di Neith"), GOLD)
		return
	Sfx.play("ui", 0.0)
	talk_name.text = Lang.t("Neith")
	talk_text.text = UiStyle.next_talk_page(talk_lines)


# ---------------------------------------------------------------- finestre (altare e prove)

func _window(title: String, sub: String) -> VBoxContainer:
	_close_menu()
	player.set_physics_process(false)
	menu = CanvasLayer.new()
	menu.layer = 20
	add_child(menu)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(NEITH_COLOR.darkened(0.3)))
	center.add_child(pap)
	# dentro uno scorrimento: sul telefono l'altare con i tre aspetti è più alto dello schermo
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pap.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(4 * Fx.ui))
	scroll.add_child(col)
	var vs := get_viewport().get_visible_rect().size
	var vw := vs.x
	col.custom_minimum_size = Vector2(minf(520.0 * Fx.ui, vw - 40.0), 0)
	var fit := func() -> void:
		if is_instance_valid(scroll) and is_instance_valid(col):
			scroll.custom_minimum_size = Vector2(col.custom_minimum_size.x + 4.0, minf(col.get_combined_minimum_size().y, vs.y - 44.0))
	col.minimum_size_changed.connect(fit)
	fit.call_deferred()
	var h := UiStyle.label(title, 13, NEITH_COLOR.darkened(0.25), true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	if sub != "":
		var s := UiStyle.label(sub, 8, UiStyle.INK_SOFT, false, col.custom_minimum_size.x)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
	return col


func _button(parent: Control, text: String, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	UiStyle.papyrus_button(b, NEITH_COLOR)
	b.add_theme_font_size_override("font_size", Fx.fs(8))
	b.add_theme_color_override("font_disabled_color", Color(UiStyle.INK, 0.4))
	b.disabled = not enabled
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _close_menu() -> void:
	if menu != null:
		menu.queue_free()
		menu = null
		player.set_physics_process(true)


func _open_aspects(focus: String = "") -> void:
	var w := Run.weapon
	var wd: Dictionary = Weapons.ALL[w]
	var col := _window(Lang.t("Altare di Neith · %s") % wd["name"], Lang.t("Lacrime di Iside: %d  ·  si ottengono battendo Am-heh la prima volta con ogni arma (e di nuovo con il Peso del Cuore a 4 e a 8)") % Meta.tears)
	var inner: float = col.custom_minimum_size.x
	var first: Button = null
	for a in wd["aspects"]:
		var ad: Dictionary = wd["aspects"][a]
		var lvl := Weapons.aspect_level(w, a)
		var chosen: bool = Run.aspect == a
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		col.add_child(box)
		# niente pallini ●○: i caratteri del gioco non li hanno e sul telefono diventano quadratini
		var stars := (Lang.t("livello %d/%d") % [lvl, Weapons.MAX_LEVEL]) if lvl > 0 else Lang.t("da risvegliare")
		var name_l := UiStyle.label("%s  ·  %s%s" % [ad["name"], stars, Lang.t("  ·  SCELTO") if chosen else ""], 10, UiStyle.INK if lvl > 0 else UiStyle.INK_SOFT, true, inner)
		box.add_child(name_l)
		var desc := Weapons.text(w, a, maxi(lvl, 1))
		var nxt := Weapons.next_cost(w, a)
		if lvl > 0 and nxt >= 0:
			desc += Lang.t("   (livello %d: %s)") % [lvl + 1, Weapons.text(w, a, lvl + 1)]
		box.add_child(UiStyle.label(desc, 8, UiStyle.INK_SOFT, false, inner))
		box.add_child(UiStyle.label(ad["lore"], 7, Color(0.36, 0.3, 0.45), false, inner))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(6 * Fx.ui))
		box.add_child(row)
		if lvl > 0 and not chosen:
			var bsel := _button(row, Lang.t("Scegli questo aspetto"), true, func() -> void:
				Weapons.choose(w, a)
				Run.new_run()
				Sfx.play("boon", 0.0)
				_open_aspects(a))
			if first == null or a == focus:
				first = bsel
		if nxt >= 0:
			var label := (Lang.t("Risveglia · %d Lacrime") % nxt) if lvl == 0 else (Lang.t("Potenzia al livello %d · %d Lacrime") % [lvl + 1, nxt])
			if nxt == 1:
				label = label.replace(Lang.t("Lacrime"), Lang.t("Lacrima"))
			var bup := _button(row, label, Meta.tears >= nxt, func() -> void:
				if Weapons.upgrade(w, a):
					Sfx.play("boon", 0.0)
					Fx.shake(3.0)
					if lvl == 0:
						Weapons.choose(w, a)
					Run.new_run()
				_open_aspects(a))
			if first == null and not bup.disabled:
				first = bup
	var close := _button(col, Lang.t("Chiudi"), true, _close_menu)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	(first if first != null else close).grab_focus.call_deferred()


func _open_trials() -> void:
	var col := _window(Lang.t("La porta delle prove"), Lang.t("Scegli chi far uscire. Nel cortile non si muore: guarda la stele per vedere quanto fa la tua arma."))
	var first: Button = null
	for trial in TRIALS:
		var b := _button(col, Lang.t(trial["name"]), true, func() -> void:
			_close_menu()
			_spawn_trial(trial["list"]))
		if first == null:
			first = b
	_button(col, Lang.t("Via tutti i nemici"), not trial_enemies.is_empty(), func() -> void:
		for e in trial_enemies:
			if is_instance_valid(e) and not e.dead:
				e.die()
		_close_menu())
	_button(col, Lang.t("Chiudi"), true, _close_menu)
	first.grab_focus.call_deferred()


func _spawn_trial(list: Array) -> void:
	Sfx.play("door")
	var origin: Vector2 = spots["prove"] + Vector2(0, -40)
	for i in range(list.size()):
		var e: Enemy = ENEMIES[list[i]].instantiate()
		e.position = origin + Vector2((i - (list.size() - 1) / 2.0) * 22.0, randf_range(-10.0, 10.0))
		e.ka_value = 0
		world.add_child(e)
		trial_enemies.append(e)
		Fx.burst(e.position + Vector2(0, -8), Color(0.85, 0.3, 0.25), 12, 80.0)


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	if spots.is_empty():
		return
	var r := ROOM
	# uscita verso la Sala, a est
	draw_rect(Rect2(r.end.x - WALL, 184, WALL, 52), Color(0.05, 0.05, 0.1))
	draw_rect(Rect2(r.end.x - WALL - 3, 180, 3, 60), GOLD)
	# porta delle prove, a sud
	var gp: Vector2 = spots["prove"]
	var glow := 0.4 + 0.3 * sin(t * 2.5)
	draw_rect(Rect2(gp.x - 24, gp.y, 48, WALL), Color(0.08, 0.02, 0.02))
	draw_rect(Rect2(gp.x - 20, gp.y + 2, 40, WALL - 4), Color(0.85, 0.25, 0.2, 0.25 + 0.25 * glow))
	draw_rect(Rect2(gp.x - 26, gp.y - 3, 52, 3), GOLD)
	for p in pedestals:
		_draw_pedestal(p)
	_draw_altar(spots["altare"])
	_draw_stele(spots["stele"])
	_draw_neith(spots["neith"])
	# i segni: stelline su ciò che si usa, il punto esclamativo se Neith ha battute nuove
	if not talk_box.visible and menu == null:
		var k := 0.0
		for key in ["neith", "altare", "prove", "stele"]:
			var off := Vector2(0, -40) if key == "neith" else (Vector2(0, -14) if key != "stele" else Vector2(0, -30))
			UiStyle.sparkle(self, spots[key] + off, 18.0, t, near == key, k)
			k += 1.3
		for i in range(pedestals.size()):
			if pedestals[i]["id"] != "":
				UiStyle.sparkle(self, pedestals[i]["pos"] + Vector2(0, -16), 14.0, t, near == "ped%d" % i, k + i)
		if t >= _news_t:
			_news_t = t + 0.5
			_news = _neith_has_news()
			_altar_news = Weapons.something_to_spend()
		if _news:
			UiStyle.exclaim(self, spots["neith"] + Vector2(0, -80), t)
		if _altar_news:
			UiStyle.exclaim(self, spots["altare"] + Vector2(0, -40), t)
	if near != "" and near != "stele" and not talk_box.visible and menu == null:
		var at: Vector2
		if near.begins_with("ped"):
			at = pedestals[int(near.substr(3))]["pos"]
		else:
			at = spots[near]
		draw_arc(at + Vector2(0, -16), 24.0, 0.0, TAU, 32, Color(NEITH_COLOR, 0.5 + 0.3 * sin(t * 4.0)), 1.5)


func _neith_emblem(c: Vector2, s: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(s, s))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(10, 0), Vector2(8, 10), Vector2(-8, 10), Vector2(-10, 0)]), Color(col, col.a * 0.5))
	draw_line(Vector2(-14, -14), Vector2(14, 14), col, 2.0)
	draw_line(Vector2(14, -14), Vector2(-14, 14), col, 2.0)
	for e in [Vector2(14, 14), Vector2(-14, 14)]:
		draw_line(e, e + Vector2(-4 * signf(e.x), 0), col, 2.0)
		draw_line(e, e + Vector2(0, -4), col, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pedestal(p: Dictionary) -> void:
	var pos: Vector2 = p["pos"]
	var stone := Color(0.56, 0.48, 0.38)
	draw_rect(Rect2(pos.x - 12, pos.y - 4, 24, 10), stone)
	draw_rect(Rect2(pos.x - 12, pos.y - 4, 24, 2), stone.lightened(0.2))
	draw_rect(Rect2(pos.x - 14, pos.y + 6, 28, 3), stone.darkened(0.3))
	var bob := sin(t * 1.8 + pos.x) * 1.2
	var id: String = p["id"]
	if id == "" or not Weapons.is_unlocked(id):
		# arma coperta dal telo di lino, con il suo segno
		draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 9, pos.y - 4), Vector2(pos.x + 9, pos.y - 4), Vector2(pos.x + 5, pos.y - 26), Vector2(pos.x, pos.y - 30), Vector2(pos.x - 5, pos.y - 26)]), Color(0.85, 0.8, 0.68))
		draw_line(Vector2(pos.x - 3, pos.y - 24), Vector2(pos.x + 3, pos.y - 10), Color(0.5, 0.42, 0.3), 1.0)
		draw_circle(Vector2(pos.x, pos.y - 17), 2.5, Color(0.5, 0.2, 0.18, 0.7))
		return
	var chosen := Run.weapon == id
	if chosen:
		draw_circle(Vector2(pos.x, pos.y - 18), 15.0 + 2.0 * sin(t * 3.0), Color(GOLD, 0.15))
	var c := Vector2(pos.x, pos.y - 18 + bob)
	if id == "lancia":
		draw_line(c + Vector2(0, 14), c + Vector2(0, -14), Color(0.55, 0.38, 0.2), 2.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(3, -14), c + Vector2(-3, -14)]), Color(0.85, 0.85, 0.9))
		draw_line(c + Vector2(-3, -12), c + Vector2(3, -12), GOLD, 1.5)
	else:
		draw_line(c + Vector2(-2, 12), c + Vector2(0, 2), GOLD, 2.5)
		var blade := PackedVector2Array()
		for i in range(9):
			var k := i / 8.0
			blade.append(c + Vector2(sin(k * PI) * 7.0 - k * 3.0, 2 - k * 18.0))
		draw_polyline(blade, Color(0.85, 0.85, 0.9), 2.5)


func _draw_altar(p: Vector2) -> void:
	var stone := Color(0.56, 0.47, 0.38)
	var outl := Color(0.12, 0.08, 0.05)
	# ombra, gradino e blocco dell'altare con il bordo dipinto e lo scudo di Neith
	draw_set_transform(p + Vector2(3, 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 26.6, p.y + 1.4, 53.2, 6.2), outl)
	draw_rect(Rect2(p.x - 26, p.y + 2, 52, 5), stone.darkened(0.2))
	draw_rect(Rect2(p.x - 21.6, p.y - 12.6, 43.2, 15.2), outl)
	draw_rect(Rect2(p.x - 21, p.y - 12, 42, 14), stone)
	draw_rect(Rect2(p.x - 21, p.y - 12, 42, 2), stone.lightened(0.2))
	draw_rect(Rect2(p.x - 18, p.y - 8, 36, 1.2), Color(0.2, 0.45, 0.75))
	draw_rect(Rect2(p.x - 18, p.y - 1, 36, 1.2), Color(0.72, 0.26, 0.15))
	draw_rect(Rect2(p.x - 23.6, p.y - 15.6, 47.2, 4.2), outl)
	draw_rect(Rect2(p.x - 23, p.y - 15, 46, 3), stone.lightened(0.1))
	_neith_emblem(Vector2(p.x, p.y - 4.5), 0.4, Color(GOLD, 0.85))
	# luce azzurra sul pavimento quando hai Lacrime da spendere
	if Weapons.something_to_spend():
		var pulse := 0.5 + 0.5 * sin(t * 2.5)
		draw_set_transform(p + Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 40.0 + pulse * 4.0, Color(0.4, 0.7, 1.0, 0.08 + 0.05 * pulse))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	p += Vector2(0, -4)
	# la ciotola delle offerte con la fiamma azzurra: più Lacrime, più luce
	var flame := 0.5 + 0.5 * sin(t * 6.0)
	var power := clampf(Meta.tears / 4.0, 0.2, 1.0)
	draw_circle(Vector2(p.x, p.y - 16), 10.0 * power + 4.0, Color(0.4, 0.7, 1.0, 0.12 + 0.08 * flame))
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 6, p.y - 14), Vector2(p.x + 6, p.y - 14), Vector2(p.x + 3, p.y - 11), Vector2(p.x - 3, p.y - 11)]), GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 3, p.y - 14), Vector2(p.x, p.y - 22 - 3 * flame * power), Vector2(p.x + 3, p.y - 14)]), Color(0.55, 0.8, 1.0, 0.85))


func _draw_stele(p: Vector2) -> void:
	var stone := Color(0.36, 0.34, 0.4)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 22, p.y + 4), Vector2(p.x + 22, p.y + 4), Vector2(p.x + 22, p.y - 44), Vector2(p.x, p.y - 52), Vector2(p.x - 22, p.y - 44)]), stone)
	draw_polyline(PackedVector2Array([Vector2(p.x - 22, p.y + 4), Vector2(p.x - 22, p.y - 44), Vector2(p.x, p.y - 52), Vector2(p.x + 22, p.y - 44), Vector2(p.x + 22, p.y + 4)]), GOLD, 1.0)
	var font := UiStyle.title_font()
	var fs := 7
	var lines := [[Lang.t("colpo"), "%d" % roundi(last_hit)], [Lang.t("combo"), "%d" % roundi(combo_dmg)], [Lang.t("al sec."), "%d" % roundi(_dps())]]
	for i in range(lines.size()):
		var yy := p.y - 36 + i * 13
		draw_string(font, Vector2(p.x - 19, yy), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.8, 0.7))
		draw_string(font, Vector2(p.x - 19, yy), lines[i][1], HORIZONTAL_ALIGNMENT_RIGHT, 38, fs + 1, GOLD)


## Neith: la dea guerriera con la corona rossa del Basso Egitto, l'arco nella mano
## e le frecce incrociate sulla veste. Ti segue con lo sguardo e gesticola quando parla.
func _draw_neith(p: Vector2) -> void:
	var skin := Color(0.72, 0.47, 0.28)
	var linen := Color(0.93, 0.9, 0.82)
	var red := Color(0.72, 0.16, 0.14)
	var green := Color(0.18, 0.5, 0.36)
	var talking: bool = talk_box.visible
	var face := 1.0
	if player != null and is_instance_valid(player) and player.global_position.x < p.x - 6.0:
		face = -1.0
	var bob := sin(t * 1.5) * 0.6
	var pulse := 0.5 + 0.5 * sin(t * (5.0 if talking else 1.4))
	draw_circle(p + Vector2(0, -30), 28.0 + 2.0 * pulse, Color(NEITH_COLOR, 0.05 + (0.08 if talking else 0.03) * pulse))
	draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 16, p.y - 4, 32, 6), Color(0.3, 0.22, 0.18))
	draw_rect(Rect2(p.x - 16, p.y - 4, 32, 1.5), GOLD)
	draw_set_transform(p, 0.0, Vector2(face, 1.0))
	var o := Vector2(0, -4)
	# arco nella mano dietro
	draw_arc(o + Vector2(-12, -30 + bob), 16.0, -PI * 0.42, PI * 0.42, 16, Color(0.5, 0.33, 0.16), 2.0)
	draw_line(o + Vector2(-12 + 16 * cos(-PI * 0.42), -30 + bob + 16 * sin(-PI * 0.42)), o + Vector2(-12 + 16 * cos(PI * 0.42), -30 + bob + 16 * sin(PI * 0.42)), Color(0.9, 0.85, 0.7, 0.8), 0.7)
	# veste lunga e aderente, con la rete a rombi
	var sh := -42.0 + bob
	draw_colored_polygon(PackedVector2Array([o + Vector2(-7, sh + 6), o + Vector2(7, sh + 6), o + Vector2(6, -14), o + Vector2(7, 0), o + Vector2(-6, 0), o + Vector2(-5, -14)]), linen)
	for i in range(4):
		draw_line(o + Vector2(-5, sh + 12 + i * 8), o + Vector2(5, sh + 18 + i * 8), green.darkened(0.1), 0.7)
		draw_line(o + Vector2(5, sh + 12 + i * 8), o + Vector2(-5, sh + 18 + i * 8), green.darkened(0.1), 0.7)
	draw_rect(Rect2(o.x - 6, o.y + sh + 5, 12, 2), red)
	# spalle, braccia, collare
	draw_colored_polygon(PackedVector2Array([o + Vector2(-8, sh), o + Vector2(8, sh), o + Vector2(7, sh + 7), o + Vector2(-7, sh + 7)]), skin)
	for rr in range(3):
		draw_arc(o + Vector2(0, sh - 1), 4.0 + rr * 2.2, 0.08 * PI, 0.92 * PI, 14, [GOLD, green, red][rr], 2.0)
	draw_line(o + Vector2(-7, sh + 2), o + Vector2(-11, -28 + bob), skin, 2.8)
	var lift := (0.6 + 0.25 * sin(t * 3.0)) if talking else 0.0
	var shoulder := o + Vector2(7, sh + 2)
	var hand := shoulder + Vector2(3 + 9 * lift, 16 - 20 * lift)
	draw_line(shoulder, hand, skin, 2.8)
	# due frecce incrociate nella mano davanti
	draw_line(hand + Vector2(-3, 6), hand + Vector2(5, -8), Color(0.55, 0.38, 0.2), 1.2)
	draw_line(hand + Vector2(3, 6), hand + Vector2(-3, -8), Color(0.55, 0.38, 0.2), 1.2)
	# testa: parrucca nera, occhio con il kohl, corona rossa con il ricciolo
	var hy := sh - 8.0
	draw_colored_polygon(PackedVector2Array([o + Vector2(-6, hy - 4), o + Vector2(3, hy - 6), o + Vector2(2, sh + 4), o + Vector2(-7, sh + 5)]), Color(0.08, 0.07, 0.1))
	draw_circle(o + Vector2(1, hy), 5.0, skin)
	draw_colored_polygon(PackedVector2Array([o + Vector2(4, hy - 2), o + Vector2(8, hy + 1), o + Vector2(5, hy + 2)]), skin)
	var eye := o + Vector2(3.5, hy - 1)
	draw_circle(eye, 2.5 + pulse, Color(1, 0.5, 0.4, (0.25 if talking else 0.08) * pulse))
	draw_colored_polygon(PackedVector2Array([eye + Vector2(-1.8, 0), eye + Vector2(0, -1), eye + Vector2(2, 0), eye + Vector2(0, 0.8)]), Color(0.98, 0.95, 0.88))
	draw_circle(eye + Vector2(0.4, 0), 0.7, Color(0.05, 0.04, 0.06))
	draw_line(eye + Vector2(-1.8, 0), eye + Vector2(-4.5, 0.5), Color(0.05, 0.04, 0.06), 0.8)
	# corona rossa (deshret): bassa davanti, alta dietro, con il ricciolo d'oro
	draw_colored_polygon(PackedVector2Array([o + Vector2(-6, hy - 3), o + Vector2(-6, hy - 17), o + Vector2(-2, hy - 17), o + Vector2(-2, hy - 8), o + Vector2(6, hy - 8), o + Vector2(6, hy - 3)]), red)
	draw_arc(o + Vector2(3, hy - 12), 3.0, PI * 0.5, PI * 1.9, 10, GOLD, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
