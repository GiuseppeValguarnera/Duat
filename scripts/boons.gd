class_name Boons
## REGOLA DI BILANCIAMENTO
## Un dono normale di livello 1 vale circa +20% su un solo aspetto del gioco
## (danni del khopesh, danni dell'Occhio, difesa, mobilità...). I livelli 2 e 3 aggiungono
## circa metà di quel valore ciascuno. Un dono pesante vale circa +50%, con un prezzo.
## Un dono di Anubi ha un vantaggio di poco più grande del prezzo.
## Prima di aggiungere un dono, confrontalo con questa misura.
## Dèi, doni, doni pesanti e patti di Set.
## Per aggiungere un dono: una riga in ALL, poi il suo effetto in run.gd.

const MAX_LEVEL := 3
## Da quale stanza in poi un dio può comparire (1 = da subito). Es.: {"sekhmet": 3}
const MIN_ROOM := {}
## Probabilità che tra le tre scelte compaia il dono pesante del dio.
const HEAVY_CHANCE := 0.35

const GODS_IT := {
	"ra": {"name": "Ra", "color": Color(0.96, 0.65, 0.14)},
	"sekhmet": {"name": "Sekhmet", "color": Color(0.94, 0.37, 0.24)},
	"thoth": {"name": "Thoth", "color": Color(0.31, 0.76, 0.78)},
	"bastet": {"name": "Bastet", "color": Color(0.4, 0.85, 0.5)},
	"sobek": {"name": "Sobek", "color": Color(0.62, 0.66, 0.28)},
	"iside": {"name": "Iside", "color": Color(0.95, 0.56, 0.76)},
	"horus": {"name": "Horus", "color": Color(0.36, 0.55, 1.0)},
	"set": {"name": "Set", "color": Color(0.78, 0.25, 0.2)},
	"anubi": {"name": "Anubi", "color": Color(0.62, 0.56, 0.92)},
	"nefti": {"name": "Nefti", "color": Color(0.78, 0.84, 0.96)},          # argento e blu notte
	"shu": {"name": "Shu", "color": Color(0.97, 0.93, 0.82)},             # bianco perla con riflessi d'oro
	"duo": {"name": "Doppio", "color": Color(1.0, 0.86, 0.45)},
	# blocco 17: i doni della Sfinge (prova della Sfinge; nelle discese solo col Favore della Sfinge)
	"sfinge": {"name": "Sfinge", "color": Color(0.84, 0.69, 0.44)},          # arenaria
}

## `values` = il numero del dono ai livelli 1, 2 e 3 (entra nel %d della descrizione).
## I doni pesanti hanno un solo livello e un prezzo (`cost`).
const ALL_IT := {
	"ra_burn": {"god": "ra", "name": "Colpo Solare", "desc": "Il khopesh incendia i nemici: %d danni ogni mezzo secondo per 2 secondi.", "values": [4, 5, 6]},
	"ra_disc": {"god": "ra", "name": "Disco di Ra", "desc": "L'Occhio di Horus esplode quando si ferma: %d danni a chi sta vicino.", "values": [14, 20, 26]},
	"ra_dawn": {"god": "ra", "name": "Corsa dell'Alba", "desc": "Lo scatto ferisce i nemici che attraversi (%d danni) e li incendia per 1 secondo.", "values": [4, 6, 8], "cost": "Lo scatto si ricarica il 40% più lentamente."},
	"ra_eye": {"god": "ra", "name": "Occhio Ardente", "desc": "L'Occhio di Horus incendia i nemici e fa il %d%% di danni in più.", "values": [15, 30, 45]},
	"sekhmet_fury": {"god": "sekhmet", "name": "Furia della Leonessa", "desc": "+%d%% ai danni del khopesh.", "values": [20, 30, 40]},
	"sekhmet_blood": {"god": "sekhmet", "name": "Sete di Sangue", "desc": "Ogni 5 nemici abbattuti ti curi di %d punti vita.", "values": [3, 4, 5]},
	"sekhmet_roar": {"god": "sekhmet", "name": "Ruggito", "desc": "Il terzo colpo della combo libera un'onda d'urto attorno a te: %d danni.", "values": [10, 14, 18]},
	"sekhmet_leap": {"god": "sekhmet", "name": "Balzo della Leonessa", "desc": "L'attacco in scatto (un colpo durante lo scatto o subito dopo) fa il %d%% di danni in più.", "values": [50, 75, 100]},
	# Thoth: tempo, parole e misura (rifatto nel blocco 10). Il nome di una cosa, detto per primo, la ferisce.
	"thoth_first": {"god": "thoth", "name": "Prima Parola", "desc": "Il primo colpo che dai a ogni nemico fa il %d%% di danni in più (sui boss, una volta per fase).", "values": [40, 60, 80]},
	"thoth_hourglass": {"god": "thoth", "name": "Clessidra di Thoth", "desc": "La prima volta in ogni stanza che vieni colpito, nemici e proiettili rallentano del 60%% per %.1f secondi; tu no.", "values": [1.2, 1.6, 2.0]},
	"thoth_glyph": {"god": "thoth", "name": "Geroglifo Scritto", "desc": "Ogni 8 colpi a segno (armi e Occhio) un geroglifo colpisce i tre nemici più vicini: %d danni.", "values": [12, 18, 24]},
	"thoth_timing": {"god": "thoth", "name": "Tempo Giusto", "desc": "L'attacco caricato si ricarica il %d%% più in fretta (mai sotto 1,8 secondi). La carica dura come prima.", "values": [15, 22, 30]},
	"thoth_lesson": {"god": "thoth", "name": "Lezione dello Scriba", "desc": "All'inizio di ogni regione e dopo ogni boss, uno dei tuoi doni a caso sale di un livello (al massimo una volta per regione)."},
	"thoth_judgment": {"god": "thoth", "rare": true, "name": "Giudizio di Thoth", "desc": "I nemici normali sotto il 12% della vita muoiono subito (non élite e boss)."},
	"duo_thoth_anubi": {"god": "duo", "gods": ["thoth", "anubi"], "name": "Registro dei Morti", "desc": "Gli spiriti della Guida delle Anime applicano anche la Prima Parola."},
	"duo_thoth_iside": {"god": "duo", "gods": ["thoth", "iside"], "name": "Nome Vero", "desc": "La Prima Parola ti dà anche uno scudo di 4 (non si somma oltre 12)."},
	# Bastet: colpi critici e agilità
	"bastet_claws": {"god": "bastet", "name": "Artigli Affilati", "desc": "Il khopesh ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [15, 22, 30]},
	"bastet_eyes": {"god": "bastet", "name": "Occhi di Gatto", "desc": "L'Occhio di Horus ha il %d%% di probabilità di fare un colpo critico (danni doppi).", "values": [15, 25, 35]},
	"bastet_step": {"god": "bastet", "name": "Passo Felino", "desc": "Lo scatto si ricarica il %d%% più in fretta.", "values": [20, 30, 40]},
	"bastet_lives": {"god": "bastet", "name": "Protezione di Bastet", "desc": "La prima volta che muori in questa run ti rialzi con il %d%% della vita.", "values": [30, 40, 50]},
	# Sobek: resistenza, controllo, acqua
	"sobek_skin": {"god": "sobek", "name": "Pelle di Coccodrillo", "desc": "Subisci il %d%% di danni in meno.", "values": [12, 18, 24]},
	"sobek_bite": {"god": "sobek", "name": "Morso di Sobek", "desc": "Il terzo colpo della combo stordisce i nemici per %.1f secondi.", "values": [0.6, 0.9, 1.2]},
	"sobek_tide": {"god": "sobek", "name": "Marea del Nilo", "desc": "Alla fine dello scatto lasci una pozza che rallenta i nemici del %d%% per 3 secondi.", "values": [30, 40, 50]},
	"sobek_river": {"god": "sobek", "name": "Forza del Fiume", "desc": "I nemici storditi dal Morso di Sobek o rallentati dalla Marea del Nilo subiscono il %d%% di danni in più.", "values": [20, 30, 40]},
	# doni che esistono solo per un'arma: compaiono soltanto se la impugni
	"sobek_tail": {"god": "sobek", "weapon": "lancia", "name": "Colpo di Coda", "desc": "La spazzata della lancia fa il %d%% di danni in più e scaglia i nemici il doppio più lontano.", "values": [25, 35, 45]},
	"sekhmet_crescent": {"god": "sekhmet", "weapon": "khopesh", "name": "Zanna Ricurva", "desc": "I primi due fendenti del khopesh fanno il %d%% di danni in più.", "values": [20, 30, 40]},
	"bastet_point": {"god": "bastet", "weapon": "lancia", "name": "Punta Felina", "desc": "L'attacco in scatto della lancia (l'affondo in corsa) ha il %d%% di probabilità di essere un colpo critico.", "values": [35, 50, 65]},
	"bastet_dance": {"god": "bastet", "weapon": "khopesh", "name": "Danza delle Lame", "desc": "Il khopesh colpisce il %d%% più rapidamente.", "values": [10, 15, 20]},
	"ra_edge": {"god": "ra", "weapon": "khopesh", "name": "Filo del Sole", "desc": "I fendenti del khopesh arrivano il %d%% più lontano e sono più ampi.", "values": [12, 18, 25]},
	# l'Arco di Satet: doni solo per l'arco (frecce = i colpi rapidi; tiro carico = tenendo premuto)
	"arco_ra": {"god": "ra", "weapon": "arco", "name": "Frecce del Sole", "desc": "Le frecce incendiano i nemici: %d danni ogni mezzo secondo per 2 secondi.", "values": [4, 5, 6]},
	"arco_sekhmet": {"god": "sekhmet", "weapon": "arco", "name": "Tiro della Leonessa", "desc": "Il tiro carico fa il %d%% di danni in più.", "values": [30, 45, 60]},
	"arco_thoth": {"god": "thoth", "weapon": "arco", "name": "Freccia Sapiente", "desc": "Le frecce trapassano un nemico: quello dietro subisce il %d%% dei danni.", "values": [60, 80, 100]},
	"arco_bastet": {"god": "bastet", "weapon": "arco", "name": "Occhio della Gatta", "desc": "Il tiro carico ha il %d%% di probabilità di essere un colpo critico.", "values": [35, 50, 65]},
	"arco_sobek": {"god": "sobek", "weapon": "arco", "name": "Frecce della Palude", "desc": "Le frecce rallentano i nemici del %d%% per 2 secondi.", "values": [20, 28, 36]},
	"arco_iside": {"god": "iside", "weapon": "arco", "name": "Respiro di Iside", "desc": "Con l'arco teso a pieno ricevi uno scudo di %d (non si somma).", "values": [5, 7, 9]},
	"arco_ricochet": {"god": "horus", "weapon": "arco", "name": "Ricochet del Falco", "desc": "Dopo un colpo la freccia rimbalza sul nemico più vicino non ancora colpito, con il %d%% dei danni (al livello 3 rimbalza due volte).", "values": [60, 80, 80]},
	"arco_anubi": {"god": "anubi", "weapon": "arco", "balanced": true, "name": "Faretra dello Sciacallo", "desc": "Ogni colpo scocca %d frecce a ventaglio.", "values": [2], "cost": "Ogni freccia fa il 35% di danni in meno."},
	"arco_nefti": {"god": "nefti", "weapon": "arco", "name": "Freccia del Lutto", "desc": "Il tiro carico marchia col Lutto: chi muore marchiato ti cura di %d.", "values": [2, 3, 4]},
	"arco_shu": {"god": "shu", "weapon": "arco", "name": "Freccia del Vento", "desc": "Il tiro carico spinge via chi trapassa: se sbatte, schianto da %d danni.", "values": [8, 12, 16]},
	# il Flagello di Osiride: frustate in linea (danni pieni alla punta) e l'aggancio del pastorale
	"flagello_ra": {"god": "ra", "weapon": "flagello", "name": "Frusta del Sole", "desc": "La terza frustata incendia i nemici: %d danni ogni mezzo secondo per 2 secondi.", "values": [4, 5, 6]},
	"flagello_sekhmet": {"god": "sekhmet", "weapon": "flagello", "name": "Morso della Punta", "desc": "I colpi di punta del flagello fanno il %d%% di danni in più.", "values": [25, 35, 45]},
	"flagello_thoth": {"god": "thoth", "weapon": "flagello", "name": "Frusta Sapiente", "desc": "Le frustate arrivano il %d%% più lontano.", "values": [15, 22, 30]},
	"flagello_bastet": {"god": "bastet", "weapon": "flagello", "name": "Presa della Gatta", "desc": "L'aggancio del pastorale è sempre critico e fa il %d%% di danni in più.", "values": [20, 35, 50]},
	"flagello_sobek": {"god": "sobek", "weapon": "flagello", "name": "Frusta della Palude", "desc": "Le frustate rallentano i nemici del %d%% per 2 secondi.", "values": [15, 22, 30]},
	"flagello_iside": {"god": "iside", "weapon": "flagello", "name": "Pastorale di Iside", "desc": "Ogni aggancio ti dà uno scudo di %d (non si somma).", "values": [6, 9, 12]},
	"flagello_horus": {"god": "horus", "weapon": "flagello", "name": "Pastorale del Falco", "desc": "Agganciare un nemico ricarica subito l'Occhio di Horus."},
	"flagello_anubi": {"god": "anubi", "weapon": "flagello", "balanced": true, "name": "Ritmo dello Sciacallo", "desc": "Le frustate sono il %d%% più rapide.", "values": [30], "cost": "La frusta arriva il 20% meno lontano."},
	"flagello_nefti": {"god": "nefti", "weapon": "flagello", "name": "Pastorale del Lutto", "desc": "Chi agganci è marchiato col Lutto: se muore ti cura di %d.", "values": [2, 3, 4]},
	# Artigli di Bastet e Scettro di Ptah (12/11): quattro doni per arma
	"artigli_bastet": {"god": "bastet", "weapon": "artigli", "name": "Nove Vite", "desc": "Gli artigli hanno il %d%% in più di probabilità di colpo critico.", "values": [10, 15, 20]},
	"artigli_sekhmet": {"god": "sekhmet", "weapon": "artigli", "name": "Furia della Leonessa", "desc": "Il Balzo della Gatta fa il %d%% di danni in più.", "values": [30, 45, 60]},
	"artigli_sobek": {"god": "sobek", "weapon": "artigli", "name": "Presa del Coccodrillo", "desc": "I graffi rallentano i nemici del %d%% per 2 secondi.", "values": [15, 22, 30]},
	"artigli_iside": {"god": "iside", "weapon": "artigli", "name": "Passo Felpato", "desc": "Ogni Balzo della Gatta ti dà uno scudo di %d (non si somma).", "values": [5, 7, 9]},
	"scettro_thoth": {"god": "thoth", "weapon": "scettro", "name": "Parola di Potere", "desc": "Il raggio dello scettro arriva il %d%% più lontano.", "values": [20, 30, 40]},
	"scettro_ra": {"god": "ra", "weapon": "scettro", "name": "Sole di Ptah", "desc": "Le scariche del Cerchio del Dominio fanno il %d%% di danni in più.", "values": [30, 45, 60]},
	"scettro_sekhmet": {"god": "sekhmet", "weapon": "scettro", "name": "Verga della Leonessa", "desc": "I primi due colpi dello scettro fanno il %d%% di danni in più.", "values": [15, 22, 30]},
	"scettro_iside": {"god": "iside", "weapon": "scettro", "name": "Cerchio di Iside", "desc": "Dentro il Cerchio del Dominio subisci il %d%% di danni in meno.", "values": [15, 22, 30]},
	"flagello_shu": {"god": "shu", "weapon": "flagello", "name": "Lancio del Vento", "desc": "Chi lanci col pastorale, se sbatte, subisce uno schianto da %d danni.", "values": [12, 18, 24]},
	# Iside: protezione, cure, magia
	"iside_wings": {"god": "iside", "name": "Ali di Iside", "desc": "All'inizio di ogni stanza hai uno scudo che assorbe %d danni.", "values": [10, 15, 20]},
	"iside_tears": {"god": "iside", "name": "Lacrime di Iside", "desc": "Tutte le cure ti curano il %d%% in più.", "values": [20, 30, 40]},
	"iside_knot": {"god": "iside", "name": "Nodo di Iside", "desc": "Sotto un terzo della vita subisci il %d%% di danni in meno.", "values": [25, 35, 45]},
	"iside_word": {"god": "iside", "name": "Nome Segreto di Ra", "desc": "Il Sekhem si carica il %d%% più in fretta.", "values": [25, 40, 55]},
	# Anubi pesa ogni cosa: i suoi doni sono bilance, un vantaggio un po' più grande del prezzo.
	"horus_return": {"god": "horus", "name": "Ritorno del Falco", "desc": "L'Occhio di Horus, finito il volo, torna da te e colpisce di nuovo chi incontra: %d%% dei danni.", "values": [60, 80, 100]},
	"horus_seek": {"god": "horus", "name": "Volo del Falco", "desc": "L'Occhio di Horus curva da solo verso il nemico più vicino e fa il %d%% di danni in più.", "values": [10, 20, 30]},
	"horus_multi": {"god": "horus", "name": "Occhio Moltiplicato", "desc": "L'Occhio di Horus scaglia %d raggi a ventaglio, ognuno con il 60%% dei danni.", "values": [3, 4, 5]},
	"horus_pierce": {"god": "horus", "name": "Occhio Penetrante", "desc": "L'Occhio di Horus trapassa fino a %d nemici.", "values": [2, 3, 4]},
	"horus_twin": {"god": "horus", "name": "Il Sole e la Luna", "desc": "L'Occhio di Horus ha %d cariche: puoi lanciarlo più volte di fila.", "values": [2, 3, 4]},
	"horus_harpoon": {"god": "horus", "weapon": "lancia", "name": "Arpione di Horus", "desc": "Gli affondi della lancia fanno il %d%% di danni in più ai nemici lontani, sulla punta.", "values": [25, 40, 55]},
	"horus_mark": {"god": "horus", "name": "Sguardo del Falco", "desc": "I nemici colpiti dall'Occhio subiscono il %d%% di danni in più dal khopesh per 3 secondi.", "values": [20, 30, 40]},
	"anubi_light": {"god": "anubi", "balanced": true, "name": "Cuore Leggero", "desc": "Lo scatto si ricarica il %d%% più in fretta e ti muovi il 12%% più veloce.", "values": [20], "cost": "-5 vita massima."},
	"anubi_stone": {"god": "anubi", "balanced": true, "name": "Cuore di Pietra", "desc": "+%d vita massima.", "values": [12], "cost": "Fai il 5% di danni in meno."},
	"anubi_jackal": {"god": "anubi", "balanced": true, "name": "Fiuto dello Sciacallo", "desc": "+%d%% di danni ai nemici sotto metà vita.", "values": [30], "cost": "-10% di danni ai nemici sopra metà vita."},
	"anubi_scale": {"god": "anubi", "balanced": true, "name": "Bilancia Giusta", "desc": "Chi ti colpisce subisce il %d%% del danno che ti ha fatto.", "values": [200], "cost": "Raccogli il 15% di Ka in meno."},
	"anubi_canopic": {"god": "anubi", "balanced": true, "name": "Vasi Canopi", "desc": "Ogni stanza ripulita ti cura di %d punti vita.", "values": [8], "cost": "-10 vita massima."},
	"anubi_mouth": {"god": "anubi", "balanced": true, "name": "Apertura della Bocca", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [35], "cost": "L'Occhio di Horus fa il 10% di danni in meno."},
	"anubi_linen": {"god": "anubi", "balanced": true, "name": "Bende di Lino", "desc": "Subisci il %d%% di danni in meno.", "values": [15], "cost": "Ti muovi il 5% più lento."},
	"anubi_guardian": {"god": "anubi", "balanced": true, "name": "Custode della Necropoli", "desc": "Il terzo colpo della combo fa il %d%% di danni in più.", "values": [50], "cost": "I primi due colpi della combo fanno il 10% di danni in meno."},
	"anubi_tribute": {"god": "anubi", "balanced": true, "name": "Offerte ai Defunti", "desc": "Ottieni il %d%% di Ka in più.", "values": [40], "cost": "-5 vita massima."},
	"anubi_guide": {"god": "anubi", "balanced": true, "name": "Guida delle Anime", "desc": "Ogni nemico abbattuto libera uno spirito che colpisce il nemico più vicino: %d danni.", "values": [15], "cost": "I nemici hanno il 5% di vita in più."},
	# Doni della Sfinge (blocco 17): un solo livello, valori modesti, funzionano con ogni arma. Non sono doni
	# di un dio: nella prova della Sfinge sostituiscono quelli degli dèi; nelle discese compaiono (al massimo
	# uno) solo col Favore della Sfinge. `trial_only` = ha senso solo nella prova. `color` = il loro colore.
	"sf_patience": {"god": "sfinge", "name": "Pazienza di Pietra", "desc": "L'attacco caricato si carica il %d%% più in fretta.", "values": [20], "color": Color(0.72, 0.62, 0.5)},
	"sf_sand": {"god": "sfinge", "name": "Sabbia sotto i Piedi", "desc": "Lo scatto si ricarica il %d%% più in fretta e dopo lo scatto corri il 15%% più veloce per un attimo.", "values": [15], "color": Color(0.93, 0.8, 0.52)},
	"sf_fang": {"god": "sfinge", "name": "Zanna del Custode", "desc": "Tutti i tuoi colpi fanno il %d%% di danni in più.", "values": [10], "color": Color(0.9, 0.55, 0.32)},
	"sf_shadow": {"god": "sfinge", "name": "Ombra Lunga", "desc": "Dopo un colpo resti invulnerabile %.1f secondi in più.", "values": [0.3], "color": Color(0.45, 0.4, 0.62)},
	"sf_breath": {"god": "sfinge", "name": "Respiro dell'Orizzonte", "desc": "Quando abbatti un guardiano o un boss ti curi di %d punti vita.", "values": [10], "color": Color(0.98, 0.72, 0.5)},
	"sf_eye": {"god": "sfinge", "name": "Occhio Sfrontato", "desc": "L'Occhio di Horus si ricarica il %d%% più in fretta.", "values": [20], "color": Color(0.45, 0.68, 0.92)},
	"sf_hand": {"god": "sfinge", "name": "Mano Sicura", "desc": "Ogni colpo a segno delle armi accorcia la ricarica dell'Occhio di %.1f secondi.", "values": [0.2], "color": Color(0.62, 0.78, 0.66)},
	"sf_coin": {"god": "sfinge", "trial_only": true, "name": "Moneta della Sfinge", "desc": "Ogni ondata superata senza colpi ti dà %d sigillo della Sfinge in più.", "values": [1], "color": Color(0.98, 0.86, 0.4)},
	"sf_second": {"god": "sfinge", "name": "Secondo Sguardo", "desc": "Una volta per prova o per discesa sopravvivi a un colpo mortale con %d punto vita.", "values": [1], "color": Color(0.88, 0.84, 0.74)},
	"sf_word": {"god": "sfinge", "name": "Peso della Parola", "desc": "Il primo colpo che dai in ogni ondata fa il %d%% di danni in più.", "values": [50], "color": Color(0.8, 0.42, 0.42)},
	"sf_sandstone": {"god": "sfinge", "name": "Pelle d'Arenaria", "desc": "+%d vita massima.", "values": [10], "color": Color(0.78, 0.58, 0.4)},
	"sf_gaze": {"god": "sfinge", "name": "Sguardo di Pietra", "desc": "I nemici colpiti dall'attacco caricato rallentano del %d%% per 2 secondi.", "values": [25], "color": Color(0.58, 0.6, 0.64)},
	# Doni Doppi: compaiono quando hai già doni di entrambi gli dèi
	"duo_ra_horus": {"god": "duo", "gods": ["ra", "horus"], "name": "Occhio del Sole", "desc": "L'Occhio di Horus incendia sempre ed esplode quando si ferma (almeno 12 danni)."},
	"duo_ra_sekhmet": {"god": "duo", "gods": ["ra", "sekhmet"], "name": "Sole Furente", "desc": "I nemici in fiamme subiscono il 25% di danni in più dal khopesh."},
	"duo_sekhmet_bastet": {"god": "duo", "gods": ["sekhmet", "bastet"], "name": "Caccia delle Leonesse", "desc": "I colpi critici del khopesh liberano un ruggito che ferisce chi ti sta attorno (12 danni)."},
	"duo_horus_bastet": {"god": "duo", "gods": ["horus", "bastet"], "name": "Sguardo del Gatto Sapiente", "desc": "Un colpo critico dell'Occhio di Horus ne dimezza la ricarica."},
	"duo_sobek_iside": {"god": "duo", "gods": ["sobek", "iside"], "name": "Piena Sacra", "desc": "Finché hai lo scudo di Iside, il khopesh fa il 25% di danni in più."},
	# Thoth guarì l'Occhio di Horus strappato da Set: da allora l'Occhio è "sano" (wedjat)
	"duo_horus_thoth": {"god": "duo", "gods": ["horus", "thoth"], "name": "Occhio Risanato", "desc": "Quando l'Occhio di Horus abbatte un nemico, si ricarica all'istante."},
	# Iside, madre di Horus, curò il figlio nelle paludi del Delta
	"duo_iside_horus": {"god": "duo", "gods": ["iside", "horus"], "name": "Figlio di Iside", "desc": "Ogni lancio dell'Occhio di Horus che colpisce almeno un nemico ti cura di 2 punti vita."},
	# Nefti, signora della casa e del lutto: le sue cure vengono dai nemici che cadono (tetto per stanza)
	"nefti_veil": {"god": "nefti", "name": "Velo del Lutto", "desc": "I tuoi colpi marchiano col Lutto: chi muore marchiato ti cura di %d.", "values": [1, 2, 3]},
	"nefti_vigil": {"god": "nefti", "name": "Veglia Funebre", "desc": "Sotto un terzo della vita, ogni 4 colpi a segno ti curano di %d.", "values": [1, 2, 3]},
	"nefti_feast": {"god": "nefti", "name": "Banchetto dei Defunti", "desc": "Abbattere un nemico élite ti cura di %d.", "values": [6, 9, 12]},
	"nefti_house": {"god": "nefti", "name": "Signora della Casa", "desc": "Le cure di Nefti oltre la vita piena diventano scudo, fino a %d.", "values": [10, 15, 20]},
	"nefti_kite": {"god": "nefti", "name": "Ala del Nibbio", "desc": "Abbattere un nemico marchiato col Lutto ti ricarica subito lo scatto."},
	"nefti_lament": {"god": "nefti", "name": "Lamento", "desc": "I nemici marchiati col Lutto subiscono il %d%% di danni in più.", "values": [15, 22, 30]},
	# Iside e Nefti piansero insieme Osiride: le due sorelle, le due nibbie
	# Shu, il dio dell'aria: spinge. Un nemico spinto che sbatte contro un muro, una colonna o un altro
	# nemico subisce lo "schianto" (Enemy.shu_push); spinto nei pericoli ci finisce dentro. Boss ed élite
	# si spostano appena. I colpi normali della combo non sono spinte di Shu.
	"shu_breath": {"god": "shu", "name": "Soffio di Shu", "desc": "Il colpo finale della combo spinge via i nemici: se sbattono, schianto da %d danni.", "values": [8, 12, 16]},
	"shu_column": {"god": "shu", "name": "Colonna d'Aria", "desc": "L'attacco caricato crea un vortice che risucchia i nemici vicini per 1,5 secondi."},
	"shu_north": {"god": "shu", "name": "Vento del Nord", "desc": "L'Occhio di Horus spinge i nemici lungo la sua traiettoria."},
	"shu_wings": {"god": "shu", "name": "Ali del Cielo", "desc": "Scatto più lungo del %d%%: i nemici che sfiori vengono spinti via.", "values": [20, 30, 40]},
	"shu_wall": {"god": "shu", "name": "Muro di Vento", "desc": "Ogni %s s un proiettile che ti raggiunge torna indietro.", "values": [3.0, 2.5, 2.0]},
	"shu_divide": {"god": "shu", "name": "Separatore del Cielo", "desc": "I nemici appena spinti subiscono il %d%% di danni in più, per 2 secondi.", "values": [15, 22, 30]},
	"shu_storm": {"god": "shu", "name": "Signore delle Tempeste", "desc": "Ogni %d s una raffica di 3 s: corri più veloce, i nemici vicini rallentano, i proiettili deviano. Nelle tempeste di sabbia di Sokar dura sempre.", "values": [12, 10, 8]},
	"shu_above": {"god": "shu", "rare": true, "name": "Sopra la Terra", "desc": "I nemici normali spinti nella sabbia nera o in una buca muoiono subito (non élite e boss)."},
	"duo_shu_ra": {"god": "duo", "gods": ["shu", "ra"], "name": "Vento Ardente", "desc": "Gli schianti incendiano i nemici."},
	"duo_shu_horus": {"god": "duo", "gods": ["shu", "horus"], "name": "Ali del Falco", "desc": "L'Occhio spinto dal vento, finito il volo, torna indietro e colpisce di nuovo."},
	"duo_nefti_iside": {"god": "duo", "gods": ["nefti", "iside"], "name": "Le Due Sorelle", "desc": "Sotto un terzo della vita, le cure del Velo del Lutto raddoppiano."},
	# Nefti fu madre di Anubi: il figlio guida le anime, la madre le piange
	"duo_nefti_anubi": {"god": "duo", "gods": ["nefti", "anubi"], "name": "Corteo delle Anime", "desc": "Gli spiriti della Guida delle Anime marchiano col Lutto i nemici che colpiscono."},
	"duo_anubi_sekhmet": {"god": "duo", "gods": ["anubi", "sekhmet"], "name": "Giudizio della Leonessa", "desc": "Il khopesh abbatte all'istante i nemici sotto il 15% della vita (non i guardiani e i boss)."},
	"duo_sobek_horus": {"god": "duo", "gods": ["sobek", "horus"], "weapon": "lancia", "name": "Arpione del Coccodrillo", "desc": "Gli affondi della lancia stordiscono per 0,6 secondi i nemici colpiti con la punta (meno i guardiani e i boss)."},
	"ra_heavy": {"god": "ra", "heavy": true, "name": "Ira del Sole", "desc": "Tutti i tuoi colpi incendiano, e le fiamme fanno il 60% di danni in più.", "cost": "L'Occhio di Horus si ricarica il 50% più lentamente."},
	"sekhmet_heavy": {"god": "sekhmet", "heavy": true, "name": "Sete Insaziabile", "desc": "+50% ai danni del khopesh.", "cost": "Finché ci sono nemici nella stanza perdi 1 punto vita ogni 2 secondi."},
	"bastet_heavy": {"god": "bastet", "heavy": true, "name": "Gioco del Gatto", "desc": "I colpi critici fanno il triplo dei danni invece del doppio, e hai sempre almeno il 10% di probabilità di critico.", "cost": "-15 vita massima."},
	"sobek_heavy": {"god": "sobek", "heavy": true, "name": "Fauci di Sobek", "desc": "+40% ai danni del khopesh e i nemici vengono scagliati il doppio più lontano.", "cost": "Ti muovi il 15% più lento."},
	"iside_heavy": {"god": "iside", "heavy": true, "name": "Abbraccio di Iside", "desc": "Ogni stanza ripulita ti cura del 15% della vita massima.", "cost": "Il khopesh fa il 25% di danni in meno."},
	"horus_heavy": {"god": "horus", "heavy": true, "name": "Occhio del Re", "desc": "L'Occhio di Horus fa il doppio dei danni e trapassa tutti i nemici.", "cost": "Il khopesh fa il 40% di danni in meno."},
	"thoth_stolen": {"god": "thoth", "heavy": true, "name": "Tempo Rubato", "desc": "Nemici e proiettili nemici sono il 20% più lenti, sempre.", "cost": "Fai il 20% di danni in meno."},
	"nefti_heavy": {"god": "nefti", "heavy": true, "name": "Fame dei Defunti", "desc": "Ogni colpo a segno ti cura di 1 punto vita, e il tetto delle cure di Nefti in una stanza sale a 20.", "cost": "-20 vita massima."},
	"shu_heavy": {"god": "shu", "heavy": true, "name": "Il Cielo Cade", "desc": "Ogni colpo spinge i nemici, non solo l'ultimo della combo, e gli schianti fanno il doppio dei danni.", "cost": "I tuoi colpi fanno il 20% di danni in meno."},
}

## Maledizioni di Set: durano le prossime stanze (contate quando le ripulisci), poi arriva la benedizione.
const SET_CURSES_IT := {
	"fast_enemies": {"desc": "I nemici sono più veloci del 20%", "rooms": 2},
	"fragile": {"desc": "Subisci il 30% di danni in più", "rooms": 2},
	"tough": {"desc": "I nemici hanno il 25% di vita in più", "rooms": 2},
	"thirst": {"desc": "Le cure ti curano il 40% in meno", "rooms": 2},
	"bleed": {"desc": "Finché ci sono nemici perdi 1 vita ogni 3 secondi", "rooms": 2},
}

## Benedizioni di Set: arrivano quando la maledizione finisce e durano tutta la run.
const SET_BLESSINGS_IT := {
	"set_might": {"name": "Forza di Set", "desc": "+25% a tutti i danni"},
	"set_vigor": {"name": "Vigore del Deserto", "desc": "+15 vita massima"},
	"set_sekhem": {"name": "Tempesta Interiore", "desc": "Il Sekhem si carica il 50% più in fretta"},
	"set_swift": {"name": "Vento Rosso", "desc": "+15% velocità di movimento"},
	"set_greed": {"name": "Tributo", "desc": "+50% di Ka"},
	"set_rage": {"name": "Ira del Deserto", "desc": "Attacchi con il khopesh il 20% più rapidamente"},
}


static func god_name(god: String) -> String:
	return GODS[god]["name"]


static func god_color(god: String) -> Color:
	return GODS[god]["color"]


static func is_heavy(id: String) -> bool:
	return ALL[id].get("heavy", false)


## Doni rari: senza prezzo, ma compaiono di rado (come i pesanti, al posto della terza scelta).
static func is_rare(id: String) -> bool:
	return ALL[id].get("rare", false)


## Doni con un prezzo da mostrare (pesanti e doni di Anubi).
static func has_cost(id: String) -> bool:
	return ALL[id].has("cost")


## Testo del dono a un certo livello (1, 2 o 3).
static func text(id: String, level: int) -> String:
	var b: Dictionary = ALL[id]
	if is_heavy(id) or not b.has("values"):
		return Weapons.adapt(b["desc"])
	return Weapons.adapt(b["desc"] % b["values"][clampi(level, 1, MAX_LEVEL) - 1])


## Le tre scelte offerte da un dio. `owned` = {id: livello} dei doni già presi.
## Prima i doni nuovi, poi i potenziamenti; a volte il dono pesante prende il terzo posto.
## Doni che riguardano il Sekhem: compaiono solo dopo averlo sbloccato sconfiggendo Am-heh.
const NEEDS_SEKHEM := ["iside_word", "set_sekhem"]


static func available_now(id: String) -> bool:
	return not NEEDS_SEKHEM.has(id) or Meta.sekhem_unlocked


## Doni che funzionano solo insieme ad altri: compaiono soltanto se ne possiedi almeno uno.
const REQUIRES := {
	"sobek_river": ["sobek_bite", "sobek_tide", "arco_sobek", "flagello_sobek", "artigli_sobek"],
	"duo_ra_sekhmet": ["ra_burn", "ra_dawn", "ra_eye", "ra_heavy", "arco_ra", "flagello_ra"],
	"duo_sekhmet_bastet": ["bastet_claws", "bastet_heavy", "bastet_point", "arco_bastet", "flagello_bastet"],
	"duo_horus_bastet": ["bastet_eyes", "bastet_heavy"],
	"duo_sobek_iside": ["iside_wings"],
	# il dono di Anubi c'è quasi sempre (lo dà all'inizio): serve uno di quelli che riguardano i colpi
	"duo_anubi_sekhmet": ["anubi_jackal", "anubi_guardian", "anubi_scale", "anubi_guide", "arco_anubi", "flagello_anubi"],
	# i doni di Nefti che vivono del marchio del Lutto
	"nefti_kite": ["nefti_veil", "arco_nefti", "flagello_nefti"],
	"nefti_lament": ["nefti_veil", "arco_nefti", "flagello_nefti"],
	"duo_nefti_iside": ["nefti_veil", "arco_nefti", "flagello_nefti"],
	"duo_nefti_anubi": ["anubi_guide"],
	"duo_thoth_anubi": ["anubi_guide"],
	"duo_thoth_iside": ["thoth_first"],
	# i doni di Shu che vivono delle spinte
	"shu_divide": ["shu_breath", "shu_column", "shu_north", "shu_wings", "arco_shu", "flagello_shu"],
	"shu_above": ["shu_breath", "shu_column", "shu_north", "shu_wings", "arco_shu", "flagello_shu"],
	"duo_shu_ra": ["shu_breath", "shu_column", "shu_north", "shu_wings", "arco_shu", "flagello_shu"],
	"duo_shu_horus": ["shu_north"],
}


## Doni che non hanno senso con un'arma: l'arco non ha la combinazione di tre colpi, e il suo
## dono di Ra (Frecce del Sole) prende il posto del Colpo Solare.
const NOT_FOR := {
	"arco": ["sekhmet_roar", "sobek_bite", "anubi_guardian", "shu_breath", "ra_burn"],
}


## Su quali colpi agisce un dono d'attacco (blocco 10). Origini: "khopesh", "lancia", "flagello",
## "occhio", "freccia". I doni di un'arma (campo `weapon`) valgono solo per i colpi di quell'arma;
## quelli che non sono qui e non hanno un'arma sono generali (danni %, critici, vita, scatto, cure).
## Le frecce ricevono SOLO i doni dell'arco e quelli generali: niente doni dell'Occhio.
const MELEE := ["khopesh", "lancia", "flagello", "artigli", "scettro"]
const WEAPON_HITS := ["khopesh", "lancia", "flagello", "freccia", "artigli", "scettro"]
const EYE := ["occhio"]
const ORIGINS := {
	# l'Occhio di Horus (dominio di Horus)
	"ra_disc": EYE, "ra_eye": EYE, "horus_multi": EYE, "horus_pierce": EYE, "horus_return": EYE,
	"horus_seek": EYE, "horus_twin": EYE, "bastet_eyes": EYE, "anubi_mouth": EYE, "shu_north": EYE,
	"duo_ra_horus": EYE, "duo_horus_bastet": EYE, "duo_horus_thoth": EYE, "duo_iside_horus": EYE,
	"duo_shu_horus": EYE,
	# la combinazione di tre colpi e il fuoco dell'arma da mischia
	"sekhmet_roar": MELEE, "sobek_bite": MELEE, "anubi_guardian": MELEE, "shu_breath": MELEE, "ra_burn": MELEE,
	# il marchio lo mette l'Occhio, ma il bonus va ai colpi dell'arma
	"horus_mark": WEAPON_HITS,
	"duo_ra_sekhmet": WEAPON_HITS, "duo_sekhmet_bastet": WEAPON_HITS, "duo_sobek_iside": WEAPON_HITS,
	"duo_anubi_sekhmet": WEAPON_HITS, "sekhmet_leap": WEAPON_HITS, "bastet_claws": WEAPON_HITS,
}
const WEAPON_ORIGIN := {"khopesh": "khopesh", "lancia": "lancia", "flagello": "flagello", "arco": "freccia", "artigli": "artigli", "scettro": "scettro"}


static func acts_on(id: String, origin: String) -> bool:
	if not ALL.has(id):
		return false
	if ALL[id].has("weapon"):
		return WEAPON_ORIGIN.get(ALL[id]["weapon"], "") == origin
	if ORIGINS.has(id):
		return (ORIGINS[id] as Array).has(origin)
	return true


static func fits_weapon(id: String) -> bool:
	if ALL[id].has("weapon") and ALL[id]["weapon"] != Run.weapon:
		return false
	return not (NOT_FOR.get(Run.weapon, []) as Array).has(id)


## Doni che chiedono TUTTI i doni elencati (REQUIRES ne chiede almeno uno).
const REQUIRES_ALL := {
	"duo_thoth_anubi": ["anubi_guide", "thoth_first"],
}


static func requirements_met(id: String, owned: Dictionary) -> bool:
	for r in REQUIRES_ALL.get(id, []):
		if not owned.has(r):
			return false
	if not REQUIRES.has(id):
		return true
	for r in REQUIRES[id]:
		if owned.has(r):
			return true
	return false


static func offers(god: String, owned: Dictionary) -> Array:
	var fresh := []
	var ups := []
	var specials := []
	for id in ALL:
		if ALL[id]["god"] != god or not available_now(id):
			continue
		if not owned.has(id) and not requirements_met(id, owned):
			continue
		if not fits_weapon(id):
			continue
		if is_heavy(id) or is_rare(id):
			if not owned.has(id):
				specials.append(id)
		elif not owned.has(id):
			fresh.append(id)
		elif owned[id] < MAX_LEVEL:
			ups.append(id)
	# raro e pesante condividono UN posto: mai tutti e due nella stessa scelta. Uno a caso; col Sigillo
	# di Thoth il raro ha la precedenza.
	var heavy := ""
	if not specials.is_empty():
		heavy = specials[randi() % specials.size()]
		if Favors.has("sigillo"):
			for sp in specials:
				if is_rare(sp):
					heavy = sp
	fresh.shuffle()
	ups.shuffle()
	var out := fresh + ups
	out = out.slice(0, 3)
	# se non resta altro, il dono pesante compare sempre (altrimenti il menu sarebbe vuoto)
	var chance := SEAL_RARE_CHANCE if heavy != "" and is_rare(heavy) and Favors.has("sigillo") else HEAVY_CHANCE
	if heavy != "" and (out.is_empty() or randf() < chance):
		if out.size() >= 3:
			out[2] = heavy
		else:
			out.append(heavy)
	return out


## Dèi (tranne Set) che hanno ancora qualcosa da offrire.
static func gods_with_boons(owned: Dictionary, for_room: int = 99) -> Array:
	var out := []
	for g in GODS:
		if MIN_ROOM.get(g, 1) > for_room:
			continue
		if g == "nefti" and Run.region < 2 and not Meta.nefti_met:
			continue                      # Nefti si mostra la prima volta nel deserto di Sokar
		if g == "shu" and Run.region < 2 and not Meta.shu_met:
			continue                      # anche Shu: la prima volta nel vento del deserto
		if g != "set" and g != "anubi" and g != "duo" and g != "sfinge" and not offers(g, owned).is_empty():
			out.append(g)
	return out


## Tre patti di Set: ognuno è una maledizione più una benedizione, scelte a caso.
static func set_offers(taken_blessings: Array) -> Array:
	var blessings := []
	for b in SET_BLESSINGS:
		if not taken_blessings.has(b) and available_now(b):
			blessings.append(b)
	blessings.shuffle()
	var curses: Array = SET_CURSES.keys()
	curses.shuffle()
	var out := []
	for i in range(mini(3, blessings.size())):
		out.append({"curse": curses[i % curses.size()], "blessing": blessings[i]})
	return out


## Probabilità che un Dono Doppio prenda il posto di una delle tre scelte, quando è disponibile.
const DUO_CHANCE := 0.45
## Sigillo di Thoth (grazia comprata con i lapislazzuli): doppi e rari più spesso.
const SEAL_DUO_CHANCE := 0.7
const SEAL_RARE_CHANCE := 0.65


static func duo_chance() -> float:
	return SEAL_DUO_CHANCE if Favors.has("sigillo") else DUO_CHANCE


## Doni della Sfinge (blocco 17).
static func is_sphinx(id: String) -> bool:
	return ALL.has(id) and ALL[id]["god"] == "sfinge"


## Il colore della carta di un dono: quello suo (doni della Sfinge) o quello del dio.
static func color_of(id: String) -> Color:
	return ALL[id].get("color", god_color(ALL[id]["god"]))


## I doni della Sfinge che si possono offrire: nella prova tutti, nelle discese non quelli `trial_only`.
static func sphinx_pool(owned: Dictionary, in_trial: bool) -> Array:
	var out := []
	for id in ALL:
		if ALL[id]["god"] != "sfinge" or owned.has(id) or not fits_weapon(id):
			continue
		if ALL[id].get("trial_only", false) and not in_trial:
			continue
		out.append(id)
	return out


static func is_duo(id: String) -> bool:
	return ALL[id]["god"] == "duo"


static func has_god(owned: Dictionary, god: String) -> bool:
	for id in owned:
		if ALL[id]["god"] == god:
			return true
	return false


## Doni Doppi che il dio `god` può offrire: serve già un dono dell'altro dio.
static func duos_for(god: String, owned: Dictionary) -> Array:
	var out := []
	for id in ALL:
		if not is_duo(id) or owned.has(id) or not requirements_met(id, owned):
			continue
		if not fits_weapon(id):
			continue
		var gods: Array = ALL[id]["gods"]
		if not gods.has(god):
			continue
		var other: String = gods[1] if gods[0] == god else gods[0]
		if has_god(owned, other) and has_god(owned, god):
			out.append(id)
	return out




## Riassunto breve di ogni dono, mostrato in fondo alla carta: [vantaggio, prezzo].
## Il %d prende il valore del livello, come nella descrizione.
const SHORT_IT := {
	"nefti_veil": ["Marchiati: +%d vita alla morte", ""],
	"nefti_vigil": ["Sotto 1/3: +%d ogni 4 colpi", ""],
	"nefti_feast": ["Élite abbattuto: +%d vita", ""],
	"nefti_house": ["Cura in più: scudo fino a %d", ""],
	"nefti_kite": ["Marchiato abbattuto: scatto pronto", ""],
	"nefti_lament": ["Marchiati: +%d%% danni", ""],
	"duo_nefti_iside": ["Sotto 1/3: cure del Lutto x2", ""],
	"duo_nefti_anubi": ["Gli spiriti marchiano", ""],
	"shu_breath": ["Colpo finale spinge · schianto %d", ""],
	"shu_column": ["Caricato: vortice 1,5 s", ""],
	"shu_north": ["L'Occhio spinge", ""],
	"shu_wings": ["Scatto +%d%% · spinge", ""],
	"shu_wall": ["Devia e rimanda i proiettili", ""],
	"shu_divide": ["Spinti: +%d%% danni", ""],
	"shu_storm": ["Raffica ogni %d s", ""],
	"shu_above": ["Spinti nei pericoli: morte", ""],
	"duo_shu_ra": ["Schianti che incendiano", ""],
	"duo_shu_horus": ["L'Occhio torna", ""],
	"ra_burn": ["Arma: fuoco %d ogni 0,5 s", ""],
	"flagello_ra": ["3ª frustata: fuoco %d", ""],
	"flagello_sekhmet": ["Punta +%d%% danni", ""],
	"artigli_bastet": ["Artigli: critico +%d%%", ""], "artigli_sekhmet": ["Balzo +%d%% danni", ""],
	"artigli_sobek": ["Graffi: -%d%% velocità", ""], "artigli_iside": ["Balzo: scudo %d", ""],
	"scettro_thoth": ["Raggio +%d%% più lungo", ""], "scettro_ra": ["Cerchio +%d%% danni", ""],
	"scettro_sekhmet": ["1° e 2° colpo +%d%% danni", ""], "scettro_iside": ["Nel Cerchio: -%d%% danni subiti", ""],
	"flagello_thoth": ["Frusta +%d%% più lunga", ""],
	"flagello_bastet": ["Aggancio: critico sicuro +%d%%", ""],
	"flagello_sobek": ["Frustate: -%d%% velocità", ""],
	"flagello_iside": ["Aggancio: scudo %d", ""],
	"flagello_horus": ["Aggancio: Occhio pronto", ""],
	"flagello_anubi": ["Frustate +%d%% rapide", "Frusta -20% lunga"],
	"flagello_nefti": ["Aggancio marchia · +%d", ""],
	"flagello_shu": ["Lanciato: schianto %d", ""],
	"arco_ra": ["Frecce: fuoco %d ogni 0,5 s", ""],
	"arco_sekhmet": ["Tiro carico +%d%% danni", ""],
	"arco_thoth": ["Trapassa 1 · dietro %d%%", ""],
	"arco_bastet": ["Tiro carico %d%% critico", ""],
	"arco_sobek": ["Frecce: -%d%% velocità 2 s", ""],
	"arco_iside": ["Arco teso: scudo %d", ""],
	"arco_ricochet": ["Rimbalzo: %d%% dei danni", ""],
	"horus_multi": ["Occhio: %d raggi a ventaglio", ""],
	"horus_pierce": ["Occhio trapassa %d nemici", ""],
	"arco_anubi": ["%d frecce per colpo", "-35% danni a freccia"],
	"arco_nefti": ["Tiro carico marchia · +%d", ""],
	"arco_shu": ["Tiro carico spinge · schianto %d", ""],
	"ra_disc": ["Occhio esplode: %d danni", ""],
	"ra_dawn": ["Scatto ferisce: %d danni", "Scatto -40% più lento"],
	"ra_eye": ["Occhio +%d%% danni e incendia", ""],
	"sekhmet_fury": ["Khopesh +%d%% danni", ""],
	"sekhmet_blood": ["+%d vita ogni 5 uccisioni", ""],
	"sekhmet_roar": ["3° colpo: onda di %d danni", ""],
	"sekhmet_leap": ["Attacco in scatto +%d%% danni", ""],
	"bastet_claws": ["Khopesh %d%% critico", ""],
	"bastet_eyes": ["Occhio %d%% critico", ""],
	"bastet_step": ["Scatto ricarica -%d%%", ""],
	"bastet_lives": ["Ti rialzi con il %d%%", ""],
	"sobek_skin": ["-%d%% danni subiti", ""],
	"sobek_bite": ["3° colpo stordisce", ""],
	"sobek_tide": ["Pozza: nemici -%d%% veloci", ""],
	"sobek_river": ["+%d%% su storditi e lenti", ""],
	"sobek_tail": ["Spazzata +%d%%, spinta ×2", ""],
	"sekhmet_crescent": ["1° e 2° fendente +%d%% danni", ""],
	"bastet_point": ["Affondo: %d%% critico", ""],
	"bastet_dance": ["Khopesh +%d%% più rapido", ""],
	"ra_edge": ["Fendenti +%d%% più lunghi", ""],
	"horus_harpoon": ["Punta: affondi +%d%%", ""],
	"iside_wings": ["Scudo di %d a ogni stanza", ""],
	"iside_tears": ["Cure +%d%%", ""],
	"iside_knot": ["Sotto 1/3 vita: -%d%% danni", ""],
	"iside_word": ["Sekhem +%d%% più rapido", ""],
	"horus_return": ["Occhio torna: %d%% danni", ""],
	"horus_seek": ["Occhio insegue · +%d%% danni", ""],
	"horus_twin": ["Occhio: %d cariche", ""],
	"horus_mark": ["Colpiti dall'Occhio: +%d%%", ""],
	"anubi_light": ["Scatto -%d%% · +12%% velocità", "-5 vita massima"],
	"anubi_stone": ["+%d vita massima", "-5% danni"],
	"anubi_jackal": ["+%d%% danni sotto metà vita", "-10% danni sopra metà"],
	"anubi_scale": ["Rifletti il %d%% dei danni", "-15% Ka"],
	"anubi_canopic": ["+%d vita a ogni stanza", "-10 vita massima"],
	"anubi_mouth": ["Occhio ricarica -%d%%", "Occhio -10% danni"],
	"anubi_linen": ["-%d%% danni subiti", "-5% velocità"],
	"anubi_guardian": ["3° colpo +%d%%", "1° e 2° colpo -10%"],
	"anubi_tribute": ["+%d%% Ka", "-5 vita massima"],
	"anubi_guide": ["Spiriti da %d danni", "Nemici +5% vita"],
	"duo_ra_horus": ["Occhio incendia, esplode", ""],
	"duo_ra_sekhmet": ["+25% sui nemici in fiamme", ""],
	"duo_sekhmet_bastet": ["Critici: ruggito di 12 danni", ""],
	"duo_horus_bastet": ["Critico: ricarica Occhio -50%", ""],
	"duo_sobek_iside": ["Con lo scudo: khopesh +25%", ""],
	"duo_horus_thoth": ["Occhio uccide: ricarica subito", ""],
	"duo_iside_horus": ["Occhio a segno: +2 vita", ""],
	"duo_anubi_sekhmet": ["Sotto il 15%: abbattuto", ""],
	"duo_sobek_horus": ["Punta: stordisce 0,6 s", ""],
	"ra_heavy": ["Tutto incendia · fiamme +60%", "Occhio ricarica +50%"],
	"sekhmet_heavy": ["Khopesh +50%", "In lotta: -1 vita ogni 2 s"],
	"bastet_heavy": ["Critici ×3 · almeno 10%", "-15 vita massima"],
	"sobek_heavy": ["Khopesh +40% · spinta doppia", "-15% velocità"],
	"iside_heavy": ["+15% vita a ogni stanza", "Khopesh -25%"],
	"thoth_stolen": ["Nemici e proiettili -20% veloci", "-20% danni"],
	"nefti_heavy": ["+1 vita a colpo · tetto 20", "-20 vita massima"],
	"shu_heavy": ["Ogni colpo spinge · schianti ×2", "-20% danni"],
	"thoth_first": ["1° colpo: +%d%% danni", ""],
	"thoth_hourglass": ["Colpito: nemici -60% veloci", ""],
	"thoth_glyph": ["Ogni 8 colpi: geroglifo %d", ""],
	"thoth_lesson": ["Un dono sale a ogni regione", ""],
	"thoth_timing": ["Caricato: ricarica -%d%%", ""],
	"thoth_judgment": ["Sotto il 12%: muoiono", ""],
	"duo_thoth_anubi": ["Spiriti con la Prima Parola", ""],
	"duo_thoth_iside": ["Prima Parola: scudo 4", ""],
	"horus_heavy": ["Occhio ×2, trapassa tutti", "Khopesh -40%"],
}


static func short(id: String, level: int) -> Array:
	if not SHORT.has(id):
		return ["", ""]
	var gain: String = SHORT[id][0]
	var b: Dictionary = ALL[id]
	if gain.find("%d") >= 0 and b.has("values"):
		gain = gain % int(round(b["values"][clampi(level, 1, b["values"].size()) - 1]))
	return [Weapons.adapt(gain), Weapons.adapt(SHORT[id][1])]


## I testi qui sopra sono in italiano (le costanti *_IT); il gioco legge le copie tradotte
## nella lingua scelta, rifatte da Lang.refresh_data() quando cambia la lingua.
static var ALL: Dictionary = Lang.deep(ALL_IT)
static var SET_CURSES: Dictionary = Lang.deep(SET_CURSES_IT)
static var SET_BLESSINGS: Dictionary = Lang.deep(SET_BLESSINGS_IT)
static var SHORT: Dictionary = Lang.deep(SHORT_IT)
static var GODS: Dictionary = Lang.deep(GODS_IT)


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)
	SET_CURSES = Lang.deep(SET_CURSES_IT)
	SET_BLESSINGS = Lang.deep(SET_BLESSINGS_IT)
	SHORT = Lang.deep(SHORT_IT)
	GODS = Lang.deep(GODS_IT)
