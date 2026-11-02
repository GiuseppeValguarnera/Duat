extends Node2D
class_name Game
## La Prima Ora del Duat: 10 stanze, poi Am-heh. In ogni stanza due ondate di nemici,
## poi la ricompensa, poi 2-3 porte tra cui scegliere la prossima ricompensa.
## Stanza 5: il Serpente della Porta (guardiano). A volte una porta porta dal Traghettatore,
## dove si spende il Ka della discesa.

## Le stanze normali sono più piccole di quelle dei boss: sul telefono se ne vede quasi tutta
## e i nemici non arrivano da fuori schermo. Boss e guardiano restano grandi.
const ROOM_BIG := Rect2(0, 0, 800, 480)
const ROOM_SMALL := Rect2(0, 0, 672, 416)
var ROOM := ROOM_BIG                    ## la stanza di adesso (cambia in start_room)
const WALL := 32.0
const TOP := 64.0                     # il muro in alto è alto due file
const PlayerScene := preload("res://scenes/player.tscn")
const ENEMIES := {
	"mummy": preload("res://scenes/mummy.tscn"),
	"scarab": preload("res://scenes/scarab.tscn"),
	"priest": preload("res://scenes/priest.tscn"),
	"ammit": preload("res://scenes/ammit.tscn"),   # resta per il finale (Sala delle Due Verità)
	"amheh": preload("res://scenes/amheh.tscn"),
	"serpent": preload("res://scenes/serpent.tscn"),
	"serket": preload("res://scenes/serket.tscn"),       # guardiana di Sokar
	"aker": preload("res://scenes/aker.tscn"),           # boss di Sokar (si divide in Ieri e Domani)
	"aker_lion": preload("res://scenes/aker_lion.tscn"),
	"scorpion": preload("res://scenes/scorpion.tscn"),   # nemici del deserto di Sokar (seconda tappa)
	"cobra": preload("res://scenes/cobra.tscn"),
	"crocodile": preload("res://scenes/crocodile.tscn"),
	# il deserto di Sokar
	"jackal": preload("res://scenes/jackal.tscn"),
	"vulture": preload("res://scenes/vulture.tscn"),
	"sokar_guard": preload("res://scenes/sokar_guard.tscn"),
	"damned_ba": preload("res://scenes/damned_ba.tscn"),
	"javelin": preload("res://scenes/javelin.tscn"),            # lanciatore di giavellotti
	"sokar_priest": preload("res://scenes/sokar_priest.tscn"),  # sacerdote di Sokar (scudi di sabbia)
	"khepri": preload("res://scenes/khepri.tscn"),              # scarabeo di Khepri (la sfera)
	"mirage": preload("res://scenes/mirage.tscn"),              # il Miraggio (le copie)
}
const FerrymanScript := preload("res://scripts/ferryman.gd")
const FEATHER_KA := 0.4               ## con la Piuma di Ma'at si custodisce solo il 40% del Ka
const KILLER_NAMES := {"mummy": "una mummia", "scarab": "gli scarabei", "priest": "un sacerdote", "scorpion": "uno scorpione di Serket", "crocodile": "un coccodrillo", "jackal": "gli sciacalli", "vulture": "un avvoltoio", "sokar_guard": "un guardiano di Sokar", "damned_ba": "un Ba dannato", "cobra": "un cobra", "serpent": "il Serpente della Porta", "serket": "Serket, la dea scorpione", "aker": "Aker, il leone dell'orizzonte", "aker_lion": "un leone di Aker", "aker_pietra": "le pietre di Aker", "aker_raggio": "il raggio dell'alba", "ammit": "Ammit", "amheh": "Am-heh, il Divoratore di Milioni", "amheh_fuoco": "il fuoco di Am-heh", "amheh_marea": "la marea di fuoco di Am-heh", "grata": "una grata di fuoco", "olio": "l'olio in fiamme", "trappola": "una trappola", "ureo": "le statue del cobra", "fiume": "la sabbia nera", "buca": "una buca nella sabbia", "falco": "il soffio del falco di Sokar", "javelin": "un lanciatore di giavellotti", "sokar_priest": "un sacerdote di Sokar", "khepri": "uno scarabeo di Khepri", "khepri_ball": "la sfera di Khepri", "mirage": "il Miraggio"}
const SHOP_ITEMS := [
	{"kind": "heal", "title": "Acqua del Nilo", "desc": "Recuperi il 30% della vita", "price": 20},
	{"kind": "boon", "title": "Offerta agli dèi", "desc": "Un dio a caso ti offre un dono", "price": 40},
	{"kind": "upgrade", "title": "Inchiostro di Thoth", "desc": "Un tuo dono a caso sale di livello", "price": 30},
]
const PickupScript := preload("res://scripts/pickup.gd")
const RoomBuilder := preload("res://scripts/room_builder.gd")
const Tutorial := preload("res://scripts/tutorial.gd")
const SerdabScript := preload("res://scripts/serdab.gd")
## Pezzi dell'interfaccia che prima erano classi interne di questo file
const SpawnMarker := preload("res://scripts/ui/spawn_marker.gd")
const PanelListener := preload("res://scripts/ui/panel_listener.gd")
const HudBars := preload("res://scripts/ui/hud_bars.gd")
const BoonRing := preload("res://scripts/ui/boon_ring.gd")
const DoorArrows := preload("res://scripts/ui/door_arrows.gd")
const DeathScale := preload("res://scripts/ui/death_scale.gd")
const ChoiceCard := preload("res://scripts/ui/choice_card.gd")
const BossIntro := preload("res://scripts/ui/boss_intro.gd")
## Nome, titolo e consiglio di ogni boss, per la presentazione; e la musica che parte con lei.
const BOSS_INTROS := {
	"amheh": ["AM-HEH", "Il guardiano del Lago di Fuoco", "Per il giusto il lago è acqua, per il dannato è fuoco. Resta nell'acqua", "boss", Color(1, 0.55, 0.2)],
	"ammit": ["AMMIT", "La Divoratrice", "Divora i cuori che non superano il giudizio", "boss", Color(0.9, 0.35, 0.25)],
	"serpent": ["IL SERPENTE DELLA PORTA", "Guardiano della quinta porta", "Ogni porta del Duat ha il suo guardiano. Attento alle statue del cobra", "boss", Color(0.5, 0.95, 0.45)],
	"aker": ["AKER", "Il leone dell'orizzonte", "Non ha un dietro: colpiscilo sui fianchi. Dietro le pietre il raggio non passa", "boss", Color(1.0, 0.7, 0.3)],
	"serket": ["SERKET", "Colei che fa respirare la gola", "Segui il solco nella sabbia: dove finisce, esce la coda. Sulla pietra non può scavare", "boss", Color(0.4, 0.9, 0.82)],
}
const DecorScript := preload("res://scripts/room_decor.gd")
const UshabtiScript := preload("res://scripts/ushabti.gd")
const TRAPS_FROM_ROOM := 3            ## le trappole compaiono da questa stanza in poi
const DoorScript := preload("res://scripts/door.gd")
## Set arriva ogni tanto, come il Caos in Hades: mai nella prima stanza né davanti al Serpente
## o al boss, almeno 3 stanze tra una porta e l'altra, al massimo 2 a partita. Le stanze buone
## sono 5 (2, 5, 6, 7, 8): la probabilità parte dal 20% e cresce dell'8% a ogni stanza buona
## senza Set. Risultato: 7 partite su 10 hanno una porta di Set, 2 ne hanno due, 1 nessuna.
const SET_DOOR_CHANCE := 0.2
const SET_DOOR_CHANCE_STEP := 0.08
const SET_DOOR_GAP := 3
const SET_DOOR_MAX := 2
## Il serdab, la stanza segreta (scripts/serdab.gd): al massimo uno a discesa, in una stanza
## normale ripulita dalla seconda in poi. Con 7 stanze buone: circa 2 discese su 3 ne hanno uno.
const SERDAB_CHANCE := 0.14
const SET_DOOR_COST := 8.0           ## vita da pagare per entrare

## Disposizioni delle colonne, in frazioni dell'area calpestabile.
const LAYOUTS := [
	[Vector2(0.3, 0.35), Vector2(0.7, 0.35), Vector2(0.3, 0.72), Vector2(0.7, 0.72)],
	[Vector2(0.5, 0.5)],
	[Vector2(0.22, 0.4), Vector2(0.5, 0.3), Vector2(0.78, 0.4)],
	[Vector2(0.25, 0.6), Vector2(0.75, 0.6), Vector2(0.5, 0.4)],
	[Vector2(0.2, 0.3), Vector2(0.8, 0.3), Vector2(0.2, 0.75), Vector2(0.8, 0.75), Vector2(0.5, 0.55)],
]
## Boss della Prima Ora (Ammit tornerà come boss finale).
const BOSS_KIND := "amheh"            ## il boss della Prima Ora (Ammit resta per il finale)


## Il boss della regione: Am-heh nelle acque di Wernes, Aker nel deserto di Sokar.
func _boss_kind() -> String:
	return "aker" if Run.region == 2 else BOSS_KIND
## Arena di Am-heh: quattro pozze d'acqua (posizione nel pavimento, raggi dell'ellisse).
const AMHEH_POOLS := [[Vector2(0.25, 0.36), Vector2(54, 30)], [Vector2(0.75, 0.36), Vector2(54, 30)], [Vector2(0.36, 0.8), Vector2(48, 27)], [Vector2(0.64, 0.8), Vector2(48, 27)]]
## Arena di Ammit: 6 colonne, ognuna crolla dopo averla stordita una volta.
const BOSS_LAYOUT := [Vector2(0.22, 0.3), Vector2(0.78, 0.3), Vector2(0.12, 0.62), Vector2(0.88, 0.62), Vector2(0.36, 0.8), Vector2(0.64, 0.8)]

var player
var pillars: Array = []
## Modalità riprese (DUAT_TRAILER=1): niente scritte d'aiuto né mirino, per trailer e screenshot.
var TRAILER := OS.get_environment("DUAT_TRAILER") != ""
var pillar_art: Node2D                  ## disegna le colonne (room_decor.gd, Pillars)
var room_decor: Node2D                  ## l'arredamento della stanza: cuoce anche pavimento e muri
var waves: Array = []
var alive := 0
var spawning := 0
var cleared := false
var current_reward := {}
var doors: Array = []
var finished := false
var boss: Enemy = null
var obstacles: Array = []             # rettangoli occupati da statue, bracieri, sarcofagi
var traps_pos: Array = []             # posizioni delle lastre con spuntoni (e degli altri pericoli)
var grates_here := 0                  # grate di fuoco nella stanza: tolgono altrettanti spuntoni
var set_doors := 0                  # porte di Set apparse in questa partita
var set_door_room := -99            # stanza in cui è apparsa l'ultima
var set_door_misses := 0            # stanze buone passate senza Set
var serdab_found := false          # il serdab di questa discesa è già comparso
var top_wall: StaticBody2D = null   # il muro in alto (il serdab lo sostituisce con due pezzi)
var saved_doors: Array = []           # le porte della stanza, per riaprirle dopo l'altare di Set
var room_gen := 0                     # cambia a ogni stanza: annulla le comparse rimaste in sospeso
var boss_bar: ColorRect
var boss_fill: ColorRect
var boss_name: Label
var menu: CanvasLayer                 # scelta dei doni
var choice_state := {}                  ## la finestra a carte aperta: selezione, pagine della frase (_open_choice)
var panel: CanvasLayer
var pause_menu: CanvasLayer           # menu di pausa (Esc / Start)
var guardian_down := false            # il guardiano della stanza è caduto (i suoi rinforzi non escono più)
var bonus_boon := false               # il prossimo dono sale di un livello in più (premio del guardiano)
var shops_visited := 0
var shop_items: Array = []
const DOOR_REACH := 46.0                ## da quanto vicino si entra in una porta (anche touch_controls.gd)
var oasis_nodes: Array = []             ## fonte, altare e statua dell'Oasi (oasis.gd)
var ferry: Node2D                       ## la barca del Traghettatore, se la stanza è la sua
var oasis_mahaf_talked := false         ## nell'Oasi: dopo avergli parlato, Mahaf ti fa salire in barca
var boarding := false
var doors_after_boon := true
var ammit_tears := 0                  # Lacrime arrivate battendo il boss della regione in questa discesa
var boss_group: Array = []            # i boss vivi della stanza: uno, o Ieri e Domani (Aker diviso)
var boss_full := 0.0                  # la vita piena per la barra (Aker: tutte e due le fasi)
var horizon_sun: Node2D = null
var can_leave := true                 # alla morte: si torna alla Sala solo dopo l'animazione
var hud_room := ""
var hud_eye := ""
var hud_sek := ""

const DummyScript := preload("res://scripts/dummy.gd")

@onready var world: Node2D = $World
var tut := Tutorial.new(self)        ## l'addestramento della prima volta (scripts/tutorial.gd)
var rooms := RoomBuilder.new(self)      ## la costruzione delle stanze (scripts/room_builder.gd)
@onready var hud: Label = $UI/Hud
@onready var help: Label = $UI/Help
@onready var prompt: Label = $UI/Prompt
@onready var message: Label = $UI/Message
@onready var reticle: Node2D = $UI/Reticle
@onready var banner: Label = $UI/Banner


func _ready() -> void:
	Atmos.vignette(self, 1.0)              # i bordi dello schermo sfumano nel buio
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.world = world
	# l'interpolazione fisica (project.godot) solo per chi si muove a ogni passo della fisica:
	# eroe e nemici (vedi i loro _ready). Il resto (scintille, numeri, proiettili) no.
	world.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Fx.set_hitboxes(Fx.show_hitboxes)
	Run.in_hub = false
	Run.new_run()
	Run.blessing_granted.connect(_on_blessing_granted)
	_build_vignette()
	_build_boss_bar()
	Fx.scale_labels($UI)
	prompt.add_theme_font_size_override("font_size", Fx.fs(8))      # la descrizione della porta, più discreta
	var hud_bars := HudBars.new()
	hud_bars.game = self
	$UI.add_child(hud_bars)
	var arrows := DoorArrows.new()
	arrows.game = self
	$UI.add_child(arrows)
	hud.position.y = (44.0 if Fx.mobile else 46.0)
	var listener := PanelListener.new()
	listener.game = self
	add_child(listener)
	# una discesa interrotta (gioco chiuso, pagina chiusa dal telefono) riprende dalla sua stanza
	if not Run.resume.is_empty():
		var d: Dictionary = Run.resume
		Run.resume = {}
		Run.apply_descent(d)
		shops_visited = d.get("shops", 0)
		bonus_boon = d.get("bonus", false)
		Run.room = int(d["room"]) - 1
		start_room(d.get("reward", {"kind": "none"}))
		_banner(Lang.t("Discesa ripresa"), Lang.t("Stanza %d di %d") % [Run.room, Run.ROOMS_PER_RUN] if Run.room <= Run.ROOMS_PER_RUN else Lang.t("Am-heh"), Color(0.94, 0.72, 0.3))
		return
	# la primissima volta: la stanza dell'addestramento, poi la discesa vera
	if not Meta.tutorial_done and OS.get_environment("DUAT_PERSONA") == "" and OS.get_environment("DUAT_NOTUT") == "":
		start_room({"kind": "tutorial"})
		return
	# per le prove: partire direttamente da Sokar
	if OS.get_environment("DUAT_START_REGION") == "2" and Run.max_region() > 1:
		Run.region = 2
	if OS.get_environment("DUAT_START_ROOM") != "":
		Run.room = int(OS.get_environment("DUAT_START_ROOM")) - 1     # per il controllo d'avvio
	# la prima stanza non ha ricompensa: il primo dono è quello di Anubi
	start_room({"kind": "none"})
	_show_anubi_menu()


## Se il telefono riceve una chiamata o cambi finestra, il gioco va in pausa da solo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if pause_menu == null and menu == null and panel == null and not finished:
			_toggle_pause()


# ---------------------------------------------------------------- stanze

func start_room(reward: Dictionary) -> void:
	Diag.record.call_deferred("stanza %s" % reward.get("kind", ""))
	if reward.get("kind", "") == "tutorial_end":
		tut.finish()
		return
	# l'altare di Set è una deviazione: la discesa non avanza
	if reward.get("kind", "") not in ["set", "oasis"]:
		Run.room += 1
	Run.nefti_room_heal = 0.0              # il tetto delle cure di Nefti vale per stanza
	room_gen += 1
	boss = null
	Fx.look = Vector2.ZERO
	boss_group = []
	boss_full = 0.0
	horizon_sun = null
	guardian_down = false
	current_reward = reward
	Run.mask_used = false
	if reward.get("kind", "") != "tutorial":
		Run.save_descent(reward, {"shops": shops_visited, "bonus": bonus_boon})
	cleared = false
	alive = 0
	spawning = 0
	doors.clear()
	message.visible = false
	boss_bar.visible = false
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()

	pillars.clear()
	var boss_room := Run.room > Run.ROOMS_PER_RUN
	var kind: String = reward.get("kind", "none")
	ROOM = ROOM_BIG if boss_room or kind == "guardian" or OS.get_environment("DUAT_BIGROOMS") != "" else ROOM_SMALL
	var calm := kind == "guardian" or kind == "shop" or kind == "tutorial" or kind == "set" or kind == "oasis"
	Run.curse_paused = boss_room or kind == "guardian" or kind == "shop" or kind == "set" or kind == "oasis"
	shop_items.clear()
	oasis_nodes.clear()
	if not boss_room and kind != "guardian":
		Music.play("hub" if kind == "shop" or kind == "oasis" else "room")
	var layout: Array = LAYOUTS.pick_random() if Run.room > 1 else LAYOUTS[0]
	if boss_room:
		layout = BOSS_LAYOUT if _boss_kind() == "ammit" else []
	elif kind == "shop" or kind == "tutorial" or kind == "oasis":
		layout = []
	elif kind == "guardian":
		layout = LAYOUTS[0]
	for f in layout:
		pillars.append(Vector2(lerpf(WALL, ROOM.size.x - WALL, f.x), lerpf(TOP, ROOM.size.y - WALL, f.y)))
	rooms.build_walls()
	var decor := DecorScript.new()
	decor.under = paint_floor
	# le arene dei guardiani e dei boss sono luoghi a parte (scripts/arenas.gd)
	var arena := "lake" if boss_room and _boss_kind() == "amheh" else ("gate" if kind == "guardian" else "")
	if boss_room and _boss_kind() == "aker":
		arena = "horizon"                # Sokar: la porta dell'orizzonte
	if arena == "gate" and Run.region == 2:
		arena = "temple"                 # Sokar: il tempio di Serket
	if kind == "oasis":
		arena = "oasis"                  # la sosta tra le due regioni
	if arena == "lake":
		decor.under = func(ci: CanvasItem) -> void: Arenas.paint_lake(ci, ROOM, TOP, WALL)
	elif arena == "gate":
		decor.under = func(ci: CanvasItem) -> void: Arenas.paint_gate(ci, ROOM, TOP, WALL)
	elif arena == "temple":
		decor.under = func(ci: CanvasItem) -> void: Arenas.paint_temple(ci, ROOM, TOP, WALL)
	elif arena == "horizon":
		decor.under = func(ci: CanvasItem) -> void: Arenas.paint_horizon(ci, ROOM, TOP, WALL)
	elif arena == "oasis":
		decor.under = func(ci: CanvasItem) -> void: Oasis.paint(ci, ROOM, TOP, WALL)
	decor.arena = arena
	Run.deep_center = Arenas.deep_center(ROOM, TOP, WALL) if arena == "gate" else Vector2.ZERO
	Run.deep_radii = Arenas.DEEP_RADII if arena == "gate" else Vector2.ZERO
	if arena != "":
		decor.SHADE = 0.18
	room_decor = decor
	world.add_child(decor)
	var pool_spots: Array = []
	if boss_room and _boss_kind() == "amheh":
		for pd in (Arenas.LAKE_POOLS if arena == "lake" else AMHEH_POOLS):
			var pool := Hazards.WaterPool.new()
			pool.radii = pd[1]
			if arena == "lake":
				pool.rect = Vector2(pd[1].x * 2.0, pd[1].y * 2.0)       # vasche sacre rettangolari
				pool.basin = true
			pool.position = Vector2(lerpf(WALL, ROOM.size.x - WALL, pd[0].x), lerpf(TOP, ROOM.size.y - WALL, pd[0].y))
			world.add_child(pool)
			pool_spots.append(pool.position)
	obstacles = decor.build(Run.room * 7919 + randi() % 1000, ROOM, TOP, WALL, pillars + pool_spots, boss_room)
	if arena != "":
		obstacles.append_array(Arenas.solids(arena, ROOM, TOP, WALL, pool_spots))
		_build_arena(arena, pool_spots)
	if current_reward.get("kind", "") == "set":
		decor.mosaic = ""                  # al centro c'è l'altare di Set: niente mosaico sopra
	pillar_art = DecorScript.Pillars.new()
	pillar_art.list = pillars
	pillar_art.in_water = arena == "gate"
	pillar_art.z_index = 1                 # sopra chi passa dietro, sotto chi sta davanti (_pillar_depth)
	world.add_child(pillar_art)
	_cover_until_baked(decor)
	for r in obstacles:
		_solid(r)
	traps_pos.clear()
	grates_here = 0
	if not boss_room and not calm:
		rooms.place_elements()
	# in Sokar le trappole fanno parte della disposizione del deserto (room_builder.gd, _place_sokar)
	if not boss_room and not calm and Run.region == 1 and Run.trap_depth() >= TRAPS_FROM_ROOM - Weights.rank("sabbie"):
		rooms.place_traps()
	if not boss_room and (not calm or kind == "guardian") and kind != "tutorial":
		_seal_doors()
	queue_redraw()

	player = PlayerScene.instantiate()
	player.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y - WALL - 24.0)
	world.add_child(player)
	Run.room_hit = false
	Run.room_dashed = false
	# Ankh: ogni stanza nuova (non la deviazione di Set) un po' di vita
	if Run.wears("ankh") and Run.room > 1 and kind != "set" and kind != "tutorial":
		player.heal(Amulets.val_of("ankh"))
	if kind == "guardian" and Run.region == 1:
		Challenges.on_guardian_room()          # la sfida "Due mani" conta le armi portate al Serpente
	var cam: Camera2D = player.get_node("Camera")
	cam.limit_left = int(ROOM.position.x)
	cam.limit_top = int(ROOM.position.y)
	cam.limit_right = int(ROOM.end.x)
	cam.limit_bottom = int(ROOM.end.y)
	# sul telefono, nelle stanze normali, la telecamera si avvicina un poco: personaggi più leggibili.
	# Contro i boss resta larga, perché serve vedere l'arena.
	cam.zoom = Vector2.ONE * (1.12 if Fx.mobile and not boss_room else 1.0)
	if TRAILER:
		cam.zoom = Vector2.ONE * (1.35 if boss_room else 1.7)     # riprese: più vicino all'azione
	cam.reset_smoothing()
	player.died.connect(_on_player_died)
	if Run.chap("c6"):
		var helper := UshabtiScript.new()
		helper.every = Chapters.value("c6")
		world.add_child(helper)
		helper.global_position = player.global_position + Vector2(-18, -6)
		helper.reset_physics_interpolation()       # parte da qui, non dall'angolo della stanza

	if boss_room:
		waves = []
		_start_boss()
		return
	if kind == "guardian":
		waves = []
		_start_guardian()
		return
	if kind == "shop":
		waves = []
		_start_shop()
		return
	if kind == "oasis":
		waves = []
		_start_oasis()
		return
	if kind == "set":
		waves = []
		_start_set_altar()
		return
	if kind == "tutorial":
		waves = []
		tut.begin()
		return
	var r := mini(Run.room + (1 if Run.region == 2 else 0), 8)
	var horde := 1.0 + 0.25 * Weights.rank("orde")
	if Run.region == 2:
		horde *= 1.3                              # Sokar: più nemici per ondata, non una terza ondata
	if Meta.feather:
		horde *= 0.75                             # Piuma di Ma'at: un quarto di nemici in meno
	var soft := 1 if r <= 2 else 0                # le prime due stanze sono un po' più leggere
	if Run.region == 2:
		sokar_types = _sokar_room_types()
	waves = [_make_wave(roundi((4 + r * 2 - soft) * horde), r >= 3), _make_wave(roundi((3 + r * 2 - soft) * horde), r >= 3)]
	_spawn_wave(waves.pop_front(), 1.0)


## Sokar: i nemici del deserto. Corpo a corpo: sciacalli (in branco), scorpioni (a coppie), guardiani
## di Sokar, Ba dannati, avvoltoi. A distanza o di supporto: lanciatori di giavellotti, sacerdoti di
## Sokar, scarabei di Khepri, il Miraggio. [costo, unità, a distanza?, massimo per ondata]
const SOKAR_KINDS := {
	"jackal": [4, ["jackal", "jackal", "jackal"], false, 1],
	"scorpion": [3, ["scorpion", "scorpion"], false, 3],
	"sokar_guard": [3, ["sokar_guard"], false, 2],
	"damned_ba": [2, ["damned_ba", "damned_ba"], false, 2],
	"vulture": [2, ["vulture"], false, 2],
	"javelin": [2, ["javelin"], true, 2],
	"sokar_priest": [3, ["sokar_priest"], true, 1],
	"khepri": [3, ["khepri"], true, 1],
	"mirage": [3, ["mirage"], true, 1],
}
var sokar_types: Array = []              ## i tipi di nemici di questa stanza di Sokar


## I tipi di una stanza di Sokar: 2-3 nelle prime due stanze (almeno uno da corpo a corpo), tutti
## dalla terza.
func _sokar_room_types() -> Array:
	var all := SOKAR_KINDS.keys()
	if Run.room >= 3:
		return all
	var melee := all.filter(func(k) -> bool: return not SOKAR_KINDS[k][2])
	var out := [melee.pick_random()]
	var rest := all.filter(func(k) -> bool: return k != out[0])
	rest.shuffle()
	for i in range(randi_range(1, 2)):
		out.append(rest[i])
	return out


## Un'ondata di Sokar: composizione casuale tra i tipi della stanza, con i limiti per ondata (1
## sacerdote, 1 miraggio, 2 giavellotti, un branco di sciacalli...) e almeno metà dei nemici da
## corpo a corpo.
func _make_sokar_wave(budget: int) -> Array:
	var out := []
	var cnt := {}
	var melee_n := 0
	var ranged_n := 0
	var tries := 0
	while budget > 0 and tries < 60:
		tries += 1
		var k: String = sokar_types.pick_random()
		var d: Array = SOKAR_KINDS[k]
		var cost: int = d[0]
		var units: Array = d[1]
		var ranged: bool = d[2]
		if int(cnt.get(k, 0)) >= int(d[3]) or cost > budget + 1:
			continue
		if ranged and ranged_n + units.size() > melee_n:
			continue                       # prima un po' di corpo a corpo
		cnt[k] = int(cnt.get(k, 0)) + 1
		out.append_array(units)
		budget -= cost
		if ranged:
			ranged_n += units.size()
		else:
			melee_n += units.size()
	if out.is_empty():
		out = ["scorpion", "scorpion"]
	return out


func _make_wave(budget: int, allow_priest: bool) -> Array:
	if Run.region == 2 and not sokar_types.is_empty():
		return _make_sokar_wave(budget)
	var out := []
	var late := Run.room > Run.GUARDIAN_ROOM    # dopo il guardiano arrivano i cobra
	# i coccodrilli vivono nelle acque di Wernes: solo nelle stanze con una pozza o un canale
	# (gli scorpioni sono del deserto di Sokar, la seconda tappa)
	var water := get_tree().get_nodes_in_group("water").size()
	var crocs := 0
	var sokar := Run.region == 2
	var cnt := {}                                  # quanti di ogni tipo in questa ondata (Sokar)
	while budget > 0:
		var roll := randf()
		# Sokar: scorpioni di Serket, sciacalli in branco, avvoltoi, guardiani con lo scudo, Ba
		# dannati. Mummie, scarabei e sacerdoti restano, meno spesso: le tombe sono ovunque.
		if sokar:
			var r := Run.room
			var pick := randf()
			if pick < 0.2 and budget >= 3 and cnt.get("jackal", 0) < 1:
				cnt["jackal"] = 1                  # un branco per ondata: due insieme erano troppi
				out.append_array(["jackal", "jackal", "jackal"])
				budget -= 4
				continue
			if pick < 0.36 and budget >= 3:
				out.append_array(["scorpion", "scorpion"])
				budget -= 3
				continue
			if pick < 0.48 and r >= 2 and budget >= 2 and cnt.get("vulture", 0) < 2:
				cnt["vulture"] = cnt.get("vulture", 0) + 1
				out.append("vulture")
				budget -= 2
				continue
			if pick < 0.58 and r >= 3 and budget >= 3 and cnt.get("guard", 0) < 2:
				cnt["guard"] = cnt.get("guard", 0) + 1
				out.append("sokar_guard")
				budget -= 3
				continue
			if pick < 0.68 and r >= 4 and budget >= 2 and cnt.get("ba", 0) < 2:
				cnt["ba"] = cnt.get("ba", 0) + 1
				out.append_array(["damned_ba", "damned_ba"])
				budget -= 2
				continue
		if late and roll < 0.22 and budget >= 3:
			out.append("cobra")
			budget -= 3
			continue
		if water > 0 and Run.room >= 3 and crocs < water and roll < (0.42 if late else 0.3) and budget >= 3:
			out.append("crocodile")
			crocs += 1
			budget -= 3
			continue
		if late:
			roll = randf()
		if allow_priest and roll < 0.25 and budget >= 3:
			out.append("priest")
			budget -= 3
		elif roll < 0.6 and budget >= 2:
			out.append("mummy")
			budget -= 2
		else:
			out.append_array(["scarab", "scarab", "scarab"])
			budget -= 2
	return out


func _spawn_wave(list: Array, delay: float) -> void:
	for i in range(list.size()):
		spawning += 1
		_spawn_after(list[i], _free_spot(), delay + i * 0.12)


func _spawn_after(kind: String, pos: Vector2, delay: float) -> void:
	var marker := SpawnMarker.new()
	marker.duration = delay
	world.add_child(marker)
	marker.position = pos
	get_tree().create_timer(delay, false).timeout.connect(_do_spawn.bind(kind, pos, marker, room_gen))


## Fa comparire il nemico annunciato da _spawn_after. Se nel frattempo la stanza
## è cambiata (o la run è finita), non fa nulla.
func _do_spawn(kind: String, pos: Vector2, marker, gen: int) -> void:
	if is_instance_valid(marker):
		marker.queue_free()
	if gen != room_gen or finished:
		return
	spawning -= 1
	if guardian_down:
		# caduto il guardiano, i suoi rinforzi annunciati non escono più (gli scorpioni di Serket
		# comparivano dopo la sua morte e tenevano chiusa la stanza: niente premio)
		if alive <= 0 and spawning <= 0:
			_room_cleared.call_deferred()
		return
	var e: Enemy = ENEMIES[kind].instantiate()
	e.position = pos
	if kind == "serket":
		# il suo tempio: il piano di pietra dove non scava e i cumuli da cui escono gli scorpioni
		e.dais_center = Arenas.deep_center(ROOM, TOP, WALL)
		e.dais_radii = Arenas.DAIS_RADII
		e.mounds = Arenas.temple_mounds(ROOM, TOP, WALL)
	# dalla terza stanza alcune mummie e alcuni sacerdoti sono élite
	var elite_w := Weights.rank("elite")
	# Sokar: élite già dalla prima stanza e più spesso (anche guardiani, avvoltoi, sciacalli e lanciatori)
	var elite_kinds := ["mummy", "priest"] if Run.region == 1 else ["mummy", "sokar_guard", "vulture", "jackal", "javelin"]
	var elite_from := 3 if Run.region == 1 else 1
	var elite_chance := minf(0.2, 0.06 + 0.02 * Run.room) if Run.region == 1 else minf(0.32, 0.14 + 0.02 * Run.room)
	if Run.room >= elite_from - elite_w and Run.room <= Run.ROOMS_PER_RUN and kind in elite_kinds and randf() < elite_chance * (1 + elite_w):
		e.elite = true
		# niente più cambio di musica per le élite: "Frozen Desert" era calmo quasi come la Sala e
		# in battaglia sembrava la musica dell'hub. Le élite si riconoscono dal bordo d'oro.
	world.add_child(e)
	alive += 1
	e.killed.connect(_on_enemy_killed)
	if e.miniboss:
		boss = e
		e.summon.connect(_on_boss_summon)
	if e.is_boss:
		boss = e
		boss_group = [e]
		boss_full = e.max_hp
		e.summon.connect(_on_boss_summon)
		if e.has_signal("pillar_broken"):
			e.pillar_broken.connect(_on_pillar_broken)
		if e.has_signal("split"):
			e.split.connect(_on_boss_split)
		if "floor_rect" in e:
			e.floor_rect = Rect2(WALL, TOP, ROOM.size.x - WALL * 2.0, ROOM.size.y - WALL - TOP)
		if "arena" in e:
			e.arena = Rect2(WALL, TOP, ROOM.size.x - WALL * 2.0, ROOM.size.y - WALL - TOP)
			if _boss_kind() == "amheh":
				e.arena = Arenas.island(ROOM, TOP, WALL)     # il lago di fuoco tutto intorno
	if (e.is_boss or e.miniboss) and BOSS_INTROS.has(kind):
		_boss_intro(e, kind)


## La presentazione del boss (scripts/ui/boss_intro.gd): lunga la prima volta, corta dopo.
func _boss_intro(e: Enemy, kind: String) -> void:
	var info: Array = BOSS_INTROS[kind]
	var first := not Meta.intros_seen.has(kind)
	if first:
		Meta.intros_seen.append(kind)
		Meta.save()
	Music.play(info[3])
	Sfx.play("roar", 0.0)
	var cam: Camera2D = player.get_node("Camera") if player != null and is_instance_valid(player) else null
	var to_boss: Vector2 = (e.global_position - player.global_position) * 0.8 if cam != null else Vector2.ZERO
	var intro := BossIntro.new()
	intro.setup(cam, to_boss, Lang.t(info[0]), Lang.t(info[1]), Lang.t(info[2]), info[4], first)
	# la barra della vita del boss arriva a presentazione finita (prima si sovrapponeva al nome)
	boss_bar.visible = false
	intro.finished.connect(func() -> void:
		if boss != null and is_instance_valid(boss) and not boss.dead:
			boss_bar.visible = true)
	add_child(intro)


func _on_enemy_killed(e: Enemy) -> void:
	alive -= 1
	if Run.room > Run.ROOMS_PER_RUN:
		# il boss è vinto quando non ne resta nessuno (Aker diviso: Ieri E Domani)
		if e.is_boss and _bosses_alive() == 0:
			_boss_defeated.call_deferred()
		return
	if e == boss and e.miniboss:
		guardian_down = true              # i rinforzi ancora in arrivo non compaiono più
		boss_bar.visible = false
		for c in world.get_children():
			if c is Enemy and not c.dead:
				c.die()                   # caduto il guardiano, i suoi scarabei si dissolvono
	if alive > 0 or spawning > 0:
		return
	if not waves.is_empty():
		_spawn_wave(waves.pop_front(), 0.8)
	else:
		_room_cleared.call_deferred()


func _on_blessing_granted(id: String) -> void:
	var b: Dictionary = Boons.SET_BLESSINGS[id]
	_banner(Lang.t("Set mantiene la promessa"), "%s: %s" % [b["name"], Weapons.adapt(b["desc"])], Boons.god_color("set"))
	if player != null and is_instance_valid(player):
		player.max_hp = Run.max_hp
		player.hp = Run.hp
		Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color("set"), 30, 140.0)


## A volte, a stanza ripulita, il muro in alto nasconde un serdab.
func _maybe_serdab() -> void:
	var kind: String = current_reward.get("kind", "none")
	var always := OS.get_environment("DUAT_SERDAB") == "always"     # per le prove
	if serdab_found or boss != null or kind in ["guardian", "shop", "set", "tutorial", "tutorial_end"]:
		return
	if Run.room < 2 or Run.room >= Run.ROOMS_PER_RUN:
		return
	var chance := SERDAB_CHANCE * (1.0 + Amulets.val_of("udjat") / 100.0)
	if not always and randf() >= chance:
		return
	serdab_found = true
	var s := SerdabScript.new()
	# tra due torce, lontano dalla porta nord e dalle statue di Anubi
	s.setup(self, [WALL + 145.0, ROOM.size.x - WALL - 145.0].pick_random())
	world.add_child(s)
	# sotto il personaggio e i nemici, sopra il pavimento e le pareti dipinte
	for i in range(world.get_child_count()):
		if world.get_child(i).get_script() == DecorScript:
			world.move_child(s, i + 1)
			break
	# si annuncia: un crollo sordo, la crepa che si apre con uno sbuffo di polvere e lo schermo che
	# trema un poco (per chi gioca senza audio). Il segno sul muro da solo era troppo nascosto.
	var crack_at := s.global_position + Vector2(0, 2)
	get_tree().create_timer(0.7, false).timeout.connect(_announce_serdab.bind(crack_at))


func _announce_serdab(at: Vector2) -> void:
	Sfx.play("serpent_erupt", 0.05, 2.0)
	Sfx.play("jar_break", 0.05, 0.0)
	Fx.shake(6.0)
	Fx.burst(at, Color(0.78, 0.66, 0.46), 26, 110.0)


func _room_cleared() -> void:
	if cleared:
		return
	cleared = true
	Run.room_done()                     # sfide "di fila", Scettro Was, livelli dell'amuleto
	Run.room_cleared()                  # le maledizioni di Set contano le stanze ripulite
	_maybe_serdab()
	# a stanza ripulita le trappole si fermano
	for trap in get_tree().get_nodes_in_group("traps"):
		trap.set_physics_process(false)
		trap.t = 0.0
		trap.queue_redraw()
	if Run.has("iside_heavy"):
		player.heal(roundf(Run.max_hp * 0.15))
	if Run.has("anubi_canopic"):
		player.heal(Run.val("anubi_canopic"))
	if current_reward.get("kind", "") == "guardian":
		# premio del guardiano: un dono che sale di due livelli invece di uno
		bonus_boon = true
		# il guardiano di mezzo non dà Lacrime di Iside: quelle cadono solo sui boss delle regioni
		var tear_txt := ""
		var fallen := ""
		var fallen_col := Color(0.6, 1, 0.5)
		if Run.region == 2:
			Meta.serket_wins += 1
			Restorations.gain(randi_range(5, 6), player.global_position)
			tear_txt = Lang.t("Il cuore di Sokar è aperto")
			fallen = Lang.t("Serket è caduta")
			fallen_col = Color(0.4, 0.9, 0.82)
		else:
			var first_serpent := Meta.serpent_wins == 0
			Meta.serpent_wins += 1
			Meta.serpent_streak = 0
			Challenges.on_serpent_beaten(Run.hp / Run.max_hp)
			Restorations.gain(randi_range(4, 5), player.global_position)
			tear_txt = Lang.t("Il Cortile di Neith si è aperto") if first_serpent else Lang.t("La via verso Am-heh è aperta")
			fallen = Lang.t("Il Serpente della Porta è caduto")
		var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
		if not gods.is_empty():
			current_reward = {"kind": "boon", "god": gods.pick_random()}
			_banner(fallen, tear_txt + Lang.t("  ·  il prossimo dono sale di un livello in più"), fallen_col)
		else:
			current_reward = {"kind": "ka"}
	if current_reward.get("kind", "none") == "none":
		_banner(Lang.t("Stanza ripulita"), Lang.t("Scegli una porta: la ricompensa è scritta sopra"), Color(0.94, 0.72, 0.3))
		_open_doors()
		return
	var p = PickupScript.new()
	p.kind = current_reward["kind"]
	p.god = current_reward.get("god", "")
	world.add_child(p)
	p.position = _free_spot_near(Vector2(ROOM.size.x / 2.0, ROOM.size.y / 2.0 + 20.0))
	p.collected.connect(_on_pickup_collected)


func _on_pickup_collected(p: Area2D) -> void:
	Sfx.play("pickup", 0.0)
	var kind: String = p.kind
	var god: String = p.god
	Fx.burst(p.global_position + Vector2(0, -10), p.color(), 24, 120.0)
	p.queue_free()
	match kind:
		"ka":
			if tut.step >= 0:
				Run.ka += 10
				Fx.float_text(player.global_position, Lang.t("+10 Ka"), Color(0.94, 0.72, 0.3))
				tut.next.call_deferred()
				return
			Run.ka += roundi(25 * Run.treasure_mult())
			Fx.float_text(player.global_position, Lang.t("+%d Ka") % roundi(25 * Run.treasure_mult()), Color(0.94, 0.72, 0.3))
			_open_doors.call_deferred()
		"heal":
			player.heal(roundf(Run.max_hp * Run.nile_heal()))
			_open_doors.call_deferred()
		"lapis":
			Restorations.gain(randi_range(4, 5), player.global_position)
			_open_doors.call_deferred()
		"boon":
			_show_boon_menu.call_deferred(god)
		"set":
			_show_set_menu.call_deferred()


func _open_doors() -> void:
	if Run.room >= Run.ROOMS_PER_RUN:
		_add_door("n", {"kind": "boss"})
		return
	if Run.room + 1 == Run.GUARDIAN_ROOM:
		_add_door("n", {"kind": "guardian"})
		return
	var sides: Array = [["w", "n", "e"], ["w", "e"], ["w", "n"], ["n", "e"]].pick_random()
	if Run.chap("c72"):
		sides = ["w", "n", "e"]              # Le porte aperte
	var pool := []
	var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
	for g in Amulets.pick_gods(gods, 2):          # con l'Anello Shen pesano di più i tuoi dèi
		pool.append({"kind": "boon", "god": g})
	# ogni tanto, al posto del tesoro di Ka, una porta di lapislazzuli (per i restauri della Sala)
	pool.append({"kind": "lapis"} if Run.room >= 2 and randf() < 0.15 else {"kind": "ka"})
	pool.append({"kind": "heal"})
	pool.shuffle()
	# il Traghettatore è una delle porte solo nella stanza subito prima del Serpente e di Ammit
	var before_boss: bool = Run.room + 2 == Run.GUARDIAN_ROOM or Run.room + 1 == Run.ROOMS_PER_RUN
	if before_boss:
		sides = ["w", "n", "e"]
		pool.insert(0, {"kind": "shop"})
	# prima del boss c'è sempre una porta che cura, insieme alle altre scelte
	if Run.room + 1 == Run.ROOMS_PER_RUN:
		pool.erase({"kind": "heal"})
		pool.insert(1, {"kind": "heal"})
	saved_doors.clear()
	for i in range(sides.size()):
		_add_door(sides[i], pool[i % pool.size()])
		saved_doors.append([sides[i], pool[i % pool.size()]])
	# a volte Set apre un varco in più, nella parete sud: è una deviazione, non prende il posto
	# di nessuna porta (come le porte del Caos in Hades)
	if _set_door_allowed(before_boss):
		if randf() < SET_DOOR_CHANCE + SET_DOOR_CHANCE_STEP * set_door_misses:
			set_doors += 1
			set_door_room = Run.room
			set_door_misses = 0
			_add_door("s", {"kind": "set"})
		else:
			set_door_misses += 1


func _set_door_allowed(before_boss: bool) -> bool:
	if OS.get_environment("DUAT_SET") == "door":
		return current_reward.get("kind", "") != "set"       # per le prove: porta di Set sempre
	return Run.room >= 2 and not before_boss and set_doors < SET_DOOR_MAX \
		and Run.room - set_door_room >= SET_DOOR_GAP and current_reward.get("kind", "") != "set" \
		and not Boons.set_offers(Run.blessings).is_empty()


## Dopo l'altare di Set si riaprono le stesse porte che avevi lasciato.
func _reopen_doors() -> void:
	if saved_doors.is_empty():
		_open_doors()
		return
	for sd in saved_doors:
		_add_door(sd[0], sd[1])


## Le tre porte di una stanza di combattimento, chiuse dall'inizio: a stanza ripulita si aprono
## quelle con una ricompensa (_add_door), le altre restano sigillate.
func _seal_doors() -> void:
	for side in ["n", "w", "e"]:
		var d = DoorScript.new()
		d.side = side
		d.position = _door_pos(side)
		world.add_child(d)
		d.chosen.connect(_on_door_chosen)
		doors.append(d)


func _door_pos(side: String) -> Vector2:
	match side:
		"n":
			return Vector2(ROOM.size.x / 2.0, TOP + 2.0)
		"w":
			return Vector2(WALL + 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
		"e":
			return Vector2(ROOM.size.x - WALL - 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
	return Vector2(ROOM.size.x / 2.0 + (150.0 if randf() < 0.5 else -150.0), ROOM.size.y - WALL - 2.0)


## Una porta con la sua ricompensa: se c'è già quella sigillata su quel lato, si apre lei; se no ne
## compare una (chiusa) che si apre subito. Si entra con "interagisci" (_process).
func _add_door(side: String, reward: Dictionary) -> void:
	for old in doors:
		if is_instance_valid(old) and old.side == side and not old.open and old.reward.is_empty():
			old.reward = reward
			Atmos.add_light(old, Vector2(0, 14) if side == "n" else Vector2.ZERO, 110.0, old.reward_color(), 1.2, false)
			old.open_door()
			return
	var d = DoorScript.new()
	d.side = side
	d.reward = reward
	match side:
		"n":
			d.position = Vector2(ROOM.size.x / 2.0, TOP + 2.0)
		"w":
			d.position = Vector2(WALL + 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
		"e":
			d.position = Vector2(ROOM.size.x - WALL - 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
		"s":
			d.position = Vector2(ROOM.size.x / 2.0 + (150.0 if randf() < 0.5 else -150.0), ROOM.size.y - WALL - 2.0)
	world.add_child(d)
	# la porta brilla del colore della sua ricompensa: nella penombra si trova a colpo d'occhio
	Atmos.add_light(d, Vector2(0, 14) if side == "n" else Vector2.ZERO, 110.0, d.reward_color(), 1.2, false)
	d.chosen.connect(_on_door_chosen)
	doors.append(d)
	d.open_door()


func _on_door_chosen(d: Area2D) -> void:
	Sfx.play("door")
	var kind: String = d.reward["kind"]
	if kind == "boss":
		_fade_to_room({"kind": "none"})
		return
	if kind == "region":
		_next_region()
		return
	if kind == "desert":
		_fade_to_room({"kind": "none"})
		return
	if kind == "set":
		# il tributo di Set: 10 punti vita, ma non può ucciderti
		Run.hp = maxf(1.0, Run.hp - SET_DOOR_COST)
	_fade_to_room(d.reward)


# ---------------------------------------------------------------- passaggio tra le stanze
# Una dissolvenza breve al nero: la stanza nuova si costruisce e si cuoce (room_decor.gd, _bake)
# mentre lo schermo è nero, così quel lavoro, che sul telefono prende un decimo di secondo, non
# si vede come uno scatto. In tutto dura circa un terzo di secondo.

var veil: ColorRect
var _veil_tw: Tween
var _veil_token := 0


func _ensure_veil() -> void:
	if veil != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 20                     # sopra il gioco e l'interfaccia, sotto i comandi touch
	add_child(layer)
	veil = ColorRect.new()
	veil.color = Color(0.02, 0.015, 0.03)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.modulate.a = 0.0
	layer.add_child(veil)


## Si passa alla tappa successiva: la barca di Ra diventa un serpente e viene trascinata sulla
## sabbia (rebirth.gd, SokarPassage), poi la prima stanza di Sokar.
func _next_region() -> void:
	Run.region += 1
	if Run.region == 2 and not Meta.sokar_seen:
		Meta.sokar_seen = true
		Meta.save()
	Run.room = 0
	shops_visited = 0
	var p := Rebirth.RegionPassage.new()
	p.title = Lang.t("La quarta ora")
	p.sub = Lang.t("La terra di Sokar")
	get_tree().root.add_child(p)
	get_tree().create_timer(1.2, true).timeout.connect(func() -> void: start_room({"kind": "oasis"}))


func _fade_to_room(reward: Dictionary) -> void:
	_ensure_veil()
	if _veil_tw != null:
		_veil_tw.kill()
	_veil_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_veil_tw.tween_property(veil, "modulate:a", 1.0, 0.12)
	_veil_tw.tween_callback(func() -> void: start_room(reward))


## Lo schermo resta nero finché la stanza non è cotta (o al massimo 0,6 secondi), poi si schiarisce.
func _cover_until_baked(decor: Node2D) -> void:
	_ensure_veil()
	if _veil_tw != null:
		_veil_tw.kill()
	veil.modulate.a = 1.0
	_veil_token += 1
	var token := _veil_token
	decor.bake_done.connect(_reveal.bind(token), CONNECT_ONE_SHOT)
	get_tree().create_timer(0.6, true).timeout.connect(_reveal.bind(token))     # anche a gioco fermo (presentazione del boss)


func _reveal(token: int) -> void:
	if token != _veil_token or veil == null:
		return
	_veil_token += 1                     # una volta sola
	_veil_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_veil_tw.tween_interval(0.03)        # un fotogramma in più: la texture è già sullo schermo
	_veil_tw.tween_property(veil, "modulate:a", 0.0, 0.2)


# ---------------------------------------------------------------- scelta dei doni

## Finestra di scelta: in alto il dio che parla (ritratto animato e testo che appare),
## sotto 1-3 carte di papiro. Ogni carta: etichetta, nome, descrizione, prezzo e, in fondo,
## il riassunto breve (▲ vantaggio, ▼ prezzo) per scegliere senza rileggere tutto.
## `cards` = [{"tag", "name", "body", "cost", "gain", "loss", "color", "heavy", "on_pick"}].
## Le finestre di scelta a carte (doni, Anubi, patti di Set, altare dell'Oasi, Seconda Barca).
## 1) La frase del dio, a pagine (UiStyle.next_talk_page) con il triangolo "tocca per continuare":
##    un tocco (o azione) passa alla pagina dopo; le carte compaiono dopo l'ultima.
## 2) Le carte si adattano allo schermo (ChoiceCard.make con l'altezza disponibile); se il testo non
##    ci sta, scorre con le freccette ▲ ▼.
## 3) Sul telefono il primo tocco SELEZIONA la carta (cornice accesa), il secondo, o "Scegli",
##    conferma. Con mouse, tastiera e pad la selezione segue il puntatore o il cursore: un clic o
##    azione conferma; su e giù scorrono il testo della carta selezionata.
func _open_choice(title_text: String, title_color: Color, subtitle: String, cards: Array, speech: String = "", god: String = "", reroll: Callable = Callable()) -> void:
	get_tree().paused = true
	# dietro la finestra non devono restare scritte (titolo della stanza, "Doni: N" dell'HUD)
	if _banner_tw != null and _banner_tw.is_valid():
		_banner_tw.kill()
	banner.visible = false
	hud.visible = false
	menu = CanvasLayer.new()
	menu.layer = 20
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)
	var vs := get_viewport().get_visible_rect().size
	var vw := vs.x
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.93)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8.0
	box.offset_right = -8.0
	box.offset_top = 6.0
	box.offset_bottom = -6.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(5 * Fx.ui))
	menu.add_child(box)
	var mine_w := 0.0
	# i doni che hai già, per vedere le combinazioni (Tab / Select, o questo pulsante)
	if not Run.boons.is_empty() or not Run.blessings.is_empty():
		var mine := Button.new()
		mine.text = Lang.t("I tuoi doni (%d)%s") % [Run.boons.size() + Run.blessings.size(), "" if Fx.device == "touch" else ("  ·  Select" if Fx.device == "pad" else "  ·  Tab")]
		UiStyle.papyrus_button(mine, UiStyle.GOLD)
		mine.add_theme_font_size_override("font_size", Fx.fs(8))
		mine.focus_mode = Control.FOCUS_NONE
		mine.pressed.connect(_toggle_boons_panel)
		menu.add_child(mine)
		mine.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		mine_w = mine.get_combined_minimum_size().x
		mine.position = Vector2(vw - mine_w - 6.0, 6.0)
	# il dio che parla
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", int(10 * Fx.ui))
	box.add_child(head)
	var portrait_w := 0.0
	var portrait: Control = null
	if god != "":
		portrait = GodPortrait.new()
		portrait.god = god
		portrait.custom_minimum_size = Vector2(56, 56) if Fx.mobile else Vector2(84, 84) * Fx.ui
		portrait_w = portrait.custom_minimum_size.x
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(portrait)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", int(2 * Fx.ui))
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(words)
	var words_w := vw - portrait_w - 40.0 - mine_w
	var title := UiStyle.heading(title_text, 15, title_color)
	# il titolo va a capo (al massimo due righe) invece di uscire dallo schermo
	if UiStyle.deco_font().get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, Fx.fs(15)).x > words_w:
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size.x = words_w
		title.max_lines_visible = 2
	words.add_child(title)
	var said: Label = null
	var said_box: Control = null
	if speech != "":
		said_box = VBoxContainer.new()
		words.add_child(said_box)
		said = UiStyle.label("", 8 if Fx.mobile else 10, title_color.lerp(Color(0.97, 0.93, 0.85), 0.65), false, words_w)
		said.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		said.add_theme_constant_override("outline_size", 3)
		said.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
		said_box.add_child(said)
		var mark := UiStyle.ContinueMark.new()
		mark.color = title_color.lerp(Color.WHITE, 0.3)
		mark.custom_minimum_size = Vector2(words_w, 9.0 * Fx.ui)
		said_box.add_child(mark)
	var sub: Label = null
	if subtitle != "":
		sub = UiStyle.label(subtitle, 9, Color(0.9, 0.8, 0.6), false, vw - 40.0)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.visible = speech == ""
		box.add_child(sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(8 * Fx.ui))
	box.add_child(row)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", int(10 * Fx.ui))
	actions.visible = false
	box.add_child(actions)
	var choose := Button.new()
	choose.text = Lang.t("Scegli")
	UiStyle.papyrus_button(choose, title_color)
	choose.add_theme_font_size_override("font_size", Fx.fs(9))
	choose.disabled = true
	choose.visible = Fx.device == "touch"
	actions.add_child(choose)
	var again: Button = null
	# Voce degli Dèi (grazia comprata con i lapislazzuli): chiedi al dio altre tre scelte
	if reroll.is_valid() and Run.voices_left > 0:
		again = Button.new()
		again.text = Lang.t("Voce degli Dèi: altre scelte (%d)") % Run.voices_left
		UiStyle.papyrus_button(again, title_color)
		again.add_theme_font_size_override("font_size", Fx.fs(8))
		again.pressed.connect(func() -> void:
			Run.voices_left -= 1
			Sfx.play("boon", 0.0)
			_close_choice()
			reroll.call())
		actions.add_child(again)
	var state := {"sel": null, "lines": [speech] if speech != "" else [], "typing": null, "cards": false}
	choice_state = state
	var keys := ChoiceCard.Keys.new()
	keys.game = self
	menu.add_child(keys)
	var select := func(btn: Button) -> void:
		if state["sel"] == btn:
			return
		if state["sel"] != null and is_instance_valid(state["sel"]):
			ChoiceCard.set_selected(state["sel"], state["sel"].get_meta("accent"), false)
		state["sel"] = btn
		ChoiceCard.set_selected(btn, btn.get_meta("accent"), true)
		choose.disabled = false
	var confirm := func(btn: Button) -> void:
		(btn.get_meta("on_pick") as Callable).call()
	choose.pressed.connect(func() -> void:
		if state["sel"] != null and is_instance_valid(state["sel"]):
			confirm.call(state["sel"]))
	# le carte: costruite quando la frase è finita, con lo spazio che resta
	var build_cards := func() -> void:
		if not is_instance_valid(row):
			return
		state["cards"] = true
		if said_box != null and Fx.mobile:
			said_box.visible = false           # sul telefono lo spazio serve alle carte
		elif said_box != null:
			said_box.get_child(1).visible = false
		if sub != null:
			sub.visible = true
		actions.visible = choose.visible or again != null
		await get_tree().process_frame
		if not is_instance_valid(row):
			return
		var used := box.get_combined_minimum_size().y
		var avail_h := vs.y - used - 12.0 - 2.0 * float(box.get_theme_constant("separation"))
		var n := maxi(1, cards.size())
		var gap := 8.0 * Fx.ui
		var card_w := minf(250.0, (vw - 24.0 - gap * (n - 1)) / n)
		var first_button: Button = null
		var i := 0
		for c in cards:
			var btn := ChoiceCard.make(c, card_w, maxf(80.0, avail_h))
			btn.set_meta("accent", c["color"])
			btn.set_meta("on_pick", c["on_pick"])
			row.add_child(btn)
			btn.focus_neighbor_top = btn.get_path()
			btn.pressed.connect(func() -> void:
				if Fx.device == "touch" and state["sel"] != btn:
					select.call(btn)
					Sfx.play("ui", 0.0)
					return
				confirm.call(btn))
			btn.focus_entered.connect(func() -> void:
				Sfx.play("ui", 0.0)
				if Fx.device != "touch":
					select.call(btn))
			btn.mouse_entered.connect(func() -> void:
				if Fx.device == "mouse":
					btn.grab_focus())
			# le carte si srotolano una dopo l'altra
			btn.modulate.a = 0.0
			var tw2 := btn.create_tween()
			tw2.tween_interval(0.06 * i)
			tw2.tween_property(btn, "modulate:a", 1.0, 0.16)
			i += 1
			if first_button == null:
				first_button = btn
		if first_button != null:
			if Fx.device != "touch":
				first_button.grab_focus()
			else:
				first_button.grab_focus.call_deferred()
	state["build"] = build_cards
	# la frase, una pagina alla volta
	var next_page := func() -> void:
		var lines: Array = state["lines"]
		if lines.is_empty():
			if not state["cards"]:
				build_cards.call()
			return
		said.text = "«%s»" % UiStyle.next_talk_page(lines)
		said.visible_ratio = 0.0
		var tw := said.create_tween()
		tw.tween_property(said, "visible_ratio", 1.0, clampf(said.text.length() * 0.012, 0.3, 1.4))
		state["typing"] = tw
	state["next"] = next_page
	if portrait != null:
		var stop := get_tree().create_timer(maxf(1.2, speech.length() * 0.025), true, false, true)
		var ref: WeakRef = weakref(portrait)
		stop.timeout.connect(func() -> void:
			var pp = ref.get_ref()
			if pp != null:
				pp.talking = false)
	if speech != "":
		next_page.call()
	else:
		build_cards.call()


## Un tocco o "azione" mentre il dio parla: finisce di scrivere la pagina, poi passa alla
## successiva; dopo l'ultima compaiono le carte. (La chiamano _input e il bot di playtest.)
func choice_advance() -> void:
	if menu == null or choice_state.is_empty() or choice_state.get("cards", true):
		return
	var tw = choice_state.get("typing")
	if tw != null and tw.is_valid() and tw.is_running():
		tw.custom_step(10.0)
		return
	(choice_state["next"] as Callable).call()


func _choice_input(event: InputEvent) -> void:
	if menu == null or choice_state.is_empty() or panel != null or pause_menu != null:
		return
	if not choice_state.get("cards", true):
		var tap: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		if tap or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack") or event.is_action_pressed("interact"):
			choice_advance()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down") and _choice_scroll(1):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") and _choice_scroll(-1):
		get_viewport().set_input_as_handled()


## Su e giù scorrono il testo della carta selezionata (se scorre); altrimenti il cursore va ai
## pulsanti sotto le carte.
func _choice_scroll(dir: int) -> bool:
	var btn = choice_state.get("sel")
	if btn == null or not is_instance_valid(btn) or not btn.has_meta("scroll"):
		return false
	var sc: ScrollContainer = btn.get_meta("scroll")
	var bar := sc.get_v_scroll_bar()
	var before := sc.scroll_vertical
	sc.scroll_vertical += int(dir * 24.0 * Fx.ui)
	return sc.scroll_vertical != before or (dir < 0 and bar.value > 0.5)


func _close_choice() -> void:
	if menu != null:
		menu.queue_free()
		menu = null
	choice_state = {}
	hud.visible = true
	get_tree().paused = false


func _show_boon_menu(god: String, then_doors: bool = true) -> void:
	doors_after_boon = then_doors
	var options := Boons.offers(god, Run.boons)
	var from_god := god
	if options.is_empty():
		var others := Boons.gods_with_boons(Run.boons, Run.room)
		if not others.is_empty():
			from_god = others.pick_random()
			options = Boons.offers(from_god, Run.boons)
	if from_god == "nefti" and not Meta.nefti_met:
		Meta.nefti_met = true             # da ora Nefti compare anche nelle acque di Wernes
		Meta.save()
	if from_god == "shu" and not Meta.shu_met:
		Meta.shu_met = true               # da ora Shu compare ovunque
		Meta.save()
	if options.is_empty():
		# tutti i doni sono già al massimo: al posto del dono arriva un tesoro di Ka
		var bonus := roundi(25 * Run.ka_mult())
		Run.ka += bonus
		bonus_boon = false
		Fx.float_text(player.global_position, Lang.t("+%d Ka") % bonus, Color(0.94, 0.72, 0.3))
		if then_doors:
			_open_doors()
		return

	# Peso del Cuore, il silenzio degli dèi: due scelte invece di tre. Va prima del Dono Doppio,
	# altrimenti il doppio (che prende l'ultimo posto) sparirebbe sempre.
	if Weights.rank("silenzio") > 0 and options.size() > 2:
		options.resize(2)
	var duos := Boons.duos_for(from_god, Run.boons)
	if not duos.is_empty() and randf() < Boons.duo_chance():
		var slots := 2 if Weights.rank("silenzio") > 0 else 3
		if options.size() >= slots:
			options[slots - 1] = duos.pick_random()
		else:
			options.append(duos.pick_random())
	var cards := []
	for id in options:
		var lvl := mini(Run.level(id) + (2 if bonus_boon else 1), _max_level(id))
		var tag := Lang.t("Nuovo") if Run.level(id) == 0 else Lang.t("Livello %d") % lvl
		if Run.level(id) == 0 and lvl > 1:
			tag = Lang.t("Nuovo · subito livello %d") % lvl
		if Boons.is_heavy(id):
			tag = Lang.t("Dono pesante")
		elif Boons.is_rare(id):
			tag = Lang.t("Dono raro")
		if Boons.ALL[id].has("weapon"):
			tag += Lang.t(" · solo %s") % String(Weapons.ALL[Boons.ALL[id]["weapon"]]["short"]).to_lower()
		if Boons.is_duo(id):
			var gs: Array = Boons.ALL[id]["gods"]
			tag = Lang.t("Dono doppio · %s + %s") % [Boons.god_name(gs[0]), Boons.god_name(gs[1])]
		var sh := Boons.short(id, lvl)
		cards.append({
			"tag": tag, "name": Boons.ALL[id]["name"], "body": Boons.text(id, lvl),
			"cost": Weapons.adapt(Boons.ALL[id]["cost"]) if Boons.has_cost(id) else "",
			"gain": sh[0], "loss": sh[1],
			"color": Boons.god_color("duo") if Boons.is_duo(id) else Boons.god_color(from_god),
			"heavy": Boons.is_heavy(id),
			"on_pick": _choose_boon.bind(id),
		})
	_open_choice(Lang.t("%s ti offre un dono") % Boons.god_name(from_god), Boons.god_color(from_god), "", cards, Lore.speech(from_god), from_god, _show_boon_menu.bind(from_god, then_doors))


## All'inizio di ogni run Anubi offre uno dei suoi doni.
func _show_anubi_menu() -> void:
	var cards := []
	for id in Boons.offers("anubi", Run.boons):
		var sh := Boons.short(id, 1)
		cards.append({
			"tag": Lang.t("Dono di Anubi"), "name": Boons.ALL[id]["name"], "body": Boons.text(id, 1),
			"cost": Weapons.adapt(Boons.ALL[id]["cost"]), "gain": sh[0], "loss": sh[1],
			"color": Boons.god_color("anubi"), "heavy": false,
			"on_pick": _choose_start_boon.bind(id),
		})
	_open_choice(Lang.t("Anubi pesa il tuo cuore"), Boons.god_color("anubi"), "", cards, Lore.speech("anubi"), "anubi")


func _choose_start_boon(id: String) -> void:
	Run.add_boon(id)
	Run.save_descent(current_reward, {"shops": shops_visited, "bonus": bonus_boon})
	_close_choice()
	player.max_hp = Run.max_hp
	player.hp = Run.hp
	_boon_fx(Boons.god_color("anubi"), Lang.t("Dono di Anubi"), Boons.ALL[id]["name"])


func _max_level(id: String) -> int:
	return Boons.MAX_LEVEL if Boons.ALL[id].has("values") else 1


func _choose_boon(id: String) -> void:
	Run.add_boon(id)
	if bonus_boon and Run.level(id) < _max_level(id):
		Run.add_boon(id)
	bonus_boon = false
	_close_choice()
	var g: String = Boons.ALL[id]["god"]
	var lvl := Run.level(id)
	_boon_fx(Boons.god_color(g), Lang.t("Dono di %s") % Boons.god_name(g) if g != "duo" else Lang.t("Dono doppio"), Boons.ALL[id]["name"] + ("" if lvl <= 1 else Lang.t("  ·  livello %d") % lvl))
	if doors_after_boon:
		_open_doors()


## L'effetto quando prendi un dono: lampo del colore del dio, anello di luce attorno a te,
## un attimo di rallentamento e il nome del dono al centro.
func _boon_fx(color: Color, title: String, sub: String) -> void:
	Sfx.play("boon", 0.0)
	Sfx.play("divine", 0.05)
	var flash := ColorRect.new()
	flash.color = Color(color, 0.45)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.6)
	tw.tween_callback(flash.queue_free)
	if player != null and is_instance_valid(player):
		var ring := BoonRing.new()
		ring.color = color
		world.add_child(ring)
		ring.global_position = player.global_position + Vector2(0, -8)
		Fx.burst(player.global_position + Vector2(0, -10), color, 60, 220.0)
		Fx.burst(player.global_position + Vector2(0, -10), Color(1, 0.95, 0.8), 20, 120.0)
	Fx.shake(5.0)
	Fx.hitstop(0.12)
	_banner(title, sub, color)


func _show_set_menu() -> void:
	var cards := []
	for o in Boons.set_offers(Run.blessings):
		var curse: Dictionary = Boons.SET_CURSES[o["curse"]]
		var bless: Dictionary = Boons.SET_BLESSINGS[o["blessing"]]
		cards.append({
			"tag": Lang.t("Patto di Set"), "name": bless["name"],
			"sections": [
				[Lang.t("Prima · maledizione per %d stanze") % curse["rooms"], curse["desc"], UiStyle.INK_RED],
				[Lang.t("Poi · per tutta la discesa"), Weapons.adapt(bless["desc"]), UiStyle.INK_GREEN],
			],
			"color": Boons.god_color("set"), "heavy": true,
			"on_pick": _choose_pact.bind(o["curse"], o["blessing"]),
		})
	if cards.is_empty():
		Run.ka += roundi(25 * Run.ka_mult())
		if current_reward.get("kind", "") == "set":
			_reopen_doors()
		else:
			_open_doors()
		return
	var sub := Lang.t("Prima la maledizione, per le prossime stanze ripulite. Poi il potere, per tutta la discesa. Davanti ai guardiani Set tace")
	if Run.room + 2 > Run.ROOMS_PER_RUN:
		sub = Lang.t("Attenzione: mancano poche stanze ad Am-heh. Il potere di Set potrebbe non arrivare in tempo")
	_open_choice(Lang.t("Set ti propone un patto"), Boons.god_color("set"), sub, cards, Lore.speech("set"), "set")


func _choose_pact(curse: String, blessing: String) -> void:
	Run.add_pact(curse, blessing)
	_close_choice()
	var cdesc: Dictionary = Boons.SET_CURSES[curse]
	_boon_fx(Boons.god_color("set"), Lang.t("Maledizione di Set: %d stanze") % cdesc["rooms"], Lang.t("%s. Poi: %s") % [cdesc["desc"], Weapons.adapt(Boons.SET_BLESSINGS[blessing]["desc"])])
	if current_reward.get("kind", "") == "set":
		_reopen_doors()
	else:
		_open_doors()


## Quanti caratteri per riga stanno in una carta, in base alla larghezza dello schermo e ai caratteri.
func _wrap_w() -> int:
	var card_w := minf(250.0, (get_viewport().get_visible_rect().size.x - 50.0) / 3.0)
	return clampi(int(card_w / (5.6 * Fx.ui)), 20, 34)


func _wrap(text: String, width: int) -> String:
	var out := ""
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() + 1 > width and line != "":
			out += line + "\n"
			line = word
		else:
			line = word if line == "" else line + " " + word
	return out + line


var _banner_tw: Tween


func _banner(title: String, sub: String, color: Color, hold: float = 2.0) -> void:
	if banner.material == null:
		banner.add_theme_font_override("font", UiStyle.deco_font())
		UiStyle.shimmer(banner, 0.6)
		# le scritte lunghe (un'iscrizione, una benedizione di Set) vanno a capo invece di uscire
		banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner.offset_left = 24.0
		banner.offset_right = -24.0
	banner.text = "%s\n%s" % [title, sub]
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 1.0
	# un banner nuovo ferma la dissolvenza di quello prima (spegneva anche il nuovo)
	if _banner_tw != null and _banner_tw.is_valid():
		_banner_tw.kill()
	_banner_tw = banner.create_tween()
	_banner_tw.tween_interval(hold)
	_banner_tw.tween_property(banner, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- pausa (Esc / Start)

func _toggle_pause() -> void:
	if pause_menu != null:
		Meta.save()
		pause_menu.queue_free()
		pause_menu = null
		# se era aperta una scelta dei doni, il gioco resta fermo su quella
		get_tree().paused = menu != null or panel != null
		return
	if player == null or player.dead:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reticle.visible = false
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 30
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.position = Vector2(-80, -70) * Fx.ui
	box.custom_minimum_size = Vector2(160, 140) * Fx.ui
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = Lang.t("Pausa")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Fx.fs(18))
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Button = null
	for entry in [[Lang.t("Riprendi"), _toggle_pause], [Lang.t("Opzioni"), _open_options], [Lang.t("Ricomincia la run"), _restart_run], [Lang.t("Torna alla Sala (abbandona)"), _abandon_run], [Lang.t("Esci alla Sala (la discesa resta salvata)") if OS.has_feature("web") else Lang.t("Esci (la discesa resta salvata)"), _quit_game]]:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(160, 26) * Fx.ui
		b.add_theme_font_size_override("font_size", Fx.fs(11))
		b.pressed.connect(entry[1])
		box.add_child(b)
		if first == null:
			first = b
	var hint := Label.new()
	hint.text = Lang.t("Esc / Start per riprendere")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", Fx.fs(8))
	hint.add_theme_color_override("font_color", Color(0.66, 0.6, 0.47))
	box.add_child(hint)
	first.grab_focus()
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)   # centrato davvero, anche con i testi grandi


## Le Opzioni (scripts/ui/options_menu.gd) sopra il menu di pausa; chiudendole si torna alla pausa.
func _open_options() -> void:
	if pause_menu == null:
		return
	pause_menu.visible = false
	var m := OptionsMenu.new()
	m.closed.connect(func() -> void:
		if pause_menu != null and is_instance_valid(pause_menu):
			pause_menu.visible = true
			get_tree().paused = true
			for b in pause_menu.find_children("*", "Button", true, false):
				b.grab_focus.call_deferred()
				break)
	add_child(m)


## Pagina del volume dentro il menu di pausa: un cursore per ogni categoria di suoni.
## Col pad: su e giù per scegliere, sinistra e destra per regolare.
func _show_audio_menu() -> void:
	if pause_menu == null:
		return
	var old := pause_menu.get_node_or_null("Audio")
	if old != null:
		old.queue_free()
	for c in pause_menu.get_children():
		if c is VBoxContainer:
			c.visible = false
	var box := VBoxContainer.new()
	box.name = "Audio"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-130, -120) * Fx.ui
	box.custom_minimum_size = Vector2(260, 240) * Fx.ui
	box.add_theme_constant_override("separation", 4)
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = Lang.t("Volume")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", Fx.fs(16))
	title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.3))
	box.add_child(title)
	var first: Control = null
	for c in Sfx.CATEGORIES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = c[1]
		name_label.custom_minimum_size = Vector2(110, 0) * Fx.ui
		name_label.add_theme_font_size_override("font_size", Fx.fs(9))
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sfx.volumes.get(c[0], 1.0)
		slider.custom_minimum_size = Vector2(120, 20) * Fx.ui    # alta abbastanza da prenderla con il dito
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(slider.value * 100.0)
		pct.custom_minimum_size = Vector2(32, 0) * Fx.ui
		pct.add_theme_font_size_override("font_size", Fx.fs(9))
		row.add_child(pct)
		slider.value_changed.connect(_on_volume_changed.bind(c[0], pct))
		if first == null:
			first = slider
	var back := Button.new()
	back.text = Lang.t("Indietro")
	back.add_theme_font_size_override("font_size", Fx.fs(11))
	back.pressed.connect(_close_audio_menu)
	box.add_child(back)
	first.grab_focus()
	box.add_theme_constant_override("separation", 3)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _on_volume_changed(value: float, category: String, pct: Label) -> void:
	Sfx.set_volume(category, value)
	pct.text = "%d%%" % roundi(value * 100.0)
	# un suono di prova della categoria, così senti subito il risultato
	for s in Sfx.SOUNDS:
		if category == "generale" or Sfx.SOUNDS[s][1] == category:
			Sfx.play(s, 0.0)
			break


func _close_audio_menu() -> void:
	Meta.save()
	if pause_menu == null:
		return
	var audio := pause_menu.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	for c in pause_menu.get_children():
		if c is VBoxContainer and c.name != "Audio":
			c.visible = true
			for b in c.get_children():
				if b is Button:
					b.grab_focus()
					break


## Abbandonare conta come una morte: il Ka raccolto viene custodito lo stesso.
func _abandon_run() -> void:
	Run.clear_descent()
	Meta.last_end = "abandon"
	Meta.last_room = Run.room
	Meta.last_region = Run.region
	Run.rebirth = "death"
	_end_run_summary()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


func _restart_run() -> void:
	Run.clear_descent()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Uscire a metà discesa non la perde: è salvata all'inizio della stanza e riprende al prossimo avvio.
## Nel browser il gioco non può chiudere la pagina (si fermava e sembrava bloccato): si torna alla
## Sala, e la discesa salvata riprende passando dal cancello.
func _quit_game() -> void:
	Meta.save()
	if OS.has_feature("web") or OS.get_environment("DUAT_WEBQUIT") != "":
		Run.hold_descent = true
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/hub.tscn")
		return
	get_tree().quit()


# ---------------------------------------------------------------- menu dei doni (Tab)

func _toggle_boons_panel() -> void:
	if finished or pause_menu != null:
		return
	if panel != null:
		panel.queue_free()
		panel = null
		if menu == null:
			get_tree().paused = false
		else:
			_refocus_choice()
		return
	get_tree().paused = true
	if menu != null:
		get_viewport().gui_release_focus()   # mentre guardi i doni non scegli per sbaglio una carta
	panel = CanvasLayer.new()
	panel.layer = 25                         # sopra la scelta dei doni
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panel)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)
	var close := Button.new()
	close.text = Lang.t("Chiudi")
	UiStyle.papyrus_button(close, UiStyle.GOLD)
	close.add_theme_font_size_override("font_size", Fx.fs(9))
	close.focus_mode = Control.FOCUS_NONE
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.position += Vector2(-8, 6)
	close.pressed.connect(_toggle_boons_panel)
	panel.add_child.call_deferred(close)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 40
	label.offset_top = 24
	label.offset_right = -40
	label.offset_bottom = -24
	label.add_theme_font_size_override("normal_font_size", Fx.fs(9))
	label.add_theme_font_size_override("bold_font_size", Fx.fs(10))
	label.add_theme_font_override("normal_font", UiStyle.body_font())
	label.add_theme_font_override("bold_font", UiStyle.title_font())
	panel.add_child(label)
	label.text = _boons_text()


func _refocus_choice() -> void:
	if menu == null:
		return
	for b in menu.find_children("*", "Button", true, false):
		if b.has_meta("text"):
			b.grab_focus()
			return


func _boons_text() -> String:
	var t := Lang.t("[center][b][color=#f0b94c]I tuoi doni[/color][/b]   [color=#a89878](%s)[/color][/center]\n\n") % (Lang.t("tocca per chiudere") if Fx.device == "touch" else Lang.t("Tab o Select per chiudere"))
	if Run.boons.is_empty() and Run.blessings.is_empty() and Run.curses.is_empty():
		t += Lang.t("[center]Nessun dono, per ora. Ripulisci una stanza e scegline uno.[/center]")
		return t
	for id in Run.boons:
		var b: Dictionary = Boons.ALL[id]
		var col: String = Boons.god_color(b["god"]).to_html(false)
		var lvl := Lang.t("pesante") if Boons.is_heavy(id) else ("bilancia" if Boons.ALL[id].get("balanced", false) else (Lang.t("doppio") if Boons.is_duo(id) else Lang.t("liv. %d") % Run.boons[id]))
		t += Lang.t("[color=#%s][b]%s[/b] · %s · %s[/color]\n%s") % [col, Boons.god_name(b["god"]), b["name"], lvl, Boons.text(id, Run.boons[id])]
		if Boons.has_cost(id):
			t += Lang.t(" [color=#ff9c8c]Prezzo: %s[/color]") % Weapons.adapt(b["cost"])
		t += "\n\n"
	var set_col: String = Boons.god_color("set").to_html(false)
	for c in Run.curses:
		t += Lang.t("[color=#%s][b]Maledizione di Set[/b] · ancora %d stanze[/color]\n%s. Poi: %s\n\n") % [set_col, c["rooms"], Boons.SET_CURSES[c["curse"]]["desc"], Weapons.adapt(Boons.SET_BLESSINGS[c["blessing"]]["desc"])]
	for b in Run.blessings:
		t += Lang.t("[color=#%s][b]Set[/b] · %s · permanente[/color]\n%s\n\n") % [set_col, Boons.SET_BLESSINGS[b]["name"], Weapons.adapt(Boons.SET_BLESSINGS[b]["desc"])]
	return t


# ---------------------------------------------------------------- fine run

func _on_player_died() -> void:
	finished = true
	can_leave = false
	Run.clear_descent()
	var where := (Lang.t("Aker, il leone dell'orizzonte") if Run.region == 2 else Lang.t("Am-heh, il Divoratore di Milioni")) if Run.room > Run.ROOMS_PER_RUN else Lang.t("stanza %d di %d, piano %d") % [Run.room, Run.ROOMS_PER_RUN, Run.depth()]
	if current_reward.get("kind", "") == "guardian":
		where = Lang.t("il Serpente della Porta") if Run.region == 1 else Lang.t("Serket, la dea scorpione")
		if Run.region == 1:
			Meta.serpent_streak += 1         # dopo 3 di fila Anubi offre la Piuma di Ma'at
	Meta.last_end = "ammit" if Run.room > Run.ROOMS_PER_RUN else "room"   # "ammit" = morto contro il boss della regione (nome storico nel salvataggio)
	if Meta.feather:
		Meta.feather_deaths += 1
	# tre morti di fila entro la stanza 4: Anubi offre la Piuma (una volta sola, dialogue.gd "piuma3")
	Meta.early_streak = Meta.early_streak + 1 if Run.region == 1 and Run.room <= 4 else 0
	Meta.last_room = Run.room
	Meta.last_region = Run.region
	var killer: String = Lang.t(KILLER_NAMES.get(Run.last_hit, ""))
	var summary := _end_run_summary()
	boss_bar.visible = false
	Music.play("death")
	_death_screen(where, killer, summary)


## La morte: tutto rallenta, un lampo rosso, lo schermo si scurisce e compare la bilancia
## di Ma'at: il cuore scende, più pesante della piuma. Poi il papiro con il riepilogo.
func _death_screen(where: String, killer: String, summary: String) -> void:
	Sfx.play("death", 0.0)
	Fx.shake(8.0)
	Engine.time_scale = 0.2
	var layer := CanvasLayer.new()
	layer.layer = 18
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var red := ColorRect.new()
	red.color = Color(0.8, 0.05, 0.03, 0.55)
	red.set_anchors_preset(Control.PRESET_FULL_RECT)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(red)
	var dark := ColorRect.new()
	dark.color = Color(0.02, 0.01, 0.03, 0.0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dark)
	# il Ba, l'anima-uccello, lascia il corpo e vola via sopra il buio: tornerà nella Sala (rebirth.gd)
	if player != null and is_instance_valid(player):
		var ba := Rebirth.BaSoul.new()
		var ct: Transform2D = player.get_global_transform_with_canvas()
		ba.position = ct.origin + Vector2(0, -14) * ct.get_scale().y
		ba.scale = ct.get_scale() * 1.2
		layer.add_child(ba)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(red, "color:a", 0.0, 0.9)
	tw.parallel().tween_property(dark, "color:a", 0.88, 1.6)
	tw.parallel().tween_property(Engine, "time_scale", 1.0, 1.6).set_delay(0.6)
	tw.tween_callback(func() -> void:
		get_tree().paused = true
		_death_panel(layer, where, killer, summary))


func _death_panel(layer: CanvasLayer, where: String, killer: String, summary: String) -> void:
	var u := Fx.ui
	var vs := get_viewport().get_visible_rect().size
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(4 * u))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	var scale_draw := DeathScale.new()
	scale_draw.custom_minimum_size = Vector2(120, 70) * u
	scale_draw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(scale_draw)
	var title := UiStyle.heading(Lang.t("Il tuo cuore è stato pesato"), 18, Color(0.95, 0.4, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.45, 0.12, 0.08)))
	pap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(3 * u))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pap.add_child(col)
	var w := minf(440.0 * u, vs.x - 40.0)
	var l1 := UiStyle.label(Lang.t("Sei caduto: ") + where, 10, UiStyle.INK, true, w)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l1)
	if killer != "":
		var l2 := UiStyle.label(Lang.t("Ti ha ucciso ") + killer, 9, UiStyle.INK_RED, false, w)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l2)
	var l3 := UiStyle.label(summary, 8, UiStyle.INK_SOFT, false, w)
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l3)
	var how := Lang.t("Tocca lo schermo") if Fx.device == "touch" else (Lang.t("Premi Start") if Fx.device == "pad" else Lang.t("Premi R"))
	var hint := UiStyle.label(Lang.t("%s per tornare alla Sala del Giudizio") % how, 9, Color(0.95, 0.85, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override("outline_size", 3)
	box.add_child(hint)
	box.modulate.a = 0.0
	var tw := box.create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.8)
	tw.tween_callback(func() -> void: can_leave = true)
	var blink := hint.create_tween().set_loops()
	blink.tween_property(hint, "modulate:a", 0.4, 0.9).set_delay(1.0)
	blink.tween_property(hint, "modulate:a", 1.0, 0.9)


# ---------------------------------------------------------------- boss

func _start_boss() -> void:
	Diag.record("boss")
	# silenzio finché il boss non si presenta: la musica parte con lui (_boss_intro)
	Music.stop()
	boss_fill.color = Color(0.85, 0.2, 0.15)
	if _boss_kind() == "aker":
		boss_name.text = Lang.t("AKER, IL LEONE DELL'ORIZZONTE")
		boss_fill.color = Color(0.95, 0.65, 0.25)
	elif _boss_kind() == "amheh":
		boss_name.text = Lang.t("AM-HEH, IL DIVORATORE DI MILIONI")
		boss_fill.color = Color(0.95, 0.45, 0.1)
	else:
		boss_name.text = Lang.t("AMMIT, LA DIVORATRICE")
	boss_bar.visible = true
	boss_fill.size.x = boss_bar.size.x
	spawning += 1
	var at := Vector2(ROOM.size.x / 2.0, TOP + 110.0)
	if _boss_kind() == "aker":
		at = Vector2(ROOM.size.x / 2.0, (TOP + ROOM.size.y - WALL) / 2.0 - 30.0)   # sulla strada del sole
	_spawn_after(_boss_kind(), at, 1.6)


## I pezzi vivi delle arene: il lago che respira e i babbuini, l'acqua che luccica e la grata
## che cade alle tue spalle.
func _build_arena(arena: String, pool_spots: Array) -> void:
	if arena == "lake":
		var glow := Arenas.LakeGlow.new()
		glow.room = ROOM
		glow.top = TOP
		glow.wall = WALL
		world.add_child(glow)
		var pools := get_tree().get_nodes_in_group("water")
		for b in Arenas.baboons(pool_spots):
			var bab := Arenas.Baboon.new()
			bab.position = b
			for w in pools:
				if bab.pool == null or w.global_position.distance_to(b) < bab.pool.global_position.distance_to(b):
					bab.pool = w
			world.add_child(bab)
	elif arena == "horizon":
		var sun := Arenas.HorizonSun.new()
		world.add_child(sun)
		horizon_sun = sun
	elif arena == "temple":
		var dust := Arenas.TempleDust.new()
		dust.room = ROOM
		dust.top = TOP
		dust.wall = WALL
		world.add_child(dust)
	elif arena == "gate":
		var sh := Arenas.GateShimmer.new()
		sh.room = ROOM
		sh.top = TOP
		sh.wall = WALL
		world.add_child(sh)
		var bars := Arenas.GateBars.new()
		bars.position = Vector2(ROOM.size.x / 2.0, ROOM.size.y)
		bars.z_index = 2
		world.add_child(bars)


## Stanza 5: il Serpente della Porta.
func _start_guardian() -> void:
	Diag.record("guardiano")
	Music.stop()
	if Run.region == 2:
		# Sokar: Serket nel suo tempio (niente statue del cobra: la complicazione sono i suoi scorpioni)
		boss_name.text = Lang.t("SERKET, LA DEA SCORPIONE")
		boss_fill.color = Color(0.25, 0.75, 0.7)
		boss_bar.visible = true
		boss_fill.size.x = boss_bar.size.x
		spawning += 1
		_spawn_after("serket", Vector2(ROOM.size.x / 2.0, TOP + 100.0), 1.4)
		return
	# le statue dell'ureo sulle pareti (Hazards.UraeusStatues), sopra le pareti dipinte
	var ur := Hazards.UraeusStatues.new()
	ur.setup(ROOM, WALL, TOP, pillars)
	world.add_child(ur)
	for i in range(world.get_child_count()):
		if world.get_child(i).get_script() == DecorScript:
			world.move_child(ur, i + 1)
			break
	boss_name.text = Lang.t("IL SERPENTE DELLA PORTA")
	boss_fill.color = Color(0.35, 0.8, 0.3)
	boss_bar.visible = true
	boss_fill.size.x = boss_bar.size.x
	spawning += 1
	_spawn_after("serpent", Vector2(ROOM.size.x / 2.0, TOP + 110.0), 1.4)


## L'altare di Set: una sala rossa senza nemici, con il patto da scegliere.
func _start_set_altar() -> void:
	cleared = true
	_banner(Lang.t("L'altare di Set"), Lang.t("Una deviazione nel deserto rosso. Le tue porte ti aspettano"), Boons.god_color("set"))
	var p = PickupScript.new()
	p.kind = "set"
	world.add_child(p)
	p.position = Vector2(ROOM.size.x / 2.0, (TOP + ROOM.size.y - WALL) / 2.0)
	p.collected.connect(_on_pickup_collected)
	if is_instance_valid(room_decor):
		room_decor.rebake()                # il pavimento diventa rosso e compare l'altare


## La stanza del Traghettatore: niente nemici, tre oggetti da comprare con il Ka della discesa.
func _start_shop(oasis := false) -> void:
	shops_visited += 1
	cleared = true
	var cx := ROOM.size.x / 2.0 + (150.0 if oasis else 0.0)      # nell'Oasi la barca sta a destra
	var mid_y := (TOP + ROOM.size.y - WALL) / 2.0 + (10.0 if oasis else 0.0)
	var boat := FerrymanScript.new()
	boat.position = Vector2(cx, mid_y - 50.0)
	world.add_child(boat)
	ferry = boat
	# la barca è un ostacolo vero (prima ci si passava sopra) e si disegna davanti o dietro
	# all'eroe a seconda di chi è più in basso (vedi _process)
	rooms.solid(Rect2(boat.position + Vector2(-46, -6), Vector2(92, 16)))
	if player != null and is_instance_valid(player):
		world.move_child(boat, player.get_index())
	if oasis:
		return                             # nell'Oasi Mahaf non vende: racconta e porta in barca a Sokar
	_banner(Lang.t("Il Traghettatore"), Lang.t("Mahaf: ") + FerrymanScript.greeting(), Color(0.6, 0.85, 0.95))
	var items := SHOP_ITEMS.duplicate()
	if _upgradable().is_empty():
		items = items.filter(func(it: Dictionary) -> bool: return it["kind"] != "upgrade")
	# Collana di Hathor: un'offerta agli dèi in più, scontata con il livello
	if Run.wears("hathor"):
		items.append({"kind": "boon", "title": "Dono di Hathor", "desc": "Un dio a caso ti offre un dono", "price": 40, "hathor": true})
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var node := FerrymanScript.ShopItem.new()
		node.kind = it["kind"]
		node.title = Lang.t(it["title"])
		node.desc = Lang.t(it["desc"])
		var off := Chapters.value("c94") / 100.0
		if it.get("hathor", false):
			off = maxf(off, Amulets.val_of("hathor") / 100.0)     # lo sconto di Hathor non si somma a Calamaio e tavolozza: vale il più alto
		node.price = roundi(it["price"] * (1.0 - off) * FerrymanScript.trust_discount())
		node.position = Vector2(cx + (i - (items.size() - 1) / 2.0) * (80.0 if oasis else 90.0), mid_y + 50.0)
		world.add_child(node)
		shop_items.append(node)
	_open_doors()


## L'Oasi della quarta ora: la sosta tra Wernes e Sokar (vedi scripts/oasis.gd). Niente nemici.
func _start_oasis() -> void:
	cleared = true
	oasis_nodes.clear()
	var pc := Oasis.pool_center(ROOM, TOP)
	rooms.solid(Rect2(pc - Vector2(Oasis.POOL_RADII.x, Oasis.POOL_RADII.y * 0.8), Vector2(Oasis.POOL_RADII.x * 2.0, Oasis.POOL_RADII.y * 1.6)))
	var spring := Oasis.Spring.new()
	spring.position = pc
	spring.title = Lang.t("La fonte della quarta ora")
	spring.desc = Lang.t("recuperi il 25% della vita (una volta sola)")
	world.add_child(spring)
	oasis_nodes.append(spring)
	Atmos.add_light(spring, Vector2(0, -6), 140.0, Color(0.55, 0.8, 1.0), 1.0, false)
	for b in Oasis.brazier_spots(ROOM, TOP):
		var fl := Oasis.Flame.new()
		fl.position = b + Vector2(0, -6)
		world.add_child(fl)
		Atmos.add_light(fl, Vector2.ZERO, 110.0, Color(1.0, 0.62, 0.3), 1.2, false, true)
	var altar := Oasis.Altar.new()
	altar.position = Vector2(pc.x + 30.0, TOP + 62.0)
	altar.title = Lang.t("L'altare di Imhotep")
	altar.desc = Lang.t("cambia l'amuleto che porti (una volta sola)")
	world.add_child(altar)
	rooms.solid(Rect2(altar.position + Vector2(-26, -12), Vector2(52, 22)))
	oasis_nodes.append(altar)
	var statue := Oasis.Statue.new()
	statue.position = Vector2(ROOM.size.x * 0.5 + 118.0, TOP + 66.0)
	statue.title = Lang.t("La statua di Sokar")
	statue.desc = Lang.t("ascolta")
	world.add_child(statue)
	rooms.solid(Rect2(statue.position + Vector2(-17, -4), Vector2(34, 14)))
	Atmos.add_light(statue, Vector2(0, -40), 80.0, Color(0.94, 0.72, 0.3), 0.8, false)
	oasis_nodes.append(statue)
	if Favors.has("barca"):
		var barque := Oasis.Barque.new()
		barque.position = pc + Vector2(Oasis.POOL_RADII.x + 26.0, 26.0)
		barque.title = Lang.t("La Seconda Barca")
		barque.desc = Lang.t("scambia un dono con un altro dello stesso dio (una volta sola)")
		world.add_child(barque)
		oasis_nodes.append(barque)
	_start_shop(true)
	oasis_mahaf_talked = false
	_banner(Lang.t("L'Oasi della quarta ora"), Lang.t("Qui la notte è breve. Riposa, poi Mahaf ti porterà nella sabbia"), Color(0.7, 0.85, 1.0), 3.0)


func _use_oasis(o: Node2D) -> void:
	Sfx.play("ui", 0.0)
	if o is Oasis.Spring:
		o.used = true
		player.heal(roundf(Run.max_hp * 0.25))
		Fx.burst(o.global_position + Vector2(0, -10), Color(0.6, 0.9, 1.0), 40, 140.0)
		Sfx.play("pickup", 0.0)
		_banner(Lang.t("La fonte della quarta ora"), Lang.t("L'acqua ricorda il Nilo: ti rende un poco di ciò che hai perduto"), Color(0.6, 0.85, 0.95))
	elif o is Oasis.Altar:
		_show_amulet_altar(o)
	elif o is Oasis.Barque:
		_open_swap(o)
	else:
		_banner(Lang.t("Sokar"), Lang.t(Oasis.SOKAR_LINES.pick_random()), Color(0.94, 0.72, 0.3), 4.5)


## Mahaf nell'Oasi: la prima battuta sul viaggio che non hai ancora sentito, poi a caso.
func _oasis_mahaf_line() -> String:
	for i in range(Oasis.MAHAF_LINES.size()):
		var id := "mahaf_oasi_%d" % i
		if not Meta.dialogue_seen.has(id):
			Meta.dialogue_seen.append(id)
			Meta.save()
			return Lang.t(Oasis.MAHAF_LINES[i])
	return Lang.t(Oasis.MAHAF_LINES.pick_random())


## Si sale sulla barca di Mahaf: l'eroe scompare a bordo, la barca scivola verso nord e si entra
## nella prima stanza di Sokar (come faceva la porta del deserto).
func _board_mahaf() -> void:
	boarding = true
	Sfx.play("door")
	player.set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(player, "global_position", ferry.global_position + Vector2(0, -4), 0.35)
	tw.tween_callback(func() -> void: player.visible = false)
	tw.tween_property(ferry, "position", ferry.position + Vector2(0, -70), 1.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(ferry, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func() -> void:
		boarding = false
		_fade_to_room({"kind": "none"}))


## La Seconda Barca: quale dono lasci sulla riva? (poi `_swap_choices` mostra quelli dello stesso dio)
func _open_swap(barque: Node2D) -> void:
	var list := []
	for id in Run.boons:
		var g: String = Boons.ALL[id]["god"]
		if g in ["anubi", "duo", "set"] or Boons.is_heavy(id) or Boons.is_rare(id):
			continue
		if _swap_candidates(id).is_empty() or _needed_by_other(id):
			continue
		list.append(id)
	if list.is_empty():
		_banner(Lang.t("La Seconda Barca"), Lang.t("Nessuno dei tuoi doni può essere scambiato"), Color(0.6, 0.85, 0.95), 3.0)
		return
	get_tree().paused = true
	menu = CanvasLayer.new()
	menu.layer = 20
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var pap := PanelContainer.new()
	pap.add_theme_stylebox_override("panel", UiStyle.papyrus_box(Color(0.3, 0.55, 0.7)))
	center.add_child(pap)
	var vs := get_viewport().get_visible_rect().size
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pap.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(3 * Fx.ui))
	col.custom_minimum_size = Vector2(minf(380.0 * Fx.ui, vs.x - 40.0), 0)
	scroll.add_child(col)
	var h := UiStyle.label(Lang.t("La Seconda Barca"), 13, UiStyle.INK, true)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var sub := UiStyle.label(Lang.t("Quale dono lasci sulla riva? Un altro dello stesso dio salirà con te, allo stesso livello."), 8, UiStyle.INK_SOFT, false, col.custom_minimum_size.x)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var first: Button = null
	for id in list:
		var g: String = Boons.ALL[id]["god"]
		var b := Button.new()
		b.text = "%s · %s (%s)" % [Boons.god_name(g), Boons.ALL[id]["name"], Lang.t("liv. %d") % Run.level(id)]
		UiStyle.papyrus_button(b, Boons.god_color(g))
		b.add_theme_font_size_override("font_size", Fx.fs(8))
		b.pressed.connect(func() -> void:
			_close_choice()
			_swap_choices(id, barque))
		col.add_child(b)
		if first == null:
			first = b
	var back := Button.new()
	back.text = Lang.t("Non scambio nulla")
	UiStyle.papyrus_button(back, Color(0.6, 0.6, 0.65))
	back.add_theme_font_size_override("font_size", Fx.fs(8))
	back.pressed.connect(_close_choice)
	col.add_child(back)
	var fit := func() -> void:
		if is_instance_valid(scroll) and is_instance_valid(col):
			scroll.custom_minimum_size = Vector2(col.custom_minimum_size.x + 4.0, minf(col.get_combined_minimum_size().y, vs.y - 44.0))
	fit.call_deferred()
	first.grab_focus.call_deferred()


## I doni dello stesso dio che potrebbero prendere il posto di `old`.
func _swap_candidates(old: String) -> Array:
	var g: String = Boons.ALL[old]["god"]
	var owned := Run.boons.duplicate()
	owned.erase(old)
	var out := []
	for id in Boons.ALL:
		if id == old or owned.has(id) or Boons.ALL[id]["god"] != g:
			continue
		if Boons.is_heavy(id) or Boons.is_rare(id) or not Boons.available_now(id) or not Boons.fits_weapon(id):
			continue
		if not Boons.requirements_met(id, owned):
			continue
		out.append(id)
	return out


## Un altro dono che hai vive solo grazie a questo? (allora non si scambia)
func _needed_by_other(old: String) -> bool:
	for id in Run.boons:
		if not Boons.REQUIRES.has(id):
			continue
		var reqs: Array = Boons.REQUIRES[id]
		if not reqs.has(old):
			continue
		var other := false
		for r in reqs:
			if r != old and Run.boons.has(r):
				other = true
		if not other:
			return true
	return false


func _swap_choices(old: String, barque: Node2D) -> void:
	var g: String = Boons.ALL[old]["god"]
	var lvl := Run.level(old)
	var pool := _swap_candidates(old)
	pool.shuffle()
	var cards := []
	for id in pool.slice(0, 3):
		var l := mini(lvl, _max_level(id))
		var sh := Boons.short(id, l)
		cards.append({"tag": Lang.t("Al posto di %s") % Boons.ALL[old]["name"], "name": Boons.ALL[id]["name"], "body": Boons.text(id, l),
			"cost": "", "gain": sh[0], "loss": sh[1], "color": Boons.god_color(g), "heavy": false,
			"on_pick": _do_swap.bind(old, id, l, barque)})
	cards.append({"tag": Lang.t("Resta com'è"), "name": Boons.ALL[old]["name"], "body": Boons.text(old, lvl), "color": Color(0.7, 0.7, 0.75), "on_pick": _close_choice})
	_open_choice(Lang.t("La Seconda Barca"), Boons.god_color(g), Lang.t("%s ti offre un altro dei suoi doni") % Boons.god_name(g), cards)


func _do_swap(old: String, id: String, lvl: int, barque: Node2D) -> void:
	Run.boons.erase(old)
	Run.boons[id] = lvl
	barque.used = true
	_close_choice()
	Sfx.play("boon", 0.0)
	Fx.burst(player.global_position + Vector2(0, -10), Boons.god_color(Boons.ALL[id]["god"]), 30, 130.0)
	_banner(Lang.t("La Seconda Barca"), Lang.t("%s al posto di %s") % [Boons.ALL[id]["name"], Boons.ALL[old]["name"]], Color(0.6, 0.85, 0.95))


## L'altare di Imhotep: fino a due amuleti tra quelli che hai forgiato, oppure tieni il tuo.
func _show_amulet_altar(altar: Node2D) -> void:
	var others := []
	for id in Amulets.ALL_IT:
		if Amulets.owned(id) and not Run.wears(id):
			others.append(id)
	if others.is_empty():
		_banner(Lang.t("L'altare di Imhotep"), Lang.t("Non hai altri amuleti da portare. Se ne forgiano alla Casa della Vita, coi lapislazzuli"), Color(0.94, 0.72, 0.3), 3.5)
		return
	others.shuffle()
	var cards := []
	for id in others.slice(0, 2):
		var d: Dictionary = Amulets.data()[id]
		cards.append({"tag": Lang.t("Amuleto"), "name": d["name"], "body": Amulets.text(id, Amulets.level(id)), "color": Amulets.COLOR, "on_pick": _wear_amulet.bind(id, altar)})
	var cur := Lang.t("Nessun amuleto") if Run.amulet == "" else String(Amulets.data()[Run.amulet]["name"])
	if Run.amulet2 != "":
		cur += " · " + String(Amulets.data()[Run.amulet2]["name"])
	cards.append({"tag": Lang.t("Resta com'è"), "name": cur, "body": "" if Run.amulet == "" else Amulets.text(Run.amulet, Run.amulet_level), "color": Color(0.7, 0.7, 0.75), "on_pick": _close_choice})
	var sub := Lang.t("Un solo amuleto al collo. Scegli ciò che porti, e lascia ciò che non ti serve")
	if Run.amulet2 != "":
		sub = Lang.t("Il nuovo amuleto prende il posto del primo sigillo; il secondo resta dov'è")
	elif Favors.has("collana") and Run.amulet != "":
		sub = Lang.t("Il secondo sigillo della collana è libero: il nuovo amuleto si aggiunge al tuo")
	_open_choice(Lang.t("L'altare di Imhotep"), Amulets.COLOR, sub, cards, Lang.t("Un amuleto è un pensiero fatto di pietra, scriba. Portane uno solo: la saggezza sta nel lasciare il resto."))


func _wear_amulet(id: String, altar: Node2D) -> void:
	if Favors.has("collana") and Run.amulet != "" and Run.amulet2 == "":
		Run.amulet2 = id                   # il secondo sigillo della collana era libero
		Run.amulet2_level = Amulets.level(id)
	else:
		Run.amulet = id
		Run.amulet_level = Amulets.level(id)
	if id == "kheper":
		Run.kheper_left = int(Amulets.value("kheper", Amulets.level(id)))
	altar.used = true
	_close_choice()
	Sfx.play("boon", 0.0)
	Fx.burst(player.global_position + Vector2(0, -10), Amulets.COLOR, 30, 130.0)
	_banner(Lang.t("Porti %s") % Amulets.data()[id]["name"], Amulets.short(id, Amulets.level(id)), Amulets.COLOR)


## Doni che possono ancora salire di livello (per l'Inchiostro di Thoth).
func _upgradable() -> Array:
	var out := []
	for id in Run.boons:
		if Boons.ALL[id].get("god", "") in ["anubi", "duo"]:
			continue
		if Run.level(id) < _max_level(id):
			out.append(id)
	return out


func _buy(item) -> void:
	if item.sold:
		return
	if Run.ka < item.price:
		Fx.float_text(player.global_position + Vector2(0, -20), Lang.t("Non hai abbastanza Ka"), Color(0.9, 0.4, 0.35))
		Fx.shake(2.0)
		return
	Run.ka -= item.price
	Run.ka_spent += item.price
	Challenges.on_ka_spent(Run.ka_spent)
	item.sold = true
	Sfx.play("pickup", 0.0)
	Fx.burst(item.global_position + Vector2(0, -20), item.color(), 24, 110.0)
	match item.kind:
		"heal":
			player.heal(roundf(Run.max_hp * 0.3))
		"boon":
			var gods := Boons.gods_with_boons(Run.boons, Run.room + 1)
			if not gods.is_empty():
				_show_boon_menu.call_deferred(gods.pick_random(), false)
		"upgrade":
			var ups := _upgradable()
			if not ups.is_empty():
				var id: String = ups.pick_random()
				Run.add_boon(id)
				_banner(Lang.t("Inchiostro di Thoth"), Lang.t("%s sale al livello %d") % [Boons.ALL[id]["name"], Run.level(id)], Boons.god_color("thoth"))


## Il boss chiama rinforzi (Ammit in furia, Am-heh quando fa evaporare una pozza).
func _bosses_alive() -> int:
	var n := 0
	for b in boss_group:
		if is_instance_valid(b) and not b.dead:
			n += 1
	return n


## Aker si divide in Ieri e Domani (o, con l'ira di Aker, un leone rinasce): i nuovi boss entrano
## nella stanza e nella stessa barra della vita. Aker se ne va senza "morire" (niente vittoria).
func _on_boss_split(lions: Array) -> void:
	var from: Node = boss
	var keep: Array = []
	for b in boss_group:
		if not is_instance_valid(b) or b.dead:
			continue
		if b.get("split_done") == true:
			alive -= 1                     # Aker si è diviso: non c'è più, ma non è stato ucciso
			continue
		keep.append(b)
	boss_group = keep
	for l in lions:
		var lion: Enemy = l
		world.add_child(lion)
		alive += 1
		lion.killed.connect(_on_enemy_killed)
		lion.summon.connect(_on_boss_summon)
		lion.split.connect(_on_boss_split)
		boss_group.append(lion)
	if from == null or not is_instance_valid(from) or from.dead:
		boss = boss_group[0] if not boss_group.is_empty() else null


## Ogni voce è un tipo di nemico (posto libero a caso) o [tipo, posizione] (Serket: i cumuli).
func _on_boss_summon(kinds: Array) -> void:
	for i in range(kinds.size()):
		spawning += 1
		if kinds[i] is Array:
			_spawn_after(kinds[i][0], kinds[i][1], 0.8 + i * 0.15)
		else:
			_spawn_after(kinds[i], _free_spot(), 0.8 + i * 0.15)


## Ammit ha sbattuto contro una colonna: la colonna crolla.
func _on_pillar_broken(body: StaticBody2D) -> void:
	var best := -1
	var best_d := 1e9
	for i in range(pillars.size()):
		var d: float = pillars[i].distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		var p: Vector2 = pillars[best]
		pillars.remove_at(best)
		Fx.burst(p + Vector2(0, -24), Color(0.77, 0.6, 0.39), 40, 180.0)
		Fx.float_text(p + Vector2(0, -40), Lang.t("La colonna crolla"), Color(0.95, 0.85, 0.65))
	body.queue_free()
	queue_redraw()
	if is_instance_valid(pillar_art):
		pillar_art.bake()                  # la colonna crollata sparisce dalla texture


func _boss_defeated() -> void:
	boss_bar.visible = false
	Fx.shake(12.0)
	for c in world.get_children():
		if c is Enemy and not c.dead:
			c.die()
	if _boss_kind() == "aker":
		await _aker_defeated()
		return
	Meta.ammit_wins += 1
	Challenges.on_amheh_beaten()
	Restorations.gain(randi_range(10, 12), player.global_position)
	var win_secs := int((Time.get_ticks_msec() - Run.start_msec) / 1000.0)
	if Meta.best_time < 0 or win_secs < Meta.best_time:
		Meta.best_time = win_secs
	ammit_tears = Meta.claim_boss(BOSS_KIND, 2)  # Lacrime di Iside: solo dai boss, la prima volta con ogni arma
	if Weights.unlocked() and not Meta.feather and Weights.total() > Meta.best_weight:
		Meta.best_weight = Weights.total()
	var first_win := not Meta.sekhem_unlocked
	Meta.sekhem_unlocked = true
	Meta.save()
	if first_win:
		_banner(Lang.t("Am-heh ti cede il suo Sekhem"), Lang.t("Dalla prossima discesa potrai caricare la Forma Divina"), Color(1, 0.85, 0.4))
	else:
		_banner(Lang.t("Am-heh è caduto"), Lang.t("Il lago di fuoco si spegne. La notte continua"), Color(0.94, 0.72, 0.3))
	await get_tree().create_timer(2.0).timeout
	if Run.region < Run.max_region():
		# la notte continua: si apre la porta verso la tappa successiva
		cleared = true
		_banner(Lang.t("La porta della quarta ora"), Lang.t("Oltre il lago, la terra di Sokar. La barca di Ra ti aspetta"), Color(0.9, 0.75, 0.45), 3.0)
		_open_lake_bridge()
		_add_door("n", {"kind": "region"})
		return
	_victory()


## Caduto Am-heh, il lago davanti alla porta si spegne e sale un ponte di basalto: la porta della
## regione successiva sta oltre il lago di fuoco (solido), e senza ponte non si raggiungeva.
func _open_lake_bridge() -> void:
	var strip := Rect2(WALL, TOP, ROOM.size.x - WALL * 2.0, Arenas.LAKE_W)
	for c in world.get_children():
		if c is StaticBody2D and c.position.is_equal_approx(strip.get_center()):
			c.queue_free()
	var gap := Arenas.lake_bridge_gap(ROOM)
	_solid(Rect2(WALL, TOP, gap.x - WALL, Arenas.LAKE_W))
	_solid(Rect2(gap.y, TOP, ROOM.size.x - WALL - gap.y, Arenas.LAKE_W))
	var bridge := Arenas.LakeBridge.new()
	bridge.room = ROOM
	bridge.top = TOP
	world.add_child(bridge)
	for i in range(world.get_child_count()):
		if world.get_child(i).get_script() == DecorScript:
			world.move_child(bridge, i + 1)       # sopra il pavimento, sotto l'eroe
			break
	Fx.shake(5.0)
	Sfx.play("amheh_land", 0.05)


## Aker è caduto: il sole spento dell'orizzonte tremola come se volesse sorgere, e si spegne
## di nuovo. Il sole sorge solo nel finale: qui è "il sole che non sorge" (Ricordo IV).
func _aker_defeated() -> void:
	Meta.aker_wins += 1
	Restorations.gain(randi_range(10, 12), player.global_position)
	var win_secs := int((Time.get_ticks_msec() - Run.start_msec) / 1000.0)
	if Meta.best_time < 0 or win_secs < Meta.best_time:
		Meta.best_time = win_secs
	ammit_tears = Meta.claim_boss("aker", 2)    # Lacrime di Iside: la prima volta con ogni arma
	if Weights.unlocked() and not Meta.feather and Weights.total() > Meta.best_weight:
		Meta.best_weight = Weights.total()
	Meta.save()
	if horizon_sun != null and is_instance_valid(horizon_sun):
		horizon_sun.call("flicker")
		# la telecamera sale verso il sole: il momento si deve vedere, anche se sei in fondo all'arena
		var to_sun: Vector2 = Arenas.SUN_POS + Vector2(0, 90) - player.global_position
		var tw := create_tween()
		tw.tween_property(Fx, "look", to_sun, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.8)
		tw.tween_property(Fx, "look", Vector2.ZERO, 0.6).set_trans(Tween.TRANS_SINE)
	_banner(Lang.t("Aker è caduto"), Lang.t("Il sole tra le montagne trema... e non sorge"), Color(1.0, 0.75, 0.35))
	await get_tree().create_timer(4.2).timeout
	if Run.region < Run.max_region():
		cleared = true
		_add_door("n", {"kind": "region"})
		return
	_victory()


## Bordi dello schermo più scuri: dà l'idea di una tomba illuminata dalle torce.
func _build_vignette() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0.02, 0.01, 0.02, 0.55))
	grad.add_point(0.6, Color(0, 0, 0, 0.05))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(rect)
	$UI.move_child(rect, 0)


func _build_boss_bar() -> void:
	var ui: CanvasLayer = $UI
	boss_name = Label.new()
	boss_name.text = Lang.t("AMMIT, LA DIVORATRICE")
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", Fx.fs(9))
	boss_name.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_name.add_theme_constant_override("outline_size", 4)
	boss_name.position = Vector2(170, 318)
	boss_name.size = Vector2(300, 12)
	boss_bar = ColorRect.new()
	boss_bar.color = Color(0.1, 0.02, 0.02, 0.85)
	# in basso al centro: in alto copriva la stanza (sul telefono più stretta, tra levetta e pulsanti)
	var bw := 250.0 if Fx.mobile else 300.0
	boss_bar.size = Vector2(bw, 6)
	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.85, 0.2, 0.15)
	boss_fill.size = Vector2(bw, 6)
	boss_bar.add_child(boss_fill)
	boss_bar.add_child(boss_name)
	boss_name.position = Vector2(0, -15)
	boss_name.size = Vector2(bw, 12)
	boss_name.add_theme_font_override("font", UiStyle.title_font())
	ui.add_child(boss_bar)
	boss_bar.visible = false


## Riepilogo della discesa. Salva anche il Ka raccolto, che resta tra una run e l'altra.
func _end_run_summary() -> String:
	var banked := roundi(Run.ka * Weights.ka_mult() * (FEATHER_KA if Meta.feather else 1.0))
	Meta.ka_bank += banked
	Meta.last_killer = Run.last_hit
	Meta.last_pacts = Run.blessings.size()
	var count := {}
	for id in Run.boons:
		var g: String = Boons.ALL[id].get("god", "")
		if g != "" and g != "anubi" and g != "duo":
			count[g] = int(count.get(g, 0)) + 1
	Meta.last_god = ""
	for g in count:
		if Meta.last_god == "" or count[g] > count[Meta.last_god]:
			Meta.last_god = g
		Meta.god_picks[g] = int(Meta.god_picks.get(g, 0)) + int(count[g])
	# il registro dello scriba (restauro): chi ti ha fermato, quanti nemici, fin dove sei arrivato
	if not finished and Run.last_hit != "":
		Meta.killers[Run.last_hit] = int(Meta.killers.get(Run.last_hit, 0)) + 1
	Meta.total_kills += Run.kills
	Meta.best_room = maxi(Meta.best_room, Run.depth(Run.region, mini(Run.room, Run.ROOMS_PER_RUN)))
	Meta.runs += 1
	Meta.save()
	var secs := int((Time.get_ticks_msec() - Run.start_msec) / 1000.0)
	var lines := [
		Lang.t("Tempo %d:%02d   ·   Nemici abbattuti %d   ·   Danni inflitti %d") % [floori(secs / 60.0), secs % 60, Run.kills, int(Run.damage_dealt)],
		Lang.t("Doni raccolti %d   ·   Ka raccolto %d%s   ·   Ka custodito %d") % [Run.boons.size() + Run.blessings.size(), banked, "" if Weights.total() == 0 else Lang.t(" (Peso del Cuore +%d%%)") % int(round((Weights.ka_mult() - 1.0) * 100.0)), Meta.ka_bank],
	]
	return "\n".join(lines)


func _victory() -> void:
	finished = true
	Run.clear_descent()
	Music.play("hub")
	for c in world.get_children():
		if c is Enemy:
			c.queue_free()
	message.visible = true
	# i nuovi poteri arrivano con la prima vittoria su Am-heh: dopo Aker non si ripetono
	var extra := Lang.t("\nNuovi poteri: il Sekhem e la Forma Divina (Q / LT), e un posto in più nel Libro dei Morti") if Meta.ammit_wins == 1 and Run.region == 1 else ""
	var ric := Lore.ricordo_for(Meta.aker_wins, "aker") if Run.region == 2 else Lore.ricordo_for(Meta.ammit_wins)
	if ric != "":
		extra += Lang.t("\nUn ricordo è riaffiorato: «%s». Lo trovi nei Papiri di Thoth") % ric
	if ammit_tears > 0:
		extra += Lang.t("\n+%d Lacrime di Iside, prima vittoria con %s (ne hai %d)") % [ammit_tears, Weapons.ALL[Run.weapon]["the"], Meta.tears]
	else:
		extra += (Lang.t("\nCon %s hai già le Lacrime di Aker: prova un'altra arma, o un Peso del Cuore più alto") if Run.region == 2 else Lang.t("\nCon %s hai già le Lacrime di Am-heh: prova un'altra arma, o un Peso del Cuore più alto")) % Weapons.ALL[Run.weapon]["the"]
	Meta.last_end = "win"
	Meta.last_region = Run.region
	var head := Lang.t("Hai sconfitto Am-heh!\nLa Prima Ora è superata. Le altre ore della notte ti attendono.")
	if Run.region == 2:
		head = Lang.t("Hai sconfitto Aker!\nIeri e Domani sono caduti, ma il sole non è sorto. La notte continua.")
	message.text = Lang.t("%s%s\n\n%s\n\nPremi R (o Start, o tocca lo schermo) per tornare alla Sala del Giudizio") % [head, extra, _end_run_summary()]
	_fit_message()


## La scritta della vittoria va a capo e, se non entra in altezza, rimpicciolisce: sul telefono
## (e in inglese, con righe più lunghe) usciva dai lati dello schermo.
func _fit_message() -> void:
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.offset_left = 20.0
	message.offset_right = -20.0
	var vh := get_viewport().get_visible_rect().size.y
	var fs := message.get_theme_font_size("font_size")
	while fs > Fx.fs(8) and message.get_minimum_size().y > vh - 16.0:
		fs -= 1
		message.add_theme_font_size_override("font_size", fs)


# ---------------------------------------------------------------- ogni frame

## Le colonne sono alte, ma solida è solo la base: chi passa DIETRO una colonna (più in alto sullo
## schermo) deve essere coperto dal fusto, chi sta DAVANTI deve coprirlo. Prima i personaggi erano
## sempre disegnati sopra e chi passava dietro sembrava attraversare la pietra. Gli avvoltoi volano
## e restano sopra (z 3, vulture.gd).
## Il tasto d'azione davanti ai suggerimenti: "E · ", "Y · " del pad; niente sul telefono, dove
## c'è il pulsante con la scritta.
func _key_prefix() -> String:
	if Fx.device == "touch":
		return ""
	return "Y · " if Fx.device == "pad" else "E · "


func _pillar_depth() -> void:
	if pillars.is_empty():
		return
	var who: Array = get_tree().get_nodes_in_group("enemies")
	if player != null and is_instance_valid(player):
		who.append(player)
	for c in who:
		if c.z_index > 2:
			continue
		var front := false
		for p in pillars:
			var d: Vector2 = c.global_position - p
			if absf(d.x) < 30.0 and d.y >= -2.0 and d.y < 48.0:
				front = true
				break
		c.z_index = 2 if front else 0


func _process(_delta: float) -> void:
	_pillar_depth()
	if Input.is_action_just_pressed("debug_hitbox"):
		Fx.set_hitboxes(not Fx.show_hitboxes)
	if Input.is_action_just_pressed("restart") and (finished or player.dead) and can_leave:
		can_leave = false
		Rebirth.to_hub(self, Meta.last_end == "win")     # lo scarabeo spinge il sole, si rinasce nella Sala
		return
	if player == null or not is_instance_valid(player):
		return

	var eye_txt := Lang.t("pronto") if player.eye_ready() else "%.1fs" % player.eye_cd
	var sek := Lang.t("PRONTO (Q / LT)") if Run.sekhem_ready() else "%d%%" % int(Run.sekhem)
	if player.divine_t > 0.0:
		sek = Lang.t("FORMA DIVINA %.1fs") % player.divine_t
	var room_txt := (Lang.t("Ammit · colonne: %d") % pillars.size() if _boss_kind() == "ammit" else (Lang.t("Aker") if _boss_kind() == "aker" else Lang.t("Am-heh"))) if Run.room > Run.ROOMS_PER_RUN else Lang.t("Stanza %d/%d") % [Run.room, Run.ROOMS_PER_RUN]
	if Run.max_region() > 1 and Run.room <= Run.ROOMS_PER_RUN:
		room_txt = Run.region_name() + " · " + room_txt
	if tut.step >= 0:
		room_txt = Lang.t("Addestramento")
		tut.tick()
	# vita, Ka, stanza, Occhio e Sekhem sono disegnati come barre da HudBars; qui resta il testo
	hud.text = ""
	hud_room = room_txt
	hud_eye = eye_txt
	hud_sek = sek
	if Meta.feather:
		hud.text = Lang.t("Piuma di Ma'at: -%d%% danni") % int(round(Run.feather_guard() * 100.0))
	if boss_group.size() > 1 or (boss != null and is_instance_valid(boss) and boss.is_boss and boss_full > 0.0):
		# una barra sola per tutto lo scontro (Aker: le due fasi, poi Ieri + Domani insieme)
		var sum := 0.0
		for b in boss_group:
			if is_instance_valid(b) and not b.dead:
				sum += b.hp
		boss_fill.size.x = boss_bar.size.x * clampf(sum / boss_full, 0.0, 1.0)
	elif boss != null and is_instance_valid(boss) and not boss.dead:
		boss_fill.size.x = boss_bar.size.x * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	var n := Run.boons.size() + Run.blessings.size()
	var line2 := ""
	if n > 0:
		line2 = (Lang.t("Doni: %d") % n) if Fx.device == "touch" else Lang.t("Doni: %d (Tab per vederli)") % n
	for c in Run.curses:
		line2 += Lang.t("    Maledizione: %s (ancora %d stanze)") % [Boons.SET_CURSES[c["curse"]]["desc"], c["rooms"]]
	# Scettro Was: quante stanze pulite ha già contato (il bonus non si perde prendendo danni)
	if Run.wears("was") and not Run.training:
		var was_bonus := roundi(Run.was_stacks * Amulets.val_of("was"))
		line2 += Lang.t("    Was %d/5 (+%d%% danni)") % [Run.was_stacks, was_bonus]
	if line2 != "":
		hud.text += ("\n" if hud.text != "" else "") + line2.strip_edges()
	# la clessidra di Thoth (restauro della Sala): il tempo della discesa e il record
	if Restorations.has("clessidra") and tut.step < 0 and not finished:
		var secs := int((Time.get_ticks_msec() - Run.start_msec) / 1000.0)
		var clock := Lang.t("Tempo %d:%02d") % [floori(secs / 60.0), secs % 60]
		if Meta.best_time >= 0:
			clock += Lang.t("  ·  record %d:%02d") % [floori(Meta.best_time / 60.0), Meta.best_time % 60]
		hud.text += ("\n" if hud.text != "" else "") + clock
	var vsz := get_viewport().get_visible_rect().size
	boss_bar.position = Vector2((vsz.x - boss_bar.size.x) / 2.0, vsz.y - (12.0 if Fx.mobile else 30.0))

	var near := ""
	var shop_near = null
	for it in shop_items:
		if is_instance_valid(it) and not it.sold and player.global_position.distance_to(it.global_position) < 26.0:
			shop_near = it
	if shop_near != null:
		near = Lang.t("%s · %s: %s (%d Ka, ne hai %d)") % ["Y" if Fx.device == "pad" else "E", shop_near.title, shop_near.desc, shop_near.price, Run.ka]
		if Input.is_action_just_pressed("interact") and menu == null:
			_buy(shop_near)
	# l'Oasi: fonte, altare e statua (gli oggetti del Traghettatore hanno la precedenza)
	var oasis_near: Node2D = null
	if shop_near == null:
		for o in oasis_nodes:
			if is_instance_valid(o) and not o.used and player.global_position.distance_to(o.global_position) < o.reach:
				oasis_near = o
		if oasis_near != null:
			near = "%s · %s: %s" % ["Y" if Fx.device == "pad" else "E", oasis_near.title, oasis_near.desc]
			if Input.is_action_just_pressed("interact") and menu == null:
				_use_oasis(oasis_near)
	# parlare con Mahaf: vicino alla barca (gli oggetti in vendita hanno la precedenza)
	if is_instance_valid(ferry):
		ferry.z_index = 1 if player.global_position.y < ferry.global_position.y + 6.0 else 0
		var by_boat: bool = shop_near == null and oasis_near == null and player.global_position.distance_to(ferry.global_position + Vector2(0, 12)) < 56.0
		ferry.near = by_boat
		var in_oasis: bool = current_reward.get("kind", "") == "oasis"
		if by_boat and in_oasis and oasis_mahaf_talked:
			near = Lang.t("%s · Sali sulla barca di Mahaf: verso la terra di Sokar") % ("Y" if Fx.device == "pad" else "E")
			if Input.is_action_just_pressed("interact") and menu == null and not boarding:
				_board_mahaf()
		elif by_boat:
			near = Lang.t("%s · Parla con Mahaf") % ("Y" if Fx.device == "pad" else "E")
			if Input.is_action_just_pressed("interact") and menu == null:
				Sfx.play("ui", 0.0)
				ferry.say(_oasis_mahaf_line() if in_oasis else FerrymanScript.talk_line())
				oasis_mahaf_talked = true
	# le porte: da vicino si legge cosa c'è dietro; accanto si entra con "interagisci"
	for d in doors:
		if not is_instance_valid(d) or not d.open or d._used:
			continue
		var dd: float = player.global_position.distance_to(d.global_position)
		if dd < 70.0:
			near = d.reward_description()
		if dd < DOOR_REACH and d.open_k >= 0.6 and shop_near == null and oasis_near == null:
			near = _key_prefix() + Lang.t("Entra · %s") % d.reward_description()
			if Input.is_action_just_pressed("interact") and menu == null:
				d.enter()
				break
	prompt.text = near
	prompt.visible = near != ""

	var mouse := Fx.device == "mouse"
	reticle.visible = mouse and not player.dead and menu == null and panel == null and pause_menu == null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if (mouse and menu == null and panel == null and pause_menu == null) else Input.MOUSE_MODE_VISIBLE
	if Fx.device == "touch":
		help.text = ""
	elif Fx.device == "pad":
		help.text = Lang.t("Levetta sinistra muovi · destra mira · RB attacca · RT Occhio · LB/A scatto · LT Forma Divina · Select doni · Start pausa")
	else:
		help.text = Lang.t("WASD muovi · mouse mira · clic sinistro attacca · Spazio scatto · clic destro Occhio · Q Forma Divina (dopo il primo boss) · Tab doni · Esc pausa · F1 hitbox")
	if TRAILER:
		help.text = ""                       # riprese per trailer e screenshot: niente scritte d'aiuto
		reticle.visible = false


# ---------------------------------------------------------------- muri e pavimento
# La costruzione delle stanze è in scripts/room_builder.gd. Qui restano i nomi di prima.

func _free_spot() -> Vector2:
	return rooms.free_spot()


func _free_spot_near(center: Vector2) -> Vector2:
	return rooms.free_spot_near(center)


func _unstick_spot(from: Vector2) -> Vector2:
	return rooms.unstick_spot(from)


func _in_floor(p: Vector2, margin: float) -> bool:
	return rooms.in_floor(p, margin)


func _spot_ok(p: Vector2) -> bool:
	return rooms.spot_ok(p)


func _solid(rect: Rect2) -> StaticBody2D:
	return rooms.solid(rect)


func _draw() -> void:
	pass          # pavimento e muri li disegna l'arredamento (paint_floor), cotti nella sua texture


## Pavimento, muri e altare di Set, disegnati su `ci`: l'arredamento della stanza (room_decor.gd)
## li cuoce nella sua texture una volta sola. Disegnati a ogni fotogramma costavano molto: sono
## più di mille rettangoli.
func paint_floor(ci: CanvasItem) -> void:
	var r := ROOM
	var tile := 32.0
	var set_altar: bool = current_reward.get("kind", "") == "set"
	# il pavimento: lastre di pietra con la fuga scura e calda (prima era blu e sembrava una
	# griglia), ogni lastra con il suo tono, il bordo alto in luce e quello basso in ombra
	var floor_r := Rect2(WALL, TOP, r.size.x - WALL * 2.0, r.size.y - WALL - TOP)
	ci.draw_rect(floor_r, Color(0.22, 0.15, 0.09))
	var sokar := Run.region == 2 and not set_altar
	var base := Color(0.55, 0.24, 0.15) if set_altar else (Color(0.6, 0.48, 0.3) if sokar else Color(0.53, 0.4, 0.25))
	var y := TOP
	var row := 0
	while y < r.end.y - WALL:
		var x := r.position.x + WALL - (16.0 if row % 2 == 1 else 0.0)        # lastre sfalsate, come i muri veri
		while x < r.end.x - WALL:
			var x0 := maxf(x, WALL)
			var x1 := minf(x + tile, r.end.x - WALL)
			var n := fmod(absf(sin(x * 12.9898 + y * 78.233 + Run.room) * 43758.5453), 1.0)
			var c := base.darkened(n * 0.16)
			if n > 0.93 and not set_altar:
				c = c.lerp(Color(0.62, 0.5, 0.34), 0.5)        # qualche lastra più chiara, rifatta
			var slab := Rect2(x0 + 1, y + 1, x1 - x0 - 2, tile - 2)
			ci.draw_rect(slab, c)
			ci.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 1.5)), c.lightened(0.14))
			ci.draw_rect(Rect2(slab.position.x, slab.end.y - 2.0, slab.size.x, 2.0), c.darkened(0.22))
			ci.draw_rect(Rect2(slab.end.x - 1.5, slab.position.y, 1.5, slab.size.y), c.darkened(0.12))
			if n > 0.8 and n < 0.86:
				# un angolo scheggiato
				ci.draw_colored_polygon(PackedVector2Array([slab.position + Vector2(slab.size.x - 7, 0), slab.position + Vector2(slab.size.x, 0), slab.position + Vector2(slab.size.x, 6)]), Color(0.22, 0.15, 0.09))
			x += tile
		y += tile
		row += 1
	if sokar:
		# il deserto di Sokar: la sabbia ha invaso la tomba, cumuli e onde che coprono le lastre
		var rng := RandomNumberGenerator.new()
		rng.seed = Run.room * 977 + 13
		for i in range(9):
			var c := Vector2(rng.randf_range(WALL, r.size.x - WALL), rng.randf_range(TOP, r.size.y - WALL))
			var rad := Vector2(rng.randf_range(60, 140), rng.randf_range(24, 50))
			ci.draw_set_transform(c, 0.0, Vector2(1.0, rad.y / rad.x))
			ci.draw_circle(Vector2.ZERO, rad.x, Color(0.78, 0.64, 0.42, 0.55))
			ci.draw_circle(Vector2.ZERO, rad.x * 0.7, Color(0.82, 0.68, 0.46, 0.6))
			for k in range(3):
				ci.draw_arc(Vector2(0, rad.x * 0.2 * k), rad.x * (0.55 + 0.12 * k), PI * 1.15, PI * 1.85, 16, Color(0.66, 0.52, 0.32, 0.5), 1.2)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var dark := Color(0.19, 0.13, 0.08)
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, WALL), dark)
	ci.draw_rect(Rect2(r.position.x, r.position.y + WALL, r.size.x, WALL), Color(0.46, 0.33, 0.2))
	var i := 0
	var fx := r.position.x
	while fx < r.end.x:
		ci.draw_rect(Rect2(fx, r.position.y + WALL + 12, 16, 6), Color(0.25, 0.66, 0.6) if i % 2 == 0 else Color(0.91, 0.69, 0.29))
		fx += 16.0
		i += 1
	ci.draw_rect(Rect2(r.position.x, r.end.y - WALL, r.size.x, WALL), dark)
	ci.draw_rect(Rect2(r.position.x, r.position.y, WALL, r.size.y), dark)
	ci.draw_rect(Rect2(r.end.x - WALL, r.position.y, WALL, r.size.y), dark)
	# i blocchi di pietra dei muri, con la cima appena in luce: i muri hanno spessore
	var block := Color(0.26, 0.18, 0.11)
	var by := WALL
	var brow := 0
	while by < r.end.y - 4.0:
		for side in [r.position.x, r.end.x - WALL]:
			var off := 0.0 if brow % 2 == 0 else 8.0
			ci.draw_line(Vector2(side, by), Vector2(side + WALL, by), block, 1.0)
			ci.draw_line(Vector2(side + 8.0 + off, by), Vector2(side + 8.0 + off, by + 16.0), block, 1.0)
		by += 16.0
		brow += 1
	var bx := r.position.x
	var bcol := 0
	while bx < r.end.x:
		var off2 := 0.0 if bcol % 2 == 0 else 8.0
		ci.draw_line(Vector2(bx + off2, r.end.y - WALL), Vector2(bx + off2, r.end.y), block, 1.0)
		bx += 24.0
		bcol += 1
	ci.draw_line(Vector2(r.position.x, r.end.y - WALL + 16.0), Vector2(r.end.x, r.end.y - WALL + 16.0), block, 1.0)
	var lip := Color(0.42, 0.3, 0.18)
	ci.draw_rect(Rect2(WALL - 3.0, TOP, 3.0, r.size.y - WALL - TOP), lip)
	ci.draw_rect(Rect2(r.end.x - WALL, TOP, 3.0, r.size.y - WALL - TOP), lip)
	ci.draw_rect(Rect2(WALL - 3.0, r.end.y - WALL, r.size.x - WALL * 2.0 + 6.0, 3.0), lip)
	ci.draw_rect(Rect2(r.size.x / 2.0 - 18.0, r.end.y - WALL, 36, 14), Color(0.3, 0.22, 0.13))
	if set_altar:
		# l'altare di Set: un blocco di pietra rossa con la bestia di Set incisa
		var ac := Vector2(r.size.x / 2.0, (TOP + r.size.y - WALL) / 2.0 + 18.0)
		ci.draw_rect(Rect2(ac.x - 26, ac.y - 10, 52, 22), Color(0.35, 0.12, 0.08))
		ci.draw_rect(Rect2(ac.x - 30, ac.y + 10, 60, 6), Color(0.25, 0.08, 0.05))
		ci.draw_rect(Rect2(ac.x - 26, ac.y - 10, 52, 22), Color(0.75, 0.3, 0.2), false, 1.5)
		var sc := Color(0.95, 0.45, 0.3)
		ci.draw_line(ac + Vector2(-8, 6), ac + Vector2(-4, -2), sc, 1.5)
		ci.draw_line(ac + Vector2(-4, -2), ac + Vector2(6, -2), sc, 1.5)
		ci.draw_line(ac + Vector2(6, -2), ac + Vector2(10, -6), sc, 1.5)
		ci.draw_line(ac + Vector2(10, -6), ac + Vector2(9, -9), sc, 1.5)
		ci.draw_line(ac + Vector2(-4, -2), ac + Vector2(-9, -8), sc, 1.5)
		ci.draw_line(ac + Vector2(4, -2), ac + Vector2(4, 6), sc, 1.5)
	# le colonne sono in room_decor.gd (Pillars), sopra l'arredamento del pavimento
