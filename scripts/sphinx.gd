class_name Sphinx
extends RefCounted
## La Sfinge: «La scala dell'enigma» (blocco 15). Una prova a ondate fuori dalla discesa, con
## equipaggiamento fisso: vita standard, niente doni, capitoli, amuleti o Pesi della meta-progressione.
## L'arma del giorno e le ondate vengono da un seme giornaliero uguale per tutti (data UTC del
## dispositivo). Qui ci sono i dati e le regole; la partita la guida scripts/sphinx_trial.gd dentro
## game.gd (Run.trial). I punteggi restano nel salvataggio (Meta.sphinx), pronti per una classifica
## online futura: ogni voce ha giorno, seme, arma e versione delle regole.

const COST := 28                       ## lapislazzuli per aprire la porta (poco sopra la grazia più economica, 15)
const RULES := 1                       ## versione delle regole: i punteggi di regole diverse non si confrontano
const WEAPONS := ["khopesh", "lancia", "arco", "flagello"]
const TOP_N := 10
## Premi settimanali: soglia di ondata -> [Ka, lapislazzuli]. Una volta a settimana per soglia; la
## settimana ricomincia il lunedì alle 00:00 UTC. Una discesa normale porta a casa 60-150 Ka e
## 5-20 lapislazzuli: tutte le soglie insieme valgono circa una buona discesa.
const WEEKLY := {5: [15, 1], 10: [25, 2], 15: [35, 3], 20: [50, 4]}
const MONDAY := 345600                 ## lunedì 5 gennaio 1970, 00:00 UTC (il primo lunedì dopo l'epoca)
const WEEK := 604800
## Punteggio: ondate superate, risposte dure, ondate senza colpi; il tempo conta poco.
const PTS_WAVE := 10
const PTS_HARD := 4                    ## per ogni ondata superata con un effetto audace attivo (al massimo 3 a pausa: 12)
const PTS_CLEAN := 3
const PTS_QUICK := 1
const QUICK_SECS := 25.0
const BOON_EVERY := 3                  ## pausa della Sfinge dopo ogni 3 ondate: enigma + tre doni (livello base)
const EFFECT_WAVES := 3               ## l'effetto dell'enigma dura fino alla pausa successiva
const HEAL_EVERY := 5                  ## ogni 5 ondate, una piccola cura
const HEAL := 0.15
const GUARD_EVERY := 5                 ## ogni 5 ondate un'ondata «guardiano»
const STRONG_FROM := 11                ## i nemici di Sokar entrano dopo la decima ondata
const PEAK := 25                       ## fin qui sale tutto; dopo solo il numero e la velocità
const TRIAL_PILLARS := [Vector2(0.22, 0.5), Vector2(0.78, 0.5)]


# --- giorno, settimana, seme ------------------------------------------------------------

static func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Il giorno (UTC) contato dall'epoca. DUAT_SPHINX_DAY per le prove.
static func day() -> int:
	var env := OS.get_environment("DUAT_SPHINX_DAY")
	if env != "":
		return int(env)
	return floori(now_unix() / 86400.0)


static func day_seed(d: int) -> int:
	return hash("sfinge-%d" % d) & 0x7fffffff


static func date_text(d: int) -> String:
	return Time.get_date_string_from_unix_time(d * 86400)


static func weapon_of_day(d: int = -1) -> String:
	if Weapons.ALL.has(OS.get_environment("DUAT_WEAPON")):
		return OS.get_environment("DUAT_WEAPON")
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed(day() if d < 0 else d)
	return WEAPONS[rng.randi() % WEAPONS.size()]


static func weapon_name(w: String) -> String:
	return String(Weapons.ALL[w]["name"]) if Weapons.ALL.has(w) else w


static func week() -> int:
	return floori((now_unix() - MONDAY) / float(WEEK))


## Quanto manca al prossimo ripristino dei premi settimanali, in parole.
static func reset_text() -> String:
	var left := MONDAY + (week() + 1) * WEEK - now_unix()
	var days := floori(left / 86400.0)
	var hours := floori((left % 86400) / 3600.0)
	if days > 0:
		return Lang.t("%d giorni e %d ore") % [days, hours]
	return Lang.t("%d ore") % maxi(1, hours)


# --- salvataggio (Meta.sphinx) ---------------------------------------------------------

static func is_open() -> bool:
	return bool(Meta.sphinx.get("open", false))


static func open() -> void:
	Meta.sphinx["open"] = true
	Meta.save()


static func scores() -> Array:
	return Meta.sphinx.get("scores", [])


## Protezione della data (blocco 16): l'ultima data/ora vista dal gioco. Se l'orologio del
## dispositivo torna indietro rispetto a questa, i premi della Sfinge non si assegnano (la classifica
## resta com'è). CLOCK_SLACK tollera le piccole correzioni automatiche dell'orologio.
const CLOCK_SLACK := 600


static func touch_clock() -> void:
	var now := now_unix()
	if now > int(Meta.sphinx.get("last_seen", 0)):
		Meta.sphinx["last_seen"] = now
		Meta.save()


static func clock_ok() -> bool:
	return now_unix() + CLOCK_SLACK >= int(Meta.sphinx.get("last_seen", 0))


## Le soglie già riscosse questa settimana. Si azzerano solo quando la settimana va AVANTI: con
## l'orologio portato indietro restano quelle di prima (e comunque claim() non paga).
static func claimed() -> Array:
	if week() > int(Meta.sphinx.get("week", -1)):
		Meta.sphinx["week"] = week()
		Meta.sphinx["claimed"] = []
	return Meta.sphinx.get("claimed", [])


## Raggiunta una soglia: il premio, se non è già stato preso questa settimana. [Ka, lapis] o [].
static func claim(threshold: int) -> Array:
	if not WEEKLY.has(threshold) or not clock_ok():
		return []
	touch_clock()
	var c := claimed()
	if c.has(threshold):
		return []
	c.append(threshold)
	Meta.sphinx["claimed"] = c
	var r: Array = WEEKLY[threshold]
	Meta.ka_bank += int(r[0])
	Meta.lapis += int(r[1])
	Meta.save()
	return r


## Registra un punteggio: restituisce la posizione in classifica (1 = il migliore) o 0 se fuori.
static func record(entry: Dictionary) -> int:
	var list: Array = scores().duplicate()
	list.append(entry)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) != int(b["score"]):
			return int(a["score"]) > int(b["score"])
		return int(a["wave"]) > int(b["wave"]))
	var pos := list.find(entry) + 1
	list.resize(mini(list.size(), TOP_N))
	Meta.sphinx["scores"] = list
	Meta.sphinx["plays"] = int(Meta.sphinx.get("plays", 0)) + 1
	Meta.sphinx["best_wave"] = maxi(int(Meta.sphinx.get("best_wave", 0)), int(entry["wave"]))
	Meta.save()
	return pos if pos <= TOP_N else 0


static func new_entry(score: int, wave: int, weapon: String, hard: int, clean: int, mods: Array = [], raw: int = -1) -> Dictionary:
	return {"score": score, "wave": wave, "weapon": weapon, "day": day(), "date": date_text(day()),
		"seed": day_seed(day()), "hard": hard, "clean": clean, "rules": RULES, "mods": mods,
		"mult": SphinxShop.mult(mods), "raw": score if raw < 0 else raw, "title": SphinxShop.title_text()}


static func seals() -> int:
	return SphinxShop.seals()


## Favore della Sfinge (blocco 17): nelle discese, a volte, un dono della Sfinge tra le scelte.
const FAVOR_CHANCE := 0.125


static func favor_roll(owned: Dictionary) -> bool:
	if Run.trial or not Favors.has("favore_sfinge"):
		return false
	for id in owned:
		if Boons.is_sphinx(id):
			return false                      # al massimo un dono della Sfinge per discesa
	return randf() < FAVOR_CHANCE


static func best_score() -> int:
	var b := 0
	for e in scores():
		b = maxi(b, int(e["score"]))
	return b


# --- difficoltà --------------------------------------------------------------------------

## Vita dei nemici: come le stanze di Wernes fino alla decima ondata, poi sale ancora fino alla 25.
static func hp_mult(w: int) -> float:
	var x := mini(w, PEAK)
	return 1.0 + 0.06 * (x - 1)


## Danni subiti: dopo la decima ondata salgono fino a quelli di Sokar (×1,25 alla 25).
static func dmg_mult(w: int) -> float:
	if w <= 10:
		return 1.0
	return 1.0 + 0.25 * (mini(w, PEAK) - 10) / float(PEAK - 10)


## Dopo la 25 cresce solo la velocità (2% a ondata, fino al 30%) e il numero.
static func speed_mult(w: int) -> float:
	return minf(1.3, 1.0 + 0.02 * maxi(0, w - PEAK))


static func budget(w: int) -> int:
	return roundi(4.0 + 0.9 * mini(w, PEAK)) + maxi(0, w - PEAK)


static func is_guard_wave(w: int) -> bool:
	return w % GUARD_EVERY == 0


## [tipo, costo, unità, a distanza?, massimo per ondata, dall'ondata]
const BASE_KINDS := [
	["mummy", 2, ["mummy"], false, 99, 1],
	["scarab", 2, ["scarab", "scarab", "scarab"], false, 99, 1],
	["scorpion", 3, ["scorpion", "scorpion"], false, 3, 3],
	["priest", 3, ["priest"], true, 2, 4],
	["cobra", 3, ["cobra"], false, 2, 6],
	["damned_ba", 2, ["damned_ba", "damned_ba"], false, 2, 8],
]
const STRONG_KINDS := [
	["jackal", 4, ["jackal", "jackal", "jackal"], false, 1, STRONG_FROM],
	["sokar_guard", 3, ["sokar_guard"], false, 2, STRONG_FROM],
	["vulture", 2, ["vulture"], false, 2, STRONG_FROM],
	["javelin", 2, ["javelin"], true, 2, STRONG_FROM],
	["sokar_priest", 3, ["sokar_priest"], true, 1, 13],
	["khepri", 3, ["khepri"], true, 1, 14],
	["mirage", 3, ["mirage"], true, 1, 16],
]
const ELITE_OK := ["mummy", "priest", "sokar_guard", "vulture", "jackal", "javelin"]

## I guardiani: un nemico forte, mai un boss intero. Vita tarata sui pochi doni della prova.
const GUARDS := [
	{"kind": "sokar_guard@g", "name": "Il Guardiano della Sabbia", "hp": 2.0},
	{"kind": "aker_lion@ieri", "name": "L'Ombra di Ieri", "hp": 220.0},
	# blocco 16: al posto di Serket (le sue regole di terreno vogliono la sabbia e il piano di pietra del
	# suo tempio) un guardiano senza regole di terreno: il grande scarabeo di Khepri, élite
	{"kind": "khepri@g", "name": "Il grande scarabeo di Khepri", "hp": 3.0},
	{"kind": "aker_lion@domani", "name": "L'Ombra di Domani", "hp": 380.0},
]


static func guard_info(w: int) -> Dictionary:
	var i := (floori(w / float(GUARD_EVERY)) - 1) % GUARDS.size()
	var cycle := floori((floori(w / float(GUARD_EVERY)) - 1) / float(GUARDS.size()))
	var g: Dictionary = GUARDS[i].duplicate()
	g["cycle"] = cycle
	g["name"] = Lang.t(g["name"])
	return g


static func guard_names() -> Array:
	return [Lang.t("Il Guardiano della Sabbia"), Lang.t("L'Ombra di Ieri"), Lang.t("Il grande scarabeo di Khepri"), Lang.t("L'Ombra di Domani")]


## L'ondata `w` del giorno: uguale per tutti (seme del giorno + numero dell'ondata). `extra` sono i
## nemici in più o in meno decisi dalla Sfinge, `elites` le élite in più. Le élite hanno "@e".
static func wave_list(w: int, extra: int = 0, elites: int = 0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed(day()) ^ (w * 7919)
	var b := maxi(3, budget(w) + extra)
	var out := []
	if is_guard_wave(w):
		out.append(guard_info(w)["kind"])
		b = maxi(2, roundi(b / 3.0))          # una piccola scorta di nemici base
	var pool := []
	for k in BASE_KINDS:
		if w >= int(k[5]):
			pool.append(k)
	var strong := []
	for k in STRONG_KINDS:
		if w >= int(k[5]) and not is_guard_wave(w):
			strong.append(k)
	var cnt := {}
	var melee := 0
	var ranged := 0
	var tries := 0
	while b > 0 and tries < 80:
		tries += 1
		var from: Array = strong if not strong.is_empty() and rng.randf() < 0.5 else pool
		var k: Array = from[rng.randi() % from.size()]
		if int(cnt.get(k[0], 0)) >= int(k[4]) or int(k[1]) > b + 1:
			continue
		var units: Array = k[2]
		if bool(k[3]) and ranged + units.size() > melee:
			continue                           # prima un po' di corpo a corpo
		cnt[k[0]] = int(cnt.get(k[0], 0)) + 1
		b -= int(k[1])
		for u in units:
			out.append(u)
		if bool(k[3]):
			ranged += units.size()
		else:
			melee += units.size()
	# élite: dalla 11ª ondata, sempre più spesse; più quelle chieste dalla Sfinge
	var chance := 0.0 if w < STRONG_FROM else minf(0.3, 0.06 + 0.015 * (w - STRONG_FROM))
	var want := elites
	for i in range(out.size()):
		var kind: String = out[i]
		if kind.contains("@") or not ELITE_OK.has(kind):
			continue
		if want > 0 or rng.randf() < chance:
			out[i] = kind + "@e"
			want = maxi(0, want - 1)
	return out


# --- enigmi -------------------------------------------------------------------------------

const HARD_EFFECTS := ["tough", "fast", "noheal", "fragile", "horde", "elite", "sting"]


static func is_hard(effect: String) -> bool:
	return HARD_EFFECTS.has(effect)


## Cosa fa una risposta, detto chiaro prima di sceglierla.
static func effect_text(effect: String) -> String:
	match effect:
		"short":
			return Lang.t("Per le prossime 3 ondate: 2 nemici in meno in ognuna.")
		"gift":
			return Lang.t("Un dono in più, subito: tre a scelta, livello base.")
		"heal":
			return Lang.t("Ti curi subito del 15% della vita massima.")
		"slow":
			return Lang.t("Per le prossime 3 ondate: nemici più lenti del 15%.")
		"shield":
			return Lang.t("Per le prossime 3 ondate: cominci ognuna con uno scudo da 12.")
		"tough":
			return Lang.t("Per le prossime 3 ondate: nemici con il 30% di vita in più.")
		"fast":
			return Lang.t("Per le prossime 3 ondate: nemici più veloci del 15%.")
		"noheal":
			return Lang.t("Per le prossime 3 ondate: niente cure, nemmeno quella che arriva ogni 5 ondate.")
		"fragile":
			return Lang.t("Per le prossime 3 ondate: dopo un colpo resti invulnerabile la metà del tempo.")
		"horde":
			return Lang.t("Per le prossime 3 ondate: 3 nemici in più in ognuna.")
		"elite":
			return Lang.t("Per le prossime 3 ondate: due nemici in più sono élite.")
		"sting":
			return Lang.t("Per le prossime 3 ondate: i nemici fanno il 20% di danni in più.")
	return ""


## Il nome corto dell'effetto per l'HUD (in modo discreto, accanto all'ondata).
static func effect_short(effect: String) -> String:
	match effect:
		"short":
			return Lang.t("ondate più corte")
		"slow":
			return Lang.t("nemici lenti")
		"shield":
			return Lang.t("scudo a ogni ondata")
		"tough":
			return Lang.t("nemici più resistenti")
		"fast":
			return Lang.t("nemici veloci")
		"noheal":
			return Lang.t("niente cure")
		"fragile":
			return Lang.t("invulnerabilità dimezzata")
		"horde":
			return Lang.t("più nemici")
		"elite":
			return Lang.t("più élite")
		"sting":
			return Lang.t("nemici più forti")
	return ""


## Gli indovinelli della Sfinge, a tema egizio. Le due risposte sono tutte e due «giuste»: la
## prudente e l'audace cambiano solo la prova (nessuno deve conoscere la soluzione).
static func riddles() -> Array:
	var base := [
		{"q": Lang.t("Ogni mattina nasco dal grembo di Nut, ogni sera lei mi inghiotte. Chi sono?"),
			"soft": Lang.t("Ra, il sole che rinasce."), "hard": Lang.t("Ra. E stanotte attraverso il Duat con lui."), "s": "heal", "h": "tough"},
		{"q": Lang.t("Salgo ogni anno senza avere piedi, porto il limo nero e lascio pane dietro di me. Chi sono?"),
			"soft": Lang.t("La piena del Nilo."), "hard": Lang.t("Hapi, che non chiede permesso a nessuno."), "s": "short", "h": "horde"},
		{"q": Lang.t("Ho la testa di ibis e il calamo in mano: scrivo ciò che il cuore confessa. Chi sono?"),
			"soft": Lang.t("Thoth, lo scriba degli dèi."), "hard": Lang.t("Thoth. Scriva pure: non ho paura."), "s": "gift", "h": "fragile"},
		{"q": Lang.t("Sono più leggera di ogni cuore giusto e più pesante di ogni menzogna. Cosa sono?"),
			"soft": Lang.t("La piuma di Ma'at."), "hard": Lang.t("La piuma. Mettimi pure sulla bilancia."), "s": "shield", "h": "sting"},
		{"q": Lang.t("Spingo il sole davanti a me come una palla e a ogni alba rinasco con lui. Chi sono?"),
			"soft": Lang.t("Khepri, lo scarabeo."), "hard": Lang.t("Khepri. Anch'io spingo, e non mi fermo."), "s": "slow", "h": "fast"},
		{"q": Lang.t("Mi fecero a pezzi e mi sparsero lungo il fiume; una sposa mi ricompose. Chi sono?"),
			"soft": Lang.t("Osiride, signore dei morti."), "hard": Lang.t("Osiride. Anche i miei pezzi si rialzeranno."), "s": "heal", "h": "noheal"},
		{"q": Lang.t("Prima di ogni cosa ero acqua, senza fondo e senza luce. Chi sono?"),
			"soft": Lang.t("Nun, le acque del principio."), "hard": Lang.t("Nun. E da te sono uscito."), "s": "short", "h": "elite"},
		{"q": Lang.t("Mi strapparono e Thoth mi ricucì: ora proteggo chi mi porta al collo. Cosa sono?"),
			"soft": Lang.t("L'occhio di Horus."), "hard": Lang.t("L'occhio di Horus, che vede tutto."), "s": "shield", "h": "tough"},
		{"q": Lang.t("Ogni notte la mia barca passa dodici porte, e alla settima un serpente mi aspetta. Chi sono?"),
			"soft": Lang.t("Ra nella sua barca notturna."), "hard": Lang.t("Ra. E il serpente lo affronto io."), "s": "gift", "h": "horde"},
		{"q": Lang.t("Testa di coccodrillo, petto di leone, dorso d'ippopotamo: mangio i cuori pesanti. Chi sono?"),
			"soft": Lang.t("Ammit, la divoratrice."), "hard": Lang.t("Ammit. Il mio cuore non lo avrà."), "s": "slow", "h": "sting"},
		{"q": Lang.t("Sono un cappio sopra una croce, e gli dèi mi porgono a chi deve vivere. Cosa sono?"),
			"soft": Lang.t("L'ankh, la vita."), "hard": Lang.t("L'ankh. La vita me la prendo da me."), "s": "heal", "h": "fragile"},
		{"q": Lang.t("Ho il corpo di leone e il volto di un re, e guardo l'oriente da quando hai memoria. Chi sono?"),
			"soft": Lang.t("Sei tu, Sfinge."), "hard": Lang.t("Sei tu. E non mi spaventi."), "s": "short", "h": "fast"},
		{"q": Lang.t("Ho la testa di sciacallo, preparo i corpi e accompagno le anime alla bilancia. Chi sono?"),
			"soft": Lang.t("Anubi, il guardiano delle tombe."), "hard": Lang.t("Anubi. Stavolta non mi accompagna."), "s": "shield", "h": "noheal"},
		{"q": Lang.t("Un anello di corda chiude il mio nome: chi lo scalpella, cancella me. Cosa sono?"),
			"soft": Lang.t("Il cartiglio, che custodisce il nome."), "hard": Lang.t("Il nome. Il mio resterà inciso."), "s": "gift", "h": "elite"},
		{"q": Lang.t("Verde come le canne, signore delle acque: il Nilo è la mia casa. Chi sono?"),
			"soft": Lang.t("Sobek, il coccodrillo."), "hard": Lang.t("Sobek. Nuoterò nel suo fiume."), "s": "slow", "h": "tough"},
		{"q": Lang.t("Con le ali ridiedi il respiro al mio sposo, e il mio nome è il trono. Chi sono?"),
			"soft": Lang.t("Iside, la grande maga."), "hard": Lang.t("Iside. Ma oggi le ali sono le mie."), "s": "heal", "h": "horde"},
		{"q": Lang.t("Uscii per prima dalle acque immobili: una collina nel nulla, dove si posò la luce. Cosa sono?"),
			"soft": Lang.t("La collina primordiale."), "hard": Lang.t("La collina. Ci salirò in cima."), "s": "short", "h": "sting"},
	]
	if SphinxShop.owns("r_nilo"):
		base.append_array(_riddles_river())
	if SphinxShop.owns("r_stelle"):
		base.append_array(_riddles_sky())
	return base


## Enigmi del fiume (Tesoro della Sfinge).
static func _riddles_river() -> Array:
	return [
		{"q": Lang.t("Scorro da sud a nord, al contrario di tutti i fiumi che conosci. Chi sono?"),
			"soft": Lang.t("Il Nilo."), "hard": Lang.t("Il Nilo. E io lo risalgo."), "s": "slow", "h": "horde"},
		{"q": Lang.t("Sono la terra nera che il fiume lascia: il mio nome è il nome dell'Egitto. Cosa sono?"),
			"soft": Lang.t("Kemet, la terra nera."), "hard": Lang.t("Kemet. E la difenderò."), "s": "heal", "h": "tough"},
		{"q": Lang.t("Misuro il fiume con gradini di pietra: dal mio numero dipendono il pane e le tasse. Cosa sono?"),
			"soft": Lang.t("Il nilometro."), "hard": Lang.t("Il nilometro. Misura anche me."), "s": "shield", "h": "fast"},
		{"q": Lang.t("Fiorisco all'alba sull'acqua e mi chiudo al tramonto, come il sole che rinasce. Cosa sono?"),
			"soft": Lang.t("Il loto azzurro."), "hard": Lang.t("Il loto. Anch'io mi rialzo ogni mattina."), "s": "gift", "h": "fragile"},
	]


## Enigmi del cielo (Tesoro della Sfinge).
static func _riddles_sky() -> Array:
	return [
		{"q": Lang.t("Il mio corpo è coperto di stelle e mi piego sopra la terra, sostenuta dall'aria. Chi sono?"),
			"soft": Lang.t("Nut, il cielo."), "hard": Lang.t("Nut. E sotto di te salgo ancora."), "s": "slow", "h": "sting"},
		{"q": Lang.t("Quando sorgo prima del sole, il fiume sta per salire. Chi sono?"),
			"soft": Lang.t("Sopdet, la stella della piena."), "hard": Lang.t("Sopdet. Annuncio la piena e la tempesta."), "s": "short", "h": "elite"},
		{"q": Lang.t("Sono le stelle che non tramontano mai, e i re volevano diventare come noi. Chi siamo?"),
			"soft": Lang.t("Le Imperiture."), "hard": Lang.t("Le Imperiture. Non tramonterò nemmeno io."), "s": "shield", "h": "noheal"},
		{"q": Lang.t("Sono il disco del sole al tramonto, vecchio e stanco, prima di entrare nella notte. Chi sono?"),
			"soft": Lang.t("Atum, il sole della sera."), "hard": Lang.t("Atum. E io non sono stanco."), "s": "heal", "h": "fast"},
	]


## L'ordine degli enigmi del giorno (uguale per tutti): nella stessa prova non si ripetono finché
## ce ne sono di non usati (17 enigmi, una pausa ogni 3 ondate: il giro finisce all'ondata 51).
static func riddle_order() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed(day()) + 31
	var idx := range(riddles().size())
	for i in range(idx.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: int = idx[i]
		idx[i] = idx[j]
		idx[j] = tmp
	return idx


## Doni della prova (blocco 17): i doni propri della Sfinge, tre a caso tra quelli non ancora presi,
## un solo livello, validi per ogni arma. Con «Digiuno» niente Respiro dell'Orizzonte (non curerebbe).
static func boon_offers(owned: Dictionary, w: int) -> Array:
	var pool := Boons.sphinx_pool(owned, true)
	if SphinxShop.has_mod("noheal"):
		pool.erase("sf_breath")
	pool.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed(day()) ^ (w * 104729) ^ owned.size()
	var out := []
	while out.size() < 3 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out
