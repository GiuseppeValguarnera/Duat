class_name Imhotep
extends RefCounted
## Imhotep, nella Casa della Vita. Esistito davvero: architetto del re Djoser, costruì la prima
## piramide a Saqqara; scriba, medico, gran sacerdote di Eliopoli. Dopo la morte gli Egizi ne
## fecero un dio, il patrono degli scribi: prima di scrivere versavano qualche goccia d'acqua
## del loro vasetto in suo onore. Qui è il maestro della Casa della Vita.
##
## Carattere: un sapiente vivace e un po' vanitoso, parla tanto, ama spiegare, ti tratta da
## allievo promettente. Il contrario di Anubi, grave e asciutto.
##
## Cosa dice, in quest'ordine di importanza:
##   1. un amuleto appena forgiato: cosa significa e come usarlo bene (una volta per amuleto);
##   2. la storia: Akhet lo pregava, e lui ricorda cosa chiedeva. Indizi con una seconda
##      lettura innocente (docs/storia.md, "Regole per chi scrive le battute");
##   3. una sfida da riscuotere sulla parete;
##   4. un consiglio adatto a dove sei arrivato (il Serpente, Am-heh, o in generale);
##   5. una frase breve.

const NAME_COLOR := Color(0.3, 0.62, 0.66)


static func _amulet_lines() -> Dictionary:
	return {
		"iside": [Lang.t("Il nodo di Iside! Diaspro rosso, il sangue della dea. Le trappole del Duat le hanno costruite artigiani pigri: con questo al collo, le loro fatiche diventano solletico."),
			Lang.t("Consiglio da maestro: con il nodo puoi attraversare le grate e gli spuntoni invece di girarci intorno. La strada più corta è anche la più elegante.")],
		"ankh": [Lang.t("L'ankh. Lo portano tutti gli dèi in ogni pittura, e nessuno sa dire con certezza cosa raffiguri. Io lo so, naturalmente. Ma un maestro non svela tutto alla prima lezione."),
			Lang.t("Ogni stanza nuova ti restituisce un soffio di vita. Poco alla volta, come le gocce di una clessidra ad acqua. Con l'ankh conviene scegliere le strade lunghe.")],
		"djed": [Lang.t("Il pilastro djed, la spina dorsale di Osiride. Stabile, immobile, testardo. Un po' come me davanti a un progetto sbagliato."),
			Lang.t("Quando scatti resta una statua al tuo posto, e i nemici ci cascano. Scatta verso di loro, non via da loro: la statua li tiene, tu li colpisci alle spalle.")],
		"was": [Lang.t("Lo scettro was: il potere. Ma il potere vero, allievo, non si prende in un colpo solo. Si accumula, stanza dopo stanza, senza commettere errori."),
			Lang.t("Ogni stanza pulita lo rende più forte. Una sola ferita e quella stanza non conta. Gioca con calma: la fretta è la nemica dello scettro.")],
		"shen": [Lang.t("L'anello shen. Un nodo che non finisce mai, come l'eternità, come i miei discorsi. Allungalo e diventa un cartiglio, il recinto del nome del re."),
			Lang.t("Con l'anello gli dèi che ti hanno già scelto tornano a cercarti. Decidi presto chi seguire, e seguilo fino in fondo.")],
		"hathor": [Lang.t("Il menat di Hathor. Le sacerdotesse lo scuotevano per rallegrare la dea. Anche il Traghettatore, scoprirai, si rallegra. A modo suo. Cioè fa uno sconto."),
			Lang.t("Con la collana conviene arrivare da Mahaf con il Ka in tasca. Non sprecarlo per strada.")],
		"udjat": [Lang.t("L'udjat, l'occhio guarito. Set lo strappò a Horus e Thoth lo rimise insieme pezzo per pezzo. Ogni pezzo era una frazione: un mezzo, un quarto, un ottavo. Gli scribi ci contavano il grano."),
			Lang.t("Con l'occhio al collo le crepe delle stanze segrete brillano. Guarda in alto, lungo il muro, quando una stanza si svuota.")],
		"kheper": [Lang.t("Kheper. Lo scarabeo che spinge il sole fuori dalla notte. «Kheper» vuol dire anche «diventare». Tutto ciò che diventa, passa da lui."),
			Lang.t("I primi doni arriveranno già maturi. Scegli i primi dèi con cura: con lo scarabeo, l'inizio di una discesa conta il doppio.")],
	}


## La storia: Akhet visto da chi riceveva le sue preghiere. Una battuta per volta, una volta sola.
static func _story() -> Array:
	return [
		{"id": "imh_intro", "if": true, "lines": [
			Lang.t("Oh! Un visitatore. Finalmente qualcuno che sa leggere."),
			Lang.t("Io sono Imhotep. Sì, quell'Imhotep. La prima piramide? Mia. Prego. Ero lo scriba, il medico e l'architetto del re Djoser, e poi gli Egizi hanno deciso che ero un dio. Non ho protestato."),
			Lang.t("Questa è la Casa della Vita: qui si copiavano i libri sacri, si studiavano le stelle e i rimedi. Lì c'è il banco dell'orafo, per gli amuleti. Là la parete di Thoth, dove il Duat incide le tue imprese."),
			Lang.t("Anche tu sei uno scriba, mi dicono. Allora versa due gocce d'acqua per me, prima di scrivere. Tutti gli scribi lo facevano. Mi piaceva molto.")]},
		{"id": "imh_akhet1", "if": Meta.runs >= 1, "lines": [
			Lang.t("Il tuo re, Akhet. Lo conoscevo, in un certo senso. Mi pregava. I re pregano gli dèi grandi in pubblico e me in privato: io sono il dio delle cose che funzionano."),
			Lang.t("Mi chiedeva rimedi. Non contro la febbre o il mal di denti. Voleva sapere se esiste un rimedio contro la morte."),
			Lang.t("Gli risposi come rispondo a tutti: l'unico rimedio contro la morte è un buon nome. Scritto bene, in un posto dove la pioggia non arriva.")]},
		{"id": "imh_akhet2", "if": Meta.ammit_wins >= 1, "lines": [
			Lang.t("Hai battuto Am-heh! Bene, bene. Prendi questo calamo, fammi vedere come scrivi il tuo nome... no, aspetta. Come lo tieni?"),
			Lang.t("Lo stringi come si stringe una lancia. Tutto il pugno, il pollice sopra. Bah. Il Duat cambia le abitudini. Anch'io qui non ho più le mie rughe, e mi mancano: le avevo guadagnate una per una.")]},
		{"id": "imh_akhet2b", "if": Meta.serpent_wins >= 3, "lines": [
			Lang.t("Sai qual è il segreto di una piramide? Non la cima. La base. Se la base è storta, ogni gradino ripete l'errore, più in alto, dove tutti lo vedono."),
			Lang.t("Akhet volle una tomba grandissima. Mandò i suoi architetti a misurare la mia, a Saqqara. Gli dissero che io avevo sbagliato un angolo. Avevano ragione. Non l'ho mai perdonato a nessuno.")]},
		{"id": "imh_akhet3", "if": Meta.ammit_wins >= 2, "lines": [
			Lang.t("Ho ricordato una cosa. Una notte Akhet mi chiese se un uomo senza nome può essere pesato."),
			Lang.t("Gli risposi che senza nome non c'è cuore da mettere sulla bilancia, ma nemmeno una casa dove tornare. Lui sorrise come chi ha sentito solo la prima metà della frase."),
			Lang.t("Poi mi offrì una giara di vino buono. Per un re è il modo di dire «grazie» e anche «non ne parliamo più».")]},
		{"id": "imh_sokar1", "if": Meta.sokar_seen, "lines": [
			Lang.t("Sokar! Signore della necropoli, dio delle barche che solcano la sabbia. Le mie piramidi sorgono a Saqqara, e Saqqara porta il suo nome. Siamo vicini da tremila anni, io e lui."),
			Lang.t("Non ci siamo mai rivolti la parola. Tra eterni, il silenzio è una forma di cortesia.")]},
		{"id": "imh_nome", "if": Meta.aker_wins >= 1, "lines": [
			Lang.t("Conosci la storia del nome segreto? Iside raccolse la saliva del vecchio Ra, la impastò con la terra e ne trasse un serpente. Il suo morso bruciava più del fuoco, e solo lei sapeva spegnerlo. Il prezzo fu il nome."),
			Lang.t("Akhet volle udirla tre volte. Alla terza mi chiese: «E Iside, dopo, divenne immortale?» Risposi che gli dèi lo sono già."),
			Lang.t("Restò in silenzio a lungo. Poi disse: «Allora a lei non serviva. A un uomo, sì.»")]},
		{"id": "imh_akhet4", "if": Meta.ammit_wins >= 3, "lines": [
			Lang.t("Il nome di un uomo è un edificio. Io costruii una montagna di pietra perché quello di Djoser restasse in piedi."),
			Lang.t("Quello di Akhet l'hanno smontato pietra per pietra. Ma con cura, allievo. Senza rompere nulla. Chi odia spacca. Chi smonta con tanta attenzione... forse vuole ricostruire, un giorno.")]},
	]


## Consigli per dove sei arrivato.
static func _tips() -> Array:
	if Meta.serpent_wins == 0:
		return [Lang.t("Il Serpente della Porta si immerge e ti segue sott'acqua: guarda la scia a V. Riemerge dove compare il cerchio. Non stargli addosso: scatta via, poi colpisci quando esce."),
			Lang.t("Quando il Serpente alza la testa e sibila, sputa a ventaglio. Non scappare all'indietro, che il ventaglio si allarga: scatta di lato, tra uno sputo e l'altro."),
			Lang.t("Prima del Serpente c'è sempre il Traghettatore. Arrivaci con il Ka in tasca: l'Acqua del Nilo ti salva più di un dono."),
			Lang.t("Una regola da architetto: guarda la stanza prima di correre. Le colonne sono ripari, non ostacoli.")]
	if Meta.ammit_wins == 0:
		return [Lang.t("Am-heh brucia, e il fuoco non entra nell'acqua. Ricordati delle pozze della sua arena: sono le tue stanze sicure."),
			Lang.t("Quando Am-heh si ferma a riprendere fiato, quello è il momento. Colpisci forte e tanto, poi torna vicino all'acqua."),
			Lang.t("Contro Am-heh conviene arrivare con la vita alta più che con i doni alti. Un dono in meno, un'Acqua del Nilo in più."),
			Lang.t("Il Libro dei Morti è lì apposta. Un capitolo comprato bene vale dieci discese fatte di fretta.")]
	return [Lang.t("Hai battuto Am-heh. Ora prova un'altra arma: Neith la tiene da parte per te, e ogni prima vittoria con un'arma nuova vale Lacrime di Iside."),
		Lang.t("Il Peso del Cuore rende la discesa più dura e il Ka più ricco. Un buon architetto aggiunge peso solo quando la base regge."),
		Lang.t("Prova a scendere senza dare a nessun dio più di due doni. Si impara molto, quando si è costretti a scegliere."),
		Lang.t("Le sfide della parete non sono decorazioni. Thoth le ha incise perché tu le faccia.")]


static func _idle() -> Array:
	return [Lang.t("La prima piramide. Sei gradoni. Mia. L'ho già detto? Vale la pena ripeterlo."),
		Lang.t("I Greci, tra duemila anni, mi chiameranno con un altro nome e diranno che curavo i malati nel sonno. Hanno ragione solo a metà: li curavo anche da svegli."),
		Lang.t("Thoth è il dio della scrittura. Io sono il dio di chi scrive. È diverso: lui inventa le parole, io sopporto chi le sbaglia."),
		Lang.t("Studia, allievo. Il Duat non perdona chi non legge le istruzioni."),
		Lang.t("Un amuleto non combatte al posto tuo. Ti ricorda solo come combattere meglio."),
		Lang.t("Hai visto lo scalpellino nella Sala? Bravo artigiano. Un po' lento. Io in quel tempo avrei alzato un tempio.")]


## Un amuleto forgiato di cui Imhotep non ha ancora parlato ("" se nessuno).
static func _new_amulet() -> String:
	for id in Meta.amulets:
		if not Meta.dialogue_seen.has("imh_am_" + id):
			return id
	return ""


static func _next_beat() -> Dictionary:
	for b in _story():
		if b["if"] and not Meta.dialogue_seen.has(b["id"]):
			return b
	return {}


## Ha qualcosa di nuovo da dire? (il punto esclamativo sopra di lui)
static func has_news() -> bool:
	return _new_amulet() != "" or not _next_beat().is_empty()


static var _last_tip := ""

static func next_lines() -> Array:
	var am := _new_amulet()
	if am != "" and Meta.dialogue_seen.has("imh_intro"):       # prima si presenta
		Meta.dialogue_seen.append("imh_am_" + am)
		Meta.save()
		return _amulet_lines()[am]
	var beat := _next_beat()
	if not beat.is_empty():
		Meta.dialogue_seen.append(beat["id"])
		Meta.save()
		return beat["lines"]
	if Challenges.to_claim() > 0:
		return [Lang.t("Thoth ha inciso qualcosa di nuovo sulla parete. Una tua impresa, credo. Va' a riscuotere: lasciare un premio sul muro è da maleducati.")]
	# un consiglio, senza ripetere quello di prima; ogni tanto una frase di vanità
	var pool := _tips() if randf() < 0.7 else _idle()
	pool = pool.filter(func(l: String) -> bool: return l != _last_tip)
	_last_tip = pool.pick_random()
	return [_last_tip]


## Imhotep in piedi accanto al tavolo degli scribi: testa rasata con la calotta azzurra, il
## gonnellino lungo da sapiente, il rotolo aperto sulle braccia. Quando parla gesticola.
static func draw(ci: CanvasItem, p: Vector2, t: float, talking: bool, face: float) -> void:
	var skin := Color(0.66, 0.42, 0.25)
	var linen := Color(0.94, 0.91, 0.82)
	var outl := Color(0.1, 0.07, 0.05)
	var bob := sin(t * 1.4) * 0.6
	ci.draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.35))
	ci.draw_set_transform(p, 0.0, Vector2(face, 1.0))
	var o := Vector2(0, bob)
	# gonnellino lungo fino alle caviglie, con la cintura
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-7, -24), o + Vector2(7, -24), o + Vector2(8, -1), o + Vector2(-8, -1)]), outl)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -23), o + Vector2(6, -23), o + Vector2(7, -2), o + Vector2(-7, -2)]), linen)
	ci.draw_line(o + Vector2(-6, -23), o + Vector2(6, -23), Color(0.94, 0.72, 0.3), 1.5)
	ci.draw_line(o + Vector2(0, -21), o + Vector2(1, -4), Color(0.8, 0.76, 0.66), 0.8)
	ci.draw_line(Vector2(-3, -1), Vector2(-3, 0), skin, 2.0)
	ci.draw_line(Vector2(3, -1), Vector2(3, 0), skin, 2.0)
	# busto nudo, un po' rotondo (il sapiente mangia bene), collare semplice
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -36), o + Vector2(6, -36), o + Vector2(7, -24), o + Vector2(-7, -24)]), skin)
	ci.draw_arc(o + Vector2(0, -37), 4.5, 0.1 * PI, 0.9 * PI, 10, Color(0.3, 0.62, 0.66), 2.0)
	# braccia con il rotolo aperto; parlando, una mano si alza a spiegare
	var lift := (0.6 + 0.3 * sin(t * 4.0)) if talking else 0.0
	ci.draw_line(o + Vector2(-6, -34), o + Vector2(-7, -26), skin, 2.4)
	var hand := o + Vector2(7 + 4 * lift, -27 - 10 * lift)
	ci.draw_line(o + Vector2(6, -34), hand, skin, 2.4)
	ci.draw_rect(Rect2(o.x - 9, o.y - 28, 14, 5), Color(0.92, 0.86, 0.66))
	ci.draw_circle(o + Vector2(-9, -25.5), 2.5, Color(0.86, 0.78, 0.58))
	for k in range(3):
		ci.draw_line(o + Vector2(-6 + k * 3.5, -27), o + Vector2(-4 + k * 3.5, -27), Color(0.2, 0.2, 0.2, 0.7), 0.6)
	# la testa rasata con la calotta azzurra, l'orecchio, l'occhio con il kohl
	var hc := o + Vector2(0.5, -42)
	ci.draw_circle(hc, 5.2, outl)
	ci.draw_circle(hc, 4.6, skin)
	ci.draw_arc(hc, 4.4, PI * 1.05, PI * 1.95, 12, Color(0.18, 0.36, 0.66), 2.6)
	ci.draw_circle(hc + Vector2(-2.6, 0.5), 1.1, skin.darkened(0.15))
	ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(4.2, -0.5), hc + Vector2(6, 1), hc + Vector2(4.2, 1.6)]), skin)
	ci.draw_circle(hc + Vector2(2.4, -0.4), 0.7, Color(0.05, 0.04, 0.06))
	ci.draw_line(hc + Vector2(3.1, -0.4), hc + Vector2(4.2, -0.2), Color(0.05, 0.04, 0.06), 0.6)
	if talking:
		ci.draw_line(hc + Vector2(2.8, 2.4), hc + Vector2(3.8, 2.4 + 0.6 * absf(sin(t * 12.0))), Color(0.3, 0.12, 0.08), 0.8)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
