# Napoleon's Last Battles — versione digitale (uso personale)

Il quadrigioco SPI del 1976 (Kevin Zucker, J.A. Nelson) sulla campagna di Waterloo, in Godot 4.7 con
esportazione web: le quattro battaglie — **Ligny**, **Quatre Bras**, **Wavre**, **La Belle Alliance** — e la
**campagna** che le unisce su un'unica mappa. Mappa 3D con le mappe e le pedine originali del modulo di Tabletop
Simulator, IA per giocare da soli, partita online con un amico e salvataggi su Firebase.

Si gioca qui: https://tannoiser2.github.io/Napoleon-Last-Battles/ (e nella ludoteca: https://tannoiser2.github.io).

## Cosa c'è

- **Mappa**: le quattro mappe originali (scansioni del modulo TTS) raddrizzate e unite sulla griglia della campagna
  (57 × 67 esagoni, `assets/mappa/`, quattro tasselli webp). Terreni, corsi d'acqua, ponti, creste, strade e sentieri
  sono stati riconosciuti dai colori della mappa (`tools/estrazione/`): la griglia è stata agganciata leggendo con
  l'OCR i numeri degli esagoni. Ogni esagono conserva la sigla originale (es. B0617 = Hougoumont).
- **Mappa ridisegnata in 3D** (predefinita; dal Menu si torna alle scansioni originali): le quattro mappe
  restyled in alta risoluzione unite in quattro tasselli `assets/mappa/mappa_nuova_*.webp` da
  `tools/estrazione/costruisci_mappa_nuova.py`. La loro griglia è stata ricavata dalle linee degli esagoni e
  confrontata esagono per esagono con quella delle scansioni (numerazione identica, scarto medio circa il 10% del
  passo). Ogni esagono è un prisma; creste, paesi e fattorie sono rialzati e le pedine si appoggiano alla quota.
  Il confronto ha anche scoperto errori nei terreni estratti dalle scansioni: titoli, rose dei venti, nomi e
  simboli di schieramento stampati in blu erano stati letti come paesi, laghi o corsi d'acqua (59 esagoni e 66
  lati, corretti con `tools/estrazione/correggi_terreni.py` e `correzioni_terreni.json`; il lago Materne di Quatre
  Bras ora è un lago).
- **Pedine dell'edizione 2015** (Decision Games, grafica di Trevor Holman): un'opzione nel menu principale e nel
  Menu della partita sostituisce le pedine originali. Ritagliate dai quattro fogli (fronte e retro, il retro è la
  forza ridotta) con `tools/pedine2015/genera.py`; gli abbinamenti unità-pedina sono in
  `tools/pedine2015/abbinamenti.txt`. Le regole restano quelle del gioco: dove la pedina 2015 riporta valori diversi
  (Friant 7 invece di 6, Roguet 6 invece di 7, d'Hurbal 4 invece di 5, Gengoult 5 invece di 6, Doguereau 4 invece
  di 5, Jacquinot movimento 6 invece di 7, 6ª Landwehr Kurmark 3 invece di 2) contano i valori del gioco.
- **Pedine**: le 205 pedine originali col loro retro a forza ridotta e i 31 capi (`assets/pedine/`,
  `assets/dati/catalogo.json`); gli schieramenti dei Folio vengono dalle posizioni del modulo TTS, quelli della
  campagna dall'elenco `NLB_Campaign_Setup.pdf` e dalle tracce dei turni stampate sulle mappe.
- **Plance**: le plance dei corpi (eliminati in attesa, riorganizzabili, persi per sempre) con le pedine sopra, e la
  Tabella dei risultati e del terreno.
- **Combattimento a schermo**: gli attacchi sono frecce dagli esagoni attaccanti a quello difeso (tratteggiate in oro
  per il bombardamento). Quando si risolve un attacco la Tabella sale dal basso, si illumina la colonna del rapporto
  di forze, una riga scorre sui valori del dado e si ferma su quello uscito, e all'incrocio compare il risultato.
  Il tiro dell'artiglieria è una parabola in 3D; dopo l'esito una freccia chiara mostra dove si è ritirata ogni
  unità e le eliminate saltano via in un lampo di fumo. Per l'avanzata si tocca un'unità con l'anello d'oro, oppure
  l'esagono vuoto per restare; il tasto «Avanti» c'è solo quando non c'è niente da scegliere. I combattimenti
  dell'IA si possono saltare per il resto della fase. Le pedine scorrono da un esagono all'altro lungo il percorso.
- **Regole** (`scripts/motore.gd`, regolamento rivisto): movimento con strade e sentieri, zone di controllo rigide,
  impilamento, rinforzi in colonna, combattimento obbligatorio anche su più esagoni, TRC con l'errata (4-1 con 5 = DR),
  ritirate e spostamenti, avanzata, artiglieria con bombardamento e linea di tiro, fattorie fortificate, notte e
  pioggia, uscite dalla mappa, demoralizzazione e vittoria di ogni Folio; regole facoltative delle armi combinate e
  della Guardia imperiale. Nella campagna: comandanti e ufficiali con capacità di comando, unità fuori comando,
  riorganizzazione, demoralizzazione di corpi e nazioni (e vicinanza ai corpi demoralizzati), rifornimento alle 9,
  punti vittoria con le uscite verso Bruxelles.
- **IA** (`scripts/ia.gd`): concentra le forze sui bersagli deboli e su quelli senza via di ritirata, porta
  l'artiglieria a distanza di tiro (il bombardamento è senza rischi), distribuisce gli attacchi obbligatori per il
  massimo valore atteso (attacchi diversivi dove serve), tiene in riserva la Guardia, evita le fattorie, presidia i
  punti chiave (Waterloo, Quatre Bras), cerca le contropendenze e una via di ritirata in difesa; a Wavre i Prussiani
  lasciano una retroguardia sui ponti della Dyle e fanno uscire il resto, i Francesi puntano ai ponti e all'uscita;
  nella campagna le unità restano vicine ai loro ufficiali. Tre caratteri: prudente, normale, aggressivo.
  Gli attacchi obbligatori si scelgono cercando la combinazione col miglior saldo atteso di punti forza (perdite
  nemiche meno le proprie, unità chiuse senza ritirata, unità amiche liberate da un accerchiamento, obiettivi).
  Dove gli Alleati vincono resistendo (Wellington alla Belle Alliance, i Prussiani a Ligny e a Wavre, Quatre Bras)
  l'IA alleata usa gli attacchi a 1-2 per sganciarsi, evita le posizioni dove il nemico può arrivare con rapporti
  schiaccianti e a Ligny presidia, contrattacca e rioccupa i villaggi (ogni villaggio perso abbassa la soglia di
  demoralizzazione prussiana); a Quatre Bras l'incrocio è tenuto dalle due fanterie più forti (il paese raddoppia
  la difesa) e gli Alleati restano in difesa fino a sera.
  Spunti dai giocatori esperti: Moves n. 31 (recensione e varianti), il resoconto di Ligny di George Nap
  (spigames.net), le recensioni di Wavre e Ligny.
  Dall'articolo di Bob Merry sulle tattiche del sistema Napoleon at Waterloo (grognard.com): l'IA abbassa
  volontariamente il rapporto a 3-1 quando conviene (contro chi non può ritirarsi elimina quasi come un 4-1,
  senza scambi), risolve prima gli attacchi al centro di un gruppo di bersagli così che le avanzate chiudano la
  ritirata ai vicini, avanza con l'unità più debole nell'esagono che taglia la ritirata a un nemico ancora da
  attaccare, sceglie per l'attacco gli esagoni che coprono le vie di fuga del bersaglio e non si ferma accanto a
  nemici che la costringerebbero a un attacco a 1-3. Con 48 partite per lato: Francesi da 30 a 35 vittorie
  contro gli stessi Alleati; Alleati da 10 a 13 vittorie contro gli stessi Francesi.
  Campagna: l'IA francese segue il piano di Napoleone. Il 16 l'ala di Ney (I e II corpo, Kellermann) va su
  Quatre Bras e il resto attacca a Ligny; dal 17 l'ala di Grouchy (III e IV corpo, Pajol, Exelmans) incalza i
  Prussiani e tutti gli altri marciano sulla strada di Bruxelles fino a uscire da 0605, con ufficiali e
  comandanti al seguito. I corpi restano uniti attorno all'ufficiale, gli ufficiali vanno al centro delle
  posizioni pianificate del corpo e i comandanti dove coprono più ufficiali: prima i Francesi finivano quasi
  tutti fuori comando (6 unità su 56 al turno 14), non potevano entrare nelle zone nemiche e restavano fermi,
  con 0-40 punti; ora 110-145 punti nelle partite automatiche (ne servono 230).
  Campagna alleata, sul piano storico: il 16 i Prussiani tengono i villaggi di Ligny e Wellington si concentra a
  Quatre Bras; nella notte i Prussiani si sganciano verso nord, dal 17 marciano verso ovest e il 18 puntano su
  Plancenoit e Frischermont, senza farsi trattenere per strada (una retroguardia basta); dal 17 Wellington tiene la
  cresta di Mont St Jean. Le colonne seguono le strade (distanza di marcia calcolata in punti movimento) e nelle
  notti prima del controllo del rifornimento nessuno resta tagliato fuori dalla rete stradale.
  Corretto anche un errore delle regole: di notte (e con la pioggia delle regole base) non c'è fase di comando e
  vale lo stato dell'ultima fase del giorno (11.3); prima tutte le unità diventavano fuori comando e quelle a
  contatto col nemico restavano inchiodate per tutta la notte.
- **Online** (`scripts/rete.gd`): stanza con codice di 4 lettere, decisioni numerate nel registro della stanza
  (`napoleonlb/rooms/<codice>`); i dadi sono deterministici, le due copie restano identiche. Se l'amico non entra,
  l'altra parte la guida l'IA. Le regole del database sono quelle comuni della ludoteca.
- **Salvataggi**: in locale a ogni cambio di lato e su Firebase (`napoleonlb/salvataggi/<uid>`).
- **Comandi**: trascina per spostare, rotella o pizzico per lo zoom, tasto destro o due dita per ruotare
  (anche su iPad).

## Scelte e semplificazioni

- Le ritirate le sceglie il motore (verso il terreno più lontano dal nemico), per entrambi i lati.
- La riorganizzazione della campagna è automatica all'inizio del turno del proprio lato.
- Il rifornimento della campagna segue la 4ª edizione (V6F, 14.1): Francesi al bordo sud, Prussiani a est,
  Anglo-alleati a ovest (la numerazione degli esagoni della V6F è la stessa del gioco). La rete stradale è quella
  riconosciuta dalla mappa: si collegano gli esagoni stradali adiacenti.
- Wavre: l'uscita è il bordo ovest a nord dell'esagono W0117 (il testo dice "est", ma l'esagono 01xx è a ovest).
- Ligny: livelli prussiani 55/74, francese 35 (che conta solo finché i Prussiani non sono demoralizzati, V6F 18.3A).
- Le regole facoltative 25.1-25.4 (ritirata della cavalleria prima del combattimento, partenza ritardata, impeto
  della cavalleria, avanzata con i capi) non ci sono.

## Confronto con la 4ª edizione (regole V6F, Decision Games 2015)

Verificato punto per punto con il regolamento V6F: sequenza di gioco, notte e pioggia, movimento e Tabella del
terreno, zone di controllo, impilamento, rinforzi, uscite, combattimento obbligatorio e su più esagoni, TRC,
terreno in combattimento, ritirate e spostamenti a catena, avanzata, artiglieria e linea di tiro, fattorie,
morale degli eserciti e dei corpi, capi, comando, riorganizzazione, rifornimento, armi combinate, Guardia,
livelli e vittoria dei cinque scenari. Corretti dopo il confronto: cavalleria dimezzata quando attacca *dentro*
bosco o palude (prima: quando attaccava *da* lì) con arrotondamento unico dei dimezzamenti; costo del bosco
invariato per i corpi demoralizzati; livello francese di Ligny (35); vantaggio della fattoria legato solo alla
demoralizzazione; niente avanzata per gli attaccanti fuori comando dopo uno scambio; riorganizzazione dopo un
turno completo; vicinanza dei corpi demoralizzati (22.5A) nel segmento di riorganizzazione; rifornimento alleato
a ovest; 10.1C (il capo che dà il comando ha metà movimento); uscite della campagna con rifornimento e capi
usciti (22.4B).

Regole facoltative e varianti, scelte nel menu iniziale («Scegli fra ... regole»), salvate fra una partita e
l'altra e trasmesse all'avversario online: 15.1 armi combinate, 15.2 Guardia, 15.3 ritirata a cavallo,
15.4 partenza ritardata francese, 15.5 impeto della cavalleria, 15.6 avanzata con i capi, 16.2 alba,
16.4 terreno modificato, 16.5 pioggia modificata, 16.7 effetti combinati (al posto di 15.1), 16.9 bombardamento
prolungato, 16.12 Vecchia Guardia (al posto di 15.2), 16.13 capi in combattimento, 16.15 fuori comando
modificato, 16.18 senza rifornimento. Le regole dei capi, dell'alba, della pioggia e del rifornimento valgono
solo nella campagna. Non realizzate: 16.1 pedine sostitutive, 16.3 osservazione, 16.6 movimento nascosto,
16.8 carica, 16.10 artiglieria pesante, 16.11 guarnigioni, 16.14 quartier generale, 16.16 riorganizzazione
modificata, 16.17 salmerie (servono pedine e segnalini che il gioco non ha, o la visibilità nascosta).

Capi, comando e rifornimento: nella campagna sono sempre in gioco. Nelle quattro battaglie le regole V6F usano
solo 1.0-9.0 e lasciano facoltativi capi e comando (10.0-11.0): si attivano con «10-11 Capi e comando»; ogni
ufficiale parte con un'unità del suo corpo, i comandanti presenti alla battaglia al centro del loro esercito,
chi arriva coi rinforzi entra con loro. Il rifornimento (14.0) vale solo nella campagna: si controlla una volta al
giorno, e il tasto «Rifornimento» mostra in ogni momento la rete stradale collegata al bordo amico e cerchia in
arancione le unità che ne sarebbero tagliate fuori.

«Come andò»: nella scheda della campagna, il pulsante «Come andò: la campagna vera, ora per ora» fa scorrere la
campagna storica dal 16 giugno alle 14 alla notte del 18, un turno di gioco alla volta, senza intervento: le pedine
marciano da sole (per le strade, entro i loro punti movimento) verso le posizioni dei resoconti storici, le frecce
mostrano gli attacchi, le perdite documentate eliminano le unità e i riquadri sulla mappa spiegano i momenti chiave
(d'Erlon fra Ligny e Quatre Bras, la carica di Kellermann, la ritirata su Wavre, Hougoumont, l'attacco di d'Erlon e la
carica della Union, le cariche di Ney, Plancenoit, la Guardia, Wavre). Si può mettere in pausa, tornare indietro,
cambiare ritmo e lasciare che la telecamera segua l'azione. La ricostruzione è a livello di corpo e di divisione:
nessuna fonte dà le posizioni ora per ora di ogni brigata (dati in assets/dati/storia.json, motore in
scripts/storia.gd).

Pannello di combattimento: in alto le due forze, sotto le unità coinvolte, poi ogni modificatore in parole
(terreno, ruscelli, dimezzamenti, armi combinate, capi...), infine colonna, «Attacca!» e «Annulla». Nella
campagna il tasto «Comando» mostra le aree di comando (5 esagoni i comandanti, 3 gli ufficiali) e cerchia di
rosso le unità fuori comando. Le pedine dei capi si girano sul retro quando l'ufficiale è demoralizzato o il
comandante inattivo; le unità non si girano in combattimento (in NLB non ci sono perdite di passi: si
eliminano), mostrano il retro ridotto solo dopo la riorganizzazione o quando lo scenario le schiera ridotte.

Terreno ricontrollato esagono per esagono sulle scansioni: le pedine di schieramento stampate in blu sulla
mappa di La Belle Alliance erano state lette come paesi (82 esagoni, tolti) e 33 paesi veri (St-Amand, Ligny,
Fleurus, Tilly, Mellet, Wavre...) erano terreno aperto. La mappa Reborn disegna case anche dove l'originale
aveva solo le pedine stampate (a sud di La Belle Alliance): conta il terreno dell'originale.

## Prove

```
tests/corri.sh sim.gd bellealliance 4          # partite automatiche IA contro IA (anche ligny, quatrebras, wavre, campagna)
godot --headless --path . -s res://tests/sim.gd -- ligny 10 0 --fr_vecchia   # IA attuale contro la Francia della versione 1.0
xvfb-run godot --path . -s res://tests/foto.gd -- combattimento bellealliance   # screenshot
GODOT=godot tests/prova_online.sh              # due copie del gioco online su un finto Firebase
python3 tools/controlla_glifi.py               # ogni carattere dei testi e dei dati esiste nei font
```

## Pubblicazione

Solo a richiesta: Actions → *Pubblica* → *Run workflow*, oppure un commit con `[pubblica]` nel messaggio.
Pubblica su GitHub Pages e, se ci sono i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID`, sulla ludoteca
privata di Cloudflare (`napoleonlb.<dominio>`).

Font: Old Standard TT (SIL Open Font License, in `assets/font/`), il carattere didone delle stampe dell'epoca.
