# Napoleon's Last Battles — versione digitale (uso personale)

Il quadrigioco SPI del 1976 (Kevin Zucker, J.A. Nelson) sulla campagna di Waterloo, in Godot 4.7 con
esportazione web: le quattro battaglie — **Ligny**, **Quatre Bras**, **Wavre**, **La Belle Alliance** — e la
**campagna** che le unisce su un'unica mappa. Mappa 3D con le mappe e le pedine originali del modulo di Tabletop
Simulator, IA per giocare da soli, partita online con un amico e salvataggi su Firebase.

Si gioca qui: https://tannoiser2.github.io/Napoleon-last-Battles/ (e nella ludoteca: https://tannoiser2.github.io).

## Cosa c'è

- **Mappa**: le quattro mappe originali (scansioni del modulo TTS) raddrizzate e unite sulla griglia della campagna
  (57 × 67 esagoni, `assets/mappa/`, quattro tasselli webp). Terreni, corsi d'acqua, ponti, creste, strade e sentieri
  sono stati riconosciuti dai colori della mappa (`tools/estrazione/`): la griglia è stata agganciata leggendo con
  l'OCR i numeri degli esagoni. Ogni esagono conserva la sigla originale (es. B0617 = Hougoumont).
- **Pedine**: le 205 pedine originali col loro retro a forza ridotta e i 31 capi (`assets/pedine/`,
  `assets/dati/catalogo.json`); gli schieramenti dei Folio vengono dalle posizioni del modulo TTS, quelli della
  campagna dall'elenco `NLB_Campaign_Setup.pdf` e dalle tracce dei turni stampate sulle mappe.
- **Plance**: le plance dei corpi (eliminati in attesa, riorganizzabili, persi per sempre) con le pedine sopra, e la
  Tabella dei risultati e del terreno.
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
- Il rifornimento della campagna: Francesi al bordo sud, Prussiani a est, Anglo-alleati a nord o a ovest (il testo
  rivisto dice "ovest" per i Prussiani e "nord o est" per gli Anglo-alleati, che non torna con la geografia della
  campagna: Liegi a est, Ostenda a ovest). La rete stradale è quella riconosciuta dalla mappa: si collegano gli
  esagoni stradali adiacenti.
- Wavre: l'uscita è il bordo ovest a nord dell'esagono W0117 (il testo dice "est", ma l'esagono 01xx è a ovest).
- Ligny: livelli prussiani 55/74 e vittoria come nelle regole di scenario della cartella `zzNLB_changes`.
- Le regole facoltative 25.1-25.4 (ritirata della cavalleria prima del combattimento, partenza ritardata, impeto
  della cavalleria, avanzata con i capi) non ci sono.

## Prove

```
tests/corri.sh sim.gd bellealliance 4          # partite automatiche IA contro IA (anche ligny, quatrebras, wavre, campagna)
xvfb-run godot --path . -s res://tests/foto.gd -- combattimento bellealliance   # screenshot
GODOT=godot tests/prova_online.sh              # due copie del gioco online su un finto Firebase
python3 tools/controlla_glifi.py               # ogni carattere dei testi e dei dati esiste nei font
```

## Pubblicazione

Solo a richiesta: Actions → *Pubblica* → *Run workflow*, oppure un commit con `[pubblica]` nel messaggio.
Pubblica su GitHub Pages e, se ci sono i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID`, sulla ludoteca
privata di Cloudflare (`napoleonlb.<dominio>`).

Font: Old Standard TT (SIL Open Font License, in `assets/font/`), il carattere didone delle stampe dell'epoca.
