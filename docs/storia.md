# Duat · La storia

Documento di riferimento per ogni battuta del gioco. Se un dialogo contraddice questo file, ha torto il dialogo.

## In una frase

Uno scriba scende nel Duat per salvare dall'oblio la storia del suo faraone, Akhet, il cui nome è stato cancellato; scoprirà che il sole non sorge più perché qualcuno ha rubato il nome segreto di Ra, e alla fine che il faraone che cercava è lui.

## Personaggi

- **Il protagonista.** Crede di essere uno scriba di corte, uno dei migliori del faraone Akhet. Ricorda di aver scritto le sue imprese, e le ricorda con dettagli vividi: il peso del khopesh, il freddo della camera del tesoro, la mano della regina. Gli dèi lo chiamano "Scriba". In verità è **Akhet**.
- **Akhet** ("l'orizzonte", il punto dove il sole rinasce). Faraone potente e amato, ossessionato dalla morte. Da vivo ha rubato il **nome segreto di Ra** per diventare immortale. Il suo nome è stato scalpellato da ogni pietra d'Egitto.
- **La regina** (nome ancora da decidere). Moglie di Akhet. Quando Akhet morì sapeva che il suo cuore, sulla bilancia, sarebbe stato divorato da Ammit. Per salvarlo fece cancellare il suo nome (senza nome non c'è giudizio) e lo seppellì con la tavolozza e l'identità del suo scriba. È Iside che salva Osiride, ma con una colpa vera da nascondere.
- **Mahaf, il Traghettatore** ("colui che guarda indietro", dal mito: ha il volto girato verso il passato). Fu lui a portare l'anima di Akhet nel Duat la prima notte. La regina lo pagò per proteggerlo finché non ricordasse: per questo compare sempre prima dei boss. All'inizio è avido e burbero; più la storia avanza, più abbassa i prezzi senza dirlo. Nel finale si gira e ti guarda in faccia per la prima volta.
- **Anubi.** Custode della bilancia. Non sa chi sei e la cosa lo inquieta: la bilancia trema quando torni.
- **Set.** Sa tutto, o quasi, e si diverte. Ride quando parli del "tuo" faraone.
- **Apopi.** Il serpente del caos vuole il nome di Ra per ucciderlo per sempre. Ti dà la caccia perché sa dove si trova il nome.

## Perché si torna dopo ogni morte

Da quando Akhet è morto il sole non è più sorto: Ra non può rinascere senza il suo nome segreto. Ogni discesa è **la stessa notte che ricomincia**. Gli dèi ti aiutano non per bontà, ma perché hanno bisogno che qualcuno arrivi in fondo.

## La premessa che il giocatore crede (inizio)

Il nome di Akhet è stato cancellato. Lo scriba aveva scritto il proprio nome accanto a quello del re in ogni testo, e i testi sono stati scalpellati con lui: senza nome il suo cuore non ha peso e Anubi non può giudicarlo. Ma'at gli concede una via: seguire la barca di Ra nelle dodici ore della notte e ricomporre il nome e la storia del suo re prima che siano dimenticati per sempre.

## Le tappe della verità

| Tappa | Boss | Cosa si scopre |
| --- | --- | --- |
| 1 | **Am-heh** (Prima Ora, le acque di Wernes) | Le prime imprese di Akhet, gloriose. Il cartiglio di Akhet nella Sala riprende il primo segno |
| 2 | **Aker** (il deserto di Sokar) | La notte non finisce: da quando Akhet è morto il sole non è più sorto. Qualcuno ha rubato il nome segreto di Ra |
| 3 | **Apopi** (il cuore della notte) | Apopi ti dà la caccia perché sa dove si trova il nome. Poi la verità sulla regina: ha cancellato Akhet per salvarlo, e lo ha nascosto dietro un volto che non era il suo |
| 4 | **Ammit** (la Sala delle Due Verità) | **Sei Akhet.** Il nome di Ra è dentro di te. Lo restituisci, accetti la pesatura, e il sole sorge all'orizzonte (*akhet*) |

Ordine voluto: prima il mondo (il sole), poi la persona (la regina), poi tu. Il giocatore cerca il colpevole per tutto il gioco, e il colpevole è lui.

## Il cartiglio di Akhet

Nella Sala del Giudizio c'è il cartiglio vuoto del faraone. Ogni boss di regione restituisce un segno, nell'ordine in cui si scrive il nome *3ḫt*:

1. l'**ibis crestato** (*akh*, lo spirito luminoso)
2. la **placenta** (il suono *kh*)
3. il **pane** (il suono *t*)
4. l'**orizzonte**: il sole tra due montagne. È il segno che si ricompone solo nel finale, quando il sole sorge davvero.

Per ora, con una sola regione, i segni arrivano con le vittorie sul boss della Prima Ora, Am-heh.

## I Ricordi dello scriba

Dopo ogni boss si sblocca un ricordo: un breve racconto delle imprese di Akhet, scritto dallo scriba in **terza persona**. Con il passare dei ricordi la terza persona scivola: una frase al presente, poi un "io" corretto subito ("io... lui alzò la lancia"). L'ultimo ricordo è tutto in **prima persona**. Il colpo di scena arriva attraverso la scrittura stessa.

### Ricordi scritti finora (`Lore.RICORDI`)

| N. | Quando | Titolo | Cosa contiene | L'indizio |
| --- | --- | --- | --- | --- |
| I | 1ª vittoria su Am-heh | La lancia di Buto | Akhet in battaglia con la lancia di Neith | la scheggia sotto il pollice che il re non fece mai limare: "forse me lo raccontò lui" |
| II | 2ª vittoria | La doppia corona | l'incoronazione, i cinque nomi | il sudore sotto la corona, che "nei rotoli non c'è" |
| III | 3ª vittoria | La casa dell'eternità | il re che scende ogni notte nella sua tomba e non vuole essere pesato | il primo scivolamento: "la mia mano... la sua mano" |

Con le nuove regioni i Ricordi continuano (IV dopo Aker, con il sole che non sorge; poi la regina; l'ultimo tutto in prima persona).

### Le tre voci di Mahaf (`scripts/ferryman.gd`)

- **0 · avido** (nessuna vittoria): le frasi di sempre, prezzi pieni.
- **1 · curioso** (dalla 1ª vittoria): "Ti ho già portato una volta", "Hai ancora quella scheggia sotto il pollice?" (eco del Ricordo I), "Gli scribi hanno le dita macchiate d'inchiostro. Tu no". Prezzi -10%.
- **2 · preoccupato** (dalla 3ª vittoria): il re che aveva paura della barca, "il tuo passato è affollato", "ho fatto una promessa" (la regina, senza nominarla). Prezzi -20%.

Una volta su quattro usa una frase della voce precedente, così il cambiamento non è a scatti.

## Indizi da seminare (si capiscono solo dopo)

- I ricordi contengono dettagli che uno scriba non poteva sapere.
- La Sala è sempre al buio: nessuna alba, mai.
- Mahaf: "Ti ho già portato una volta. Non te lo ricordi." / "Ho già visto la tua schiena. Era coperta d'oro." / si corregge dopo averti quasi chiamato "signore".
- Set ride quando parli del "tuo" faraone.
- La bilancia trema quando torni.
- Ra: "Anche tu, Scriba, sei più di ciò che appari."
- Neith ti riconosce senza dirlo: la lancia era l'arma di Akhet in battaglia. Ogni arma nuova è un ricordo.

## Regole per chi scrive le battute

- Prima della tappa 4 nessuno dice al protagonista che è lui il faraone, né lo lascia intendere in modo diretto. Gli indizi devono avere sempre una seconda lettura innocente.
- Gli dèi parlano di Akhet al passato e in terza persona.
- La regina non si nomina prima della tappa 3.
- Il nome di Ra rubato non si nomina prima della tappa 2 (si può parlare del mito di Iside e del nome segreto, che è storia antica).

## Ammit, boss finale

Ammit conosce ogni arma: ha divorato guerrieri con tutte. Il combattimento ha una base comune (la bilancia: i colpi subiti e i patti di Set appesantiscono il cuore; quando la bilancia pende dalla tua parte Ammit è vulnerabile) e una **risposta all'arma** che impugni. Contro la lancia ti salta addosso e sta attaccata; contro il khopesh si tiene a distanza. Ogni arma nuova aggiunge la sua risposta, così ogni prima volta contro Ammit con un'arma nuova è una sorpresa.
