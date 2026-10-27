extends Node
## Una porta che compare mentre ci stai sopra: un passo verso l'interno (non ti porta via da
## sola), poi camminandoci dentro si passa davvero.
## Uso: tools/dev/shot.sh doorpush 1280 720 res://scenes/game.tscn
var t := 0.0
var step := 0
var room0 := 0
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
	p.hp = p.max_hp; p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu) and t > 0.5:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Run.room = 2; g.start_room({"kind": "ka"}); step = 1; t = 0
		1:
			if t > 1.2:
				g.waves = []
				for e in get_tree().get_nodes_in_group("enemies"): e.die()
				var at := Vector2(g.WALL + 6.0, (g.TOP + g.ROOM.size.y - g.WALL) / 2.0)
				p.global_position = at
				room0 = Run.room
				g._add_door("w", {"kind": "ka"})
				L("porta comparsa sotto di te: spinto a %s, stanza ancora %d (la porta non ti ha portato via: %s)" % [str(p.global_position), Run.room, str(Run.room == room0)])
				step = 2; t = 0
		2:
			Input.action_press("move_left")
			if Run.room != room0 or t > 3.0:
				Input.action_release("move_left")
				L("camminando verso la porta: stanza %d -> %d (passato=%s)" % [room0, Run.room, str(Run.room != room0)])
				get_tree().quit()
