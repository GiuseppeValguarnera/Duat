class_name SphinxTrial
extends Node
## La prova della Sfinge dentro game.gd (Run.trial): ondate, enigmi, doni, cure, guardiani,
## punteggio e schermata finale. Le regole e i dati sono in scripts/sphinx.gd.

const SAND := Color(0.93, 0.78, 0.45)
const HARD_COL := Color(0.92, 0.42, 0.3)
const SOFT_COL := Color(0.5, 0.78, 0.86)

var game                                 ## game.gd
var wave := 0
var score := 0
var hard_taken := 0                      ## risposte dure superate
var clean := 0                           ## ondate senza colpi subiti
var active := ""                         ## l'effetto dell'ultimo enigma (dura fino alla pausa successiva)
var active_left := 0                     ## ondate che restano con l'effetto attivo
var prize_blocked := false               ## data del dispositivo indietro: premi della settimana sospesi
var rewards: Array = []                  ## premi settimanali presi in questa prova: [soglia, Ka, lapis]
var wave_t := 0.0
var running := false
var ended := false
var order: Array = []
var riddle_i := 0
var weapon := ""
var zones_added := 0


func _ready() -> void:
	weapon = Run.weapon
	order = Sphinx.riddle_order()


func _process(delta: float) -> void:
	if running:
		wave_t += delta


## La riga dell'HUD al posto di «Stanza N/10».
func hud_line() -> String:
	var s := Lang.t("La Sfinge · ondata %d · %d punti") % [maxi(wave, 1), score]
	if active != "" and active_left > 0:
		s += " · " + Sphinx.effect_short(active) + " (%d)" % active_left
	return s


func _on(eff: String) -> bool:
	return active == eff and active_left > 0


## L'arena: la Sfinge sdraiata contro la parete nord e due colonne. Chiamata da game.start_room.
## (Blocco 16: niente più Serket qui, e quindi niente cumuli: il suo guardiano è lo scarabeo di Khepri.)
func build_arena() -> void:
	var cx: float = game.ROOM.size.x / 2.0
	var statue := SphinxStatue.new()
	statue.position = Vector2(cx, game.TOP + 26.0)
	game.world.add_child(statue)
	var r := Rect2(cx - 44.0, game.TOP, 88.0, 40.0)
	game.obstacles.append(r)
	game._solid(r)


func begin() -> void:
	Sphinx.touch_clock()
	prize_blocked = not Sphinx.clock_ok()
	var seen: Array = Meta.sphinx.get("intro", [])
	if seen.has(weapon):
		_begin_waves()
	else:
		seen.append(weapon)
		Meta.sphinx["intro"] = seen
		Meta.save()
		show_controls(_begin_waves)


func _begin_waves() -> void:
	game._banner(Lang.t("La scala dell'enigma"), Lang.t("Arma del giorno: %s · uguale per tutti, oggi") % Sphinx.weapon_name(weapon), SAND, 3.0)
	if prize_blocked:
		Fx.float_text(game.player.global_position + Vector2(0, -30), Lang.t("I premi della settimana non sono disponibili: controlla la data del dispositivo."), Color(0.85, 0.82, 0.75), 9)
	get_tree().create_timer(2.6, false).timeout.connect(_start_wave)


## La schermata di inizio (blocco 16): l'arma del giorno con il suo disegno, i tre comandi
## (attacco, attacco caricato tenendo premuto, attacco dopo lo scatto) e una riga sulla prova. La
## prima volta con ogni arma; poi dal pulsante «Comandi dell'arma» della pausa. Sul telefono il
## riquadro si rimpicciolisce finché non sta tutto nello schermo.
func show_controls(then: Callable) -> void:
	var was_paused := get_tree().paused
	get_tree().paused = true
	var u: float = Fx.ui
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 27
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	game.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.6, 0.46, 0.2)))
	layer.add_child(pap)
	var w := minf(440.0 * u, vs.x - 32.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(3 * u))
	pap.add_child(col)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", int(8 * u))
	col.add_child(top)
	var icon := WeaponIcon.new()
	icon.weapon = weapon
	icon.custom_minimum_size = Vector2(44, 44) * u
	top.add_child(icon)
	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(names)
	names.add_child(UiStyle.label(Lang.t("Arma del giorno"), 8, UiStyle.INK_SOFT))
	names.add_child(UiStyle.label(Sphinx.weapon_name(weapon), 14, UiStyle.INK, true))
	var keys := _keys()
	var moves := _moves()
	for i in range(3):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(6 * u))
		col.add_child(row)
		var k := UiStyle.label(String(keys[i]), 9, UiStyle.INK_RED, true)
		k.custom_minimum_size.x = w * 0.3
		k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(k)
		row.add_child(UiStyle.label(String(moves[i]), 9, UiStyle.INK, false, w * 0.66))
	var about := UiStyle.label(Lang.t("La prova: ondate sempre più dure, con vita normale e solo i doni che trovi qui. Ogni 3 ondate la Sfinge si ferma: un enigma e un dono. Conta quanto in alto arrivi."), 8, UiStyle.INK_SOFT, false, w)
	col.add_child(about)
	var b := Button.new()
	b.text = Lang.t("Comincia") if not was_paused else Lang.t("Indietro")
	UiStyle.papyrus_button(b, SAND)
	b.add_theme_font_size_override("font_size", Fx.fs(10))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(b)
	b.pressed.connect(func() -> void:
		layer.queue_free()
		get_tree().paused = was_paused
		then.call())
	b.grab_focus.call_deferred()
	_fit_panel.call_deferred(pap, vs)


## Centra il riquadro e, se è più alto dello schermo (telefono, testo grande), lo rimpicciolisce.
func _fit_panel(pap: Control, vs: Vector2) -> void:
	if not is_instance_valid(pap):
		return
	var sz := pap.get_combined_minimum_size()
	pap.size = sz
	var k := minf(1.0, minf((vs.y - 12.0) / maxf(1.0, sz.y), (vs.x - 12.0) / maxf(1.0, sz.x)))
	pap.scale = Vector2(k, k)
	pap.position = (vs - sz * k) / 2.0


## Come si fanno le tre mosse, col dispositivo che stai usando.
func _keys() -> Array:
	if Fx.device == "touch":
		if weapon == "arco":
			return [Lang.t("Trascina il tasto dell'arco"), Lang.t("Tieni fermo il dito"), Lang.t("Scatto")]
		return [Lang.t("Tasto d'attacco"), Lang.t("Tieni premuto l'attacco"), Lang.t("Scatto, poi attacco")]
	if Fx.device == "pad":
		return [Lang.t("RB"), Lang.t("Tieni premuto RB"), Lang.t("LB/A, poi RB")]
	return [Lang.t("Clic sinistro"), Lang.t("Tieni premuto il clic"), Lang.t("Spazio, poi clic")]


func _moves() -> Array:
	match weapon:
		"lancia":
			return [Lang.t("Affondi lunghi e stretti; il terzo è un'ampia spazzata."),
				Lang.t("La lanci: trapassa tutti e torna. Finché non torna sei disarmato."),
				Lang.t("Affondo in corsa che trapassa la fila.")]
		"arco":
			return [Lang.t("Frecce rapide dove punti: si fermano sul primo nemico."),
				Lang.t("Tiro carico: una freccia che trapassa tutto (ricarica 4 s)."),
				Lang.t("Alla fine dello scatto, un ventaglio di tre frecce.")]
		"flagello":
			return [Lang.t("Frustate in linea: colpiscono tutti, i danni pieni sono in punta."),
				Lang.t("Il pastorale aggancia e ti lancia addosso un nemico; élite e guardiani tirano te."),
				Lang.t("Una frustata lunga che trascina con te i nemici colpiti.")]
	return [Lang.t("Tre fendenti: il terzo è il più forte."),
		Lang.t("Un colpo a giro, tutto intorno a te."),
		Lang.t("Un fendente più largo e più lungo.")]


# --- ondate -------------------------------------------------------------------------------

func _start_wave() -> void:
	if ended or game.player == null or game.player.dead:
		return
	wave += 1
	Run.trial_hp = Sphinx.hp_mult(wave) * (1.3 if _on("tough") else 1.0)
	Run.trial_speed = Sphinx.speed_mult(wave) * (1.15 if _on("fast") else 1.0) * (0.85 if _on("slow") else 1.0)
	Run.trial_dmg = Sphinx.dmg_mult(wave) * (1.2 if _on("sting") else 1.0)
	game.player.hit_invuln = 0.8 * (0.5 if _on("fragile") else 1.0)
	if _on("shield"):
		game.player.shield = maxf(game.player.shield, 12.0)
		Fx.float_text(game.player.global_position + Vector2(0, -20), Lang.t("Scudo 12"), Boons.god_color("iside"))
	var extra := (3 if _on("horde") else 0) - (2 if _on("short") else 0)
	var list := Sphinx.wave_list(wave, extra, 2 if _on("elite") else 0)
	game.guardian_down = false
	game.boss = null
	game.boss_group = []
	game.boss_full = 0.0
	game.boss_bar.visible = false
	game.cleared = false
	Run.room_hit = false
	_add_zones()
	var guard := Sphinx.is_guard_wave(wave)
	if guard:
		game.waves = []
		game._spawn_wave(list, 1.2)
		var gi := Sphinx.guard_info(wave)
		game._banner(Lang.t("Ondata %d · un guardiano") % wave, gi["name"], HARD_COL, 2.4)
		if not String(gi["kind"]).begins_with("serket"):
			Music.play("elite")
	else:
		var half := floori(list.size() / 2.0) if list.size() > 8 else list.size()
		game.waves = [list.slice(0, half)]
		if half < list.size():
			game.waves.append(list.slice(half))
		game._spawn_wave(game.waves.pop_front(), 1.0)
		var sub := Lang.t("%d nemici") % list.size()
		if active != "" and active_left > 0:
			sub += " · " + Sphinx.effect_short(active)
		game._banner(Lang.t("Ondata %d") % wave, sub, SAND, 1.6)
		Music.play("room")
	wave_t = 0.0
	running = true


## Le zone di Sokar entrano con i nemici forti: sabbie mobili dalla 11ª ondata, crepe di fuoco
## (avviso rosso di 1 secondo) dalla 16ª. Restano fino alla fine della prova.
func _add_zones() -> void:
	var r: Rect2 = game.ROOM
	if wave >= Sphinx.STRONG_FROM and zones_added == 0:
		zones_added = 1
		for f in [Vector2(0.3, 0.75), Vector2(0.7, 0.3)]:
			var q := Hazards.Quicksand.new()
			q.radii = Vector2(40, 22)
			q.position = Vector2(lerpf(game.WALL, r.size.x - game.WALL, f.x), lerpf(game.TOP, r.size.y - game.WALL, f.y))
			game.world.add_child(q)
		game._banner(Lang.t("La sabbia di Sokar"), Lang.t("Le sabbie mobili rallentano te e i nemici"), SAND, 2.0)
	if wave >= 16 and zones_added == 1:
		zones_added = 2
		for f in [Vector2(0.7, 0.75), Vector2(0.3, 0.3)]:
			var c := AkerArena.FireCrack.new()
			c.length = 80.0
			c.dir = Vector2.RIGHT.rotated(0.5 if f.x > 0.5 else -0.5)
			c.position = Vector2(lerpf(game.WALL, r.size.x - game.WALL, f.x), lerpf(game.TOP, r.size.y - game.WALL, f.y))
			game.world.add_child(c)


## game._do_spawn chiama qui prima di mettere il nemico in scena: élite e guardiani della prova.
func adjust(e: Enemy, kind: String, tag: String) -> void:
	if tag == "e":
		e.elite = true
		return
	if kind == "aker_lion":
		e.set("kind", tag)
		var gi := Sphinx.guard_info(wave)
		e.max_hp = float(gi["hp"]) * (1.0 + 0.3 * int(gi["cycle"]))
		e.no_reward = true
		_show_bar.call_deferred(e, gi["name"])
	elif tag == "g":
		var gi := Sphinx.guard_info(wave)
		e.elite = true
		e.max_hp *= float(gi["hp"]) * (1.0 + 0.3 * int(gi["cycle"]))
		_show_bar.call_deferred(e, gi["name"])


func _show_bar(e: Enemy, nm: String) -> void:
	if not is_instance_valid(e) or e.dead:
		return
	game.boss = e
	game.boss_name.text = nm.to_upper()
	game.boss_bar.visible = true


## L'ondata è finita (game._room_cleared): punti, premi, cura, poi dono e/o enigma.
func on_wave_cleared() -> void:
	if not running or ended:
		return
	running = false
	game.boss = null
	game.boss_bar.visible = false
	var gained := Sphinx.PTS_WAVE
	var notes := []
	if not Run.room_hit:
		gained += Sphinx.PTS_CLEAN
		clean += 1
		notes.append(Lang.t("senza colpi +%d") % Sphinx.PTS_CLEAN)
	if wave_t < Sphinx.QUICK_SECS:
		gained += Sphinx.PTS_QUICK
	if active_left > 0 and Sphinx.is_hard(active):
		gained += Sphinx.PTS_HARD             # per ogni ondata superata con l'effetto audace attivo
		hard_taken += 1
		notes.append(Lang.t("risposta audace +%d") % Sphinx.PTS_HARD)
	score += gained
	var sub := Lang.t("+%d punti") % gained
	if not notes.is_empty():
		sub += " · " + " · ".join(notes)
	game._banner(Lang.t("Ondata %d superata") % wave, sub, SAND, 1.8)
	var busy := false                         # premio o cura: la pausa aspetta che si leggano
	var prize := [] if prize_blocked else Sphinx.claim(wave)
	if not prize.is_empty():
		busy = true
		rewards.append([wave, prize[0], prize[1]])
		Sfx.play("boon", 0.0)
		Fx.float_text(game.player.global_position + Vector2(0, -30), Lang.t("Premio della settimana: +%d Ka, +%d lapislazzuli") % [prize[0], prize[1]], Restorations.LAPIS_COLOR, 10)
	if wave % Sphinx.HEAL_EVERY == 0:
		busy = true
		if _on("noheal"):
			Fx.float_text(game.player.global_position + Vector2(0, -20), Lang.t("Niente cura: l'hai promesso alla Sfinge"), HARD_COL)
		else:
			game.player.heal(roundf(Run.max_hp * Sphinx.HEAL))
	active_left = maxi(0, active_left - 1)
	if active_left == 0:
		active = ""
	var pause := wave % Sphinx.BOON_EVERY == 0
	if pause:
		# la cura (e il premio) prima, poi la pausa della Sfinge: in sequenza, mai sovrapposte
		get_tree().create_timer(2.8 if busy else 1.6, false).timeout.connect(_sphinx_pause)
	else:
		_queue_wave()


## La pausa della Sfinge (dopo le ondate 3, 6, 9...): l'enigma, poi il dono.
func _sphinx_pause() -> void:
	if ended or game.player == null or game.player.dead:
		return
	_riddle()


# --- doni -----------------------------------------------------------------------------------

func _offer_boons(then: Callable) -> void:
	var ids := Sphinx.boon_offers(Run.boons, wave)
	if ids.is_empty():
		game.player.heal(roundf(Run.max_hp * Sphinx.HEAL))
		then.call()
		return
	var cards := []
	for id in ids:
		var g: String = Boons.ALL[id]["god"]
		var sh := Boons.short(id, 1)
		var tag := Boons.god_name(g) + " · " + Lang.t("Nuovo")
		if Boons.ALL[id].has("weapon"):
			tag += Lang.t(" · solo %s") % String(Weapons.ALL[Boons.ALL[id]["weapon"]]["short"]).to_lower()
		cards.append({"tag": tag, "name": Boons.ALL[id]["name"], "body": Boons.text(id, 1),
			"gain": sh[0], "loss": sh[1], "color": Boons.god_color(g), "on_pick": _pick_boon.bind(id, then)})
	game._open_choice(Lang.t("Pausa della Sfinge · il dono"), SAND, Lang.t("Un dono, al livello base"), cards)


func _pick_boon(id: String, then: Callable) -> void:
	Run.add_boon(id)
	game._close_choice()
	var g: String = Boons.ALL[id]["god"]
	game._boon_fx(Boons.god_color(g), Lang.t("Dono di %s") % Boons.god_name(g), Boons.ALL[id]["name"])
	get_tree().create_timer(0.9, false).timeout.connect(then)


# --- enigmi ----------------------------------------------------------------------------------

func _riddle() -> void:
	if ended:
		return
	var all := Sphinx.riddles()
	var r: Dictionary = all[order[riddle_i % order.size()]]
	riddle_i += 1
	var cards := []
	for side in ["soft", "hard"]:
		var eff: String = r["s"] if side == "soft" else r["h"]
		var hard: bool = side == "hard"
		var body := Sphinx.effect_text(eff)
		if hard:
			body += "\n" + Lang.t("+%d punti per ogni ondata superata con questo effetto.") % Sphinx.PTS_HARD
		cards.append({"tag": Lang.t("Risposta audace") if hard else Lang.t("Risposta prudente"),
			"name": "«" + String(r[side]) + "»", "body": body,
			"color": HARD_COL if hard else SOFT_COL, "on_pick": _answer.bind(eff)})
	game._open_choice(Lang.t("Pausa della Sfinge · l'enigma"), SAND, Lang.t("Ogni risposta è giusta: scegli che prova vuoi per le prossime 3 ondate"), cards, String(r["q"]))


func _answer(eff: String) -> void:
	game._close_choice()
	Sfx.play("ui", 0.0)
	var hard := Sphinx.is_hard(eff)
	active = ""
	active_left = 0
	if eff == "heal":
		game.player.heal(roundf(Run.max_hp * 0.15))
	elif eff != "gift":
		active = eff                          # dura fino alla prossima pausa: 3 ondate
		active_left = Sphinx.EFFECT_WAVES
	game._banner(Lang.t("La Sfinge annuisce"), Sphinx.effect_text(eff), HARD_COL if hard else SOFT_COL, 2.0)
	# poi il dono della pausa (due, se la risposta era «un dono in più»)
	var after := _offer_boons.bind(_queue_wave) if eff == "gift" else _queue_wave
	get_tree().create_timer(0.9, false).timeout.connect(_offer_boons.bind(after))


func _queue_wave() -> void:
	get_tree().create_timer(2.2, false).timeout.connect(_start_wave)


# --- fine -----------------------------------------------------------------------------------

## Morte (o ritiro dalla pausa): punteggio in classifica e schermata finale. La discesa normale e
## le risorse non cambiano, tranne i premi settimanali già presi.
func finish(retired: bool = false) -> void:
	if ended:
		return
	ended = true
	var reached := maxi(0, wave - 1) if running else wave     # le ondate superate davvero
	running = false
	game.finished = true
	game.can_leave = false
	game.boss_bar.visible = false
	var entry := Sphinx.new_entry(score, reached, weapon, hard_taken, clean)
	var pos := Sphinx.record(entry)
	Music.play("death")
	var tw := create_tween().set_ignore_time_scale(true)
	if not retired:
		Engine.time_scale = 0.3
		tw.tween_property(Engine, "time_scale", 1.0, 1.2)
	tw.tween_callback(_summary.bind(reached, pos, retired))


func _summary(reached: int, pos: int, retired: bool) -> void:
	get_tree().paused = true
	var u: float = Fx.ui
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 26
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	game.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.55, 0.42, 0.18)))
	center.add_child(pap)
	var w := minf(440.0 * u, vs.x - 36.0)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(w, 0)
	col.add_theme_constant_override("separation", int(3 * u))
	pap.add_child(col)
	var title := UiStyle.label(Lang.t("Ti sei ritirato dalla scala") if retired else Lang.t("La Sfinge ha parlato"), 14, UiStyle.INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var big := UiStyle.label(Lang.t("%d punti") % score, 18, UiStyle.INK_RED, true)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(big)
	var lines := [
		Lang.t("Ondate superate: %d   ·   Arma del giorno: %s") % [reached, Sphinx.weapon_name(weapon)],
		Lang.t("Risposte audaci superate: %d   ·   Ondate senza colpi: %d") % [hard_taken, clean],
	]
	if pos == 1:
		lines.append(Lang.t("Il tuo miglior punteggio sulla scala!"))
	elif pos > 0:
		lines.append(Lang.t("%d° posto nella tua classifica") % pos)
	for l in lines:
		var lb := UiStyle.label(l, 9, UiStyle.INK_SOFT, false, w)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lb)
	var pr := Lang.t("Premi della settimana: nessuno in questa prova")
	if not rewards.is_empty():
		var parts := []
		for r in rewards:
			parts.append(Lang.t("ondata %d: +%d Ka, +%d lapislazzuli") % r)
		pr = Lang.t("Premi della settimana: ") + " · ".join(parts)
	if prize_blocked:
		pr = Lang.t("I premi della settimana non sono disponibili: controlla la data del dispositivo.")
	var prl := UiStyle.label(pr, 9, UiStyle.INK_GREEN, false, w)
	prl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(prl)
	var note := UiStyle.label(Lang.t("La discesa e le tue risorse non cambiano: la prova resta a parte."), 8, UiStyle.INK_SOFT, false, w)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(10 * u))
	col.add_child(row)
	var again := Button.new()
	again.text = Lang.t("Riprova")
	UiStyle.papyrus_button(again, SAND)
	again.add_theme_font_size_override("font_size", Fx.fs(10))
	again.pressed.connect(_retry)
	row.add_child(again)
	var back := Button.new()
	back.text = Lang.t("Torna alla Sala")
	UiStyle.papyrus_button(back, SAND)
	back.add_theme_font_size_override("font_size", Fx.fs(10))
	back.pressed.connect(_to_hub)
	row.add_child(back)
	back.grab_focus.call_deferred()


func _retry() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_viewport().set_input_as_handled()
	get_tree().reload_current_scene()


func _to_hub() -> void:
	Run.trial = false
	Run.from_sphinx = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


## La Sfinge di pietra sdraiata contro la parete nord dell'arena: corpo di leone, nemes a righe,
## zampe in avanti. Gli occhi si accendono quando parla (enigma aperto).
class SphinxStatue extends Node2D:
	var t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var stone := Color(0.78, 0.66, 0.46)
		var dark := Color(0.52, 0.42, 0.28)
		var outl := Color(0.18, 0.12, 0.07)
		draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# basamento
		draw_rect(Rect2(-46, 2, 92, 12), dark)
		draw_rect(Rect2(-46, 2, 92, 12), outl, false, 1.0)
		for k in range(5):
			draw_rect(Rect2(-40 + k * 17, 6, 8, 3), Color(0.3, 0.42, 0.62, 0.7))
		# corpo di leone (anca dietro, zampe davanti)
		var body := PackedVector2Array([Vector2(-40, 2), Vector2(-38, -10), Vector2(-26, -16), Vector2(16, -16), Vector2(24, -8), Vector2(36, -2), Vector2(42, 2)])
		draw_colored_polygon(body, stone)
		draw_polyline(body, outl, 1.0)
		draw_rect(Rect2(18, -3, 26, 5), stone)
		draw_rect(Rect2(18, -3, 26, 5), outl, false, 1.0)
		draw_line(Vector2(-44, 0), Vector2(-48, -10), stone, 2.0)          # la coda
		# testa con il nemes
		var h := Vector2(14, -26)
		var nemes := PackedVector2Array([h + Vector2(-13, 12), h + Vector2(-10, -8), h + Vector2(0, -13), h + Vector2(10, -8), h + Vector2(13, 12)])
		draw_colored_polygon(nemes, Color(0.86, 0.72, 0.42))
		for k in range(4):
			draw_line(h + Vector2(-11 + k * 1.0, -4 + k * 4), h + Vector2(11 - k * 1.0, -4 + k * 4), Color(0.22, 0.34, 0.6, 0.8), 1.4)
		draw_polyline(nemes, outl, 1.0)
		draw_rect(Rect2(h.x - 6, h.y - 5, 12, 13), stone)
		draw_rect(Rect2(h.x - 6, h.y - 5, 12, 13), outl, false, 1.0)
		var glow := 0.55 + 0.45 * sin(t * 2.2)
		var eye := Color(0.98, 0.82, 0.4, 0.5 + 0.5 * glow)
		draw_rect(Rect2(h.x - 4, h.y, 3, 1.5), eye)
		draw_rect(Rect2(h.x + 1, h.y, 3, 1.5), eye)
		draw_line(h + Vector2(0, 8), h + Vector2(0, 12), outl, 1.4)        # la barba posticcia
		draw_circle(h + Vector2(0, -9), 1.6, Color(0.94, 0.72, 0.3))       # l'ureo



## Il disegno dell'arma del giorno nella schermata dei comandi (come sui piedistalli del Cortile).
class WeaponIcon extends Control:
	var weapon := "khopesh"

	func _draw() -> void:
		var gold := Color(0.94, 0.72, 0.3)
		var k := size.y / 44.0
		var c := size / 2.0
		draw_circle(c, size.y * 0.48, Color(0.12, 0.09, 0.06, 0.85))
		draw_arc(c, size.y * 0.48, 0.0, TAU, 32, gold, 1.5)
		draw_set_transform(c, 0.0, Vector2(k, k))
		match weapon:
			"arco":
				ArrowArt.draw_bow(self, Vector2(0, 0), 0.0, 1.0, 0.0)
			"flagello":
				FlailArt.draw_crook(self, Vector2(5, 12), Vector2(-0.35, -1).normalized(), 24.0, FlailArt.GOLD)
				FlailArt.draw_flail(self, Vector2(-5, 12), Vector2(0.35, -1).normalized(), 1.5)
			"lancia":
				draw_line(Vector2(0, 16), Vector2(0, -10), Color(0.55, 0.38, 0.2), 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(3, -10), Vector2(-3, -10)]), Color(0.85, 0.85, 0.9))
				draw_line(Vector2(-3, -8), Vector2(3, -8), gold, 1.5)
			_:
				draw_line(Vector2(-2, 14), Vector2(0, 4), gold, 2.5)
				var blade := PackedVector2Array()
				for i in range(9):
					var t := i / 8.0
					blade.append(Vector2(sin(t * PI) * 7.0 - t * 3.0, 4.0 - t * 18.0))
				draw_polyline(blade, Color(0.85, 0.85, 0.9), 2.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
