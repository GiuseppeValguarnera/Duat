extends Node
## La storia di Sokar: con un salvataggio arrivato a Sokar e vincitore di Aker, controlla l'ordine
## delle battute di Anubi, Imhotep e Mahaf, i Ricordi nei Papiri e il cartiglio nella Sala.
## Uso: DUAT_REGION2=1 tools/dev/shot.sh storyshot
const Ferry := preload("res://scripts/ferryman.gd")
var t := 0.0
var step := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Hub" or t < 1.2 or step > 0:
		return
	step = 1
	while g.talk_box.visible: g._advance_talk()
	Meta.runs = 6; Meta.ammit_wins = 1; Meta.aker_wins = 1; Meta.sokar_seen = true
	Meta.dialogue_seen = ["intro1", "book1", "papiri1", "lago1", "deaths3", "deaths5", "name1", "pesi1"]
	var order := []
	for i in range(8):
		var lines: Array = Dialogue._next_story()
		if lines.is_empty():
			break
		order.append(Meta.dialogue_seen[-1])
		L("Anubi [%s]: %s" % [Meta.dialogue_seen[-1], str(lines[0])])
	L("ordine Anubi: %s" % str(order))
	var imh := []
	for b in Imhotep._story():
		if b["if"]:
			imh.append(b["id"])
	L("Imhotep disponibili: %s" % str(imh))
	Run.region = 2
	var mah := []
	for e in Ferry._available():
		mah.append(e[0])
	L("Mahaf a Sokar (prime): %s" % str(mah.slice(0, 5)))
	L("Mahaf a caso: %s" % Ferry.line())
	for cat in Lore.codex():
		if cat["title"] == Lang.t("Ricordi dello scriba"):
			for e in cat["entries"]:
				L("Ricordo %s aperto=%s" % [e["title"], str(e["seen"])])
	L("ricordo nuovo per la vittoria su Aker: %s" % Lore.ricordo_for(1, "aker"))
	Run.region = 1
	g.queue_redraw()
	await get_tree().create_timer(0.5).timeout
	var cam: Camera2D = g.player.get_node("Camera")
	g.player.global_position = Vector2(g.ROOM.size.x / 2.0, 90.0)
	cam.zoom = Vector2(2.2, 2.2)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(D + "cartiglio.png")
	get_tree().quit()
