extends Node
## Prova di carico: tutti i Pesi del Cuore al massimo, poi gli scenari più pesanti del gioco.
## Per ogni scenario misura a ogni fotogramma il tempo di calcolo (logica + fisica), il tempo del
## fotogramma intero, quanti fotogrammi superano 1/60 e 1/30 di secondo, nodi e nemici in scena.
## Uso: DUAT_REGION2=1 tools/dev/shot.sh stressshot 1280 720 res://scenes/game.tscn [mobile]
## Senza disegno (solo logica e fisica): lo stesso, con Godot --headless.
## STRESS_KIND=<tipo> riempie l'orda con un solo tipo di nemico ("dummy" = il manichino);
## STRESS_EXP=no_aree / no_urti / no_corpi / no_interp: esperimenti sul motore fisico.
var t := 0.0
var step := 0
var sc := 0
var setup_done := false
var D := OS.get_environment("DUAT_SHOTS") + "/"
const DUR := 10.0
# misure dello scenario in corso
var frames := 0
var cpu_sum := 0.0
var cpu_max := 0.0
var dt_sum := 0.0
var dt_max := 0.0
var over60 := 0
var over30 := 0
var nodes_max := 0
var enemies_max := 0
var draws_max := 0
var stone_t := 0.0
var proc_sum := 0.0
var scripts_sum := 0.0
var pairs_max := 0
var t_start := 0


class Mark extends Node:
	var first := true
	var owner_test: Node = null
	func _physics_process(_d: float) -> void:
		if first:
			owner_test.t_start = Time.get_ticks_usec()
		else:
			owner_test.scripts_sum += (Time.get_ticks_usec() - owner_test.t_start) / 1000000.0
var phys_sum := 0.0
var SCEN: Array = ["3_orda_100"] if OS.get_environment("STRESS_KIND") != "" else ["0_vuota", "1_wernes_stanza8", "2_sokar_stanza8", "3_orda_100", "4_amheh_marea", "5_serket", "6_aker_pietre_raggi", "7_ieri_e_domani"]


func L(x: String) -> void:
	print("LOG ", x)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := Mark.new()
	a.owner_test = self
	a.process_physics_priority = -100000
	add_child(a)
	var b := Mark.new()
	b.first = false
	b.owner_test = self
	b.process_physics_priority = 100000
	add_child(b)


func _reset() -> void:
	scripts_sum = 0.0; proc_sum = 0.0; phys_sum = 0.0; pairs_max = 0
	frames = 0; cpu_sum = 0.0; cpu_max = 0.0; dt_sum = 0.0; dt_max = 0.0
	over60 = 0; over30 = 0; nodes_max = 0; enemies_max = 0; draws_max = 0


func _measure(dt: float) -> void:
	var mode := OS.get_environment("STRESS_EXP")
	for e in get_tree().get_nodes_in_group("enemies"):
		if mode == "no_aree" and e.contact != null:
			e.contact.monitoring = false
		if mode == "no_urti":
			e.collision_mask = 1
		if mode == "no_corpi":
			for c in e.find_children("*", "CollisionShape2D", true, false):
				c.set_deferred("disabled", true)
		if mode == "no_interp":
			e.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var cpu := Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	proc_sum += Performance.get_monitor(Performance.TIME_PROCESS)
	pairs_max = maxi(pairs_max, int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)))
	phys_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	frames += 1
	cpu_sum += cpu
	cpu_max = maxf(cpu_max, cpu)
	dt_sum += dt
	dt_max = maxf(dt_max, dt)
	if cpu > 1.0 / 60.0:
		over60 += 1
	if cpu > 1.0 / 30.0:
		over30 += 1
	nodes_max = maxi(nodes_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	enemies_max = maxi(enemies_max, get_tree().get_nodes_in_group("enemies").size())
	draws_max = maxi(draws_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))


func _report(scen: String) -> void:
	var f := maxf(1.0, frames)
	L("  _process %.2f ms   _physics (script + motore fisico) %.2f ms   di cui tutti gli script %.2f ms   coppie di collisione max %d" % [proc_sum / f * 1000.0, phys_sum / f * 1000.0, scripts_sum / f * 1000.0, pairs_max])
	L("%-22s fotogrammi=%d  calcolo medio=%.1fms max=%.1fms  oltre 16ms=%d oltre 33ms=%d  fotogramma medio=%.1fms max=%.1fms  nodi max=%d nemici max=%d draw max=%d" % [
		scen, frames, cpu_sum / f * 1000.0, cpu_max * 1000.0, over60, over30, dt_sum / f * 1000.0, dt_max * 1000.0, nodes_max, enemies_max, draws_max])


func _max_weights() -> void:
	Meta.ammit_wins = maxi(Meta.ammit_wins, 1)
	Meta.feather = false
	var w := {}
	for id in Weights.ALL:
		w[id] = int(Weights.ALL[id]["max"])
	Meta.weights = w
	L("pesi al massimo: totale %d  %s" % [Weights.total(), str(w)])


func _spawn(g, kind: String, pos: Vector2, elite: bool) -> void:
	var e = g.DummyScript.new() if kind == "dummy" else g.ENEMIES[kind].instantiate()
	e.elite = elite
	e.position = pos
	g.world.add_child(e)
	g.alive += 1
	e.killed.connect(g._on_enemy_killed)


func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	p.invuln_t = 1.0
	p.poison_t = 0.0
	if g.menu != null and is_instance_valid(g.menu) and t > 0.5:
		g._close_choice()
	if step == 0:
		if t > 1.0:
			_max_weights()
			step = 1; t = 0.0; setup_done = false
		return
	if sc >= SCEN.size():
		L("FINE")
		get_tree().quit()
		return
	var scen: String = SCEN[sc]
	if not setup_done:
		setup_done = true
		_reset()
		match scen:
			"0_vuota":
				Run.region = 1; Run.room = 0
				g.start_room({"kind": "shop"})
			"1_wernes_stanza8":
				Run.region = 1; Run.room = 7
				g.start_room({"kind": "ka"})
			"2_sokar_stanza8":
				Run.region = 2; Run.room = 7
				g.start_room({"kind": "ka"})
			"3_orda_100":
				Run.region = 2; Run.room = 7
				g.start_room({"kind": "ka"})
			"4_amheh_marea":
				Run.region = 1; Run.room = 10
				g.start_room({"kind": "none"})
			"5_serket":
				Run.region = 2; Run.room = 4
				g.start_room({"kind": "guardian"})
			"6_aker_pietre_raggi":
				Run.region = 2; Run.room = 10
				g.start_room({"kind": "none"})
			"7_ieri_e_domani":
				pass
		t = 0.0
		return
	# preparazione dentro lo scenario (dopo che la stanza è pronta)
	if t > 1.2 and t - dt <= 1.2:
		match scen:
			"3_orda_100":
				g.waves = []
				var kinds := ["mummy", "scarab", "priest", "cobra", "crocodile", "jackal", "vulture", "sokar_guard", "damned_ba", "scorpion"]
				var only := OS.get_environment("STRESS_KIND")
				if only != "":
					kinds = [only]
				for i in range(100):
					var a := TAU * i / 100.0
					var pos: Vector2 = Vector2(g.ROOM.size.x / 2.0, (g.TOP + g.ROOM.size.y) / 2.0) + Vector2(cos(a) * 260.0, sin(a) * 140.0)
					_spawn(g, kinds[i % kinds.size()], pos, i % 4 == 0)
			"6_aker_pietre_raggi":
				pass
	if scen == "4_amheh_marea" and g.boss != null and is_instance_valid(g.boss) and not get_tree().paused:
		if t > 4.0 and int(t * 2.0) % 6 == 0 and g.boss.state == "chase":
			g.boss._howl()
	if scen == "6_aker_pietre_raggi" and g.boss != null and is_instance_valid(g.boss) and g.boss.has_method("_drop_stones") and not get_tree().paused:
		var b = g.boss
		if b.get("split_done") == false and t > 4.0:
			stone_t -= dt
			if stone_t <= 0.0:
				stone_t = 2.0
				b._drop_stones(8)             # pietre ben più spesso del normale: il caso peggiore
			if b.state == "stalk":
				b._fire_ray(p.global_position - b.global_position, 100.0, 9.0)
	if scen == "7_ieri_e_domani":
		var b = g.boss
		if b != null and is_instance_valid(b) and b.get("split_done") == false:
			b.take_hit(b.hp, Vector2.UP, 0.0)
	# misura dopo la presentazione del boss (il gioco è in pausa mentre si presenta)
	if not get_tree().paused and t > 2.0:
		_measure(dt)
	if dt_sum >= DUR:
		_report(scen)
		if DisplayServer.get_name() != "headless":
			get_viewport().get_texture().get_image().save_png(D + "stress_" + scen + ".png")
		sc += 1
		setup_done = false
		t = 0.0
