extends Node
## Blocco 23: il Cortile. 0 = accanto all'altare (il segnale delle cose usabili), 1 = la finestra
## dell'altare con l'evoluzione, 2 = la finestra dopo aver fatto evolvere l'arma.
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Meta.lapis = 60
	Meta.serpent_wins = 3
	Meta.weapons_unlocked = ["lancia", "arco"]
	Meta.weapon_rooms = {"khopesh": 12}
	Meta.weapon_evo = {}
	Meta.tears = 2
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "arm_" + n + ".png")
func _process(dt: float) -> void:
	var g = get_tree().current_scene
	if g == null or g.name != "Armory" or g.player == null:
		return
	if Fx.mobile:
		Touch.active = true
		Fx.device = "touch"
	t += dt
	if g.talk_box.visible:
		g.talk_box.visible = false
	match step:
		0:
			if t > 1.0:
				g.player.global_position = g.spots["altare"] + Vector2(0, 26)
				step = 1
		1:
			if t > 2.0:
				shot("0_altare")
				g._open_aspects()
				step = 2
		2:
			if t > 2.8:
				shot("1_finestra")
				Weapons.evo_up("khopesh")
				g._open_aspects()
				step = 3
		3:
			if t > 3.6:
				shot("2_evoluta")
				get_tree().quit()
