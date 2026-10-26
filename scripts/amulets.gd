class_name Amulets
extends RefCounted
## Gli amuleti della Casa della Vita. Se ne porta uno solo, scelto prima di scendere.
##
## La regola che li tiene in equilibrio con il resto del gioco: il Libro dei Morti dà numeri
## (vita, danni, Ka, ricariche) e i doni degli dèi danno i loro poteri; gli amuleti danno un
## potere che non c'è né nell'uno né negli altri. Così non si sommano mai sulla stessa cosa.
## Si ottengono con le sfide della parete di Thoth (challenges.gd) e si forgiano con i
## lapislazzuli; crescono con l'uso: livello 2 dopo 20 stanze portate al collo, 3 dopo 50.

const LEVEL_ROOMS := [0, 20, 50]
const COLOR := Color(0.94, 0.72, 0.3)

## L'ordine è quello del banco dell'orafo. `values` per livello, `cost` in lapislazzuli.
const ALL_IT := {
	"iside": {"name": "Nodo di Iside", "cost": 0, "values": [50, 75, 100],
		"desc": "Le trappole (spuntoni, grate di fuoco, olio in fiamme, statue dell'ureo) ti fanno il %d%% di danni in meno.",
		"lore": "Il tyet, il nodo della veste di Iside, era fatto di diaspro rosso: si legava al collo della mummia perché «il sangue di Iside» la proteggesse."},
	"ankh": {"name": "Ankh", "cost": 6, "values": [2, 3, 4],
		"desc": "Ogni volta che entri in una stanza nuova recuperi %d punti vita.",
		"lore": "Il segno della vita. Gli dèi lo tengono per l'ansa e lo avvicinano al naso del re: gli danno il respiro dell'eternità."},
	"djed": {"name": "Pilastro Djed", "cost": 8, "values": [1.5, 2.0, 2.5],
		"desc": "Lo scatto lascia dietro di te una statua di pietra che attira i nemici per %s secondi.",
		"lore": "La spina dorsale di Osiride, il segno della stabilità. Nella festa di Sokar il re in persona rialzava un grande pilastro djed con le corde."},
	"was": {"name": "Scettro Was", "cost": 8, "values": [2, 3, 4],
		"desc": "Ogni stanza finita senza perdere vita ti dà +%d%% di danni fino alla fine della discesa (al massimo 5 volte).",
		"lore": "Lo scettro con la testa di animale e la base a forcella: il potere e il dominio. Lo reggono gli dèi in quasi ogni pittura."},
	"shen": {"name": "Anello Shen", "cost": 8, "values": [2, 3, 4],
		"desc": "Gli dèi da cui hai già un dono compaiono alle porte %d volte più spesso.",
		"lore": "Un giro di corda legato senza fine: l'eternità. Allungato, diventò il cartiglio che chiude il nome del re."},
	"hathor": {"name": "Collana di Hathor", "cost": 6, "values": [0, 15, 30],
		"desc": "Il Traghettatore ha un'offerta agli dèi in più, scontata del %d%%.",
		"desc0": "Il Traghettatore ha un'offerta agli dèi in più.",
		"lore": "Il menat, la collana pesante delle sacerdotesse di Hathor: la scuotevano come un sonaglio per calmare la dea e portare gioia."},
	"udjat": {"name": "Occhio Udjat", "cost": 6, "values": [0, 50, 100],
		"desc": "La crepa delle stanze segrete brilla da lontano, e le stanze segrete compaiono il %d%% più spesso.",
		"desc0": "La crepa delle stanze segrete brilla da lontano.",
		"lore": "L'occhio di Horus strappato da Set e guarito da Thoth. Era l'amuleto più comune di tutti: «udjat» vuol dire «integro, sano»."},
	"kheper": {"name": "Scarabeo Kheper", "cost": 10, "values": [1, 2, 3],
		"desc": "I primi %d doni della discesa arrivano già al livello 2.",
		"desc1": "Il primo dono della discesa arriva già al livello 2.",
		"lore": "Lo scarabeo che spinge il sole fuori dalla notte: il dio del divenire, di ciò che rinasce. Kheper, come te."},
}
static var ALL := {}


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)


static func data() -> Dictionary:
	if ALL.is_empty():
		refresh_lang()
	return ALL


static func owned(id: String) -> bool:
	return Meta.amulets.has(id)


## Si può forgiare: la sfida che lo dà è stata riscossa e non è ancora tuo.
static func unlocked(id: String) -> bool:
	return Meta.amulet_recipes.has(id)


static func can_forge(id: String) -> bool:
	return unlocked(id) and not owned(id) and Meta.lapis >= int(data()[id]["cost"])


static func forge(id: String) -> bool:
	if not can_forge(id):
		return false
	Meta.lapis -= int(data()[id]["cost"])
	Meta.amulets.append(id)
	if Meta.amulet == "":
		Meta.amulet = id
	Meta.save()
	return true


static func equip(id: String) -> void:
	Meta.amulet = id if owned(id) else ""
	Meta.save()


static func rooms(id: String) -> int:
	return int(Meta.amulet_rooms.get(id, 0))


static func level(id: String) -> int:
	var r := rooms(id)
	var l := 1
	for i in range(LEVEL_ROOMS.size()):
		if r >= LEVEL_ROOMS[i]:
			l = i + 1
	return l


static func value(id: String, lvl: int = -1) -> float:
	if lvl < 0:
		lvl = level(id)
	return float(data()[id]["values"][clampi(lvl, 1, 3) - 1])


## La descrizione al livello dato (lo scettro e il djed hanno decimali o numeri interi).
static func text(id: String, lvl: int = -1) -> String:
	var v := value(id, lvl)
	var d: Dictionary = data()[id]
	if v == 0.0 and d.has("desc0"):
		return d["desc0"]
	if v == 1.0 and d.has("desc1"):
		return d["desc1"]
	return String(d["desc"]).replace("%d%%", short(id, lvl)).replace("%d", short(id, lvl)).replace("%s", short(id, lvl))


## Solo il numero del potere, con l'unità: "+3%", "2,5", "4".
static func short(id: String, lvl: int = -1) -> String:
	var v := value(id, lvl)
	var s := ("%s" % v).replace(".", ",") if id == "djed" else str(int(v))
	return s + "%" if String(ALL_IT[id]["desc"]).contains("%d%%") else s


## Qualcosa da fare al banco dell'orafo? (il punto esclamativo)
static func something_to_forge() -> bool:
	for id in ALL_IT:
		if can_forge(id):
			return true
	return false


## L'amuleto della discesa in corso ("" se nessuno) e il suo valore.
static func active() -> String:
	return Run.amulet


static func val() -> float:
	return value(Run.amulet, Run.amulet_level) if Run.amulet != "" else 0.0


## Anello Shen: sceglie `n` dèi diversi, dando più peso a quelli da cui hai già un dono.
static func pick_gods(gods: Array, n: int) -> Array:
	var pool := gods.duplicate()
	if Run.amulet != "shen":
		pool.shuffle()
		return pool.slice(0, n)
	var mine := {}
	for b in Run.boons:
		mine[String(Boons.ALL[b].get("god", ""))] = true
	var out := []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for g in pool:
			total += val() if mine.has(g) else 1.0
		var r := randf() * total
		for g in pool:
			r -= val() if mine.has(g) else 1.0
			if r <= 0.0:
				out.append(g)
				pool.erase(g)
				break
	return out


## L'amuleto disegnato: un piccolo gioiello per ogni forma, in oro, lapislazzuli e corniola.
static func draw_icon(ci: CanvasItem, id: String, c: Vector2, s: float, dim := false) -> void:
	var gold := COLOR if not dim else Color(0.45, 0.4, 0.34)
	var lapis := Color(0.2, 0.36, 0.8) if not dim else Color(0.32, 0.32, 0.36)
	var red := Color(0.78, 0.24, 0.16) if not dim else Color(0.4, 0.34, 0.32)
	var turq := Color(0.2, 0.66, 0.64) if not dim else Color(0.34, 0.38, 0.38)
	var outl := Color(0.1, 0.07, 0.05)
	match id:
		"iside":
			ci.draw_circle(c + Vector2(0, -5) * s, 4.0 * s, outl)
			ci.draw_circle(c + Vector2(0, -5) * s, 3.0 * s, red)
			ci.draw_circle(c + Vector2(0, -5) * s, 1.2 * s, outl)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -2) * s, c + Vector2(2, -2) * s, c + Vector2(3, 7) * s, c + Vector2(-3, 7) * s]), red)
			ci.draw_line(c + Vector2(-6, -1) * s, c + Vector2(6, -1) * s, red, 2.0 * s)
		"ankh":
			ci.draw_arc(c + Vector2(0, -5) * s, 3.2 * s, 0, TAU, 14, gold, 1.8 * s)
			ci.draw_line(c + Vector2(0, -2) * s, c + Vector2(0, 8) * s, gold, 2.0 * s)
			ci.draw_line(c + Vector2(-5, -1) * s, c + Vector2(5, -1) * s, gold, 2.0 * s)
		"djed":
			ci.draw_rect(Rect2(c + Vector2(-2, -4) * s, Vector2(4, 12) * s), gold)
			for k in range(4):
				ci.draw_rect(Rect2(c + Vector2(-5, -7 + k * 2.2) * s, Vector2(10, 1.3) * s), lapis if k % 2 == 0 else gold)
		"was":
			ci.draw_line(c + Vector2(0, -5) * s, c + Vector2(0, 8) * s, turq, 1.6 * s)
			ci.draw_line(c + Vector2(0, -5) * s, c + Vector2(3, -8) * s, turq, 1.6 * s)
			ci.draw_line(c + Vector2(3, -8) * s, c + Vector2(5, -7) * s, turq, 1.4 * s)
			ci.draw_line(c + Vector2(0, 8) * s, c + Vector2(-2, 10) * s, turq, 1.2 * s)
			ci.draw_line(c + Vector2(0, 8) * s, c + Vector2(2, 10) * s, turq, 1.2 * s)
		"shen":
			ci.draw_arc(c + Vector2(0, -2) * s, 5.0 * s, 0, TAU, 18, gold, 2.0 * s)
			ci.draw_rect(Rect2(c + Vector2(-6, 3) * s, Vector2(12, 2.2) * s), gold)
			ci.draw_circle(c + Vector2(0, -2) * s, 2.0 * s, lapis)
		"hathor":
			ci.draw_arc(c + Vector2(0, -3) * s, 5.0 * s, PI * 0.1, PI * 0.9, 10, lapis, 2.0 * s)
			ci.draw_line(c + Vector2(0, 2) * s, c + Vector2(0, 6) * s, gold, 1.6 * s)
			ci.draw_circle(c + Vector2(0, 8) * s, 2.6 * s, turq)
		"udjat":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -2) * s, c + Vector2(0, -6) * s, c + Vector2(7, -2) * s, c + Vector2(0, 2) * s]), Color(0.95, 0.92, 0.84) if not dim else Color(0.5, 0.5, 0.48))
			ci.draw_circle(c + Vector2(0, -2) * s, 2.0 * s, lapis)
			ci.draw_line(c + Vector2(-7, -6) * s, c + Vector2(7, -7) * s, outl, 1.2 * s)
			ci.draw_line(c + Vector2(-1, 2) * s, c + Vector2(-2, 8) * s, outl, 1.2 * s)
			ci.draw_arc(c + Vector2(3, 6) * s, 2.5 * s, PI, TAU, 8, outl, 1.2 * s)
		"kheper":
			ci.draw_circle(c + Vector2(0, -7) * s, 3.0 * s, red)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -3) * s, c + Vector2(4, -3) * s, c + Vector2(4, 5) * s, c + Vector2(0, 8) * s, c + Vector2(-4, 5) * s]), turq)
			ci.draw_line(c + Vector2(0, -3) * s, c + Vector2(0, 8) * s, outl, 0.8 * s)
			for sx in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(sx * 4, -1) * s, c + Vector2(sx * 9, -4) * s, lapis, 2.0 * s)


## Pilastro Djed: la statua di pietra che lo scatto lascia dietro di sé. I nemici vicini
## (non i guardiani e i boss) la inseguono finché non si sbriciola.
class Decoy extends Node2D:
	var life := 2.0
	var t := 0.0

	func _ready() -> void:
		Run.decoy_pos = global_position
		Run.decoy_t = life
		Fx.burst(global_position + Vector2(0, -8), Color(0.75, 0.68, 0.55), 10, 60.0)

	func _exit_tree() -> void:
		Run.decoy_t = 0.0                    # cambiando stanza la statua sparisce: nessuno la insegue più

	func _process(delta: float) -> void:
		t += delta
		Run.decoy_t = maxf(0.0, life - t)
		if t >= life:
			Fx.burst(global_position + Vector2(0, -8), Color(0.7, 0.62, 0.5), 14, 80.0)
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf((life - t) / 0.4, 0.0, 1.0)
		var stone := Color(0.78, 0.7, 0.56, a)
		var outl := Color(0.12, 0.08, 0.05, a)
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.3 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(-5.6, -22.6, 11.2, 23.2), outl)
		draw_rect(Rect2(-5, -22, 10, 22), stone)
		for k in range(4):
			draw_rect(Rect2(-8, -24 + k * 3.0, 16, 1.8), Color(0.2, 0.36, 0.8, a) if k % 2 == 0 else Color(0.94, 0.72, 0.3, a))
		var pulse := 0.5 + 0.5 * sin(t * 8.0)
		draw_arc(Vector2(0, -12), 16.0 + pulse * 3.0, 0, TAU, 24, Color(0.94, 0.72, 0.3, 0.4 * a), 1.0)
