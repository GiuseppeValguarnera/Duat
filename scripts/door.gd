extends Area2D
## Porta verso la stanza successiva. Mostra sopra di sé la ricompensa che c'è dietro.

signal chosen(door: Area2D)

var side := "n"                       # n | w | e
var reward := {}                      # {"kind": "boon"/"set"/"ka"/"heal"/"end", "god": "..."}
var open := false
var t := 0.0
var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 12) if side == "n" else Vector2(12, 44)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if open and not _used and body.is_in_group("player"):
		_used = true
		chosen.emit(self)


func reward_color() -> Color:
	match reward.get("kind", ""):
		"boon":
			return Boons.god_color(reward["god"])
		"set":
			return Boons.god_color("set")
		"ka":
			return Color(0.94, 0.72, 0.3)
		"heal":
			return Color(0.95, 0.35, 0.3)
		"boss":
			return Color(0.9, 0.3, 0.25)
		"guardian":
			return Color(0.45, 0.9, 0.4)
		"shop":
			return Color(0.6, 0.85, 0.95)
		_:
			return Color(0.9, 0.9, 1.0)


func reward_label() -> String:
	match reward.get("kind", ""):
		"boon":
			return Boons.god_name(reward["god"])
		"set":
			return "Set"
		"ka":
			return "Ka"
		"heal":
			return "Cura"
		"boss":
			return "Am-heh"
		"guardian":
			return "Guardiano"
		"shop":
			return "Traghettatore"
		"tutorial_end":
			return "La discesa"
		_:
			return "Uscita"


## Testo mostrato quando il giocatore si avvicina.
func reward_description() -> String:
	match reward.get("kind", ""):
		"boon":
			return "Dono di %s: scegli uno dei suoi poteri" % Boons.god_name(reward["god"])
		"set":
			return "Patto di Set: entrare costa 10 vita. Una maledizione per 2 stanze, poi un potere per tutta la run"
		"ka":
			return "Tesoro di Ka: +25 Ka"
		"heal":
			if Run.room + 1 == Run.ROOMS_PER_RUN:
				return "Acqua del Nilo: recuperi il %d%% della vita. Ultima stanza prima di Am-heh" % roundi(Run.nile_heal() * 100.0)
			return "Acqua del Nilo: recuperi il %d%% della vita" % roundi(Run.nile_heal() * 100.0)
		"boss":
			return "Cancello della Prima Ora: Am-heh, il Divoratore di Milioni, ti aspetta nel suo lago di fuoco"
		"guardian":
			return "La Porta di mezzo: il Serpente che la custodisce. Battilo per un dono di livello superiore"
		"shop":
			return "Il Traghettatore: spendi il Ka della discesa (quello che spendi non torna a casa)"
		"tutorial_end":
			return "Comincia la discesa: Anubi ti aspetta con il primo dono"
		_:
			return "Uscita: fine della discesa di prova"


func _draw() -> void:
	var gold := Color(0.94, 0.72, 0.3)
	var size := Vector2(36, 14) if side == "n" else Vector2(14, 36)
	var r := Rect2(-size / 2.0, size)
	if open:
		draw_rect(r, Color(0.02, 0.02, 0.04))
		var glow := reward_color()
		draw_rect(r.grow(2.0 + sin(t * 3.0)), Color(glow, 0.25))
	else:
		draw_rect(r, Color(0.3, 0.22, 0.13))
	draw_rect(r, gold, false, 2.0)
	if open and not reward.is_empty():
		var off := Vector2(0, 26) if side == "n" else (Vector2(26, 0) if side == "w" else Vector2(-26, 0))
		var bob := sin(t * 3.0) * 2.0
		var c := reward_color()
		draw_circle(off + Vector2(0, bob), 7.0, Color(c, 0.3))
		draw_circle(off + Vector2(0, bob), 4.5, c)
		draw_string(ThemeDB.fallback_font, off + Vector2(-30, bob - 10), reward_label(), HORIZONTAL_ALIGNMENT_CENTER, 60, 9, Color(1, 0.95, 0.85))
