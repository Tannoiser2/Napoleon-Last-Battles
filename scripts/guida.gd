## Le regole in breve (dal regolamento rivisto di Napoleon's Last Battles).
class_name Guida
extends RefCounted

const TESTO := """[b]Il gioco[/b]
Quattro battaglie della campagna di Waterloo — Ligny, Quatre Bras, Wavre, La Belle Alliance — su quattro mappe che si uniscono nella campagna. Un esagono è largo 480 metri, un turno vale un'ora (tre ore di notte e con la pioggia), un punto forza 350-750 uomini o una batteria. Le pedine hanno forza e movimento (es. 5-4); sul retro la forza ridotta.

[b]Sequenza[/b]
In ogni turno muovono e combattono prima i Francesi, poi gli Alleati (Prussiani e Anglo-alleati, sempre amici fra loro). Nella campagna, prima del movimento: rifornimento (alle 9 di ogni giorno), riorganizzazione e comando.

[b]Movimento[/b]
Ogni esagono costa punti movimento: aperto e paese 1, fattoria fortificata 2, bosco e palude 2 per fanteria e artiglieria e 4 per la cavalleria. Lungo una strada 1/2, lungo un sentiero 1. Un ruscello costa 2 in più; il fiume (la Dyle) si passa solo dai ponti. Al massimo due unità per esagono alla fine di ogni fase (una sola nelle fattorie). Rinforzi: entrano dal loro esagono pagandone il terreno; chi arriva dopo nello stesso esagono paga qualcosa in più (la colonna in marcia).

[b]Zone di controllo[/b]
Ogni unità controlla i sei esagoni attorno (non oltre il fiume senza ponte e non dentro le fattorie). Chi entra in un esagono controllato dal nemico si ferma, e non può uscirne se non ritirandosi o avanzando dopo un combattimento. Di notte e con la pioggia non si entra nelle zone nemiche e non si combatte.

[b]Combattimento[/b]
Ogni unità a contatto col nemico deve attaccare, e ogni nemico a contatto deve essere attaccato; un'unità attacca una volta, un nemico è attaccato una volta. Si sommano le forze e si confrontano a rapporto (arrotondato a favore del difensore): da 1-5 a 6-1. Unità nello stesso esagono attaccano e difendono insieme. Un attacco può colpire più esagoni se tutti gli attaccanti li toccano tutti. Si può scegliere di attaccare a una colonna più bassa.
Terreno: paese raddoppia il difensore, fattoria lo triplica (e per la fanteria l'attacco non va oltre 4-1 e la ritirata non ha effetto), ruscello o ponte lo raddoppiano se tutti attaccano da lì; i vantaggi non si sommano (vale il migliore). La cavalleria vale metà quando difende in bosco o palude e quando attacca un esagono di bosco o palude (le forze dimezzate si sommano e si arrotonda una volta, per eccesso); le creste non cambiano il combattimento ma bloccano il tiro.
Risultati: AE attaccanti eliminati, AR attaccanti si ritirano di un esagono, DR difensori si ritirano, DE difensori eliminati, EX scambio (il difensore è eliminato, l'attaccante perde almeno altrettanti punti). Chi non può ritirarsi è eliminato (o sposta un amico che ha spazio). Se un esagono si libera, un vincitore può avanzarci (non i demoralizzati).

[b]Artiglieria[/b]
L'artiglieria non a contatto può bombardare un esagono a 2 di distanza, da sola o insieme a un attacco, senza subire alcun risultato. Bosco, paese e fattoria intermedi e i lati di cresta bloccano la linea di tiro; nelle fattorie non si tira. A contatto col nemico l'artiglieria combatte come le altre unità.

[b]Regole facoltative e varianti (si scelgono nel menu)[/b]
Armi combinate (15.1): fanteria, cavalleria e artiglieria contro lo stesso esagono spostano l'attacco di una colonna a destra. Guardia imperiale (15.2): se un attacco della fanteria della Guardia va male (AE, AR o EX) il livello francese scende di 20 (nella campagna: i corpi vicini scendono di 7). Le altre (ritirata a cavallo, impeto, capi in combattimento, terreno modificato, effetti combinati, bombardamento prolungato, Vecchia Guardia, fuori comando e senza rifornimento modificati, alba, pioggia) sono spiegate una per una nel menu. Ogni modificatore applicato compare in parole nel pannello di combattimento.

[b]Area di comando (campagna)[/b]
Nelle battaglie singole capi e comando sono facoltativi (regola «10-11 Capi e comando» nel menu). Il tasto «Comando» in alto colora in oro le zone dei comandanti (5 esagoni), in blu quelle degli ufficiali (3) e cerchia di rosso le unità fuori comando. Toccando un capo si vede la sua zona. I capi demoralizzati o inattivi mostrano il retro della pedina.

[b]Rifornimento (solo campagna)[/b]
Una volta al giorno, al primo turno di luce, ogni unità deve tracciare al massimo 5 esagoni fino a una strada collegata al suo bordo (Francesi a sud, Prussiani a est, Alleati a ovest), senza passare da nemici: chi non ci riesce è eliminato. Il tasto «Rifornimento» mostra la rete e cerchia in arancione chi oggi sarebbe tagliato fuori.

[b]Demoralizzazione e vittoria nei quattro Folio[/b]
Ogni esercito ha un livello di demoralizzazione (e gli Alleati uno di disintegrazione): quando le perdite lo raggiungono, l'esercito non avanza più dopo i combattimenti; le perdite sono indicate in alto. Le condizioni di vittoria di ogni battaglia sono nella sua scheda nel menu.

[b]La campagna[/b]
[i]Comando[/i]: Napoleone (3), Grouchy (2), Ney (1), Wellington (4), Orange (1) e Blücher (2) comandano tanti ufficiali e tante unità quanto la loro capacità, entro 5 esagoni; gli ufficiali passano il comando alle unità del loro corpo (o divisione) entro 3 esagoni. Le unità fuori comando (FC) non attaccano e non entrano nelle zone nemiche; se sono già a contatto attaccano ma un DE o DR diventa AR. Di notte tutti sono fuori comando.
[i]Capi[/i]: muovono come la cavalleria (10 i comandanti, 6 gli ufficiali), non hanno forza; se restano soli dopo un combattimento cadono con 1-2 sul dado, altrimenti raggiungono le loro truppe.
[i]Riorganizzazione[/i]: le unità piene eliminate, dopo un turno di attesa, tornano a forza ridotta nell'esagono del loro ufficiale (due per turno) se nessun nemico è entro 10 esagoni; se il corpo è demoralizzato, un 5-6 le perde per sempre. Le unità ridotte o da un punto eliminate sono perse.
[i]Demoralizzazione[/i]: ogni corpo francese e prussiano ha il suo livello (Guardia 20, I 15, II 19, III 13, IV 12, VI 8, cavalleria 3-4; prussiani 20, 20, 14, 19); gli Anglo-alleati hanno un totale unico e ogni nazione cede al suo livello (Britannici 40, KGL 33, Hannover 12, Brunswick 10, Nassau 8, Olanda 7). Un corpo demoralizzato paga 2 per l'aperto (gli altri terreni costano come sempre), non avanza e rischia nella riorganizzazione. Un ufficiale entro 5 esagoni da un corpo demoralizzato abbassa il suo livello di 2.
[i]Rifornimento[/i]: alle 9 del 17 e del 18 ogni unità deve collegarsi (5 esagoni qualunque, poi strade e sentieri) al suo bordo: Francesi sud, Prussiani est, Anglo-alleati ovest; le zone nemiche non lo bloccano, le unità nemiche sì; chi non ci riesce è eliminato.
[i]Vittoria[/i]: +1 punto per ogni punto forza alleato eliminato, -1 per ogni francese, +2 per ogni punto francese che esce verso Bruxelles da B0605 (raddoppiati oltre i 40). I Francesi vincono arrivando a 230.

[b]Comandi[/b]
Trascina per spostare la mappa, rotella o pizzico per lo zoom, tasto destro o due dita per ruotare (anche su iPad). Tocca un esagono per vederne le unità. «Plance» mostra le perdite di ogni esercito sulle plance originali dei corpi, «Tabelle» la Tabella dei risultati e il terreno.
"""

## Napoleon at War (SPI 1975): regole standard ed esclusive dei quattro giochi, e cosa cambia rispetto a Last Battles
const TESTO_NAW := """[b]Il gioco[/b]
Quattro battaglie napoleoniche in un'unica scatola: Marengo (1800), Jena-Auerstadt (1806), Wagram (1809) e la battaglia delle Nazioni a Lipsia (1813). Un esagono vale 400-800 metri, un turno una o due ore, un punto forza 500-1000 uomini. Le pedine sono divisioni o brigate con forza e movimento (es. 6-4) e non hanno retro: un'unità è intera o eliminata.

[b]Sequenza[/b]
Movimento e combattimento del primo giocatore, poi del secondo. Muovono per primi gli Austriaci a Marengo, i Francesi negli altri tre giochi. I turni di notte non hanno combattimento.

[b]Movimento e impilamento[/b]
Aperto e paese 1 punto, bosco e terreno accidentato 2; strada 1/2 da un esagono di strada all'altro, sentiero (Marengo) 1. Un ruscello costa 2 in più, il fiume si passa solo dai ponti. Salire un pendio (dall'esagono col tratteggio verso quello in alto) costa 1 in più. La palude (Nazioni) si attraversa solo per strada. Si passa sopra le unità amiche, ma alla fine del movimento c'è al massimo [b]una unità per esagono[/b]. I rinforzi entrano dal loro esagono pagando 1 punto; se l'esagono è occupato aspettano o entrano dal più vicino.

[b]Zone di controllo[/b]
Le sei caselle attorno a ogni unità (non oltre un fiume senza ponte). Chi ci entra si ferma e ne esce solo ritirandosi o avanzando dopo un combattimento. Di notte non si entra nelle zone nemiche (a Lipsia però ci si può sganciare).

[b]Combattimento[/b]
Obbligatorio: ogni unità nella zona di controllo nemica deve attaccare e ogni nemico a contatto deve essere attaccato; ogni unità attacca e viene attaccata una sola volta per turno. Si sommano le forze e si arrotonda a favore del difensore (13 contro 4 = 3-1). Si può abbassare il rapporto a piacere prima del dado. La tabella è la stessa di Last Battles: AE, AR, DR, DE, EX (nello scambio l'attaccante perde almeno quanto il difensore, in punti stampati). Chi non può ritirarsi è eliminato; un'unità amica può essere spostata per fargli posto. Dopo il combattimento un'unità vincitrice può avanzare nell'esagono lasciato libero: è il modo per chiudere la ritirata ai nemici non ancora attaccati.

[b]Artiglieria[/b]
Bombarda a due esagoni, anche oltre il fiume, senza subire risultati; la linea di tiro è bloccata da boschi e paesi (non dai pendii). A contatto col nemico combatte come le altre unità. Nella battaglia delle Nazioni l'artiglieria è dentro le divisioni.

[b]Terreno in difesa[/b]
Difensore raddoppiato in paese, terreno accidentato e palude; e quando tutti gli attacchi passano da ruscelli o ponti, oppure salgono un pendio dal basso. I raddoppi non si sommano. Il bosco non aiuta il difensore, ma blocca il tiro.

[b]Marengo[/b]
14 turni. Primo turno: i Francesi, sorpresi, muovono a metà e non entrano nelle zone austriache. Dal turno 9 Bonaparte può lanciare il contrattacco: per tre turni la forza francese in attacco è doppia. Vincono i Francesi con 33 punti austriaci eliminati e almeno 10 punti entro 4 esagoni da Marengo (1412); gli Austriaci con 30 punti francesi eliminati tenendo Marengo e Pietrabuona (1111). Se nessuno infligge le perdite vince chi tiene i suoi obiettivi; se li tengono entrambi è pari.

[b]Jena-Auerstadt[/b]
12 turni: 1-3 di notte (e niente boschi), 4-5 di nebbia (movimento a metà, artiglieria solo a contatto). Due battaglie sulla stessa mappa (Jena sopra, Auerstadt sotto) con demoralizzazione separata: chi supera il suo livello combatte una colonna più a sinistra e viene attaccato una colonna più a destra. Il Prussiano sceglie l'opzione A (Brunswick verso Auerstadt) o B (tutti a Jena); facoltativi i rinforzi di Luigi Ferdinando e la marcia di Bernadotte su Auerstadt. I Francesi passano da una mappa all'altra col binario di transito (tre turni); dopo la demoralizzazione di un campo si può uscire dalla mappa. Punti vittoria a fine partita secondo le perdite e la demoralizzazione.

[b]Wagram[/b]
14 turni, il 5 e il 6 di notte. I Francesi partono attorno a Lobau (le artiglierie 10-1 non lasciano l'isola). Cavalleria e artiglieria non attraversano i ruscelli senza ponte, non attaccano attraverso e lì non estendono la zona di controllo. Demoralizzazione: i Francesi a 50 punti persi, gli Austriaci a 45; chi è demoralizzato non avanza più dopo il combattimento. Dal turno 7 all'11 gli Austriaci tirano un dado: con 1 arriva l'arciduca Giovanni da sud-est. Punti: 1 per punto forza nemico eliminato; gli Austriaci 25, 30 e 35 entrando ad Aspern, Essling e Gross Enzersdorf (e di nuovo se li tengono alla fine) e 1 per punto uscito a ovest; i Francesi 1 per ogni loro punto sulle alture della Russbach alla fine. Ai Francesi servono almeno 75 punti.

[b]La battaglia delle Nazioni[/b]
Tre scenari: primo giorno (turni 1-5), terzo giorno (13-20, con le unità già distrutte) e la grande battaglia (1-20). Notti ai turni 6, 12 e 18: si può uscire dalle zone nemiche ma non entrarci. Nel primo turno i Francesi non muovono. La demoralizzazione cresce coi giorni (Alleati/Francesi: 80/100 nei turni 1-5, 120/110 nei 6-11, 160/110 dal 12): il primo esercito demoralizzato perde. A fine partita le unità francesi che non hanno una via libera fino a 2131 (Lipsia) sono eliminate.

[b]Cosa cambia rispetto a Napoleon's Last Battles[/b]
Stesso sistema (Napoleon at Waterloo) e stessa tabella dei combattimenti, ma: una sola unità per esagono invece di due; niente forza ridotta; niente capi, comando né rifornimento; niente fattorie fortificate; la cavalleria non è dimezzata nel bosco e il bosco non raddoppia il difensore; nuovi terreni (pendii con tratteggio, terreno accidentato, palude, sentieri, laghi); i pendii non bloccano il tiro; la notte vieta di entrare nelle zone nemiche; ogni gioco ha la sua demoralizzazione (stop alle avanzate a Wagram, spostamento di colonna a Jena, fine della partita a Lipsia) e le sue regole esclusive (sorpresa e contrattacco a Marengo, nebbia e transito fra le mappe a Jena-Auerstadt, ruscelli e arciduca Giovanni a Wagram, ritirata notturna e linea di comunicazione a Lipsia)."""
