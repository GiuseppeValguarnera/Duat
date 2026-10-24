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
					"Di nuovo qui, e così presto. Il Duat non perdona chi corre senza guardare.",
					"Sei tornato prima che finissi di lucidare la bilancia. Un record, credo.",
					"Così presto? Le mummie stanno ancora ridendo.",
				])]
			return [_pick([
				"Stanza %d. Più lontano di quanto pensassi, meno di quanto serva." % Meta.last_room,
				"Sei arrivato alla stanza %d. Il Duat comincia a ricordarsi di te." % Meta.last_room,
			])]
		"ammit":
			return [_pick([
				"Ammit ti ha assaggiato. Non le sei piaciuto abbastanza da finirti, a quanto pare.",
				"Arrivare davanti ad Ammit è già più di quanto riesca alla maggior parte dei morti. Ma non basta.",
			]), "Le colonne la stordiscono, ma crollano. Usale bene: sono poche."]
		"win":
			if Meta.ammit_wins <= 1:
				return ["Hai abbattuto la Divoratrice. Non succedeva da molto, molto tempo.", "Il suo Sekhem ora scorre in te. Quando sarà pieno, lasciati diventare ciò che eri."]
			return [_pick([
				"Ammit di nuovo a terra. Comincia a prenderla sul personale.",
				"Un'altra vittoria. Ma'at ha guardato la bilancia due volte, stanotte.",
			])]
		"abandon":
			return ["Te ne sei andato a metà strada. Il Duat ricorda anche questo.", "Non ti giudico. Cioè, sì, ti giudico: è il mio lavoro."]
	return []


## 2. Una reazione a qualcosa che è successo nella discesa (una sola, scelta a caso).
static func _reaction() -> Array:
	var options := []
	if Meta.last_end in ["room", "ammit"]:
		match Meta.last_killer:
			"trappola":
				options.append("Una trappola. Nelle piramidi c'erano pozzi profondi, corridoi chiusi con blocchi di granito e porte finte, per fermare i ladri di tombe. Non per te. Eppure eccoti qui.")
			"mummy":
				options.append("Una mummia. Settanta giorni di cure per finire a vagare arrabbiata nel Duat. Non prenderla sul personale: ce l'hanno con tutti.")
			"scarab":
				options.append("Gli scarabei. Gli Egizi li adoravano: lo scarabeo che spinge la sua pallina era il sole che rinasce. Questi però non rinascono. Mordono.")
			"priest":
				options.append("Un sacerdote. In vita servivano gli dèi, qui sotto servono il caos. Colpiscili prima che finiscano di pregare.")
	var gods := {
		"ra": "Puzzi di fumo. Ra ti ha preso in simpatia. Ra prende in simpatia chiunque bruci qualcosa.",
		"sekhmet": "Sekhmet ti ha dato la sua furia. Attento: l'ultima volta che si è arrabbiata davvero, ci è voluto un lago di birra per fermarla.",
		"thoth": "Thoth ti osserva con attenzione. Non so se sia un complimento: osserva con attenzione anche le formiche.",
		"bastet": "Hai camminato con Bastet. Ti ha già graffiato? Lo fa solo con chi le piace.",
		"sobek": "Sobek. Un dio paziente: aspetta immobile sott'acqua per ore. Tu invece corri sempre. Forse avete qualcosa da insegnarvi.",
		"iside": "Iside ti ha protetto. Lei sa cosa vuol dire raccogliere i pezzi di qualcuno. Anche i tuoi.",
	}
	if gods.has(Meta.last_god):
		options.append(gods[Meta.last_god])
	if Meta.last_pacts > 0:
		options.append("Hai stretto patti con Set. Set mantiene sempre la parola. Il problema è cosa dice, la parola.")
	if options.is_empty():
		return []
	return [options.pick_random()]


## 3. La storia: battute in ordine, ognuna con la sua condizione, dette una volta sola.
static func story() -> Array:
	return [
		{"id": "intro1", "if": Meta.runs == 0, "lines": [
			"Svegliati, Scriba. Sì, dico a te. Sei morto.",
			"Io sono Anubi. Peso i cuori dei morti contro la piuma di Ma'at. Il tuo, però, non posso pesarlo.",
			"Qualcuno ha scalpellato il tuo nome da ogni tempio. Senza nome il cuore non ha peso, e senza peso non c'è giudizio.",
			"Ma'at ti concede un'occasione: segui la barca di Ra attraverso le dodici ore della notte, e ritrova il tuo nome prima dell'alba.",
			"Il cancello è a nord. Quando cadrai, e cadrai, ti riporterò qui."]},
		{"id": "book1", "if": Meta.runs >= 1 and Meta.chapters_unlocked.is_empty(), "lines": [
			"Vedi quel leggio? È il Libro dei Morti. Ogni capitolo è una formula che ti protegge laggiù.",
			"Costano Ka, la forza vitale che raccogli nel Duat. Non te lo regalo: te lo guadagni."]},
		{"id": "chapter1", "if": not Meta.chapters_unlocked.is_empty(), "lines": [
			"Il tuo primo capitolo. I ricchi si facevano scrivere papiri lunghi più di venti metri: quello dello scriba Ani è uno dei più belli, e oggi sta in un museo di Londra.",
			"Tu cominci da una pagina. Va bene così. Anche Ani ha cominciato da una pagina."]},
		{"id": "papiri1", "if": Meta.runs >= 2, "lines": [
			"Hai visto gli scaffali in fondo alla sala? Sono i Papiri di Thoth.",
			"Ogni volta che un dio ti racconta qualcosa, Thoth ne lascia una copia lì. Leggili, ogni tanto.",
			"Un dio che parla di sé dice sempre un po' di più di quanto vorrebbe."]},
		{"id": "deaths3", "if": Meta.runs >= 3 and Meta.ammit_wins == 0, "lines": [
			"Tre volte giù, tre volte su. Gli dèi cominciano a parlare di te.",
			"Set ti offrirà dei patti. Diffida, ma non troppo: è l'unico che ogni notte combatte Apophis sulla barca di Ra."]},
		{"id": "deaths5", "if": Meta.runs >= 5 and Meta.ammit_wins == 0, "lines": [
			"Sai quanti morti mi passano davanti ogni notte? Migliaia. Nessuno torna indietro.",
			"Tu sì. Ho smesso di chiedermi perché, e ho cominciato a chiedermi chi."]},
		{"id": "name1", "if": Meta.ammit_wins >= 1, "lines": [
			"Dopo la tua vittoria ho guardato nel cuore che non so pesare. C'è un frammento di nome, inciso male.",
			"Un geroglifico solo: una canna fiorita. Non basta per leggerlo. Ma prima non c'era nulla.",
			"Il Libro dei Morti ora ti concede un capitolo in più. E Ammit ti ha lasciato il suo Sekhem."]},
		{"id": "deaths8", "if": Meta.runs >= 8, "lines": [
			"Sai qual è la cosa strana, Scriba? Ogni volta che torni, la bilancia trema. Come se avesse paura di te.",
			"Non chiedermi perché. Non lo so. E io so quasi tutto."]},
		{"id": "name2", "if": Meta.ammit_wins >= 2, "lines": [
			"Un altro segno del tuo nome: dopo la canna, l'acqua. Due geroglifici.",
			"Thoth dice che potrebbe essere l'inizio di cento nomi diversi. Thoth dice sempre cose del genere."]},
		{"id": "deaths12", "if": Meta.runs >= 12, "lines": [
			"Ho fatto una domanda a Ma'at, su di te. Non ha risposto.",
			"In quattromila anni non era mai successo."]},
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
		["La piuma di Ma'at non pesa nulla. Eppure nessuno è mai riuscito a spostarla."],
		["Thoth dice che sei uno scriba. Io dico che scrivi male: il tuo nome non si legge più."],
		["Gli scarabei non lasciano Ka. Non perdere tempo a inseguirli."],
		["Quando un dio ti offre un dono pesante, guarda il prezzo. Poi guardalo di nuovo."],
		["Il cancello è sempre aperto. Il Duat ha sempre fame."],
		["Se cerchi qualcosa da leggere, i Papiri di Thoth sono in fondo alla sala."],
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
