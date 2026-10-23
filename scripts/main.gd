extends Node2D
## Stanza di prova: pavimento, muri, due colonne e ondate di mummie sempre più grandi.

const ROOM := Rect2(0, 0, 800, 480)
const WALL := 32.0
const PlayerScene := preload("res://scenes/player.tscn")
const MummyScene := preload("res://scenes/mummy.tscn")
const PILLARS := [Vector2(240, 200), Vector2(560, 200), Vector2(240, 340), Vector2(560, 340)]

var player
var wave := 0
var alive := 0
var spawning := 0
var next_wave_t := 0.0

@onready var hud: Label = $UI/Hud
@onready var help: Label = $UI/Help
@onready var death: Label = $UI/Death
@onready var reticle: Node2D = $UI/Reticle


func _ready() -> void:
	Engine.time_scale = 1.0
	Fx.world = self
	Fx.set_hitboxes(Fx.show_hitboxes)
	_build_walls()
	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - 90.0)
	add_child(player)
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = int(ROOM.position.x)
	cam.limit_top = int(ROOM.position.y)
	cam.limit_right = int(ROOM.end.x)
	cam.limit_bottom = int(ROOM.end.y)
	player.died.connect(_on_player_died)
	death.visible = false
	next_wave_t = 1.0


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_hitbox"):
		Fx.set_hitboxes(not Fx.show_hitboxes)
	if Input.is_action_just_pressed("restart"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		return

	if alive == 0 and spawning == 0 and not player.dead:
		next_wave_t -= delta
		if next_wave_t <= 0.0:
			_spawn_wave()

	var dash_txt := "pronto" if player.dash_cd <= 0.0 else "%.1fs" % player.dash_cd
	var eye_txt := "pronto" if player.eye_cd <= 0.0 else "%.1fs" % player.eye_cd
	hud.text = "Vita %d/%d    Scatto: %s    Occhio di Horus: %s    Ondata %d" % [ceili(player.hp), int(player.max_hp), dash_txt, eye_txt, wave]

	var mouse := Fx.device == "mouse"
	reticle.visible = mouse and not player.dead
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if mouse else Input.MOUSE_MODE_VISIBLE
	if Fx.device == "pad":
		help.text = "Levetta sinistra muovi · destra mira · X khopesh · A scatto · Y Occhio · Start ricomincia"
	else:
		help.text = "WASD muovi · mouse mira · clic sinistro khopesh · Spazio scatto · clic destro Occhio · F1 hitbox · R ricomincia"


func _spawn_wave() -> void:
	wave += 1
	var count := 1 + wave
	for i in range(count):
		var pos := _free_spot()
		spawning += 1
		_spawn_after(pos, 0.8 + i * 0.15)


func _spawn_after(pos: Vector2, delay: float) -> void:
	var marker := SpawnMarker.new()
	marker.duration = delay
	add_child(marker)
	marker.position = pos
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(marker):
		marker.queue_free()
	spawning -= 1
	var m = MummyScene.instantiate()
	m.position = pos
	add_child(m)
	alive += 1
	m.killed.connect(_on_enemy_killed)


func _on_enemy_killed() -> void:
	alive -= 1
	if alive == 0 and spawning == 0:
		next_wave_t = 1.5


func _free_spot() -> Vector2:
	var p := Vector2.ZERO
	for i in range(40):
		p = Vector2(randf_range(WALL + 30.0, ROOM.size.x - WALL - 30.0), randf_range(WALL + 40.0, ROOM.size.y - WALL - 30.0))
		var ok: bool = p.distance_to(player.global_position) > 160.0
		for pl in PILLARS:
			if p.distance_to(pl) < 40.0:
				ok = false
		if ok:
			break
	return p


func _on_player_died() -> void:
	death.visible = true
	death.text = "Il tuo cuore è stato pesato.\nOndata raggiunta: %d\n\nPremi R (o Start) per ricominciare" % wave


func _build_walls() -> void:
	var r := ROOM
	_wall(Rect2(r.position.x, r.position.y, r.size.x, WALL * 2.0))
	_wall(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL))
	_wall(Rect2(r.position.x, r.position.y, WALL, r.size.y))
	_wall(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y))
	for p in PILLARS:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(26, 14)
		shape.shape = rect
		body.add_child(shape)
		body.position = p
		add_child(body)


func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.position = rect.get_center()
	add_child(body)


# ---------------------------------------------------------------- disegno provvisorio

func _draw() -> void:
	var r := ROOM
	var tile := 32.0
	var y := r.position.y + WALL * 2.0
	while y < r.end.y - WALL:
		var x := r.position.x + WALL
		while x < r.end.x - WALL:
			var n := fmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
			var c := Color(0.6, 0.46, 0.29).darkened(absf(n) * 0.12)
			draw_rect(Rect2(x + 1, y + 1, tile - 2, tile - 2), c)
			x += tile
		y += tile
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, WALL), Color(0.19, 0.13, 0.08))
	draw_rect(Rect2(r.position.x, r.position.y + WALL, r.size.x, WALL), Color(0.46, 0.33, 0.2))
	var i := 0
	var fx := r.position.x
	while fx < r.end.x:
		var band := Color(0.25, 0.66, 0.6) if i % 2 == 0 else Color(0.91, 0.69, 0.29)
		draw_rect(Rect2(fx, r.position.y + WALL + 12, 16, 6), band)
		fx += 16.0
		i += 1
	draw_rect(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL), Color(0.19, 0.13, 0.08))
	draw_rect(Rect2(r.position.x, r.position.y, WALL, r.size.y), Color(0.19, 0.13, 0.08))
	draw_rect(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y), Color(0.19, 0.13, 0.08))
	for p in PILLARS:
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
