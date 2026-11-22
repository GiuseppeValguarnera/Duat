extends RefCounted
## L'addestramento (solo la prima volta). Prima stava in game.gd: è stato spostato qui nel
## riordino del codice, uguale. `g` è la partita (scripts/game.gd).
## Una stanza vera, con fantocci al posto dei nemici: un passo alla volta, con il testo
## in una pergamena piccola e semitrasparente sul lato sinistro, sotto la barra della vita: non
## ferma il gioco e non copre l'azione. Qui non si può morire.
## Passi (blocco 27): muoversi, combo, attacco caricato, scatto (e colpo in corsa), Occhio di Horus, Arte
## dell'arma, Ka, lapislazzuli, Lacrime di Iside, porte. Si può rifare dalla porta della Sala
## (Run.tutorial_replay): allora c'è anche la porta per tornare indietro e, alla fine, quella per scendere.

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
var used := false                      ## attacco caricato o Arte usati nel passo
var prev_cd := 0.0

const STEPS := 10
const INFO_TIME := 14.0                ## i passi solo da leggere vanno avanti da soli dopo qualche secondo


func _init(game: Game) -> void:
	g = game


func ctl(what: String) -> String:
	var dev := Fx.device
	match what:
		"move":
			return {"pad": Lang.t("la levetta sinistra"), "touch": Lang.t("la levetta a sinistra")}.get(dev, Lang.t("W A S D (o le frecce)"))
		"attack":
			return {"pad": Lang.t("X o RB"), "touch": Lang.t("il pulsante d'attacco")}.get(dev, Lang.t("il clic sinistro (o J)"))
		"dash":
			return {"pad": Lang.t("A o LB"), "touch": Lang.t("il pulsante SCATTO")}.get(dev, Lang.t("Spazio"))
		"eye":
			return {"pad": Lang.t("Y o RT"), "touch": Lang.t("il pulsante OCCHIO")}.get(dev, Lang.t("il clic destro (o L)"))
		"charge":
			return {"pad": Lang.t("tieni premuto X"), "touch": Lang.t("tieni premuto il pulsante d'attacco")}.get(dev, Lang.t("tieni premuto il clic sinistro (o J)"))
		"art":
			return {"pad": Lang.t("B"), "touch": Lang.t("il pulsante ARTE")}.get(dev, Lang.t("C (o la rotella del mouse premuta)"))
		"next":
			return {"pad": Lang.t("X"), "touch": Lang.t("il pulsante d'attacco")}.get(dev, Lang.t("il clic sinistro"))
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
	panel.modulate.a = ALPHA
	g.get_node("UI").add_child(panel)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	panel.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	title_label = UiStyle.label("", 7, UiStyle.INK, true)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	var skip := Button.new()
	skip.text = Lang.t("Salta ›")
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", Fx.fs(7))
	skip.add_theme_color_override("font_color", UiStyle.INK_RED)
	skip.add_theme_color_override("font_hover_color", UiStyle.INK)
	skip.pressed.connect(_skip)
	skip.add_to_group("touch_tap")          # sul telefono il tocco arriva da touch_controls.gd
	top.add_child(skip)
	body_label = UiStyle.label("", 7, UiStyle.INK_SOFT, false, width() - 14.0)
	body_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	col.add_child(body_label)
	panel.custom_minimum_size = Vector2(width(), 0)
	if Run.tutorial_replay:
		g._add_door("s", {"kind": "hub_back"})     # la porta da cui sei entrato: si torna alla Sala quando vuoi
	next()


## «Salta»: la prima volta chiude l'addestramento e comincia la discesa; rifatto dalla Sala porta
## all'ultimo passo, con le due porte (Sala o discesa).
func _skip() -> void:
	if Run.tutorial_replay:
		if step < STEPS - 1:
			clear_targets()
			step = STEPS - 2
			next()
		return
	finish()


const ALPHA := 0.72                    ## semitrasparente: dietro si vede la stanza

## La pergamena è stretta e sta a sinistra, sotto la barra della vita: lontana dal centro della
## stanza (i fantocci) e dai pulsanti del telefono (in basso).
func width() -> float:
	var vw := g.get_viewport().get_visible_rect().size.x
	return clampf(vw * 0.25, 140.0, 165.0) * (Fx.ui if Fx.ui > 1.0 else 1.0)


func place() -> void:
	if panel == null:
		return
	panel.reset_size()
	var hud_bottom := 52.0 * Fx.ui          # la barra della vita e il Ka, in alto a sinistra
	panel.position = Vector2(6.0, hud_bottom)


func say(title: String, body: String) -> void:
	title_label.text = "%d/%d · %s" % [step + 1, STEPS, title]
	body_label.text = body
	body_label.visible_ratio = 0.0
	body_label.create_tween().tween_property(body_label, "visible_ratio", 1.0, clampf(body.length() * 0.008, 0.3, 0.8))
	place.call_deferred()
	Sfx.play("ui", 0.0)
	panel.modulate = Color(1.5, 1.3, 1.0, ALPHA)
	panel.create_tween().tween_property(panel, "modulate", Color(1, 1, 1, ALPHA), 0.4)


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
	used = false
	var mid := Vector2(g.ROOM.size.x / 2.0, g.ROOM.size.y / 2.0 + 20.0)
	var wname: String = Weapons.ALL[Run.weapon]["name"] if Weapons.ALL.has(Run.weapon) else Lang.t("l'arma")
	match step:
		0:
			start = g.player.global_position
			walked = 0.0
			say(Lang.t("Il cammino"), Lang.t("Anubi ti fa provare le armi prima della discesa. Muoviti con %s.") % ctl("move"))
		1:
			dummy(Vector2(mid.x - 50.0, 340.0))
			dummy(Vector2(mid.x + 50.0, 340.0))
			say(Lang.t("La combo"), Lang.t("Rompi i due fantocci con %s (%s). Colpi di fila fanno una combo: il terzo è il più forte.") % [ctl("attack"), wname])
		2:
			for off in [Vector2(-22, 0), Vector2(22, 0), Vector2(0, 18)]:
				dummy(mid + Vector2(0, -20) + off)
			prev_cd = g.player.charge_cd
			say(Lang.t("L'attacco caricato"), Lang.t("Ora %s per un secondo: il cerchio sopra la testa si riempie. Lascia a cerchio pieno: è il colpo più forte dell'arma. Poi il cerchio si ricarica.") % ctl("charge"))
		3:
			clear_targets()
			var m := dummy(Vector2(mid.x, 290.0), false, true)
			m.dodged.connect(func() -> void: dodges += 1)
			dodges = 0
			dashes = 0
			say(Lang.t("Lo scatto"), Lang.t("Rosso = sta per colpire. Quando la mummia carica premi %s: durante lo scatto nulla ti tocca. Hai due scatti, poi una breve pausa (i puntini sotto i piedi). Se attacchi subito dopo lo scatto fai un colpo in corsa, più forte. Schivala 2 volte.") % ctl("dash"))
		4:
			clear_targets()
			for at in [Vector2(110, 320), Vector2(g.ROOM.size.x - 110.0, 320), Vector2(mid.x, 300)]:
				dummy(at, true)
			say(Lang.t("L'Occhio di Horus"), Lang.t("I fantocci azzurri si rompono solo con l'Occhio: %s. Si ricarica da solo (il cerchio in alto).") % ctl("eye"))
		5:
			for off in [Vector2(-26, -10), Vector2(26, -10), Vector2(-12, 16), Vector2(14, 18)]:
				dummy(mid + off)
			g.player.art_cd = 0.0
			prev_cd = 0.0
			say(Lang.t("L'Arte dell'arma"), Lang.t("Avvicinati al gruppo e premi %s: l'Arte, un colpo ad area diverso per ogni arma. Si ricarica in circa 9 secondi: l'icona accanto alla vita ti dice quando è pronta.") % ctl("art"))
		6:
			clear_targets()
			_drop("ka", mid)
			say(Lang.t("Il Ka"), Lang.t("Raccogli la luce d'oro: è Ka, la tua forza vitale. Durante la discesa lo spendi dal Traghettatore; quello che ti resta lo custodisci anche se muori, e nella Sala compra i capitoli del Libro dei Morti."))
		7:
			_drop("lapis", mid)
			say(Lang.t("I lapislazzuli"), Lang.t("La pietra blu: i lapislazzuli. Li danno guardiani, boss, il serdab e alcune porte. Nella Sala servono a tutto il resto: restauri, la Casa della Vita, la Sfinge, armi nuove, amuleti, evoluzioni delle armi."))
		8:
			say(Lang.t("Le Lacrime di Iside"), Lang.t("Le più rare: le dà solo un boss di regione, la prima volta che lo batti con un'arma (e di nuovo con un Peso del Cuore più alto). Servono per gli aspetti delle armi, nel Cortile di Neith, e per i capitoli più alti del Libro. Premi %s per continuare.") % ctl("next"))
		9:
			g._add_door("n", {"kind": "tutorial_end"})
			var body := Lang.t("Davanti a ogni porta una stele mostra la ricompensa: il segno di un dio è un dono, poi Ka, lapislazzuli, cura, il Traghettatore. Avvicinati e premi E (Y sul pad, ENTRA sul telefono).")
			if Run.tutorial_replay:
				body += " " + Lang.t("La porta a nord comincia la discesa, quella da cui sei entrato ti riporta alla Sala.")
			else:
				body += " " + Lang.t("Comincia la discesa.")
			say(Lang.t("Le porte"), body)
		_:
			pass


## Una ricompensa finta dell'addestramento: si raccoglie e fa andare avanti (niente Ka né pietre vere).
func _drop(kind: String, at: Vector2) -> void:
	var p = g.PickupScript.new()
	p.kind = kind
	g.world.add_child(p)
	p.position = at
	p.collected.connect(g._on_pickup_collected)


func tick() -> void:
	if g.player == null or not is_instance_valid(g.player):
		return
	g.player.hp = g.player.max_hp            # nell'addestramento non si muore
	var dt := g.get_process_delta_time()
	match step:
		0:
			walked += g.player.velocity.length() * dt
			if walked > 160.0:
				next()
		1, 4:
			if _all_down():
				wait += dt
				if wait > 0.5:
					targets.clear()
					next()
		2:
			# l'attacco caricato è partito quando la sua ricarica riparte
			if g.player.charge_cd > prev_cd + 0.05:
				used = true
			prev_cd = g.player.charge_cd
			if used or _all_down():
				wait += dt
				if wait > 0.9:
					next()
		3:
			var dashing: bool = g.player.dash_t > 0.0
			if dashing and not prev_dash:
				dashes += 1
			prev_dash = dashing
			# chi proprio non ci riesce passa lo stesso dopo un po' di tentativi
			if dodges >= 2 or dashes >= 10:
				next()
		5:
			if g.player.art_cd > prev_cd + 0.05:
				used = true
			prev_cd = g.player.art_cd
			if used:
				wait += dt
				if wait > 1.1:
					next()
		8:
			wait += dt
			var pressed := Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact")
			if (wait > 0.6 and pressed) or wait > INFO_TIME:
				next()


func _all_down() -> bool:
	for d in targets:
		if is_instance_valid(d) and not d.dead:
			return false
	return true


func finish() -> void:
	if step < 0 and Meta.tutorial_done:
		return
	Meta.tutorial_done = true
	Run.tutorial_replay = false
	Meta.save()
	step = -1
	if panel != null:
		panel.queue_free()
		panel = null
	targets.clear()
	Run.room = 0
	g.start_room.call_deferred({"kind": "none"})
	g._show_anubi_menu.call_deferred()
