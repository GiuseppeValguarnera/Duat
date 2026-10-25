extends Node
## Musica di sottofondo. Music.play("room") passa a quel brano con una dissolvenza incrociata.
## Brani in assets/music: hub (Sala del Giudizio), room (stanze), elite (stanze con nemici élite), boss (Am-heh).
## Il volume segue la categoria "musica" del menu di pausa (Sfx.volume_of("musica")).

const FADE := 1.6
const TRACKS := ["hub", "room", "elite", "boss", "death"]

var streams := {}
var players: Array[AudioStreamPlayer] = []
var active := 0                       # quale dei due player suona il brano corrente
var current := ""
var levels := [0.0, 0.0]              # volume (0..1) di ciascun player durante le dissolvenze
var targets := [0.0, 0.0]
var duck := 1.0                       # abbassa la musica (per esempio alla morte)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for track in TRACKS:
		var path := "res://assets/music/%s.ogg" % track
		if ResourceLoader.exists(path):
			var s: AudioStreamOggVorbis = load(path)
			s.loop = track != "death"       # la musica della morte suona una volta sola
			streams[track] = s
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		players.append(p)


## Passa al brano `name`. Se sta già suonando non fa nulla.
func play(track: String) -> void:
	duck = 1.0
	if track == current or not streams.has(track):
		return
	current = track
	targets[active] = 0.0
	active = 1 - active
	var p := players[active]
	p.stream = streams[track]
	p.play()
	levels[active] = 0.0
	targets[active] = 1.0


## Abbassa la musica (0..1) senza cambiare brano: alla morte, nei riepiloghi.
func set_duck(value: float) -> void:
	duck = value


func stop() -> void:
	current = ""
	targets = [0.0, 0.0]


func _process(delta: float) -> void:
	var master := Sfx.volume_of("musica")
	for i in range(2):
		levels[i] = move_toward(levels[i], targets[i], delta / FADE)
		var p := players[i]
		var linear: float = levels[i] * master * duck
		if linear <= 0.001:
			p.volume_db = -80.0
			if levels[i] <= 0.0 and targets[i] <= 0.0 and p.playing:
				p.stop()
		else:
			p.volume_db = linear_to_db(linear)


func _exit_tree() -> void:
	for p in players:
		p.stop()
		p.stream = null
