extends Node
## Piuma di Ma'at (blocco 2): meno nemici e più lenti, sconto fino al 30%, ricompense a metà,
## niente Lacrime "prima volta con quest'arma", offerta di Anubi dopo 3 morti di fila entro la stanza 4.
## Uso: tools/dev/shot.sh feathershot 1280 720 res://scenes/game.tscn
var t := 0.0
var step := 0
var counts := {true: [], false: []}
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _wave_total(g) -> int:
	var n := 0
	for w in g.waves:
		n += w.size()
	return n + g.spawning + g.alive
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	p.hp = p.max_hp
	p.invuln_t = 1.0
	if g.menu != null and is_instance_valid(g.menu):
		g._close_choice()
	if step == 0 and t > 1.0:
		step = 1; t = 0
	elif step == 1:
		# 30 stanze 6 con la Piuma spenta e 30 accesa: quanti nemici in tutto
		for i in range(30):
			for on in [false, true]:
				Meta.feather = on
				Run.region = 1; Run.room = 5
				g.start_room({"kind": "ka"})
				counts[on].append(_wave_total(g))
		var avg_off: float = counts[false].reduce(func(a, b): return a + b, 0) / 30.0
		var avg_on: float = counts[true].reduce(func(a, b): return a + b, 0) / 30.0
		L("nemici per stanza 6: spenta %.1f, accesa %.1f (%.0f%%)" % [avg_off, avg_on, avg_on / avg_off * 100.0])
		Meta.feather = true
		Run.region = 1; Run.room = 3
		g.start_room({"kind": "ka"})
		step = 2; t = 0
	elif step == 2 and t > 1.5:
		var m = g.ENEMIES["mummy"].instantiate()
		var base: float = m.speed
		g.world.add_child(m)
		L("velocità mummia: base %.1f, con la Piuma %.1f" % [base, m.speed])
		Meta.feather_deaths = 0
		var g0 := Run.feather_guard()
		Meta.feather_deaths = 50
		L("sconto danni: %.0f%% senza morti, %.0f%% dopo 50 morti (tetto 30%%)" % [g0 * 100.0, Run.feather_guard() * 100.0])
		var lap: int = Meta.lapis
		Restorations.gain(5, p.global_position)
		L("lapislazzuli: +5 -> +%d" % (Meta.lapis - lap))
		L("cuore del capitolo 26 (7 vita): %.0f;  cuore del serdab (10): %.0f" % [Run.feather_halff(7.0), Run.feather_halff(10.0)])
		var tears: int = Meta.tears
		var got: int = Meta.claim_boss("amheh", 2)
		L("Lacrime prima vittoria con l'arma: %d (Lacrime %d -> %d)" % [got, tears, Meta.tears])
		Meta.feather = false
		Meta.early_streak = 3
		Meta.dialogue_seen.erase("piuma3")
		var first_offer := ""
		for b in Dialogue.story():
			if b["if"] and not Meta.dialogue_seen.has(b["id"]):
				first_offer = b["id"]
				break
		L("dopo 3 morti entro la stanza 4 Anubi dice: %s (offre la piuma=%s)" % [first_offer, str(first_offer == "piuma3")])
		Meta.feather = true
		step = 3; t = 0
	elif step == 3 and t > 0.5:
		get_viewport().get_texture().get_image().save_png(D + "feather_room.png")
		get_tree().quit()
