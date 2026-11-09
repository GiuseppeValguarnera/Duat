class_name Tales
extends RefCounted
## «Racconti dell'acqua» (blocco 15): brevi storie sul Nilo e sul Duat che la vasca della Sala
## racconta, una per ogni cosa sbloccata o raggiunta. Solo miti egizi veri (testi delle piramidi,
## Libro dei Morti, Amduat, i templi di Esna e Kom Ombo, Plutarco per Osiride). Le storie lette
## sono in Meta.tales_read; quelle sbloccate e non ancora lette hanno il segno.


## [id, titolo, testo, sbloccata?, come si sblocca]
static func all() -> Array:
	return [
		["nun", Lang.t("Le acque di Nun"),
			Lang.t("Prima del cielo e della terra c'era solo Nun: acqua scura, immobile, senza fondo. Da quell'acqua emerse una collina, la prima terra, e sulla collina si posò la luce. Ogni anno, quando il Nilo si ritira e lascia i campi coperti di limo, l'Egitto rivede quel primo mattino."),
			true, ""],
		["hapi", Lang.t("Hapi e la piena"),
			Lang.t("Hapi è la piena del fiume: un dio dal ventre pieno, con papiri e loti sul capo, che porta offerte invece di chiederne. Si diceva che abitasse nelle caverne vicino alla prima cateratta, da dove versava l'acqua. Una piena giusta era pane per tutti; una piena troppo bassa, la fame."),
			Meta.runs >= 1, Lang.t("Torna dalla tua prima discesa.")],
		["bilancia", Lang.t("La pesatura del cuore"),
			Lang.t("Nella sala delle Due Verità il cuore del morto va su un piatto della bilancia, la piuma di Ma'at sull'altro. Anubi controlla il filo a piombo, Thoth scrive il verdetto. Se il cuore è leggero, il morto passa ai campi di Iaru; se è pesante, lo divora Ammit. Per questo i vivi recitavano: «Cuore mio, non testimoniare contro di me»."),
			Meta.runs >= 3, Lang.t("Torna tre volte dalla discesa.")],
		["ra_duat", Lang.t("Le dodici ore della notte"),
			Lang.t("Ogni sera Ra entra nel Duat sulla sua barca e lo attraversa in dodici ore, porta dopo porta. Alla settima ora lo attende Apopi, il serpente del caos, che vuole fermare la barca: gli dèi lo legano e lo trafiggono. All'alba Ra rinasce a oriente come Khepri, lo scarabeo che spinge il sole."),
			Meta.serpent_wins >= 1, Lang.t("Supera il Serpente della Porta.")],
		["sobek", Lang.t("Sobek, signore delle acque"),
			Lang.t("Sobek ha la testa di coccodrillo e il Nilo come casa. A Shedet, nel Fayum, e a Kom Ombo si allevavano coccodrilli sacri in vasche come questa: li ornavano d'oro e di orecchini, li nutrivano con pane e carne. Temuto e pregato insieme, Sobek dava forza ai faraoni e fertilità alle rive."),
			Meta.dialogue_seen.has("sobek_0"), Lang.t("Incontra Sobek nella discesa.")],
		["neith", Lang.t("Neith che uscì dalle acque"),
			Lang.t("A Esna si raccontava che Neith, la dea di Sais, fosse uscita per prima da Nun e avesse creato il mondo con sette parole. Poi diede alla luce Ra. La chiamavano anche madre di Sobek, il coccodrillo. Arco e frecce erano il suo simbolo: tesseva il mondo e lo difendeva."),
			Meta.weapons_unlocked.has("lancia"), Lang.t("Entra nel Cortile di Neith.")],
		["osiride", Lang.t("Il corpo di Osiride"),
			Lang.t("Set chiuse il fratello Osiride in una cassa e la gettò nel Nilo; poi ne fece a pezzi il corpo e lo sparse per l'Egitto. Iside cercò i pezzi uno a uno, Anubi li ricompose e li avvolse nel lino: fu la prima mummia. Osiride divenne re dei morti, e il grano che rinasce dal limo era il segno della sua vita."),
			not Meta.restorations.is_empty(), Lang.t("Restaura qualcosa nella Sala.")],
		["iside", Lang.t("Le lacrime di Iside"),
			Lang.t("Quando Iside piangeva Osiride, si diceva, le sue lacrime cadevano nel fiume e lo facevano salire. Ancora in tempi recenti, a giugno, gli egiziani festeggiavano la Notte della Goccia: la prima lacrima della dea che annuncia la piena. Il dolore di una sposa che diventa pane per un paese intero."),
			Meta.dialogue_seen.has("iside_0") or Meta.tears > 0, Lang.t("Incontra Iside, o raccogli una Lacrima.")],
		["lago", Lang.t("Il Lago di Fuoco"),
			Lang.t("Il Libro dei Morti descrive un lago di fuoco custodito da quattro babbuini. Per il giusto le sue fiamme sono acqua fresca e cibo; per il dannato bruciano. Lì vive Am-heh, «colui che divora milioni», con il muso di cane: chi lo supera ha già un piede oltre la notte."),
			Meta.ammit_wins >= 1, Lang.t("Sconfiggi Am-heh.")],
		["sokar", Lang.t("La terra di Sokar"),
			Lang.t("Alla quarta e alla quinta ora della notte la barca di Ra arriva a Rosetau, la terra di Sokar, il dio falco di Menfi. Lì non c'è acqua, solo sabbia: la barca diventa un serpente e gli dèi la tirano a braccia attraverso il deserto, mentre sotto, nascosto, riposa il corpo del dio."),
			Meta.sokar_seen, Lang.t("Arriva nella terra di Sokar.")],
		["serket", Lang.t("Serket che fa respirare"),
			Lang.t("Serket, la dea scorpione, porta sul capo l'animale che può uccidere. Il suo nome dice «colei che fa respirare la gola»: i guaritori la invocavano contro il veleno. Aiutò Iside a nascondere il piccolo Horus nelle paludi e veglia, con altre tre dee, sui vasi che custodiscono gli organi dei morti."),
			Meta.serket_wins >= 1, Lang.t("Sconfiggi Serket.")],
		["aker", Lang.t("I leoni dell'orizzonte"),
			Lang.t("Aker è la terra stessa, il varco dove il sole entra la sera ed esce al mattino. Lo disegnavano come due leoni schiena contro schiena, con il sole tra loro: uno guarda l'ovest e si chiama Ieri, l'altro guarda l'est e si chiama Domani. Custodisce le porte, perché la notte non esca dal Duat."),
			Meta.aker_wins >= 1, Lang.t("Sconfiggi Aker.")],
		# dal Tesoro della Sfinge (blocco 17)
		["harmachis", Lang.t("Horemakhet, Horus nell'orizzonte"),
			Lang.t("Nel Nuovo Regno la Grande Sfinge di Giza era venerata come Horemakhet, «Horus nell'orizzonte»: il sole che sorge, che lei guarda da sempre verso oriente. I pellegrini le lasciavano stele con orecchie scolpite, perché il dio ascoltasse le loro preghiere."),
			SphinxShop.owns("s_harmachis"), Lang.t("Si trova nel Tesoro della Sfinge.")],
		["thutmose", Lang.t("Il sogno di Thutmose"),
			Lang.t("Il giovane principe Thutmose si addormentò, durante una caccia, all'ombra della Sfinge sepolta fino al collo nella sabbia. In sogno il dio gli promise il trono se l'avesse liberata. Diventato re, Thutmose IV fece togliere la sabbia e pose tra le sue zampe una stele che racconta il sogno: è ancora lì."),
			SphinxShop.owns("s_thutmose"), Lang.t("Si trova nel Tesoro della Sfinge.")],
	]


static func unlocked() -> Array:
	return all().filter(func(e: Array) -> bool: return bool(e[3]))


static func is_new(id: String) -> bool:
	return not Meta.tales_read.has(id)


static func unread() -> int:
	var n := 0
	for e in unlocked():
		if is_new(String(e[0])):
			n += 1
	return n


static func mark_read(id: String) -> void:
	if not Meta.tales_read.has(id):
		Meta.tales_read.append(id)
		Meta.save()


## Il prossimo racconto ancora nascosto: come si sblocca (vuoto se sono tutti aperti).
static func next_hint() -> String:
	for e in all():
		if not bool(e[3]):
			return String(e[4])
	return ""
