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

[b]Regole facoltative (attive per scelta)[/b]
Armi combinate: fanteria, cavalleria e artiglieria contro lo stesso esagono spostano l'attacco di una colonna a destra. Guardia imperiale: se un attacco della fanteria della Guardia va male (AE, AR o EX) il livello di demoralizzazione francese scende di 20 (nella campagna: tutti i corpi vicini scendono di 7).

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
