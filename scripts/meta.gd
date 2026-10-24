extends Node
## Progressi che restano tra una run e l'altra, salvati su disco.
## Per ora: cosa hai sbloccato sconfiggendo i boss.
## Il file è in user://duat_save.cfg (su Windows: %APPDATA%\Godot\app_userdata\Duat).

const PATH := "user://duat_save.cfg"

var sekhem_unlocked := false          ## si sblocca la prima volta che sconfiggi Ammit
var ammit_wins := 0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sekhem_unlocked = cfg.get_value("sblocchi", "sekhem", false)
		ammit_wins = cfg.get_value("boss", "ammit", 0)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sblocchi", "sekhem", sekhem_unlocked)
	cfg.set_value("boss", "ammit", ammit_wins)
	cfg.save(PATH)
