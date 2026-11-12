## Il generale artificiale: pianifica movimenti e attacchi per un lato.
## Movimento: prima cerca attacchi con buone probabilità (concentrando le forze attorno a un bersaglio,
## artiglieria a distanza di tiro), poi porta le altre unità verso il fronte o sulle posizioni da tenere.
## Combattimento: copre gli attacchi obbligatori, aggiunge l'artiglieria che bombarda senza rischi.
class_name IA
extends RefCounted

var m: Motore
var carattere := 1        # 0 prudente, 1 normale, 2 aggressivo
# parametri della difesa alleata (tarati con le partite automatiche)
var p_minaccia := 0.55    # quota della forza nemica raggiungibile che si stima arrivi su un esagono
var p_resistere := 1.0    # 1: chi vince sopravvivendo usa sganciamenti e ripiegamenti
var p_rischio_res := 1.0  # peso del rischio per chi resiste
var p_qb_attacco := 99.0  # Quatre Bras: turno da cui gli Alleati passano all'attacco
var p_coesione := 0.0     # chi resiste: valore di ogni esagono amico accanto (fino a 3)
var p_presidio := 1.0     # presidi affidati alle unità più forti (Quatre Bras: due unità nel paese)
var p_wavre := 1.0        # Wavre: sganciamento per uscire
var p_villaggi := 1.0     # Ligny: presidiare e riprendere i villaggi
var p_peso := 1.6        # quanto chi difende pesa le proprie perdite
var p_libera := 0.5       # valore delle unità amiche liberate dall'accerchiamento
# disciplina d'attacco (dai resoconti: si va a contatto solo dove si attacca bene, si avanza per chiudere)
var p_contatto := 1.0     # penalità per fermarsi a contatto senza un attacco favorevole
var p_isola := 0.0        # penalità per l'unità che resta sola vicino al nemico (provata: rende passivi)
var p_rischio_att := 0.0  # peso del rischio per chi attacca (provato: rende passivi)
var p_accerchia := 1.0    # avanzata che toglie la ritirata a un nemico ancora da attaccare
var p_tre_uno := 1.0      # abbassare il rapporto (di solito a 3-1) quando conviene: niente scambi
var p_ordine := 1.0       # prima gli attacchi al centro: le avanzate chiudono la ritirata ai vicini
var p_aggiro := 1.0       # chi va all'attacco preferisce gli esagoni che tagliano la ritirata al bersaglio
var piano: Array = []
var chiave := ""
var _fatto := ""

func _init(motore: Motore) -> void:
	m = motore

func decidi(rq: Dictionary) -> Dictionary:
	match rq.get("k", ""):
		"movimento":
			return _movimento(int(rq["lato"]))
		"combattimento":
			return _combattimento(int(rq["lato"]))
		"avanza":
			return _avanza(rq)
		"ritirata_cav":
			return _ritirata_cav(rq)
	return {"a": "fine"}

## 15.3: la cavalleria minacciata da forze molto superiori si sottrae al combattimento
func _ritirata_cav(rq: Dictionary) -> Dictionary:
	var lato := int(rq["lato"])
	for id in rq["cand"]:
		var h: String = m.s["unita"][id]["h"]
		if h in obiettivi(lato) or Mappa.terreno(h) in ["citta", "castello"]:
			continue
		var nem := 0
		for v in Mappa.vicini(h):
			for e in m.unita_in(v, 1 - lato):
				nem += m.forza(e)
		var mio := 0
		for x in m.unita_in(h, lato):
			mio += m.forza(x)
		var soglia := 3.0 if aggressivo(lato) else 2.0
		if float(nem) >= soglia * float(maxi(mio, 1)):
			return {"a": "ritira_cav", "u": id}
	return {"a": "fine"}

func _k(f: String) -> String:
	return "%s|%d|%d|%s" % [f, int(m.s["turno"]), int(m.s["lato"]), m.s["scen"]]

# =============================================================================================
# Atteggiamento

## L'IA attacca oppure tiene le posizioni? (secondo scenario, lato e turno)
func aggressivo(lato: int, es := "") -> bool:
	if carattere == 2:
		return true
	match m.s["scen"]:
		"ligny", "bellealliance":
			if lato == Motore.FR:
				return true
			return es == "PR" and m.s["scen"] == "bellealliance"
		"quatrebras":
			return lato == Motore.FR or int(m.s["turno"]) >= int(p_qb_attacco)
		"wavre":
			return lato == Motore.FR
		"campagna":
			return lato == Motore.FR or (es == "PR" and m.giorno() == 18)
	return lato == Motore.FR

## Resistere: chi vince semplicemente sopravvivendo fino a sera (Wellington alla Belle Alliance,
## Blücher a Ligny) cede terreno piuttosto che farsi accerchiare
func resistere(lato: int, es := "") -> bool:
	if lato != Motore.AL or p_resistere <= 0.0:
		return false
	match m.s["scen"]:
		"bellealliance":
			return es != "PR"
		"ligny":
			return true
		"quatrebras":
			return true
		"wavre":
			# sganciarsi serve per uscire dalla mappa (punti) e per non lasciare unità ai Francesi
			return p_wavre > 0.0
	return false

func soglia(lato: int) -> int:
	# colonna minima per un attacco voluto
	var base := 5 if aggressivo(lato) else 6
	if carattere == 0:
		base += 1
	elif carattere == 2:
		base -= 1
	return clampi(base, 4, 7)

## Obiettivi del lato: esagoni da prendere o tenere
func obiettivi(lato: int) -> Array:
	match m.s["scen"]:
		"ligny":
			return ["3755", "3854", "3855", "3955", "3256", "3357", "3457"]
		"quatrebras":
			return ["1641"]
		"wavre":
			if lato == Motore.AL and int(m.s["turno"]) > 3:
				return ["4609", "4407", "4205"]
			return ["2901", "2903", "2905", "2907", "2909", "2911", "2913", "2915", "2917"]
		"bellealliance":
			return ["0607", "0708", "0709", "0811", "0812"] if lato == Motore.FR else ["0811", "0812", "0617", "0916", "1423"]
		"campagna":
			return ["0605", "0812", "1641"] if lato == Motore.FR else ["1641", "0812", "3755", "4609"]
	return []

# =============================================================================================
# Strumenti

func _nemici(lato: int) -> Array:
	var out := []
	for id in m.s["unita"]:
		if m.lato_di(id) != lato and m.s["unita"][id]["st"] == "mappa":
			out.append(id)
	return out

func _dist_nemico(h: String, lato: int, nem: Array) -> int:
	var best := 99
	for id in nem:
		var d := Mappa.distanza(h, m.s["unita"][id]["h"])
		if d < best:
			best = d
	return best

func _difesa_hex(h: String, lato_dif: int) -> float:
	var base := 0.0
	for id in m.unita_in(h, lato_dif):
		var f := float(m.forza(id))
		if m.tipo(id) == "C" and Mappa.terreno(h) in ["bosco", "palude"]:
			f = ceilf(f / 2.0)
		base += f
	match Mappa.terreno(h):
		"citta":
			base *= 2.0
		"castello":
			base *= 3.0
	return base

func _valore_terreno(h: String, tp: String) -> float:
	match Mappa.terreno(h):
		"citta":
			return 3.0
		"castello":
			return 4.0 if tp == "I" else 1.0
		"bosco":
			return 1.0 if tp == "I" else -2.0
		"palude":
			return -1.5
	return 0.0

## La Guardia imperiale si tiene in riserva: un suo attacco respinto demoralizza l'esercito
func riserva_guardia(id: String) -> bool:
	if m.esercito(id) != "FR" or m.tipo(id) != "I" or not str(m.cat(id)["des"]).ends_with("Gd"):
		return false
	var finale: bool = int(m.s["turno"]) >= m.scen["turni"].size() - 3
	if m.campagna():
		return not finale
	var nemico_rotto := false
	for k in m.s["dem"]:
		if m.s["dem"][k] and not str(k).begins_with("FR"):
			nemico_rotto = true
	return not (finale or nemico_rotto)

## Valore atteso di un attacco per l'attaccante, colonna per colonna (dalla TRC)
func valore_colonna(col: int) -> float:
	var v := 0.0
	for r in 6:
		match Dati.TRC[r][clampi(col, 0, 9)]:
			"DE": v += 2.0
			"DR": v += 1.0
			"EX": v += 0.6
			"AR": v -= 0.8
			"AE": v -= 2.0
	return v / 6.0

## Il nemico in h è chiuso (non ha esagoni liberi per ritirarsi)? Allora un DR lo elimina:
## è la fonte principale delle perdite secondo i resoconti di gioco
func senza_ritirata(h: String, lato_dif: int) -> bool:
	for v in Mappa.vicini(h):
		if not Mappa.passabile(h, v) or m.nemico_in(v, lato_dif) or m.zoc(v, 1 - lato_dif):
			continue
		if m.unita_in(v, lato_dif).size() < _capienza(v):
			return false
	return true

## Il nemico in e resterebbe senza ritirata se un'unità amica occupasse h (che con la sua zona di
## controllo chiude anche gli esagoni attorno)?
func _chiuso_con(e: String, lato_dif: int, h: String) -> bool:
	for v in Mappa.vicini(e):
		if v == h or Mappa.adiacenti(v, h):
			continue
		if not Mappa.passabile(e, v) or m.nemico_in(v, lato_dif) or m.zoc(v, 1 - lato_dif):
			continue
		if m.unita_in(v, lato_dif).size() < _capienza(v):
			return false
	return true

var _ponti := []

## I ponti sulla Dyle (Wavre): la chiave della partita
func ponti() -> Array:
	if _ponti.is_empty():
		for k in Mappa.lati:
			var v: String = Mappa.lati[k]
			if v.begins_with("F") and v.contains("p"):
				for h in String(k).split("-"):
					if not _ponti.has(h):
						_ponti.append(h)
	return _ponti

func _capienza(h: String) -> int:
	return 1 if Mappa.terreno(h) == "castello" else 2

# =============================================================================================
# Movimento

var _occ_piano := {}
var _minaccia := {}
var _forza_piano := {}
var _retroguardia := {}
var _presidio := {}

func _movimento(lato: int) -> Dictionary:
	if chiave != _k("mov"):
		chiave = _k("mov")
		piano = _pianifica_movimento(lato)
	while not piano.is_empty():
		var d: Dictionary = piano.pop_front()
		if _valida_mossa(d):
			return d
	# ultime correzioni d'impilamento
	for h in m.ammassati():
		for id in m.unita_in(h, lato):
			if m.puo_muovere(id):
				var rg := m.raggiungibili(id)
				for x in rg:
					if x != h and m.unita_in(x, lato).size() < _capienza(x) and not m.zoc(x, 1 - lato):
						return {"a": "muovi", "u": id, "h": x}
	return {"a": "fine"}

## 22.4B: le unità uscite contano solo se escono anche i loro ufficiali e abbastanza comandanti
func _uscite_capi(piano_usc: Array) -> Array:
	var out := []
	var uscenti := {}
	for mv in piano_usc:
		if mv["a"] == "esci":
			uscenti[mv["u"]] = true
	var capacita := 0
	var uff_fuori := 0
	for c in m.s["capi"]:
		if m.lato_di(c) == Motore.FR and m.s["capi"][c]["st"] == "uscita":
			if int(m.catalogo["capi"][c]["cap"]) > 0:
				capacita += int(m.catalogo["capi"][c]["cap"])
			else:
				uff_fuori += 1
	var da_far_uscire := []
	for c in m.s["capi"]:
		var k: Dictionary = m.catalogo["capi"][c]
		if m.lato_di(c) != Motore.FR or m.s["capi"][c]["st"] != "mappa" or int(k["cap"]) > 0:
			continue
		var usciti := 0
		var restano := 0
		for id in m.s["unita"]:
			if m.lato_di(id) != Motore.FR or m.ufficiale_di(id) != c:
				continue
			var st: String = m.s["unita"][id]["st"]
			if st == "uscita" or uscenti.has(id):
				usciti += 1
			elif st == "mappa" or st == "arrivo":
				restano += 1
		if usciti > 0 and restano == 0 and m.raggiungibili(c).has("0605"):
			da_far_uscire.append(c)
	for c in da_far_uscire:
		out.append({"a": "esci_capo", "c": c})
		uff_fuori += 1
	if uff_fuori > capacita:
		for c in m.s["capi"]:
			var k: Dictionary = m.catalogo["capi"][c]
			if m.lato_di(c) == Motore.FR and m.s["capi"][c]["st"] == "mappa" and int(k["cap"]) > 0 and k["n"] != "Napoleone" and m.raggiungibili(c).has("0605"):
				out.append({"a": "esci_capo", "c": c})
				capacita += int(k["cap"])
				if capacita >= uff_fuori:
					break
	return out

func _valida_mossa(d: Dictionary) -> bool:
	match d["a"]:
		"muovi":
			return m.puo_muovere(d["u"]) and d["h"] != m.s["unita"][d["u"]]["h"] and m.raggiungibili(d["u"]).has(d["h"]) and m.unita_in(d["h"], m.lato_di(d["u"])).size() < _capienza(d["h"])
		"entra":
			return d["u"] in m.arrivi_disponibili(m.lato_di(d["u"])) and m.raggiungibili_arrivo(d["u"]).has(d["h"]) and m.unita_in(d["h"], m.lato_di(d["u"])).size() < _capienza(d["h"])
		"esci", "esci_capo":
			return true
		"capo":
			return m.raggiungibili(d["c"]).has(d["h"])
	return false

func _pianifica_movimento(lato: int) -> Array:
	var out := []
	_occ_piano = {}
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if u["st"] == "mappa" and m.lato_di(id) == lato:
			_occ_piano[u["h"]] = _occ_piano.get(u["h"], 0) + 1
	var nem := _nemici(lato)
	_minaccia = _calcola_minaccia(lato, nem) if (resistere(lato, "AA") or resistere(lato, "PR") or p_rischio_att > 0.0) else {}
	_forza_piano = {}
	for id in m.s["unita"]:
		if m.s["unita"][id]["st"] == "mappa" and m.lato_di(id) == lato:
			var hh: String = m.s["unita"][id]["h"]
			_forza_piano[hh] = _forza_piano.get(hh, 0.0) + m.forza(id)
	# unità che possono muovere (e rinforzi), con le loro destinazioni possibili
	var mobili := {}
	for id in m.s["unita"]:
		if m.lato_di(id) == lato and m.puo_muovere(id):
			mobili[id] = {"rg": m.raggiungibili(id), "arr": false, "da": m.s["unita"][id]["h"]}
	for id in m.arrivi_disponibili(lato):
		var rg := m.raggiungibili_arrivo(id)
		if not rg.is_empty():
			mobili[id] = {"rg": rg, "arr": true, "da": ""}
	# Wavre: un terzo dei Prussiani fa da retroguardia sui ponti, gli altri escono subito
	_retroguardia = {}
	if m.s["scen"] == "wavre" and lato == Motore.AL:
		var lista := []
		for id in m.s["unita"]:
			if m.lato_di(id) == lato and m.s["unita"][id]["st"] == "mappa":
				var dp := 99
				for p in ponti():
					dp = mini(dp, Mappa.distanza(m.s["unita"][id]["h"], p))
				lista.append([dp, id])
		lista.sort()
		for i in int(lista.size() / 3):
			_retroguardia[lista[i][1]] = true
	# presidi: esagoni chiave da tenere sempre occupati (Waterloo alle spalle di Wellington, l'incrocio di Quatre Bras)
	_presidio = {}
	var chiave_hex := []
	match m.s["scen"]:
		"bellealliance":
			if lato == Motore.AL:
				chiave_hex = ["0708", "0709", "0607"]
		"quatrebras":
			if lato == Motore.AL:
				chiave_hex = ["1641"]
		"ligny":
			if lato == Motore.AL and p_villaggi > 0.0:
				# ogni villaggio perso abbassa di 3 la soglia di demoralizzazione prussiana
				chiave_hex = obiettivi(lato)
	for hk in chiave_hex:
		# posti da coprire: a Quatre Bras il paese si riempie (la difesa raddoppia), altrove basta un'unità
		var posti := 1
		if m.s["scen"] == "quatrebras" and p_presidio > 0.0:
			posti = _capienza(hk)
		for x in m.unita_in(hk, lato):
			if not mobili.has(x):
				posti -= 1
		for _n in posti:
			var best := ""
			var bv := -INF
			for id in mobili:
				if _presidio.has(id) or (m.esercito(id) == "PR" and m.s["scen"] == "bellealliance") or not mobili[id]["rg"].has(hk):
					continue
				var d := Mappa.distanza(mobili[id]["da"] if mobili[id]["da"] != "" else hk, hk)
				var v := -float(d)
				if p_presidio > 0.0 and m.s["scen"] == "quatrebras":
					# l'incrocio va alle unità più forti, fanteria prima di tutto (la cavalleria non difende i paesi meglio)
					v += float(m.forza(id)) * 0.8 + (2.0 if m.tipo(id) == "I" else 0.0)
				if v > bv:
					bv = v
					best = id
			if best != "":
				_presidio[best] = hk
	# uscite
	for id in mobili.keys():
		if _retroguardia.has(id) and int(m.s["turno"]) < m.scen["turni"].size() - 1:
			continue
		if mobili[id]["arr"]:
			continue
		var h_usc := _uscita(id, lato, mobili[id])
		if h_usc != "":
			out.append({"a": "esci", "u": id, "h": h_usc})
			_occ_piano[mobili[id]["da"]] = _occ_piano.get(mobili[id]["da"], 1) - 1
			mobili.erase(id)
	if m.campagna() and lato == Motore.FR:
		out += _uscite_capi(out)
	# 1. attacchi concentrati
	var assegnate := {}
	for att in _pianifica_attacchi(lato, mobili, nem):
		for mv in att:
			out.append(mv)
			assegnate[mv["u"]] = true
	# 2. le altre unità: verso il fronte o in difesa, prima le più vicine al nemico
	var resto := []
	for id in mobili:
		if not assegnate.has(id):
			var h0: String = mobili[id]["da"] if mobili[id]["da"] != "" else mobili[id]["rg"].keys()[0]
			resto.append([_dist_nemico(h0, lato, nem), id])
	resto.sort()
	for x in resto:
		var id: String = x[1]
		var best := _miglior_posto(id, lato, mobili[id], nem)
		if best == "":
			continue
		if mobili[id]["arr"]:
			out.append({"a": "entra", "u": id, "h": best})
		elif best != mobili[id]["da"]:
			out.append({"a": "muovi", "u": id, "h": best})
		else:
			continue
		if mobili[id]["da"] != "":
			_occ_piano[mobili[id]["da"]] = _occ_piano.get(mobili[id]["da"], 1) - 1
		_occ_piano[best] = _occ_piano.get(best, 0) + 1
		_forza_piano[best] = _forza_piano.get(best, 0.0) + m.forza(id)
		if mobili[id]["da"] != "":
			_forza_piano[mobili[id]["da"]] = _forza_piano.get(mobili[id]["da"], 0.0) - m.forza(id)
	# 3. capi (campagna, o battaglia con le regole 10-11)
	if m.comando():
		out.append_array(_muovi_capi(lato))
	return out

## Forza nemica che può colpire ciascun esagono nel prossimo turno (movimento più attacco,
## artiglieria anche a due esagoni): serve a chi difende per non esporsi a rapporti schiaccianti
func _calcola_minaccia(lato: int, nem: Array) -> Dictionary:
	var pot := {}
	for e in nem:
		var f := m.forza_att(e)
		var art: bool = m.tipo(e) in ["A", "HA"]
		var h0: String = m.s["unita"][e]["h"]
		var rg: Dictionary = {h0: {"c": 0}} if m.in_ezoc(e) else m.raggiungibili(e, h0)
		var toccati := {}
		for r in rg:
			for x in Mappa.vicini(r):
				if Mappa.passabile(r, x) and not (Mappa.fiume(r, x) and not Mappa.ponte(r, x)):
					toccati[x] = true
				if art:
					for y in Mappa.vicini(x):
						toccati[y] = true
		for x in toccati:
			pot[x] = pot.get(x, 0.0) + f
	return pot

## Perdita attesa (in punti forza) di chi difende h con forza sp contro la minaccia stimata
func rischio(h: String, sp: float, chiuso: bool) -> float:
	var minac: float = _minaccia.get(h, 0.0) * p_minaccia
	if minac <= 0.0 or sp <= 0.0:
		return 0.0
	var dif := sp
	match Mappa.terreno(h):
		"citta":
			dif *= 2.0
		"castello":
			dif *= 3.0
	var col := Dati.colonna(minac, dif)
	var v := 0.0
	for r in 6:
		match Dati.TRC[r][col]:
			"DE": v += sp
			"DR": v += sp if chiuso else 0.15 * sp
			"EX": v += sp
	return v / 6.0

func _peso_rischio(lato: int, es := "") -> float:
	return p_rischio_res if resistere(lato, es) else p_rischio_att

func _uscita(id: String, lato: int, info: Dictionary) -> String:
	match m.s["scen"]:
		"wavre":
			if lato == Motore.AL and int(m.s["turno"]) > 3:
				return ""
		"campagna":
			if lato != Motore.FR:
				return ""
		_:
			return ""
	var rg: Dictionary = info["rg"]
	for h in rg:
		if m.uscita_valida(id, h) and not m.zoc(h, 1 - lato) and rg[h]["c"] + Dati.costo_terreno(Mappa.terreno(h), m.tipo(id)) <= m.ma(id):
			if _occ_piano.get(h, 0) < _capienza(h):
				return h
	return ""

## Concentrazioni d'attacco: per ogni bersaglio debole si cercano unità che arrivano accanto
func _pianifica_attacchi(lato: int, mobili: Dictionary, nem: Array) -> Array:
	var risultato := []
	if m.senza_combattimento():
		return risultato
	var bersagli := {}
	for id in nem:
		bersagli[m.s["unita"][id]["h"]] = true
	var lista := []
	var obi := obiettivi(lato)
	for h in bersagli:
		var dv := _difesa_hex(h, 1 - lato)
		var val := -dv
		if h in obi:
			val += 6.0
		if senza_ritirata(h, 1 - lato):
			val += 8.0
		if Mappa.terreno(h) == "castello":
			val -= 20.0
		lista.append([val, h])
	lista.sort()
	lista.reverse()
	var usate := {}
	var aggr := aggressivo(lato)
	var limite := 6 if aggr else 2
	var soglia_min := soglia(lato)
	for x in lista:
		if risultato.size() >= limite:
			break
		var t: String = x[1]
		if Mappa.terreno(t) == "castello":
			continue
		var dif := _difesa_hex(t, 1 - lato)
		# forze già a contatto (attaccheranno comunque)
		var forza := 0.0
		for v in Mappa.vicini(t):
			for id in m.unita_in(v, lato):
				if not mobili.has(id) and not usate.has(id):
					forza += m.forza_att(id, t)
		var mosse := []
		var posti := {}
		var cand := []
		for id in mobili:
			if usate.has(id):
				continue
			if riserva_guardia(id) or _presidio.has(id):
				continue
			var rg: Dictionary = mobili[id]["rg"]
			var art: bool = m.tipo(id) in ["A", "HA"]
			for h in rg:
				var d := Mappa.distanza(h, t)
				if d == 1 and Mappa.passabile(h, t) and not (Mappa.fiume(h, t) and not Mappa.ponte(h, t)):
					if art and aggr:
						cand.append([1, id, h])
					elif not art:
						cand.append([0, id, h])
				elif d == 2 and art and not m.zoc(h, 1 - lato) and Mappa.terreno(t) != "castello" and m.linea_di_tiro(h, t):
					cand.append([0, id, h])
		# aggiramento: gli esagoni accanto al bersaglio che ne coprono le vie di ritirata vengono prima
		var vie := []
		if p_aggiro > 0.0:
			for v in Mappa.vicini(t):
				if Mappa.passabile(t, v) and not m.nemico_in(v, 1 - lato) and not m.zoc(v, lato) and m.lato_hex(v) != lato:
					vie.append(v)
		var chiude := {}
		for c in cand:
			var hc: String = c[2]
			var n := 0
			for v in vie:
				if v == hc or Mappa.adiacenti(v, hc):
					n += 1
			chiude[hc] = n
		cand.sort_custom(func(a, b):
			if a[0] != b[0]:
				return a[0] < b[0]
			if p_aggiro > 0.0 and chiude[a[2]] != chiude[b[2]]:
				return chiude[a[2]] > chiude[b[2]]
			return m.forza(a[1]) > m.forza(b[1]))
		var presi := {}
		var tipi := {}
		for c in cand:
			var id: String = c[1]
			var h: String = c[2]
			if presi.has(id):
				continue
			if _occ_piano.get(h, 0) + posti.get(h, 0) >= _capienza(h):
				continue
			# non fermarsi accanto ad altri nemici troppo forti
			var altri := 0.0
			for v in Mappa.vicini(h):
				if v != t and m.lato_hex(v) == 1 - lato:
					altri += _difesa_hex(v, 1 - lato)
			if altri > m.forza(id) * 2.0 and Mappa.distanza(h, t) == 1:
				continue
			presi[id] = true
			posti[h] = posti.get(h, 0) + 1
			forza += m.forza_att(id, t)
			tipi[m.tipo(id).substr(0, 1)] = true
			mosse.append({"a": "entra" if mobili[id]["arr"] else "muovi", "u": id, "h": h})
			if Dati.colonna(forza, dif) >= soglia_min + 1:
				break
		var col := Dati.colonna(forza, dif)
		if m.s["opzioni"].get("armi_combinate", true) and tipi.has("I") and tipi.has("C") and tipi.has("A"):
			col += 1
		if col >= soglia_min and not mosse.is_empty():
			# l'attacco deve avere almeno un'unità adiacente
			var adi := false
			for mv in mosse:
				if Mappa.distanza(mv["h"], t) == 1:
					adi = true
			for v in Mappa.vicini(t):
				if not m.unita_in(v, lato).is_empty():
					adi = true
			if not adi and not aggr:
				continue
			for mv in mosse:
				usate[mv["u"]] = true
				var da: String = mobili[mv["u"]]["da"]
				if da != "":
					_occ_piano[da] = _occ_piano.get(da, 1) - 1
				_occ_piano[mv["h"]] = _occ_piano.get(mv["h"], 0) + 1
			risultato.append(mosse)
	return risultato

func _miglior_posto(id: String, lato: int, info: Dictionary, nem: Array) -> String:
	var rg: Dictionary = info["rg"]
	var tp := m.tipo(id)
	var aggr := aggressivo(lato, m.esercito(id))
	var obi := obiettivi(lato)
	var best := ""
	var bv := -INF
	var h0: String = info["da"]
	if _presidio.has(id):
		var hp: String = _presidio[id]
		if rg.has(hp) and (_occ_piano.get(hp, 0) < _capienza(hp) or hp == h0):
			return hp
	for h in rg:
		if h != h0 and _occ_piano.get(h, 0) >= _capienza(h):
			continue
		var v := 0.0
		var dn := _dist_nemico(h, lato, nem)
		var in_z := m.zoc(h, 1 - lato)
		if in_z and riserva_guardia(id):
			continue
		if in_z:
			# fermarsi a contatto obbliga ad attaccare: solo se il rapporto è buono
			var dif := 0.0
			for x in Mappa.vicini(h):
				if m.lato_hex(x) == 1 - lato:
					dif += _difesa_hex(x, 1 - lato)
			var att := float(m.forza(id))
			for x in m.unita_in(h, lato):
				att += m.forza(x)
			var col := Dati.colonna(att, dif)
			# conta anche gli amici che sono già a contatto con gli stessi nemici
			for x in Mappa.vicini(h):
				if m.lato_hex(x) == 1 - lato:
					for y in Mappa.vicini(x):
						if y != h and m.lato_hex(y) == lato:
							for z in m.unita_in(y, lato):
								att += m.forza(z) * 0.5
			col = Dati.colonna(att, dif)
			v += (col - soglia(lato)) * 3.0 - 4.0
			if col < 4:
				v -= 8.0
			# a contatto si è obbligati ad attaccare: a 1-3 o peggio (dove si può perdere l'unità) ci si
			# ferma a due esagoni; un 1-2 resta un diversivo senza rischi
			if col < 3 and not _presidio.has(id):
				v -= 10.0 * p_contatto
		if aggr:
			v -= dn * 2.0
			if dn == 2 and not in_z:
				v += 2.0
		else:
			# in difesa: vicino agli obiettivi e su buon terreno, senza correre verso il nemico
			var dobj := 99
			for o in obi:
				dobj = mini(dobj, Mappa.distanza(h, o))
			if dobj < 99:
				v -= dobj * 1.2
			if dn <= 2:
				v += 1.0
			v -= maxf(0.0, 6.0 - dn) * 0.2 if dn > 3 else 0.0
		if not obi.is_empty():
			var dobj2 := 99
			for o in obi:
				dobj2 = mini(dobj2, Mappa.distanza(h, o))
			v -= dobj2 * (0.6 if aggr else 0.0)
		v += _valore_terreno(h, tp) * (0.6 if aggr else 1.2)
		if not aggr and dn <= 4:
			# contropendenza: una cresta fra noi e il nemico ferma il tiro dell'artiglieria (Wellington)
			for x in Mappa.vicini(h):
				if Mappa.cresta(h, x) and _dist_nemico(x, lato, nem) < dn:
					v += 1.5
					break
			# tenere aperta una via di ritirata: chi resta chiuso viene eliminato da un DR
			var libere := 0
			for x in Mappa.vicini(h):
				if Mappa.passabile(h, x) and not m.nemico_in(x, lato) and _dist_nemico(x, lato, nem) > 1:
					libere += 1
			if libere == 0:
				v -= 3.0
			# due unità nei paesi: la difesa raddoppiata vale doppio
			if Mappa.terreno(h) == "citta" and _occ_piano.get(h, 0) == 1:
				v += 1.0
		# coesione: chi resiste tiene una linea compatta, con i fianchi coperti da unità amiche
		if p_coesione > 0.0 and resistere(lato, m.esercito(id)) and dn <= 6:
			var amici := 0
			for x in Mappa.vicini(h):
				if _occ_piano.get(x, 0) > 0:
					amici += 1
			v += p_coesione * mini(amici, 3)
			if amici == 0:
				v -= p_coesione * 2.0
		# esposizione: quanto si rischia di perdere restando qui nel turno nemico
		var pr := _peso_rischio(lato, m.esercito(id))
		if pr > 0.0 and dn <= 8:
			var lib := 0
			for x in Mappa.vicini(h):
				if Mappa.passabile(h, x) and not m.nemico_in(x, lato) and _dist_nemico(x, lato, nem) > 1:
					lib += 1
			var sp: float = float(m.forza(id)) + _forza_piano.get(h, 0.0) - (float(m.forza(id)) if h == h0 else 0.0)
			v -= pr * rischio(h, sp, lib <= 1)
		# nessuno si spinge da solo vicino al nemico: le unità isolate sono le prime a essere accerchiate
		if p_isola > 0.0 and dn <= 3:
			var vicini_amici := 0
			for x in Mappa.vicini(h):
				if _occ_piano.get(x, 0) > 0:
					vicini_amici += 1
			if _occ_piano.get(h, 0) - (1 if h == h0 else 0) > 0:
				vicini_amici += 1
			if vicini_amici == 0:
				v -= 3.0 * p_isola
		if tp in ["A", "HA"] and in_z:
			v -= 3.0
		if tp in ["A", "HA"] and dn == 2:
			v += 2.0
		v -= _occ_piano.get(h, 0) * 0.3
		if h == h0:
			v += 0.4
		# accanto a una fattoria nemica si è obbligati ad attaccarla a 4-1 al massimo
		for x in Mappa.vicini(h):
			if Mappa.terreno(x) == "castello" and m.lato_hex(x) == 1 - lato:
				v -= 4.0
		# comando: restare entro 3 esagoni dal proprio ufficiale
		if m.comando():
			var uf := m.ufficiale_di(id)
			if uf != "" and m.s["capi"][uf]["st"] == "mappa":
				var du := Mappa.distanza(h, m.s["capi"][uf]["h"])
				if du > 3:
					v -= (du - 3) * 0.8
		# Wavre: la retroguardia prussiana tiene i ponti, i Francesi li vogliono
		if m.s["scen"] == "wavre":
			var dp := 99
			for p in ponti():
				dp = mini(dp, Mappa.distanza(h, p))
			if lato == Motore.FR:
				v -= dp * 0.5
			elif _retroguardia.has(id):
				v -= dp * 2.0
		if v > bv:
			bv = v
			best = h
	return best

func _muovi_capi(lato: int) -> Array:
	var out := []
	for c in m.s["capi"]:
		var cc: Dictionary = m.s["capi"][c]
		if cc["st"] != "mappa" or m.lato_di(c) != lato:
			continue
		var cat: Dictionary = Motore.catalogo["capi"][c]
		# baricentro delle unità da comandare (pianificato)
		var somma := Vector2.ZERO
		var n := 0
		for id in m.s["unita"]:
			var u: Dictionary = m.s["unita"][id]
			if u["st"] != "mappa" or m.esercito(id) != cat["es"]:
				continue
			if int(cat["cap"]) == 0:
				var des: String = m.cat(id)["c"] if cat["es"] != "AA" else m.cat(id)["des"]
				if des != cat["des"]:
					continue
			somma += Mappa.pos(u["h"])
			n += 1
		if n == 0:
			continue
		var p := somma / n
		var rg := m.raggiungibili(c)
		var best: String = cc["h"]
		var bd := Mappa.pos(best).distance_to(p)
		for h in rg:
			var d := Mappa.pos(h).distance_to(p)
			if m.zoc(h, 1 - lato):
				d += 200.0
			if d < bd - 1.0:
				bd = d
				best = h
		if best != cc["h"]:
			out.append({"a": "capo", "c": c, "h": best})
	return out

# =============================================================================================
# Combattimento

func _combattimento(lato: int) -> Dictionary:
	for _i in 3:
		if chiave != _k("comb") or piano.is_empty():
			if chiave == _k("comb") and piano.is_empty() and _fatto == chiave:
				return {"a": "fine"}
			chiave = _k("comb")
			piano = _pianifica_attacchi_fase(lato)
			_fatto = chiave
			if piano.is_empty():
				return {"a": "fine"}
		while not piano.is_empty():
			var d: Dictionary = piano.pop_front()
			if m.valuta_attacco(d)["ok"]:
				return d
		# il piano non vale più (ritirate, avanzate): si rifà
		_fatto = ""
	return {"a": "fine"}

func _pianifica_attacchi_fase(lato: int) -> Array:
	var out := []
	var ob := m.obblighi()
	# gruppi d'attacco per esagono amico
	var gruppi := {}
	for id in ob["amici"]:
		var h: String = m.s["unita"][id]["h"]
		if not gruppi.has(h):
			gruppi[h] = []
		gruppi[h].append(id)
	var bersagli_di := {}
	for h in gruppi:
		var b := []
		for e in ob["nemici"]:
			if Mappa.adiacenti(h, e) and not (Mappa.fiume(h, e) and not Mappa.ponte(h, e)):
				b.append(e)
		bersagli_di[h] = b
	var lista: Array
	if m.s["scen"] == "wavre" and lato == Motore.AL and p_wavre > 0.0:
		lista = _assegna_classica(gruppi, bersagli_di, ob["nemici"], lato)
	else:
		lista = _assegna_obbligati(gruppi, bersagli_di, ob["nemici"], lato)
	# artiglieria che bombarda: dove alza la colonna, oppure da sola sul bersaglio più debole
	var artiglieria := []
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if u["st"] == "mappa" and m.lato_di(id) == lato and m.tipo(id) in ["A", "HA"] and not u["att"] and not m.in_ezoc(id):
			artiglieria.append(id)
	for a in artiglieria:
		var migliore := -1
		var guad := -1
		for i in lista.size():
			var ok := false
			for h in lista[i]["dif"]:
				if m.puo_bombardare(a, h):
					ok = true
			if not ok:
				continue
			var v0 := m.valuta_attacco(lista[i])
			var prova: Dictionary = lista[i].duplicate(true)
			prova["att"].append(a)
			var v1 := m.valuta_attacco(prova)
			if v0["ok"] and v1["ok"]:
				var g := int(v1["col"]) - int(v0["col"])
				if g > guad:
					guad = g
					migliore = i
		if migliore >= 0 and guad > 0:
			lista[migliore]["att"].append(a)
			continue
		# bombardamento autonomo: il bersaglio più debole a tiro non già attaccato
		var bb := ""
		var bd := INF
		for id in _nemici(lato):
			var h: String = m.s["unita"][id]["h"]
			if m.s["unita"][id]["dif"] or not m.puo_bombardare(a, h):
				continue
			var gia := false
			for at in lista:
				if h in at["dif"]:
					gia = true
			if gia:
				continue
			var dv := _difesa_hex(h, 1 - lato)
			if dv < bd:
				bd = dv
				bb = h
		if bb != "":
			var nuovo := true
			for at in lista:
				if at["dif"] == [bb] and at.get("solo_art", false):
					at["att"].append(a)
					nuovo = false
			if nuovo:
				lista.append({"dif": [bb], "att": [a], "solo_art": true})
		elif migliore >= 0:
			lista[migliore]["att"].append(a)
	for at in lista:
		at.erase("solo_art")
		var d := {"a": "attacco", "dif": at["dif"], "att": at["att"]}
		# rapporto ridotto: contro chi non può ritirarsi un 3-1 elimina quasi come un 4-1, senza scambi
		if p_tre_uno > 0.0:
			var va := m.valuta_attacco(d)
			if va["ok"] and int(va["col_max"]) >= 6:
				var best_c := int(va["col_max"])
				var best_v := saldo_atteso(va, lato)
				for c in range(int(va["col_max"]) - 1, 4, -1):
					var vc: Dictionary = va.duplicate()
					vc["col"] = c
					var sv := saldo_atteso(vc, lato)
					if sv > best_v + 0.05:
						best_v = sv
						best_c = c
				if best_c < int(va["col_max"]):
					d["col"] = best_c
		out.append(d)
	# ordine: prima gli attacchi migliori; con p_ordine prima quelli al centro di un gruppo di bersagli,
	# perché le avanzate chiudono la ritirata ai vicini (e chi è già chiuso va per ultimo)
	var punti := {}
	for d in out:
		var va := m.valuta_attacco(d)
		var pv := float(va.get("col", 0))
		if p_ordine > 0.0:
			var vicini_b := 0
			for e in out:
				if e != d and Mappa.distanza(e["dif"][0], d["dif"][0]) <= 2:
					vicini_b += 1
			pv += p_ordine * 0.6 * vicini_b
			if senza_ritirata(d["dif"][0], 1 - lato):
				pv -= p_ordine * 1.5
		punti[d] = pv
	out.sort_custom(func(x, y): return punti[x] > punti[y])
	return out

## Attacchi obbligatori: ogni gruppo a contatto deve attaccare e ogni nemico a contatto deve essere attaccato.
## Si cerca la combinazione con il miglior saldo atteso di punti forza (perdite nemiche meno le proprie),
## con attacchi diversivi a 1-2 (nessun rischio di eliminazione) dove non si può vincere.
func _assegna_obbligati(gruppi: Dictionary, bersagli_di: Dictionary, nemici: Array, lato: int) -> Array:
	var hexs: Array = []
	for h in gruppi:
		if not bersagli_di[h].is_empty():
			hexs.append(h)
	hexs.sort()
	if hexs.is_empty():
		return []
	# per ogni gruppo: le combinazioni di bersagli possibili (al più tre esagoni)
	var opz := {}
	for h in hexs:
		var b: Array = bersagli_di[h].duplicate()
		b.sort()
		var lista := []
		var n := b.size()
		for mask in range(1, 1 << n):
			var sub := []
			for i in n:
				if mask & (1 << i):
					sub.append(b[i])
			if sub.size() <= 3:
				lista.append("+".join(sub))
		lista.sort_custom(func(x, y): return x.length() < y.length() or (x.length() == y.length() and x < y))
		opz[h] = lista
	_cache_val = {}
	var scelta := {}
	for h in hexs:
		scelta[h] = opz[h][0]
	# partenza golosa: ogni gruppo al bersaglio singolo che rende di più da solo
	for h in hexs:
		var bv := -INF
		for k in opz[h]:
			if k.contains("+"):
				continue
			var v := _val_attacco(k, gruppi[h], lato)
			if v > bv:
				bv = v
				scelta[h] = k
	var cur := _val_scelta(scelta, gruppi, nemici, lato)
	for _giro in 8:
		var meglio := false
		# mosse singole
		for h in hexs:
			var k0: String = scelta[h]
			for k in opz[h]:
				if k == k0:
					continue
				scelta[h] = k
				var v := _val_scelta(scelta, gruppi, nemici, lato)
				if v > cur + 0.01:
					cur = v
					k0 = k
					meglio = true
				else:
					scelta[h] = k0
		# mosse a coppie: due gruppi sullo stesso attacco
		for i in hexs.size():
			for j in range(i + 1, hexs.size()):
				var hi: String = hexs[i]
				var hj: String = hexs[j]
				var ki: String = scelta[hi]
				var kj: String = scelta[hj]
				for k in opz[hi]:
					if not opz[hj].has(k) or (k == ki and k == kj):
						continue
					scelta[hi] = k
					scelta[hj] = k
					var v := _val_scelta(scelta, gruppi, nemici, lato)
					if v > cur + 0.01:
						cur = v
						ki = k
						kj = k
						meglio = true
					else:
						scelta[hi] = ki
						scelta[hj] = kj
		if not meglio:
			break
	var attacchi := {}
	for h in hexs:
		var k: String = scelta[h]
		if not attacchi.has(k):
			attacchi[k] = []
		attacchi[k].append_array(gruppi[h])
	var out := []
	for k in attacchi:
		out.append({"dif": Array(k.split("+")), "att": attacchi[k]})
	return out

var _cache_val := {}

func _val_scelta(scelta: Dictionary, gruppi: Dictionary, nemici: Array, lato: int) -> float:
	var per := {}
	for h in scelta:
		var k: String = scelta[h]
		if not per.has(k):
			per[k] = []
		per[k].append_array(gruppi[h])
	var tot := 0.0
	var coperti := {}
	for k in per:
		for e in k.split("+"):
			if coperti.has(e):
				tot -= 1000.0     # lo stesso nemico attaccato due volte: non ammesso
			coperti[e] = true
		tot += _val_attacco(k, per[k], lato)
	for e in nemici:
		if not coperti.has(e):
			tot -= 1000.0
	return tot

## Saldo atteso in punti forza di un attacco (perdite nemiche meno le proprie, pesate)
func _val_attacco(k: String, ids: Array, lato: int) -> float:
	var ord := ids.duplicate()
	ord.sort()
	var ck := k + "|" + ",".join(ord)
	if _cache_val.has(ck):
		return _cache_val[ck]
	var va := m.valuta_attacco({"dif": Array(k.split("+")), "att": ids})
	var v := -500.0
	if va["ok"]:
		v = saldo_atteso(va, lato)
	_cache_val[ck] = v
	return v

## Punti forza amici oggi senza ritirata che l'avrebbero se gli esagoni nemici "via" fossero sgombri
func _sp_liberati(via: Array, lato: int) -> float:
	var tot := 0.0
	var visti := {}
	for e in via:
		for a in Mappa.vicini(e):
			for b in [a] + Mappa.vicini(a):
				if visti.has(b) or via.has(b) or m.lato_hex(b) != lato:
					continue
				visti[b] = true
				if not senza_ritirata(b, lato):
					continue
				# con il nemico respinto, b avrebbe un esagono libero?
				for x in Mappa.vicini(b):
					if via.has(x) or not Mappa.passabile(b, x) or m.nemico_in(x, lato):
						continue
					var z := false
					for y in Mappa.vicini(x):
						if not via.has(y) and m.lato_hex(y) == 1 - lato and not (Mappa.fiume(y, x) and not Mappa.ponte(y, x)):
							z = true
							break
					if not z and Mappa.terreno(x) != "castello":
						tot += m.sp_in(b, lato)
						break
	return tot

func saldo_atteso(va: Dictionary, lato: int) -> float:
	var col := int(va["col"])
	var att_sp := 0.0
	var att_chiusi := 0.0
	for id in va["adiac"]:
		var f := float(m.forza(id))
		att_sp += f
		if senza_ritirata(m.s["unita"][id]["h"], lato):
			att_chiusi += f
	var dif_sp := 0.0
	var dif_chiusi := 0.0
	for id in va["difensori"]:
		var f := float(m.forza(id))
		dif_sp += f
		if senza_ritirata(m.s["unita"][id]["h"], 1 - lato):
			dif_chiusi += f
	# chi difende preferisce conservare le truppe
	var peso := 1.0 if aggressivo(lato) else p_peso
	var res := resistere(lato)
	# liberazione: respingere il nemico riapre la via di ritirata a unità amiche accerchiate
	var liberati := _sp_liberati(va["dif_hex"], lato) * p_libera
	var obi := obiettivi(lato)
	for h in va["dif_hex"]:
		if h in obi:
			liberati += 3.0 * p_villaggi
	var v := 0.0
	for r in 6:
		match Dati.TRC[r][clampi(col, 0, 9)]:
			"DE": v += dif_sp + liberati
			"DR": v += dif_chiusi + 0.15 * dif_sp + liberati
			"EX": v += dif_sp - peso * minf(att_sp, dif_sp) + liberati
			"AR": v -= peso * (att_chiusi + (-0.3 if res else 0.15) * (att_sp - att_chiusi))
			"AE": v -= peso * att_sp
	return v / 6.0

## Assegnazione classica degli attacchi obbligatori (bersaglio con meno pretendenti, poi miglioramento
## sul valore atteso per colonna): a Wavre produce più sganciamenti utili all'uscita dei Prussiani
func _assegna_classica(gruppi: Dictionary, bersagli_di: Dictionary, nemici: Array, lato: int) -> Array:
	var attaccanti_di := {}
	for e in nemici:
		attaccanti_di[e] = []
		for h in gruppi:
			if e in bersagli_di[h]:
				attaccanti_di[e].append(h)
	# assegnazione: ogni gruppo al bersaglio con meno pretendenti
	var assegnato := {}
	for h in gruppi:
		var b: Array = bersagli_di[h]
		if b.is_empty():
			continue
		b.sort_custom(func(x, y): return attaccanti_di[x].size() < attaccanti_di[y].size())
		assegnato[h] = b[0]
	# ogni bersaglio deve avere almeno un attaccante
	for e in nemici:
		var ha := false
		for h in assegnato:
			if assegnato[h] == e:
				ha = true
		if ha:
			continue
		for h in attaccanti_di[e]:
			var altro: String = assegnato.get(h, "")
			var conta := 0
			for x in assegnato:
				if assegnato[x] == altro:
					conta += 1
			if conta > 1:
				assegnato[h] = e
				ha = true
				break
		if not ha and not attaccanti_di[e].is_empty():
			# attacco su due esagoni
			var h: String = attaccanti_di[e][0]
			assegnato[h] = assegnato.get(h, "") + "+" + e
	# miglioramento: sposta i gruppi fra i bersagli finché cresce il valore atteso totale
	# (attacchi diversivi deboli dove serve, il grosso dove si ottiene un buon rapporto)
	for _giro in 4:
		var migliorato := false
		for h in assegnato.keys():
			if String(assegnato[h]).begins_with("+") or String(assegnato[h]).contains("+"):
				continue
			var b: Array = bersagli_di[h]
			if b.size() < 2:
				continue
			var att0: String = assegnato[h]
			var resto := 0
			for x in assegnato:
				if assegnato[x] == att0 and x != h:
					resto += 1
			if resto == 0:
				continue
			var base := _valore_classico(assegnato, gruppi, lato)
			for e in b:
				if e == att0:
					continue
				assegnato[h] = e
				var nv := _valore_classico(assegnato, gruppi, lato)
				if nv > base + 0.05:
					base = nv
					att0 = e
					migliorato = true
				else:
					assegnato[h] = att0
		if not migliorato:
			break
	# compone gli attacchi
	var attacchi := {}
	for h in assegnato:
		var k: String = assegnato[h]
		if k.begins_with("+"):
			k = k.substr(1)
		if not attacchi.has(k):
			attacchi[k] = []
		attacchi[k].append_array(gruppi[h])
	var lista := []
	for k in attacchi:
		lista.append({"dif": Array(k.split("+")), "att": attacchi[k]})
	return lista

func _valore_classico(assegnato: Dictionary, gruppi: Dictionary, lato: int) -> float:
	var per := {}
	for h in assegnato:
		var k: String = assegnato[h]
		if not per.has(k):
			per[k] = 0.0
		for id in gruppi[h]:
			per[k] += m.forza_att(id)
	var tot := 0.0
	for k in per:
		var dif := 0.0
		for e in k.split("+"):
			if e != "":
				dif += _difesa_hex(e, 1 - lato)
		var col := Dati.colonna(per[k], dif)
		var v := valore_colonna(col)
		for e in k.split("+"):
			if e != "" and senza_ritirata(e, 1 - lato):
				v += 0.4 * col / 9.0
		tot += v
	return tot

func _avanza(rq: Dictionary) -> Dictionary:
	var lato := int(rq["lato"])
	var best := []
	var bv := -INF
	for c in rq["cand"]:
		var id: String = c[0]
		var h: String = c[1]
		var h0: String = m.s["unita"][id]["h"]
		var v := _valore_terreno(h, m.tipo(id)) - _valore_terreno(h0, m.tipo(id))
		if aggressivo(lato):
			v += 1.5
		if Mappa.terreno(h0) in ["citta", "castello"] and not aggressivo(lato):
			v -= 3.0
		if h in obiettivi(lato):
			v += 4.0 * p_villaggi
		if h0 in obiettivi(lato):
			v -= 4.0 * p_villaggi
		# la zona di controllo di un'unità debole taglia la ritirata come quella di una forte
		if p_accerchia > 0.0:
			v -= float(m.forza(id)) * 0.08 * p_accerchia
		# accerchiamento: occupando h si chiude l'ultima via di ritirata a un nemico non ancora attaccato
		if p_accerchia > 0.0:
			for e in Mappa.vicini(h):
				var nem_e := m.unita_in(e, 1 - lato)
				if nem_e.is_empty() or m.s["unita"][nem_e[0]]["dif"]:
					continue
				if not senza_ritirata(e, 1 - lato) and _chiuso_con(e, 1 - lato, h):
					var sp := 0.0
					for x in nem_e:
						sp += m.forza(x)
					v += (2.0 + sp * 0.5) * p_accerchia
		if v > bv:
			bv = v
			best = c
	if (bv > 0 or rq.get("obbligata", false)) and not best.is_empty():
		return {"a": "avanza", "u": best[0], "h": best[1]}
	return {"a": "avanza", "u": ""}
