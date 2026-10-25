extends RefCounted
## L'addestramento (solo la prima volta). Prima stava in game.gd: è stato spostato qui nel
## riordino del codice, uguale. `g` è la partita (scripts/game.gd).
## Una stanza vera, con fantocci al posto dei nemici: un passo alla volta, con il testo
## in un riquadro fisso in alto (mai sopra i nemici). Qui non si può morire.
## Passi: muoversi, khopesh, scatto, Occhio di Horus, Ka, porta.

var g: Game

var step := -1
var panel: PanelContainer
var title_label: Label
var body_label: Label
var start := Vector2.ZERO
var walked := 0.0
var targets: Array = []
var dodges := 0
var dashes := 0
var prev_dash := false
var wait := 0.0

const STEPS := 6


func _init(game: Game) -> void:
	g = game


func ctl(what: String) -> String:
	var dev := Fx.device
	match what:
		"move":
			return {"pad": "la levetta sinistra", "touch": "la levetta a sinistra"}.get(dev, "W A S D (o le frecce)")
		"attack":
			return {"pad": "X o RB", "touch": "il pulsante KHOPESH"}.get(dev, "il clic sinistro (o J)")
		"dash":
			return {"pad": "A o LB", "touch": "il pulsante SCATTO"}.get(dev, "Spazio")
		"eye":
			return {"pad": "Y o RT", "touch": "il pulsante OCCHIO"}.get(dev, "il clic destro (o L)")
	return ""


func begin() -> void:
	Music.play("hub")
	step = -1
	panel = PanelContainer.new()
	var box := UiStyle.papyrus_box(UiStyle.GOLD.darkened(0.3))
	box.content_margin_left = 7
	box.content_margin_right = 7
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.93
	g.get_node("UI").add_child(panel)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	panel.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	title_label = UiStyle.label("", 8, UiStyle.INK, true)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	var skip := Button.new()
	skip.text = "Salta ›"
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", Fx.fs(8))
	skip.add_theme_color_override("font_color", UiStyle.INK_RED)
	skip.add_theme_color_override("font_hover_color", UiStyle.INK)
	skip.pressed.connect(finish)
	skip.add_to_group("touch_tap")          # sul telefono il tocco arriva da touch_controls.gd
	top.add_child(skip)
	body_label = UiStyle.label("", 8, UiStyle.INK_SOFT, false, width() - 14.0)
	body_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	col.add_child(body_label)
	panel.custom_minimum_size = Vector2(width(), 0)
	next()


## Il riquadro sta in alto, tra l'HUD a sinistra e i pulsanti del telefono a destra, ed è
## stretto: i fantocci restano sempre visibili sotto.
func width() -> float:
	var vw := g.get_viewport().get_visible_rect().size.x
	var left := 168.0 if not Fx.mobile else 156.0
	var right := vw - (84.0 if Fx.device == "touch" or Fx.mobile else 10.0)
	return clampf(right - left, 180.0, 300.0)


func place() -> void:
	if panel == null:
		return
	panel.reset_size()
	var vw := g.get_viewport().get_visible_rect().size.x
	var left := 168.0 if not Fx.mobile else 156.0
	var right := vw - (84.0 if Fx.device == "touch" or Fx.mobile else 10.0)
	var x := clampf((vw - panel.size.x) / 2.0, left, maxf(left, right - panel.size.x))
	panel.position = Vector2(x, 6.0)


func say(title: String, body: String) -> void:
	title_label.text = "%d/%d · %s" % [step + 1, STEPS, title]
	body_label.text = body
	body_label.visible_ratio = 0.0
	body_label.create_tween().tween_property(body_label, "visible_ratio", 1.0, clampf(body.length() * 0.008, 0.3, 0.8))
	place.call_deferred()
	Sfx.play("ui", 0.0)
	panel.modulate = Color(1.5, 1.3, 1.0, 0.93)
	panel.create_tween().tween_property(panel, "modulate", Color(1, 1, 1, 0.93), 0.4)


func dummy(pos: Vector2, eye_only: bool = false, lunger: bool = false) -> Enemy:
	var d: Enemy = g.DummyScript.new()
	d.eye_only = eye_only
	d.lunger = lunger
	d.position = pos
	g.world.add_child(d)
	Fx.burst(pos + Vector2(0, -10), Color(0.9, 0.8, 0.6), 12, 70.0)
	targets.append(d)
	return d


func clear_targets() -> void:
	for d in targets:
		if is_instance_valid(d) and not d.dead:
			d.die()
	targets.clear()


func next() -> void:
	step += 1
	wait = 0.0
	var mid := Vector2(g.ROOM.size.x / 2.0, g.ROOM.size.y / 2.0 + 20.0)
	match step:
		0:
			start = g.player.global_position
			walked = 0.0
			say("Il cammino", "Anubi ti fa provare le armi prima della discesa. Muoviti con %s." % ctl("move"))
		1:
			dummy(Vector2(mid.x - 50.0, 340.0))
			dummy(Vector2(mid.x + 50.0, 340.0))
			say("Il khopesh", "Rompi i due fantocci con %s. Il terzo colpo di fila è il più forte." % ctl("attack"))
		2:
			var m := dummy(Vector2(mid.x, 290.0), false, true)
			m.dodged.connect(func() -> void: dodges += 1)
			dodges = 0
			dashes = 0
			say("Lo scatto", "Rosso = sta per colpire. Quando la mummia carica premi %s: durante lo scatto nulla ti tocca. Hai due scatti, poi una breve pausa (i puntini sotto i piedi). Schivala 2 volte." % ctl("dash"))
		3:
			clear_targets()
			for at in [Vector2(110, 320), Vector2(g.ROOM.size.x - 110.0, 320), Vector2(mid.x, 300)]:
				dummy(at, true)
			say("L'Occhio di Horus", "I fantocci azzurri si rompono solo con l'Occhio: %s. Si ricarica da solo (il cerchio in alto)." % ctl("eye"))
		4:
			var p = g.PickupScript.new()
			p.kind = "ka"
			g.world.add_child(p)
			p.position = mid
			p.collected.connect(g._on_pickup_collected)
			say("Il Ka", "Raccogli la luce d'oro: è Ka, la tua forza vitale. Resta tuo anche se muori: nella Sala lo spendi nel Libro dei Morti per poteri permanenti.")
		5:
			g._add_door("n", {"kind": "tutorial_end"})
			say("Le porte", "Sopra ogni porta c'è la sua ricompensa. Le frecce sul bordo indicano le porte fuori schermo. Entra: comincia la discesa.")
		_:
			pass


func tick() -> void:
	if g.player == null or not is_instance_valid(g.player):
		return
	g.player.hp = g.player.max_hp            # nell'addestramento non si muore
	match step:
		0:
			walked += g.player.velocity.length() * g.get_process_delta_time()
			if walked > 160.0:
				next()
		1, 3:
			var all_down := true
			for d in targets:
				if is_instance_valid(d) and not d.dead:
					all_down = false
			if all_down:
				wait += g.get_process_delta_time()
				if wait > 0.5:
					targets.clear()
					next()
		2:
			var dashing: bool = g.player.dash_t > 0.0
			if dashing and not prev_dash:
				dashes += 1
			prev_dash = dashing
			# chi proprio non ci riesce passa lo stesso dopo un po' di tentativi
			if dodges >= 2 or dashes >= 10:
				next()


func finish() -> void:
	if step < 0 and Meta.tutorial_done:
		return
	Meta.tutorial_done = true
	Meta.save()
	step = -1
	if panel != null:
		panel.queue_free()
		panel = null
	targets.clear()
	Run.room = 0
	g.start_room.call_deferred({"kind": "none"})
	g._show_anubi_menu.call_deferred()
