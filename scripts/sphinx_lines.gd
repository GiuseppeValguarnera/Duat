class_name SphinxLines
extends RefCounted
## Le battute della Sfinge (blocco 17). Tono: enigmatica e ironica, mai crudele; una custode di pietra
## enorme e antica, un po' annoiata e un po' affezionata. Per ogni situazione almeno 6-8 varianti:
## pick() ne sceglie una a caso senza ripetere l'ultima usata (Meta.sphinx.last_line, salvata).
## Le battute con %s / %d ricevono arma, ondata o punteggio da chi le chiama.


static func table() -> Dictionary:
	return {
		# la prima visita in assoluto: chi è, cosa chiede, cosa dà
		"first": [
			Lang.t("Un visitatore. Che novità. L'ultimo è arrivato quando le piramidi erano ancora a punta."),
			Lang.t("Io sono la Sfinge. Custodisco la scala dell'enigma: ondate su ondate, ognuna un po' più cattiva della precedente."),
			Lang.t("Qui non contano i tuoi doni né i tuoi amuleti. Ti presto un'arma, quella del giorno, la stessa per tutti. Il resto lo guadagni salendo."),
			Lang.t("Ogni tre ondate mi fermo e ti faccio un indovinello. Nessuna risposta è sbagliata: scegli solo quanto vuoi soffrire."),
			Lang.t("In cambio ti do sigilli, i miei. Li spendi nel mio Tesoro. E se muori, pazienza: qui non si perde niente, tranne la dignità."),
		],
		"enter_back": [
			Lang.t("Sei tornato. Il tuo record no."),
			Lang.t("Di nuovo tu. Stavo giusto contando i granelli di sabbia. Ero a sette."),
			Lang.t("Ah, il mio visitatore preferito. Non dirlo agli altri: non ce ne sono."),
			Lang.t("Ti aspettavo. Non è vero, ma suona bene."),
			Lang.t("La scala è dove l'hai lasciata. Anch'io, purtroppo per le mie zampe."),
			Lang.t("Bentornato. Ho lucidato la pietra per te. Si fa per dire."),
			Lang.t("Hai la faccia di chi ha un piano. Lo dicono tutti, prima dell'ondata sei."),
			Lang.t("Eccoti. Il deserto era noioso senza qualcuno da guardare cadere."),
		],
		"enter_long": [
			Lang.t("Quanto tempo. Per me un battito di palpebre, per te un'eternità. Siediti, cioè: combatti."),
			Lang.t("Credevo ti fossi perso nel Duat. Poi ho ricordato che ti perdi solo qui."),
			Lang.t("Sei sparito per giorni. Ho fatto finta di non accorgermene. Con scarso successo."),
			Lang.t("Oh, guarda chi si ricorda della vecchia Sfinge. Le ragnatele le ho lasciate per te."),
			Lang.t("Hai preso una pausa. Saggio. La scala, intanto, non è diventata più corta."),
			Lang.t("Bentornato. Il tuo posto in classifica ti ha aspettato con più pazienza di me."),
		],
		"enter_claimed": [
			Lang.t("I premi di questa settimana li hai già presi tutti. Sei qui per la gloria, allora. O per me."),
			Lang.t("Niente più premi fino a lunedì. Restano i sigilli e il piacere della mia compagnia."),
			Lang.t("Hai svuotato le soglie della settimana. Ora sali solo per orgoglio, il motivo migliore."),
			Lang.t("La settimana non ha più niente da darti. Io sì: altri indovinelli."),
			Lang.t("Premi esauriti. Mi piaci di più quando non hai un motivo."),
			Lang.t("Tutte le soglie prese. Se cerchi un'altra ricompensa, guarda la classifica e piangi."),
		],
		"enter_record": [
			Lang.t("Il tuo record è %d punti. Io ne ho visti di migliori. Quasi tutti miei."),
			Lang.t("%d punti, il tuo massimo. Un numero rispettabile, per un mortale."),
			Lang.t("Il tuo meglio è %d. Oggi magari ti batti da solo. Magari."),
			Lang.t("Ricordo i tuoi %d punti. Li ricordo perché me li hai ripetuti tre volte."),
			Lang.t("%d punti in cima alla tua lista. La cima è un posto ventoso: scendi spesso."),
			Lang.t("Hai fatto %d, una volta. Gli dèi ne parlano ancora. Due, per la precisione."),
		],
		"weapon": [
			Lang.t("Oggi l'arma è %s. Non l'ho scelta io: la sorte ha un senso dell'umorismo peggiore del mio."),
			Lang.t("Arma del giorno: %s. Uguale per tutti, quindi niente scuse."),
			Lang.t("Ti tocca %s. Trattala bene: domani torna nel mio deposito."),
			Lang.t("%s, oggi. Se non la sai usare, è il momento giusto per imparare. Di fronte a me."),
			Lang.t("Oggi si sale con %s. La scala non fa differenze. Io sì, ma non lo ammetterò."),
			Lang.t("L'arma è %s. La stessa che oggi hanno in mano tutti gli altri sciocchi come te."),
		],
		"accept": [
			Lang.t("Allora sali. Io guardo."),
			Lang.t("Coraggio o distrazione? Lo scopriremo all'ondata tre."),
			Lang.t("Comincia. Prometto di non ridere. Ad alta voce."),
			Lang.t("La scala ti aspetta. Anche il pavimento, a dire il vero."),
			Lang.t("Vai. E ricordati di schivare: la gente se ne dimentica sempre."),
			Lang.t("Molto bene. Che la sabbia ti sia leggera."),
		],
		"shop": [
			Lang.t("Tutto ha un prezzo, tranne l'attesa, che è gratis."),
			Lang.t("Il mio Tesoro. Guarda pure, ma non toccare con le dita sporche di mummia."),
			Lang.t("Accetto solo sigilli. I lapislazzuli tienili per lo scalpellino, che è meno raffinato."),
			Lang.t("Ogni oggetto qui ha una storia. Quasi tutte inventate da me, ma sono belle."),
			Lang.t("Compra qualcosa per me, e dirò che sei generoso. Compra qualcosa per te, e dirò che sei umano."),
			Lang.t("Niente sconti. Sono una statua: non ho bisogno di soldi, ho bisogno di rispetto."),
			Lang.t("Scegli con calma. Io ho tutta l'eternità, tu no."),
		],
		"mods": [
			Lang.t("Vuoi renderti la vita più difficile? Finalmente una richiesta sensata."),
			Lang.t("Più dura la prova, più alti i punti. È l'unica giustizia che conosco."),
			Lang.t("Tre al massimo. Non voglio raccoglierti col cucchiaino."),
			Lang.t("I modificatori restano per tutta la prova. Non come i tuoi buoni propositi."),
			Lang.t("Scegli bene: alla classifica piacciono i coraggiosi, al pavimento ancora di più."),
			Lang.t("Ogni peso che aggiungi lo vedo. E lo apprezzo. In silenzio."),
		],
		"leave": [
			Lang.t("Vai già via? Non ti tratterrò. Non posso: sono di pietra."),
			Lang.t("Torna quando avrai voglia di perdere con stile."),
			Lang.t("Scappare è una strategia. Ne ho viste di peggiori. Poche."),
			Lang.t("La scala resta qui. Anch'io. Purtroppo."),
			Lang.t("Arrivederci. Mi annoierò in tua assenza, ma non lo saprai mai."),
			Lang.t("Vai pure. Domani l'arma sarà un'altra, e tu no."),
		],
		"idle": [
			Lang.t("Puoi anche parlarmi, sai. Non mordo. Non più."),
			Lang.t("Mi stai fissando. Io ti fisso da prima che tu nascessi."),
			Lang.t("Se aspetti che l'indovinello si risolva da solo, siediti: ci vorrà un po'."),
			Lang.t("Stai pensando o ti sei incantato? In entrambi i casi, ti capisco."),
			Lang.t("Sono enorme, è vero. Puoi smettere di guardarmi così."),
			Lang.t("Hai una domanda? Io ne ho mille. Comincia tu."),
			Lang.t("Il silenzio mi piace. Il tuo, però, comincia a pesare."),
		],
		"walk_off": [
			Lang.t("Nemmeno un saluto. I giovani d'oggi."),
			Lang.t("Torna quando trovi il coraggio. O la strada."),
			Lang.t("Ti sei avvicinato, ti sei allontanato. Una danza che conosco bene."),
			Lang.t("Ah, girare intorno ai problemi. Un classico."),
			Lang.t("Ero pronta a parlare. Sarà per un altro millennio."),
			Lang.t("Vai, vai. Ti guardo lo stesso."),
		],
		"record": [
			Lang.t("Contro ogni pronostico, compreso il mio."),
			Lang.t("Un nuovo record. Lo scolpirò da qualche parte. Piccolo."),
			Lang.t("Più in alto di sempre. La scala è sorpresa. Io meno: un po' ci credevo."),
			Lang.t("Hai battuto te stesso. È l'avversario più difficile, perché conosce tutte le tue scuse."),
			Lang.t("Record. Non abituarti: la gloria è sabbia, scivola."),
			Lang.t("Bene. Molto bene. Non lo ripeterò, quindi ascolta bene."),
			Lang.t("Oggi hai salito più gradini di quanti ne ricordi io. E io ricordo tutto."),
		],
		"near": [
			Lang.t("Quasi il tuo record. Quasi è la parola più crudele che conosco."),
			Lang.t("Ti mancava poco. Lo so, l'ho visto, e ho sospirato."),
			Lang.t("A un passo dal tuo meglio. La prossima volta fai quel passo."),
			Lang.t("Così vicino che il record ti ha sentito respirare."),
			Lang.t("Non è un record, ma ci assomiglia. Come un cugino."),
			Lang.t("Quasi. Gli dèi tengono un libro solo per i quasi. È enorme."),
		],
		"early": [
			Lang.t("Già finito? Stavo ancora sistemando la coda."),
			Lang.t("Una salita breve. Brevissima. Quasi una discesa."),
			Lang.t("Così presto? Avevo appena cominciato a fare il tifo. In segreto."),
			Lang.t("Non tutti i giorni sono buoni. Questo, per esempio."),
			Lang.t("La scala ha più gradini di così. Te lo assicuro, li ho contati."),
			Lang.t("Un inizio sfortunato. O un riscaldamento. Scegli tu la storia."),
		],
		"normal": [
			Lang.t("Una prova onesta. Non memorabile, ma onesta."),
			Lang.t("Sei salito, sei caduto. La storia di ogni mortale, in piccolo."),
			Lang.t("Non male. Non bene. Esattamente nel mezzo, dove vive la maggior parte del mondo."),
			Lang.t("Hai fatto quello che potevi. Domani potrai di più. O di meno. Vedremo."),
			Lang.t("La scala ti ha respinto, come fa con tutti. Con te è stata quasi gentile."),
			Lang.t("Ricorderò questa prova. Per un po'. Diciamo fino a cena."),
			Lang.t("Né trionfo né disastro. Mi piaci quando sei prevedibile."),
		],
		"retired": [
			Lang.t("Ti ritiri. Saggezza o paura? Spesso sono la stessa cosa con vestiti diversi."),
			Lang.t("Hai scelto tu quando fermarti. Pochi lo fanno. Pochissimi lo fanno al momento giusto."),
			Lang.t("Un ritiro ordinato. Il punteggio resta, il dolore no."),
			Lang.t("Ti fermi qui. Rispetto la decisione. Non la condivido, ma la rispetto."),
			Lang.t("Meglio scendere con le proprie gambe. Così mi hanno detto: io non ne ho bisogno."),
			Lang.t("Basta così, per oggi. Anche le statue sanno quando chiudere gli occhi."),
		],
		# la causa della morte (da Run.last_hit, la stessa fonte degli «Ultimi colpi»)
		"cause_mummy": [
			Lang.t("Una mummia. Lenta, bendata, eppure ti ha preso. Riflettici."),
			Lang.t("Ti ha fermato una mummia. Le bende, almeno, ce le aveva già."),
		],
		"cause_scarab": [
			Lang.t("Gli scarabei. Piccoli, tanti, e tu uno solo. La matematica è crudele."),
			Lang.t("Ti hanno sommerso gli scarabei. Khepri sarà fiero di loro."),
		],
		"cause_scorpion": [
			Lang.t("Lo scorpione ti ha ucciso. Di nuovo. Io lo chiamerei fedeltà."),
			Lang.t("Uno scorpione. Il cono rosso era lì apposta, sai."),
			Lang.t("Il veleno dello scorpione. Serket manda i suoi saluti."),
		],
		"cause_priest": [
			Lang.t("Un sacerdote. Le preghiere funzionano, a quanto pare. Le sue."),
			Lang.t("Ti ha colpito un sacerdote. Da lontano, come fanno i prudenti."),
		],
		"cause_cobra": [
			Lang.t("Un cobra. Ha sibilato, ti ha avvisato. Era educato, almeno."),
			Lang.t("Il cobra. Elegante, rapido, letale. Non lo invidio. Un po' sì."),
		],
		"cause_damned_ba": [
			Lang.t("Un Ba dannato. È esploso, come fanno le anime arrabbiate."),
			Lang.t("Ti sei fatto saltare da un Ba. La miccia si vedeva, sai."),
		],
		"cause_jackal": [
			Lang.t("Gli sciacalli. Uno ti distrae, gli altri ti mordono. Un vecchio trucco."),
			Lang.t("Il branco ti ha preso. Anubi ride sotto i baffi. Ha i baffi, credo."),
		],
		"cause_sokar_guard": [
			Lang.t("Un guardiano di Sokar. Lo scudo davanti, la carica dritta. Prevedibile, per chi guarda."),
			Lang.t("Ti ha travolto un guardiano. Di fianco, la prossima volta. I fianchi non hanno scudi."),
		],
		"cause_vulture": [
			Lang.t("Un avvoltoio. L'ombra a terra diceva tutto, ma tu guardavi altrove."),
			Lang.t("Dal cielo. Gli avvoltoi di Nekhbet non sbagliano mai il pranzo."),
		],
		"cause_javelin": [
			Lang.t("Un giavellotto. La striscia era lunga e chiara. Un po' come le mie lezioni."),
			Lang.t("Il lanciatore ti ha centrato. Bel tiro. Non per te."),
		],
		"cause_sokar_priest": [
			Lang.t("Un sacerdote di Sokar. Il deserto ha i suoi predicatori."),
			Lang.t("Ti ha fermato un sacerdote di Sokar. La sabbia gli dà sempre ragione."),
		],
		"cause_khepri": [
			Lang.t("La sfera di Khepri. Rotola, rimbalza, non perdona. Come il sole."),
			Lang.t("Uno scarabeo di Khepri. Ha spinto il sole addosso a te. Che onore."),
		],
		"cause_mirage": [
			Lang.t("Il miraggio. Ti ha ingannato. Succede anche ai migliori. Succede soprattutto a te."),
			Lang.t("Hai combattuto un'illusione e hai perso. C'è una morale, ma è triste."),
		],
		"cause_aker_lion": [
			Lang.t("L'ombra di un leone di Aker. Solo l'ombra, e ti è bastata."),
			Lang.t("Un leone dell'orizzonte. Ieri o Domani, che importa: oggi ha vinto lui."),
		],
		"cause_fire": [
			Lang.t("Una crepa di fuoco. Diventa rossa prima di bruciare. Tu no, a quanto vedo."),
			Lang.t("Il fuoco della terra spaccata. Ti aveva avvisato per un intero secondo."),
		],
		"cause_generic": [
			Lang.t("Sei caduto. Capita. Agli altri capita meno, ma capita."),
			Lang.t("La scala ti ha scosso via, come la sabbia da una zampa."),
			Lang.t("Una brutta fine per una salita discreta."),
			Lang.t("Non so cosa ti abbia colpito per ultimo. So solo che ti ha colpito bene."),
			Lang.t("Fine. Il pavimento ti ringrazia della visita."),
			Lang.t("Hai lottato. Il risultato non lo dice, ma io sì."),
			Lang.t("Giù. Di nuovo. La gravità è l'unico dio che non si offende mai."),
			Lang.t("È finita. Ma ogni fine, qui, è soltanto un altro inizio. Lo dico sempre, è il mio lavoro."),
		],
		# «Ricordi della Sfinge» (dal Tesoro): si ascoltano dal menu
		"memories": [
			Lang.t("Una volta ero sepolta nella sabbia fino al collo. Un principe si addormentò all'ombra della mia testa e io gli promisi un regno. Lo ebbe. Mi ripagò spalando."),
			Lang.t("Mi chiamavano Horemakhet, Horus nell'orizzonte. Guardo l'oriente perché è da lì che il sole torna. Ogni mattina. Non ha mai saltato un giorno: lo ammiro."),
			Lang.t("Mi hanno rubato il naso, un tempo. Non chiedermi chi. Ho fatto pace con il profilo che mi resta."),
			Lang.t("I Greci raccontano di una sfinge che mangiava chi sbagliava l'indovinello. Una parente lontana. Molto lontana. Io preferisco i sigilli."),
			Lang.t("Ho visto costruire le piramidi. Sembravano più alte, allora. Forse ero più piccola io."),
			Lang.t("Sai qual è l'indovinello più difficile? Perché torni. Io una risposta ce l'ho, ma me la tengo."),
			Lang.t("Una volta un uccello ha fatto il nido nel mio orecchio. È rimasto tre secoli. Mi manca ancora."),
			Lang.t("Non dormo mai. Chiudo gli occhi, ogni tanto, per far credere al deserto che può riposare anche lui."),
		],
	}


## Una battuta della situazione `key`, a caso, mai uguale all'ultima usata (salvata nel salvataggio).
static func pick(key: String) -> String:
	var all := table()
	if not all.has(key):
		return ""
	var list: Array = all[key]
	var last: Dictionary = Meta.sphinx.get("last_line", {})
	var prev := int(last.get(key, -1))
	var i := randi() % list.size()
	if list.size() > 1 and i == prev:
		i = (i + 1 + randi() % (list.size() - 1)) % list.size()
	last[key] = i
	Meta.sphinx["last_line"] = last
	Meta.save()
	return String(list[i])


## Le fonti dell'ultimo colpo (Run.last_hit) che hanno una battuta loro.
const CAUSES := {"mummy": "mummy", "scarab": "scarab", "scorpion": "scorpion", "scorpion_veleno": "scorpion",
	"priest": "priest", "cobra": "cobra", "damned_ba": "damned_ba", "jackal": "jackal", "sokar_guard": "sokar_guard",
	"vulture": "vulture", "javelin": "javelin", "sokar_priest": "sokar_priest", "khepri": "khepri", "khepri_ball": "khepri",
	"mirage": "mirage", "aker_lion": "aker_lion", "aker_crepa": "fire"}


## La battuta sulla causa: solo se la fonte è nota, altrimenti quella generica (mai battute false).
static func cause_line(src: String) -> String:
	if CAUSES.has(src):
		return pick("cause_" + String(CAUSES[src]))
	return pick("cause_generic")
