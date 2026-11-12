extends Node
## Giro della Sfinge per guardarla: arrivo, statua, dialogo, menu, modificatori, Tesoro, comandi, ondata,
## pausa (enigma e dono), morte (commento e riepilogo).
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
var orn := OS.get_environment("DUAT_ORN") != ""
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Meta.sphinx["open"] = true
	Meta.sphinx["seals"] = 300
	if orn:
		Meta.sphinx["owned"] = ["o_collare", "o_gioielli", "o_loti", "o_bracieri", "o_stendardi", "d_ricordi"]
		Meta.sphinx["orn_on"] = ["o_collare", "o_gioielli", "o_loti", "o_bracieri", "o_stendardi"]
		Meta.sphinx["visits"] = 3
	Run.trial = true
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "sph_" + n + ".png")
func _btn(txt: String) -> Button:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and txt in b.text:
			return b
	return null
func _tb():
	for n in get_tree().current_scene.find_children("*", "Control", true, false):
		if n.has_method("_advance") and not n.closing:
			return n
	return null
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.trial == null:
		return
	if g.player != null and is_instance_valid(g.player) and step < 30:
		g.player.invuln_t = 2.0
	match step:
		0:
			if t > 1.5:
				shot("00_arrivo"); step = 1; t = 0
				g.player.global_position = g.trial.statue.global_position + Vector2(-40, 36)
		1:
			if t > 1.2:
				shot("01_davanti"); step = 2; t = 0
				g.trial.statue.say("Mi stai fissando. Io ti fisso da prima che tu nascessi.")
		2:
			if t > 0.8:
				shot("02_fumetto"); step = 3; t = 0
				g.trial.open_menu()
		3:
			if t > 0.25:
				shot("03_dialogo_scrive"); step = 4; t = 0
		4:
			var tb = _tb()
			if tb != null and not tb.grid.visible:
				if t > 0.3:
					tb._advance(); t = 0
			elif tb != null and t > 0.5:
				shot("04_menu"); step = 5; t = 0
				_btn("Modificatori").pressed.emit()
		5:
			if t > 0.5:
				_btn("Pietra Dura").pressed.emit()
				step = 6; t = 0
		6:
			if t > 0.4:
				shot("05_modificatori"); step = 7; t = 0
				_btn("Fatto").pressed.emit()
		7:
			var tb = _tb()
			if tb != null and not tb.grid.visible:
				if t > 0.2:
					tb._advance(); t = 0
			elif tb != null and t > 0.4:
				_btn("Tesoro").pressed.emit(); step = 8; t = 0
		8:
			if t > 0.5:
				shot("06_tesoro"); step = 9; t = 0
				_btn("Chiudi").pressed.emit()
		9:
			var tb = _tb()
			if tb != null and not tb.grid.visible:
				if t > 0.2:
					tb._advance(); t = 0
			elif tb != null and t > 0.4:
				_btn("Accetta").pressed.emit(); step = 10; t = 0
		10:
			if t > 0.6:
				shot("07_comandi"); step = 11; t = 0
				var b := _btn("Comincia")
				if b != null:
					b.pressed.emit()
		11:
			if t > 1.2:
				shot("08_inizio"); step = 12; t = 0
		12:
			if t > 4.0:
				shot("09_ondata1"); step = 13; t = 0
		13:
			# salta alla fine dell'ondata 3: uccidi tutto finché non si apre la pausa
			if g.menu != null:
				if g.choice_state.get("cards", true) == false:
					if t > 0.6:
						shot("10_enigma_testo"); g.choice_advance(); t = 0
				elif t > 0.8:
					shot("11_enigma_carte"); step = 14; t = 0
					var cs = g.menu.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("text"))
					cs[1].pressed.emit(); cs[1].pressed.emit()
			elif t > 0.4:
				t = 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if not e.dead:
						e.die()
		14:
			if g.menu != null and t > 1.0:
				shot("12_doni"); step = 15; t = 0
				var cs = g.menu.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("text"))
				cs[0].pressed.emit(); cs[0].pressed.emit()
		15:
			if g.trial.wave >= 5 and g.trial.running and t > 3.5:
				shot("13_guardiano"); step = 16; t = 0
			elif g.trial.wave < 5 and t > 0.4:
				t = 0
				for e in get_tree().get_nodes_in_group("enemies"):
					if not e.dead:
						e.die()
		16:
			step = 30; t = 0
			Run.last_hit = "scorpion"
			g.player.invuln_t = 0.0
			g.player.take_damage(999.0, g.player.global_position + Vector2(10, 0))
		30:
			var tb = _tb()
			if tb != null and tb.text.visible_characters == -1 and t > 0.4:
				shot("14_morte_%d" % tb.i); tb._advance(); t = 0
			elif tb == null and t > 2.5 and _btn("Riprova") != null:
				shot("15_riepilogo"); get_tree().quit()
			elif tb != null and t > 1.0:
				tb._advance(); t = 0
