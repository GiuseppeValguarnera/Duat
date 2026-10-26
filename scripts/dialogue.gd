class_name Dialogue
## Cosa dice Anubi nella Sala del Giudizio.
##
## La prima volta che gli parli dopo una discesa:
##   1. commenta com'è finita (morte presto, morte avanti, Ammit, vittoria, abbandono);
##   2. aggiunge una reazione a qualcosa che hai fatto: chi ti ha ucciso, il dio che hai
##      seguito di più, i patti con Set;
##   3. racconta il prossimo pezzo della storia, se ce n'è uno sbloccato.
## Se gli parli ancora, ti insegna qualcosa sul giudizio dei morti (Lore.JUDGEMENT);
## quando ha detto tutto, risponde con una frase breve.

static func _pick(lines: Array) -> String:
	return lines.pick_random()


## 1. Commento su com'è finita l'ultima discesa.
static func _ending() -> Array:
	match Meta.last_end:
		"room":
			if Meta.last_room <= 2:
				return [_pick([
					Lang.t("Così presto, Scriba. Il Duat non concede nulla a chi corre senza guardare."),
					Lang.t("Sei tornato prima che la sabbia della clessidra si posasse. Rialzati."),
					Lang.t("Il tuo cuore è caduto vicino alla soglia. Non è una vergogna. Restare a terra lo sarebbe."),
				])]
			return [_pick([
				Lang.t("Stanza %d. Più lontano di quanto credessi. Meno di quanto serva.") % Meta.last_room,
				Lang.t("Sei giunto alla stanza %d. Il Duat comincia a riconoscere il tuo passo.") % Meta.last_room,
			])]
		"ammit":
			return [_pick([
				Lang.t("Hai visto Am-heh in volto. Il Divoratore di Milioni ha contato anche te, stanotte."),
				Lang.t("Il lago di fuoco ti ha restituito. Am-heh non restituisce mai nulla due volte."),
			]), Lang.t("Il fuoco non entra nell'acqua. Quando ulula, cerca una pozza. E quando si ferma a riprendere fiato, colpisci.")]
		"win":
			if Meta.ammit_wins <= 1:
				return [Lang.t("Am-heh è caduto. Il Divoratore di Milioni ha contato i dannati per mille anni, e stanotte ha perso il conto."), Lang.t("Il suo Sekhem ora scorre in te. Quando sarà colmo, lascia che ti trasformi."), Lang.t("Ma la Prima Ora è solo l'inizio. Ammit, la vera Divoratrice, ti aspetta in fondo alla notte, accanto alla mia bilancia.")]
			return [_pick([
				Lang.t("Am-heh è caduto di nuovo. La bilancia ha tremato, stanotte."),
				Lang.t("Un'altra vittoria. Ma'at ha guardato due volte il tuo cuore."),
			])]
		"abandon":
			return [Lang.t("Hai lasciato il cammino a metà. Il Duat ricorda chi si volta indietro."), Lang.t("Non ti biasimo. Ma ti peso, e la bilancia annota anche questo.")]
	return []


## 2. Una reazione a qualcosa che è successo nella discesa (una sola, scelta a caso).
static func _reaction() -> Array:
	var options := []
	if Meta.last_end in ["room", "ammit"]:
		match Meta.last_killer:
			"trappola":
				options.append(Lang.t("Una trappola ti ha fermato. Nelle tombe dei re i costruttori scavavano pozzi profondi, sbarravano i corridoi con blocchi di granito, dipingevano porte che non si aprivano. Erano per i ladri. Non per te. Eppure."))
			"mummy":
				options.append(Lang.t("Una mummia. Settanta giorni di cure, di preghiere, di bende di lino, e ora vaga nel buio piena d'ira. Non portarle rancore. Non ricorda più il suo nome. Senza il tuo re, presto lo dimenticherai anche tu."))
			"scarab":
				options.append(Lang.t("Gli scarabei. Gli uomini li veneravano: lo scarabeo che spinge la sua sfera era il sole che rinasce. Questi non rinascono. Divorano."))
			"priest":
				options.append(Lang.t("Un sacerdote. In vita servì gli dèi, nel Duat serve il caos. Colpiscilo prima che la sua preghiera sia compiuta."))
			"serpent":
				options.append(Lang.t("Il Serpente della Porta. Ogni porta del Duat sta sul fiume della notte, e ha il suo guardiano. Quando si immerge, guarda la scia nell'acqua: ti sta cercando. Poi guarda il cerchio: è lì che tornerà."))
			"crocodile":
				options.append(Lang.t("Un coccodrillo. Il Libro ha due formule apposta, la trentuno e la trentadue: i coccodrilli del Duat vengono a rubare la magia del morto. Quando l'acqua ribolle vicino a te, non restare sul bordo."))
			"scorpion":
				options.append(Lang.t("Gli scorpioni di Serket. La dea protegge dal veleno chi la onora. Tu non l'hai onorata. Quando la coda si accende, allontanati."))
			"grata":
				options.append(Lang.t("Una grata di fuoco. Nelle acque di Wernes il fuoco di Am-heh corre anche sotto le pietre. Quando le sbarre si arroventano, non aspettare di capire perché."))
			"olio":
				options.append(Lang.t("L'olio in fiamme. Nelle tombe le giare custodivano l'olio per le lampade del morto. Tu le usi per altro. Anche il fuoco, però, non sceglie chi bruciare."))
			"amheh", "amheh_fuoco", "amheh_marea":
				options.append(Lang.t("Am-heh. Il Libro lo chiama 'colui che divora milioni', e dice che vive in un lago di fuoco nel Duat. Nessun morto ci si bagna due volte. Tu sì, a quanto pare."))
			"cobra":
				options.append(Lang.t("Un cobra. L'ureo sulla fronte del faraone sputava fuoco sui suoi nemici. Questi sputano veleno, e si nascondono. Colpiscili quando alzano il cappuccio."))
	var gods := {
		"ra": Lang.t("Porti addosso l'odore della fiamma. Ra ti ha guardato con favore. Il suo favore brucia, Scriba. Ricordalo."),
		"sekhmet": Lang.t("Sekhmet ti ha prestato la sua ira. L'ultima volta che la scatenò davvero, servì un fiume di birra rossa per placarla."),
		"thoth": Lang.t("Thoth ha scritto di te nei suoi registri. Non il tuo nome vero. Quello che ti stai guadagnando."),
		"bastet": Lang.t("Hai camminato con Bastet. È una dea che sceglie chi proteggere. Non sceglie mai a caso."),
		"sobek": Lang.t("Sobek ti ha dato la sua pelle. Lui sa attendere per ore, immobile sotto l'acqua. Tu non sai attendere un istante. Imparerai."),
		"horus": Lang.t("Horus ti ha prestato il suo Occhio. Il falco sceglie con cura a chi affidarlo: non deluderlo."),
		"iside": Lang.t("Iside ti ha posato le mani sul capo. Lei conosce il dolore di raccogliere ciò che è stato spezzato. Anche te."),
	}
	if gods.has(Meta.last_god):
		options.append(gods[Meta.last_god])
	if Meta.last_pacts > 0:
		options.append(Lang.t("Hai stretto patti con Set. Set mantiene sempre la parola data. È la parola, Scriba, che dovresti leggere meglio."))
	if options.is_empty():
		return []
	return [options.pick_random()]


## 3. La storia: battute in ordine, ognuna con la sua condizione, dette una volta sola.
static func story() -> Array:
	return [
		{"id": "intro1", "if": Meta.runs == 0, "lines": [
			Lang.t("Apri gli occhi, Scriba."),
			Lang.t("Sei morto. Lo sai già, credo. Lo si sente nelle ossa."),
			Lang.t("Io sono Anubi, Signore della Terra Sacra, custode della bilancia. Ogni notte peso il cuore dei morti contro la piuma di Ma'at. Il tuo non posso pesarlo."),
			Lang.t("Servivi un re, il faraone Akhet. Qualcuno ha scalpellato il suo nome da ogni pietra d'Egitto. E dove c'era il suo nome c'era anche il tuo, accanto, in ogni rotolo che hai scritto per lui."),
			Lang.t("Senza nome il cuore non ha peso. Senza peso, non c'è giudizio."),
			Lang.t("Ma'at ti concede una via: segui la barca di Ra attraverso le dodici ore della notte, e ricomponi il nome del tuo re prima che sia dimenticato per sempre."),
			Lang.t("Il cancello è a settentrione. Quando cadrai, e cadrai, io ti riporterò qui.")]},
		{"id": "book1", "if": Meta.runs >= 1 and Meta.chapter_levels.is_empty(), "lines": [
			Lang.t("Quel leggio custodisce il Libro dei Morti. Ogni capitolo è una formula che ti protegge nel buio."),
			Lang.t("Si pagano in Ka, la forza vitale che strappi al Duat. Gli dèi non regalano nulla. Nemmeno io.")]},
		{"id": "chapter1", "if": not Meta.chapter_levels.is_empty(), "lines": [
			Lang.t("Il tuo primo capitolo. I potenti si facevano dipingere papiri lunghi quanto una barca del Fiume. Quello dello scriba Ani è tra i più belli mai tracciati: lo vedo riposare in una terra straniera, oltre il mare, sotto gli occhi di mille sconosciuti."),
			Lang.t("Tu cominci da una pagina. Anche Ani cominciò da una pagina.")]},
		{"id": "papiri1", "if": Meta.runs >= 2, "lines": [
			Lang.t("In fondo alla sala riposano i Papiri di Thoth."),
			Lang.t("Ogni parola che gli dèi ti rivolgono, Thoth la copia e la ripone lì. Leggili."),
			Lang.t("Un dio che parla di sé rivela sempre più di quanto vorrebbe.")]},
		{"id": "casa0", "if": Meta.lapis >= 10 and not Meta.casa, "lines": [
			Lang.t("Porti lapislazzuli. La pietra del cielo notturno: gli dèi hanno i capelli fatti di questa pietra."),
			Lang.t("Vedi la porta murata a oriente? Dietro c'è la Casa della Vita, dove gli scribi copiavano i libri sacri. Con quaranta pietre lo scalpellino la riaprirà."),
			Lang.t("Dentro troverai amuleti, e un maestro. Parla molto più di me. Molto più di me.")]},
		{"id": "casa1", "if": Meta.casa, "lines": [
			Lang.t("Hai riaperto la Casa della Vita. Ho sentito Imhotep parlare fin da qui."),
			Lang.t("Fu un uomo, poi gli uomini ne fecero un dio. Non tutti gli dèi del Duat lo hanno perdonato. Io sì: le sue piramidi hanno reso il mio lavoro più ordinato.")]},
		{"id": "sfide1", "if": Meta.casa and Challenges.to_claim() > 0, "lines": [
			Lang.t("Thoth ha inciso una tua impresa sulla parete della Casa della Vita. I premi del Duat non si consegnano da soli, Scriba. Va' a prenderlo.")]},
		{"id": "lago1", "if": Meta.last_end == "ammit" or Meta.ammit_wins >= 1, "lines": [
			Lang.t("Ti sei chiesto perché il Divoratore viva nell'acqua e sputi fuoco. Non vive nell'acqua. Vive nel Lago di Fuoco."),
			Lang.t("Per il morto giusto quel lago è acqua fresca. Per il dannato è fiamma. Lo stesso lago, due nature: dipende da chi vi entra."),
			Lang.t("Le pozze della sua arena sono la parte del lago che ti riconosce ancora come giusto. Il fuoco non le tocca. Finché ti riconoscono, Scriba.")]},
		{"id": "deaths3", "if": Meta.runs >= 3 and Meta.ammit_wins == 0, "lines": [
			Lang.t("Tre volte sei disceso, tre volte sei tornato. Gli dèi hanno cominciato a parlare di te, a bassa voce."),
			Lang.t("Set ti offrirà patti. Diffida di lui, ma non disprezzarlo: è il solo che ogni notte affronta Apophis a viso aperto.")]},
		{"id": "deaths5", "if": Meta.runs >= 5 and Meta.ammit_wins == 0, "lines": [
			Lang.t("Ogni notte migliaia di morti mi passano davanti. Nessuno è mai tornato indietro."),
			Lang.t("Tu torni. Ho smesso di domandarmi perché. Ora mi domando chi sei.")]},
		{"id": "name1", "if": Meta.ammit_wins >= 1, "lines": [
			Lang.t("Guarda il cartiglio sopra il cancello. Era vuoto: dopo la tua vittoria un segno è riaffiorato, inciso male, quasi cancellato."),
			Lang.t("Un ibis con la cresta: lo spirito luminoso, l'akh. È l'inizio del nome di Akhet. Prima, lì, non c'era nulla."),
			Lang.t("Il Libro dei Morti ora ti concede un capitolo in più. E Am-heh ti ha lasciato il suo Sekhem.")]},
		{"id": "pesi1", "if": Meta.ammit_wins >= 1 and Meta.dialogue_seen.has("name1"), "lines": [
			Lang.t("Ora che hai abbattuto il Divoratore di Milioni, la bilancia ti riconosce. Puoi posarvi dei pesi, prima di scendere."),
			Lang.t("Ogni peso rende il cammino più duro. Ma il Duat paga chi sceglie di soffrire: più pesante è il tuo cuore, più Ka porterai indietro."),
			Lang.t("Non c'è vergogna nel cuore leggero. C'è gloria nel cuore che pesa e passa ugualmente.")]},
		{"id": "lacrime1", "if": Meta.tears > 0, "lines": [
			Lang.t("Porti con te una Lacrima di Iside. Quando pianse Osiride, le sue lacrime gonfiarono il Fiume, e il Fiume ricoprì la Terra Nera."),
			Lang.t("Ogni lacrima vale più di mille Ka. Neith sa cosa farne: nel suo cortile le armi si risvegliano solo con il pianto di una dea.")]},
		{"id": "livelli1", "if": Meta.chapter_levels.values().any(func(v): return int(v) >= 2), "lines": [
			Lang.t("Hai ripassato la stessa formula due volte. Bene. Gli scribi copiavano lo stesso capitolo per anni, finché la mano non lo sapeva da sola."),
			Lang.t("Una formula detta bene vale più di dieci dette in fretta.")]},
		{"id": "deaths8", "if": Meta.runs >= 8, "lines": [
			Lang.t("Ogni volta che torni, Scriba, la bilancia trema. Come se avesse timore di te."),
			Lang.t("Non so il perché. E io conosco quasi ogni cosa.")]},
		{"id": "name2", "if": Meta.ammit_wins >= 2, "lines": [
			Lang.t("Un altro segno è tornato nel cartiglio del tuo re: dopo l'ibis, un cerchio segnato da linee. Due geroglifici."),
			Lang.t("Thoth dice che potrebbero essere l'inizio di cento nomi diversi. Thoth dice sempre così, quando non sa.")]},
		{"id": "deaths12", "if": Meta.runs >= 12, "lines": [
			Lang.t("Ho interrogato Ma'at, su di te. Non mi ha risposto."),
			Lang.t("In quattromila anni non era mai accaduto.")]},
		{"id": "name3", "if": Meta.ammit_wins >= 3, "lines": [
			Lang.t("Il terzo segno: un pane. Ibis, cerchio, pane. Il nome si legge quasi, ma un segno manca ancora."),
			Lang.t("Thoth dice che l'ultimo segno torna solo quando la notte finisce. Poi tace. È peggio di quando dice che non sa.")]},
		{"id": "deaths20", "if": Meta.runs >= 20, "lines": [
			Lang.t("Venti discese. I guardiani delle porte hanno smesso di chiedermi chi sei. Ti chiamano 'quello che torna'."),
			Lang.t("Non è un nome. Ma è più di quanto avevi.")]},
		{"id": "name4", "if": Meta.ammit_wins >= 5, "lines": [
			Lang.t("Cinque volte Am-heh è caduto, e l'ultimo segno non torna."),
			Lang.t("Chiunque abbia cancellato Akhet, Scriba, aveva molta paura di lui. O lo amava molto. Non so dire quale delle due.")]},
	]


static func _next_story() -> Array:
	for b in story():
		if b["if"] and not Meta.dialogue_seen.has(b["id"]):
			Meta.dialogue_seen.append(b["id"])
			Meta.save()
			return b["lines"]
	return []


## Frasi brevi per quando Anubi non ha più niente di nuovo da dire.
static func idle() -> Array:
	return [
		[Lang.t("La piuma di Ma'at non pesa nulla. Eppure nessuno è mai riuscito a smuoverla.")],
		[Lang.t("Thoth dice che sei uno scriba. Il tuo nome, però, nessuno sa più leggerlo.")],
		[Lang.t("Gli scarabei non portano Ka. Non sprecare il tuo tempo con loro.")],
		[Lang.t("Quando un dio ti offre un dono pesante, guarda il prezzo. Poi guardalo ancora.")],
		[Lang.t("Il cancello è sempre aperto. Il Duat ha sempre fame.")],
		[Lang.t("Se cerchi parole, i Papiri di Thoth sono in fondo alla sala.")],
		[Lang.t("Ogni porta del Duat ha un guardiano. Ogni guardiano ha un nome. Impara i nomi, e le porte si aprono.")],
		[Lang.t("Il Traghettatore guarda sempre all'indietro. Non chiedergli perché. Paga, e sali.")],
		[Lang.t("Il Ka che non spendi nella discesa torna qui con te. Quello che spendi, ti tiene in vita. Scegli.")],
	]


## Cosa dice Anubi adesso. `first_talk` è true la prima volta che gli parli in questa visita.
## Anubi ha qualcosa di nuovo da dirti? (il punto esclamativo sopra di lui nella Sala)
## `first_talk`: è la prima volta che gli parli in questa visita alla Sala (solo allora racconta
## i pezzi nuovi della storia); le lezioni sul giudizio arrivano a ogni chiacchierata.
static func has_news(first_talk: bool) -> bool:
	if first_talk:
		for b in story():
			if b["if"] and not Meta.dialogue_seen.has(b["id"]):
				return true
	return Lore.has_lesson()


static func next_lines(first_talk: bool) -> Array:
	var out := []
	if first_talk:
		out.append_array(_ending())
		out.append_array(_reaction())
		var beat := _next_story()
		if not beat.is_empty():
			if Meta.runs == 0:
				return beat
			out.append_array(beat)
			return out
	var lesson := Lore.next_lesson()
	if lesson != "":
		out.append(lesson)
	if out.is_empty():
		out.append_array(idle().pick_random())
	return out
