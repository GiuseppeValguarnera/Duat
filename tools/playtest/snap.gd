extends Node
## Fotografo delle partite dei bot (tools/dev/watch.sh): uno screenshot ogni DUAT_SNAP_EVERY secondi di
## gioco (default 5) e uno a ogni cambio di stanza, in DUAT_SNAP_DIR. Serve a GUARDARE il gioco giocato.
var t := 0.0
var n := 0
var every := 5.0
var dir := ""
var last_room := -1
var room_t := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dir = OS.get_environment("DUAT_SNAP_DIR")
	if OS.get_environment("DUAT_SNAP_EVERY") != "":
		every = float(OS.get_environment("DUAT_SNAP_EVERY"))
func _process(delta: float) -> void:
	if dir == "":
		return
	t += delta
	room_t += delta
	var run = get_node("/root/Run")
	var key: int = run.region * 100 + run.room
	if key != last_room:
		last_room = key
		room_t = 0.0
		t = every - 1.2                     # poco dopo l'ingresso
	if t >= every:
		t = 0.0
		n += 1
		get_viewport().get_texture().get_image().save_png("%s/%03d_r%d_s%02d.png" % [dir, n, run.region, run.room])
