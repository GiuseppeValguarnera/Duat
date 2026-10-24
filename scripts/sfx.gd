extends Node
## Effetti sonori. Sfx.play("hit") suona il file "hit" in assets/sfx con un po' di variazione
## di intonazione, così i colpi ripetuti non suonano tutti uguali.
##
## Per usare suoni veri: metti in assets/sfx un file .ogg (o .wav) con lo stesso nome,
## per esempio hit.ogg. Il file .ogg ha la precedenza su quello generato.
##
## Ogni suono appartiene a una categoria con il suo volume, regolabile dal menu di pausa.

## Volume di base di ogni suono (in decibel) e la sua categoria.
const SOUNDS := {
	"swing": [-14.0, "attacchi"], "hit": [-8.0, "attacchi"], "crit": [-6.0, "attacchi"],
	"eye": [-12.0, "attacchi"], "divine": [-6.0, "attacchi"],
	"dash": [-13.0, "scatto"],
	"hurt": [-5.0, "personaggio"], "death": [-4.0, "personaggio"],
	"kill": [-9.0, "nemici"], "bite": [-7.0, "nemici"], "roar": [-5.0, "nemici"], "charge": [-9.0, "nemici"],
	"spikes": [-14.0, "trappole"], "dart": [-13.0, "trappole"],
	"pickup": [-8.0, "menu"], "boon": [-7.0, "menu"], "door": [-9.0, "menu"], "ui": [-14.0, "menu"],
}
## Categorie mostrate nel menu, nell'ordine in cui compaiono.
const CATEGORIES := [
	["generale", "Volume generale"],
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
var next := 0
## Volume di ogni categoria, da 0 (muto) a 1 (pieno). Salvato in Meta.
var volumes := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in CATEGORIES:
		volumes[c[0]] = float(Meta.audio.get(c[0], 1.0))
	for sound in SOUNDS:
		for ext in ["ogg", "wav"]:
			var path := "res://assets/sfx/%s.%s" % [sound, ext]
			if ResourceLoader.exists(path):
				streams[sound] = load(path)
				break
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func play(sound: String, pitch_range: float = 0.08) -> void:
	if not streams.has(sound):
		return
	var linear := volume_of(SOUNDS[sound][1])
	if linear <= 0.001:
		return
	var now := Time.get_ticks_msec()
	if now - int(last.get(sound, -1000)) < 35:
		return                            # evita di sovrapporre lo stesso suono nello stesso istante
	last[sound] = now
	var p := players[next]
	next = (next + 1) % POOL
	p.stream = streams[sound]
	p.volume_db = SOUNDS[sound][0] + linear_to_db(linear)
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
