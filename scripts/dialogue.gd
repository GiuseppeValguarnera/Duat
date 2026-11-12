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


## Le battute di Anubi sulla morte, regione per regione e fascia di stanze. Per aggiungere una
## regione basta una voce in più: "bands" = [prima stanza, ultima stanza, frasi], più "guardian"
## (morte contro il guardiano), "boss" (contro il boss), "hazard" (uccisi dal terreno della regione),
## "win" (il boss della regione battuto). "{piano}" diventa la profondità totale (Run.depth).
## Le frasi sono dentro una funzione (non una costante) perché Lang.t le traduca.
const HAZARD_KILLERS := ["fiume", "buca", "falco", "isfet", "spira"]


static func death_table() -> Dictionary:
	return {
		1: {
			"bands": [
				[1, 2, [
					Lang.t("Così presto, Scriba. La sabbia della clessidra non si è ancora posata."),
					Lang.t("Il tuo cuore è caduto sulla soglia. Rialzati: anche il sole cade, ogni sera."),
					Lang.t("Il Duat non concede nulla a chi corre senza guardare."),
				]],
				[3, 10, [
					Lang.t("Piano {piano}. Più lontano di quanto credessi, meno di quanto serva."),
					Lang.t("Piano {piano}. Il Duat comincia a riconoscere il tuo passo."),
					Lang.t("Piano {piano}. Le acque di Wernes sono lente, ma non dimenticano chi le attraversa."),
				]],
			],
			"guardian": [
				Lang.t("Il Serpente della Porta ti ha fermato a metà strada. Ogni porta si apre a chi torna."),
				Lang.t("Piano {piano}. La Porta di mezzo è stretta come una gola. Respira, e riprova."),
				Lang.t("Il guardiano della Porta ti ha respinto. Il fiume della notte è lungo, Scriba: non sei il primo."),
			],
			"boss": [
				Lang.t("Hai visto Am-heh in volto. Il Divoratore di Milioni ha contato anche te, stanotte."),
				Lang.t("Il lago di fuoco ti ha restituito. Am-heh non restituisce mai nulla due volte."),
				Lang.t("Piano {piano}. Il Divoratore ti ha sentito arrivare dall'acqua. La prossima volta arriverai più leggero."),
			],
			"boss_tip": Lang.t("Il fuoco non entra nell'acqua. Quando ulula, cerca una pozza. E quando si ferma a riprendere fiato, colpisci."),
		},
		2: {
			"bands": [
				[1, 3, [
					Lang.t("Piano {piano}. Hai appena lasciato le acque, e il deserto ti ha già bevuto."),
					Lang.t("Le acque di Wernes erano ancora sui tuoi piedi quando la sabbia ti ha preso. Il cammino è lungo, Scriba."),
					Lang.t("Piano {piano}. La sabbia di Sokar non aspetta che tu impari i suoi passi."),
				]],
				[4, 6, [
					Lang.t("Piano {piano}. Nel cuore del deserto il sole non perdona chi si ferma."),
					Lang.t("Sei caduto dove la sabbia è più alta. Lì anche le ombre hanno sete."),
					Lang.t("Piano {piano}. Sokar ti ha guardato a metà del suo regno. I giorni passano: ogni discesa è un passo."),
				]],
				[7, 10, [
					Lang.t("Piano {piano}. L'orizzonte era vicino. La sete, più vicina ancora."),
					Lang.t("Così vicino alla porta del sole. Nel deserto uccide la stanchezza, Scriba, non la sabbia."),
					Lang.t("Piano {piano}. Le notti si allungano, i giorni passano. Hai visto l'orizzonte: tornerai a vederlo."),
				]],
			],
			"guardian": [
				Lang.t("Serket ti ha punto, Scriba. Nella sua mano anche il veleno è una preghiera rovesciata."),
				Lang.t("Il tempio della dea scorpione ti ha trattenuto. Guarda la sabbia, non lei: è la sabbia che parla."),
				Lang.t("Piano {piano}. Serket custodisce il mezzo del deserto, e il mezzo è sempre la parte più lunga."),
			],
			"boss": [
				Lang.t("Aker ti ha guardato con entrambi i volti. Ieri ti ha visto cadere; Domani ti vedrà tornare."),
				Lang.t("Il leone dell'orizzonte non ha fretta. Il sole aspetta da mille anni: può aspettare un'altra notte."),
				Lang.t("Piano {piano}. Sei arrivato alla porta del sole. Il cammino è lungo, ma ora sai dove finisce."),
			],
			"boss_tip": Lang.t("Aker non ha un dietro, ma ha dei fianchi. E dopo ogni grande assalto riprende fiato: è lì che si colpisce."),
			"hazard": [
				Lang.t("Non un nemico, Scriba: la terra stessa. In Sokar anche il suolo ha fame."),
				Lang.t("Ti ha preso il deserto, non una lama. La sabbia nera non odia: inghiotte."),
				Lang.t("Piano {piano}. Le statue del falco vegliano, la sabbia cede, il fiume nero scorre. Il deserto combatte senza mani."),
			],
			"win": [
				Lang.t("Aker è caduto, e il sole ha tremato. Non è ancora sorto, ma ha ricordato la strada."),
				Lang.t("Hai attraversato la terra di Sokar. I giorni passano, Scriba, e tu sei ancora in cammino."),
			],
		},
		3: {
			"bands": [
				[1, 3, [
					Lang.t("Piano {piano}. Hai visto l'acqua nera, e l'acqua nera ha visto te."),
					Lang.t("Nella settima ora anche l'ombra ha un padrone, e non sei tu. Guardati le spalle, Scriba."),
					Lang.t("Piano {piano}. Il caos non combatte: aspetta che tu metta il piede dove ha già aperto la bocca."),
				]],
				[4, 6, [
					Lang.t("Piano {piano}. Dove muore una serpe resta il suo veleno. Scegli dove ucciderle."),
					Lang.t("Sei caduto a metà della caverna, dove il serpente sogna. I suoi sogni hanno i denti."),
					Lang.t("Piano {piano}. La tartaruga si ferma sempre a pancia in su. Aspetta quel momento: la fretta, qui, è una preghiera ad Apopi."),
				]],
				[7, 10, [
					Lang.t("Piano {piano}. Hai sentito il banco di sabbia sotto i piedi. Il serpente ti ha sentito arrivare."),
					Lang.t("Così vicino alla barca arenata. Ra ti ha visto, Scriba: non può parlare, ma ti ha visto."),
					Lang.t("Piano {piano}. Più si scende, più il buio somiglia a qualcuno. Non fermarti a riconoscerlo."),
				]],
			],
			"guardian": [
				Lang.t("Shezmu ti ha spremuto, Scriba. Fa lo stesso vino da quattromila anni, e non gli è mai mancata l'uva."),
				Lang.t("La mannaia torna sempre dal suo padrone. Chi le volta le spalle la sente due volte."),
				Lang.t("Piano {piano}. Il Signore del Torchio carica come un toro e come un toro si ferma: contro il muro."),
			],
			"boss": [
				Lang.t("Apopi ti ha bevuto come beve il fiume. Ma il fiume torna, ogni notte. Anche tu."),
				Lang.t("Hai guardato il caos negli occhi. Pochi lo hanno fatto, e nessuno una volta sola."),
				Lang.t("Piano {piano}. Il serpente non si uccide. Si lega, un nodo per notte. Stanotte il nodo si è sciolto."),
			],
			"boss_tip": Lang.t("Quando beve, cammina contro la corrente e scatta di lato. Quando affonda, il suo muso resta nella sabbia: quello è il tuo momento."),
			"hazard": [
				Lang.t("Non un nemico, Scriba: l'Isfet. Il caos non ha bisogno di mani per prendere ciò che vuole."),
				Lang.t("La caverna respira, e tu eri nel suo respiro. Guarda il pavimento: le crepe dicono dove dorme la spira."),
				Lang.t("Piano {piano}. Le pozze nere hanno occhi. Se le vedi aprirsi, sei già troppo vicino."),
			],
			"win": [
				Lang.t("Apopi è legato, e la barca di Ra è tornata a galla. Per una notte, Scriba, l'ordine ha vinto."),
				Lang.t("Hai attraversato il cuore della notte. Resta una porta sola. La conosci: ci passi davanti ogni volta che torni."),
			],
		},
	}


## La frase con il piano al posto di {piano}.
static func _with_depth(line: String, reg: int, rm: int) -> String:
	return line.replace("{piano}", str(Run.depth(reg, mini(rm, Run.ROOMS_PER_RUN + 1))))


## La battuta di morte per regione, stanza e chi ti ha fermato.
static func death_line(reg: int, rm: int, killer: String, boss: bool) -> Array:
	var table := death_table()
	var t: Dictionary = table.get(reg, table[table.keys().max()])
	if boss:
		var out := [_with_depth(_pick(t["boss"]), reg, rm)]
		if t.has("boss_tip"):
			out.append(t["boss_tip"])
		return out
	if killer in HAZARD_KILLERS and t.has("hazard"):
		return [_with_depth(_pick(t["hazard"]), reg, rm)]
	if rm == Run.GUARDIAN_ROOM and (killer.begins_with("serpent") or killer in ["serket", "scorpion", "shezmu"]):
		return [_with_depth(_pick(t["guardian"]), reg, rm)]
	for band in t["bands"]:
		if rm >= int(band[0]) and rm <= int(band[1]):
			return [_with_depth(_pick(band[2]), reg, rm)]
	return [_with_depth(_pick(t["bands"][-1][2]), reg, rm)]


## 1. Commento su com'è finita l'ultima discesa.
static func _ending() -> Array:
	match Meta.last_end:
		"room":
			return death_line(Meta.last_region, Meta.last_room, Meta.last_killer, false)
		"ammit":
			return death_line(Meta.last_region, Meta.last_room, Meta.last_killer, true)
		"win":
			var t: Dictionary = death_table().get(Meta.last_region, {})
			if Meta.last_region >= 2 and t.has("win"):
				return [_pick(t["win"])]
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
			"jackal":
				options.append(Lang.t("Gli sciacalli. Mi somigliano, lo so. Cacciano in branco: uno ti guarda negli occhi mentre gli altri ti girano dietro. Non guardare quello che ringhia. Guarda quelli che tacciono."))
			"vulture":
				options.append(Lang.t("Un avvoltoio. Nekhbet, la dea avvoltoio, proteggeva il re con le ali aperte. Questi non proteggono nessuno. Quando la sua ombra si stringe su di te, sei già in ritardo."))
			"sokar_guard":
				options.append(Lang.t("Un guardiano di Sokar. Lo scudo para tutto ciò che vede. Non vede dietro di sé: nessuno ci riesce."))
			"damned_ba":
				options.append(Lang.t("Un Ba dannato. L'anima di un morto che la bilancia ha respinto. Non ha più un corpo dove tornare, e odia chi ce l'ha. Abbattila prima che si accenda."))
			"crocodile":
				options.append(Lang.t("Un coccodrillo. Il Libro ha due formule apposta, la trentuno e la trentadue: i coccodrilli del Duat vengono a rubare la magia del morto. Quando l'acqua ribolle vicino a te, non restare sul bordo."))
			"aker", "aker_lion":
				options.append(Lang.t("Aker. Il dio dell'orizzonte, due leoni schiena contro schiena: Ieri guarda dove il sole muore, Domani dove rinasce. Non ha un dietro, Scriba. Ha dei fianchi."))
			"aker_raggio":
				options.append(Lang.t("Il raggio dell'alba. Nemmeno la luce di Domani passa attraverso la pietra. Quando Aker ruggisce, le montagne ti lanciano un riparo: usalo."))
			"aker_pietra":
				options.append(Lang.t("Le pietre dell'orizzonte. Guarda l'ombra a terra: si allarga prima che la pietra arrivi."))
			"serket":
				options.append(Lang.t("Serket. La chiamavano Colei che fa respirare la gola: chi era punto la pregava, e lei toglieva il veleno. A te non lo toglierà. Guarda il solco nella sabbia, non lei: il solco ti dice dove uscirà la coda."))
			"scorpion":
				options.append(Lang.t("Gli scorpioni di Serket. La dea protegge dal veleno chi la onora. Tu non l'hai onorata. Quando la coda si accende, allontanati."))
			"grata":
				options.append(Lang.t("Una grata di fuoco. Nelle acque di Wernes il fuoco di Am-heh corre anche sotto le pietre. Quando le sbarre si arroventano, non aspettare di capire perché."))
			"olio":
				options.append(Lang.t("L'olio in fiamme. Nelle tombe le giare custodivano l'olio per le lampade del morto. Tu le usi per altro. Anche il fuoco, però, non sceglie chi bruciare."))
			"amheh", "amheh_fuoco", "amheh_marea", "amheh_anello":
				options.append(Lang.t("Am-heh. Il Libro lo chiama 'colui che divora milioni', e dice che vive in un lago di fuoco nel Duat. Nessun morto ci si bagna due volte. Tu sì, a quanto pare."))
			"javelin":
				options.append(Lang.t("Un lanciatore del deserto. La linea rossa è il suo pensiero prima del gesto: leggila, e il giavellotto non ti troverà."))
			"sokar_priest":
				options.append(Lang.t("Un sacerdote di Sokar. Non ferisce: veste gli altri di sabbia. Colpisci prima chi prega, poi chi combatte."))
			"khepri", "khepri_ball":
				options.append(Lang.t("Lo scarabeo di Khepri. Ogni mattina spinge il sole oltre l'orizzonte; laggiù spinge soltanto pietra. Guarda dove rimbalzerà, non dove si trova."))
			"mirage":
				options.append(Lang.t("Il Miraggio. Nel deserto la luce mente. Solo ciò che è vero getta ombra, Scriba."))
			"fiume":
				options.append(Lang.t("La sabbia nera di Sokar. Scorre come il Fiume, ma divora invece di nutrire. Cerca le lastre di pietra, o attraversala d'un balzo."))
			"buca":
				options.append(Lang.t("La sabbia ha ceduto. Nella terra di Sokar anche il suolo ha fame: quando la pietra si crepa, non restarle sopra."))
			"falco":
				options.append(Lang.t("Il soffio del falco di Sokar. Le sue statue vegliano sui passaggi: quando gli occhi si accendono, esci dalla linea."))
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
		"nefti": Lang.t("Nefti ha raccolto per te ciò che cadeva. Il suo velo è fatto d'argento e di notte."),
		"shu": Lang.t("Shu ti ha prestato il suo respiro. Lui regge il cielo a braccia alzate: tu reggi soltanto la tua lama."),
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
		# chi cade tre volte di fila contro il Serpente, o tre volte di fila prima della quinta stanza,
		# scopre che esiste un aiuto. Un'offerta sola per ciascun caso: non a ogni morte.
		{"id": "piuma1", "if": Meta.serpent_streak >= 3 and not Meta.feather, "offer": true, "lines": [
			Lang.t("Il Serpente della Porta ti ha fermato ancora. Tre volte di fila."),
			Lang.t("Ma'at non chiede a tutti di camminare allo stesso passo. A chi inciampa, presta una sua piuma: i colpi pesano meno sul tuo cuore. In cambio, il Duat ti restituisce meno Ka."),
			Lang.t("Non è una vergogna accettarla. È una vergogna non provare. Vuoi la piuma?")]},
		{"id": "piuma3", "if": Meta.early_streak >= 3 and not Meta.feather, "offer": true, "lines": [
			Lang.t("Tre volte sei tornato a me prima ancora di vedere la Porta, Scriba."),
			Lang.t("Il Duat non è un sentiero per i soli forti. Ma'at può prestarti una sua piuma: meno nemici ti cercheranno, e più lenti; i loro colpi peseranno meno sul tuo cuore. In cambio le ricompense della notte saranno più povere."),
			Lang.t("La piuma si posa e si toglie quando vuoi, dalle Opzioni. Vuoi accoglierla?")]},
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
			Lang.t("Vedi la porta murata a oriente? Dietro c'è la Casa della Vita, dove gli scribi copiavano i libri sacri. Con trenta pietre lo scalpellino la riaprirà."),
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
		{"id": "artigli0", "if": Weapons.requirement_met("artigli") and not Weapons.is_unlocked("artigli"), "lines": [
			Lang.t("Nel Cortile di Neith un telo è caduto da un piedistallo. Sotto ci sono gli artigli di Bastet."),
			Lang.t("La gatta li presta di rado. Deve averti visto passare tra gli scorpioni.")]},
		{"id": "scettro0", "if": Weapons.requirement_met("scettro") and not Weapons.is_unlocked("scettro"), "lines": [
			Lang.t("Lo scettro di Ptah si è mostrato, nel Cortile. Non accadeva da quando l'ultimo re lo posò."),
			Lang.t("È un'arma per chi comanda, Scriba. Mi chiedo perché si offra a te.")]},
		{"id": "flagello0", "if": Weapons.requirement_met("flagello") and not Weapons.is_unlocked("flagello"), "lines": [
			Lang.t("Nel cortile di Neith qualcosa si è svegliato, Scriba. Sotto il telo dormivano il flagello e il pastorale di Osiride: le insegne del re dei morti."),
			Lang.t("Neith li cede per trentacinque lapislazzuli. Non chiedermi perché una dea abbia bisogno di pietre: le dee hanno i loro conti.")]},
		{"id": "flagello1", "if": Weapons.is_unlocked("flagello"), "lines": [
			Lang.t("Porti il flagello e il pastorale. Le insegne del faraone, Scriba. Le stesse che Osiride stringe sul petto, seduto accanto alla mia bilancia."),
			Lang.t("Un re guida con il pastorale e difende con il flagello. Uno scriba che li impugna... o è un usurpatore, o è qualcuno che il Duat non ha ancora capito.")]},
		{"id": "arco1", "if": Meta.weapons_unlocked.has("arco"), "lines": [
			Lang.t("Neith è venuta fin qui, nella mia sala, per darti l'arco di Satet. Non lascia il suo cortile per chiunque."),
			Lang.t("Un arco tiene i nemici lontani. Ma nel Duat, Scriba, ciò che è lontano ha l'abitudine di avvicinarsi in fretta.")]},
		{"id": "lacrime1", "if": Meta.tears > 0, "lines": [
			Lang.t("Porti con te una Lacrima di Iside. Quando pianse Osiride, le sue lacrime gonfiarono il Fiume, e il Fiume ricoprì la Terra Nera."),
			Lang.t("Ogni lacrima vale più di mille Ka. Neith sa cosa farne: nel suo cortile le armi si risvegliano solo con il pianto di una dea.")]},
		{"id": "livelli1", "if": Meta.chapter_levels.values().any(func(v): return int(v) >= 2), "lines": [
			Lang.t("Hai ripassato la stessa formula due volte. Bene. Gli scribi copiavano lo stesso capitolo per anni, finché la mano non lo sapeva da sola."),
			Lang.t("Una formula detta bene vale più di dieci dette in fretta.")]},
		{"id": "deaths8", "if": Meta.runs >= 8, "lines": [
			Lang.t("Ogni volta che torni, Scriba, la bilancia trema. Come se avesse timore di te."),
			Lang.t("Non so il perché. E io conosco quasi ogni cosa.")]},
		# Sokar, la quarta ora: l'arrivo, poi Aker e il nome segreto di Ra (tappa 2, docs/storia.md)
		{"id": "sokar1", "if": Meta.sokar_seen, "lines": [
			Lang.t("Hai varcato il lago, e il lago ti ha lasciato passare. Ora cammini nella quarta ora: la terra di Sokar."),
			Lang.t("Là la barca del sole non solca le acque. La trascinano sulla sabbia, come un serpente che dorme. Perfino gli dèi, in quell'ora, camminano in silenzio."),
			Lang.t("Sokar custodisce ciò che è sepolto. Nella sua sabbia ogni cosa nascosta attende. Non tutte attendono di essere trovate.")]},
		{"id": "aker1", "if": Meta.aker_wins >= 1, "lines": [
			Lang.t("Hai veduto l'orizzonte, e l'orizzonte ha tremato. Ma il sole non si è levato."),
			Lang.t("Da quando il tuo re è disceso nel buio, l'alba non è più venuta. Ogni notte la barca di Ra giunge alle due montagne, e lì si arresta, come davanti a una porta senza chiave."),
			Lang.t("Il dio del sole rinasce pronunciando il proprio nome segreto. Quel nome gli è stato tolto. Chi lo ha preso lo ha portato quaggiù, nella notte. E la notte, Scriba, non restituisce ciò che custodisce.")]},
		{"id": "name2_aker", "if": Meta.aker_wins >= 1 and Meta.dialogue_seen.has("aker1"), "lines": [
			Lang.t("Un secondo segno è riaffiorato nel cartiglio del tuo re: un cerchio solcato da linee."),
			Lang.t("Aker l'ha lasciato andare, come si restituisce ciò che non ci appartiene. I guardiani dell'orizzonte sanno di chi è ogni cosa.")]},
		# il Banco di Apopi, la settima ora: l'arrivo, poi la regina (tappa 3, docs/storia.md)
		{"id": "apep0", "if": Meta.apep_seen, "lines": [
			Lang.t("Sei disceso oltre l'orizzonte. Ora sei nella settima ora: il banco di sabbia di Apopi."),
			Lang.t("Là il serpente beve il fiume, e la barca di Ra resta in secca. Accade ogni notte, da prima che esistessero le notti."),
			Lang.t("Apopi non ha padre e non ha fine. Non cerca te, Scriba. Cerca qualcosa, e crede che tu sappia dov'è. Vorrei saperlo anch'io.")]},
		{"id": "apep1", "if": Meta.apep_wins >= 1, "lines": [
			Lang.t("Hai legato il serpente. Nessuno lo uccide: tu lo hai fermato, ed è più di quanto si chieda a un'anima."),
			Lang.t("Ti dava la caccia. Apopi fiuta il nome segreto di Ra come lo sciacallo fiuta la tomba aperta. Ti segue perché tu sai dove si trova, anche se non sai di saperlo."),
			Lang.t("Ho interrogato i registri, infine. Il nome del tuo re non fu cancellato per odio. Fu la regina. Lo tolse da ogni pietra perché la bilancia non potesse chiamarlo, e lo depose nel buio dietro un volto che non era il suo. Io peso i cuori da quattromila anni, e nessuno mi aveva mai ingannato per amore.")]},
		{"id": "name3_apep", "if": Meta.apep_wins >= 1 and Meta.dialogue_seen.has("apep1"), "lines": [
			Lang.t("Un terzo segno è tornato nel cartiglio: una piccola cupola. Il pane. Il segno più umile, e quello che regge gli altri."),
			Lang.t("Ne manca uno. E l'ultimo, Scriba, non lo custodisce nessun mostro.")]},
		{"id": "deaths12", "if": Meta.runs >= 12, "lines": [
			Lang.t("Ho interrogato Ma'at, su di te. Non mi ha risposto."),
			Lang.t("In quattromila anni non era mai accaduto.")]},
		# il terzo segno (il pane) tornerà con Apopi, il boss della regione 3: per ora non si dice
		{"id": "name3", "if": false, "lines": [
			Lang.t("Il terzo segno: un pane. Ibis, cerchio, pane. Il nome si legge quasi, ma un segno manca ancora."),
			Lang.t("Thoth dice che l'ultimo segno torna solo quando la notte finisce. Poi tace. È peggio di quando dice che non sa.")]},
		{"id": "deaths20", "if": Meta.runs >= 20, "lines": [
			Lang.t("Venti discese. I guardiani delle porte hanno smesso di chiedermi chi sei. Ti chiamano 'quello che torna'."),
			Lang.t("Non è un nome. Ma è più di quanto avevi.")]},
		{"id": "name4", "if": Meta.ammit_wins >= 5, "lines": [
			Lang.t("Cinque volte Am-heh è caduto, e l'ultimo segno non torna."),
			Lang.t("Chiunque abbia cancellato Akhet, Scriba, aveva molta paura di lui. O lo amava molto. Non so dire quale delle due.")]},
	]


## Vero quando l'ultima battuta raccontata chiede una scelta (la Piuma di Ma'at): la Sala apre la
## domanda quando il dialogo finisce.
static var offer_feather := false

static func _next_story() -> Array:
	for b in story():
		if b["if"] and not Meta.dialogue_seen.has(b["id"]):
			Meta.dialogue_seen.append(b["id"])
			Meta.save()
			offer_feather = b.get("offer", false)
			return b["lines"]
	return []


## Frasi brevi per quando Anubi non ha più niente di nuovo da dire.
static func idle() -> Array:
	return [
		[Lang.t("La piuma di Ma'at non pesa nulla. Eppure nessuno l'ha mai smossa.")],
		[Lang.t("Il tuo nome è sabbia nel vento. Raccoglilo, segno dopo segno.")],
		[Lang.t("Gli scarabei non portano Ka. Non sprecare il tuo tempo con loro.")],
		[Lang.t("Quando un dio ti offre un dono pesante, guarda il prezzo. Poi guardalo ancora.")],
		[Lang.t("Il cancello è sempre aperto. Il Duat ha sempre fame.")],
		[Lang.t("Le parole degli dèi riposano nei Papiri di Thoth, in fondo alla sala.")],
		[Lang.t("Ogni porta ha un guardiano, ogni guardiano un nome. Impara i nomi, e le porte si aprono.")],
		[Lang.t("Il Traghettatore guarda sempre all'indietro. Paga, e sali sulla sua barca.")],
		[Lang.t("Il Ka che non spendi torna qui con te. Quello che spendi ti tiene in vita. Scegli.")],
		[Lang.t("La barca del sole attende, oltre la notte. Ogni discesa la avvicina.")],
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
