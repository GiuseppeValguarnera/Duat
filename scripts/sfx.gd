extends Node
## Effetti sonori. Sfx.play("hit") suona il file "hit" in assets/sfx con un po' di variazione
## di intonazione, così i colpi ripetuti non suonano tutti uguali.
##
## Ogni suono può avere più varianti: hit.ogg, hit_2.ogg, hit_3.ogg...
## Ogni volta ne viene scelta una a caso, diversa dalla precedente.
##
## Ogni suono appartiene a una categoria con il suo volume, regolabile dal menu di pausa.

## Volume di base di ogni suono (in decibel), la sua categoria e, facoltativo, l'intervallo
## minimo in millisecondi tra due riproduzioni (per i suoni ripetuti, come i passi).
## I file sono già normalizzati tra loro (vedi tools/convert_sfx.py), qui si fanno solo ritocchi.
const SOUNDS := {
	"swing": [-3.0, "attacchi"], "hit": [0.0, "attacchi"], "crit": [0.0, "attacchi"],
	"eye": [-2.0, "attacchi"], "divine": [0.0, "attacchi"],
	"dash": [-3.0, "scatto"],
	"hurt": [0.0, "personaggio"], "death": [0.0, "personaggio"],
	"kill": [-1.0, "nemici"], "bite": [0.0, "nemici"], "roar": [0.0, "nemici"], "charge": [0.0, "nemici"],
	"scarab_step": [-6.0, "nemici", 70], "mummy_step": [-5.0, "nemici", 140],
	"mummy_windup": [-2.0, "nemici"], "mummy_lunge": [-2.0, "nemici"],
	"priest_cast": [-3.0, "nemici"], "orb": [-2.0, "nemici"], "orb_pop": [-6.0, "nemici", 60],
	"spikes": [-3.0, "trappole"], "dart": [-2.0, "trappole"],
	"pickup": [0.0, "menu"], "boon": [0.0, "menu"], "door": [0.0, "menu"], "ui": [-4.0, "menu"],
	"book": [0.0, "menu"], "page": [0.0, "menu"],
}
## Categorie mostrate nel menu, nell'ordine in cui compaiono.
const CATEGORIES := [
	["generale", "Volume generale"],
	["musica", "Musica"],
	["attacchi", "Attacchi e colpi"],
	["scatto", "Scatto"],
	["personaggio", "Danni subiti"],
	["nemici", "Nemici e boss"],
	["trappole", "Trappole"],
	["menu", "Ricompense e menu"],
]
const POOL := 14

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last := {}
var last_variant := {}
var next := 0
## Volume di ogni categoria, da 0 (muto) a 1 (pieno). Salvato in Meta.
var volumes := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in CATEGORIES:
		volumes[c[0]] = float(Meta.audio.get(c[0], 0.7 if c[0] == "musica" else 1.0))
	for sound in SOUNDS:
		var variants: Array[AudioStream] = []
		for i in range(1, 10):
			var base: String = sound if i == 1 else "%s_%d" % [sound, i]
			for ext in ["ogg", "wav"]:
				var path := "res://assets/sfx/%s.%s" % [base, ext]
				if ResourceLoader.exists(path):
					variants.append(load(path))
					break
		if not variants.is_empty():
			streams[sound] = variants
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


## Come play(), ma il volume cala con la distanza dal giocatore e i suoni troppo lontani
## (fuori dallo schermo) non si sentono. Per i nemici.
func play_at(sound: String, pos: Vector2, pitch_range: float = 0.1) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var extra := 0.0
	if player != null:
		var d: float = (player as Node2D).global_position.distance_to(pos)
		if d > 380.0:
			return
		extra = -12.0 * clampf(d / 380.0, 0.0, 1.0)
	play(sound, pitch_range, extra)


func play(sound: String, pitch_range: float = 0.08, extra_db: float = 0.0) -> void:
	if not streams.has(sound):
		return
	var linear := volume_of(SOUNDS[sound][1])
	if linear <= 0.001:
		return
	var now := Time.get_ticks_msec()
	var gap: int = SOUNDS[sound][2] if SOUNDS[sound].size() > 2 else 35
	if now - int(last.get(sound, -1000)) < gap:
		return                            # evita di sovrapporre lo stesso suono nello stesso istante
	last[sound] = now
	var p := players[next]
	next = (next + 1) % POOL
	var variants: Array[AudioStream] = streams[sound]
	var pick := randi() % variants.size()
	if variants.size() > 1 and pick == int(last_variant.get(sound, -1)):
		pick = (pick + 1) % variants.size()
	last_variant[sound] = pick
	p.stream = variants[pick]
	p.volume_db = SOUNDS[sound][0] + linear_to_db(linear) + extra_db
	p.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	p.play()


## Volume effettivo di una categoria: il suo volume per quello generale.
func volume_of(category: String) -> float:
	return float(volumes.get("generale", 1.0)) * float(volumes.get(category, 1.0))


func set_volume(category: String, value: float) -> void:
	volumes[category] = clampf(value, 0.0, 1.0)
	Meta.audio[category] = volumes[category]


## All'uscita ferma i suoni ancora in riproduzione, così Godot non segnala risorse rimaste aperte.
func _exit_tree() -> void:
	for p in players:
		p.stop()
		p.stream = null
