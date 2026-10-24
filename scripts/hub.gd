extends Node2D
## La Sala del Giudizio: dove ti risvegli tra una discesa e l'altra.
## - Anubi: parla con te, e le sue battute cambiano con le tue morti e vittorie.
## - Il Libro dei Morti: compri e attivi i capitoli con il Ka custodito.
## - La bilancia di Ma'at: mostra i tuoi progressi.
## - Il cancello a nord: inizia una nuova discesa.

const ROOM := Rect2(0, 0, 640, 400)
const WALL := 32.0
const TOP := 64.0
const PlayerScene := preload("res://scenes/player.tscn")
const DecorScript := preload("res://scripts/room_decor.gd")

var player
var spots := {}                       # nome -> posizione dei punti con cui interagire
var near := ""
var talk_lines: Array = []
var commented := false
var book: CanvasLayer = null
var t := 0.0
var quit_asked := -10.0

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
	Run.in_hub = true
	Run.new_run()
	Fx.world = world
	var cx := ROOM.size.x / 2.0
	spots = {
		"anubi": Vector2(cx - 120.0, 200.0),
		"libro": Vector2(cx + 120.0, 200.0),
		"bilancia": Vector2(cx, 190.0),
		"cancello": Vector2(cx, TOP + 4.0),
	}
	_build()
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
	var decor := DecorScript.new()
	world.add_child(decor)
	for r in decor.build(424242, ROOM, TOP, WALL, [], true):
		_solid(r)
	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - WALL - 30.0)
	world.add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM.size.x)
	cam.limit_bottom = int(ROOM.size.y)
	cam.reset_smoothing()
	queue_redraw()


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
	if Fx.device == "pad":
		help.text = "Levetta muovi · LB/A scatto · Y interagisci · Start ×2 esci"
	else:
		help.text = "WASD muovi · Spazio scatto · E interagisci · Esc ×2 esci dal gioco"

	if talk_box.visible or book != null:
		prompt.visible = false
		return
	# il cancello si attraversa camminandoci dentro
	if player.global_position.y < TOP + 14.0 and absf(player.global_position.x - spots["cancello"].x) < 22.0:
		_start_run()
		return
	near = ""
	for k in ["anubi", "libro", "bilancia"]:
		if player.global_position.distance_to(spots[k]) < 40.0:
			near = k
	var key := "Y" if Fx.device == "pad" else "E"
	match near:
		"anubi":
			prompt.text = "%s · Parla con Anubi" % key
		"libro":
			prompt.text = "%s · Apri il Libro dei Morti" % key
		"bilancia":
			prompt.text = "La bilancia di Ma'at · %d discese, %d Ka custodito, capitoli attivi %d/%d" % [Meta.runs, Meta.ka_bank, Meta.chapters_equipped.size(), Chapters.slots()]
		_:
			prompt.text = "Il cancello del Duat è a nord" if player.global_position.y < TOP + 90.0 else ""
	prompt.visible = prompt.text != ""


func _unhandled_input(event: InputEvent) -> void:
	if book != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			_close_book()
			get_viewport().set_input_as_handled()
		return
	if talk_box.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
			_advance_talk()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if near == "anubi":
			_start_talk()
		elif near == "libro":
			_open_book()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		# per uscire serve una seconda pressione entro 2 secondi, così non si chiude per sbaglio
		if t - quit_asked < 2.0:
			get_tree().quit()
		quit_asked = t
		Fx.float_text(player.global_position + Vector2(0, -30), "Premi di nuovo per uscire", Color(0.95, 0.9, 0.78))


func _start_run() -> void:
	Meta.last_end = ""
	Meta.save()
	Sfx.play("door")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------- dialoghi

func _start_talk() -> void:
	talk_lines = Dialogue.next_lines(commented)
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


# ---------------------------------------------------------------- Libro dei Morti

func _open_book() -> void:
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("book", 0.0)
	book = CanvasLayer.new()
	book.layer = 20
	add_child(book)
	_fill_book()


func _fill_book(focus_id: String = "") -> void:
	for c in book.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.08, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	book.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-220, -160)
	box.custom_minimum_size = Vector2(440, 320)
	box.add_theme_constant_override("separation", 4)
	book.add_child(box)
	var title := Label.new()
	title.text = "Il Libro dei Morti"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Ka custodito: %d    ·    Capitoli attivi: %d di %d" % [Meta.ka_bank, Meta.chapters_equipped.size(), Chapters.slots()]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	box.add_child(sub)
	var first: Button = null
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		var state := ""
		if Chapters.is_equipped(id):
			state = "ATTIVO · premi per toglierlo"
		elif Chapters.is_unlocked(id):
			state = "comprato · premi per attivarlo"
		elif Meta.ka_bank >= int(c["cost"]):
			state = "compra per %d Ka" % c["cost"]
		else:
			state = "costa %d Ka" % c["cost"]
		var b := Button.new()
		b.text = "Capitolo %d · %s    [%s]\n%s" % [c["num"], c["name"], state, c["desc"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 9)
		var col := Color(0.95, 0.9, 0.78)
		if Chapters.is_equipped(id):
			col = Color(0.62, 0.95, 0.7)
		elif not Chapters.is_unlocked(id) and Meta.ka_bank < int(c["cost"]):
			col = Color(0.6, 0.55, 0.48)
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_focus_color", Color(0.94, 0.72, 0.3))
		b.add_theme_color_override("font_hover_color", Color(0.94, 0.72, 0.3))
		b.pressed.connect(_on_chapter_pressed.bind(id))
		b.focus_entered.connect(Sfx.play.bind("ui", 0.0))
		box.add_child(b)
		if first == null or id == focus_id:
			first = b
	var hint := Label.new()
	hint.text = "E / Y / B per chiudere"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	box.add_child(hint)
	first.grab_focus.call_deferred()


func _on_chapter_pressed(id: String) -> void:
	if Chapters.is_unlocked(id):
		if Chapters.toggle(id):
			Sfx.play("page", 0.0)
		else:
			Fx.shake(2.0)
	elif Chapters.buy(id):
		Sfx.play("boon", 0.0)
	_fill_book(id)


func _close_book() -> void:
	Sfx.play("page", 0.0)
	book.queue_free()
	book = null
	player.set_physics_process(true)


# ---------------------------------------------------------------- disegno

func _draw() -> void:
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


func _draw_scale(p: Vector2) -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var tilt := sin(t * 0.8) * 3.0
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
