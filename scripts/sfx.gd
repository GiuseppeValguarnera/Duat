extends Node
## Effetti sonori. Sfx.play("hit") suona assets/sfx/hit.wav con un po' di variazione
## di intonazione, così i colpi ripetuti non suonano tutti uguali.
## I suoni sono provvisori (generati da tools/make_sfx.py): basta sostituire i file .wav.

const VOLUME := {
	"swing": -14.0, "hit": -8.0, "crit": -6.0, "kill": -9.0, "dash": -13.0, "eye": -12.0,
	"hurt": -5.0, "death": -4.0, "pickup": -8.0, "boon": -7.0, "door": -9.0, "spikes": -14.0,
	"dart": -13.0, "roar": -5.0, "charge": -9.0, "bite": -7.0, "ui": -14.0, "divine": -6.0,
}
const POOL := 14

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last := {}
var next := 0
var master_db := 0.0                  ## volume generale degli effetti (in decibel)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound in VOLUME:
		var path := "res://assets/sfx/%s.wav" % sound
		if ResourceLoader.exists(path):
			streams[sound] = load(path)
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func play(sound: String, pitch_range: float = 0.08) -> void:
	if not streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(last.get(sound, -1000)) < 35:
		return                            # evita di sovrapporre lo stesso suono nello stesso istante
	last[sound] = now
	var p := players[next]
	next = (next + 1) % POOL
	p.stream = streams[sound]
	p.volume_db = VOLUME[sound] + master_db
	p.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	p.play()


## All'uscita ferma i suoni ancora in riproduzione, così Godot non segnala risorse rimaste aperte.
func _exit_tree() -> void:
	for p in players:
		p.stop()
		p.stream = null
