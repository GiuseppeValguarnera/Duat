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
var chapters_unlocked: Array = []     ## capitoli del Libro dei Morti comprati
var chapters_equipped: Array = []     ## capitoli attivi (limitati da Chapters.slots())
var dialogue_seen: Array = []         ## battute di Anubi già ascoltate
var last_end := ""                    ## com'è finita l'ultima discesa: "room", "ammit", "win"
var last_room := 0
var last_killer := ""                 ## chi ti ha ucciso l'ultima volta: "mummy", "scarab", "priest", "ammit", "trappola"
var last_god := ""                    ## il dio da cui hai preso più doni nell'ultima discesa
var last_pacts := 0                   ## quanti patti di Set hai stretto nell'ultima discesa


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sekhem_unlocked = cfg.get_value("sblocchi", "sekhem", false)
		ammit_wins = cfg.get_value("boss", "ammit", 0)
		ka_bank = cfg.get_value("progressi", "ka", 0)
		runs = cfg.get_value("progressi", "run", 0)
		audio = cfg.get_value("impostazioni", "audio", {})
		chapters_unlocked = cfg.get_value("libro", "comprati", [])
		chapters_equipped = cfg.get_value("libro", "attivi", [])
		dialogue_seen = cfg.get_value("storia", "battute", [])
		last_end = cfg.get_value("storia", "ultima_fine", "")
		last_room = cfg.get_value("storia", "ultima_stanza", 0)
		last_killer = cfg.get_value("storia", "ucciso_da", "")
		last_god = cfg.get_value("storia", "dio_preferito", "")
		last_pacts = cfg.get_value("storia", "patti", 0)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sblocchi", "sekhem", sekhem_unlocked)
	cfg.set_value("boss", "ammit", ammit_wins)
	cfg.set_value("progressi", "ka", ka_bank)
	cfg.set_value("progressi", "run", runs)
	cfg.set_value("impostazioni", "audio", audio)
	cfg.set_value("libro", "comprati", chapters_unlocked)
	cfg.set_value("libro", "attivi", chapters_equipped)
	cfg.set_value("storia", "battute", dialogue_seen)
	cfg.set_value("storia", "ultima_fine", last_end)
	cfg.set_value("storia", "ultima_stanza", last_room)
	cfg.set_value("storia", "ucciso_da", last_killer)
	cfg.set_value("storia", "dio_preferito", last_god)
	cfg.set_value("storia", "patti", last_pacts)
	cfg.save(PATH)
