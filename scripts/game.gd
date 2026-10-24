extends Node2D
## La Prima Ora del Duat: 10 stanze, poi Ammit. In ogni stanza due ondate di nemici,
## poi la ricompensa, poi 2-3 porte tra cui scegliere la prossima ricompensa.
## Stanza 5: il Serpente della Porta (guardiano). A volte una porta porta dal Traghettatore,
## dove si spende il Ka della discesa.

const ROOM := Rect2(0, 0, 800, 480)
const WALL := 32.0
const TOP := 64.0                     # il muro in alto è alto due file
const PlayerScene := preload("res://scenes/player.tscn")
const ENEMIES := {
	"mummy": preload("res://scenes/mummy.tscn"),
	"scarab": preload("res://scenes/scarab.tscn"),
	"priest": preload("res://scenes/priest.tscn"),
	"ammit": preload("res://scenes/ammit.tscn"),
	"serpent": preload("res://scenes/serpent.tscn"),
	"scorpion": preload("res://scenes/scorpion.tscn"),
	"cobra": preload("res://scenes/cobra.tscn"),
}
const FerrymanScript := preload("res://scripts/ferryman.gd")
const FEATHER_KA := 0.4               ## con la Piuma di Ma'at si custodisce solo il 40% del Ka
const KILLER_NAMES := {"mummy": "una mummia", "scarab": "gli scarabei", "priest": "un sacerdote", "scorpion": "uno scorpione di Serket", "cobra": "un cobra", "serpent": "il Serpente della Porta", "ammit": "Ammit", "trappola": "una trappola"}
const SHOP_CHANCE := 0.25             ## probabilità di una porta del Traghettatore (oltre a quella dopo il guardiano)
const SHOP_ITEMS := [
	{"kind": "heal", "title": "Acqua del Nilo", "desc": "Recuperi il 30% della vita", "price": 30},
	{"kind": "boon", "title": "Offerta agli dèi", "desc": "Un dio a caso ti offre un dono", "price": 55},
	{"kind": "upgrade", "title": "Inchiostro di Thoth", "desc": "Un tuo dono a caso sale di livello", "price": 45},
]
const PickupScript := preload("res://scripts/pickup.gd")
const DecorScript := preload("res://scripts/room_decor.gd")
const UshabtiScript := preload("res://scripts/ushabti.gd")
const TRAPS_FROM_ROOM := 3            ## le trappole compaiono da questa stanza in poi
const DoorScript := preload("res://scripts/door.gd")
const SET_DOOR_CHANCE := 0.4          ## probabilità che compaia una porta di Set
const SET_DOOR_COST := 10.0           ## vita da pagare per entrare

## Disposizioni delle colonne, in frazioni dell'area calpestabile.
const LAYOUTS := [
	[Vector2(0.3, 0.35), Vector2(0.7, 0.35), Vector2(0.3, 0.72), Vector2(0.7, 0.72)],
	[Vector2(0.5, 0.5)],
	[Vector2(0.22, 0.4), Vector2(0.5, 0.3), Vector2(0.78, 0.4)],
	[Vector2(0.25, 0.6), Vector2(0.75, 0.6), Vector2(0.5, 0.4)],
	[Vector2(0.2, 0.3), Vector2(0.8, 0.3), Vector2(0.2, 0.75), Vector2(0.8, 0.75), Vector2(0.5, 0.55)],
]
## Arena di Ammit: 6 colonne, ognuna crolla dopo averla stordita una volta.
const BOSS_LAYOUT := [Vector2(0.22, 0.3), Vector2(0.78, 0.3), Vector2(0.12, 0.62), Vector2(0.88, 0.62), Vector2(0.36, 0.8), Vector2(0.64, 0.8)]

var player
var pillars: Array = []
var waves: Array = []
var alive := 0
var spawning := 0
var cleared := false
var current_reward := {}
var doors: Array = []
var finished := false
var boss: Enemy = null
var obstacles: Array = []             # rettangoli occupati da statue, bracieri, sarcofagi
var traps_pos: Array = []             # posizioni delle lastre con spuntoni
var room_gen := 0                     # cambia a ogni stanza: annulla le comparse rimaste in sospeso
var boss_bar: ColorRect
var boss_fill: ColorRect
var boss_name: Label
var menu: CanvasLayer                 # scelta dei doni
var panel: CanvasLayer
var pause_menu: CanvasLayer           # menu di pausa (Esc / Start)
var bonus_boon := false               # il prossimo dono sale di un livello in più (premio del guardiano)
var shops_visited := 0
var shop_items: Array = []
var doors_after_boon := true
var can_leave := true                 # alla morte: si torna alla Sala solo dopo l'animazione
var hud_room := ""
var hud_eye := ""
var hud_sek := ""

const DummyScript := preload("res://scripts/dummy.gd")

@onready var world: Node2D = $World
@onready var hud: Label = $UI/Hud
@onready var help: Label = $UI/Help
@onready var prompt: Label = $UI/Prompt
@onready var message: Label = $UI/Message
@onready var reticle: Node2D = $UI/Reticle
@onready var banner: Label = $UI/Banner


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.world = world
	Fx.set_hitboxes(Fx.show_hitboxes)
	Run.in_hub = false
	Run.new_run()
	Run.blessing_granted.connect(_on_blessing_granted)
	_build_vignette()
	_build_boss_bar()
	Fx.scale_labels($UI)
	prompt.add_theme_font_size_override("font_size", Fx.fs(8))      # la descrizione della porta, più discreta
	var hud_bars := HudBars.new()
	hud_bars.game = self
	$UI.add_child(hud_bars)
	var arrows := DoorArrows.new()
	arrows.game = self
	$UI.add_child(arrows)
	hud.position.y = (44.0 if Fx.mobile else 46.0)
	var listener := PanelListener.new()
	listener.game = self
	add_child(listener)
	# una discesa interrotta (gioco chiuso, pagina chiusa dal telefono) riprende dalla sua stanza
	if not Run.resume.is_empty():
		var d: Dictionary = Run.resume
		Run.resume = {}
		Run.apply_descent(d)
		shops_visited = d.get("shops", 0)
		bonus_boon = d.get("bonus", false)
		Run.room = int(d["room"]) - 1
		start_room(d.get("reward", {"kind": "none"}))
		_banner("Discesa ripresa", "Stanza %d di %d" % [Run.room, Run.ROOMS_PER_RUN] if Run.room <= Run.ROOMS_PER_RUN else "Ammit", Color(0.94, 0.72, 0.3))
		return
	# la primissima volta: la stanza dell'addestramento, poi la discesa vera
	if not Meta.tutorial_done and OS.get_environment("DUAT_PERSONA") == "" and OS.get_environment("DUAT_NOTUT") == "":
		start_room({"kind": "tutorial"})
		return
	# la prima stanza non ha ricompensa: il primo dono è quello di Anubi
	start_room({"kind": "none"})
	_show_anubi_menu()


## Se il telefono riceve una chiamata o cambi finestra, il gioco va in pausa da solo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if pause_menu == null and menu == null and panel == null and not finished:
			_toggle_pause()


# ---------------------------------------------------------------- addestramento (solo la prima volta)
## Una stanza vera, con fantocci al posto dei nemici: un passo alla volta, con il testo
## in un riquadro fisso in alto (mai sopra i nemici). Qui non si può morire.
## Passi: muoversi, khopesh, scatto, Occhio di Horus, Ka, porta.

var tut_step := -1
var tut_panel: PanelContainer
var tut_title: Label
var tut_body: Label
var tut_start := Vector2.ZERO
var tut_walked := 0.0
var tut_targets: Array = []
var tut_dodges := 0
var tut_dashes := 0
var tut_prev_dash := false
var tut_wait := 0.0

const TUT_STEPS := 6


func _ctl(what: String) -> String:
	var dev := Fx.device
	match what:
		"move":
			return {"pad": "la levetta sinistra", "touch": "la levetta a sinistra"}.get(dev, "W A S D (o le frecce)")
		"attack":
			return {"pad": "X o RB", "touch": "il pulsante KHOPESH"}.get(dev, "il clic sinistro (o J)")
		"dash":
			return {"pad": "A o LB", "touch": "il pulsante SCATTO"}.get(dev, "Spazio")
		"eye":
			return {"pad": "Y o RT", "touch": "il pulsante OCCHIO"}.get(dev, "il clic destro (o L)")
	return ""


func _tut_begin() -> void:
	Music.play("hub")
	tut_step = -1
	tut_panel = PanelContainer.new()
	var box := UiStyle.papyrus_box(UiStyle.GOLD.darkened(0.3))
	box.content_margin_left = 7
	box.content_margin_right = 7
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	tut_panel.add_theme_stylebox_override("panel", box)
	tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_panel.modulate.a = 0.93
	$UI.add_child(tut_panel)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	tut_panel.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	tut_title = UiStyle.label("", 8, UiStyle.INK, true)
	tut_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tut_title)
	var skip := Button.new()
	skip.text = "Salta ›"
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", Fx.fs(8))
	skip.add_theme_color_override("font_color", UiStyle.INK_RED)
	skip.add_theme_color_override("font_hover_color", UiStyle.INK)
	skip.pressed.connect(_finish_tutorial)
	skip.add_to_group("touch_tap")          # sul telefono il tocco arriva da touch_controls.gd
	top.add_child(skip)
	tut_body = UiStyle.label("", 8, UiStyle.INK_SOFT, false, _tut_width() - 14.0)
	tut_body.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	col.add_child(tut_body)
	tut_panel.custom_minimum_size = Vector2(_tut_width(), 0)
	_tut_next()


## Il riquadro sta in alto, tra l'HUD a sinistra e i pulsanti del telefono a destra, ed è
## stretto: i fantocci restano sempre visibili sotto.
func _tut_width() -> float:
	var vw := get_viewport().get_visible_rect().size.x
	var left := 168.0 if not Fx.mobile else 156.0
	var right := vw - (84.0 if Fx.device == "touch" or Fx.mobile else 10.0)
	return clampf(right - left, 180.0, 300.0)


func _tut_place() -> void:
	if tut_panel == null:
		return
	tut_panel.reset_size()
	var vw := get_viewport().get_visible_rect().size.x
	var left := 168.0 if not Fx.mobile else 156.0
	var right := vw - (84.0 if Fx.device == "touch" or Fx.mobile else 10.0)
	var x := clampf((vw - tut_panel.size.x) / 2.0, left, maxf(left, right - tut_panel.size.x))
	tut_panel.position = Vector2(x, 6.0)


func _tut_say(title: String, body: String) -> void:
	tut_title.text = "%d/%d · %s" % [tut_step + 1, TUT_STEPS, title]
	tut_body.text = body
	tut_body.visible_ratio = 0.0
	tut_body.create_tween().tween_property(tut_body, "visible_ratio", 1.0, clampf(body.length() * 0.008, 0.3, 0.8))
	_tut_place.call_deferred()
	Sfx.play("ui", 0.0)
	tut_panel.modulate = Color(1.5, 1.3, 1.0, 0.93)
	tut_panel.create_tween().tween_property(tut_panel, "modulate", Color(1, 1, 1, 0.93), 0.4)


func _tut_dummy(pos: Vector2, eye_only: bool = false, lunger: bool = false) -> Enemy:
	var d: Enemy = DummyScript.new()
	d.eye_only = eye_only
	d.lunger = lunger
	d.position = pos
	world.add_child(d)
	Fx.burst(pos + Vector2(0, -10), Color(0.9, 0.8, 0.6), 12, 70.0)
	tut_targets.append(d)
	return d


func _tut_clear_targets() -> void:
	for d in tut_targets:
		if is_instance_valid(d) and not d.dead:
			d.die()
	tut_targets.clear()


func _tut_next() -> void:
	tut_step += 1
	tut_wait = 0.0
	var mid := Vector2(ROOM.size.x / 2.0, ROOM.size.y / 2.0 + 20.0)
	match tut_step:
		0:
			tut_start = player.global_position
			tut_walked = 0.0
			_tut_say("Il cammino", "Anubi ti fa provare le armi prima della discesa. Muoviti con %s." % _ctl("move"))
		1:
			_tut_dummy(Vector2(mid.x - 50.0, 340.0))
			_tut_dummy(Vector2(mid.x + 50.0, 340.0))
			_tut_say("Il khopesh", "Rompi i due fantocci con %s. Il terzo colpo di fila è il più forte." % _ctl("attack"))
		2:
			var m := _tut_dummy(Vector2(mid.x, 290.0), false, true)
			m.dodged.connect(func() -> void: tut_dodges += 1)
			tut_dodges = 0
			tut_dashes = 0
			_tut_say("Lo scatto", "Rosso = sta per colpire. Quando la mummia carica premi %s: durante lo scatto nulla ti tocca. Schivala 2 volte." % _ctl("dash"))
		3:
			_tut_clear_targets()
			for at in [Vector2(110, 320), Vector2(ROOM.size.x - 110.0, 320), Vector2(mid.x, 300)]:
				_tut_dummy(at, true)
			_tut_say("L'Occhio di Horus", "I fantocci azzurri si rompono solo con l'Occhio: %s. Si ricarica da solo (il cerchio in alto)." % _ctl("eye"))
		4:
			var p = PickupScript.new()
			p.kind = "ka"
			world.add_child(p)
			p.position = mid
			p.collected.connect(_on_pickup_collected)
			_tut_say("Il Ka", "Raccogli la luce d'oro: è Ka, la tua forza vitale. Resta tuo anche se muori: nella Sala lo spendi nel Libro dei Morti per poteri permanenti.")
		5:
			_add_door("n", {"kind": "tutorial_end"})
			_tut_say("Le porte", "Sopra ogni porta c'è la sua ricompensa. Le frecce sul bordo indicano le porte fuori schermo. Entra: comincia la discesa.")
		_:
			pass


func _tut_tick() -> void:
	if player == null or not is_instance_valid(player):
		return
	player.hp = player.max_hp            # nell'addestramento non si muore
	match tut_step:
		0:
			tut_walked += player.velocity.length() * get_process_delta_time()
			if tut_walked > 160.0:
				_tut_next()
		1, 3:
			var all_down := true
			for d in tut_targets:
				if is_instance_valid(d) and not d.dead:
					all_down = false
			if all_down:
				tut_wait += get_process_delta_time()
				if tut_wait > 0.5:
					tut_targets.clear()
					_tut_next()
		2:
			var dashing: bool = player.dash_t > 0.0
			if dashing and not tut_prev_dash:
				tut_dashes += 1
			tut_prev_dash = dashing
			# chi proprio non ci riesce passa lo stesso dopo un po' di tentativi
			if tut_dodges >= 2 or tut_dashes >= 10:
				_tut_next()


func _finish_tutorial() -> void:
	if tut_step < 0 and Meta.tutorial_done:
		return
	Meta.tutorial_done = true
	Meta.save()
	tut_step = -1
	if tut_panel != null:
		tut_panel.queue_free()
		tut_panel = null
	tut_targets.clear()
	Run.room = 0
	start_room.call_deferred({"kind": "none"})
	_show_anubi_menu.call_deferred()


# ---------------------------------------------------------------- stanze

func start_room(reward: Dictionary) -> void:
	if reward.get("kind", "") == "tutorial_end":
		_finish_tutorial()
		return
	Run.room += 1
	room_gen += 1
	boss = null
	current_reward = reward
	if reward.get("kind", "") != "tutorial":
		Run.save_descent(reward, {"shops": shops_visited, "bonus": bonus_boon})
	cleared = false
	alive = 0
	spawning = 0
	doors.clear()
	message.visible = false
	boss_bar.visible = false
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()

	pillars.clear()
	var boss_room := Run.room > Run.ROOMS_PER_RUN
	var kind: String = reward.get("kind", "none")
	var calm := kind == "guardian" or kind == "shop" or kind == "tutorial"
	shop_items.clear()
	if not boss_room and kind != "guardian":
		Music.play("hub" if kind == "shop" else "room")
	var layout: Array = LAYOUTS.pick_random() if Run.room > 1 else LAYOUTS[0]
	if boss_room:
		layout = BOSS_LAYOUT
	elif kind == "shop" or kind == "tutorial":
		layout = []
	elif kind == "guardian":
		layout = LAYOUTS[0]
	for f in layout:
		pillars.append(Vector2(lerpf(WALL, ROOM.size.x - WALL, f.x), lerpf(TOP, ROOM.size.y - WALL, f.y)))
	_build_walls()
	var decor := DecorScript.new()
	world.add_child(decor)
	obstacles = decor.build(Run.room * 7919 + randi() % 1000, ROOM, TOP, WALL, pillars, boss_room)
	for r in obstacles:
		_solid(r)
	traps_pos.clear()
	if not boss_room and not calm and Run.room >= TRAPS_FROM_ROOM - Weights.rank("sabbie"):
		_place_traps()
	queue_redraw()

	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - WALL - 24.0)
	world.add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = int(ROOM.position.x)
	cam.limit_top = int(ROOM.position.y)
	cam.limit_right = int(ROOM.end.x)
	cam.limit_bottom = int(ROOM.end.y)
	cam.reset_smoothing()
	player.died.connect(_on_player_died)
	if Run.chap("c6"):
		var helper := UshabtiScript.new()
		world.add_child(helper)
		helper.global_position = player.global_position + Vector2(-18, -6)

	if boss_room:
		waves = []
		_start_boss()
		return
	if kind == "guardian":
		waves = []
		_start_guardian()
		return
	if kind == "shop":
		waves = []
		_start_shop()
		return
	if kind == "tutorial":
		waves = []
		_tut_begin()
		return
	var r := mini(Run.room, 8)
	var horde := 1.0 + 0.25 * Weights.rank("orde")
	var soft := 1 if r <= 2 else 0                # le prime due stanze sono un po' più leggere
	waves = [_make_wave(roundi((4 + r * 2 - soft) * horde), r >= 3), _make_wave(roundi((3 + r * 2 - soft) * horde), r >= 3)]
	_spawn_wave(waves.pop_front(), 1.0)


func _make_wave(budget: int, allow_priest: bool) -> Array:
	var out := []
	var late := Run.room > Run.GUARDIAN_ROOM    # dopo il guardiano arrivano scorpioni e cobra
	while budget > 0:
		var roll := randf()
		if late and roll < 0.22 and budget >= 3:
			out.append("cobra")
			budget -= 3
			continue
		if late and roll < 0.45 and budget >= 2:
			out.append_array(["scorpion", "scorpion"])
			budget -= 3
			continue
		if late:
			roll = randf()
		if allow_priest and roll < 0.25 and budget >= 3:
			out.append("priest")
			budget -= 3
		elif roll < 0.6 and budget >= 2:
			out.append("mummy")
			budget -= 2
		else:
			out.append_array(["scarab", "scarab", "scarab"])
			budget -= 2
	return out


func _spawn_wave(list: Array, delay: float) -> void:
	for i in range(list.size()):
		spawning += 1
		_spawn_after(list[i], _free_spot(), delay + i * 0.12)


func _spawn_after(kind: String, pos: Vector2, delay: float) -> void:
	var marker := SpawnMarker.new()
	marker.duration = delay
	world.add_child(marker)
	marker.position = pos
	get_tree().create_timer(delay, false).timeout.connect(_do_spawn.bind(kind, pos, marker, room_gen))


## Fa comparire il nemico annunciato da _spawn_after. Se nel frattempo la stanza
## è cambiata (o la run è finita), non fa nulla.
func _do_spawn(kind: String, pos: Vector2, marker, gen: int) -> void:
	if is_instance_valid(marker):
		marker.queue_free()
	if gen != room_gen or finished:
		return
	spawning -= 1
	var e: Enemy = ENEMIES[kind].instantiate()
	e.position = pos
	# dalla terza stanza alcune mummie e alcuni sacerdoti sono élite
	var elite_w := Weights.rank("elite")
	if Run.room >= 3 - elite_w and Run.room <= Run.ROOMS_PER_RUN and kind in ["mummy", "priest"] and randf() < minf(0.2, 0.06 + 0.02 * Run.room) * (1 + elite_w):
		e.elite = true
		Music.play("elite")           # una stanza con nemici élite cambia musica fino alla prossima
	world.add_child(e)
	alive += 1
	e.killed.connect(_on_enemy_killed)
	if e.miniboss:
		boss = e
		e.summon.connect(_on_boss_summon)
	if e.is_boss:
		boss = e
		e.summon.connect(_on_boss_summon)
		e.pillar_broken.connect(_on_pillar_broken)


func _on_enemy_killed(e: Enemy) -> void:
	alive -= 1
	if Run.room > Run.ROOMS_PER_RUN:
		if e.is_boss:
			_boss_defeated.call_deferred()
		return
	if e == boss and e.miniboss:
		boss_bar.visible = false
		for c in world.get_children():
			if c is Enemy and not c.dead:
				c.die()                   # caduto il guardiano, i suoi scarabei si dissolvono
	if alive > 0 or spawning > 0:
		return
	if not waves.is_empty():
		_spawn_wave(waves.pop_front(), 0.8)
	else:
		_room_cleared.call_deferred()


func _on_blessing_granted(id: String) -> void:
	var b: Dictionary = Boons.SET_BLESSINGS[id]
	_banner("Set mantiene la promessa", "%s: %s" % [b["name"], b["desc"]], Boons.god_color("set"))
	if player != null and is_instance_valid(player):
		player.max_hp = Run.max_hp
		player.hp = Run.hp
		Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color("set"), 30, 140.0)


func _room_cleared() -> void:
	if cleared:
		return
	cleared = true
	Run.room_cleared()                  # le maledizioni di Set contano le stanze ripulite
	# a stanza ripulita le trappole si fermano
	for trap in get_tree().get_nodes_in_group("traps"):
		trap.set_physics_process(false)
		trap.t = 0.0
		trap.queue_redraw()
	if Run.has("iside_heavy"):
		player.heal(roundf(Run.max_hp * 0.15))
	if Run.has("anubi_canopic"):
		player.heal(Run.val("anubi_canopic"))
	if current_reward.get("kind", "") == "guardian":
		# premio del guardiano: un dono che sale di due livelli invece di uno
		bonus_boon = true
		var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
		if not gods.is_empty():
			current_reward = {"kind": "boon", "god": gods.pick_random()}
			_banner("Il Serpente della Porta è caduto", "Il prossimo dono sale di un livello in più", Color(0.6, 1, 0.5))
		else:
			current_reward = {"kind": "ka"}
	if current_reward.get("kind", "none") == "none":
		_banner("Stanza ripulita", "Scegli una porta: la ricompensa è scritta sopra", Color(0.94, 0.72, 0.3))
		_open_doors()
		return
	var p = PickupScript.new()
	p.kind = current_reward["kind"]
	p.god = current_reward.get("god", "")
	world.add_child(p)
	p.position = _free_spot_near(Vector2(ROOM.size.x / 2.0, ROOM.size.y / 2.0 + 20.0))
	p.collected.connect(_on_pickup_collected)


func _on_pickup_collected(p: Area2D) -> void:
	Sfx.play("pickup", 0.0)
	var kind: String = p.kind
	var god: String = p.god
	Fx.burst(p.global_position + Vector2(0, -10), p.color(), 24, 120.0)
	p.queue_free()
	match kind:
		"ka":
			if tut_step >= 0:
				Run.ka += 10
				Fx.float_text(player.global_position, "+10 Ka", Color(0.94, 0.72, 0.3))
				_tut_next.call_deferred()
				return
			Run.ka += roundi(25 * Run.treasure_mult())
			Fx.float_text(player.global_position, "+%d Ka" % roundi(25 * Run.treasure_mult()), Color(0.94, 0.72, 0.3))
			_open_doors.call_deferred()
		"heal":
			player.heal(roundf(Run.max_hp * Run.nile_heal()))
			_open_doors.call_deferred()
		"boon":
			_show_boon_menu.call_deferred(god)
		"set":
			_show_set_menu.call_deferred()


func _open_doors() -> void:
	if Run.room >= Run.ROOMS_PER_RUN:
		_add_door("n", {"kind": "boss"})
		return
	if Run.room + 1 == Run.GUARDIAN_ROOM:
		_add_door("n", {"kind": "guardian"})
		return
	var sides: Array = [["w", "n", "e"], ["w", "e"], ["w", "n"], ["n", "e"]].pick_random()
	var pool := []
	var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
	gods.shuffle()
	for g in gods.slice(0, 2):
		pool.append({"kind": "boon", "god": g})
	pool.append({"kind": "ka"})
	pool.append({"kind": "heal"})
	pool.shuffle()
	# a volte Set apre una sua porta: prende il posto di una delle altre
	if randf() < SET_DOOR_CHANCE and not Boons.set_offers(Run.blessings).is_empty():
		pool.insert(0, {"kind": "set"})
	# il Traghettatore: sempre dopo il guardiano, a volte nelle altre stanze (mai prima di Ammit)
	var shop_ok: bool = shops_visited < 2 and Run.room + 1 < Run.ROOMS_PER_RUN and Run.room >= 2 and current_reward.get("kind", "") != "shop"
	if shop_ok and (Run.room == Run.GUARDIAN_ROOM or randf() < SHOP_CHANCE):
		pool.insert(0, {"kind": "shop"})
	# prima del boss c'è sempre una porta che cura, insieme alle altre scelte
	if Run.room + 1 == Run.ROOMS_PER_RUN:
		sides = ["w", "n", "e"]
		pool.erase({"kind": "heal"})
		pool.insert(0, {"kind": "heal"})
	for i in range(sides.size()):
		_add_door(sides[i], pool[i % pool.size()])


func _add_door(side: String, reward: Dictionary) -> void:
	var d = DoorScript.new()
	d.side = side
	d.reward = reward
	d.open = true
	match side:
		"n":
			d.position = Vector2(ROOM.size.x / 2.0, TOP + 2.0)
		"w":
			d.position = Vector2(WALL + 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
		"e":
			d.position = Vector2(ROOM.size.x - WALL - 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
	world.add_child(d)
	d.chosen.connect(_on_door_chosen)
	doors.append(d)


func _on_door_chosen(d: Area2D) -> void:
	Sfx.play("door")
	var kind: String = d.reward["kind"]
	if kind == "boss":
		start_room.call_deferred({"kind": "none"})
		return
	if kind == "set":
		# il tributo di Set: 10 punti vita, ma non può ucciderti
		Run.hp = maxf(1.0, Run.hp - SET_DOOR_COST)
	start_room.call_deferred(d.reward)


# ---------------------------------------------------------------- scelta dei doni

## Finestra di scelta: in alto il dio che parla (ritratto animato e testo che appare),
## sotto 1-3 carte di papiro. Ogni carta: etichetta, nome, descrizione, prezzo e, in fondo,
## il riassunto breve (▲ vantaggio, ▼ prezzo) per scegliere senza rileggere tutto.
## `cards` = [{"tag", "name", "body", "cost", "gain", "loss", "color", "heavy", "on_pick"}].
func _open_choice(title_text: String, title_color: Color, subtitle: String, cards: Array, speech: String = "", god: String = "") -> void:
	get_tree().paused = true
	menu = CanvasLayer.new()
	menu.layer = 20
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)
	var vw := get_viewport().get_visible_rect().size.x

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(6 * Fx.ui))
	menu.add_child(box)

	# il dio che parla
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", int(10 * Fx.ui))
	box.add_child(head)
	if god != "":
		var portrait := GodPortrait.new()
		portrait.god = god
		portrait.custom_minimum_size = Vector2(66, 66) if Fx.mobile else Vector2(84, 84) * Fx.ui
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(portrait)
		var stop := get_tree().create_timer(maxf(1.2, speech.length() * 0.025), true, false, true)
		var ref: WeakRef = weakref(portrait)
		stop.timeout.connect(func() -> void:
			var pp = ref.get_ref()
			if pp != null:
				pp.talking = false)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", int(2 * Fx.ui))
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(words)
	var title := UiStyle.heading(title_text, 15, title_color)
	words.add_child(title)
	if speech != "":
		var said := UiStyle.label("«%s»" % speech, 8 if Fx.mobile else 10, title_color.lerp(Color(0.97, 0.93, 0.85), 0.65), false, vw - (66.0 if Fx.mobile else 84.0 * Fx.ui) - 70.0)
		said.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		said.add_theme_constant_override("outline_size", 3)
		said.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
		said.visible_ratio = 0.0
		words.add_child(said)
		var tw := said.create_tween()
		tw.tween_property(said, "visible_ratio", 1.0, clampf(speech.length() * 0.012, 0.4, 1.6))
	if subtitle != "":
		var sub := UiStyle.label(subtitle, 9, Color(0.9, 0.8, 0.6))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(8 * Fx.ui))
	box.add_child(row)

	var card_w := minf(250.0, (vw - 40.0) / 3.0)
	var first_button: Button = null
	var i := 0
	for c in cards:
		var btn := _make_card(c, card_w)
		row.add_child(btn)
		btn.pressed.connect(c["on_pick"])
		btn.focus_entered.connect(Sfx.play.bind("ui", 0.0))
		# la carta scelta si solleva un poco; le altre tornano giù
		btn.focus_entered.connect(func() -> void:
			btn.pivot_offset = btn.size / 2.0
			btn.create_tween().tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12))
		btn.focus_exited.connect(func() -> void:
			btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12))
		btn.mouse_entered.connect(btn.grab_focus)
		# le carte si srotolano una dopo l'altra
		btn.modulate.a = 0.0
		btn.scale = Vector2(1.0, 0.85)
		var tw2 := btn.create_tween()
		tw2.tween_interval(0.08 * i)
		tw2.tween_property(btn, "modulate:a", 1.0, 0.18)
		tw2.parallel().tween_property(btn, "scale", Vector2.ONE, 0.18)
		i += 1
		if first_button == null:
			first_button = btn
	first_button.grab_focus()


## Una carta di papiro. Il testo completo resta anche nei metadati (lo usa il bot di playtest).
func _make_card(c: Dictionary, card_w: float) -> Button:
	var accent: Color = c["color"]
	var btn := Button.new()
	UiStyle.papyrus_button(btn, accent)
	btn.custom_minimum_size = Vector2(card_w, 0)
	btn.pivot_offset = Vector2(card_w / 2.0, 0)
	btn.set_meta("text", "%s\n%s\n%s\n%s\n%s\n%s" % [c.get("tag", ""), c["name"], c.get("body", ""), c.get("cost", ""), c.get("gain", ""), c.get("loss", "")])
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
	# riassunto in fondo
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	if c.get("gain", "") != "":
		var g := UiStyle.label("▲ " + c["gain"], 9, UiStyle.INK_GREEN, true, inner)
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(g)
	if c.get("loss", "") != "":
		var l := UiStyle.label("▼ " + c["loss"], 9, UiStyle.INK_RED, true, inner)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	# l'altezza giusta si conosce solo dopo che il testo è andato a capo
	var fit := func() -> void:
		if is_instance_valid(btn) and is_instance_valid(col):
			btn.custom_minimum_size.y = col.get_combined_minimum_size().y + 16.0 * Fx.ui
	col.minimum_size_changed.connect(fit)
	fit.call_deferred()
	return btn


func _close_choice() -> void:
	if menu != null:
		menu.queue_free()
		menu = null
	get_tree().paused = false


func _show_boon_menu(god: String, then_doors: bool = true) -> void:
	doors_after_boon = then_doors
	var options := Boons.offers(god, Run.boons)
	var from_god := god
	if options.is_empty():
		var others := Boons.gods_with_boons(Run.boons, Run.room)
		if not others.is_empty():
			from_god = others.pick_random()
			options = Boons.offers(from_god, Run.boons)
	if options.is_empty():
		# tutti i doni sono già al massimo: al posto del dono arriva un tesoro di Ka
		var bonus := roundi(25 * Run.ka_mult())
		Run.ka += bonus
		bonus_boon = false
		Fx.float_text(player.global_position, "+%d Ka" % bonus, Color(0.94, 0.72, 0.3))
		if then_doors:
			_open_doors()
		return

	var duos := Boons.duos_for(from_god, Run.boons)
	if not duos.is_empty() and randf() < Boons.DUO_CHANCE:
		if options.size() >= 3:
			options[2] = duos.pick_random()
		else:
			options.append(duos.pick_random())
	if Weights.rank("silenzio") > 0 and options.size() > 2:
		options.resize(2)             # Peso del Cuore: il silenzio degli dèi
	var cards := []
	for id in options:
		var lvl := mini(Run.level(id) + (2 if bonus_boon else 1), _max_level(id))
		var tag := "Nuovo" if Run.level(id) == 0 else "Livello %d" % lvl
		if Run.level(id) == 0 and lvl > 1:
			tag = "Nuovo · subito livello %d" % lvl
		if Boons.is_heavy(id):
			tag = "Dono pesante"
		if Boons.is_duo(id):
			var gs: Array = Boons.ALL[id]["gods"]
			tag = "Dono doppio · %s + %s" % [Boons.god_name(gs[0]), Boons.god_name(gs[1])]
		var sh := Boons.short(id, lvl)
		cards.append({
			"tag": tag, "name": Boons.ALL[id]["name"], "body": Boons.text(id, lvl),
			"cost": Boons.ALL[id]["cost"] if Boons.has_cost(id) else "",
			"gain": sh[0], "loss": sh[1],
			"color": Boons.god_color("duo") if Boons.is_duo(id) else Boons.god_color(from_god),
			"heavy": Boons.is_heavy(id),
			"on_pick": _choose_boon.bind(id),
		})
	_open_choice("%s ti offre un dono" % Boons.god_name(from_god), Boons.god_color(from_god), "", cards, Lore.speech(from_god), from_god)


## All'inizio di ogni run Anubi offre uno dei suoi doni.
func _show_anubi_menu() -> void:
	var cards := []
	for id in Boons.offers("anubi", Run.boons):
		var sh := Boons.short(id, 1)
		cards.append({
			"tag": "Dono di Anubi", "name": Boons.ALL[id]["name"], "body": Boons.text(id, 1),
			"cost": Boons.ALL[id]["cost"], "gain": sh[0], "loss": sh[1],
			"color": Boons.god_color("anubi"), "heavy": false,
			"on_pick": _choose_start_boon.bind(id),
		})
	_open_choice("Anubi pesa il tuo cuore", Boons.god_color("anubi"), "", cards, Lore.speech("anubi"), "anubi")


func _choose_start_boon(id: String) -> void:
	Run.add_boon(id)
	Run.save_descent(current_reward, {"shops": shops_visited, "bonus": bonus_boon})
	_close_choice()
	player.max_hp = Run.max_hp
	player.hp = Run.hp
	_boon_fx(Boons.god_color("anubi"), "Dono di Anubi", Boons.ALL[id]["name"])


func _max_level(id: String) -> int:
	return Boons.MAX_LEVEL if Boons.ALL[id].has("values") else 1


func _choose_boon(id: String) -> void:
	Run.add_boon(id)
	if bonus_boon and Run.level(id) < _max_level(id):
		Run.add_boon(id)
	bonus_boon = false
	_close_choice()
	var g: String = Boons.ALL[id]["god"]
	var lvl := Run.level(id)
	_boon_fx(Boons.god_color(g), "Dono di %s" % Boons.god_name(g) if g != "duo" else "Dono doppio", Boons.ALL[id]["name"] + ("" if lvl <= 1 else "  ·  livello %d" % lvl))
	if doors_after_boon:
		_open_doors()


## L'effetto quando prendi un dono: lampo del colore del dio, anello di luce attorno a te,
## un attimo di rallentamento e il nome del dono al centro.
func _boon_fx(color: Color, title: String, sub: String) -> void:
	Sfx.play("boon", 0.0)
	Sfx.play("divine", 0.05)
	var flash := ColorRect.new()
	flash.color = Color(color, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.6)
	tw.tween_callback(flash.queue_free)
	if player != null and is_instance_valid(player):
		var ring := BoonRing.new()
		ring.color = color
		world.add_child(ring)
		ring.global_position = player.global_position + Vector2(0, -8)
		Fx.burst(player.global_position + Vector2(0, -10), color, 60, 220.0)
		Fx.burst(player.global_position + Vector2(0, -10), Color(1, 0.95, 0.8), 20, 120.0)
	Fx.shake(5.0)
	Fx.hitstop(0.12)
	_banner(title, sub, color)


func _show_set_menu() -> void:
	var cards := []
	for o in Boons.set_offers(Run.blessings):
		var curse: Dictionary = Boons.SET_CURSES[o["curse"]]
		var bless: Dictionary = Boons.SET_BLESSINGS[o["blessing"]]
		cards.append({
			"tag": "Patto di Set", "name": bless["name"],
			"body": "",
			"cost": "",
			"gain": bless["desc"], "loss": "%s (%d stanze)" % [curse["desc"], curse["rooms"]],
			"color": Boons.god_color("set"), "heavy": true,
			"on_pick": _choose_pact.bind(o["curse"], o["blessing"]),
		})
	if cards.is_empty():
		Run.ka += roundi(25 * Run.ka_mult())
		_open_doors()
		return
	var sub := "Prima la maledizione, per le prossime stanze ripulite. Poi il potere, per tutta la discesa"
	if Run.room + 2 > Run.ROOMS_PER_RUN:
		sub = "Attenzione: la maledizione ti seguirà anche contro Ammit"
	_open_choice("Set ti propone un patto", Boons.god_color("set"), sub, cards, Lore.speech("set"), "set")


func _choose_pact(curse: String, blessing: String) -> void:
	Run.add_pact(curse, blessing)
	_close_choice()
	_boon_fx(Boons.god_color("set"), "Patto di Set", Boons.SET_CURSES[curse]["desc"])
	_open_doors()


## Quanti caratteri per riga stanno in una carta, in base alla larghezza dello schermo e ai caratteri.
func _wrap_w() -> int:
	var card_w := minf(250.0, (get_viewport().get_visible_rect().size.x - 50.0) / 3.0)
	return clampi(int(card_w / (5.6 * Fx.ui)), 20, 34)


func _wrap(text: String, width: int) -> String:
	var out := ""
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() + 1 > width and line != "":
			out += line + "\n"
			line = word
		else:
			line = word if line == "" else line + " " + word
	return out + line


func _banner(title: String, sub: String, color: Color) -> void:
	if banner.material == null:
		banner.add_theme_font_override("font", UiStyle.deco_font())
		UiStyle.shimmer(banner, 0.6)
	banner.text = "%s\n%s" % [title, sub]
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 1.0
	var tw := banner.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(banner, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- pausa (Esc / Start)

func _toggle_pause() -> void:
	if pause_menu != null:
		Meta.save()
		pause_menu.queue_free()
		pause_menu = null
		# se era aperta una scelta dei doni, il gioco resta fermo su quella
		get_tree().paused = menu != null or panel != null
		return
	if player == null or player.dead:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reticle.visible = false
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 30
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.position = Vector2(-80, -70) * Fx.ui
	box.custom_minimum_size = Vector2(160, 140) * Fx.ui
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Fx.fs(18))
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Button = null
	for entry in [["Riprendi", _toggle_pause], ["Volume", _show_audio_menu], ["Ricomincia la run", _restart_run], ["Torna alla Sala (abbandona)", _abandon_run], ["Esci (la discesa resta salvata)", _quit_game]]:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(160, 26) * Fx.ui
		b.add_theme_font_size_override("font_size", Fx.fs(11))
		b.pressed.connect(entry[1])
		box.add_child(b)
		if first == null:
			first = b
	var hint := Label.new()
	hint.text = "Esc / Start per riprendere"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", Fx.fs(8))
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	box.add_child(hint)
	first.grab_focus()
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)   # centrato davvero, anche con i testi grandi


## Pagina del volume dentro il menu di pausa: un cursore per ogni categoria di suoni.
## Col pad: su e giù per scegliere, sinistra e destra per regolare.
func _show_audio_menu() -> void:
	if pause_menu == null:
		return
	var old := pause_menu.get_node_or_null("Audio")
	if old != null:
		old.queue_free()
	for c in pause_menu.get_children():
		if c is VBoxContainer:
			c.visible = false
	var box := VBoxContainer.new()
	box.name = "Audio"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-130, -120) * Fx.ui
	box.custom_minimum_size = Vector2(260, 240) * Fx.ui
	box.add_theme_constant_override("separation", 4)
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Volume"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Fx.fs(16))
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Control = null
	for c in Sfx.CATEGORIES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = c[1]
		name_label.custom_minimum_size = Vector2(110, 0) * Fx.ui
		name_label.add_theme_font_size_override("font_size", Fx.fs(9))
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sfx.volumes.get(c[0], 1.0)
		slider.custom_minimum_size = Vector2(100, 14) * Fx.ui
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(slider.value * 100.0)
		pct.custom_minimum_size = Vector2(32, 0) * Fx.ui
		pct.add_theme_font_size_override("font_size", Fx.fs(9))
		row.add_child(pct)
		slider.value_changed.connect(_on_volume_changed.bind(c[0], pct))
		if first == null:
			first = slider
	var back := Button.new()
	back.text = "Indietro"
	back.add_theme_font_size_override("font_size", Fx.fs(11))
	back.pressed.connect(_close_audio_menu)
	box.add_child(back)
	first.grab_focus()
	box.add_theme_constant_override("separation", 3)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _on_volume_changed(value: float, category: String, pct: Label) -> void:
	Sfx.set_volume(category, value)
	pct.text = "%d%%" % roundi(value * 100.0)
	# un suono di prova della categoria, così senti subito il risultato
	for s in Sfx.SOUNDS:
		if category == "generale" or Sfx.SOUNDS[s][1] == category:
			Sfx.play(s, 0.0)
			break


func _close_audio_menu() -> void:
	Meta.save()
	if pause_menu == null:
		return
	var audio := pause_menu.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	for c in pause_menu.get_children():
		if c is VBoxContainer and c.name != "Audio":
			c.visible = true
			for b in c.get_children():
				if b is Button:
					b.grab_focus()
					break


## Abbandonare conta come una morte: il Ka raccolto viene custodito lo stesso.
func _abandon_run() -> void:
	Run.clear_descent()
	Meta.last_end = "abandon"
	Meta.last_room = Run.room
	_end_run_summary()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


func _restart_run() -> void:
	Run.clear_descent()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Uscire a metà discesa non la perde: è salvata all'inizio della stanza e riprende al prossimo avvio.
func _quit_game() -> void:
	Meta.save()
	get_tree().quit()


# ---------------------------------------------------------------- menu dei doni (Tab)

func _toggle_boons_panel() -> void:
	if menu != null or finished or pause_menu != null:
		return
	if panel != null:
		panel.queue_free()
		panel = null
		get_tree().paused = false
		return
	get_tree().paused = true
	panel = CanvasLayer.new()
	panel.layer = 20
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panel)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 40
	label.offset_top = 24
	label.offset_right = -40
	label.offset_bottom = -24
	label.add_theme_font_size_override("normal_font_size", 9)
	label.add_theme_font_size_override("bold_font_size", 10)
	panel.add_child(label)
	label.text = _boons_text()


func _boons_text() -> String:
	var t := "[center][b][color=#f0b94c]I tuoi doni[/color][/b]   [color=#a89878](Tab o Select per chiudere)[/color][/center]\n\n"
	if Run.boons.is_empty() and Run.blessings.is_empty() and Run.curses.is_empty():
		t += "[center]Nessun dono, per ora. Ripulisci una stanza e scegline uno.[/center]"
		return t
	for id in Run.boons:
		var b: Dictionary = Boons.ALL[id]
		var col: String = Boons.god_color(b["god"]).to_html(false)
		var lvl := "pesante" if Boons.is_heavy(id) else ("bilancia" if Boons.ALL[id].get("balanced", false) else ("doppio" if Boons.is_duo(id) else "liv. %d" % Run.boons[id]))
		t += "[color=#%s][b]%s[/b] · %s · %s[/color]\n%s" % [col, Boons.god_name(b["god"]), b["name"], lvl, Boons.text(id, Run.boons[id])]
		if Boons.has_cost(id):
			t += " [color=#ff9c8c]Prezzo: %s[/color]" % b["cost"]
		t += "\n\n"
	var set_col: String = Boons.god_color("set").to_html(false)
	for c in Run.curses:
		t += "[color=#%s][b]Maledizione di Set[/b] · ancora %d stanze[/color]\n%s. Poi: %s\n\n" % [set_col, c["rooms"], Boons.SET_CURSES[c["curse"]]["desc"], Boons.SET_BLESSINGS[c["blessing"]]["desc"]]
	for b in Run.blessings:
		t += "[color=#%s][b]Set[/b] · %s · permanente[/color]\n%s\n\n" % [set_col, Boons.SET_BLESSINGS[b]["name"], Boons.SET_BLESSINGS[b]["desc"]]
	return t


# ---------------------------------------------------------------- fine run

func _on_player_died() -> void:
	finished = true
	can_leave = false
	Run.clear_descent()
	var where := "Ammit, la Divoratrice" if Run.room > Run.ROOMS_PER_RUN else "stanza %d di %d" % [Run.room, Run.ROOMS_PER_RUN]
	if current_reward.get("kind", "") == "guardian":
		where = "il Serpente della Porta"
	Meta.last_end = "ammit" if Run.room > Run.ROOMS_PER_RUN else "room"
	if Meta.feather:
		Meta.feather_deaths += 1
	Meta.last_room = Run.room
	var killer: String = KILLER_NAMES.get(Run.last_hit, "")
	var summary := _end_run_summary()
	boss_bar.visible = false
	Music.play("death")
	_death_screen(where, killer, summary)


## La morte: tutto rallenta, un lampo rosso, lo schermo si scurisce e compare la bilancia
## di Ma'at: il cuore scende, più pesante della piuma. Poi il papiro con il riepilogo.
func _death_screen(where: String, killer: String, summary: String) -> void:
	Sfx.play("death", 0.0)
	Fx.shake(8.0)
	Engine.time_scale = 0.2
	var layer := CanvasLayer.new()
	layer.layer = 18
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var red := ColorRect.new()
	red.color = Color(0.8, 0.05, 0.03, 0.55)
	red.set_anchors_preset(Control.PRESET_FULL_RECT)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(red)
	var dark := ColorRect.new()
	dark.color = Color(0.02, 0.01, 0.03, 0.0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dark)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(red, "color:a", 0.0, 0.9)
	tw.parallel().tween_property(dark, "color:a", 0.88, 1.6)
	tw.parallel().tween_property(Engine, "time_scale", 1.0, 1.6).set_delay(0.6)
	tw.tween_callback(func() -> void:
		get_tree().paused = true
		_death_panel(layer, where, killer, summary))


func _death_panel(layer: CanvasLayer, where: String, killer: String, summary: String) -> void:
	var u := Fx.ui
	var vs := get_viewport().get_visible_rect().size
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(4 * u))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	var scale_draw := DeathScale.new()
	scale_draw.custom_minimum_size = Vector2(120, 70) * u
	scale_draw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(scale_draw)
	var title := UiStyle.heading("Il tuo cuore è stato pesato", 18, Color(0.95, 0.4, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.45, 0.12, 0.08)))
	pap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(3 * u))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pap.add_child(col)
	var w := minf(440.0 * u, vs.x - 40.0)
	var l1 := UiStyle.label("Sei caduto: " + where, 10, UiStyle.INK, true, w)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l1)
	if killer != "":
		var l2 := UiStyle.label("Ti ha ucciso " + killer, 9, UiStyle.INK_RED, false, w)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l2)
	var l3 := UiStyle.label(summary, 8, UiStyle.INK_SOFT, false, w)
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l3)
	var how := "Tocca lo schermo" if Fx.device == "touch" else ("Premi Start" if Fx.device == "pad" else "Premi R")
	var hint := UiStyle.label("%s per tornare alla Sala del Giudizio" % how, 9, Color(0.95, 0.85, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override("outline_size", 3)
	box.add_child(hint)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.8)
	tw.tween_callback(func() -> void: can_leave = true)
	var blink := hint.create_tween().set_loops()
	blink.tween_property(hint, "modulate:a", 0.4, 0.9).set_delay(1.0)
	blink.tween_property(hint, "modulate:a", 1.0, 0.9)


# ---------------------------------------------------------------- boss

func _start_boss() -> void:
	Music.play("boss")
	boss_name.text = "AMMIT, LA DIVORATRICE"
	boss_fill.color = Color(0.85, 0.2, 0.15)
	Sfx.play("roar", 0.0)
	_banner("Ammit, la Divoratrice", "Divora i cuori che non superano il giudizio", Color(0.9, 0.35, 0.25))
	boss_bar.visible = true
	boss_fill.size.x = boss_bar.size.x
	spawning += 1
	_spawn_after("ammit", Vector2(ROOM.size.x / 2.0, TOP + 120.0), 1.6)


## Stanza 5: il Serpente della Porta.
func _start_guardian() -> void:
	Music.play("elite")
	Sfx.play("roar", 0.15)
	_banner("Il Serpente della Porta", "Ogni porta del Duat ha il suo guardiano", Color(0.5, 0.95, 0.45))
	boss_name.text = "IL SERPENTE DELLA PORTA"
	boss_fill.color = Color(0.35, 0.8, 0.3)
	boss_bar.visible = true
	boss_fill.size.x = boss_bar.size.x
	spawning += 1
	_spawn_after("serpent", Vector2(ROOM.size.x / 2.0, TOP + 110.0), 1.4)


## La stanza del Traghettatore: niente nemici, tre oggetti da comprare con il Ka della discesa.
func _start_shop() -> void:
	shops_visited += 1
	cleared = true
	var cx := ROOM.size.x / 2.0
	var mid_y := (TOP + ROOM.size.y - WALL) / 2.0
	var boat := FerrymanScript.new()
	boat.position = Vector2(cx, mid_y - 50.0)
	world.add_child(boat)
	_banner("Il Traghettatore", FerrymanScript.LINES.pick_random().split(": ", true, 1)[1], Color(0.6, 0.85, 0.95))
	var items := SHOP_ITEMS.duplicate()
	if _upgradable().is_empty():
		items = items.filter(func(it: Dictionary) -> bool: return it["kind"] != "upgrade")
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var node := FerrymanScript.ShopItem.new()
		node.kind = it["kind"]
		node.title = it["title"]
		node.desc = it["desc"]
		node.price = it["price"]
		node.position = Vector2(cx + (i - (items.size() - 1) / 2.0) * 90.0, mid_y + 50.0)
		world.add_child(node)
		shop_items.append(node)
	_open_doors()


## Doni che possono ancora salire di livello (per l'Inchiostro di Thoth).
func _upgradable() -> Array:
	var out := []
	for id in Run.boons:
		if Boons.ALL[id].get("god", "") in ["anubi", "duo"]:
			continue
		if Run.level(id) < _max_level(id):
			out.append(id)
	return out


func _buy(item) -> void:
	if item.sold:
		return
	if Run.ka < item.price:
		Fx.float_text(player.global_position + Vector2(0, -20), "Non hai abbastanza Ka", Color(0.9, 0.4, 0.35))
		Fx.shake(2.0)
		return
	Run.ka -= item.price
	item.sold = true
	Sfx.play("pickup", 0.0)
	Fx.burst(item.global_position + Vector2(0, -20), item.color(), 24, 110.0)
	match item.kind:
		"heal":
			player.heal(roundf(Run.max_hp * 0.3))
		"boon":
			var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
			if not gods.is_empty():
				_show_boon_menu.call_deferred(gods.pick_random(), false)
		"upgrade":
			var ups := _upgradable()
			if not ups.is_empty():
				var id: String = ups.pick_random()
				Run.add_boon(id)
				_banner("Inchiostro di Thoth", "%s sale al livello %d" % [Boons.ALL[id]["name"], Run.level(id)], Boons.god_color("thoth"))


## Seconda fase: Ammit chiama uno sciame di scarabei.
func _on_boss_summon(kinds: Array) -> void:
	for i in range(kinds.size()):
		spawning += 1
		_spawn_after(kinds[i], _free_spot(), 0.8 + i * 0.15)


## Ammit ha sbattuto contro una colonna: la colonna crolla.
func _on_pillar_broken(body: StaticBody2D) -> void:
	var best := -1
	var best_d := 1e9
	for i in range(pillars.size()):
		var d: float = pillars[i].distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		var p: Vector2 = pillars[best]
		pillars.remove_at(best)
		Fx.burst(p + Vector2(0, -24), Color(0.77, 0.6, 0.39), 40, 180.0)
		Fx.float_text(p + Vector2(0, -40), "La colonna crolla", Color(0.95, 0.85, 0.65))
	body.queue_free()
	queue_redraw()


func _boss_defeated() -> void:
	boss_bar.visible = false
	Fx.shake(12.0)
	for c in world.get_children():
		if c is Enemy and not c.dead:
			c.die()
	Meta.ammit_wins += 1
	if Weights.unlocked() and not Meta.feather and Weights.total() > Meta.best_weight:
		Meta.best_weight = Weights.total()
	var first_win := not Meta.sekhem_unlocked
	Meta.sekhem_unlocked = true
	Meta.save()
	if first_win:
		_banner("Ammit ti cede il suo Sekhem", "Dalla prossima discesa potrai caricare la Forma Divina", Color(1, 0.85, 0.4))
	else:
		_banner("Ammit è caduta", "Il primo cancello del Duat si apre", Color(0.94, 0.72, 0.3))
	await get_tree().create_timer(2.0).timeout
	_victory()


## Bordi dello schermo più scuri: dà l'idea di una tomba illuminata dalle torce.
func _build_vignette() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0.02, 0.01, 0.02, 0.55))
	grad.add_point(0.6, Color(0, 0, 0, 0.05))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(rect)
	$UI.move_child(rect, 0)


func _build_boss_bar() -> void:
	var ui: CanvasLayer = $UI
	boss_name = Label.new()
	boss_name.text = "AMMIT, LA DIVORATRICE"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", Fx.fs(9))
	boss_name.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_name.add_theme_constant_override("outline_size", 4)
	boss_name.position = Vector2(170, 318)
	boss_name.size = Vector2(300, 12)
	boss_bar = ColorRect.new()
	boss_bar.color = Color(0.1, 0.02, 0.02, 0.85)
	# in basso al centro: in alto copriva la stanza (sul telefono più stretta, tra levetta e pulsanti)
	var bw := 250.0 if Fx.mobile else 300.0
	boss_bar.size = Vector2(bw, 6)
	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.85, 0.2, 0.15)
	boss_fill.size = Vector2(bw, 6)
	boss_bar.add_child(boss_fill)
	boss_bar.add_child(boss_name)
	boss_name.position = Vector2(0, -15)
	boss_name.size = Vector2(bw, 12)
	boss_name.add_theme_font_override("font", UiStyle.title_font())
	ui.add_child(boss_bar)
	boss_bar.visible = false


## Riepilogo della discesa. Salva anche il Ka raccolto, che resta tra una run e l'altra.
func _end_run_summary() -> String:
	var banked := roundi(Run.ka * Weights.ka_mult() * (FEATHER_KA if Meta.feather else 1.0))
	Meta.ka_bank += banked
	Meta.last_killer = Run.last_hit
	Meta.last_pacts = Run.blessings.size()
	var count := {}
	for id in Run.boons:
		var g: String = Boons.ALL[id].get("god", "")
		if g != "" and g != "anubi" and g != "duo":
			count[g] = int(count.get(g, 0)) + 1
	Meta.last_god = ""
	for g in count:
		if Meta.last_god == "" or count[g] > count[Meta.last_god]:
			Meta.last_god = g
	Meta.runs += 1
	Meta.save()
	var secs := int((Time.get_ticks_msec() - Run.start_msec) / 1000.0)
	var lines := [
		"Tempo %d:%02d   ·   Nemici abbattuti %d   ·   Danni inflitti %d" % [floori(secs / 60.0), secs % 60, Run.kills, int(Run.damage_dealt)],
		"Doni raccolti %d   ·   Ka raccolto %d%s   ·   Ka custodito %d" % [Run.boons.size() + Run.blessings.size(), banked, "" if Weights.total() == 0 else " (Peso del Cuore +%d%%)" % int(round((Weights.ka_mult() - 1.0) * 100.0)), Meta.ka_bank],
	]
	return "\n".join(lines)


func _victory() -> void:
	finished = true
	Run.clear_descent()
	Music.play("hub")
	for c in world.get_children():
		if c is Enemy:
			c.queue_free()
	message.visible = true
	var extra := "\nNuovi poteri: il Sekhem e la Forma Divina (Q / LT), e un posto in più nel Libro dei Morti" if Meta.ammit_wins == 1 else ""
	Meta.last_end = "win"
	message.text = "Hai sconfitto Ammit!\nLa Prima Ora è superata.%s\n\n%s\n\nPremi R (o Start, o tocca lo schermo) per tornare alla Sala del Giudizio" % [extra, _end_run_summary()]


# ---------------------------------------------------------------- ogni frame

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_hitbox"):
		Fx.set_hitboxes(not Fx.show_hitboxes)
	if Input.is_action_just_pressed("restart") and (finished or player.dead) and can_leave:
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/hub.tscn")
		return
	if player == null or not is_instance_valid(player):
		return

	var eye_txt := "pronto" if player.eye_ready() else "%.1fs" % player.eye_cd
	var sek := "PRONTO (Q / LT)" if Run.sekhem_ready() else "%d%%" % int(Run.sekhem)
	if player.divine_t > 0.0:
		sek = "FORMA DIVINA %.1fs" % player.divine_t
	var room_txt := "Ammit · colonne: %d" % pillars.size() if Run.room > Run.ROOMS_PER_RUN else "Stanza %d/%d" % [Run.room, Run.ROOMS_PER_RUN]
	if tut_step >= 0:
		room_txt = "Addestramento"
		_tut_tick()
	# vita, Ka, stanza, Occhio e Sekhem sono disegnati come barre da HudBars; qui resta il testo
	hud.text = ""
	hud_room = room_txt
	hud_eye = eye_txt
	hud_sek = sek
	if Meta.feather:
		hud.text = "Piuma di Ma'at: -%d%% danni" % int(round(Run.feather_guard() * 100.0))
	if boss != null and is_instance_valid(boss) and not boss.dead:
		boss_fill.size.x = boss_bar.size.x * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	var n := Run.boons.size() + Run.blessings.size()
	var line2 := ""
	if n > 0:
		line2 = ("Doni: %d" % n) if Fx.device == "touch" else "Doni: %d (Tab per vederli)" % n
	for c in Run.curses:
		line2 += "    Maledizione: %s (ancora %d stanze)" % [Boons.SET_CURSES[c["curse"]]["desc"], c["rooms"]]
	if line2 != "":
		hud.text += ("\n" if hud.text != "" else "") + line2.strip_edges()
	var vsz := get_viewport().get_visible_rect().size
	boss_bar.position = Vector2((vsz.x - boss_bar.size.x) / 2.0, vsz.y - (12.0 if Fx.mobile else 30.0))

	var near := ""
	var shop_near = null
	for it in shop_items:
		if is_instance_valid(it) and not it.sold and player.global_position.distance_to(it.global_position) < 26.0:
			shop_near = it
	if shop_near != null:
		near = "%s · %s: %s (%d Ka, ne hai %d)" % ["Y" if Fx.device == "pad" else "E", shop_near.title, shop_near.desc, shop_near.price, Run.ka]
		if Input.is_action_just_pressed("interact") and menu == null:
			_buy(shop_near)
	for d in doors:
		if is_instance_valid(d) and d.open and player.global_position.distance_to(d.global_position) < 70.0:
			near = d.reward_description()
	prompt.text = near
	prompt.visible = near != ""

	var mouse := Fx.device == "mouse"
	reticle.visible = mouse and not player.dead and menu == null and panel == null and pause_menu == null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if (mouse and menu == null and panel == null and pause_menu == null) else Input.MOUSE_MODE_VISIBLE
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = "Levetta sinistra muovi · destra mira · RB khopesh · RT Occhio · LB/A scatto · LT Forma Divina · Select doni · Start pausa"
	else:
		help.text = "WASD muovi · mouse mira · clic sinistro khopesh · Spazio scatto · clic destro Occhio · Q Forma Divina (dopo Ammit) · Tab doni · Esc pausa · F1 hitbox"


# ---------------------------------------------------------------- muri e pavimento

func _free_spot() -> Vector2:
	var p := Vector2.ZERO
	for i in range(50):
		p = Vector2(randf_range(WALL + 30.0, ROOM.size.x - WALL - 30.0), randf_range(TOP + 30.0, ROOM.size.y - WALL - 30.0))
		if _spot_ok(p) and (player == null or p.distance_to(player.global_position) > 160.0):
			break
	return p


func _free_spot_near(center: Vector2) -> Vector2:
	var p := center
	for i in range(30):
		if _spot_ok(p):
			return p
		p = center + Vector2(randf_range(-80.0, 80.0), randf_range(-50.0, 50.0))
	return p


func _spot_ok(p: Vector2) -> bool:
	for pl in pillars:
		if p.distance_to(pl) < 36.0:
			return false
	for r in obstacles:
		if (r as Rect2).grow(14.0).has_point(p):
			return false
	for tp in traps_pos:
		if p.distance_to(tp) < 26.0:
			return false
	return true


## Trappole da piramide: lastre con spuntoni e, più avanti, feritoie che sparano dardi.
func _place_traps() -> void:
	var cx := ROOM.size.x / 2.0
	var mid_y := (TOP + ROOM.size.y - WALL) / 2.0
	var spikes := clampi(Run.room, 2, 4) + 2 * Weights.rank("sabbie")
	var tries := 0
	while traps_pos.size() < spikes and tries < 80:
		tries += 1
		var gx := randi_range(1, int((ROOM.size.x - WALL * 2.0) / 32.0) - 2)
		var gy := randi_range(1, int((ROOM.size.y - WALL - TOP) / 32.0) - 2)
		var p := Vector2(WALL + 16.0 + gx * 32.0, TOP + 16.0 + gy * 32.0)
		if p.distance_to(Vector2(cx, mid_y + 20.0)) < 70.0:
			continue                      # lì compare la ricompensa
		if p.distance_to(Vector2(cx, ROOM.size.y - WALL - 24.0)) < 100.0:
			continue                      # punto di partenza del giocatore
		if absf(p.x - cx) < 50.0 and p.y < TOP + 70.0:
			continue
		if absf(p.y - mid_y) < 60.0 and (p.x < WALL + 70.0 or p.x > ROOM.size.x - WALL - 70.0):
			continue
		if not _spot_ok(p):
			continue
		traps_pos.append(p)
		var s := Traps.Spikes.new()
		s.t = randf() * 2.0
		world.add_child(s)
		s.position = p
	if Run.room >= TRAPS_FROM_ROOM + 1 - Weights.rank("sabbie"):
		for i in range(randi_range(1, 2)):
			var left := randf() < 0.5
			var y := randf_range(TOP + 40.0, ROOM.size.y - WALL - 40.0)
			if absf(y - mid_y) < 60.0:
				y += 80.0 if y >= mid_y else -80.0
			var d := Traps.DartWall.new()
			d.dir = Vector2.RIGHT if left else Vector2.LEFT
			d.t = randf() * 2.0
			world.add_child(d)
			d.position = Vector2(WALL - 2.0 if left else ROOM.size.x - WALL + 2.0, y)


func _build_walls() -> void:
	var r := ROOM
	_solid(Rect2(r.position.x, r.position.y, r.size.x, TOP))
	_solid(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL))
	_solid(Rect2(r.position.x, r.position.y, WALL, r.size.y))
	_solid(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y))
	for p in pillars:
		_solid(Rect2(p.x - 13.0, p.y - 7.0, 26.0, 14.0)).add_to_group("pillars")


func _solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.position = rect.get_center()
	world.add_child(body)
	return body


func _draw() -> void:
	var r := ROOM
	var tile := 32.0
	var y := TOP
	while y < r.end.y - WALL:
		var x := r.position.x + WALL
		while x < r.end.x - WALL:
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233 + Run.room) * 43758.5453), 1.0)
			draw_rect(Rect2(x + 1, y + 1, tile - 2, tile - 2), Color(0.52, 0.39, 0.24).darkened(n * 0.14))
			x += tile
		y += tile
	var dark := Color(0.19, 0.13, 0.08)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, WALL), dark)
	draw_rect(Rect2(r.position.x, r.position.y + WALL, r.size.x, WALL), Color(0.46, 0.33, 0.2))
	var i := 0
	var fx := r.position.x
	while fx < r.end.x:
		draw_rect(Rect2(fx, r.position.y + WALL + 12, 16, 6), Color(0.25, 0.66, 0.6) if i % 2 == 0 else Color(0.91, 0.69, 0.29))
		fx += 16.0
		i += 1
	draw_rect(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL), dark)
	draw_rect(Rect2(r.position.x, r.position.y, WALL, r.size.y), dark)
	draw_rect(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y), dark)
	draw_rect(Rect2(r.size.x / 2.0 - 18.0, r.end.y - WALL, 36, 14), Color(0.3, 0.22, 0.13))
	for p in pillars:
		draw_rect(Rect2(p.x - 13, p.y - 48, 26, 55), Color(0.77, 0.6, 0.39))
		draw_rect(Rect2(p.x - 15, p.y - 54, 30, 8), Color(0.18, 0.56, 0.5))
		draw_rect(Rect2(p.x - 15, p.y + 3, 30, 5), Color(0.48, 0.35, 0.22))


class SpawnMarker extends Node2D:
	var duration := 0.8
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var k := clampf(t / duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 6.0 + (1.0 - k) * 18.0, 0.0, TAU, 24, Color(1, 0.3, 0.2, 0.4 + 0.5 * k), 2.0)


## Ascolta Tab/Select anche a gioco in pausa, per aprire e chiudere il menu dei doni.
class PanelListener extends Node:
	var game: Node

	func _process(_delta: float) -> void:
		# a gioco in pausa (schermata della morte) il tasto R / Start arriva solo da qui
		if game.finished and game.can_leave and get_tree().paused and Input.is_action_just_pressed("restart"):
			_leave()

	func _leave() -> void:
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _unhandled_input(event: InputEvent) -> void:
		if game.pause_menu != null:
			var on_audio: bool = game.pause_menu.get_node_or_null("Audio") != null
			if on_audio and event.is_action_pressed("ui_cancel") and not event.is_action_pressed("pause"):
				game._close_audio_menu()
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
				game._toggle_pause()
				get_viewport().set_input_as_handled()
			return
		# sul telefono: un tocco chiude il pannello dei doni, e a fine discesa riporta alla Sala
		if event is InputEventScreenTouch and event.pressed:
			if game.panel != null:
				game._toggle_boons_panel()
				get_viewport().set_input_as_handled()
				return
			if game.finished and game.can_leave:
				_leave()
				return
		if event.is_action_pressed("pause") and not game.finished:
			game._toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("boons_menu") or (game.panel != null and event.is_action_pressed("ui_cancel")):
			game._toggle_boons_panel()
			get_viewport().set_input_as_handled()



## HUD in alto a sinistra, in stile egizio: riquadro scuro con il bordo d'oro, l'ankh accanto
## alla vita (con la scia rossa del danno appena subito), il segno del Ka con il suo numero,
## la stanza, e l'Occhio di Horus che si riempie mentre si ricarica (con un pallino per carica).
class HudBars extends Control:
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
		var font := ThemeDB.fallback_font
		var title := UiStyle.title_font()
		var sek: bool = Run.sekhem_unlocked()
		var o := Vector2(6, 6) * u
		var pw := 206.0 * u
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
		# Occhio di Horus
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
class BoonRing extends Node2D:
	var color := Color.WHITE
	var t := 0.0

	func _ready() -> void:
		z_index = 3
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		t += delta
		if t > 0.7:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := t / 0.7
		draw_arc(Vector2.ZERO, 8.0 + 70.0 * k, 0.0, TAU, 48, Color(color, 1.0 - k), 4.0 * (1.0 - k) + 1.0)
		draw_arc(Vector2.ZERO, 4.0 + 40.0 * k, 0.0, TAU, 32, Color(1, 0.95, 0.8, 0.8 * (1.0 - k)), 2.0)
		for i in range(8):
			var a := TAU * i / 8.0 + k
			draw_line(Vector2.from_angle(a) * (10.0 + 30.0 * k), Vector2.from_angle(a) * (20.0 + 60.0 * k), Color(color, 0.7 * (1.0 - k)), 2.0)



## Frecce sul bordo dello schermo verso le porte aperte che non si vedono: con il colore
## e il nome della ricompensa, così si capisce subito che le uscite sono più di una.
class DoorArrows extends Control:
	var game: Node

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var vs := get_viewport().get_visible_rect().size
		var u: float = Fx.ui
		var margin := 22.0 * u
		var inner := Rect2(Vector2(margin, margin + 24.0 * u), vs - Vector2(margin * 2.0, margin * 2.0 + 24.0 * u))
		var font := UiStyle.title_font()
		var fs := Fx.fs(8)
		var bob := sin(Time.get_ticks_msec() / 180.0) * 3.0 * u
		for d in game.doors:
			if not is_instance_valid(d) or not d.open:
				continue
			var sp: Vector2 = d.get_global_transform_with_canvas().origin
			if Rect2(Vector2.ZERO, vs).grow(-8.0).has_point(sp):
				continue
			var center := vs / 2.0
			var dir := (sp - center).normalized()
			# punto sul bordo del rettangolo interno lungo la direzione della porta
			var tx := INF if dir.x == 0.0 else ((inner.end.x if dir.x > 0.0 else inner.position.x) - center.x) / dir.x
			var ty := INF if dir.y == 0.0 else ((inner.end.y if dir.y > 0.0 else inner.position.y) - center.y) / dir.y
			var pos := center + dir * minf(tx, ty) + dir * bob
			var col: Color = d.reward_color()
			var a := dir.angle()
			var r := 9.0 * u
			var tip := pos + Vector2.from_angle(a) * r
			var l := pos + Vector2.from_angle(a + 2.5) * r
			var rr := pos + Vector2.from_angle(a - 2.5) * r
			draw_circle(pos, r + 3.0 * u, Color(0, 0, 0, 0.55))
			draw_colored_polygon(PackedVector2Array([tip, l, pos - Vector2.from_angle(a) * r * 0.3, rr]), col)
			draw_polyline(PackedVector2Array([tip, l, pos - Vector2.from_angle(a) * r * 0.3, rr, tip]), Color(1, 0.95, 0.8), 1.2)
			var txt: String = d.reward_label()
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lp := pos - Vector2.from_angle(a) * (r + 8.0 * u) - Vector2(tw / 2.0, -fs / 3.0)
			lp.x = clampf(lp.x, 4.0, vs.x - tw - 4.0)
			draw_string_outline(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
			draw_string(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.lightened(0.3))



## La bilancia di Ma'at alla morte: il piatto del cuore scende, quello della piuma sale.
class DeathScale extends Control:
	var t := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var s := size.x / 120.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		var gold := Color(0.94, 0.72, 0.3)
		var tilt := clampf(t / 1.6, 0.0, 1.0)
		tilt = 1.0 - pow(1.0 - tilt, 3.0)
		var ang := 0.32 * tilt + sin(t * 2.0) * 0.015 * tilt
		var piv := Vector2(60, 16)
		draw_line(Vector2(60, 16), Vector2(60, 66), gold, 3.0)
		draw_line(Vector2(44, 66), Vector2(76, 66), gold, 3.0)
		draw_circle(piv, 3.0, gold)
		var lft := piv + Vector2(-40, 0).rotated(ang)
		var rgt := piv + Vector2(40, 0).rotated(ang)
		draw_line(lft, rgt, gold, 2.5)
		for end in [lft, rgt]:
			draw_line(end, end + Vector2(-8, 16), Color(gold, 0.7), 1.0)
			draw_line(end, end + Vector2(8, 16), Color(gold, 0.7), 1.0)
			draw_line(end + Vector2(-11, 16), end + Vector2(11, 16), gold, 2.5)
		# piatto sinistro: la piuma di Ma'at (sale)
		var fp := lft + Vector2(0, 10)
		draw_line(fp + Vector2(0, 5), fp + Vector2(2, -7), Color(0.95, 0.93, 0.85), 1.5)
		draw_colored_polygon(PackedVector2Array([fp + Vector2(1, 4), fp + Vector2(5, -2), fp + Vector2(3, -8), fp + Vector2(0, -2)]), Color(0.95, 0.93, 0.85))
		# piatto destro: il cuore (scende), che pulsa piano
		var hp := rgt + Vector2(0, 9)
		var beat := 1.0 + 0.08 * maxf(0.0, sin(t * 3.0))
		draw_circle(hp + Vector2(-2.5, -1) * beat, 3.5 * beat, Color(0.75, 0.12, 0.1))
		draw_circle(hp + Vector2(2.5, -1) * beat, 3.5 * beat, Color(0.75, 0.12, 0.1))
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-5.8, 0) * beat, hp + Vector2(5.8, 0) * beat, hp + Vector2(0, 7) * beat]), Color(0.75, 0.12, 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
