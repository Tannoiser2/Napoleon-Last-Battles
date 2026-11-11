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
a ovest. Non realizzati: le regole facoltative 15.3-15.6 e le varianti del capitolo 16; i capi non dimezzano il
movimento quando danno il comando (10.1C); le uscite della campagna non controllano rifornimento e capi usciti
(22.4B).

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
