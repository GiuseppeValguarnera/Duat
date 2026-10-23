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
}
const PickupScript := preload("res://scripts/pickup.gd")
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

var player
var pillars: Array = []
var waves: Array = []
var alive := 0
var spawning := 0
var cleared := false
var current_reward := {}
var doors: Array = []
var finished := false
var menu: CanvasLayer                 # scelta dei doni
var panel: CanvasLayer                # menu dei doni (Tab)

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
	Run.new_run()
	Run.blessing_granted.connect(_on_blessing_granted)
	var listener := PanelListener.new()
	listener.game = self
	add_child(listener)
	var first := Boons.gods_with_boons(Run.boons)
	start_room({"kind": "boon", "god": first.pick_random()})


# ---------------------------------------------------------------- stanze

func start_room(reward: Dictionary) -> void:
	Run.room += 1
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
	var layout: Array = LAYOUTS.pick_random() if Run.room > 1 else LAYOUTS[0]
	for f in layout:
		pillars.append(Vector2(lerpf(WALL, ROOM.size.x - WALL, f.x), lerpf(TOP, ROOM.size.y - WALL, f.y)))
	_build_walls()
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
	await get_tree().create_timer(delay, false).timeout
	if is_instance_valid(marker):
		marker.queue_free()
	if not is_instance_valid(world) or finished:
		return
	spawning -= 1
	var e: Enemy = ENEMIES[kind].instantiate()
	e.position = pos
	world.add_child(e)
	alive += 1
	e.killed.connect(_on_enemy_killed)


func _on_enemy_killed(_e: Enemy) -> void:
	alive -= 1
	if alive > 0 or spawning > 0:
		return
	Run.wave_cleared()
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
	var p = PickupScript.new()
	p.kind = current_reward["kind"]
	p.god = current_reward.get("god", "")
	world.add_child(p)
	p.position = _free_spot_near(Vector2(ROOM.size.x / 2.0, ROOM.size.y / 2.0 + 20.0))
	p.collected.connect(_on_pickup_collected)


func _on_pickup_collected(p: Area2D) -> void:
	var kind: String = p.kind
	var god: String = p.god
	Fx.burst(p.global_position + Vector2(0, -10), p.color(), 24, 120.0)
	p.queue_free()
	match kind:
		"ka":
			Run.ka += 25
			Fx.float_text(player.global_position, "+25 Ka", Color(0.94, 0.72, 0.3))
			_open_doors.call_deferred()
		"heal":
			player.heal(roundf(Run.max_hp * 0.4))
			_open_doors.call_deferred()
		"boon":
			_show_boon_menu.call_deferred(god)
		"set":
			_show_set_menu.call_deferred()


func _open_doors() -> void:
	if Run.room >= Run.ROOMS_PER_RUN:
		_add_door("n", {"kind": "end"})
		return
	var sides: Array = [["w", "n", "e"], ["w", "e"], ["w", "n"], ["n", "e"]].pick_random()
	var pool := []
	var gods := Boons.gods_with_boons(Run.boons)
	gods.shuffle()
	for g in gods.slice(0, 2):
		pool.append({"kind": "boon", "god": g})
	pool.append({"kind": "ka"})
	pool.append({"kind": "heal"})
	pool.shuffle()
	# a volte Set apre una sua porta: prende il posto di una delle altre
	if randf() < SET_DOOR_CHANCE and not Boons.set_offers(Run.blessings).is_empty():
		pool.insert(0, {"kind": "set"})
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
	var kind: String = d.reward["kind"]
	if kind == "end":
		_victory.call_deferred()
		return
	if kind == "set":
		# il tributo di Set: 10 punti vita, ma non può ucciderti
		Run.hp = maxf(1.0, Run.hp - SET_DOOR_COST)
	start_room.call_deferred(d.reward)


# ---------------------------------------------------------------- scelta dei doni

## Finestra con titolo e 1-3 carte. `cards` = [{"text", "color", "heavy", "on_pick"}].
func _open_choice(title_text: String, title_color: Color, subtitle: String, cards: Array) -> void:
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
		var others := Boons.gods_with_boons(Run.boons)
		if others.is_empty():
			player.heal(30.0)
			_open_doors()
			return
		from_god = others.pick_random()
		options = Boons.offers(from_god, Run.boons)

	var cards := []
	for id in options:
		var lvl := Run.level(id) + 1
		var name_line: String = Boons.ALL[id]["name"]
		var tag := "NUOVO" if lvl == 1 else "LIVELLO %d" % lvl
		var body := _wrap(Boons.text(id, lvl), 32)
		if Boons.is_heavy(id):
			tag = "DONO PESANTE"
			body += "\n\nPrezzo: " + _wrap(Boons.ALL[id]["cost"], 32)
		cards.append({
			"text": "%s\n%s\n\n%s" % [tag, name_line, body],
			"color": Boons.god_color(from_god),
			"heavy": Boons.is_heavy(id),
			"on_pick": _choose_boon.bind(id),
		})
	_open_choice("%s ti offre un dono" % Boons.god_name(from_god), Boons.god_color(from_god), "", cards)


func _choose_boon(id: String) -> void:
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
			"text": "%s\n\nPER %d ONDATE\n%s\n\nPOI, PER TUTTA LA RUN\n%s" % [bless["name"], curse["waves"], _wrap(curse["desc"], 32), _wrap(bless["desc"], 32)],
			"color": Boons.god_color("set"),
			"heavy": true,
			"on_pick": _choose_pact.bind(o["curse"], o["blessing"]),
		})
	if cards.is_empty():
		Run.ka += 25
		_open_doors()
		return
	_open_choice("Set ti propone un patto", Boons.god_color("set"), "Prima la maledizione, poi la ricompensa", cards)


func _choose_pact(curse: String, blessing: String) -> void:
	Run.add_pact(curse, blessing)
	Run.ka += 25
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


# ---------------------------------------------------------------- menu dei doni (Tab)

func _toggle_boons_panel() -> void:
	if menu != null or finished:
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
		var lvl := "pesante" if Boons.is_heavy(id) else "liv. %d" % Run.boons[id]
		t += "[color=#%s][b]%s[/b] · %s · %s[/color]\n%s" % [col, Boons.god_name(b["god"]), b["name"], lvl, Boons.text(id, Run.boons[id])]
		if Boons.is_heavy(id):
			t += " [color=#ff9c8c]Prezzo: %s[/color]" % b["cost"]
		t += "\n\n"
	var set_col: String = Boons.god_color("set").to_html(false)
	for c in Run.curses:
		t += "[color=#%s][b]Maledizione di Set[/b] · ancora %d ondate[/color]\n%s. Poi: %s\n\n" % [set_col, c["waves"], Boons.SET_CURSES[c["curse"]]["desc"], Boons.SET_BLESSINGS[c["blessing"]]["desc"]]
	for b in Run.blessings:
		t += "[color=#%s][b]Set[/b] · %s · permanente[/color]\n%s\n\n" % [set_col, Boons.SET_BLESSINGS[b]["name"], Boons.SET_BLESSINGS[b]["desc"]]
	return t


# ---------------------------------------------------------------- fine run

func _on_player_died() -> void:
	finished = true
	message.visible = true
	message.text = "Il tuo cuore è stato pesato.\nStanza raggiunta: %d di %d\n\nPremi R (o Start) per ricominciare" % [Run.room, Run.ROOMS_PER_RUN]


func _victory() -> void:
	finished = true
	for c in world.get_children():
		if c is Enemy:
			c.queue_free()
	message.visible = true
	message.text = "Discesa di prova completata!\nKa totale: %d\n\nPremi R (o Start) per ricominciare" % Run.ka


# ---------------------------------------------------------------- ogni frame

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_hitbox"):
		Fx.set_hitboxes(not Fx.show_hitboxes)
	if Input.is_action_just_pressed("restart") and (finished or player.dead):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		return
	if player == null or not is_instance_valid(player):
		return

	var eye_txt := "pronto" if player.eye_cd <= 0.0 else "%.1fs" % player.eye_cd
	if Run.cursed("no_eye"):
		eye_txt = "bloccato da Set"
	var sek := "PRONTO (Q / RB)" if Run.sekhem_ready() else "%d%%" % int(Run.sekhem)
	if player.divine_t > 0.0:
		sek = "FORMA DIVINA %.1fs" % player.divine_t
	hud.text = "Vita %d/%d    Ka %d    Stanza %d/%d    Occhio: %s    Sekhem: %s" % [ceili(player.hp), int(player.max_hp), Run.ka, Run.room, Run.ROOMS_PER_RUN, eye_txt, sek]
	var n := Run.boons.size() + Run.blessings.size()
	var line2 := ""
	if n > 0:
		line2 = "Doni: %d (Tab per vederli)" % n
	for c in Run.curses:
		line2 += "    Maledizione: %s (%d ondate)" % [Boons.SET_CURSES[c["curse"]]["desc"], c["waves"]]
	if line2 != "":
		hud.text += "\n" + line2

	var near := ""
	for d in doors:
		if is_instance_valid(d) and d.open and player.global_position.distance_to(d.global_position) < 70.0:
			near = d.reward_description()
	prompt.text = near
	prompt.visible = near != ""

	var mouse := Fx.device == "mouse"
	reticle.visible = mouse and not player.dead and menu == null and panel == null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if (mouse and menu == null and panel == null) else Input.MOUSE_MODE_VISIBLE
	if Fx.device == "pad":
		help.text = "Levetta sinistra muovi · destra mira · X khopesh · A scatto · Y Occhio · RB Forma Divina · Select doni"
	else:
		help.text = "WASD muovi · mouse mira · clic sinistro khopesh · Spazio scatto · clic destro Occhio · Q Forma Divina · Tab doni · F1 hitbox"


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
	return true


func _build_walls() -> void:
	var r := ROOM
	_solid(Rect2(r.position.x, r.position.y, r.size.x, TOP))
	_solid(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL))
	_solid(Rect2(r.position.x, r.position.y, WALL, r.size.y))
	_solid(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y))
	for p in pillars:
		_solid(Rect2(p.x - 13.0, p.y - 7.0, 26.0, 14.0))


func _solid(rect: Rect2) -> void:
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


func _draw() -> void:
	var r := ROOM
	var tile := 32.0
	var y := TOP
	while y < r.end.y - WALL:
		var x := r.position.x + WALL
		while x < r.end.x - WALL:
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233 + Run.room) * 43758.5453), 1.0)
			draw_rect(Rect2(x + 1, y + 1, tile - 2, tile - 2), Color(0.6, 0.46, 0.29).darkened(n * 0.12))
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
		if event.is_action_pressed("boons_menu") or (game.panel != null and event.is_action_pressed("ui_cancel")):
			game._toggle_boons_panel()
			get_viewport().set_input_as_handled()
