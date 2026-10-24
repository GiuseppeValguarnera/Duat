class_name Lore
## Cosa raccontano le divinità quando ti offrono un dono, e l'archivio dei Papiri di Thoth.
##
## Ogni dio ha:
## - "intro": come si presenta la prima volta;
## - "stories": pezzi del suo mito, raccontati uno per incontro, una volta sola;
## - "idle": frasi brevi per quando ha già raccontato tutto.
## Le storie ascoltate vengono salvate in Meta.dialogue_seen e si rileggono nei Papiri di Thoth.
## I fatti sono quelli della mitologia e della storia egizia: niente inventato, al massimo semplificato.

const GODS := {
	"anubi": {
		"name": "Anubi, il Guardiano",
		"intro": {"title": "La bilancia", "text": "Prima di scendere ti peso. Ogni mio dono è una bilancia: qualcosa guadagni, qualcosa cedi. Esattamente come nel giudizio dei morti."},
		"stories": [
			{"title": "L'imbalsamatore", "text": "Fui io a imbalsamare Osiride, il primo dei morti. Da allora proteggo i corpi. I sacerdoti imbalsamatori a volte lavoravano con una maschera da sciacallo sul viso: la mia faccia."},
			{"title": "Settanta giorni", "text": "Una mummificazione durava settanta giorni. Si toglieva il cervello passando dal naso, si asciugava il corpo sotto il natron, un sale del deserto, per circa quaranta giorni. Il cuore restava al suo posto: serviva al giudizio."},
			{"title": "I vasi canopi", "text": "Fegato, polmoni, stomaco e intestino finivano in quattro vasi, ognuno protetto da un figlio di Horus: Imset con la testa d'uomo, Hapi di babbuino, Duamutef di sciacallo, Qebehsenuf di falco."},
			{"title": "Perché uno sciacallo", "text": "Gli sciacalli si aggiravano nei cimiteri e scavavano nelle tombe. Gli Egizi pensarono che fosse meglio avere uno sciacallo dalla propria parte. Così sono diventato il guardiano della necropoli."},
			{"title": "Prima di Osiride", "text": "Nei testi più antichi il signore dei morti ero io. Poi il trono dell'aldilà passò a Osiride, e io tenni la bilancia. Fidati, è il lavoro migliore: si vede tutto."},
		],
		"idle": ["Scegli con attenzione. La bilancia ricorda.", "Torna intero, se puoi.", "Un cuore leggero va più lontano."],
	},
	"ra": {
		"name": "Ra, il Sole",
		"intro": {"title": "Chi è Ra", "text": "Io sono Ra, il sole che muore ogni sera e rinasce ogni mattina. Questa notte la mia barca attraversa il Duat, proprio come te. Prendi il mio fuoco, Scriba: illumina la strada a tutti e due."},
		"stories": [
			{"title": "La barca della notte", "text": "Di giorno navigo nel cielo. Al tramonto cambio barca ed entro nel Duat: dodici ore di notte, dodici porte, ognuna con il suo guardiano. Se non arrivassi alla dodicesima, il sole non sorgerebbe più."},
			{"title": "Apophis", "text": "Ogni notte il serpente Apophis prova a inghiottire la mia barca. Non muore mai: viene sconfitto e torna. I sacerdoti scrivevano il suo nome su papiri e statuine, poi li calpestavano e li bruciavano per aiutarmi."},
			{"title": "L'Occhio di Ra", "text": "Quando gli uomini complottarono contro di me, mandai il mio Occhio a punirli. Diventò Sekhmet, e non voleva più fermarsi. La ingannai con birra tinta di rosso: credendola sangue la bevve, si addormentò, e l'umanità fu salva."},
			{"title": "Il nome segreto", "text": "Ho molti nomi, ma uno solo è vero, e dà potere su di me. Iside lo voleva: creò un serpente dalla mia saliva e lo mise sul mio cammino. Solo lei poteva guarire il morso... in cambio del nome. Ricordatelo, quando la incontri."},
			{"title": "Tre volti", "text": "Al mattino sono Khepri, lo scarabeo che spinge il sole come una palla. A mezzogiorno sono Ra. La sera sono Atum, il vecchio. Per gli Egizi un dio poteva avere molti volti senza smettere di essere uno."},
		],
		"idle": ["Il fuoco non chiede permesso.", "Bruciali. La notte è lunga.", "Anch'io muoio ogni sera. Non è una scusa per fermarsi."],
	},
	"sekhmet": {
		"name": "Sekhmet, la Potente",
		"intro": {"title": "Chi è Sekhmet", "text": "Sono Sekhmet, la Potente. Ho la testa di leonessa, e il mio respiro è il vento caldo del deserto. Ra mi ha creata per punire, e io punisco volentieri. Prendi la mia furia."},
		"stories": [
			{"title": "La strage", "text": "Ra mi mandò contro gli uomini ribelli e io ne divorai così tanti che lui stesso si pentì. Mi fermò solo la birra rossa che credetti sangue. Gli Egizi ricordavano quel giorno con una festa... in cui ci si ubriacava."},
			{"title": "Signora della peste", "text": "Gli Egizi temevano i miei messaggeri: le epidemie. Ma chi porta la malattia sa anche toglierla. I miei sacerdoti erano medici, tra i più antichi della storia."},
			{"title": "Centinaia di statue", "text": "Il faraone Amenhotep III mi fece scolpire centinaia di statue di granito nero, forse più di settecento, per tenermi calma. Molte le trovi ancora oggi nei musei di tutto il mondo."},
			{"title": "Due volti", "text": "Hathor è la dea della gioia, della musica e dell'amore. In molti miti siamo la stessa dea: io sono quello che succede quando la gioia si arrabbia."},
			{"title": "Menfi", "text": "Ero adorata a Menfi, sposa di Ptah, il dio degli artigiani. Nostro figlio è Nefertum, il fiore di loto che si apre sull'acqua al primo sole."},
		],
		"idle": ["Più forte.", "Ruggisci quando colpisci. Aiuta.", "La pietà è per chi ha già vinto."],
	},
	"thoth": {
		"name": "Thoth, lo Scriba degli dèi",
		"intro": {"title": "Chi è Thoth", "text": "Sono Thoth, testa di ibis, signore della scrittura e della luna. Al giudizio dei morti sono io a scrivere il verdetto. Anche tu sei uno scriba: vediamo se il tuo Occhio è preciso quanto la mia penna."},
		"stories": [
			{"title": "Le parole divine", "text": "Ho dato agli Egizi i geroglifici, le 'parole divine': centinaia di segni, alcuni sono suoni, altri idee. Per un egizio scrivere un nome significava farlo vivere per sempre. Cancellarlo... beh, lo sai bene."},
			{"title": "I cinque giorni", "text": "Ra aveva vietato a Nut di partorire in qualunque giorno dell'anno. Io giocai d'azzardo con la Luna e le vinsi cinque giorni nuovi, fuori dal calendario. In quei giorni nacquero Osiride, Iside, Set e Nefti."},
			{"title": "L'Occhio di Horus", "text": "Set strappò l'occhio a Horus e lo fece a pezzi. Io raccolsi i pezzi e lo guarii. Quell'occhio, il wedjat, divenne il simbolo della salute e della protezione. È lo stesso che lanci contro i nemici."},
			{"title": "Al giudizio", "text": "Quando il cuore viene pesato contro la piuma di Ma'at, Anubi controlla la bilancia e io scrivo il risultato. Nei dipinti ho in mano una tavolozza da scriba. Senza scrittura, nemmeno gli dèi saprebbero chi è innocente."},
			{"title": "Milioni di ibis", "text": "Mi raffiguravano anche come babbuino, che all'alba saluta il sole gridando. A Saqqara e a Tuna el-Gebel sono stati trovati milioni di ibis mummificati: offerte dei pellegrini per me."},
		],
		"idle": ["Mira. Poi mira meglio.", "Ogni colpo è una parola. Scrivi bene.", "Il sapere è un'arma che non si spunta."],
	},
	"bastet": {
		"name": "Bastet, la Gatta",
		"intro": {"title": "Chi è Bastet", "text": "Sì, sono una dea, non fare quella faccia. Sono Bastet, la gatta di Bubasti: proteggo le case, le madri e i bambini. E graffio. Molto."},
		"stories": [
			{"title": "Da leonessa a gatta", "text": "All'inizio ero una leonessa feroce, come Sekhmet. Col tempo gli Egizi mi hanno immaginata come una gatta: dolce in casa, terribile quando serve. Diciamo che sono maturata."},
			{"title": "La festa di Bubasti", "text": "Lo storico greco Erodoto racconta che alla mia festa arrivavano settecentomila persone sulle barche, cantando e battendo le mani, e che si beveva più vino lì che in tutto il resto dell'anno. Ero popolare."},
			{"title": "I gatti sacri", "text": "I gatti difendevano i granai da topi e serpenti, e per questo erano preziosi. Uccidere un gatto, anche per sbaglio, poteva costare la vita. Quando il gatto di casa moriva, la famiglia si radeva le sopracciglia in segno di lutto."},
			{"title": "Mummie in Inghilterra", "text": "Nei miei santuari sono stati sepolti moltissimi gatti mummificati. Nel 1890 ne spedirono in Inghilterra un carico intero, quasi centottantamila, per farne fertilizzante. Non ne voglio parlare."},
			{"title": "Il Grande Gatto", "text": "In un mito il Grande Gatto di Eliopoli taglia la testa al serpente Apophis sotto l'albero sacro. Qualcuno dice che fossi io. Non fidarti di chi dice che i gatti sono pigri."},
		],
		"idle": ["Colpisci dove fa male. Poi sparisci.", "Nove vite? Magari. Tu ne hai una alla volta.", "Fusa. Ora vai."],
	},
	"sobek": {
		"name": "Sobek, il Signore del Nilo",
		"intro": {"title": "Chi è Sobek", "text": "Sobek, signore del Nilo. Testa di coccodrillo, pelle più dura della pietra. Il fiume è la vita dell'Egitto, e io sono il fiume quando morde. Prendi la mia forza."},
		"stories": [
			{"title": "La Terra Nera", "text": "Ogni anno il Nilo straripava e lasciava sui campi il limo nero, la terra fertile. Per questo gli Egizi chiamavano il loro paese Kemet, la Terra Nera. Alcuni testi dicono che le acque del Nilo nascessero da me."},
			{"title": "Il coccodrillo con gli orecchini", "text": "A Coccodrilopoli, nel Fayyum, viveva in un lago un coccodrillo sacro. Lo ornavano con orecchini d'oro e braccialetti, e i visitatori gli portavano pane, carne e vino. Il geografo greco Strabone lo vide con i suoi occhi."},
			{"title": "Kom Ombo", "text": "Il tempio di Kom Ombo è doppio: metà è mio, metà di Horus il Vecchio. Due ingressi, due santuari. Lì sono stati trovati coccodrilli mummificati, alcuni con le loro uova."},
			{"title": "Temuto e pregato", "text": "Chi viveva sul Nilo mi temeva: i coccodrilli uccidevano davvero. Per questo mi pregavano. Meglio avere dalla propria parte chi ti può mangiare."},
		],
		"idle": ["Resisti. Il fiume non si ferma.", "Morde chi sa aspettare.", "Pelle dura, cuore calmo."],
	},
	"iside": {
		"name": "Iside, la Grande Maga",
		"intro": {"title": "Chi è Iside", "text": "Sono Iside, la Grande Maga. Ho riportato in vita mio marito Osiride con la magia e con l'amore. Se un morto può tornare, Scriba, anche tu puoi."},
		"stories": [
			{"title": "La cassa", "text": "Set fece costruire una cassa splendida, su misura per Osiride, e durante un banchetto la promise a chi ci entrava perfettamente. Osiride si sdraiò dentro. Set chiuse il coperchio e la gettò nel Nilo."},
			{"title": "La prima mummia", "text": "Ritrovai Osiride, ma Set lo fece a pezzi e li sparse per l'Egitto. Con mia sorella Nefti li cercai uno per uno, e Anubi ci aiutò a ricomporlo e fasciarlo: fu la prima mummia. Per questo ogni egizio voleva essere mummificato."},
			{"title": "Horus nella palude", "text": "Osiride tornò in vita abbastanza a lungo da darmi un figlio: Horus. Lo nascosi tra i papiri delle paludi del Delta, lontano da Set, finché non fu grande abbastanza da combattere."},
			{"title": "Il nome di Ra", "text": "Sì, ho ingannato Ra per avere il suo nome segreto. Te l'avrà raccontato a modo suo. Io volevo il potere per proteggere mio figlio. Giudica tu."},
			{"title": "Il nodo di Iside", "text": "Il tyet, il nodo di Iside, era un amuleto di pietra rossa messo sul collo della mummia. Il Libro dei Morti dice che chi lo porta è protetto dalla magia di Iside."},
			{"title": "Oltre l'Egitto", "text": "Il mio culto uscì dall'Egitto: avevo templi in Grecia, a Roma, fino a Londra. A Pompei puoi ancora entrare nel mio tempio. Sono stata pregata per più di tremila anni."},
		],
		"idle": ["Ti proteggo io. Tu pensa a vivere.", "Ogni ferita si chiude, prima o poi.", "Ho ricomposto un dio. Posso ricomporre te."],
	},
	"set": {
		"name": "Set, il Signore del Deserto",
		"intro": {"title": "Chi è Set", "text": "Set. Signore del deserto, delle tempeste e degli stranieri. Sì, quello che ha ucciso suo fratello. Ma ogni notte, quando Apophis attacca la barca di Ra, chi credi che lo respinga? Facciamo un patto."},
		"stories": [
			{"title": "La terra rossa", "text": "Osiride aveva il trono e la terra fertile, Kemet, la nera. A me restava il deserto, Deshret, la rossa. Per questo il rosso era il colore del caos. Il mio colore."},
			{"title": "Ottant'anni", "text": "Dopo Osiride combattei contro Horus per il trono, per ottant'anni: gare di barche, trasformazioni in ippopotami, tribunali di dèi. Alla fine il trono andò a lui. Io ebbi un posto sulla barca di Ra. Non male, per un cattivo."},
			{"title": "Sulla prua", "text": "Sulla prua della barca del sole, ogni notte, trafiggo Apophis con la lancia. Il caos combatte un caos più grande. A volte serve un mostro per fermare un mostro."},
			{"title": "L'animale di Set", "text": "Ho la testa di un animale che nessuno sa riconoscere: muso lungo e curvo, orecchie squadrate, coda dritta. Un cane? Un asino? Un formichiere? Gli studiosi litigano ancora. Io mi diverto."},
			{"title": "Il nome dei faraoni", "text": "Non sono sempre stato il cattivo. Alcuni faraoni portavano il mio nome con orgoglio: Seti, il padre di Ramses II, significa 'quello di Set'."},
		],
		"idle": ["Prima il prezzo, poi il premio. Sempre.", "Ti piace soffrire? Imparerai.", "Un patto è un patto."],
	},
}

## Le lezioni di Anubi nella Sala del Giudizio (le racconta quando non ha altro di nuovo da dire).
const JUDGEMENT := [
	{"title": "La pesatura del cuore", "text": "Il cuore del morto va su un piatto della bilancia, la piuma di Ma'at sull'altro. Se il cuore è leggero, il morto entra nel Campo dei Giunchi, l'Aaru. Se è pesante di colpe, Ammit lo divora: è la seconda morte, quella definitiva."},
	{"title": "Ma'at", "text": "Ma'at è la verità e l'ordine del mondo, e anche la dea che li rappresenta. La sua piuma è il simbolo dell'equilibrio. Il faraone doveva mantenere Ma'at, e ogni egizio doveva viverci dentro. Il contrario si chiamava isfet: il caos."},
	{"title": "I quarantadue giudici", "text": "Prima della bilancia il morto passa davanti a quarantadue giudici. A ciascuno dichiara una colpa che non ha commesso: non ho rubato, non ho mentito, non ho fatto piangere nessuno. È la Confessione negativa, capitolo 125 del Libro dei Morti."},
	{"title": "Le parti dell'anima", "text": "Per gli Egizi l'anima ha più parti: il Ka, la forza vitale; il Ba, che vola come un uccello con la testa umana; il Ren, il nome; lo Sheut, l'ombra; l'Ib, il cuore. Perdi il nome, Scriba, e perdi un pezzo di te."},
	{"title": "Il Libro dei Morti", "text": "Non è un libro solo: è una raccolta di formule su papiro messa nella tomba per aiutare il morto nel viaggio. Gli Egizi lo chiamavano 'Formule per uscire al giorno'. Ognuno sceglieva i capitoli che poteva permettersi. Come te."},
	{"title": "Ammit", "text": "Ammit non era adorata, era temuta. Testa di coccodrillo, zampe davanti di leone, dietro di ippopotamo: i tre animali più pericolosi d'Egitto in un corpo solo. Aspetta accanto alla bilancia. Non ha mai mangiato abbastanza."},
	{"title": "Il Duat", "text": "Il Duat è il mondo sotto il mondo. Un testo chiamato Amduat, dipinto sulle pareti delle tombe nella Valle dei Re, lo descrive ora per ora: dodici ore di notte, ognuna con i suoi dèi, i suoi mostri e la sua porta."},
	{"title": "Il nome cancellato", "text": "Cancellare il nome di qualcuno dai monumenti era la punizione peggiore. Lo fecero con la regina Hatshepsut e con il faraone Akhenaton, scalpellando i loro nomi dalle pareti. Senza nome è come se non fossi mai esistito. È quello che hanno fatto a te."},
	{"title": "Il Campo dei Giunchi", "text": "L'Aaru, il Campo dei Giunchi, è il paradiso egizio: un Egitto perfetto, con canali, grano altissimo e nessuna fame. Anche lì però si lavora i campi. Per questo nelle tombe mettevano gli ushabti, che lavoravano al posto tuo."},
]


static func god_name(god: String) -> String:
	return GODS[god]["name"] if GODS.has(god) else god


static func _entries(god: String) -> Array:
	var g: Dictionary = GODS[god]
	var out: Array = [g["intro"]]
	out.append_array(g["stories"])
	return out


## Cosa dice il dio adesso: la prima storia non ancora ascoltata, oppure una frase breve.
static func speech(god: String) -> String:
	if not GODS.has(god):
		return ""
	var entries := _entries(god)
	for i in range(entries.size()):
		var id := "%s_%d" % [god, i]
		if not Meta.dialogue_seen.has(id):
			Meta.dialogue_seen.append(id)
			Meta.save()
			return entries[i]["text"]
	var idle: Array = GODS[god]["idle"]
	return idle.pick_random()


## La prossima lezione di Anubi non ancora ascoltata ("" se le ha dette tutte).
static func next_lesson() -> String:
	for i in range(JUDGEMENT.size()):
		var id := "giudizio_%d" % i
		if not Meta.dialogue_seen.has(id):
			Meta.dialogue_seen.append(id)
			Meta.save()
			return JUDGEMENT[i]["text"]
	return ""


## L'archivio dei Papiri di Thoth: categorie con le voci già ascoltate (le altre restano sigillate).
static func codex() -> Array:
	var out := []
	var judgement := []
	for i in range(JUDGEMENT.size()):
		judgement.append(_entry(JUDGEMENT[i], Meta.dialogue_seen.has("giudizio_%d" % i)))
	out.append({"title": "Il giudizio", "entries": judgement})
	for god in ["anubi", "ra", "sekhmet", "thoth", "bastet", "sobek", "iside", "set"]:
		var list := []
		var entries := _entries(god)
		for i in range(entries.size()):
			list.append(_entry(entries[i], Meta.dialogue_seen.has("%s_%d" % [god, i])))
		out.append({"title": GODS[god]["name"], "entries": list})
	var chapters := []
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		chapters.append(_entry({"title": "Capitolo %d · %s" % [c["num"], c["name"]], "text": c["lore"]}, Chapters.is_unlocked(id)))
	out.append({"title": "Il Libro dei Morti", "entries": chapters})
	return out


static func _entry(e: Dictionary, seen: bool) -> Dictionary:
	return {"title": e["title"] if seen else "???", "text": e["text"] if seen else "Questo papiro è ancora sigillato.", "seen": seen}


static func count_seen() -> Vector2i:
	var seen := 0
	var total := 0
	for cat in codex():
		for e in cat["entries"]:
			total += 1
			if e["seen"]:
				seen += 1
	return Vector2i(seen, total)
