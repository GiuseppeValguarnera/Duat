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
					"Così presto, Scriba. Il Duat non concede nulla a chi corre senza guardare.",
					"Sei tornato prima che la sabbia della clessidra si posasse. Rialzati.",
					"Il tuo cuore è caduto vicino alla soglia. Non è una vergogna. Restare a terra lo sarebbe.",
				])]
			return [_pick([
				"Stanza %d. Più lontano di quanto credessi. Meno di quanto serva." % Meta.last_room,
				"Sei giunto alla stanza %d. Il Duat comincia a riconoscere il tuo passo." % Meta.last_room,
			])]
		"ammit":
			return [_pick([
				"Hai visto la Divoratrice in volto. Pochi morti possono dirlo, e nessuno lo ha mai raccontato.",
				"Ammit ti ha assaggiato, e ti ha risputato. Non eri ancora pronto per lei.",
			]), "Le colonne la stordiscono, ma crollano. Usale con saggezza: sono poche."]
		"win":
			if Meta.ammit_wins <= 1:
				return ["La Divoratrice è caduta. Da secoli nessun morto alzava la mano contro di lei.", "Il suo Sekhem ora scorre in te. Quando sarà colmo, lascia che ti trasformi."]
			return [_pick([
				"Ammit è caduta di nuovo. La bilancia ha tremato, stanotte.",
				"Un'altra vittoria. Ma'at ha guardato due volte il tuo cuore.",
			])]
		"abandon":
			return ["Hai lasciato il cammino a metà. Il Duat ricorda chi si volta indietro.", "Non ti biasimo. Ma ti peso, e la bilancia annota anche questo."]
	return []


## 2. Una reazione a qualcosa che è successo nella discesa (una sola, scelta a caso).
static func _reaction() -> Array:
	var options := []
	if Meta.last_end in ["room", "ammit"]:
		match Meta.last_killer:
			"trappola":
				options.append("Una trappola ti ha fermato. Nelle tombe dei re i costruttori scavavano pozzi profondi, sbarravano i corridoi con blocchi di granito, dipingevano porte che non si aprivano. Erano per i ladri. Non per te. Eppure.")
			"mummy":
				options.append("Una mummia. Settanta giorni di cure, di preghiere, di bende di lino, e ora vaga nel buio piena d'ira. Non portarle rancore. Non ricorda più chi era. Come te.")
			"scarab":
				options.append("Gli scarabei. Gli uomini li veneravano: lo scarabeo che spinge la sua sfera era il sole che rinasce. Questi non rinascono. Divorano.")
			"priest":
				options.append("Un sacerdote. In vita servì gli dèi, nel Duat serve il caos. Colpiscilo prima che la sua preghiera sia compiuta.")
	var gods := {
		"ra": "Porti addosso l'odore della fiamma. Ra ti ha guardato con favore. Il suo favore brucia, Scriba. Ricordalo.",
		"sekhmet": "Sekhmet ti ha prestato la sua ira. L'ultima volta che la scatenò davvero, servì un fiume di birra rossa per placarla.",
		"thoth": "Thoth ha scritto di te nei suoi registri. Non il tuo nome vero. Quello che ti stai guadagnando.",
		"bastet": "Hai camminato con Bastet. È una dea che sceglie chi proteggere. Non sceglie mai a caso.",
		"sobek": "Sobek ti ha dato la sua pelle. Lui sa attendere per ore, immobile sotto l'acqua. Tu non sai attendere un istante. Imparerai.",
		"iside": "Iside ti ha posato le mani sul capo. Lei conosce il dolore di raccogliere ciò che è stato spezzato. Anche te.",
	}
	if gods.has(Meta.last_god):
		options.append(gods[Meta.last_god])
	if Meta.last_pacts > 0:
		options.append("Hai stretto patti con Set. Set mantiene sempre la parola data. È la parola, Scriba, che dovresti leggere meglio.")
	if options.is_empty():
		return []
	return [options.pick_random()]


## 3. La storia: battute in ordine, ognuna con la sua condizione, dette una volta sola.
static func story() -> Array:
	return [
		{"id": "intro1", "if": Meta.runs == 0, "lines": [
			"Apri gli occhi, Scriba.",
			"Sei morto. Lo sai già, credo. Lo si sente nelle ossa.",
			"Io sono Anubi, Signore della Terra Sacra, custode della bilancia. Ogni notte peso il cuore dei morti contro la piuma di Ma'at. Il tuo non posso pesarlo.",
			"Qualcuno ha scalpellato il tuo nome da ogni pietra d'Egitto. Senza nome il cuore non ha peso. Senza peso, non c'è giudizio.",
			"Ma'at ti concede una via: segui la barca di Ra attraverso le dodici ore della notte, e ritrova il tuo nome prima dell'alba.",
			"Il cancello è a settentrione. Quando cadrai, e cadrai, io ti riporterò qui."]},
		{"id": "book1", "if": Meta.runs >= 1 and Meta.chapters_unlocked.is_empty(), "lines": [
			"Quel leggio custodisce il Libro dei Morti. Ogni capitolo è una formula che ti protegge nel buio.",
			"Si pagano in Ka, la forza vitale che strappi al Duat. Gli dèi non regalano nulla. Nemmeno io."]},
		{"id": "chapter1", "if": not Meta.chapters_unlocked.is_empty(), "lines": [
			"Il tuo primo capitolo. I potenti si facevano dipingere papiri lunghi quanto una barca del Fiume. Quello dello scriba Ani è tra i più belli mai tracciati: lo vedo riposare in una terra straniera, oltre il mare, sotto gli occhi di mille sconosciuti.",
			"Tu cominci da una pagina. Anche Ani cominciò da una pagina."]},
		{"id": "papiri1", "if": Meta.runs >= 2, "lines": [
			"In fondo alla sala riposano i Papiri di Thoth.",
			"Ogni parola che gli dèi ti rivolgono, Thoth la copia e la ripone lì. Leggili.",
			"Un dio che parla di sé rivela sempre più di quanto vorrebbe."]},
		{"id": "deaths3", "if": Meta.runs >= 3 and Meta.ammit_wins == 0, "lines": [
			"Tre volte sei disceso, tre volte sei tornato. Gli dèi hanno cominciato a pronunciare il tuo passo.",
			"Set ti offrirà patti. Diffida di lui, ma non disprezzarlo: è il solo che ogni notte affronta Apophis a viso aperto."]},
		{"id": "deaths5", "if": Meta.runs >= 5 and Meta.ammit_wins == 0, "lines": [
			"Ogni notte migliaia di morti mi passano davanti. Nessuno è mai tornato indietro.",
			"Tu torni. Ho smesso di domandarmi perché. Ora mi domando chi sei."]},
		{"id": "name1", "if": Meta.ammit_wins >= 1, "lines": [
			"Dopo la tua vittoria ho guardato dentro il cuore che non so pesare. Vi ho trovato un segno, inciso male, quasi cancellato.",
			"Un solo geroglifico: una canna fiorita. Non basta a leggere un nome. Ma prima, lì, non c'era nulla.",
			"Il Libro dei Morti ora ti concede un capitolo in più. E Ammit ti ha lasciato il suo Sekhem."]},
		{"id": "deaths8", "if": Meta.runs >= 8, "lines": [
			"Ogni volta che torni, Scriba, la bilancia trema. Come se avesse timore di te.",
			"Non so il perché. E io conosco quasi ogni cosa."]},
		{"id": "name2", "if": Meta.ammit_wins >= 2, "lines": [
			"Un altro segno del tuo nome è riaffiorato: dopo la canna, l'acqua. Due geroglifici.",
			"Thoth dice che potrebbero essere l'inizio di cento nomi diversi. Thoth dice sempre così, quando non sa."]},
		{"id": "deaths12", "if": Meta.runs >= 12, "lines": [
			"Ho interrogato Ma'at, su di te. Non mi ha risposto.",
			"In quattromila anni non era mai accaduto."]},
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
		["La piuma di Ma'at non pesa nulla. Eppure nessuno è mai riuscito a smuoverla."],
		["Thoth dice che sei uno scriba. Il tuo nome, però, nessuno sa più leggerlo."],
		["Gli scarabei non portano Ka. Non sprecare il tuo tempo con loro."],
		["Quando un dio ti offre un dono pesante, guarda il prezzo. Poi guardalo ancora."],
		["Il cancello è sempre aperto. Il Duat ha sempre fame."],
		["Se cerchi parole, i Papiri di Thoth sono in fondo alla sala."],
	]


## Cosa dice Anubi adesso. `first_talk` è true la prima volta che gli parli in questa visita.
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
