extends SceneTree
## Prova della finestra a carte (senza grafica): frase a pagine, carte dentro lo schermo,
## doppio tocco per confermare sul telefono.
var frames := 0
var g = null
var picked := false

func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")

func _cards():
	return g.menu.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("text"))

func _process(_d: float) -> bool:
	frames += 1
	var fx = root.get_node("Fx")
	if frames == 60:
		g = current_scene
		if g.menu != null:
			g._close_choice()
		fx.device = "touch"
		g._show_set_menu()
	if frames == 62:
		print("carte durante la frase: ", _cards().size())
	if frames > 62 and frames < 80:
		g.choice_advance()
	if frames == 90:
		var cs = _cards()
		var vs = g.get_viewport().get_visible_rect().size
		for c in cs:
			print("carta h=%.0f w=%.0f scorre=%s fondo=%.0f schermo=%.0f" % [c.size.y, c.size.x, c.has_meta("scroll"), c.global_position.y + c.size.y, vs.y])
		cs[0].pressed.emit()
		print("dopo un tocco: menu aperto=", g.menu != null, " sel=", g.choice_state.get("sel") == cs[0])
		cs[0].pressed.emit()
		print("dopo due tocchi: menu aperto=", g.menu != null, " patti=", root.get_node("Run").curses.size())
		var long := "Una descrizione molto lunga. ".repeat(20)
		var card = load("res://scripts/ui/choice_card.gd").make({"tag": "Prova", "name": "Carta lunga", "body": long, "color": Color.GOLD, "gain": "di più", "loss": "di meno"}, 160.0, 140.0)
		root.add_child(card)
		print("carta stretta: scorre=", card.has_meta("scroll"))
		return true
	return false
