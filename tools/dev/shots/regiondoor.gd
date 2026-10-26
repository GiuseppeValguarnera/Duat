extends Node
## Dopo Am-heh (con Sokar aperta) la porta verso la regione successiva deve essere raggiungibile
## camminando: il giocatore va verso la porta e la partita deve passare a Sokar.
## Uso: DUAT_REGION2=1 tools/dev/shot.sh regiondoor 1280 720 res://scenes/game.tscn
var t := 0.0
var step := 0
var photo_done := false
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	if g.menu != null and is_instance_valid(g.menu) and t > 0.6:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 10; g.start_room({"kind": "none"}); step = 1; t = 0
		1:
			if not get_tree().paused and t > 4.0 and g.boss != null and is_instance_valid(g.boss):
				g.boss.take_hit(g.boss.hp + 1.0, Vector2.UP, 0.0)
				step = 2; t = 0
		2:
			if t > 3.5 and not g.doors.is_empty():
				var d = g.doors[0]
				L("porta: tipo=%s posizione=%s" % [d.reward.get("kind", ""), str(d.global_position)])
				step = 3; t = 0
		3:
			# cammina verso la porta come farebbe un giocatore
			var d = g.doors[0] if not g.doors.is_empty() and is_instance_valid(g.doors[0]) else null
			if d != null:
				var dir: Vector2 = (d.global_position - p.global_position).normalized()
				Input.action_release("move_up"); Input.action_release("move_left"); Input.action_release("move_right")
				if dir.y < -0.3: Input.action_press("move_up")
				if dir.x < -0.3: Input.action_press("move_left")
				if dir.x > 0.3: Input.action_press("move_right")
			if not photo_done and p.global_position.y < 150.0:
				photo_done = true
				get_viewport().get_texture().get_image().save_png(D + "porta_regione_0.png")
			if t > 6.0 or Run.region == 2:
				Input.action_release("move_up"); Input.action_release("move_left"); Input.action_release("move_right")
				L("dopo %.1f s: regione=%d, giocatore a %s" % [t, Run.region, str(p.global_position)])
				get_viewport().get_texture().get_image().save_png(D + "porta_regione_1.png")
				get_tree().quit()
