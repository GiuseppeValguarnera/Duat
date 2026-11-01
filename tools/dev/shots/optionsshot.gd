extends Node
## Il menu Opzioni (blocco 2): dalla pausa di una stanza e nella Sala. Cambia i valori come con il
## pad (frecce), prova la grandezza del testo e la lingua, chiude con Esc.
## Uso: tools/dev/shot.sh optionsshot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var om = null
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "opt_" + n + ".png")
func _key(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
func _find_menu(root: Node):
	for c in root.get_children():
		if c is OptionsMenu:
			return c
	return null
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null:
		return
	if step >= 20:
		if g.name != "Hub":
			return
		match step:
			20:
				if t > 1.5:
					if g.talk_box.visible:
						g.talk_box.visible = false
					g._open_options()
					step = 21; t = 0
			21:
				if t > 0.6:
					om = _find_menu(g)
					L("Sala: menu aperto=%s, gioco fermo=%s, voci=%d" % [str(om != null), str(get_tree().paused), om.rows.size() if om != null else 0])
					_shot("4_sala")
					_key("pause")
					step = 22; t = 0
			22:
				if t > 0.4:
					L("Sala dopo Esc: menu chiuso=%s, gioco fermo=%s" % [str(_find_menu(g) == null), str(get_tree().paused)])
					get_tree().quit()
		return
	if g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	match step:
		0:
			if t > 1.2:
				g._toggle_pause()
				step = 1; t = 0
		1:
			if t > 0.3:
				g._open_options()
				step = 2; t = 0
		2:
			if t > 0.5:
				om = _find_menu(g)
				L("stanza: menu aperto=%s, pausa=%s, voci=%d, fuoco su=%s" % [str(om != null), str(get_tree().paused), om.rows.size(), om.focus_id])
				_shot("1_pausa_stanza")
				var v0: float = Sfx.volumes.get("musica", 0.7)
				_key("ui_left")
				L("musica con sinistra: %d%% -> %d%%" % [roundi(v0 * 100.0), roundi(Sfx.volumes.get("musica", 0.7) * 100.0)])
				_key("ui_right")
				step = 3; t = 0
		3:
			if t > 0.2:
				for i in range(4):
					_key("ui_down")
				step = 4; t = 0
		4:
			if t > 0.3:
				L("fuoco dopo 4 giù: %s" % om.focus_id)
				_key("ui_right")
				step = 5; t = 0
				L("grandezza testo: %s, Fx.ui %.2f" % [Meta.options.get("text", 0), Fx.ui])
		5:
			if t > 0.5:
				om = _find_menu(g)
				L("menu trovato=%s  opzioni=%s" % [str(om), str(Meta.options)])
				_shot("2_testo_grande")
				om._change("text", 1)
				L("dopo un _change(text): %s" % str(Meta.options))
				om._change("text", 1)
				om = _find_menu(g)
				om._change("lang", 1)
				step = 6; t = 0
		6:
			if t > 0.5:
				om = _find_menu(g)
				_shot("3_inglese")
				L("lingua ora: %s, testo %s" % ["en" if Lang.is_en() else "it", Meta.options.get("text", 0)])
				om._change("lang", 1)
				_key("ui_cancel")
				step = 7; t = 0
		7:
			if t > 0.4:
				L("dopo Esc: menu chiuso=%s, pausa ancora aperta=%s, gioco fermo=%s" % [str(_find_menu(g) == null), str(g.pause_menu != null and g.pause_menu.visible), str(get_tree().paused)])
				g._toggle_pause()
				g._abandon_run()
				step = 20; t = 0
