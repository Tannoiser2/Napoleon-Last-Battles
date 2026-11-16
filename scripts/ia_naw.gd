## Il generale artificiale per Napoleon at War: la stessa IA di Last Battles, con il terreno, l'impilamento
## (una unità per esagono) e gli obiettivi di ciascuno dei quattro giochi, presi dalle note dei giocatori.
class_name IANaw
extends IA

func _n() -> MotoreNaw:
	return m as MotoreNaw

func decidi(rq: Dictionary) -> Dictionary:
	# Marengo: il contrattacco si lancia appena è possibile, se ci sono attacchi da fare
	if rq.get("k", "") == "combattimento" and _n().contrattacco_possibile():
		var ob := m.obblighi()
		if ob["amici"].size() >= 2 or int(m.s["turno"]) >= 10:
			return {"a": "contrattacco"}
	return super.decidi(rq)

func _capienza(_h: String) -> int:
	return 1

func riserva_guardia(_id: String) -> bool:
	return false

func aggressivo(lato: int, _es := "") -> bool:
	if carattere == 2:
		return true
	var t := int(m.s["turno"])
	match _n().gioco:
		"marengo":
			# gli Austriaci attaccano all'inizio; i Francesi tengono e poi contrattaccano
			return t < 9 if lato == Motore.AL else t >= 8
		"wagram":
			return lato == Motore.FR
		"nazioni":
			# i Francesi devono battere gli Alleati prima che arrivino i rinforzi; poi tocca agli Alleati
			return lato == Motore.FR if _n().turno_gioco() <= 11 else lato == Motore.AL
		"jena":
			return lato == Motore.FR or (t >= 5 and str(m.s["naw"]["varianti"].get("opzione", "A")) == "A")
	return lato == Motore.FR

func resistere(lato: int, _es := "") -> bool:
	return not aggressivo(lato)

func obiettivi(lato: int) -> Array:
	var sc: Dictionary = m.scen
	match _n().gioco:
		"marengo":
			return [sc["marengo"], sc["pietrabuona"], "1312", "1411"]
		"wagram":
			if lato == Motore.FR:
				return ["2517", "2220", "2025", "2318", "2421", "2223", "2124"]
			return sc["aspern"] + sc["essling"] + sc["enzersdorf"] + ["2517", "2220", "2025"]
		"nazioni":
			return ["1617", "1618", "1717", "1916", "2115", "2214", "1313"] if lato == Motore.FR else ["1617", "1618", "1717", "1916", "2115"]
		"jena":
			return ["0510", "0709", "1110", "1315", "1524", "1428"]
	return []

func _difesa_hex(h: String, lato_dif: int) -> float:
	var base := 0.0
	for id in m.unita_in(h, lato_dif):
		base += float(m.forza(id))
	if Mappa.terreno(h) in ["citta", "accidentato", "palude"]:
		base *= 2.0
	return base

func _valore_terreno(h: String, tp: String) -> float:
	match Mappa.terreno(h):
		"citta", "accidentato":
			return 3.0
		"palude":
			return 1.0
		"bosco":
			# il bosco non protegge, ma blocca il tiro dell'artiglieria
			return 0.5 if tp == "I" else -0.5
	return 0.0

func rischio(h: String, sp: float, chiuso: bool) -> float:
	var minac: float = _minaccia.get(h, 0.0) * p_minaccia
	if minac <= 0.0 or sp <= 0.0:
		return 0.0
	var dif := sp
	if Mappa.terreno(h) in ["citta", "accidentato", "palude"]:
		dif *= 2.0
	var col := Dati.colonna(minac, dif)
	var v := 0.0
	for r in 6:
		match Dati.TRC[r][col]:
			"DE": v += sp
			"DR": v += sp if chiuso else 0.15 * sp
			"EX": v += sp
	return v / 6.0
