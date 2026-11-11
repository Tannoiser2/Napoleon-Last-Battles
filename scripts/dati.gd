## Tabelle e costanti del gioco (dal regolamento rivisto e dalle tabelle di Napoleon's Last Battles).
class_name Dati
extends RefCounted

## Colonne della Tabella dei Risultati del Combattimento
const COLONNE := ["1-5", "1-4", "1-3", "1-2", "1-1", "2-1", "3-1", "4-1", "5-1", "6-1"]
## TRC (con l'errata: 4-1 con 5 = DR)
const TRC := [
	["AR", "AR", "DR", "DR", "DR", "DR", "DR", "DE", "DE", "DE"],
	["AR", "AR", "AR", "DR", "DR", "DR", "DR", "DR", "DE", "DE"],
	["AE", "AR", "AR", "AR", "DR", "DR", "DR", "DR", "DR", "DE"],
	["AE", "AR", "AR", "AR", "AR", "DR", "DR", "DR", "DR", "DR"],
	["AE", "AE", "AR", "AR", "AR", "AR", "DR", "DR", "EX", "EX"],
	["AE", "AE", "AE", "AR", "AR", "AR", "AR", "EX", "EX", "EX"],
]
const NOMI_RISULTATO := {
	"AE": "attaccante eliminato", "AR": "l'attaccante si ritira", "DR": "il difensore si ritira",
	"DE": "difensore eliminato", "EX": "scambio", "NE": "nessun effetto",
}
const LATI := ["Francesi", "Alleati"]
const LATI_BREVI := ["Francia", "Alleati"]
const ESERCITI := {"FR": "Armée du Nord", "PR": "Esercito prussiano", "AA": "Esercito anglo-alleato"}
const NAZ := {
	"FR": {"nome": "Francia", "col": Color(0.42, 0.66, 0.92)},
	"PR": {"nome": "Prussia", "col": Color(0.13, 0.55, 0.16)},
	"BR": {"nome": "Gran Bretagna", "col": Color(0.82, 0.2, 0.13)},
	"KGL": {"nome": "Legione tedesca del re", "col": Color(0.55, 0.13, 0.05)},
	"HAN": {"nome": "Hannover", "col": Color(0.97, 0.6, 0.6)},
	"BRU": {"nome": "Brunswick", "col": Color(0.62, 0.62, 0.62)},
	"NAS": {"nome": "Nassau", "col": Color(0.05, 0.4, 0.28)},
	"NL": {"nome": "Paesi Bassi", "col": Color(0.05, 0.38, 0.05)},
}
const TIPI := {"I": "fanteria", "C": "cavalleria", "A": "artiglieria", "HA": "artiglieria a cavallo"}
const NOMI_TERRENO := {
	"aperto": "terreno aperto", "bosco": "bosco", "palude": "palude", "citta": "paese",
	"castello": "fattoria fortificata", "lago": "lago",
}
## Regole facoltative (15.x) e varianti (16.x) della 4ª edizione: chiave, titolo, spiegazione, dove valgono
## ("tutti", "campagna" = solo dove ci sono i capi, "guardia" = dove c'è la Guardia)
const OPZIONI := [
	["armi_combinate", "15.1 Armi combinate", "Fanteria, cavalleria e artiglieria contro lo stesso esagono: +1 colonna.", "tutti"],
	["guardia", "15.2 Guardia imperiale", "Se un attacco della fanteria della Guardia fallisce (AE, AR, EX) il morale francese scende di 20 (nella campagna i corpi vicini di 7).", "guardia"],
	["ritirata_cav", "15.3 Ritirata a cavallo", "All'inizio di ogni fase di combattimento la cavalleria e l'artiglieria a cavallo a contatto, se non toccano cavalleria nemica, possono ritirarsi di un esagono.", "tutti"],
	["partenza", "15.4 Partenza ritardata francese", "Alle 6 di ogni giorno i comandanti francesi sono inattivi: non muovono né comandano finché un 1 sul dado, un comandante attivo o un nemico vicino non li sveglia.", "campagna"],
	["impeto", "15.5 Impeto della cavalleria", "Quando la cavalleria può avanzare si tira un dado: 1-2 si sceglie, 3-4 nessuno avanza, 5-6 una cavalleria deve avanzare.", "tutti"],
	["avanzata_capi", "15.6 Avanzata con i capi", "Un capo in un esagono con due unità vincitrici può avanzare con entrambe.", "campagna"],
	["alba", "16.2 Alba", "Il turno delle 6 di ogni giorno è di giorno (si combatte).", "campagna"],
	["terreno_mod", "16.4 Terreno modificato", "Il terreno colpisce chi attacca: dimezzato chi attacca un paese, l'artiglieria contro il bosco, chi attacca attraverso ruscelli e ponti; nei paesi solo la cavalleria difende dimezzata; i ponti bloccano le zone di controllo; strade e sentieri non portano dentro zone nemiche né in esagoni amici.", "tutti"],
	["pioggia_mod", "16.5 Pioggia modificata", "Con la pioggia si combatte: movimento a costo doppio (almeno un esagono), attacchi a metà forza, artiglieria solo insieme a un attacco.", "campagna"],
	["effetti_comb", "16.7 Effetti combinati", "Al posto di 15.1: contro fanteria in terreno aperto le armi combinate raddoppiano o triplicano la forza di una o due armi (sceglie il difensore).", "tutti"],
	["bomb_prol", "16.9 Bombardamento prolungato", "L'artiglieria che non ha mosso e bombarda da sola raddoppia la forza.", "tutti"],
	["garde_vieille", "16.12 La Vecchia Guardia", "Al posto di 15.2: se un attacco della Vecchia Guardia finisce in AR o AE, ogni fanteria di linea francese entro 10 esagoni tira un dado e con 1-3 fugge di tre esagoni (morale -1 per ognuna).", "guardia"],
	["bonus_capi", "16.13 Capi in combattimento", "Un comandante attivo o un ufficiale con la sua pila sposta il combattimento di due colonne a suo favore; se vince avanza con la pila; con un 6 cade.", "campagna"],
	["fc_mod", "16.15 Fuori comando modificato", "Al posto di 11.3: chi è fuori comando paga 2 per l'aperto ma entra nelle zone nemiche e attacca; per lui DR non ha effetto, e in difesa AE e AR non hanno effetto; non avanza.", "campagna"],
	["oos_mod", "16.18 Senza rifornimento", "Al posto dell'eliminazione: le unità senza rifornimento muovono quanto un dado e prima di combattere tirano (1-2 si ritirano, 3-4 metà forza, 5-6 normali).", "campagna"],
]
const OPZIONI_ATTIVE := ["armi_combinate", "guardia"]

## Livelli di demoralizzazione dei corpi (campagna)
const DEM_CORPI := {
	"FR": {"Gd": 20, "I": 15, "II": 19, "III": 13, "IV": 12, "VI": 8, "IC": 3, "IIC": 4, "IIIC": 4, "IVC": 4},
	"PR": {"I": 20, "II": 20, "III": 14, "IV": 19},
}
const DEM_NAZIONI := {"NL": 7, "NAS": 8, "BRU": 10, "HAN": 12, "KGL": 33, "BR": 40}
const NOMI_CORPI := {
	"Gd": "Guardia imperiale", "I": "I corpo", "II": "II corpo", "III": "III corpo", "IV": "IV corpo", "VI": "VI corpo",
	"IC": "I corpo di cavalleria", "IIC": "II corpo di cavalleria", "IIIC": "III corpo di cavalleria", "IVC": "IV corpo di cavalleria",
}
const NOMI_DIVISIONI := {
	"1": "1ª divisione britannica", "2": "2ª divisione britannica", "3": "3ª divisione britannica",
	"4": "4ª divisione britannica", "5": "5ª divisione britannica", "6": "6ª divisione britannica",
	"C": "cavalleria alleata", "N2": "2ª divisione olandese", "N3": "3ª divisione olandese",
	"NC": "cavalleria olandese", "B": "corpo di Brunswick",
}

## Costo per entrare in un esagono (senza strade)
static func costo_terreno(t: String, tipo: String, demoralizzato := false) -> float:
	var cav := tipo == "C" or tipo == "HA"
	match t:
		"aperto":
			return 2.0 if demoralizzato else 1.0
		"citta":
			return 1.0
		"castello":
			return 2.0
		"bosco", "palude":
			# 13.2: la demoralizzazione cambia solo il costo del terreno aperto
			return 4.0 if cav else 2.0
	return 999.0

static func colonna(att: float, dif: float) -> int:
	if dif <= 0:
		return 9
	if att >= dif:
		return clampi(4 + int(floor(att / dif)) - 1, 4, 9)
	var n := int(ceil(dif / maxf(att, 0.001)))
	return clampi(4 - (n - 1), 0, 4)
