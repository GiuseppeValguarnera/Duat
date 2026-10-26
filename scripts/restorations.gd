class_name Restorations
extends RefCounted
## I restauri della Sala del Giudizio, pagati in lapislazzuli. La Sala si rimette in piedi un
## pezzo alla volta: quasi tutti cambiano solo l'aspetto (bracieri, stendardi, pitture, la vasca,
## il trono di Anubi), tre sono piccole comodità. Nessuno dà potenza: quella è del Libro dei Morti,
## e i due sistemi non si fanno concorrenza.
##
## I lapislazzuli sono rari e restano anche se muori (come le gemme di Hades): li lasciano il
## Serpente della Porta (4-5), Am-heh (10-12), a volte le stanze segrete (2-3) e, ogni tanto,
## una porta apposta (4-5). Una discesa media ne porta a casa 5-10, una vittoria 20-25.

const LAPIS_COLOR := Color(0.25, 0.42, 0.95)

## id -> nome, costo, descrizione, racconto. L'ordine è quello del pannello.
const ALL_IT := {
	"bracieri": {"name": "I bracieri della Sala", "cost": 6,
		"desc": "I bracieri spenti negli angoli della Sala tornano ad ardere: più luce calda nella notte blu.",
		"lore": "Nei templi il fuoco non si spegneva mai: i sacerdoti lo nutrivano all'alba e al tramonto, con incenso e grasso di bue."},
	"stendardi": {"name": "Gli stendardi degli dèi", "cost": 9,
		"desc": "Gli stendardi strappati sopra la Sala tornano interi, con le frange d'oro e il simbolo di ogni dio.",
		"lore": "Davanti ai piloni dei templi si alzavano pali di cedro con lunghe bandiere colorate: il geroglifico per «dio» è proprio uno stendardo al vento."},
	"pitture": {"name": "Le pitture del giudizio", "cost": 12,
		"desc": "Sulla parete in alto torna la scena della pesatura del cuore: Anubi alla bilancia, Thoth che scrive, Ammit che aspetta.",
		"lore": "Il papiro di Ani mostra la scena più famosa del Libro dei Morti: il cuore su un piatto, la piuma di Ma'at sull'altro."},
	"vasca": {"name": "La vasca del Nilo", "cost": 15,
		"desc": "Una vasca d'acqua viva con i fiori di loto, accanto alla cassa dello scalpellino.",
		"lore": "Ogni tempio aveva il suo lago sacro: i sacerdoti vi si purificavano prima dei riti, e ogni mattina il sole sorgeva dalle sue acque."},
	"trono": {"name": "Il trono di Anubi", "cost": 18,
		"desc": "Alle spalle di Anubi torna il suo trono dorato, con lo schienale dipinto e le zampe di leone.",
		"lore": "Il trono era il segno del potere: il nome di Iside si scrive proprio con il geroglifico di un seggio."},
	"clessidra": {"name": "La clessidra di Thoth", "cost": 8, "comfort": true,
		"desc": "Comodità. Durante la discesa vedi in alto il tempo trascorso e il tuo record contro Am-heh.",
		"lore": "Gli Egizi misuravano le ore della notte con le clessidre ad acqua: un vaso forato, con le tacche dipinte all'interno."},
	"registro": {"name": "Il registro dello scriba", "cost": 12, "comfort": true,
		"desc": "Comodità. Nei Papiri di Thoth compare una pagina con le tue imprese: discese, vittorie, chi ti ha fermato più spesso, gli dèi che hai scelto.",
		"lore": "Gli scribi tenevano registri di tutto: il grano, il bestiame, i lavoratori. Anche le imprese dei re finivano su un papiro."},
	"gatto": {"name": "Il gatto di Bastet", "cost": 15, "comfort": true,
		"desc": "Comodità. Un gatto vive nella Sala: ti segue, si lascia accarezzare e ogni tanto ti porta un po' di Ka davanti al cancello.",
		"lore": "I gatti erano sacri a Bastet. Chi ne uccideva uno, anche per sbaglio, rischiava la vita; quando un gatto moriva, la famiglia si radeva le sopracciglia in segno di lutto."},
}
static var ALL := {}


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)


static func data() -> Dictionary:
	if ALL.is_empty():
		refresh_lang()
	return ALL


static func has(id: String) -> bool:
	return Meta.restorations.has(id)


static func can_buy(id: String) -> bool:
	return not has(id) and Meta.lapis >= int(data()[id]["cost"])


## C'è un restauro che puoi già pagare? (il punto esclamativo sulla cassa dello scalpellino)
static func something_affordable() -> bool:
	for id in ALL_IT:
		if can_buy(id):
			return true
	return false


static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	Meta.lapis -= int(data()[id]["cost"])
	Meta.restorations.append(id)
	Meta.save()
	return true


## Lapislazzuli trovati: restano subito, anche se poi muori.
static func gain(n: int, at: Vector2) -> void:
	if n <= 0:
		return
	Meta.lapis += n
	Meta.save()
	Sfx.play("pickup", 0.05)
	Fx.float_text(at + Vector2(0, -20), Lang.t("+%d Lapislazzuli") % n, LAPIS_COLOR.lightened(0.35), 12)
	Fx.burst(at + Vector2(0, -10), LAPIS_COLOR, 18, 100.0)


## Il lapislazzuli disegnato: una pietra blu sfaccettata con le venature d'oro (pirite).
static func draw_gem(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -6) * s, c + Vector2(5, -2) * s, c + Vector2(4, 4) * s, c + Vector2(-2, 6) * s, c + Vector2(-5, 1) * s])
	ci.draw_colored_polygon(pts, LAPIS_COLOR)
	var cl := pts.duplicate()
	cl.append(pts[0])
	ci.draw_polyline(cl, Color(0.08, 0.06, 0.12), 0.8)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6) * s, c + Vector2(5, -2) * s, c + Vector2(0, 0) * s]), LAPIS_COLOR.lightened(0.3))
	ci.draw_circle(c + Vector2(-1.5, 2) * s, 0.7 * s, Color(1.0, 0.85, 0.4))
	ci.draw_circle(c + Vector2(2, 1) * s, 0.5 * s, Color(1.0, 0.85, 0.4))
