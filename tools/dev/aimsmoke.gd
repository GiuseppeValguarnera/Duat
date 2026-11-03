extends SceneTree
## Controllo della mira assistita della mischia (blocco 12), senza partite: quattro scenari sulla
## funzione di bersaglio del giocatore (player.gd, _melee_pick).
var frames := 0
var p = null
var a = null
var b = null

func _initialize() -> void:
	var w := Node2D.new()
	root.add_child(w)
	p = load("res://scenes/player.tscn").instantiate()
	p.position = Vector2(400, 300)
	w.add_child(p)
	a = load("res://scenes/scarab.tscn").instantiate()
	b = load("res://scenes/scarab.tscn").instantiate()
	a.position = Vector2(-1000, -1000)
	b.position = Vector2(-1000, -1000)
	w.add_child(a)
	w.add_child(b)

func _pick(facing: Vector2, moving: bool) -> String:
	p.facing = facing
	p.aim = facing
	p.moving_input = moving
	p._melee_target = null
	var reach: float = p.COMBO[0]["range"]
	var t = p._melee_pick(p.aim, reach)
	var d: Vector2 = p._melee_aim(p.aim, reach)
	var who := "nessuno" if t == null else ("A" if t == a else "B")
	return "%s, direzione (%.2f, %.2f)" % [who, d.x, d.y]

func _process(_d: float) -> bool:
	frames += 1
	var fx = root.get_node("Fx")
	fx.device = "pad"
	root.get_node("Meta").options["autoaim"] = true
	match frames:
		2:
			a.position = Vector2(440, 300)
		4:
			print("mira 1 (nemico davanti, guardi a destra): ", _pick(Vector2.RIGHT, false))
			a.position = Vector2(440, 300)
		6:
			print("mira 2 (nemico dietro, cammini a sinistra): ", _pick(Vector2.LEFT, true))
			a.position = Vector2(445, 300)
			b.position = Vector2(400, 330)
		8:
			print("mira 3 (A a 45 px a destra, B a 30 px sotto; guardi a sinistra): ", _pick(Vector2.LEFT, true))
			a.position = Vector2(-1000, -1000)
			b.position = Vector2(-1000, -1000)
		10:
			print("mira 4 (nessun nemico, cammini in alto): ", _pick(Vector2.UP, true))
			return true
	return false
