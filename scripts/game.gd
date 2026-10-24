extends Node2D
## Una discesa di prova: 3 stanze. In ogni stanza due ondate di nemici,
## poi la ricompensa, poi 2-3 porte tra cui scegliere la prossima ricompensa.

const ROOM := Rect2(0, 0, 800, 480)
const WALL := 32.0
const TOP := 64.0                     # il muro in alto è alto due file
const PlayerScene := preload("res://scenes/player.tscn")
const ENEMIES := {
	"mummy": preload("res://scenes/mummy.tscn"),
	"scarab": preload("res://scenes/scarab.tscn"),
	"priest": preload("res://scenes/priest.tscn"),
	"ammit": preload("res://scenes/ammit.tscn"),
}
const PickupScript := preload("res://scripts/pickup.gd")
const DecorScript := preload("res://scripts/room_decor.gd")
const UshabtiScript := preload("res://scripts/ushabti.gd")
const TRAPS_FROM_ROOM := 2            ## le trappole compaiono da questa stanza in poi
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
var pause_menu: CanvasLayer           # menu di pausa (Esc / Start)                # menu dei doni (Tab)

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
	var listener := PanelListener.new()
	listener.game = self
	add_child(listener)
	# la prima stanza non ha ricompensa: il primo dono è quello di Anubi
	start_room({"kind": "none"})
	_show_anubi_menu()


# ---------------------------------------------------------------- stanze

func start_room(reward: Dictionary) -> void:
	Run.room += 1
	room_gen += 1
	boss = null
	current_reward = reward
	cleared = false
	alive = 0
	spawning = 0
	doors.clear()
	message.visible = false
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()

	pillars.clear()
	var boss_room := Run.room > Run.ROOMS_PER_RUN
	if not boss_room:
		Music.play("room")
	var layout: Array = LAYOUTS.pick_random() if Run.room > 1 else LAYOUTS[0]
	if boss_room:
		layout = BOSS_LAYOUT
	for f in layout:
		pillars.append(Vector2(lerpf(WALL, ROOM.size.x - WALL, f.x), lerpf(TOP, ROOM.size.y - WALL, f.y)))
	_build_walls()
	var decor := DecorScript.new()
	world.add_child(decor)
	obstacles = decor.build(Run.room * 7919 + randi() % 1000, ROOM, TOP, WALL, pillars, boss_room)
	for r in obstacles:
		_solid(r)
	traps_pos.clear()
	if not boss_room and Run.room >= TRAPS_FROM_ROOM:
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
	var r := Run.room
	waves = [_make_wave(4 + r * 2, r >= 2), _make_wave(3 + r * 2, r >= 2)]
	_spawn_wave(waves.pop_front(), 1.0)


func _make_wave(budget: int, allow_priest: bool) -> Array:
	var out := []
	while budget > 0:
		var roll := randf()
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
	if Run.room >= 3 and Run.room <= Run.ROOMS_PER_RUN and kind != "scarab" and randf() < 0.08 + 0.03 * Run.room:
		e.elite = true
		Music.play("elite")           # una stanza con nemici élite cambia musica fino alla prossima
	world.add_child(e)
	alive += 1
	e.killed.connect(_on_enemy_killed)
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

## Finestra con titolo e 1-3 carte. `cards` = [{"text", "color", "heavy", "on_pick"}].
func _open_choice(title_text: String, title_color: Color, subtitle: String, cards: Array, speech: String = "") -> void:
	get_tree().paused = true
	menu = CanvasLayer.new()
	menu.layer = 20
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	menu.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", title_color)
	box.add_child(title)

	if speech != "":
		var said := Label.new()
		said.text = "«%s»" % speech
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.custom_minimum_size = Vector2(560, 0)
		said.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		said.add_theme_font_size_override("font_size", 10)
		said.add_theme_color_override("font_color", title_color.lerp(Color(0.97, 0.93, 0.85), 0.6))
		said.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		said.add_theme_constant_override("outline_size", 3)
		box.add_child(said)

	if subtitle != "":
		var sub := Label.new()
		sub.text = subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 9)
		sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
		box.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	var first_button: Button = null
	for c in cards:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(190, 120)
		btn.text = c["text"]
		btn.add_theme_font_size_override("font_size", 9)
		var base := Color(1, 0.62, 0.55) if c.get("heavy", false) else Color(0.95, 0.9, 0.78)
		btn.add_theme_color_override("font_color", base)
		btn.add_theme_color_override("font_hover_color", c["color"])
		btn.add_theme_color_override("font_focus_color", c["color"])
		btn.pressed.connect(c["on_pick"])
		btn.focus_entered.connect(Sfx.play.bind("ui", 0.0))
		row.add_child(btn)
		if first_button == null:
			first_button = btn
	first_button.grab_focus()


func _close_choice() -> void:
	if menu != null:
		menu.queue_free()
		menu = null
	get_tree().paused = false


func _show_boon_menu(god: String) -> void:
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
		Fx.float_text(player.global_position, "+%d Ka" % bonus, Color(0.94, 0.72, 0.3))
		_open_doors()
		return

	var duos := Boons.duos_for(from_god, Run.boons)
	if not duos.is_empty() and randf() < Boons.DUO_CHANCE:
		if options.size() >= 3:
			options[2] = duos.pick_random()
		else:
			options.append(duos.pick_random())
	var cards := []
	for id in options:
		var lvl := Run.level(id) + 1
		var name_line: String = Boons.ALL[id]["name"]
		var tag := "NUOVO" if lvl == 1 else "LIVELLO %d" % lvl
		var body := _wrap(Boons.text(id, lvl), 32)
		if Boons.is_heavy(id):
			tag = "DONO PESANTE"
		if Boons.is_duo(id):
			var gs: Array = Boons.ALL[id]["gods"]
			tag = "DONO DOPPIO · %s + %s" % [Boons.god_name(gs[0]), Boons.god_name(gs[1])]
		if Boons.has_cost(id):
			body += "\n\nPrezzo: " + _wrap(Boons.ALL[id]["cost"], 32)
		cards.append({
			"text": "%s\n%s\n\n%s" % [tag, name_line, body],
			"color": Boons.god_color("duo") if Boons.is_duo(id) else Boons.god_color(from_god),
			"heavy": Boons.is_heavy(id),
			"on_pick": _choose_boon.bind(id),
		})
	_open_choice("%s ti offre un dono" % Boons.god_name(from_god), Boons.god_color(from_god), "", cards, Lore.speech(from_god))


## All'inizio di ogni run Anubi offre uno dei suoi doni.
func _show_anubi_menu() -> void:
	var cards := []
	for id in Boons.offers("anubi", Run.boons):
		cards.append({
			"text": "%s\n\n%s\n\nPrezzo: %s" % [Boons.ALL[id]["name"], _wrap(Boons.text(id, 1), 32), _wrap(Boons.ALL[id]["cost"], 32)],
			"color": Boons.god_color("anubi"),
			"heavy": false,
			"on_pick": _choose_start_boon.bind(id),
		})
	_open_choice("Anubi pesa il tuo cuore", Boons.god_color("anubi"), "", cards, Lore.speech("anubi"))


func _choose_start_boon(id: String) -> void:
	Sfx.play("boon", 0.0)
	Run.add_boon(id)
	_close_choice()
	player.max_hp = Run.max_hp
	player.hp = Run.hp
	Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color("anubi"), 30, 140.0)
	_banner("Dono di Anubi", Boons.ALL[id]["name"], Boons.god_color("anubi"))


func _choose_boon(id: String) -> void:
	Sfx.play("boon", 0.0)
	Run.add_boon(id)
	_close_choice()
	Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color(Boons.ALL[id]["god"]), 30, 140.0)
	_open_doors()


func _show_set_menu() -> void:
	var cards := []
	for o in Boons.set_offers(Run.blessings):
		var curse: Dictionary = Boons.SET_CURSES[o["curse"]]
		var bless: Dictionary = Boons.SET_BLESSINGS[o["blessing"]]
		cards.append({
			"text": "%s\n\nPER LE PROSSIME %d STANZE\n%s\n\nPOI, PER TUTTA LA RUN\n%s" % [bless["name"], curse["rooms"], _wrap(curse["desc"], 32), _wrap(bless["desc"], 32)],
			"color": Boons.god_color("set"),
			"heavy": true,
			"on_pick": _choose_pact.bind(o["curse"], o["blessing"]),
		})
	if cards.is_empty():
		Run.ka += roundi(25 * Run.ka_mult())
		_open_doors()
		return
	_open_choice("Set ti propone un patto", Boons.god_color("set"), "Prima la maledizione, poi la ricompensa", cards, Lore.speech("set"))


func _choose_pact(curse: String, blessing: String) -> void:
	Sfx.play("boon", 0.0)
	Run.add_pact(curse, blessing)
	Run.ka += roundi(25 * Run.ka_mult())
	_close_choice()
	Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color("set"), 30, 140.0)
	_banner("Maledizione di Set", Boons.SET_CURSES[curse]["desc"], Boons.god_color("set"))
	_open_doors()


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
	box.position = Vector2(-80, -70)
	box.custom_minimum_size = Vector2(160, 140)
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Button = null
	for entry in [["Riprendi", _toggle_pause], ["Volume", _show_audio_menu], ["Ricomincia la run", _restart_run], ["Torna alla Sala (abbandona)", _abandon_run], ["Esci dal gioco", _quit_game]]:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(160, 26)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(entry[1])
		box.add_child(b)
		if first == null:
			first = b
	var hint := Label.new()
	hint.text = "Esc / Start per riprendere"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	box.add_child(hint)
	first.grab_focus()


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
	box.position = Vector2(-130, -120)
	box.custom_minimum_size = Vector2(260, 240)
	box.add_theme_constant_override("separation", 4)
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Volume"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Control = null
	for c in Sfx.CATEGORIES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = c[1]
		name_label.custom_minimum_size = Vector2(110, 0)
		name_label.add_theme_font_size_override("font_size", 9)
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sfx.volumes.get(c[0], 1.0)
		slider.custom_minimum_size = Vector2(100, 14)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(slider.value * 100.0)
		pct.custom_minimum_size = Vector2(32, 0)
		pct.add_theme_font_size_override("font_size", 9)
		row.add_child(pct)
		slider.value_changed.connect(_on_volume_changed.bind(c[0], pct))
		if first == null:
			first = slider
	var back := Button.new()
	back.text = "Indietro"
	back.add_theme_font_size_override("font_size", 11)
	back.pressed.connect(_close_audio_menu)
	box.add_child(back)
	first.grab_focus()


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
	Meta.last_end = "abandon"
	Meta.last_room = Run.room
	_end_run_summary()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


func _restart_run() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _quit_game() -> void:
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
	Music.set_duck(0.35)
	message.visible = true
	var where := "Ammit, la Divoratrice" if Run.room > Run.ROOMS_PER_RUN else "stanza %d di %d" % [Run.room, Run.ROOMS_PER_RUN]
	Meta.last_end = "ammit" if Run.room > Run.ROOMS_PER_RUN else "room"
	Meta.last_room = Run.room
	message.text = "Il tuo cuore è stato pesato.\nSei caduto: %s\n\n%s\n\nPremi R (o Start) per tornare alla Sala del Giudizio" % [where, _end_run_summary()]
	boss_bar.visible = false


# ---------------------------------------------------------------- boss

func _start_boss() -> void:
	Music.play("boss")
	Sfx.play("roar", 0.0)
	_banner("Ammit, la Divoratrice", "Divora i cuori che non superano il giudizio", Color(0.9, 0.35, 0.25))
	boss_bar.visible = true
	boss_fill.size.x = boss_bar.size.x
	spawning += 1
	_spawn_after("ammit", Vector2(ROOM.size.x / 2.0, TOP + 120.0), 1.6)


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
	boss_name.add_theme_font_size_override("font_size", 9)
	boss_name.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_name.add_theme_constant_override("outline_size", 4)
	boss_name.position = Vector2(170, 318)
	boss_name.size = Vector2(300, 12)
	boss_bar = ColorRect.new()
	boss_bar.color = Color(0.1, 0.02, 0.02, 0.85)
	boss_bar.position = Vector2(170, 56)
	boss_bar.size = Vector2(300, 6)
	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.85, 0.2, 0.15)
	boss_fill.size = Vector2(300, 6)
	boss_bar.add_child(boss_fill)
	boss_bar.add_child(boss_name)
	boss_name.position = Vector2(0, -14)
	ui.add_child(boss_bar)
	boss_bar.visible = false


## Riepilogo della discesa. Salva anche il Ka raccolto, che resta tra una run e l'altra.
func _end_run_summary() -> String:
	Meta.ka_bank += Run.ka
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
		"Doni raccolti %d   ·   Ka raccolto %d   ·   Ka custodito %d" % [Run.boons.size() + Run.blessings.size(), Run.ka, Meta.ka_bank],
	]
	return "\n".join(lines)


func _victory() -> void:
	finished = true
	Music.play("hub")
	for c in world.get_children():
		if c is Enemy:
			c.queue_free()
	message.visible = true
	var extra := "\nNuovi poteri: il Sekhem e la Forma Divina (Q / LT), e un posto in più nel Libro dei Morti" if Meta.ammit_wins == 1 else ""
	Meta.last_end = "win"
	message.text = "Hai sconfitto Ammit!\nLa Prima Ora è superata.%s\n\n%s\n\nPremi R (o Start) per tornare alla Sala del Giudizio" % [extra, _end_run_summary()]


# ---------------------------------------------------------------- ogni frame

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_hitbox"):
		Fx.set_hitboxes(not Fx.show_hitboxes)
	if Input.is_action_just_pressed("restart") and (finished or player.dead):
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/hub.tscn")
		return
	if player == null or not is_instance_valid(player):
		return

	var eye_txt := "pronto" if player.eye_cd <= 0.0 else "%.1fs" % player.eye_cd
	if Run.cursed("no_eye"):
		eye_txt = "bloccato da Set"
	var sek := "PRONTO (Q / LT)" if Run.sekhem_ready() else "%d%%" % int(Run.sekhem)
	if player.divine_t > 0.0:
		sek = "FORMA DIVINA %.1fs" % player.divine_t
	var room_txt := "Ammit · colonne: %d" % pillars.size() if Run.room > Run.ROOMS_PER_RUN else "Stanza %d/%d" % [Run.room, Run.ROOMS_PER_RUN]
	hud.text = "Vita %d/%d    Ka %d    %s    Occhio: %s" % [ceili(player.hp), int(player.max_hp), Run.ka, room_txt, eye_txt]
	if Run.sekhem_unlocked():
		hud.text += "    Sekhem: %s" % sek
	if boss != null and is_instance_valid(boss) and not boss.dead:
		boss_fill.size.x = boss_bar.size.x * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	var n := Run.boons.size() + Run.blessings.size()
	var line2 := ""
	if n > 0:
		line2 = "Doni: %d (Tab per vederli)" % n
	for c in Run.curses:
		line2 += "    Maledizione: %s (ancora %d stanze)" % [Boons.SET_CURSES[c["curse"]]["desc"], c["rooms"]]
	if line2 != "":
		hud.text += "\n" + line2

	var near := ""
	for d in doors:
		if is_instance_valid(d) and d.open and player.global_position.distance_to(d.global_position) < 70.0:
			near = d.reward_description()
	prompt.text = near
	prompt.visible = near != ""

	var mouse := Fx.device == "mouse"
	reticle.visible = mouse and not player.dead and menu == null and panel == null and pause_menu == null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if (mouse and menu == null and panel == null and pause_menu == null) else Input.MOUSE_MODE_VISIBLE
	if Fx.device == "pad":
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
	var spikes := clampi(Run.room, 2, 4)
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
	if Run.room >= TRAPS_FROM_ROOM + 1:
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
		if event.is_action_pressed("pause") and not game.finished:
			game._toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("boons_menu") or (game.panel != null and event.is_action_pressed("ui_cancel")):
			game._toggle_boons_panel()
			get_viewport().set_input_as_handled()
