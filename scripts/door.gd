extends Area2D
## Porta verso la stanza successiva. Mostra sopra di sé la ricompensa che c'è dietro.

signal chosen(door: Area2D)

var side := "n"                       # n | w | e | s (s: la porta di Set, nella parete sud)
var reward := {}                      # {"kind": "boon"/"set"/"ka"/"heal"/"end", "god": "..."}
var open := false
var t := 0.0
var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 12) if side in ["n", "s"] else Vector2(12, 44)
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
		"lapis":
			return Restorations.LAPIS_COLOR.lightened(0.15)
		"heal":
			return Color(0.95, 0.35, 0.3)
		"boss":
			return Color(0.9, 0.3, 0.25)
		"guardian":
			return Color(0.45, 0.9, 0.4)
		"region":
			return Color(0.95, 0.8, 0.45)
		"shop":
			return Color(0.6, 0.85, 0.95)
		"desert":
			return Color(0.95, 0.8, 0.45)
		_:
			return Color(0.9, 0.9, 1.0)


func reward_label() -> String:
	match reward.get("kind", ""):
		"boon":
			return Boons.god_name(reward["god"])
		"set":
			return Lang.t("Set")
		"ka":
			return Lang.t("Ka")
		"lapis":
			return Lang.t("Lapislazzuli")
		"heal":
			return Lang.t("Cura")
		"boss":
			return Lang.t("Am-heh")
		"guardian":
			return Lang.t("Guardiano")
		"region":
			return Lang.t("Sokar")
		"shop":
			return Lang.t("Traghettatore")
		"desert":
			return Lang.t("Il deserto")
		"tutorial_end":
			return Lang.t("La discesa")
		_:
			return Lang.t("Uscita")


## Testo mostrato quando il giocatore si avvicina.
func reward_description() -> String:
	match reward.get("kind", ""):
		"boon":
			return Lang.t("Dono di %s: scegli uno dei suoi poteri") % Boons.god_name(reward["god"])
		"set":
			return Lang.t("L'altare di Set: una deviazione, non perdi questa stanza né le altre porte. Entrare costa 8 vita. Una maledizione per 2 stanze, poi un potere per tutta la discesa")
		"ka":
			return Lang.t("Tesoro di Ka: +25 Ka")
		"lapis":
			return Lang.t("Lapislazzuli: pietre preziose per i restauri (restano anche se cadi)")
		"heal":
			if Run.room + 1 == Run.ROOMS_PER_RUN:
				return Lang.t("Acqua del Nilo: recuperi il %d%% della vita. Ultima stanza prima di Am-heh") % roundi(Run.nile_heal() * 100.0)
			return Lang.t("Acqua del Nilo: recuperi il %d%% della vita") % roundi(Run.nile_heal() * 100.0)
		"boss":
			return Lang.t("Cancello della Prima Ora: Am-heh, il Divoratore di Milioni, ti aspetta nel suo lago di fuoco")
		"guardian":
			return Lang.t("La Porta di mezzo: il Serpente che la custodisce. Battilo per un dono di livello superiore")
		"region":
			return Lang.t("La porta della quarta ora: oltre, la terra di Sokar")
		"shop":
			return Lang.t("Il Traghettatore: spendi il Ka della discesa (quello che spendi non torna a casa)")
		"desert":
			return Lang.t("Il deserto di Sokar: da qui la discesa ricomincia, più dura")
		"tutorial_end":
			return Lang.t("Comincia la discesa: Anubi ti aspetta con il primo dono")
		_:
			return Lang.t("Uscita: fine della discesa di prova")


func _draw() -> void:
	# una porta egizia: stipiti di pietra, architrave con la gola a foglie di palma e il disco
	# solare alato al centro; chiusa ha i battenti di legno con le borchie, aperta mostra il
	# buio con la luce della ricompensa che sale dal fondo. Disegnata per la parete nord e poi
	# girata per le altre.
	var gold := Color(0.94, 0.72, 0.3)
	var outl := Color(0.12, 0.08, 0.05)
	var stone := Color(0.72, 0.56, 0.36)
	var stone_d := Color(0.5, 0.37, 0.22)
	var rot := {"n": 0.0, "s": PI, "w": -PI / 2.0, "e": PI / 2.0}.get(side, 0.0) as float
	draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	var opening := Rect2(-18, -7, 36, 14)
	if open:
		var glow := reward_color()
		draw_rect(opening, Color(0.02, 0.02, 0.04))
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		draw_polygon(PackedVector2Array([opening.position, Vector2(opening.end.x, opening.position.y), opening.end, Vector2(opening.position.x, opening.end.y)]),
			PackedColorArray([Color(glow, 0.0), Color(glow, 0.0), Color(glow, 0.55 + 0.25 * pulse), Color(glow, 0.55 + 0.25 * pulse)]))
	else:
		draw_rect(opening, Color(0.36, 0.24, 0.12))
		draw_line(Vector2(0, -7), Vector2(0, 7), outl, 1.0)
		for bx in [-12.0, -5.0, 5.0, 12.0]:
			for by in [-3.5, 3.0]:
				draw_circle(Vector2(bx, by), 0.9, gold)
		draw_rect(Rect2(-18, -1, 36, 1.5), Color(gold, 0.7))
	# stipiti
	for sx in [-1.0, 1.0]:
		var j := Rect2(Vector2(18.0 if sx > 0.0 else -23.0, -8), Vector2(5, 16))
		draw_rect(j.grow(0.6), outl)
		draw_rect(j, stone)
		draw_rect(Rect2(j.position.x + (3.5 if sx > 0.0 else 0.0), j.position.y, 1.5, j.size.y), stone_d)
	# architrave e gola egizia con le foglie di palma colorate
	draw_rect(Rect2(-24.6, -12.6, 49.2, 5.2), outl)
	draw_rect(Rect2(-24, -12, 48, 4), stone)
	draw_rect(Rect2(-26.6, -17.6, 53.2, 5.6), outl)
	var leaf := [Color(0.16, 0.3, 0.68), Color(0.72, 0.26, 0.15), Color(0.26, 0.55, 0.32)]
	for k in range(13):
		var x := -26.0 + k * 4.0
		draw_rect(Rect2(x, -17, 4, 5), leaf[k % 3])
		draw_line(Vector2(x, -17), Vector2(x, -12), outl, 0.4)
	draw_rect(Rect2(-26, -17, 52, 1.2), gold)
	# il disco solare alato
	draw_circle(Vector2(0, -10), 2.6, outl)
	draw_circle(Vector2(0, -10), 2.0, Color(0.85, 0.25, 0.12))
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(2.6 * sx, -11.2), Vector2(14 * sx, -11.6), Vector2(11 * sx, -9.4), Vector2(2.6 * sx, -8.8)]), gold)
		draw_line(Vector2(4 * sx, -10.4), Vector2(12 * sx, -10.6), Color(0.16, 0.3, 0.68), 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if open and not reward.is_empty():
		var off := Vector2(0, 26) if side == "n" else (Vector2(0, -26) if side == "s" else (Vector2(26, 0) if side == "w" else Vector2(-26, 0)))
		var bob := sin(t * 3.0) * 2.0
		var c := reward_color()
		draw_circle(off + Vector2(0, bob), 7.0, Color(c, 0.3))
		draw_circle(off + Vector2(0, bob), 4.5, c)
		draw_string_outline(UiStyle.body_font(), off + Vector2(-50, bob - 10), reward_label(), HORIZONTAL_ALIGNMENT_CENTER, 100, 10, 3, Color(0.08, 0.05, 0.03, 0.9))
		draw_string(UiStyle.body_font(), off + Vector2(-50, bob - 10), reward_label(), HORIZONTAL_ALIGNMENT_CENTER, 100, 10, Color(1, 0.95, 0.85))
