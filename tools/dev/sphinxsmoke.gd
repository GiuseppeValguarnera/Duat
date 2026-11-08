extends SceneTree
## Blocchi 15-16: la prova della Sfinge. Schermata dei comandi, ondate fino alla 16 (guardiani alle
## 5, 10, 15: guardiano di Sokar, Ombra di Ieri, scarabeo di Khepri), pause della Sfinge ogni 3
## ondate (enigma alternando prudente e audace, poi il dono), premi settimanali, protezione della data,
## poi la morte: classifica e schermata finale. L'eroe non prende danni.
var frames := 0
var g = null
var picks := 0
var riddles := 0
var last_wave := 0
var seen := {}

func _initialize() -> void:
	root.get_node("Run").trial = true
	change_scene_to_file("res://scenes/game.tscn")

func _cards() -> Array:
	return g.menu.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("text"))

func _process(_d: float) -> bool:
	frames += 1
	var run = root.get_node("Run")
	if frames == 30:
		g = current_scene
		root.get_node("Fx").device = "touch"
		print("prova: trial=", g.trial != null, " arma=", run.weapon, " vita=", run.max_hp, " capitoli=", run.chap("c17"), " amuleto='", run.amulet, "'")
	if g == null or frames < 40:
		return false
	if frames == 40:
		var start = g.find_children("*", "Button", true, false).filter(func(b): return b.text == "Comincia")
		print("schermata dei comandi: ", start.size() == 1)
		for b in start:
			b.pressed.emit()
		# protezione della data: un orologio "indietro" non dà premi
		var sph = load("res://scripts/sphinx.gd")
		var m = root.get_node("Meta")
		var keep: int = m.sphinx.get("last_seen", 0)
		m.sphinx["last_seen"] = sph.now_unix() + 100000
		print("data indietro: clock_ok=", sph.clock_ok(), " premio=", sph.claim(20))
		m.sphinx["last_seen"] = keep
		return false
	if g.trial.ended:
		if frames % 60 == 0:
			var m = root.get_node("Meta")
			print("fine: punti=", g.trial.score, " ondata=", g.trial.wave, " audaci=", g.trial.hard_taken, " pulite=", g.trial.clean, " doni=", run.boons.size(), " premi=", g.trial.rewards)
			print("classifica: ", m.sphinx.get("scores", []).size(), " voci, settimana=", m.sphinx.get("claimed", []))
			return true
		return false
	if g.player != null and is_instance_valid(g.player):
		g.player.invuln_t = 5.0
	if g.trial.wave != last_wave:
		last_wave = g.trial.wave
		var kinds := {}
		for e in g.get_tree().get_nodes_in_group("enemies"):
			kinds[e.scene_file_path.get_file().get_basename()] = true
	if g.menu != null:
		if g.choice_state.get("cards", true) == false:
			g.choice_advance()
			return false
		var cs := _cards()
		if cs.is_empty():
			return false
		var b = cs[0]
		if cs.size() == 2:
			b = cs[riddles % 2]
			print("pausa dopo l'ondata ", g.trial.wave, ": enigma (", "audace" if riddles % 2 == 1 else "prudente", ")")
			riddles += 1
		picks += 1
		b.pressed.emit()
		b.pressed.emit()
		return false
	if frames % 20 == 0:
		for e in g.get_tree().get_nodes_in_group("enemies"):
			var k: String = e.scene_file_path.get_file().get_basename()
			if not seen.has(k):
				seen[k] = true
				print("ondata ", g.trial.wave, ": compare ", k, (" (élite)" if e.elite else ""), (" vita %.0f" % e.max_hp))
			if not e.dead:
				e.die()
	if g.trial.wave >= 17 and g.trial.running:
		print("hp x%.2f vel x%.2f danni x%.2f · hud: %s" % [run.trial_hp, run.trial_speed, run.trial_dmg, g.trial.hud_line()])
		g.player.invuln_t = 0.0
		g.player.take_damage(999.0, g.player.global_position + Vector2(10, 0))
	if frames > 60000:
		print("TROPPO LUNGA: ondata ", g.trial.wave)
		return true
	return false
