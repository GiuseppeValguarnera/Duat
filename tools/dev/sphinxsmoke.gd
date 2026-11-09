extends SceneTree
## Blocchi 15-17: la prova della Sfinge. Si entra, la prova non parte; si parla con la Sfinge (dialogo
## a macchina da scrivere + menu), si scelgono due modificatori, si compra nel Tesoro con i sigilli
## (ornamento, Favore), si accetta. Schermata dei comandi, ondate fino alla 16 (guardiani alle 5, 10,
## 15), pause ogni 3 ondate (enigma alternando prudente e audace, poi un dono della Sfinge), premi
## settimanali, protezione della data, poi la morte: commento della Sfinge, riepilogo, classifica.
var frames := 0
var g = null
var picks := 0
var riddles := 0
var seen := {}
var accepted := false
var end_frame := 0

func _initialize() -> void:
	root.get_node("Run").trial = true
	change_scene_to_file("res://scenes/game.tscn")

func _cards() -> Array:
	return g.menu.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("text"))

func _talkbox():
	for n in g.find_children("*", "Control", true, false):
		if n.get_script() != null and n.has_method("_advance") and not n.closing:
			return n
	return null

func _process(_d: float) -> bool:
	frames += 1
	var run = root.get_node("Run")
	var m = root.get_node("Meta")
	if frames == 30:
		g = current_scene
		root.get_node("Fx").device = "touch"
		print("prova: trial=", g.trial != null, " arma=", run.weapon, " vita=", run.max_hp, " capitoli=", run.chap("c17"), " amuleto='", run.amulet, "' partita=", g.trial.started)
		m.sphinx["seals"] = 520
		var shop = load("res://scripts/sphinx_shop.gd")
		print("modificatori: ", shop.toggle_mod("tough"), shop.toggle_mod("first"), shop.toggle_mod("horde"), " attivi=", shop.mods_on())
		print("Tesoro: collare=", shop.buy("o_collare"), " favore=", shop.buy("favore"), " sigilli=", shop.seals(), " favore nelle discese=", root.get_node("Meta").favors.has("favore_sfinge"))
		print("doni della Sfinge per le discese: ", load("res://scripts/boons.gd").sphinx_pool({}, false).size(), " (nella prova ", load("res://scripts/boons.gd").sphinx_pool({}, true).size(), ")")
	if g == null or frames < 40:
		return false
	if frames == 40:
		var sph = load("res://scripts/sphinx.gd")
		var keep: int = m.sphinx.get("last_seen", 0)
		m.sphinx["last_seen"] = sph.now_unix() + 100000
		print("data indietro: clock_ok=", sph.clock_ok(), " premio=", sph.claim(20))
		m.sphinx["last_seen"] = keep
		g.player.global_position = g.trial.statue.global_position + Vector2(0, 30)
		print("davanti alla Sfinge: ", g.trial.near_statue(), " · ", g.trial.prompt_text())
		g.trial.open_menu()
		return false
	# il dialogo della Sfinge: completa il testo, poi «Accetta la prova» (o avanti, se è un commento)
	var tb = _talkbox()
	if tb != null:
		if tb.grid.visible:
			var b: Button = tb.grid.get_child(0)
			print("menu della Sfinge: ", tb.grid.get_child_count(), " voci, prima: ", b.text, " · righe: ", tb.lines.size())
			b.pressed.emit()
			accepted = true
		else:
			if frames % 3 == 0:
				if g.trial.ended and tb.text.visible_characters == -1:
					print("la Sfinge commenta: ", tb.text.text)
				tb._advance()
		return false
	for b in g.find_children("*", "Button", true, false):
		if b.text in ["Comincia", "Start"] and b.is_visible_in_tree():
			print("schermata dei comandi")
			b.pressed.emit()
			return false
	if g.trial.ended:
		if end_frame == 0:
			end_frame = frames
		if frames - end_frame > 400:
			print("fine: punti=", g.trial.total_score(), " (grezzi ", g.trial.score, ") ondata=", g.trial.wave, " audaci=", g.trial.hard_taken, " pulite=", g.trial.clean, " doni=", run.boons.keys(), " premi=", g.trial.rewards, " sigilli=", g.trial.seals_got)
			var sc: Array = m.sphinx.get("scores", [])
			print("classifica: ", sc.size(), " voci, mod=", sc[0].get("mods", []) if not sc.is_empty() else [], " settimana=", m.sphinx.get("claimed", []), " ultime battute=", m.sphinx.get("last_line", {}))
			return true
		return false
	if g.player != null and is_instance_valid(g.player):
		g.player.invuln_t = 5.0
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
	if frames % 20 == 0 and g.trial.started:
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
		run.sf_second_used = true
		g.player.take_damage(999.0, g.player.global_position + Vector2(10, 0))
	if frames > 60000:
		print("TROPPO LUNGA: ondata ", g.trial.wave)
		return true
	return false
