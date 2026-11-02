extends SceneTree
## Prova veloce delle grazie degli dèi senza grafica: Voce degli Dèi (cambio delle scelte),
## Collana a due sigilli, Sigillo di Thoth, e l'Oasi (Seconda Barca, Mahaf che porta a Sokar).
var frames := 0
var g = null

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	var meta = root.get_node("Meta")
	var run = root.get_node("Run")
	if frames == 60:
		g = current_scene
		meta.favors = ["voce", "voce2", "barca", "sigillo", "collana"]
		meta.amulets = ["ankh", "udjat"]
		run.amulet = "ankh"
		run.amulet2 = "udjat"
		run.voices_left = 2
		for id in ["ra_burn", "ra_disc", "sekhmet_fury", "horus_pierce", "sobek_skin", "iside_wings", "horus_seek"]:
			run.boons[id] = 2
		g._show_boon_menu("ra", false)
	if frames == 70:
		g._close_choice()
		g._show_boon_menu("sekhmet", false)
	if frames == 90:
		g._close_choice()
		g.start_room({"kind": "oasis"})
	if frames == 150:
		var barque = g.oasis_nodes.back()          # la Seconda Barca è l'ultima aggiunta all'Oasi
		print("barque=", barque != null)
		g._open_swap(barque)
		g._close_choice()
		g._swap_choices("horus_pierce", barque)
		g._close_choice()
		g._do_swap("horus_pierce", g._swap_candidates("horus_pierce")[0], 2, barque)
		print("boons=", run.boons.keys())
		g.oasis_mahaf_talked = true
		g._board_mahaf()
	if frames == 400:
		print("favors ok, room=", run.room, " amulets=", run.amulet, "+", run.amulet2, " wears udjat=", run.wears("udjat"), " val=", root.get_node("Run").amulet_lvl("udjat"))
		return true
	paused = false
	return false
