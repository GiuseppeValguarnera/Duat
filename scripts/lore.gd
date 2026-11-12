class_name Lore
## Cosa raccontano le divinità quando ti offrono un dono, e l'archivio dei Papiri di Thoth.
##
## Ogni dio ha:
## - "intro": come si presenta la prima volta;
## - "stories": pezzi del suo mito, raccontati uno per incontro, una volta sola;
## - "idle": frasi brevi per quando ha già raccontato tutto.
## Le storie ascoltate vengono salvate in Meta.dialogue_seen e si rileggono nei Papiri di Thoth.
##
## Tono: gli dèi parlano in prima persona, con formule solenni, e ognuno ha la sua voce
## (Ra cosmico, Sekhmet feroce, Thoth misurato, Bastet regale, Sobek lento, Iside materna,
## Set sprezzante). Non dicono mai "gli Egizi credevano": per loro è tutto vero, e il futuro
## (musei, archeologi) lo vedono come una profezia. I fatti sono storici, solo semplificati.

const GODS_IT := {
	"anubi": {
		"name": "Anubi, il Guardiano",
		"intro": {"title": "La bilancia", "text": "Prima che tu scenda, Scriba, io ti peso. Ogni mio dono è un piatto della bilancia: ciò che prendi da una parte, lo lasci sull'altra. Così è il giudizio, dal primo sole all'ultimo."},
		"stories": [
			{"title": "L'imbalsamatore", "text": "Fui io a fasciare Osiride, quando il mondo non conosceva ancora la morte. Le mie mani furono le prime. Da allora i miei sacerdoti lavorano con il mio volto di sciacallo sul viso, perché nessun morto resti solo."},
			{"title": "Settanta giorni", "text": "Settanta giorni dura il cammino del corpo verso l'eternità. Quaranta sotto il natron, il sale del deserto, finché in lui non resta più acqua. Il cervello si getta: non serve. Il cuore resta al suo posto. Il cuore dovrà parlare, davanti a me."},
			{"title": "I vasi canopi", "text": "Quattro vasi, quattro guardiani: i figli di Horus. Imset dal volto d'uomo custodisce il fegato. Hapi il babbuino, i polmoni. Duamutef lo sciacallo, lo stomaco. Qebehsenuf il falco, le viscere. Nulla del morto va perduto."},
			{"title": "Perché lo sciacallo", "text": "Gli uomini vedevano gli sciacalli aggirarsi tra le tombe, al margine del deserto, e ne avevano paura. Allora pregarono lo sciacallo perché diventasse il custode di ciò che temevano. E io lo divenni."},
			{"title": "Prima di Osiride", "text": "Prima che Osiride sedesse sul trono dei morti, l'Occidente era mio. Glielo cedetti. Tenni per me la bilancia, perché il trono comanda, ma solo la bilancia conosce la verità."},
		],
		"idle": ["La bilancia non dimentica. Scegli.", "Un cuore leggero cammina lontano.", "Torna intero, Scriba. O torna comunque.", "Ho pesato re e mendicanti. La piuma non fa distinzioni.", "Il primo passo è leggero. È l'ultimo che pesa."],
	},
	"ra": {
		"name": "Ra, il Sole",
		"intro": {"title": "Chi è Ra", "text": "Io sono Ra. Sono colui che sorge come Khepri, che splende come Ra, che tramonta come Atum. Questa notte la mia barca attraversa il Duat insieme a te. Prendi la mia fiamma, Scriba, e fa' luce dove io non giungo."},
		"stories": [
			{"title": "La barca della notte", "text": "Ogni sera discendo nell'Occidente e la mia barca entra nel Duat. Dodici ore di tenebra, dodici porte, dodici guardiani. Se una sola porta restasse chiusa, il mattino non verrebbe. Per questo io non mi fermo. Mai."},
			{"title": "Apophis", "text": "Apophis, il serpente del caos, mi attende ogni notte nelle acque del Duat. Lo vinco, e ritorna. Lo vinco ancora, e ritorna ancora. Nei miei templi gli uomini scrivevano il suo nome per calpestarlo e darlo al fuoco. Ogni nome bruciato era una notte vinta."},
			{"title": "L'Occhio di Ra", "text": "Quando divenni vecchio, gli uomini tramarono contro di me. Mandai il mio Occhio a punirli: esso divenne Sekhmet, e la sua fame non aveva fine. Feci versare sui campi birra tinta d'ocra rossa. Lei la bevve credendola sangue, e si addormentò. Per questo l'umanità vive ancora."},
			{"title": "Il nome segreto", "text": "Molti sono i miei nomi, ma uno solo è il vero, e chi lo conosce ha potere su di me. Iside impastò la mia saliva con la terra e ne trasse un serpente. Il suo morso mi bruciava come nessun fuoco. Solo lei poteva guarirmi, e il prezzo fu il mio nome. Ricordalo, quando le parlerai."},
			{"title": "Tre volti", "text": "Al mattino sono Khepri, lo scarabeo che spinge il disco oltre l'orizzonte. A mezzogiorno sono Ra, in tutta la mia forza. Alla sera sono Atum, il vecchio che si corica. Tre volti, un solo dio. Anche tu, Scriba, sei più di ciò che appari."},
		],
		"idle": ["Ardi, Scriba. La notte è lunga.", "Dove passa la mia barca, il buio arretra.", "Ogni sera muoio. Ogni alba ritorno. Fa' lo stesso.", "Anche il sole teme la dodicesima ora. Non per questo si ferma.", "Brucia ciò che ti sbarra la via. Il resto, illuminalo."],
	},
	"sekhmet": {
		"name": "Sekhmet, la Potente",
		"intro": {"title": "Chi è Sekhmet", "text": "Io sono Sekhmet, la Potente. Il mio fiato è il vento rovente del deserto, la mia ira è la pestilenza che cammina. Ra mi creò per punire, e io non ho dimenticato come si fa. Prendi la mia furia, mortale. Non sprecarla."},
		"stories": [
			{"title": "La strage", "text": "Ra mi scagliò contro gli uomini ribelli e io li divorai, campo dopo campo, finché il Fiume non si fece rosso. Fu lui a pentirsi, non io. Mi fermò con l'inganno, con la birra rossa che bevvi credendola sangue. Da allora, ogni anno, gli uomini si inebriano in mio onore, per ricordare il giorno in cui furono risparmiati."},
			{"title": "Signora della pestilenza", "text": "Le pestilenze sono i miei messaggeri. Ma la mano che manda il male sa anche richiamarlo. I miei sacerdoti erano guaritori: con le mie preghiere e le loro mani risanavano i corpi. Temimi. Poi chiedimi la guarigione."},
			{"title": "Settecento statue", "text": "Il faraone Amenhotep ebbe paura di me. Fece scolpire più di settecento mie immagini di pietra nera, perché ogni giorno dell'anno qualcuno placasse la mia collera. Vedo il loro futuro: mi guarderanno dalle sale di popoli stranieri, in terre che non hanno mai visto il Fiume."},
			{"title": "Due volti", "text": "Hathor è la gioia, la danza, il canto, l'amore. Io sono ciò che la gioia diventa quando si leva in collera. Siamo una sola dea con due volti. Prega che ti mostri quello dolce."},
			{"title": "Menfi", "text": "A Menfi siedo accanto a Ptah, colui che plasma ogni cosa. Nostro figlio è Nefertum, il loto che si schiude sull'acqua al primo raggio del sole. Anche la leonessa ha una casa, Scriba."},
		],
		"idle": ["Il vento del deserto è il mio respiro. Respira con me.", "Fa' che tremino.", "La pietà appartiene a chi ha già vinto.", "Rosso si fa il Fiume, quando io avanzo.", "Non chiedermi dolcezza. Chiedimi vittoria."],
	},
	"thoth": {
		"name": "Thoth, lo Scriba degli dèi",
		"intro": {"title": "Chi è Thoth", "text": "Io sono Thoth, signore delle parole divine, misuratore del tempo, voce della luna. Quando il cuore viene pesato, è la mia mano a scrivere il verdetto. Anche tu sei uno scriba. Ogni cosa ha un nome, e chi lo pronuncia per primo la ferisce: dimostrami che il tuo primo colpo è preciso quanto la mia prima parola."},
		"stories": [
			{"title": "Le parole divine", "text": "Io diedi agli uomini i segni: le parole divine, che i popoli venuti dopo chiameranno geroglifici. Alcuni sono suoni, altri sono idee, tutti sono vivi. Ciò che è scritto esiste per sempre. Ciò che viene cancellato non è mai esistito. Tu lo sai meglio di chiunque."},
			{"title": "I cinque giorni", "text": "Ra aveva decretato che Nut non avrebbe partorito in alcun giorno dell'anno. Così sfidai la Luna al gioco e le vinsi parte della sua luce: cinque giorni nuovi, fuori dal calendario. In quei giorni nacquero Osiride, Iside, Set e Nefti. Ogni decreto ha una crepa. Io la trovo."},
			{"title": "L'Occhio di Horus", "text": "Set strappò l'occhio a Horus e lo ridusse in frantumi. Io li raccolsi, uno a uno, e lo risanai. Quell'occhio, il wedjat, divenne il segno di ciò che è intero e protetto. È lo stesso che tu scagli contro i tuoi nemici. Usalo con rispetto."},
			{"title": "Al giudizio", "text": "Nella Sala delle Due Verità il cuore giace su un piatto e la piuma di Ma'at sull'altro. Anubi osserva il filo della bilancia. Io scrivo. Senza la scrittura, nemmeno gli dèi saprebbero chi è giusto."},
			{"title": "Milioni di ibis", "text": "Mi venerano come ibis e come babbuino, che all'alba leva le braccia e grida verso il sole. Per secoli i pellegrini mi offrirono ibis imbalsamati, a milioni, deposti nelle gallerie di Saqqara e di Tuna el-Gebel. Ogni ibis era una preghiera. Le ho lette tutte."},
		],
		"idle": ["Misura. Poi colpisci.", "Ogni colpo è un segno sul papiro. Scrivi bene.", "La luna conta i passi di chi cammina nel buio.", "Ho già scritto come finirà questa stanza.", "Un segno sbagliato nel Libro, e il morto si perde. Così un colpo.", "Il tempo è una clessidra, Scriba. Io so quando girarla."],
	},
	"bastet": {
		"name": "Bastet, la Signora di Bubasti",
		"intro": {"title": "Chi è Bastet", "text": "Io sono Bastet, la Signora di Bubasti. Veglio sulle case, sulle madri, sui bambini che dormono. Per loro ho le fusa. Per chi li minaccia, ho gli artigli. Avvicinati, scriba. Ti presto i miei."},
		"stories": [
			{"title": "Da leonessa a gatta", "text": "Un tempo ero leonessa, feroce come Sekhmet. Poi gli uomini mi accolsero nelle loro case e io divenni gatta: dolce al focolare, terribile nella notte. La ferocia non mi ha lasciata, Scriba. Ha soltanto imparato ad attendere."},
			{"title": "La festa di Bubasti", "text": "Per la mia festa risalivano il Fiume a centinaia di migliaia, sulle barche, cantando, battendo le mani, suonando i flauti. Un viaggiatore greco, Erodoto, li contò: settecentomila. Scrisse che in quei giorni si beveva più vino che in tutto il resto dell'anno. Ne fui lieta."},
			{"title": "I gatti sacri", "text": "I miei figli difendevano il grano dai topi e le case dai serpenti. Chi uccideva un gatto, anche per errore, poteva pagarlo con la vita. E quando un gatto moriva, la sua famiglia si radeva le sopracciglia in segno di lutto. Così si onora chi ti protegge."},
			{"title": "La profezia dei gatti", "text": "Imbalsamarono i miei figli a migliaia e li deposero accanto a me. Vedo ciò che accadrà: verranno uomini da una terra fredda e li porteranno via a tonnellate, centottantamila, per concimare i loro campi. Una dea vede anche questo. E non dimentica."},
			{"title": "Il Grande Gatto", "text": "Sotto l'albero sacro di Eliopoli, il Grande Gatto afferrò il coltello e recise la testa del serpente Apophis. Alcuni dicono che fosse Ra stesso. Altri dicono che fossi io. Io non li correggo."},
		],
		"idle": ["Colpisci dove duole. Poi svanisci nell'ombra.", "La casa è sacra. Chi la minaccia conosce i miei artigli.", "Va'. I miei occhi ti seguono nel buio.", "Fusa per chi amo. Artigli per tutti gli altri.", "Un gatto non corre, se non sta vincendo."],
	},
	"sobek": {
		"name": "Sobek, il Signore del Fiume",
		"intro": {"title": "Chi è Sobek", "text": "Io sono Sobek, Signore del Fiume. La mia pelle è più dura della pietra, la mia pazienza più lunga delle piene. Il Nilo dà la vita alla Terra Nera, e io sono il Nilo quando morde. Prendi la mia forza, mortale, e non lasciare la presa."},
		"stories": [
			{"title": "La Terra Nera", "text": "Ogni anno il Fiume si gonfia e ricopre i campi. Quando si ritira, lascia il limo nero, la terra che nutre. Per questo gli uomini chiamarono il loro paese Kemet, la Terra Nera. Alcuni scrissero che le acque nascono da me. Io lascio che lo credano."},
			{"title": "Il figlio dagli orecchini d'oro", "text": "Nella città dei coccodrilli, nel Fayyum, un mio figlio sacro viveva dentro un lago. Lo adornavano di orecchini d'oro e anelli alle zampe. I pellegrini gli offrivano pane, carne e vino, e un greco di nome Strabone venne a vederlo mangiare. Il Fiume onora chi lo onora."},
			{"title": "Kom Ombo", "text": "A Kom Ombo il mio tempio è diviso in due: una metà è mia, l'altra di Horus il Vecchio. Due porte, due santuari, sotto un solo tetto. Nelle sue tombe dormono i miei figli imbalsamati, e accanto a loro le loro uova."},
			{"title": "Temuto e pregato", "text": "Sul Fiume i miei figli uccidevano. Chi lavava i panni, chi pescava, chi guadava. Per questo gli uomini mi pregavano. Chi può divorarti, è meglio averlo amico."},
		],
		"idle": ["Il Fiume non si ferma. Nemmeno tu.", "Attendi sotto l'acqua. Poi mordi.", "Pelle di pietra. Cuore lento.", "La piena arriva senza chiedere permesso.", "Mordi, trattieni, non lasciare."],
	},
	"iside": {
		"name": "Iside, la Grande di Magia",
		"intro": {"title": "Chi è Iside", "text": "Io sono Iside, la Grande di Magia. Ho strappato il mio sposo alla morte con le mie parole e con le mie lacrime. Se Osiride è tornato, Scriba, puoi tornare anche tu. Lascia che ti protegga."},
		"stories": [
			{"title": "La cassa", "text": "Set fece costruire una cassa splendida, intarsiata d'oro, e durante un banchetto la promise in dono a chi l'avesse colmata alla perfezione. Era fatta sulle misure di Osiride. Quando il mio sposo vi si distese, Set serrò il coperchio, lo sigillò col piombo e lo gettò nel Fiume."},
			{"title": "La prima mummia", "text": "Ritrovai il mio sposo, ma Set lo fece a pezzi e li disperse per tutta la Terra Nera. Con mia sorella Nefti li cercai, uno per uno, piangendo. Anubi ci aiutò a ricomporlo e a fasciarlo. Fu il primo dei morti a essere imbalsamato, e da allora ogni uomo ha sperato lo stesso."},
			{"title": "Horus nella palude", "text": "Il mio sposo tornò in vita il tempo di darmi un figlio: Horus. Lo nascosi nelle paludi di papiro del Delta, lontano dagli occhi di Set, e lo crebbi in segreto finché non fu forte abbastanza da reclamare il trono di suo padre."},
			{"title": "Il nome di Ra", "text": "Sì. Ho ingannato Ra per strappargli il suo nome segreto. Ti avrà narrato la sua versione. Io ti dico la mia: volevo un potere che nessuno potesse togliere a mio figlio. Una madre non chiede perdono per questo."},
			{"title": "Il nodo di Iside", "text": "Il tyet, il mio nodo, si intaglia nella pietra rossa e si posa sul collo dei morti. Il Libro dice che chi lo porta è protetto dal mio sangue e dalla mia magia. Ne porti uno anche tu, Scriba, anche se non lo vedi."},
			{"title": "Oltre il mare", "text": "Vedo il mio nome attraversare il mare. Avrò templi in Grecia, a Roma, fino alla lontana Londinium. A Pompei la cenere del vulcano custodirà la mia casa. Per più di tremila anni gli uomini mi chiameranno madre."},
		],
		"idle": ["Le mie ali ti coprono anche quando non le vedi.", "Ogni ferita si richiude, come il Fiume dopo la barca.", "Ho ricomposto un dio. Posso ricomporre te.", "Non sei solo, Scriba. Non lo sei mai stato.", "Torna da me intero."],
	},
	"nefti": {
		"name": "Nefti, Signora della Casa",
		"intro": {"title": "Chi è Nefti", "text": "Solo nella quarta ora mi lascio vedere, Scriba, dove la sabbia seppellisce anche la luce. Io sono Nefti, la Signora della Casa, colei che piange i morti. Ciò che cade davanti a te non è perduto: lo raccolgo, e te lo rendo. D'ora in poi veglierò su di te anche sulle acque di Wernes."},
		"stories": [
			{"title": "Le due nibbie", "text": "Quando Osiride fu ucciso, io e mia sorella Iside diventammo due nibbie. Volammo sopra il Fiume, gridando il suo nome, finché non trovammo ogni pezzo del suo corpo. Il nostro pianto è il primo canto funebre che il mondo abbia udito."},
			{"title": "La sposa di Set", "text": "Mi diedero in sposa a Set, il signore del deserto. Ma il mio cuore stava con chi Set aveva ucciso. Il lutto non sceglie da che parte stare: si posa su tutti, come la notte."},
			{"title": "Mio figlio", "text": "Anubi è mio figlio. Io lo lasciai nelle paludi, e Iside lo crebbe. Ora lui guida le anime e io le piango. Quando le sue guide colpiscono, il mio velo le segue."},
			{"title": "Ai piedi della bara", "text": "Sui sarcofagi mi vedrai inginocchiata ai piedi del morto, con le ali aperte. Iside sta alla testa. Fra le due sorelle, nessun morto resta solo nella notte."},
		],
		"idle": ["Ogni caduto ti rende qualcosa.", "Il lutto è un dono, se sai riceverlo.", "Raccolgo ciò che cade. Non temere.", "La notte è lunga. Io la conosco tutta.", "Piango per loro, perché tu possa restare in piedi."],
	},
	"shu": {
		"name": "Shu, il Respiro del Mondo",
		"intro": {"title": "Chi è Shu", "text": "Nel vento della quarta ora mi riconosci, Scriba: sono il respiro che corre sulla sabbia. Io sono Shu, l'aria che sta fra il cielo e la terra. Sul capo porto la piuma, perché nulla è più leggero di me, e nulla regge un peso più grande. Da questa notte il mio soffio ti seguirà in ogni ora del Duat."},
		"stories": [
			{"title": "Il primo respiro", "text": "Atum era solo, nelle acque immobili del principio. Starnutì, e nacqui io; sputò, e nacque mia sorella Tefnut, l'umidità. Il primo suono del mondo fu un respiro. Ogni respiro, da allora, è un piccolo inizio."},
			{"title": "Le braccia alzate", "text": "Nut, il cielo, e Geb, la terra, erano stretti in un solo abbraccio, e fra loro non c'era spazio per nulla. Atum mi ordinò di separarli. Alzai le braccia, e il cielo salì. Da allora le tengo alzate, e fra le mie mani vive tutto ciò che respira."},
			{"title": "La piuma", "text": "La piuma di struzzo che porto sul capo è la stessa che Ma'at mette sulla bilancia. L'aria e la verità pesano uguale: niente, eppure senza di loro nulla resta in piedi."},
			{"title": "I pilastri del cielo", "text": "Quattro sostegni reggono il cielo, uno per ogni vento. I venti sono miei figli. Quello del nord porta fresco e vita; quello del sud porta sabbia e fuoco. Qui, nella terra di Sokar, soffiano tutti insieme."},
		],
		"idle": ["Respira, Scriba. Anche il cielo si regge su un respiro.", "Ciò che spingi lontano non ti tocca più.", "La piuma non lotta col vento. Lo cavalca.", "Fra il cielo e la terra c'è posto per te.", "Il vento non si vede. Si vede ciò che sposta."],
	},
	"horus": {
		"name": "Horus, il Falco",
		"intro": {"title": "Chi è Horus", "text": "Io sono Horus, il Falco, figlio di Iside e di Osiride. Il mio occhio destro è il sole, il sinistro è la luna. Tu porti in battaglia il mio Occhio, Scriba: lascia che ti insegni a farlo volare."},
		"stories": [
			{"title": "Il trono del padre", "text": "Set uccise mio padre e prese il suo trono. Io crebbi nascosto tra i papiri, e quando fui forte lo sfidai. Ottant'anni di lotta, davanti al tribunale degli dèi. Alla fine il trono della Terra Nera fu mio. Chi ha ragione deve anche saper aspettare."},
			{"title": "L'occhio strappato", "text": "Nella lotta Set mi strappò l'occhio e lo fece a pezzi. Thoth li raccolse e me lo restituì intero. Da allora quell'occhio si chiama wedjat, 'il sano', e gli uomini lo portano al collo contro ogni male. Anche ferito, il falco vede."},
			{"title": "Il re vivente", "text": "Ogni faraone era Horus sulla terra. Il primo dei suoi cinque nomi era il nome di Horus, scritto dentro un recinto sormontato da un falco. Quando il re moriva diventava Osiride, e il nuovo re diventava me. Così il trono non resta mai vuoto."},
			{"title": "Edfu", "text": "Il mio tempio di Edfu è tra i più intatti della Terra Nera. Ogni anno la statua di Hathor risaliva il Fiume da Dendera per raggiungermi: la chiamavano la Festa del Bell'Incontro. Gli dèi, Scriba, sanno anche festeggiare."},
		],
		"idle": ["Mira come il falco: dall'alto, una volta sola.", "Il mio Occhio vede ciò che il buio nasconde.", "Vola, Scriba.", "Il falco non insegue. Attende, poi scende.", "Lancia. E quando torna, lancia ancora."],
	},
	"set": {
		"name": "Set, il Signore del Deserto",
		"intro": {"title": "Chi è Set", "text": "Io sono Set. Signore del deserto rosso, delle tempeste, delle terre straniere. Sì, sono colui che uccise il fratello. Eppure, ogni notte, quando il serpente assale la barca del sole, è la mia lancia a respingerlo. Vuoi un patto? Prima il prezzo. Sempre."},
		"stories": [
			{"title": "La Terra Rossa", "text": "A Osiride toccò la terra nera, quella che dà il grano. A me il deserto, Deshret, la Terra Rossa, dove nulla cresce e tutto muore. Per questo il rosso divenne il colore del caos. Il mio colore. Non fui io a sceglierlo."},
			{"title": "Ottant'anni", "text": "Per ottant'anni contesi il trono a Horus. Gareggiammo con barche di pietra, ci battemmo nel Fiume in forma di ippopotami, ci trascinammo davanti al tribunale degli dèi. Il trono andò a lui. A me toccò la prua della barca di Ra. Non tutti i vinti escono a mani vuote."},
			{"title": "Sulla prua", "text": "Ogni notte, dalla prua della barca solare, trafiggo Apophis con la lancia. Il caos contro un caos più grande. Gli dèi luminosi non sanno fare questo lavoro. Per fermare un mostro, Scriba, serve un mostro."},
			{"title": "La bestia senza nome", "text": "Porto la testa di una bestia che nessun uomo sa nominare. Muso lungo e ricurvo, orecchie squadrate, coda dritta come una freccia. Vedo i sapienti delle terre future discuterne per secoli: un cane? un asino? Lasciali discutere."},
			{"title": "Il nome dei faraoni", "text": "Non sempre fui il nemico. Alcuni faraoni portarono il mio nome con orgoglio. Seti, il padre del grande Ramses, significa 'colui che appartiene a Set'. I re sanno riconoscere la forza, anche quando gli altri la temono."},
			{"title": "Il tuo faraone", "text": "Mi parli del tuo faraone come si parla di un fratello morto. Io di fratelli morti me ne intendo. Lo conoscevo, il tuo Akhet: un re che non voleva morire. Ne ho visti tanti, di re così. Lui però ci è quasi riuscito. Chiedi agli altri dèi perché nessuno ne parla volentieri. Io rido, e basta."},
		],
		"idle": ["Prima il prezzo, poi il premio.", "Il dolore insegna. Tu impari piano.", "La tempesta non chiede perdono. Nemmeno io.", "Un patto è sabbia incisa nella pietra.", "Ogni notte respingo il serpente. E tu, cosa respingi?"],
	},
}

## Le lezioni di Anubi nella Sala del Giudizio (le racconta quando non ha altro di nuovo da dire).
const JUDGEMENT_IT := [
	{"title": "La pesatura del cuore", "text": "Nella Sala delle Due Verità il cuore del morto viene posato su un piatto, la piuma di Ma'at sull'altro. Se il cuore è leggero, il morto attraversa e raggiunge il Campo dei Giunchi. Se è greve di colpe, Ammit lo divora. Quella è la seconda morte. Dalla seconda, non si torna."},
	{"title": "Ma'at", "text": "Ma'at è la verità, la giustizia, l'ordine che regge il mondo. È anche una dea, e la sua piuma è la misura di ogni cuore. Il faraone regnava per custodirla. Il suo contrario è isfet: il caos, la menzogna, la fame del serpente."},
	{"title": "I quarantadue giudici", "text": "Prima della bilancia, il morto si ferma davanti a quarantadue giudici e a ciascuno dichiara una colpa che non ha commesso. Non ho rubato. Non ho mentito. Non ho fatto piangere nessuno. È la Confessione negativa, il capitolo centoventicinque del Libro."},
	{"title": "Le parti dell'anima", "text": "L'uomo non è una cosa sola. C'è il Ka, la forza che lo tiene in vita. Il Ba, che vola come un uccello dal volto umano. Lo Sheut, la sua ombra. L'Ib, il cuore. E il Ren, il nome. Perdi il nome, Scriba, e perdi la parte di te che gli altri ricordano."},
	{"title": "Il Libro dei Morti", "text": "Il Libro dei Morti non è un libro solo. È un insieme di formule scritte sul papiro e deposte nella tomba, per guidare il morto nel viaggio. Gli uomini lo chiamavano 'Formule per uscire al giorno'. Ciascuno ne prendeva quante poteva pagarne. Come te."},
	{"title": "Am-heh", "text": "Am-heh, il Divoratore di Milioni. Ha la testa di un cane e vive in un lago di fuoco, nelle prime ore della notte. Il Libro dei Morti insegna una formula per sfuggirgli, perché nessuno sa contare le anime che ha inghiottito. Solo l'acqua lo ferma: il fuoco di Am-heh non entra nel Fiume."},
	{"title": "Il Lago di Fuoco", "text": "Il capitolo centoventisei del Libro descrive un lago nel Duat. Ai suoi quattro angoli siedono quattro babbuini, i custodi. Al morto giusto il lago dà acqua fresca e pane. Al dannato, fiamme. È lo stesso lago, Scriba: non cambia l'acqua, cambia chi vi si specchia. Am-heh ne è il guardiano. Per questo, nella sua arena, l'acqua ti protegge: finché il lago ti riconosce come giusto."},
	{"title": "Ammit", "text": "Ammit non ha templi. Nessuno la prega, tutti la temono. Ha la testa del coccodrillo, il petto del leone, le zampe dell'ippopotamo: le tre bestie più letali della Terra Nera, in un corpo solo. Siede accanto alla bilancia. E attende."},
	{"title": "Il Duat", "text": "Il Duat è il mondo che giace sotto il mondo. Sulle pareti delle tombe dei re, nella valle a occidente di Tebe, i sacerdoti dipinsero l'Amduat, il libro di ciò che è nel Duat, ora per ora. Dodici ore, dodici porte, e in ognuna dèi e mostri."},
	{"title": "Il nome cancellato", "text": "Cancellare un nome dalla pietra è peggio che uccidere. Dopo la loro morte, scalpellarono il nome della regina Hatshepsut e quello del faraone Akhenaton da templi e monumenti, perché il ricordo morisse con loro. Qualcuno ha fatto lo stesso con il tuo re, e con lui con te, che lo scrivevi. E io voglio sapere chi."},
	{"title": "Il Campo dei Giunchi", "text": "Oltre la bilancia si stende l'Aaru, il Campo dei Giunchi: una Terra Nera senza fame né dolore, con canali limpidi e grano più alto di un uomo. Ma anche là si lavora la terra. Per questo i morti portavano con sé gli ushabti, che rispondevano al loro posto."},
]


## I Ricordi dello scriba: le imprese del faraone Akhet, scritte da chi crede di essere stato
## il suo scriba. Uno per ogni boss di regione battuto (`needs` = vittorie). Sono in terza persona,
## ma la terza persona scivola: è il colpo di scena che arriva attraverso la scrittura
## (vedi docs/storia.md, "I Ricordi dello scriba"). Prima della tappa 2 non si nomina il nome di Ra
## rubato, prima della tappa 3 non si nomina la regina.
const RICORDI_IT := [
	{"needs": 1, "title": "I · La lancia di Buto", "text": "Scrissi la battaglia di Buto come me la dettarono i capitani. Il re scese dal carro prima che le linee si toccassero e prese la lancia dalle mani del portatore: una lancia antica, dissero, uscita dal tempio di Neith a Sais. I capitani ricordavano le grida, la polvere, il fiume rosso. Io ricordo il legno. Liscio, caldo di sole, con una scheggia sotto il pollice destro che il re non volle mai far limare. Non so perché lo ricordo. Forse me lo raccontò lui."},
	{"needs": 2, "title": "II · La doppia corona", "text": "Il giorno dell'incoronazione scrissi i cinque nomi del re su cento rotoli. Toro possente. Amato di Ma'at. Colui che sorge all'orizzonte. La corona bianca dentro la corona rossa, una sola corona per le Due Terre. Dalla folla sembrava leggera. Non lo era: faceva sudare la nuca, e il lino sotto si bagnava tutto prima del tramonto. Questo nei rotoli non c'è. Non l'ho mai scritto. Eppure lo so, come se me l'avesse confidato lui, quella sera, togliendosela davanti a me."},
	{"needs": 3, "title": "III · La casa dell'eternità", "text": "Il re cominciò a scavare la sua tomba nel primo anno di regno, come tutti i re. Ma lui ci scendeva ogni notte. Una lampada sola, e ore davanti alle pareti ancora bianche, dove i pittori avrebbero dipinto la pesatura del cuore. Una notte mi chiamò e mi chiese di leggergli il capitolo centoventicinque. Lo lessi due volte. Alla seconda, la mia mano... la sua mano strinse il rotolo fino a spezzarne il bordo. Disse soltanto: «Non voglio essere pesato.»"},
	{"needs": 1, "boss": "aker", "title": "IV · Il nome nascosto", "text": "Nel nono anno il re andò a Iunu, la città del sole, e non volle nessuno con sé. Nemmeno me. Lo scrissi lo stesso: il re visitò il tempio di Ra e offrì mille pani. È quello che si scrive. Ma io so che entrò nella sala dove nessun uomo entra, quella dove i sacerdoti custodiscono la storia di Iside e del nome segreto. So che il buio là dentro odora di cedro e di cera. So che le parole si dicono a bassa voce, perché anche il muro ascolta. Le dico... le disse. Uscì all'alba. Quel giorno il sole sorse, come sempre. Il sole sorse ogni giorno, finché il re visse."},
	{"needs": 1, "boss": "apep", "title": "V · La mano della regina", "text": "Quando il re morì, la regina Meritneith non pianse davanti a nessuno. Chiamò gli scalpellini, di notte. Scrissi anche questo, perché uno scriba scrive tutto: che la regina fece togliere il nome del re da ogni pietra, da ogni stele, da ogni rotolo. La corte disse: odio. Io c'ero, e non era odio. Le tremavano le mani. Disse: «Senza nome non c'è pesatura. Senza pesatura la Divoratrice non avrà il suo cuore.» Poi fece portare una tavolozza da scriba, la mia... una tavolozza da scriba, e la posò nel sarcofago, sul petto, dove si posa lo scarabeo del cuore. Si chinò. Disse: «Dormi dietro un altro volto, amore mio, finché il buio non avrà dimenticato il tuo.» Non capii a chi parlasse. Ricordo la sua mano, fredda. Era sulla mia fronte."}
]


## Ogni ricordo si sblocca con le vittorie su un boss di regione: Am-heh (I-III, la gloria del re),
## Aker (IV, il nome nascosto).
static func ricordo_boss(r: Dictionary) -> String:
	return str(r.get("boss", "amheh"))


## I ricordi di Sokar compaiono nei Papiri (anche sigillati) solo dopo che ci sei arrivato.
## (Non si usa Run qui: Lore si carica con le lingue all'avvio, e Run dipende dalle lingue.)
static func ricordo_visible(r: Dictionary) -> bool:
	if ricordo_boss(r) == "apep":
		return Meta.apep_seen
	return ricordo_boss(r) != "aker" or Meta.sokar_seen


static func ricordo_open(r: Dictionary) -> bool:
	var wins: int = Meta.aker_wins if ricordo_boss(r) == "aker" else Meta.ammit_wins
	if ricordo_boss(r) == "apep":
		wins = Meta.apep_wins
	return wins >= int(r["needs"])


## Ricordi già sbloccati che non hai ancora letto nei Papiri.
static func unread_ricordi() -> int:
	var n := 0
	for i in range(RICORDI.size()):
		if ricordo_visible(RICORDI[i]) and ricordo_open(RICORDI[i]) and not Meta.dialogue_seen.has("ricordo_%d" % i):
			n += 1
	return n


## Il ricordo appena sbloccato da una vittoria su `boss` (titolo), o "".
static func ricordo_for(wins: int, boss: String = "amheh") -> String:
	for r in RICORDI:
		if ricordo_boss(r) == boss and int(r["needs"]) == wins:
			return r["title"]
	return ""


static func god_name(god: String) -> String:
	return GODS[god]["name"] if GODS.has(god) else god


static func _entries(god: String) -> Array:
	var g: Dictionary = GODS[god]
	var out: Array = [g["intro"]]
	out.append_array(g["stories"])
	return out


## Cosa dice il dio adesso: la prima storia non ancora ascoltata, oppure una frase breve.
## La prima volta che un dio ti vede con l'Arco di Satet in mano, lo commenta (dopo la sua presentazione).
static func bow_line(god: String) -> String:
	match god:
		"ra":
			return Lang.t("Un arco, piccolo scriba? Anche i miei raggi colpiscono da lontano. Le tue frecce porteranno un poco del mio fuoco.")
		"sekhmet":
			return Lang.t("Ti nascondi dietro una corda tesa? Io caccio con le zanne. Ma una freccia nel cuore della preda... sì, anche questa è caccia.")
		"thoth":
			return Lang.t("L'arco di Satet. Ne annoto il peso e la tensione: una freccia è un pensiero che vola dritto. Che il tuo non esiti.")
		"bastet":
			return Lang.t("Colpire da lontano, senza farsi toccare. Questo è un modo di combattere che un gatto capisce benissimo.")
		"sobek":
			return Lang.t("Nelle paludi i cacciatori mi temono, e tirano dalle barche. Tu tiri dall'asciutto. Le mie acque renderanno lente le tue prede.")
		"iside":
			return Lang.t("Satet custodiva la piena che dà la vita. Il suo arco è in buone mani, se ricordi che ogni freccia scoccata è anche una preghiera.")
		"horus":
			return Lang.t("Il falco vede la preda da lontanissimo e non la manca mai. Impugni l'arma giusta per uno che ha il mio Occhio.")
		"anubi":
			return Lang.t("Ora tieni la morte a distanza, Scriba. È prudente. Ma la bilancia pesa anche ciò che colpisci da lontano.")
		"nefti":
			return Lang.t("Una freccia è un lamento che vola. Lascia che le mie lacrime viaggino con le tue, e chi cade ti ristorerà.")
		"shu":
			return Lang.t("Una freccia vive dentro di me, Scriba: io sono l'aria in cui vola. Tendi la corda, e il mio vento farà il resto.")
		"set":
			return Lang.t("Un arco! Il deserto è pieno di arcieri morti di sete. Ma tu sei divertente. Facciamo un patto.")
	return ""


## La prima volta che un dio ti vede con il Flagello di Osiride: sono le insegne del faraone.
static func flail_line(god: String) -> String:
	match god:
		"ra":
			return Lang.t("Il flagello e il pastorale... le insegne che io stesso diedi ai re della terra. Uno scriba che li porta. Il Duat ha il senso dell'umorismo.")
		"sekhmet":
			return Lang.t("Una frusta! Finalmente qualcosa che schiocca. Colpisci con la punta, piccolo re, e lascia che urlino.")
		"thoth":
			return Lang.t("Il nekhakha e l'heka. Li ho disegnati mille volte nei miei registri, sempre nelle mani di un faraone. Mai in quelle di uno scriba. Annoto l'eccezione.")
		"bastet":
			return Lang.t("Un bastone che afferra e tira a sé la preda. Sembra quasi una zampa. Mi piace.")
		"sobek":
			return Lang.t("Con quel pastorale i pastori del Nilo tiravano fuori le pecore dall'acqua, prima che arrivassi io. Ora tiri fuori i nemici. Portali vicino alla riva.")
		"iside":
			return Lang.t("Le insegne del mio sposo. Osiride le teneva incrociate sul petto quando lo ricomposi. Portale con rispetto, Scriba: hanno guidato un regno.")
		"horus":
			return Lang.t("Il flagello e il pastorale di mio padre. Li ho ripresi a Set con il sangue. Non lasciarteli strappare.")
		"anubi":
			return Lang.t("Porti le insegne del re dei morti, Scriba. Davanti alla mia bilancia, Osiride siede con quelle stesse mani. Ricordalo, quando colpisci.")
		"nefti":
			return Lang.t("Il pastorale di Osiride. Io l'ho pianto quanto Iside, anche se nessuno lo ricorda. Lascia che le mie lacrime cadano su chi agganci.")
		"shu":
			return Lang.t("Un pastorale per tirare, un respiro per lanciare. Lancia quello che agganci, Scriba, e io lo farò volare contro le pietre.")
		"set":
			return Lang.t("Il flagello di mio fratello! Gliel'ho strappato una volta, sai? Con un sarcofago su misura. Facciamo un patto, piccolo re di carta.")
	return ""


## Gli Artigli di Bastet: ogni dio li commenta la prima volta.
static func claws_line(god: String) -> String:
	match god:
		"ra":
			return Lang.t("Gli artigli della mia gatta. Ogni notte, sotto la persea di Iunu, è lei che taglia la testa al serpente. Stanotte, pare, tocca a te.")
		"sekhmet":
			return Lang.t("Artigli! Da gatta, non da leonessa, ma tagliano lo stesso. Stagli addosso, Scriba: chi graffia da lontano graffia l'aria.")
		"thoth":
			return Lang.t("Ho contato i tuoi colpi: sono troppi per scriverli tutti. Annoterò soltanto «molti». È la prima volta che arrotondo.")
		"bastet":
			return Lang.t("Li riconosco. Sono miei. Non te li ho prestati perché mi piaci: te li ho prestati perché cadi sempre in piedi. Quasi sempre.")
		"sobek":
			return Lang.t("Unghie piccole, per una preda grande. Ma anche il coccodrillo comincia dal morso piccolo: quello che non molla.")
		"iside":
			return Lang.t("Con quelle unghie Bastet difese mio figlio nelle paludi, quando io non potevo. Portale come le portò lei: per proteggere.")
		"horus":
			return Lang.t("Il gatto e il falco cacciano la stessa preda, uno da terra e uno dal cielo. Tu salta. Io guardo dall'alto.")
		"anubi":
			return Lang.t("Artigli di gatta sulla mia bilancia non ne ho mai pesati. Le gatte, Scriba, non si presentano al giudizio: ci passano accanto.")
		"nefti":
			return Lang.t("Graffi svelti, che non lasciano il tempo di piangere. Lascia a me il pianto, dunque. Tu continua a correre.")
		"shu":
			return Lang.t("Leggero sui piedi, quasi quanto me. Quando salti, per un respiro sei mio: lassù nessuno ti tocca.")
		"set":
			return Lang.t("La gattina ti ha dato le unghie! E tu gliele riporterai, vero, come un bravo servo? Tienile. Graffia qualcuno che conta.")
	return ""


## Lo Scettro di Ptah.
static func sceptre_line(god: String) -> String:
	match god:
		"ra":
			return Lang.t("Lo scettro di Ptah, che pensò il mondo prima che io lo illuminassi. I re lo stringevano davanti a me, all'alba. Tu lo stringi nel buio.")
		"sekhmet":
			return Lang.t("Un bastone che comanda. Io preferisco quelli che rompono. Ma dentro il tuo cerchio bruciano bene: resta lì, e portameli.")
		"thoth":
			return Lang.t("Ptah creò con la parola, io la scrivo. Quel raggio è una frase detta bene: breve, dritta, e trapassa chi ascolta.")
		"bastet":
			return Lang.t("Tre colpi e una luce. È lento, per i miei gusti. Ma chi entra nel tuo cerchio cammina come un topo nel miele. Questo mi diverte.")
		"sobek":
			return Lang.t("Pianti il bastone e la terra è tua. Così fa il coccodrillo con la riva: non insegue, aspetta che vengano a bere.")
		"iside":
			return Lang.t("Was, djed, ankh: dominio, stabilità, vita. Tre segni in un legno solo. Il terzo, Scriba, è quello che conta. Non scordarlo.")
		"horus":
			return Lang.t("Mio padre teneva uno scettro così, sul trono dei vivi. Lo conosco da quando ero alto quanto il suo ginocchio. Tienilo dritto.")
		"anubi":
			return Lang.t("Quello scettro lo reggono i re nelle statue, e le statue non mentono su chi sono. Mi domando cosa direbbe la tua.")
		"nefti":
			return Lang.t("Un cerchio di luce, e fuori il buio. Io sto sempre fuori dai cerchi, Scriba. Ma veglio su chi ci sta dentro.")
		"shu":
			return Lang.t("Il djed è la mia colonna: regge il cielo. La porti in cima a un bastone come fosse niente. Pesa più di quanto credi.")
		"set":
			return Lang.t("Guarda la testa di quello scettro. Guardala bene. È la MIA faccia, piccolo scriba: il was porta il muso di Set. Comandi con me, che ti piaccia o no.")
	return ""


## Il Banco di Apopi: la prima volta che un dio ti parla nella settima ora.
static func apep_line(god: String) -> String:
	match god:
		"ra":
			return Lang.t("Qui ogni notte mi fermo, e ogni notte lui beve il mio fiume. Non l'ho mai visto morire. Stanotte guardo te, e per la prima volta spero.")
		"sekhmet":
			return Lang.t("Il serpente! L'ho bruciato mille volte e mille volte è tornato. Non importa. Il bello non è ucciderlo: è farlo ancora.")
		"thoth":
			return Lang.t("La settima ora. Nei miei registri questa pagina è nera: l'inchiostro non c'entra, è Apopi che non si lascia scrivere.")
		"bastet":
			return Lang.t("Questo è il mio territorio di caccia. Guarda dove metti i piedi: le pozze nere non sono acqua, e le crepe respirano.")
		"sobek":
			return Lang.t("Ha bevuto il fiume. Il MIO fiume. Riportamelo, Scriba, e ti chiamerò fratello davanti a tutti i coccodrilli d'Egitto.")
		"iside":
			return Lang.t("Il suo sguardo addormentò i rematori di Ra, e io lo incantai con la voce. Tu non hai la mia voce: abbi almeno i miei occhi aperti.")
		"horus":
			return Lang.t("Mio zio Set lo trafigge dalla prua, ogni notte. È l'unica cosa buona che fa. Stanotte la prua è vuota: sali tu.")
		"anubi":
			return Lang.t("Sei oltre la mia bilancia, qui. Apopi non ha cuore da pesare. Chi cade sul suo banco non viene da me: non va da nessuno.")
		"nefti":
			return Lang.t("Qui il buio non è il mio. Il mio consola; questo divora. Se la luce se ne va, non cercarla: resta dove sei e guarda il rosso.")
		"shu":
			return Lang.t("Io tengo separati il cielo e la terra. Lui vuole che tornino una cosa sola, come prima del primo giorno. Non permetterglielo.")
		"set":
			return Lang.t("Ah, il verme. Sai che sono l'unico che non si addormenta quando guarda? Per questo mi tengono. Nessuno ringrazia mai, ma mi tengono.")
	return ""


static func speech(god: String) -> String:
	if not GODS.has(god):
		return ""
	var entries := _entries(god)
	var wid := "%s_%s" % [Run.weapon, god]
	if Meta.dialogue_seen.has("%s_0" % god) and not Meta.dialogue_seen.has(wid):
		var wl := bow_line(god) if Run.weapon == "arco" else (flail_line(god) if Run.weapon == "flagello" else "")
		if Run.weapon == "artigli":
			wl = claws_line(god)
		elif Run.weapon == "scettro":
			wl = sceptre_line(god)
		if wl != "":
			Meta.dialogue_seen.append(wid)
			Meta.save()
			return wl
	if Run.region >= 3 and not Run.trial and Meta.dialogue_seen.has("%s_0" % god) and not Meta.dialogue_seen.has("apep_%s" % god):
		var al := apep_line(god)
		if al != "":
			Meta.dialogue_seen.append("apep_%s" % god)
			Meta.save()
			return al
	for i in range(entries.size()):
		var id := "%s_%d" % [god, i]
		if not Meta.dialogue_seen.has(id):
			Meta.dialogue_seen.append(id)
			Meta.save()
			return entries[i]["text"]
	var idle: Array = GODS[god]["idle"]
	return idle.pick_random()


## La prossima lezione di Anubi non ancora ascoltata ("" se le ha dette tutte).
static func has_lesson() -> bool:
	for i in range(JUDGEMENT.size()):
		if not Meta.dialogue_seen.has("giudizio_%d" % i):
			return true
	return false


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
	var ricordi := []
	for i in range(RICORDI.size()):
		if not ricordo_visible(RICORDI[i]):
			continue
		var e := _entry(RICORDI[i], ricordo_open(RICORDI[i]))
		e["id"] = "ricordo_%d" % i
		e["new"] = e["seen"] and not Meta.dialogue_seen.has(e["id"])
		if not e["seen"]:
			e["text"] = Lang.t("Questo ricordo è ancora sepolto. Riaffiora quando cade un signore della notte.")
		ricordi.append(e)
	out.append({"title": Lang.t("Ricordi dello scriba"), "entries": ricordi})
	var judgement := []
	for i in range(JUDGEMENT.size()):
		judgement.append(_entry(JUDGEMENT[i], Meta.dialogue_seen.has("giudizio_%d" % i)))
	out.append({"title": Lang.t("Il giudizio"), "entries": judgement})
	for god in ["anubi", "ra", "sekhmet", "thoth", "bastet", "sobek", "iside", "horus", "set", "nefti"]:
		var list := []
		var entries := _entries(god)
		for i in range(entries.size()):
			list.append(_entry(entries[i], Meta.dialogue_seen.has("%s_%d" % [god, i])))
		out.append({"title": GODS[god]["name"], "entries": list})
	var chapters := []
	for id in Chapters.ALL:
		var c: Dictionary = Chapters.ALL[id]
		chapters.append(_entry({"title": Lang.t("Capitolo %d · %s") % [c["num"], c["name"]], "text": c["lore"]}, Chapters.is_unlocked(id)))
	out.append({"title": Lang.t("Il Libro dei Morti"), "entries": chapters})
	return out


static func _entry(e: Dictionary, seen: bool) -> Dictionary:
	return {"title": e["title"] if seen else "???", "text": e["text"] if seen else Lang.t("Questo papiro è ancora sigillato."), "seen": seen}


static func count_seen() -> Vector2i:
	var seen := 0
	var total := 0
	for cat in codex():
		for e in cat["entries"]:
			total += 1
			if e["seen"]:
				seen += 1
	return Vector2i(seen, total)


## I testi qui sopra sono in italiano (le costanti *_IT); il gioco legge le copie tradotte
## nella lingua scelta, rifatte da Lang.refresh_data() quando cambia la lingua.
static var GODS: Dictionary = Lang.deep(GODS_IT)
static var JUDGEMENT: Array = Lang.deep(JUDGEMENT_IT)
static var RICORDI: Array = Lang.deep(RICORDI_IT)


static func refresh_lang() -> void:
	GODS = Lang.deep(GODS_IT)
	JUDGEMENT = Lang.deep(JUDGEMENT_IT)
	RICORDI = Lang.deep(RICORDI_IT)
