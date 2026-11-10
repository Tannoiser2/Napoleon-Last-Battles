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
			return 4.0 if (cav or demoralizzato) else 2.0
	return 999.0

static func colonna(att: float, dif: float) -> int:
	if dif <= 0:
		return 9
	if att >= dif:
		return clampi(4 + int(floor(att / dif)) - 1, 4, 9)
	var n := int(ceil(dif / maxf(att, 0.001)))
	return clampi(4 - (n - 1), 0, 4)
