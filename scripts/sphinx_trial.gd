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
var cur := {}                            ## effetti della Sfinge sull'ondata in corso
var nxt := {}                            ## effetti decisi per la prossima ondata
var noheal_left := 0                     ## ondate ancora senza cure
var fragile_left := 0                    ## ondate ancora con l'invulnerabilità dimezzata
var rewards: Array = []                  ## premi settimanali presi in questa prova: [soglia, Ka, lapis]
var wave_t := 0.0
var running := false
var ended := false
var order: Array = []
var riddle_i := 0
var weapon := ""
var zones_added := 0
var mounds: Array = []


func _ready() -> void:
	weapon = Run.weapon
	order = Sphinx.riddle_order()


func _process(delta: float) -> void:
	if running:
		wave_t += delta


## La riga dell'HUD al posto di «Stanza N/10».
func hud_line() -> String:
	return Lang.t("La Sfinge · ondata %d · %d punti") % [maxi(wave, 1), score]


## L'arena: la Sfinge sdraiata contro la parete nord, i cumuli di sabbia (Serket ne esce) e due
## colonne. Chiamata da game.start_room.
func build_arena() -> void:
	var cx: float = game.ROOM.size.x / 2.0
	var statue := SphinxStatue.new()
	statue.position = Vector2(cx, game.TOP + 26.0)
	game.world.add_child(statue)
	var r := Rect2(cx - 44.0, game.TOP, 88.0, 40.0)
	game.obstacles.append(r)
	game._solid(r)
	mounds = Arenas.temple_mounds(game.ROOM, game.TOP, game.WALL)
	var m := SandMounds.new()
	m.list = mounds
	game.world.add_child(m)


func begin() -> void:
	game._banner(Lang.t("La scala dell'enigma"), Lang.t("Arma del giorno: %s · uguale per tutti, oggi") % Sphinx.weapon_name(weapon), SAND, 3.0)
	get_tree().create_timer(2.6, false).timeout.connect(_start_wave)


# --- ondate -------------------------------------------------------------------------------

func _start_wave() -> void:
	if ended or game.player == null or game.player.dead:
		return
	wave += 1
	cur = nxt
	nxt = {}
	Run.trial_hp = Sphinx.hp_mult(wave) * (1.35 if cur.has("tough") else 1.0)
	Run.trial_speed = Sphinx.speed_mult(wave) * (1.15 if cur.has("fast") else 1.0) * (0.85 if cur.has("slow") else 1.0)
	Run.trial_dmg = Sphinx.dmg_mult(wave) * (1.2 if cur.has("sting") else 1.0)
	game.player.hit_invuln = 0.8 * (0.5 if fragile_left > 0 else 1.0)
	if cur.has("shield"):
		game.player.shield = maxf(game.player.shield, 12.0)
		Fx.float_text(game.player.global_position + Vector2(0, -20), Lang.t("Scudo 12"), Boons.god_color("iside"))
	var extra := (4 if cur.has("horde") else 0) - (3 if cur.has("short") else 0)
	var list := Sphinx.wave_list(wave, extra, 2 if cur.has("elite") else 0)
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
		if not cur.is_empty():
			sub += " · " + Lang.t("la Sfinge ricorda la tua risposta")
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
	elif kind == "serket":
		var gi := Sphinx.guard_info(wave)
		e.set("dais_radii", Vector2.ZERO)    # nell'arena della Sfinge non c'è il piano di pietra
		e.set("mounds", mounds)
		e.max_hp = float(gi["hp"]) * (1.0 + 0.3 * int(gi["cycle"])) / maxf(0.1, Run.trial_hp)
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
	if cur.has("hard"):
		gained += Sphinx.PTS_HARD
		hard_taken += 1
		notes.append(Lang.t("risposta audace +%d") % Sphinx.PTS_HARD)
	score += gained
	var sub := Lang.t("+%d punti") % gained
	if not notes.is_empty():
		sub += " · " + " · ".join(notes)
	game._banner(Lang.t("Ondata %d superata") % wave, sub, SAND, 1.8)
	var prize := Sphinx.claim(wave)
	if not prize.is_empty():
		rewards.append([wave, prize[0], prize[1]])
		Sfx.play("boon", 0.0)
		Fx.float_text(game.player.global_position + Vector2(0, -30), Lang.t("Premio della settimana: +%d Ka, +%d lapislazzuli") % [prize[0], prize[1]], Restorations.LAPIS_COLOR, 10)
	if wave % Sphinx.HEAL_EVERY == 0:
		if noheal_left > 0:
			Fx.float_text(game.player.global_position + Vector2(0, -20), Lang.t("Niente cura: l'hai promesso alla Sfinge"), HARD_COL)
		else:
			game.player.heal(roundf(Run.max_hp * Sphinx.HEAL))
	noheal_left = maxi(0, noheal_left - 1)
	fragile_left = maxi(0, fragile_left - 1)
	get_tree().create_timer(1.6, false).timeout.connect(_after_wave)


func _after_wave() -> void:
	if ended or game.player == null or game.player.dead:
		return
	if wave % Sphinx.BOON_EVERY == 0:
		_offer_boons(_riddle)
	else:
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
	game._open_choice(Lang.t("Gli dèi guardano la scala"), SAND, Lang.t("Un dono, al livello base"), cards)


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
			body += "\n" + Lang.t("+%d punti se superi l'ondata.") % Sphinx.PTS_HARD
		cards.append({"tag": Lang.t("Risposta audace") if hard else Lang.t("Risposta prudente"),
			"name": "«" + String(r[side]) + "»", "body": body,
			"color": HARD_COL if hard else SOFT_COL, "on_pick": _answer.bind(eff)})
	game._open_choice(Lang.t("La Sfinge"), SAND, Lang.t("Ogni risposta è giusta: scegli che prova vuoi"), cards, String(r["q"]))


func _answer(eff: String) -> void:
	game._close_choice()
	Sfx.play("ui", 0.0)
	var hard := Sphinx.is_hard(eff)
	match eff:
		"noheal":
			noheal_left = 3
		"fragile":
			fragile_left = 3
		"heal":
			game.player.heal(roundf(Run.max_hp * 0.15))
		"gift":
			pass
		_:
			nxt[eff] = true
	if hard:
		nxt["hard"] = true                    # il bonus arriva se superi la prossima ondata
	game._banner(Lang.t("La Sfinge annuisce"), Sphinx.effect_text(eff), HARD_COL if hard else SOFT_COL, 2.0)
	if eff == "gift":
		get_tree().create_timer(0.8, false).timeout.connect(_offer_boons.bind(_queue_wave))
	else:
		_queue_wave()


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


## I cumuli di sabbia dell'arena (da lì escono gli scorpioni quando arriva Serket).
class SandMounds extends Node2D:
	var list: Array = []

	func _ready() -> void:
		z_index = 0
		Hazards.ground.call_deferred(self)

	func _draw() -> void:
		for p in list:
			var c: Vector2 = p - global_position
			draw_set_transform(c, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, 17.0, Color(0.62, 0.5, 0.32))
			draw_circle(Vector2(-3, -4), 11.0, Color(0.74, 0.61, 0.4))
			draw_circle(Vector2(-5, -7), 5.0, Color(0.84, 0.72, 0.5))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
