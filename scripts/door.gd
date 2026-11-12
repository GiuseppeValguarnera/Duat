extends Area2D
## Porta verso la stanza successiva. Mostra sopra di sé la ricompensa che c'è dietro.
## È una porta vera: chiusa (battenti di legno con le borchie) finché la stanza non è ripulita, poi
## i battenti si aprono e compare la ricompensa. Si entra solo con "interagisci" (game.gd): niente
## più ingressi per sbaglio camminando contro il muro.

signal chosen(door: Area2D)

var side := "n"                       # n | w | e | s (s: la porta di Set, nella parete sud)
var reward := {}                      # {"kind": "boon"/"set"/"ka"/"heal"/"end", "god": "..."}
var open := false
var open_k := 0.0                     ## 0 battenti chiusi, 1 aperti (l'animazione dell'apertura)
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
	if open:
		open_k = 1.0


func _process(delta: float) -> void:
	t += delta
	if open and open_k < 1.0:
		open_k = minf(1.0, open_k + delta / 0.45)
	# chiusa la porta è ferma: si ridisegna solo da aperta (la luce che pulsa, la ricompensa che ondeggia)
	if open:
		queue_redraw()


## I battenti si aprono (la stanza è ripulita): da qui si può entrare.
func open_door() -> void:
	if open:
		return
	open = true
	queue_redraw()
	Sfx.play_at("door", global_position, 0.05)


## Il giocatore ha scelto questa porta (con "interagisci").
func enter() -> void:
	if open and open_k >= 0.6 and not _used:
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
			return Lang.t("Apopi") if Run.region >= 3 else (Lang.t("Aker") if Run.region == 2 else Lang.t("Am-heh"))
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
	if reward.get("calm", false):
		return _base_description() + Lang.t(" · sala tranquilla, senza nemici")
	return _base_description()


func _base_description() -> String:
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
			return Lang.t("Acqua del Nilo: recuperi il %d%% della vita") % roundi(Run.nile_heal() * 100.0)
		"boss":
			if Run.region >= 3:
				return Lang.t("Il banco di sabbia: Apopi ha bevuto il fiume e la barca di Ra è arenata. Respingilo")
			if Run.region == 2:
				return Lang.t("La porta dell'orizzonte: Aker, il leone dalle due teste, custodisce il passaggio del sole")
			return Lang.t("Cancello della Prima Ora: Am-heh, il Divoratore di Milioni, ti aspetta nel suo lago di fuoco")
		"guardian":
			if Run.region >= 3:
				return Lang.t("Il torchio di Shezmu: il dio che spreme i dannati custodisce la via. Battilo per un dono di livello superiore")
			if Run.region == 2:
				return Lang.t("Il tempio di Serket: la dea scorpione custodisce il deserto. Battila per un dono di livello superiore")
			return Lang.t("La Porta di mezzo: il Serpente che la custodisce. Battilo per un dono di livello superiore")
		"region":
			if Run.region >= 2:
				return Lang.t("La porta della settima ora: oltre, il Banco di Apopi")
			return Lang.t("La porta della quarta ora: oltre, la terra di Sokar")
		"shop":
			if Run.room + 1 == Run.GUARDIAN_ROOM or Run.room + 2 == Run.GUARDIAN_ROOM or Run.room + 1 >= Run.ROOMS_PER_RUN:
				return Lang.t("Il Traghettatore, prima della prova: una sala tranquilla per spendere il Ka della discesa")
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
	# girata per le altre. Quasi tutto è fatto di rettangoli e di quadrilateri "primitivi", che la
	# scheda grafica disegna insieme in poche chiamate: cerchi e poligoni costano una chiamata
	# ciascuno, e una porta ne usava una quarantina (tre porte per stanza, sul telefono si sentiva).
	var gold := Color(0.94, 0.72, 0.3)
	var outl := Color(0.12, 0.08, 0.05)
	var stone := Color(0.72, 0.56, 0.36)
	var stone_d := Color(0.5, 0.37, 0.22)
	var rot := {"n": 0.0, "s": PI, "w": -PI / 2.0, "e": PI / 2.0}.get(side, 0.0) as float
	draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	var opening := Rect2(-18, -7, 36, 14)
	draw_rect(opening, Color(0.02, 0.02, 0.04))
	if open:
		var glow := reward_color()
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		var a := (0.55 + 0.25 * pulse) * open_k
		draw_primitive(PackedVector2Array([opening.position, Vector2(opening.end.x, opening.position.y), opening.end, Vector2(opening.position.x, opening.end.y)]),
			PackedColorArray([Color(glow, 0.0), Color(glow, 0.0), Color(glow, a), Color(glow, a)]), PackedVector2Array())
	# i due battenti di legno: chiusi si toccano al centro, aprendosi rientrano verso gli stipiti
	var leaf_w := 18.0 * (1.0 - open_k)
	if leaf_w > 0.3:
		var wood := Color(0.36, 0.24, 0.12) if not open else Color(0.36, 0.24, 0.12).lightened(0.08)
		for sx in [-1.0, 1.0]:
			var lr := Rect2(-18.0 if sx < 0.0 else 18.0 - leaf_w, -7, leaf_w, 14)
			draw_rect(lr, outl)
			draw_rect(lr.grow(-0.8), wood)
			draw_rect(Rect2(lr.position.x, -1, lr.size.x, 1.5), Color(gold, 0.7))
			if leaf_w > 6.0:
				for by in [-3.5, 3.0]:
					draw_rect(Rect2(lr.position.x + lr.size.x * 0.3 - 0.9, by - 0.9, 1.8, 1.8), gold)
					draw_rect(Rect2(lr.position.x + lr.size.x * 0.75 - 0.9, by - 0.9, 1.8, 1.8), gold)
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
	for k in range(13):
		draw_rect(Rect2(-26.2 + k * 4.0, -17, 0.4, 5), outl)
	draw_rect(Rect2(-26, -17, 52, 1.2), gold)
	# il disco solare alato
	for sx in [-1.0, 1.0]:
		draw_primitive(PackedVector2Array([Vector2(2.6 * sx, -11.2), Vector2(14 * sx, -11.6), Vector2(11 * sx, -9.4), Vector2(2.6 * sx, -8.8)]),
			PackedColorArray([gold, gold, gold, gold]), PackedVector2Array())
		draw_primitive(PackedVector2Array([Vector2(4 * sx, -10.7), Vector2(12 * sx, -10.9), Vector2(12 * sx, -10.3), Vector2(4 * sx, -10.1)]),
			PackedColorArray([Color(0.16, 0.3, 0.68), Color(0.16, 0.3, 0.68), Color(0.16, 0.3, 0.68), Color(0.16, 0.3, 0.68)]), PackedVector2Array())
	draw_circle(Vector2(0, -10), 2.6, outl)
	draw_circle(Vector2(0, -10), 2.0, Color(0.85, 0.25, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if open and open_k >= 1.0 and not reward.is_empty():
		var off := Vector2(0, 26) if side == "n" else (Vector2(0, -26) if side == "s" else (Vector2(26, 0) if side == "w" else Vector2(-26, 0)))
		var bob := sin(t * 3.0) * 2.0
		var c := reward_color()
		draw_circle(off + Vector2(0, bob), 7.0, Color(c, 0.3))
		draw_circle(off + Vector2(0, bob), 4.5, c)
		draw_string_outline(UiStyle.body_font(), off + Vector2(-50, bob - 10), reward_label(), HORIZONTAL_ALIGNMENT_CENTER, 100, 10, 3, Color(0.08, 0.05, 0.03, 0.9))
		draw_string(UiStyle.body_font(), off + Vector2(-50, bob - 10), reward_label(), HORIZONTAL_ALIGNMENT_CENTER, 100, 10, Color(1, 0.95, 0.85))
