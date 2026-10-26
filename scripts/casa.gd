extends Node2D
## La Casa della Vita (per-ankh): nei templi era il luogo degli scribi e degli artigiani, la
## biblioteca e la bottega insieme. Si apre dalla parete est della Sala del Giudizio con 40
## lapislazzuli.
## - il banco dell'orafo: si forgiano gli amuleti (amulets.gd) e si sceglie quello da portare;
## - la parete di Thoth: le sfide (challenges.gd), con il premio da riscuotere. Le vedi ogni
##   volta che passi a cambiare amuleto, ed è il punto: una sfida che non vedi non la fai;
## - la seconda parete, coperta da un telo finché non hai compiuto 7 sfide;
## - la statua di Thoth con la testa d'ibis, che guarda gli scribi;
## - Imhotep, il maestro della Casa: parla degli amuleti, dà consigli, ricorda Akhet (imhotep.gd).

const ROOM := Rect2(0, 0, 640, 380)
const WALL := 32.0
const TOP := 64.0
const PlayerScene := preload("res://scenes/player.tscn")
const COLOR := Color(0.3, 0.62, 0.66)       ## il turchese di Thoth: titoli e cornici
const GOLD := Color(0.94, 0.72, 0.3)
const EXIT_Y := 210.0                        ## la porta verso la Sala, nella parete ovest
const OPEN_COST := 40

var is_armory := true                  # i comandi touch mostrano anche il pulsante Azione
var player
var spots := {}
var near := ""
var t := 0.0
var menu: CanvasLayer = null
var _news_t := 0.0
var _forge_news := false
var _wall_news := false
var _imhotep_news := false
var talk_lines: Array = []

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
	Run.in_hub = false
	Music.play("hub")
	Run.new_run()
	Fx.world = world
	world.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	spots = {
		"orafo": Vector2(170, 196),
		"parete": Vector2(440, 150),
		"thoth": Vector2(560, 214),
		"imhotep": Vector2(262, 272),
	}
	_solid(Rect2(0, 0, ROOM.size.x, TOP + 40))                       # le pareti con gli scaffali
	_solid(Rect2(0, ROOM.size.y - WALL, ROOM.size.x, WALL))
	_solid(Rect2(0, 0, WALL, EXIT_Y - 26))
	_solid(Rect2(0, EXIT_Y + 26, WALL, ROOM.size.y))
	_solid(Rect2(ROOM.size.x - WALL, 0, WALL, ROOM.size.y))
	_solid(Rect2(spots["orafo"] - Vector2(40, 10), Vector2(80, 18)))
	_solid(Rect2(spots["thoth"] - Vector2(14, 6), Vector2(28, 10)))
	_solid(Rect2(spots["imhotep"] - Vector2(8, 5), Vector2(16, 8)))
	_solid(Rect2(56, 258, 28, 14))                                            # le casse negli angoli
	_solid(Rect2(576, 258, 28, 14))
	var bg := CasaArt.new()
	bg.show_behind_parent = true
	add_child(bg)
	move_child(bg, 0)
	_solid(Rect2(Vector2(330, 280) - Vector2(40, 10), Vector2(80, 18)))         # il tavolo degli scribi
	# luce calda di lampade a olio: la Casa è un interno, più raccolto della Sala
	var amb := CanvasModulate.new()
	amb.color = Color(0.86, 0.79, 0.74)
	world.add_child(amb)
	for p in CasaArt.LAMPS:
		Atmos.add_glow(world, p + Vector2(0, -14), 130.0, Color(1.0, 0.66, 0.34), 0.8)
	player = PlayerScene.instantiate()
	player.position = Vector2(WALL + 26.0, EXIT_Y)
	world.add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM.size.x)
	cam.limit_bottom = int(ROOM.size.y)
	cam.reset_smoothing()
	Fx.scale_labels($UI)
	talk_box.visible = false
	UiStyle.talk_style(talk_box, talk_name, talk_text, Imhotep.NAME_COLOR)
	# la prima volta Imhotep si presenta da solo
	if not Meta.dialogue_seen.has("imh_intro"):
		_start_talk.call_deferred()


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
	var am := Lang.t("nessuno") if Meta.amulet == "" else String(Amulets.data()[Meta.amulet]["name"])
	hud.text = Lang.t("Casa della Vita    Lapislazzuli: %d    Amuleto: %s") % [Meta.lapis, am]
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = Lang.t("Levetta muovi · LB/A scatto · Y interagisci · B chiudi")
	else:
		help.text = Lang.t("WASD muovi · Spazio scatto · E interagisci · Esc esci")
	if t >= _news_t:
		_news_t = t + 0.5
		_forge_news = Amulets.something_to_forge()
		_wall_news = Challenges.to_claim() > 0
		_imhotep_news = Imhotep.has_news()
	if menu != null or talk_box.visible:
		prompt.visible = false
		return
	if player.global_position.x < WALL + 14.0 and absf(player.global_position.y - EXIT_Y) < 24.0:
		_leave()
		return
	near = ""
	for k in ["orafo", "parete", "thoth", "imhotep"]:
		var reach := 70.0 if k == "parete" else 44.0
		if player.global_position.distance_to(spots[k] + Vector2(0, 20 if k == "parete" else 0)) < reach:
			near = k
	var key := "Y" if Fx.device == "pad" else (Lang.t("AZIONE") if Fx.device == "touch" else "E")
	match near:
		"orafo":
			prompt.text = Lang.t("%s · Il banco dell'orafo: gli amuleti") % key
		"parete":
			prompt.text = Lang.t("%s · La parete di Thoth: le sfide (%d da riscuotere)") % [key, Challenges.to_claim()]
		"thoth":
			prompt.text = Lang.t("Thoth, il signore della scrittura, guarda gli scribi al lavoro")
		"imhotep":
			prompt.text = Lang.t("%s · Parla con Imhotep") % key
		_:
			prompt.text = ""
	prompt.visible = prompt.text != ""


func _unhandled_input(event: InputEvent) -> void:
	if menu != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_close_menu()
			get_viewport().set_input_as_handled()
		return
	if talk_box.visible:
		var tap: bool = event is InputEventScreenTouch and event.pressed
		if tap or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
			_advance_talk()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if near == "imhotep":
			_start_talk()
		elif near == "orafo":
			_open_forge()
		elif near == "parete":
			_open_wall()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_leave()
		get_viewport().set_input_as_handled()


func _start_talk() -> void:
	talk_lines = Imhotep.next_lines()
	player.set_physics_process(false)
	talk_box.visible = true
	_advance_talk()


func _advance_talk() -> void:
	if talk_lines.is_empty():
		talk_box.visible = false
		player.set_physics_process(true)
		return
	Sfx.play("ui", 0.0)
	talk_name.text = "Imhotep"
	talk_text.text = talk_lines.pop_front()


func _leave() -> void:
	Run.from_casa = true
	Sfx.play("door")
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


# ---------------------------------------------------------------- finestre

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
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(COLOR.darkened(0.3)))
	center.add_child(pap)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pap.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(4 * Fx.ui))
	scroll.add_child(col)
	var vs := get_viewport().get_visible_rect().size
	col.custom_minimum_size = Vector2(minf(540.0 * Fx.ui, vs.x - 40.0), 0)
	var scroll_ref: WeakRef = weakref(scroll)
	var col_ref: WeakRef = weakref(col)
	var fit := func() -> void:
		var sc: ScrollContainer = scroll_ref.get_ref()
		var cc: VBoxContainer = col_ref.get_ref()
		if sc != null and cc != null:
			sc.custom_minimum_size = Vector2(cc.custom_minimum_size.x + 4.0, minf(cc.get_combined_minimum_size().y, vs.y - 44.0))
	col.minimum_size_changed.connect(fit)
	fit.call_deferred()
	var h := UiStyle.label(title, 13, COLOR.darkened(0.35), true)
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
	UiStyle.papyrus_button(b, COLOR)
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


## Il banco dell'orafo: ogni amuleto con il suo potere, il livello e cosa serve per averlo.
func _open_forge(focus: String = "") -> void:
	var col := _window(Lang.t("Il banco dell'orafo"), Lang.t("Porti un solo amuleto per volta. Si ottengono con le sfide della parete di Thoth, poi si forgiano con i lapislazzuli (ne hai %d). Crescono con l'uso: livello 2 dopo 20 stanze al collo, livello 3 dopo 50.") % Meta.lapis)
	var inner: float = col.custom_minimum_size.x
	var first: Button = null
	for id in Amulets.ALL_IT:
		var d: Dictionary = Amulets.data()[id]
		var own := Amulets.owned(id)
		var worn: bool = Meta.amulet == id
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		col.add_child(box)
		var lvl := Amulets.level(id)
		var title: String = d["name"]
		if own:
			title += Lang.t("  ·  livello %d") % lvl + (Lang.t("  ·  AL COLLO") if worn else "")
		box.add_child(UiStyle.label(title, 10, UiStyle.INK if own or Amulets.unlocked(id) else UiStyle.INK_SOFT, true, inner))
		var desc := Amulets.text(id, lvl if own else 1)
		if own and lvl < 3:
			desc += Lang.t("   (al livello %d: %s, dopo %d stanze; ne hai fatte %d)") % [lvl + 1, Amulets.short(id, lvl + 1), Amulets.LEVEL_ROOMS[lvl], Amulets.rooms(id)]
		box.add_child(UiStyle.label(desc, 8, UiStyle.INK_SOFT, false, inner))
		if own:
			box.add_child(UiStyle.label(d["lore"], 7, Color(0.3, 0.38, 0.42), false, inner))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(6 * Fx.ui))
		box.add_child(row)
		if own and not worn:
			var b := _button(row, Lang.t("Mettilo al collo"), true, func() -> void:
				Amulets.equip(id)
				Sfx.play("boon", 0.0)
				_open_forge(id))
			if first == null or id == focus:
				first = b
		elif own and worn:
			_button(row, Lang.t("Toglilo"), true, func() -> void:
				Amulets.equip("")
				_open_forge(id))
		elif Amulets.unlocked(id):
			var cost := int(d["cost"])
			var label := Lang.t("Forgialo · gratis") if cost == 0 else Lang.t("Forgialo · %d lapislazzuli") % cost
			var bf := _button(row, label, Amulets.can_forge(id), func() -> void:
				if Amulets.forge(id):
					Sfx.play("boon", 0.0)
					Fx.shake(3.0)
					Fx.burst(spots["orafo"] + Vector2(0, -20), GOLD, 26, 110.0)
				_open_forge(id))
			if first == null and not bf.disabled:
				first = bf
		else:
			row.add_child(UiStyle.label(Lang.t("Sfida: %s") % _challenge_for(id), 8, Color(0.5, 0.36, 0.2), false, inner))
	var close := _button(col, Lang.t("Chiudi"), true, _close_menu)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	(first if first != null else close).grab_focus.call_deferred()


func _challenge_for(amulet_id: String) -> String:
	for cid in Challenges.ALL_IT:
		var r: Array = Challenges.ALL_IT[cid]["reward"]
		if r[0] == "amulet" and r[1] == amulet_id:
			return Challenges.data()[cid]["desc"]
	return "?"


## La parete di Thoth: le sfide, a che punto sei, il premio da riscuotere.
func _open_wall() -> void:
	var done := Challenges.done_count()
	var col := _window(Lang.t("La parete di Thoth"), Lang.t("Le sfide si compiono giocando; il premio si riscuote qui. Sfide compiute: %d su %d.") % [done, Challenges.ALL_IT.size()])
	var inner: float = col.custom_minimum_size.x
	var first: Button = null
	for id in Challenges.ALL_IT:
		var d: Dictionary = Challenges.data()[id]
		var st := Challenges.state(id)
		var pr := Challenges.progress(id)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		col.add_child(box)
		var mark := Lang.t("  ·  FATTA") if st == 2 else (Lang.t("  ·  COMPIUTA!") if st == 1 else "  ·  %d/%d" % [pr.x, pr.y])
		box.add_child(UiStyle.label(String(d["name"]) + mark, 10, UiStyle.INK if st > 0 else UiStyle.INK_SOFT, true, inner))
		box.add_child(UiStyle.label(String(d["desc"]) + Lang.t("  Premio: %s.") % Challenges.reward_text(id), 8, UiStyle.INK_SOFT, false, inner))
		if st == 1:
			var b := _button(box, Lang.t("Riscuoti il premio"), true, func() -> void:
				if Challenges.claim(id):
					Sfx.play("boon", 0.0)
					Fx.shake(3.0)
					Fx.burst(spots["parete"], GOLD, 26, 110.0)
				_open_wall())
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			if first == null:
				first = b
	var more := UiStyle.label(Lang.t("La seconda parete è coperta da un telo: si svelerà quando avrai compiuto %d sfide.") % Challenges.SECOND_WALL if done < Challenges.SECOND_WALL else Lang.t("Thoth sta ancora incidendo la seconda parete: tornerà presto, con sfide più dure."), 8, Color(0.3, 0.38, 0.42), false, inner)
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(more)
	var close := _button(col, Lang.t("Chiudi"), true, _close_menu)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	(first if first != null else close).grab_focus.call_deferred()


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	if spots.is_empty():
		return
	_draw_bench(spots["orafo"])
	_draw_tablets()
	_draw_thoth(spots["thoth"])
	var face := -1.0 if player != null and is_instance_valid(player) and player.global_position.x < spots["imhotep"].x else 1.0
	Imhotep.draw(self, spots["imhotep"], t, talk_box.visible, face)
	if menu == null and not talk_box.visible:
		UiStyle.sparkle(self, spots["imhotep"] + Vector2(0, -30), 18.0, t, near == "imhotep", 3.3)
		if _imhotep_news:
			UiStyle.exclaim(self, spots["imhotep"] + Vector2(0, -62), t)
	if menu == null:
		UiStyle.sparkle(self, spots["orafo"] + Vector2(0, -26), 20.0, t, near == "orafo", 0.4)
		UiStyle.sparkle(self, spots["parete"] + Vector2(0, -40), 26.0, t, near == "parete", 2.1)
		if _forge_news:
			UiStyle.exclaim(self, spots["orafo"] + Vector2(0, -50), t)
		if _wall_news:
			UiStyle.exclaim(self, spots["parete"] + Vector2(96, -30), t)


## Il banco dell'orafo: il tavolo basso, il crogiolo con la brace, gli attrezzi e gli amuleti
## forgiati in fila sul piano (quelli ancora da fare sono solo una sagoma di cera).
func _draw_bench(p: Vector2) -> void:
	var wood := Color(0.5, 0.32, 0.18)
	var outl := Color(0.12, 0.08, 0.05)
	draw_set_transform(p + Vector2(0, 10), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 42.6, p.y - 12.6, 85.2, 20.2), outl)
	draw_rect(Rect2(p.x - 42, p.y - 12, 84, 8), wood.lightened(0.15))
	draw_rect(Rect2(p.x - 42, p.y - 4, 84, 11), wood)
	for x in [-38.0, 34.0]:
		draw_rect(Rect2(p.x + x, p.y + 7, 4, 6), wood.darkened(0.3))
	var i := 0
	for id in Amulets.ALL_IT:
		var c := Vector2(p.x - 33 + i * 9.5, p.y - 8)
		Amulets.draw_icon(self, id, c, 0.42, not Amulets.owned(id))
		i += 1
	# il crogiolo con la brace, accanto al banco
	var cr := p + Vector2(54, 0)
	var glow := 0.5 + 0.5 * sin(t * 5.0)
	draw_circle(cr + Vector2(0, -8), 12.0, Color(1.0, 0.5, 0.2, 0.12 + 0.08 * glow))
	draw_rect(Rect2(cr.x - 8, cr.y - 6, 16, 12), Color(0.36, 0.3, 0.28))
	draw_rect(Rect2(cr.x - 6, cr.y - 8, 12, 3), Color(1.0, 0.55 + 0.2 * glow, 0.2))
	# la cannuccia per soffiare sul fuoco e il martelletto
	draw_line(cr + Vector2(-14, -16), cr + Vector2(-4, -8), Color(0.8, 0.72, 0.5), 1.2)
	draw_line(p + Vector2(-30, -16), p + Vector2(-20, -18), Color(0.55, 0.5, 0.48), 2.0)


## Le tavolette delle sfide sulla parete di Thoth: due file da cinque. Quelle compiute hanno il
## segno inciso e dipinto d'oro; quelle da riscuotere brillano.
func _draw_tablets() -> void:
	var i := 0
	for id in Challenges.ALL_IT:
		var c := Vector2(370 + (i % 5) * 34, 52 + int(i / 5.0) * 32)
		var st := Challenges.state(id)
		var stone := Color(0.84, 0.78, 0.64) if st > 0 else Color(0.62, 0.58, 0.52)
		if st == 1:
			var pulse := 0.5 + 0.5 * sin(t * 4.0 + i)
			draw_circle(c, 16.0 + pulse * 2.0, Color(1.0, 0.82, 0.4, 0.18 + 0.12 * pulse))
		draw_rect(Rect2(c.x - 12.6, c.y - 13.6, 25.2, 27.2), Color(0.12, 0.08, 0.05))
		draw_rect(Rect2(c.x - 12, c.y - 13, 24, 26), stone)
		draw_rect(Rect2(c.x - 12, c.y - 13, 24, 2), stone.lightened(0.15))
		var r: Array = Challenges.ALL_IT[id]["reward"]
		if r[0] == "amulet":
			Amulets.draw_icon(self, r[1], c + Vector2(0, -1), 0.8, st == 0)
		else:
			var ink := GOLD if st > 0 else Color(0.4, 0.36, 0.3)
			for k in range(3):
				draw_line(c + Vector2(-7, -6 + k * 5), c + Vector2(7, -6 + k * 5), ink, 1.2)
		if st == 2:
			draw_line(c + Vector2(-6, 9), c + Vector2(-2, 12), Color(0.2, 0.5, 0.3), 1.6)
			draw_line(c + Vector2(-2, 12), c + Vector2(6, 6), Color(0.2, 0.5, 0.3), 1.6)
		i += 1
	# la seconda parete, coperta dal telo di lino
	var cx := 556.0
	draw_rect(Rect2(cx - 20, 34, 40, 66), Color(0.86, 0.82, 0.72))
	for k in range(5):
		draw_line(Vector2(cx - 18 + k * 9, 36), Vector2(cx - 16 + k * 9, 98), Color(0.7, 0.66, 0.56), 1.0)
	draw_rect(Rect2(cx - 22, 32, 44, 4), Color(0.5, 0.32, 0.18))


## Thoth, il dio scriba con la testa d'ibis, in piedi su un piedistallo: la tavolozza in mano.
func _draw_thoth(p: Vector2) -> void:
	var outl := Color(0.1, 0.07, 0.05)
	var stone := Color(0.24, 0.28, 0.32)
	draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(p.x - 14, p.y - 6, 28, 8), Color(0.5, 0.44, 0.36))
	draw_rect(Rect2(p.x - 14, p.y - 6, 28, 1.5), GOLD)
	# corpo con il gonnellino, collare e braccia
	draw_rect(Rect2(p.x - 6.6, p.y - 46.6, 13.2, 41.2), outl)
	draw_rect(Rect2(p.x - 6, p.y - 46, 12, 18), stone)
	draw_rect(Rect2(p.x - 6, p.y - 28, 12, 22), Color(0.92, 0.88, 0.78))
	draw_rect(Rect2(p.x - 6, p.y - 28, 12, 2), GOLD)
	draw_arc(p + Vector2(0, -46), 6.0, 0.1 * PI, 0.9 * PI, 10, COLOR, 2.4)
	draw_line(p + Vector2(6, -42), p + Vector2(11, -30), stone, 2.6)
	draw_rect(Rect2(p.x + 8, p.y - 34, 7, 10), Color(0.9, 0.86, 0.76))      # la tavolozza dello scriba
	draw_circle(p + Vector2(10, -31), 1.0, Color(0.1, 0.1, 0.1))
	draw_circle(p + Vector2(13, -31), 1.0, Color(0.7, 0.2, 0.15))
	# la testa d'ibis con il becco lungo e ricurvo, la parrucca blu e il disco lunare
	draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -56), p + Vector2(2, -60), p + Vector2(2, -46), p + Vector2(-7, -44)]), Color(0.16, 0.3, 0.68))
	draw_circle(p + Vector2(0, -56), 4.5, Color(0.12, 0.12, 0.12))
	var beak := PackedVector2Array()
	for k in range(7):
		var u := k / 6.0
		beak.append(p + Vector2(3 + u * 14.0, -56 + u * u * 12.0))
	draw_polyline(beak, outl, 2.6)
	draw_polyline(beak, Color(0.2, 0.18, 0.16), 1.6)
	draw_circle(p + Vector2(1.5, -57.5), 0.9, Color(0.95, 0.8, 0.4))
	draw_arc(p + Vector2(0, -66), 5.0, PI * 0.15, PI * 0.85, 10, Color(0.9, 0.9, 0.95), 1.5)
	draw_circle(p + Vector2(0, -68), 3.0, Color(0.92, 0.92, 0.98))


## Il fondo della Casa: pavimento di pietra con le stuoie di giunco, le pareti con gli scaffali
## dei rotoli di papiro (la biblioteca), la porta a ovest. Si disegna una volta sola.
class CasaArt extends Node2D:
	const LAMPS := [Vector2(52, 136), Vector2(330, 128), Vector2(600, 136), Vector2(52, 330), Vector2(600, 330)]

	func _draw() -> void:
		var r := Rect2(0, 0, 640, 380)
		var stone := Color(0.56, 0.47, 0.38)
		draw_rect(r, Color(0.2, 0.14, 0.11))
		# pavimento a lastre
		var y := 64.0
		var row := 0
		while y < r.end.y - 32.0:
			var x := 32.0 - (16.0 if row % 2 == 1 else 0.0)
			while x < r.end.x - 32.0:
				var n := fmod(absf(sin(x * 12.9898 + y * 78.233) * 43758.5453), 1.0)
				draw_rect(Rect2(maxf(x, 32.0) + 0.5, y + 0.5, 31, 23), stone.darkened(n * 0.12))
				x += 32.0
			y += 24.0
			row += 1
		# le stuoie di giunco davanti al banco e davanti alla parete
		for m in [Rect2(110, 220, 120, 60), Rect2(380, 150, 130, 70)]:
			draw_rect(m, Color(0.72, 0.6, 0.36))
			var k := 0.0
			while k < m.size.y:
				draw_line(Vector2(m.position.x, m.position.y + k), Vector2(m.end.x, m.position.y + k), Color(0.58, 0.46, 0.26), 1.0)
				k += 4.0
			draw_rect(Rect2(m.position.x, m.position.y, m.size.x, 3), Color(0.72, 0.26, 0.15))
			draw_rect(Rect2(m.position.x, m.end.y - 3, m.size.x, 3), Color(0.72, 0.26, 0.15))
		# la parete nord: intonaco, il fregio, gli scaffali dei papiri a sinistra (la biblioteca)
		draw_rect(Rect2(0, 0, r.size.x, 104), Color(0.78, 0.7, 0.56))
		draw_rect(Rect2(0, 0, r.size.x, 10), Color(0.16, 0.3, 0.68))
		draw_rect(Rect2(0, 10, r.size.x, 2), Color(0.94, 0.72, 0.3))
		for k in range(int(r.size.x / 12.0)):
			draw_rect(Rect2(k * 12.0 + 3, 12, 6, 8), [Color(0.72, 0.26, 0.15), Color(0.2, 0.62, 0.62), Color(0.94, 0.72, 0.3)][k % 3])
		for sx: float in [40.0, 200.0]:
			draw_rect(Rect2(sx, 28, 130, 72), Color(0.36, 0.22, 0.12))
			for shelf in range(3):
				var sy := 32.0 + shelf * 23.0
				draw_rect(Rect2(sx + 3, sy, 124, 19), Color(0.22, 0.13, 0.08))
				for c in range(10):
					var px := sx + 8 + c * 12.0
					draw_circle(Vector2(px, sy + 12), 4.5, Color(0.88, 0.8, 0.62))
					draw_circle(Vector2(px, sy + 12), 1.6, Color(0.6, 0.5, 0.36))
				draw_rect(Rect2(sx + 3, sy + 18, 124, 2), Color(0.5, 0.32, 0.18))
		# dietro le tavolette: la parete di Thoth, più scura, con la cornice turchese
		draw_rect(Rect2(348, 30, 184, 72), Color(0.62, 0.55, 0.44))
		draw_rect(Rect2(348, 30, 184, 72), Color(0.3, 0.62, 0.66), false, 2.0)
		draw_rect(Rect2(0, 100, r.size.x, 4), Color(0.4, 0.3, 0.22))
		# pareti laterali e in basso
		draw_rect(Rect2(0, 104, 32, r.size.y), Color(0.32, 0.22, 0.16))
		draw_rect(Rect2(r.size.x - 32, 104, 32, r.size.y), Color(0.32, 0.22, 0.16))
		draw_rect(Rect2(0, r.size.y - 32, r.size.x, 32), Color(0.26, 0.18, 0.13))
		# la porta verso la Sala, a ovest
		draw_rect(Rect2(0, 184, 32, 52), Color(0.04, 0.03, 0.08))
		draw_rect(Rect2(29, 180, 3, 60), Color(0.94, 0.72, 0.3))
		# le lampade a olio sui loro sostegni
		for p: Vector2 in LAMPS:
			draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_line(p, p + Vector2(0, -12), Color(0.4, 0.28, 0.16), 2.0)
			draw_rect(Rect2(p.x - 5, p.y - 15, 10, 3), Color(0.72, 0.5, 0.3))
			draw_circle(p + Vector2(0, -18), 2.5, Color(1.0, 0.75, 0.35))
		# il tavolo basso degli scribi, con i rotoli aperti, il calamaio e le cannucce
		var tb := Vector2(330, 280)
		draw_set_transform(tb + Vector2(0, 10), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(tb.x - 40.6, tb.y - 12.6, 81.2, 20.2), Color(0.12, 0.08, 0.05))
		draw_rect(Rect2(tb.x - 40, tb.y - 12, 80, 8), Color(0.58, 0.38, 0.22))
		draw_rect(Rect2(tb.x - 40, tb.y - 4, 80, 11), Color(0.46, 0.3, 0.17))
		for k in range(3):
			var px := tb.x - 30.0 + k * 22.0
			draw_rect(Rect2(px, tb.y - 11, 18, 6), Color(0.92, 0.86, 0.68))
			for ln in range(2):
				draw_line(Vector2(px + 2, tb.y - 9 + ln * 2), Vector2(px + 15, tb.y - 9 + ln * 2), Color(0.2, 0.2, 0.2, 0.6), 0.6)
		draw_rect(Rect2(tb.x + 30, tb.y - 13, 6, 4), Color(0.86, 0.82, 0.7))
		draw_circle(Vector2(tb.x + 32, tb.y - 11), 0.9, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(tb.x + 34.5, tb.y - 11), 0.9, Color(0.7, 0.2, 0.15))
		# casse di legno dipinte e anfore negli angoli
		for c: Vector2 in [Vector2(70, 270), Vector2(590, 270)]:
			draw_rect(Rect2(c.x - 14.6, c.y - 14.6, 29.2, 21.2), Color(0.12, 0.08, 0.05))
			draw_rect(Rect2(c.x - 14, c.y - 14, 28, 20), Color(0.6, 0.4, 0.22))
			draw_rect(Rect2(c.x - 14, c.y - 14, 28, 4), Color(0.72, 0.5, 0.28))
			draw_rect(Rect2(c.x - 10, c.y - 7, 20, 2), Color(0.16, 0.3, 0.68))
			draw_rect(Rect2(c.x - 10, c.y - 3, 20, 2), Color(0.72, 0.26, 0.15))
