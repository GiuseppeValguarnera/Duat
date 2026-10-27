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
		"intro": {"title": "La bilancia", "text": "Prima che tu discenda, Scriba, io ti peso. Ogni mio dono è un piatto della bilancia: ciò che prendi da un lato, lo lasci sull'altro. Così è il giudizio. Così sarà sempre."},
		"stories": [
			{"title": "L'imbalsamatore", "text": "Fui io a fasciare Osiride, quando il mondo non conosceva ancora la morte. Le mie mani furono le prime. Da allora i miei sacerdoti lavorano con il mio volto di sciacallo sul viso, perché nessun morto resti solo."},
			{"title": "Settanta giorni", "text": "Settanta giorni dura il cammino del corpo verso l'eternità. Quaranta sotto il natron, il sale del deserto, finché in lui non resta più acqua. Il cervello si getta: non serve. Il cuore resta al suo posto. Il cuore dovrà parlare, davanti a me."},
			{"title": "I vasi canopi", "text": "Quattro vasi, quattro guardiani: i figli di Horus. Imset dal volto d'uomo custodisce il fegato. Hapi il babbuino, i polmoni. Duamutef lo sciacallo, lo stomaco. Qebehsenuf il falco, le viscere. Nulla del morto va perduto."},
			{"title": "Perché lo sciacallo", "text": "Gli uomini vedevano gli sciacalli aggirarsi tra le tombe, al margine del deserto, e ne avevano paura. Allora pregarono lo sciacallo perché diventasse il custode di ciò che temevano. E io lo divenni."},
			{"title": "Prima di Osiride", "text": "Prima che Osiride sedesse sul trono dei morti, l'Occidente era mio. Glielo cedetti. Tenni per me la bilancia, perché il trono comanda, ma solo la bilancia conosce la verità."},
		],
		"idle": ["Scegli con cura. La bilancia non dimentica.", "Torna intero, Scriba. O torna comunque.", "Il cuore leggero va più lontano.", "Il primo passo è sempre il più leggero. È l'ultimo che pesa.", "Ho pesato re e mendicanti. Il cuore di un re non pesa di meno."],
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
		"idle": ["Brucia, Scriba. La notte è lunga.", "La fiamma non chiede permesso.", "Ogni sera muoio. Ogni mattina ritorno. Fa' lo stesso.", "Dove passo io, il buio arretra. Dove passi tu?", "Anche il sole teme la dodicesima ora. Non per questo si ferma.", "Brucia ciò che ti sbarra la strada. Il resto lo illuminerò io."],
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
		"idle": ["Più forte.", "Fa' che ti temano.", "La pietà è per chi ha già vinto.", "Ancora. Ancora!", "Sento il loro terrore da qui. È un buon odore.", "Non chiedermi di essere gentile. Chiedimi di vincere."],
	},
	"thoth": {
		"name": "Thoth, lo Scriba degli dèi",
		"intro": {"title": "Chi è Thoth", "text": "Io sono Thoth, signore delle parole divine, misuratore del tempo, voce della luna. Quando il cuore viene pesato, è la mia mano a scrivere il verdetto. Anche tu sei uno scriba. Dimostrami che il tuo Occhio è preciso quanto il mio calamo."},
		"stories": [
			{"title": "Le parole divine", "text": "Io diedi agli uomini i segni: le parole divine, che i popoli venuti dopo chiameranno geroglifici. Alcuni sono suoni, altri sono idee, tutti sono vivi. Ciò che è scritto esiste per sempre. Ciò che viene cancellato non è mai esistito. Tu lo sai meglio di chiunque."},
			{"title": "I cinque giorni", "text": "Ra aveva decretato che Nut non avrebbe partorito in alcun giorno dell'anno. Così sfidai la Luna al gioco e le vinsi parte della sua luce: cinque giorni nuovi, fuori dal calendario. In quei giorni nacquero Osiride, Iside, Set e Nefti. Ogni decreto ha una crepa. Io la trovo."},
			{"title": "L'Occhio di Horus", "text": "Set strappò l'occhio a Horus e lo ridusse in frantumi. Io li raccolsi, uno a uno, e lo risanai. Quell'occhio, il wedjat, divenne il segno di ciò che è intero e protetto. È lo stesso che tu scagli contro i tuoi nemici. Usalo con rispetto."},
			{"title": "Al giudizio", "text": "Nella Sala delle Due Verità il cuore giace su un piatto e la piuma di Ma'at sull'altro. Anubi osserva il filo della bilancia. Io scrivo. Senza la scrittura, nemmeno gli dèi saprebbero chi è giusto."},
			{"title": "Milioni di ibis", "text": "Mi venerano come ibis e come babbuino, che all'alba leva le braccia e grida verso il sole. Per secoli i pellegrini mi offrirono ibis imbalsamati, a milioni, deposti nelle gallerie di Saqqara e di Tuna el-Gebel. Ogni ibis era una preghiera. Le ho lette tutte."},
		],
		"idle": ["Misura. Poi colpisci.", "Ogni colpo è una parola. Scrivi bene.", "La conoscenza non si spunta.", "Ho già scritto come finirà questa stanza. Non ti dirò come.", "Contare i nemici è il primo passo per non temerli.", "Una parola sbagliata nel Libro, e il morto si perde. Anche un colpo sbagliato."],
	},
	"bastet": {
		"name": "Bastet, la Signora di Bubasti",
		"intro": {"title": "Chi è Bastet", "text": "Io sono Bastet, la Signora di Bubasti. Veglio sulle case, sulle madri, sui bambini che dormono. Per loro ho le fusa. Per chi li minaccia, ho gli artigli. Avvicinati, piccolo scriba. Ti presto i miei."},
		"stories": [
			{"title": "Da leonessa a gatta", "text": "Un tempo ero leonessa, feroce come Sekhmet. Poi gli uomini mi accolsero nelle loro case e io divenni gatta: dolce al focolare, terribile nella notte. La ferocia non mi ha lasciata, Scriba. Ha soltanto imparato ad attendere."},
			{"title": "La festa di Bubasti", "text": "Per la mia festa risalivano il Fiume a centinaia di migliaia, sulle barche, cantando, battendo le mani, suonando i flauti. Un viaggiatore greco, Erodoto, li contò: settecentomila. Scrisse che in quei giorni si beveva più vino che in tutto il resto dell'anno. Ne fui lieta."},
			{"title": "I gatti sacri", "text": "I miei figli difendevano il grano dai topi e le case dai serpenti. Chi uccideva un gatto, anche per errore, poteva pagarlo con la vita. E quando un gatto moriva, la sua famiglia si radeva le sopracciglia in segno di lutto. Così si onora chi ti protegge."},
			{"title": "La profezia dei gatti", "text": "Imbalsamarono i miei figli a migliaia e li deposero accanto a me. Vedo ciò che accadrà: verranno uomini da una terra fredda e li porteranno via a tonnellate, centottantamila, per concimare i loro campi. Una dea vede anche questo. E non dimentica."},
			{"title": "Il Grande Gatto", "text": "Sotto l'albero sacro di Eliopoli, il Grande Gatto afferrò il coltello e recise la testa del serpente Apophis. Alcuni dicono che fosse Ra stesso. Altri dicono che fossi io. Io non li correggo."},
		],
		"idle": ["Colpisci dove duole. Poi svanisci.", "Nove vite? Tu ne hai una alla volta. Custodiscila.", "Va'. Ti osservo.", "Fusa per chi amo. Artigli per tutti gli altri.", "Muoviti piano. Poi non muoverti affatto. Poi colpisci.", "Un gatto non corre mai, a meno che non stia vincendo."],
	},
	"sobek": {
		"name": "Sobek, il Signore del Fiume",
		"intro": {"title": "Chi è Sobek", "text": "Io sono Sobek, Signore del Fiume. La mia pelle è più dura della pietra, la mia pazienza più lunga delle piene. Il Nilo dà la vita alla Terra Nera, e io sono il Nilo quando morde. Prendi la mia forza, piccolo uomo."},
		"stories": [
			{"title": "La Terra Nera", "text": "Ogni anno il Fiume si gonfia e ricopre i campi. Quando si ritira, lascia il limo nero, la terra che nutre. Per questo gli uomini chiamarono il loro paese Kemet, la Terra Nera. Alcuni scrissero che le acque nascono da me. Io lascio che lo credano."},
			{"title": "Il figlio dagli orecchini d'oro", "text": "Nella città dei coccodrilli, nel Fayyum, un mio figlio sacro viveva dentro un lago. Lo adornavano di orecchini d'oro e anelli alle zampe. I pellegrini gli offrivano pane, carne e vino, e un greco di nome Strabone venne a vederlo mangiare. Il Fiume onora chi lo onora."},
			{"title": "Kom Ombo", "text": "A Kom Ombo il mio tempio è diviso in due: una metà è mia, l'altra di Horus il Vecchio. Due porte, due santuari, sotto un solo tetto. Nelle sue tombe dormono i miei figli imbalsamati, e accanto a loro le loro uova."},
			{"title": "Temuto e pregato", "text": "Sul Fiume i miei figli uccidevano. Chi lavava i panni, chi pescava, chi guadava. Per questo gli uomini mi pregavano. Chi può divorarti, è meglio averlo amico."},
		],
		"idle": ["Resisti. Il Fiume non si ferma.", "Attendi. Poi mordi.", "Pelle dura. Cuore lento.", "Il Fiume ha tempo. Tu no. Sbrigati.", "Chi mi sottovaluta finisce sott'acqua.", "Mordi, trattieni, non lasciare."],
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
		"idle": ["Ti proteggo io. Tu pensa a vivere.", "Ogni ferita si richiude, prima o poi.", "Ho ricomposto un dio. Posso ricomporre te.", "Non sei solo, Scriba. Non lo sei mai stato.", "Le mie ali coprono anche chi non le vede.", "Torna da me intero. Ho già ricucito abbastanza."],
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
		"idle": ["Mira come il falco: dall'alto, una volta sola.", "Il mio Occhio non manca il bersaglio. Tu?", "Vola, Scriba.", "Il falco non insegue la preda. La aspetta dall'alto.", "Mio padre regna sui morti. Io regno sui vivi. Tu, per ora, su questa stanza.", "Lancia. E quando torna, lancia ancora."],
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
		"idle": ["Prima il prezzo, poi il premio.", "Il dolore insegna. Tu impari lentamente.", "Un patto è un patto.", "Ti piace soffrire? A me piace guardare.", "La tempesta non chiede scusa. Nemmeno io.", "I tuoi dèi luminosi ti hanno mai fatto un'offerta onesta? Io sì: prima il dolore, poi il premio."],
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
	{"needs": 1, "boss": "aker", "title": "IV · Il nome nascosto", "text": "Nel nono anno il re andò a Iunu, la città del sole, e non volle nessuno con sé. Nemmeno me. Lo scrissi lo stesso: il re visitò il tempio di Ra e offrì mille pani. È quello che si scrive. Ma io so che entrò nella sala dove nessun uomo entra, quella dove i sacerdoti custodiscono la storia di Iside e del nome segreto. So che il buio là dentro odora di cedro e di cera. So che le parole si dicono a bassa voce, perché anche il muro ascolta. Le dico... le disse. Uscì all'alba. Quel giorno il sole sorse, come sempre. Il sole sorse ogni giorno, finché il re visse."}
]


## Ogni ricordo si sblocca con le vittorie su un boss di regione: Am-heh (I-III, la gloria del re),
## Aker (IV, il nome nascosto).
static func ricordo_boss(r: Dictionary) -> String:
	return str(r.get("boss", "amheh"))


## I ricordi di Sokar compaiono nei Papiri (anche sigillati) solo dopo che ci sei arrivato.
## (Non si usa Run qui: Lore si carica con le lingue all'avvio, e Run dipende dalle lingue.)
static func ricordo_visible(r: Dictionary) -> bool:
	return ricordo_boss(r) != "aker" or Meta.sokar_seen


static func ricordo_open(r: Dictionary) -> bool:
	var wins: int = Meta.aker_wins if ricordo_boss(r) == "aker" else Meta.ammit_wins
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
	for god in ["anubi", "ra", "sekhmet", "thoth", "bastet", "sobek", "iside", "horus", "set"]:
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
