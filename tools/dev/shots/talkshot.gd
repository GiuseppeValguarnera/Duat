extends Node
## Il riquadro del dialogo (Anubi nella Sala) con una battuta lunga: deve stare tutto nello
## schermo, anche sul telefono, e dividersi in pagine a fine frase.
var t := 0.0
var step := 0
var page := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
const LONG := "Il capitolo centoventisei del Libro descrive un lago nel Duat. Ai suoi quattro angoli siedono quattro babbuini, i custodi. Al morto giusto il lago dà acqua fresca e pane. Al dannato, fiamme. È lo stesso lago, Scriba: non cambia l'acqua, cambia chi vi si specchia. Am-heh ne è il guardiano. Per questo, nella sua arena, resta nell'acqua."
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "talk_" + n + ".png")
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Hub":
		return
	match step:
		0:
			if t > 1.2:
				while g.talk_box.visible: g._advance_talk()
				g.talk_lines = [LONG, "Una battuta corta."]
				g.player.set_physics_process(false)
				g.talk_box.visible = true
				g._advance_talk()
				step = 1; t = 0
		1:
			if t > 0.5:
				var r: Rect2 = g.talk_box.get_global_rect()
				var vp: Vector2 = g.get_viewport().get_visible_rect().size
				print("LOG pagina %d: riquadro %s, schermo %s, dentro=%s, testo=%d caratteri" % [page, str(r), str(vp), str(Rect2(Vector2.ZERO, vp).encloses(r)), g.talk_text.text.length()])
				shot("p%d" % page)
				page += 1
				if not g.talk_box.visible or page > 5:
					get_tree().quit()
					return
				g._advance_talk()
				t = 0
				if not g.talk_box.visible:
					get_tree().quit()
