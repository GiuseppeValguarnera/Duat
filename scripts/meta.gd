extends Node
## Progressi che restano tra una run e l'altra, salvati su disco.
## Per ora: cosa hai sbloccato sconfiggendo i boss.
## Il file è in user://duat_save.cfg (su Windows: %APPDATA%\Godot\app_userdata\Duat).

const PATH := "user://duat_save.cfg"

var sekhem_unlocked := false          ## si sblocca la prima volta che sconfiggi Ammit
var ammit_wins := 0				  ## vittorie sul boss della Prima Ora (oggi Am-heh; il nome resta per i salvataggi)
var ka_bank := 0                      ## Ka custodito tra una run e l'altra (servirà nella Sala del Giudizio)
var runs := 0
var audio := {}                       ## volumi delle categorie di suoni (0..1), vedi sfx.gd
var chapter_levels := {}             ## livello di ogni capitolo comprato del Libro dei Morti
var tears := 0                        ## Lacrime di Iside: la moneta rara dei boss
var extra_slots := 0                  ## posti in più nel Libro dei Morti
var weapon := "khopesh"               ## arma scelta nel Cortile di Neith
var weapons_unlocked: Array = []      ## armi sbloccate oltre al khopesh
var weapon_aspect := {}               ## arma -> aspetto scelto
var aspect_levels := {}               ## "arma:aspetto" -> livello (il primo aspetto di ogni arma è libero)
var first_kills := {}                 ## "boss|arma|peso" già premiati con le Lacrime di Iside
var intros_seen: Array = []           ## boss già presentati (la seconda volta la presentazione è corta)
var serpent_wins := 0                 ## volte che hai battuto il Serpente della Porta
var neith_seen: Array = []            ## battute di Neith già ascoltate
var chapters_equipped: Array = []     ## capitoli attivi (limitati da Chapters.slots())
var dialogue_seen: Array = []         ## battute di Anubi già ascoltate
var last_end := ""                    ## com'è finita l'ultima discesa: "room", "ammit", "win"
var last_room := 0
var last_killer := ""                 ## chi ti ha ucciso l'ultima volta: "mummy", "scarab", "priest", "ammit", "trappola"
var last_god := ""                    ## il dio da cui hai preso più doni nell'ultima discesa
var last_pacts := 0                   ## quanti patti di Set hai stretto nell'ultima discesa
var weights := {}                     ## Peso del Cuore: livello di ogni peso (vedi weights.gd)
var best_weight := -1                 ## il Peso più alto con cui hai battuto Ammit
var options := {"shake": true, "hitstop": true, "autoaim": true, "lang": "auto"}   ## opzioni di gioco ("lang": auto, it o en)
var tutorial_done := false            ## addestramento della prima stanza già fatto
var feather := false                  ## Piuma di Ma'at (modalità aiuto) attiva
var feather_deaths := 0               ## morti da quando la Piuma è attiva
var lapis := 0                        ## lapislazzuli: la moneta dei restauri della Sala (restorations.gd)
var restorations: Array = []          ## restauri della Sala già fatti
var killers := {}                     ## chi ti ha fermato e quante volte (registro dello scriba)
var god_picks := {}                   ## doni presi da ogni dio, in tutte le discese
var total_kills := 0
var best_room := 0                    ## la stanza più lontana raggiunta
var best_time := -1                   ## la vittoria più rapida su Am-heh, in secondi
var casa := false                     ## la Casa della Vita è aperta (30 lapislazzuli, vedi casa.gd)
var amulets: Array = []               ## amuleti forgiati (amulets.gd)
var amulet_recipes: Array = []        ## amuleti che si possono forgiare (premi delle sfide)
var amulet := ""                      ## l'amuleto al collo
var amulet_rooms := {}                ## amuleto -> stanze portate al collo (i livelli)
var challenges := {}                  ## sfida -> 1 compiuta, 2 premio riscosso (challenges.gd)
var stats := {}                       ## contatori delle sfide


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sekhem_unlocked = cfg.get_value("sblocchi", "sekhem", false)
		ammit_wins = cfg.get_value("boss", "ammit", 0)
		ka_bank = cfg.get_value("progressi", "ka", 0)
		runs = cfg.get_value("progressi", "run", 0)
		audio = cfg.get_value("impostazioni", "audio", {})
		chapter_levels = cfg.get_value("libro", "livelli", {})
		for id in cfg.get_value("libro", "comprati", []):       # salvataggi vecchi: livello 1
			if not chapter_levels.has(id):
				chapter_levels[id] = 1
		tears = cfg.get_value("libro", "lacrime", 0)
		extra_slots = cfg.get_value("libro", "posti", 0)
		weapon = cfg.get_value("armi", "scelta", "khopesh")
		weapons_unlocked = cfg.get_value("armi", "sbloccate", [])
		weapon_aspect = cfg.get_value("armi", "aspetto", {})
		aspect_levels = cfg.get_value("armi", "livelli", {})
		first_kills = cfg.get_value("armi", "prime_vittorie", {})
		serpent_wins = cfg.get_value("boss", "serpente", 0)
		intros_seen = cfg.get_value("boss", "presentati", [])
		neith_seen = cfg.get_value("storia", "neith", [])
		chapters_equipped = cfg.get_value("libro", "attivi", [])
		dialogue_seen = cfg.get_value("storia", "battute", [])
		last_end = cfg.get_value("storia", "ultima_fine", "")
		last_room = cfg.get_value("storia", "ultima_stanza", 0)
		last_killer = cfg.get_value("storia", "ucciso_da", "")
		last_god = cfg.get_value("storia", "dio_preferito", "")
		last_pacts = cfg.get_value("storia", "patti", 0)
		weights = cfg.get_value("bilancia", "pesi", {})
		best_weight = cfg.get_value("bilancia", "record", -1)
		var saved_opts: Dictionary = cfg.get_value("impostazioni", "opzioni", {})
		for k in saved_opts:
			options[k] = saved_opts[k]
		tutorial_done = cfg.get_value("storia", "addestramento", runs > 0)
		feather = cfg.get_value("piuma", "attiva", false)
		feather_deaths = cfg.get_value("piuma", "morti", 0)
		lapis = cfg.get_value("sala", "lapislazzuli", 0)
		restorations = cfg.get_value("sala", "restauri", [])
		killers = cfg.get_value("registro", "uccisori", {})
		god_picks = cfg.get_value("registro", "doni", {})
		total_kills = cfg.get_value("registro", "nemici", 0)
		best_room = cfg.get_value("registro", "stanza", 0)
		best_time = cfg.get_value("registro", "tempo", -1)
		casa = cfg.get_value("casa", "aperta", false)
		amulets = cfg.get_value("casa", "amuleti", [])
		amulet_recipes = cfg.get_value("casa", "ricette", [])
		amulet = cfg.get_value("casa", "al_collo", "")
		amulet_rooms = cfg.get_value("casa", "stanze", {})
		challenges = cfg.get_value("casa", "sfide", {})
		stats = cfg.get_value("casa", "contatori", {})
		# le sfide contano solo da quando la Casa è aperta: i salvataggi di prima ne avevano già
		# compiute alcune a Casa murata, si ripulisce
		if not casa and not challenges.is_empty():
			challenges = {}
			stats = {"rinascite": stats.get("rinascite", 0)}
	Lang.apply(String(options.get("lang", "auto")))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sblocchi", "sekhem", sekhem_unlocked)
	cfg.set_value("boss", "ammit", ammit_wins)
	cfg.set_value("progressi", "ka", ka_bank)
	cfg.set_value("progressi", "run", runs)
	cfg.set_value("impostazioni", "audio", audio)
	cfg.set_value("libro", "livelli", chapter_levels)
	cfg.set_value("libro", "lacrime", tears)
	cfg.set_value("libro", "posti", extra_slots)
	cfg.set_value("armi", "scelta", weapon)
	cfg.set_value("armi", "sbloccate", weapons_unlocked)
	cfg.set_value("armi", "aspetto", weapon_aspect)
	cfg.set_value("armi", "livelli", aspect_levels)
	cfg.set_value("armi", "prime_vittorie", first_kills)
	cfg.set_value("boss", "serpente", serpent_wins)
	cfg.set_value("boss", "presentati", intros_seen)
	cfg.set_value("storia", "neith", neith_seen)
	cfg.set_value("libro", "attivi", chapters_equipped)
	cfg.set_value("storia", "battute", dialogue_seen)
	cfg.set_value("storia", "ultima_fine", last_end)
	cfg.set_value("storia", "ultima_stanza", last_room)
	cfg.set_value("storia", "ucciso_da", last_killer)
	cfg.set_value("storia", "dio_preferito", last_god)
	cfg.set_value("storia", "patti", last_pacts)
	cfg.set_value("bilancia", "pesi", weights)
	cfg.set_value("bilancia", "record", best_weight)
	cfg.set_value("impostazioni", "opzioni", options)
	cfg.set_value("storia", "addestramento", tutorial_done)
	cfg.set_value("piuma", "attiva", feather)
	cfg.set_value("piuma", "morti", feather_deaths)
	cfg.set_value("sala", "lapislazzuli", lapis)
	cfg.set_value("sala", "restauri", restorations)
	cfg.set_value("registro", "uccisori", killers)
	cfg.set_value("registro", "doni", god_picks)
	cfg.set_value("registro", "nemici", total_kills)
	cfg.set_value("registro", "stanza", best_room)
	cfg.set_value("registro", "tempo", best_time)
	cfg.set_value("casa", "aperta", casa)
	cfg.set_value("casa", "amuleti", amulets)
	cfg.set_value("casa", "ricette", amulet_recipes)
	cfg.set_value("casa", "al_collo", amulet)
	cfg.set_value("casa", "stanze", amulet_rooms)
	cfg.set_value("casa", "sfide", challenges)
	cfg.set_value("casa", "contatori", stats)
	cfg.save(PATH)


## Lacrime di Iside per un boss battuto: una sola volta per ogni arma, e di nuovo con il
## Peso del Cuore a 4 e a 8. Restituisce quante Lacrime sono arrivate (0 = già prese con quest'arma).
const TEAR_TIERS := [0, 4, 8]

func claim_boss(boss: String, per_tier: int) -> int:
	var w := Weights.total()
	var gained := 0
	for tier in TEAR_TIERS:
		var key := "%s|%s|%d" % [boss, Run.weapon, tier]
		if w >= tier and not first_kills.has(key):
			first_kills[key] = true
			gained += per_tier
	tears += gained
	save()
	return gained
