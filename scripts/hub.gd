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
var book: CanvasLayer = null           # finestra aperta (Libro dei Morti o Papiri di Thoth)
var book_kind := ""
var page_title: Label
var page_body: Label
var page_lore: Label
var papiri_entries: VBoxContainer
var codex: Array = []
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
		"papiri": Vector2(cx + 230.0, 310.0),
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
	_solid(Rect2(spots["papiri"] - Vector2(20, 8), Vector2(40, 12)))
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
			_open_book("libro")
		elif near == "papiri":
			_open_book("papiri")
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
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	outer.add_child(title)
	var sub := Label.new()
	sub.text = sub_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	outer.add_child(sub)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	outer.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(left_width, 0)
	left.add_theme_constant_override("separation", 3)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	page_title = _text_label(right, 12, Color(0.94, 0.72, 0.3))
	page_body = _text_label(right, 10, Color(0.95, 0.9, 0.78))
	page_lore = _text_label(right, 9, Color(0.72, 0.68, 0.9))
	var hint := Label.new()
	hint.text = "E / Y / B per chiudere"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	outer.add_child(hint)
	return left


func _text_label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _list_button(parent: Control, text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_focus_color", Color(0.94, 0.72, 0.3))
	b.add_theme_color_override("font_hover_color", Color(0.94, 0.72, 0.3))
	b.focus_entered.connect(Sfx.play.bind("ui", 0.0))
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- Libro dei Morti

func _fill_book(focus_id: String = "") -> void:
	var left := _frame("Il Libro dei Morti", "Ka custodito: %d    ·    Capitoli attivi: %d di %d" % [Meta.ka_bank, Meta.chapters_equipped.size(), Chapters.slots()], 250)
	var first: Button = null
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		var state := "%d Ka" % c["cost"]
		var col := Color(0.95, 0.9, 0.78)
		if Chapters.is_equipped(id):
			state = "ATTIVO"
			col = Color(0.62, 0.95, 0.7)
		elif Chapters.is_unlocked(id):
			state = "comprato"
		elif Meta.ka_bank < int(c["cost"]):
			col = Color(0.6, 0.55, 0.48)
		var b := _list_button(left, "%d · %s   [%s]" % [c["num"], c["name"], state], col)
		b.pressed.connect(_on_chapter_pressed.bind(id))
		b.focus_entered.connect(_show_chapter.bind(id))
		b.mouse_entered.connect(_show_chapter.bind(id))
		if first == null or id == focus_id:
			first = b
	first.grab_focus.call_deferred()


func _show_chapter(id: String) -> void:
	var c: Dictionary = Chapters.ALL[id]
	page_title.text = "Capitolo %d · %s" % [c["num"], c["name"]]
	var action := ""
	if Chapters.is_equipped(id):
		action = "Attivo. Premi per toglierlo."
	elif Chapters.is_unlocked(id):
		action = "Comprato. Premi per attivarlo (posti liberi: %d)." % (Chapters.slots() - Meta.chapters_equipped.size())
	elif Meta.ka_bank >= int(c["cost"]):
		action = "Premi per comprarlo: %d Ka." % c["cost"]
	else:
		action = "Costa %d Ka: te ne mancano %d." % [c["cost"], int(c["cost"]) - Meta.ka_bank]
	page_body.text = "%s\n\n%s" % [c["desc"], action]
	page_lore.text = c["lore"]


func _on_chapter_pressed(id: String) -> void:
	if Chapters.is_unlocked(id):
		if Chapters.toggle(id):
			Sfx.play("page", 0.0)
		else:
			Fx.shake(2.0)
	elif Chapters.buy(id):
		Sfx.play("boon", 0.0)
	_fill_book(id)


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
	_draw_papiri(spots["papiri"])


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
