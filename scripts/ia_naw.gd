## Il generale artificiale per Napoleon at War: la stessa IA di Last Battles, con il terreno, l'impilamento
## (una unità per esagono) e gli obiettivi di ciascuno dei quattro giochi, presi dalle note dei giocatori.
class_name IANaw
extends IA

var p_aggancio := 1.0   # penalità per fermarsi a contatto con più nemici
var p_presidi := 1.0    # Marengo: presidio degli obiettivi
var p_mar_au := 15.0   # Marengo: fino a quale turno gli Austriaci attaccano (sempre: devono allontanare i Francesi da Marengo)
var p_naz3 := 1.0    # Lipsia: i Francesi attaccano anche il terzo giorno (difendendosi fermi vengono accerchiati)

func _init(motore: Motore) -> void:
	super._init(motore)
	# una sola unità per esagono e attacco obbligatorio contro tutti i nemici a contatto: chi va
	# all'attacco non si ferma accanto ad altri nemici più forti di lui
	p_altri = 1.0

func _n() -> MotoreNaw:
	return m as MotoreNaw

func decidi(rq: Dictionary) -> Dictionary:
	# Marengo: il contrattacco si lancia appena è possibile, se ci sono attacchi da fare
	if rq.get("k", "") == "combattimento" and _n().contrattacco_possibile():
		var ob := m.obblighi()
		if ob["amici"].size() >= 2 or int(m.s["turno"]) >= 10:
			return {"a": "contrattacco"}
	return super.decidi(rq)

## Nello scambio si perdono unità intere: la combinazione più piccola che arriva alla forza stampata dei
## difensori (una divisione da 11 che attacca una cavalleria da 2 la perde tutta)
func costo_scambio(va: Dictionary, att_sp: float, dif_sp: float) -> float:
	var sp := 0
	for id in va["difensori"]:
		sp += m.forza(id)
	var tot := 0.0
	for id in m._scegli_scambio(va["adiac"], sp):
		tot += float(m.forza(id))
	return tot if not va["adiac"].is_empty() else 0.0

# ---------- contesto: in Jena-Auerstadt le due battaglie hanno atteggiamenti diversi
var _campo_ctx := ""

func _miglior_posto(id: String, lato: int, info: Dictionary, nem: Array) -> String:
	var h0: String = info["da"]
	if h0 == "" and not info["rg"].is_empty():
		h0 = info["rg"].keys()[0]
	_campo_ctx = _n().campo(h0)
	var r := super._miglior_posto(id, lato, info, nem)
	_campo_ctx = ""
	return r

func saldo_atteso(va: Dictionary, lato: int) -> float:
	_campo_ctx = _n().campo(va["dif_hex"][0])
	var r := super.saldo_atteso(va, lato)
	_campo_ctx = ""
	return r

func _molt_attacco(t: String, h: String) -> float:
	if not Mappa.adiacenti(t, h) or Mappa.terreno(t) in ["citta", "accidentato", "palude"]:
		return 1.0
	if Mappa.ruscello(h, t) or Mappa.ponte(h, t):
		return 2.0
	if Mappa.pendio(h, t) and Mappa.in_basso(h, t) == h:
		return 2.0
	return 1.0

## Marengo: dopo l'attacco gli Austriaci presidiano Marengo e Pietrabuona (la loro condizione di vittoria);
## i Francesi tengono Marengo
func _esagoni_chiave(lato: int) -> Array:
	if _n().gioco != "marengo" or p_presidi <= 0.0:
		return []
	var sc: Dictionary = m.scen
	if lato == Motore.AL:
		var out := []
		for h in [sc["marengo"], sc["pietrabuona"]]:
			if m.lato_hex(h) == Motore.AL or (int(m.s["turno"]) >= 6 and not m.nemico_in(h, Motore.AL)):
				out.append(h)
		return out
	return [sc["marengo"]] if not m.nemico_in(sc["marengo"], Motore.FR) else []

## Una sola unità per esagono e niente uscita dalle zone di controllo: chi si ferma accanto a più nemici
## dovrà attaccarli tutti insieme al turno dopo (o subirne gli attacchi uno dopo l'altro). In difesa si
## preferiscono posti a contatto con un solo nemico, e mai accanto a tre o più
func _extra_posto(_id: String, h: String, lato: int, in_z: bool) -> float:
	if not in_z or p_aggancio <= 0.0:
		return 0.0
	var n := 0
	var sp := 0.0
	for v in Mappa.vicini(h):
		if m.lato_hex(v) == 1 - lato and not m.blocca_zoc(v, h):
			n += 1
			sp += _difesa_hex(v, 1 - lato)
	if n <= 1:
		return 0.0
	var mio := float(m.forza(_id))
	var pen := float(n - 1) * 2.5 + maxf(0.0, sp - 2.0 * mio) * 0.4
	return -pen * p_aggancio * (0.6 if aggressivo(lato) else 1.0)

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
			return t < int(p_mar_au) if lato == Motore.AL else t >= 8
		"wagram":
			return lato == Motore.FR
		"nazioni":
			# i Francesi devono battere gli Alleati prima che arrivino i rinforzi; poi tocca agli Alleati
			return lato == Motore.FR if (_n().turno_gioco() <= 11 or p_naz3 > 0.0) else lato == Motore.AL
		"jena":
			# Jena: Napoleone attacca Hohenlohe; Auerstadt: Davout tiene finché non arriva Morand (turno 7),
			# Brunswick attacca subito per aprirsi la strada (opzione A)
			if _campo_ctx == "A":
				return lato == Motore.AL
			return lato == Motore.FR
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
			if _campo_ctx == "A":
				return ["1524", "1428", "0926", "1027"]
			return ["0510", "0709", "1110", "1315", "0808", "1408"]
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
