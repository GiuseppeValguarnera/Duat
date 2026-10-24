extends Node
## Progressi che restano tra una run e l'altra, salvati su disco.
## Per ora: cosa hai sbloccato sconfiggendo i boss.
## Il file è in user://duat_save.cfg (su Windows: %APPDATA%\Godot\app_userdata\Duat).

const PATH := "user://duat_save.cfg"

var sekhem_unlocked := false          ## si sblocca la prima volta che sconfiggi Ammit
var ammit_wins := 0
var ka_bank := 0                      ## Ka custodito tra una run e l'altra (servirà nella Sala del Giudizio)
var runs := 0
var audio := {}                       ## volumi delle categorie di suoni (0..1), vedi sfx.gd


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sekhem_unlocked = cfg.get_value("sblocchi", "sekhem", false)
		ammit_wins = cfg.get_value("boss", "ammit", 0)
		ka_bank = cfg.get_value("progressi", "ka", 0)
		runs = cfg.get_value("progressi", "run", 0)
		audio = cfg.get_value("impostazioni", "audio", {})


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sblocchi", "sekhem", sekhem_unlocked)
	cfg.set_value("boss", "ammit", ammit_wins)
	cfg.set_value("progressi", "ka", ka_bank)
	cfg.set_value("progressi", "run", runs)
	cfg.set_value("impostazioni", "audio", audio)
	cfg.save(PATH)
