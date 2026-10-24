class_name Dialogue
## Le battute di Anubi nella Sala del Giudizio.
## Ogni battuta ha un id (per ricordarsi che è già stata detta) e una condizione.
## Anubi dice la prima battuta non ancora ascoltata la cui condizione è vera;
## se le ha già dette tutte, ne ripete una a caso tra quelle "sempre".

## Commento al ritorno da una discesa: cambia in base a com'è finita.
static func return_comment() -> Array:
	match Meta.last_end:
		"room":
			if Meta.last_room <= 2:
				return ["Di nuovo qui, e così presto. Il Duat non perdona chi corre senza guardare.", "Le trappole hanno occhi che si accendono. Le mummie diventano rosse. Tutto ti avvisa, Scriba. Ascolta."]
			return ["Sei arrivato alla stanza %d. Più lontano di quanto credessi, meno di quanto serva." % Meta.last_room]
		"ammit":
			return ["Ammit ti ha assaggiato. Non le sei piaciuto abbastanza da finirti, a quanto pare.", "Le colonne la stordiscono, ma crollano. Usale bene: sono poche."]
		"win":
			return ["Hai abbattuto la Divoratrice. Non succedeva da molto tempo.", "Il suo Sekhem ora scorre in te. Quando sarà pieno, lasciati diventare ciò che eri."]
		"abandon":
			return ["Te ne sei andato a metà strada. Il Duat ricorda anche questo."]
	return []


## Battute della storia, in ordine. "if" è la condizione per poterla dire.
static func story() -> Array:
	return [
		{"id": "intro1", "if": Meta.runs == 0, "lines": [
			"Svegliati, Scriba. Sì, dico a te. Sei morto.",
			"Io sono Anubi. Peso i cuori dei morti contro la piuma di Ma'at. Il tuo, però, non posso pesarlo.",
			"Qualcuno ha scalpellato il tuo nome da ogni tempio. Senza nome il cuore non ha peso, e senza peso non c'è giudizio.",
			"Ma'at ti concede un'occasione: segui la barca di Ra attraverso le dodici ore della notte. Ritrova il tuo nome prima dell'alba.",
			"Il cancello è a nord. Quando cadrai, e cadrai, ti riporterò qui."]},
		{"id": "book1", "if": Meta.runs >= 1 and Meta.chapters_unlocked.is_empty(), "lines": [
			"Vedi quel leggio? È il Libro dei Morti. Ogni capitolo è un incantesimo che ti protegge laggiù.",
			"Costano Ka, l'energia che raccogli nel Duat. Non te lo regalo: te lo guadagni."]},
		{"id": "deaths3", "if": Meta.runs >= 3 and Meta.ammit_wins == 0, "lines": [
			"Tre volte giù, tre volte su. Gli dèi cominciano a parlare di te.",
			"Set ti offrirà dei patti. Diffida, ma non troppo: lui è l'unico che combatte Apophis ogni notte."]},
		{"id": "name1", "if": Meta.ammit_wins >= 1, "lines": [
			"Dopo la tua vittoria ho guardato nel cuore che non so pesare. C'è un frammento di nome, inciso male.",
			"Un geroglifico solo. Non basta per leggerlo. Ma prima non c'era nulla.",
			"Il Libro dei Morti ora ti concede un capitolo in più. E Ammit ti ha lasciato il suo Sekhem."]},
		{"id": "deaths8", "if": Meta.runs >= 8, "lines": [
			"Sai qual è la cosa strana, Scriba? Ogni volta che torni, la bilancia trema. Come se avesse paura di te.",
			"Non chiedermi perché. Non lo so. E io so quasi tutto."]},
	]


## Battute generiche, quando la storia per ora non ha altro da dire.
static func idle() -> Array:
	return [
		["La piuma di Ma'at non pesa nulla. Eppure nessuno riesce a spostarla."],
		["Thoth dice che sei uno scriba. Io dico che scrivi male: il tuo nome non si legge più."],
		["Gli scarabei non lasciano Ka. Non perdere tempo a inseguirli, pensa alle mummie."],
		["Quando un dio ti offre un dono pesante, guarda prima il prezzo. Poi guardalo di nuovo."],
		["Il cancello è sempre aperto. Il Duat ha fame."],
	]


## Cosa dice Anubi adesso. Segna come ascoltate le battute della storia.
static func next_lines(already_commented: bool) -> Array:
	var out := []
	if not already_commented:
		out.append_array(return_comment())
	for b in story():
		if b["if"] and not Meta.dialogue_seen.has(b["id"]):
			Meta.dialogue_seen.append(b["id"])
			Meta.save()
			out.append_array(b["lines"])
			return out
	if out.is_empty():
		out.append_array(idle().pick_random())
	return out
