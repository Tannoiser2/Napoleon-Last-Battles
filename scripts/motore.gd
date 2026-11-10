## Il motore delle regole di Napoleon's Last Battles: i quattro Folio (Ligny, Quatre Bras, Wavre,
## La Belle Alliance) e la campagna con comando, riorganizzazione, demoralizzazione dei corpi e rifornimento.
## Tutto lo stato sta nel dizionario `s` (salvabile in JSON); i dadi sono deterministici, così due copie
## del gioco che ricevono le stesse decisioni restano identiche (partite online).
class_name Motore
extends RefCounted

static var catalogo := {}
static var scenari := {}

var causa := ""
var diagnosi := false
var ultimo_mov := {}
var stat := {}
var s := {}
var scen := {}
var eventi: Array = []
var _zoc_cache := {}
var _occ := {}            # esagono -> [id unità] (solo unità sulla mappa)
var _capi_hex := {}

const FR := 0
const AL := 1

static func carica_catalogo() -> void:
	if not catalogo.is_empty():
		return
	catalogo = JSON.parse_string(FileAccess.open("res://assets/dati/catalogo.json", FileAccess.READ).get_as_text())
	scenari = JSON.parse_string(FileAccess.open("res://assets/dati/scenari.json", FileAccess.READ).get_as_text())

# =============================================================================================
# Avvio

func nuova(cfg: Dictionary) -> void:
	carica_catalogo()
	Mappa.carica()
	var k: String = cfg.get("scen", "bellealliance")
	scen = scenari[k]
	s = {
		"scen": k, "seed": int(cfg.get("seed", 1)), "rng": int(cfg.get("seed", 1)) * 7919 + 17,
		"turno": 0, "lato": FR, "fase": "movimento", "azioni": 0,
		"unita": {}, "capi": {}, "log": [], "esito": {}, "pendente": {},
		"perdite": {"FR": 0, "PR": 0, "AA": 0}, "perdite_corpo": {}, "pv": [0, 0],
		"occup": {}, "dem": {}, "dis": {}, "mod": {}, "uscite": {"FR": 0, "PR": 0}, "pv_uscita": 0,
		"entrate": {}, "comando": {}, "contatto_pr": false, "guardia": 0, "opzionali": bool(cfg.get("opzionali", false)),
		"opzioni": {"armi_combinate": bool(cfg.get("armi_combinate", true)), "guardia": bool(cfg.get("guardia", true))},
		"ultima_battaglia": {},
	}
	for e in scen["unita"]:
		if e.has("opz") and not s["opzionali"]:
			_crea_unita(e["u"], "", "arrivo", -1)
			continue
		_crea_unita(e["u"], e["h"], "mappa", 0)
		if e.has("rid"):
			s["unita"][e["u"]]["rid"] = true
	for r in scen["rinforzi"]:
		var id: String = r["u"]
		if r.has("opz") and not s["opzionali"]:
			continue
		if id.begins_with("c"):
			s["capi"][id] = {"h": "", "st": "arrivo", "t": int(r["t"]), "e": r["e"]}
		else:
			_crea_unita(id, "", "arrivo", int(r["t"]))
			s["unita"][id]["e"] = r["e"]
	# le unità opzionali non scelte restano fuori dal gioco
	for id in s["unita"].keys():
		if s["unita"][id]["st"] == "arrivo" and int(s["unita"][id]["t"]) < 0:
			s["unita"].erase(id)
	if campagna():
		for c in scen["capi"]:
			s["capi"][c["c"]] = {"h": c["h"], "st": "mappa"}
	_ricalcola()
	_log("[b]%s[/b] — %s, %s." % [scen["titolo"], scen["sotto"], scen["data"]])
	_inizio_turno_giocatore()

func _crea_unita(id: String, h: String, st: String, t: int) -> void:
	s["unita"][id] = {"h": h, "st": st, "t": t, "rid": false, "mosso": false, "att": false, "dif": false, "avz": false}

func importa(d: Dictionary) -> void:
	carica_catalogo()
	Mappa.carica()
	s = d
	scen = scenari[s["scen"]]
	_ricalcola()

func campagna() -> bool:
	return s["scen"] == "campagna"

func finita() -> bool:
	return not s["esito"].is_empty()

# =============================================================================================
# Dadi

func dado() -> int:
	var x: int = int(s["rng"])
	x = (x * 1103515245 + 12345) % 2147483648
	s["rng"] = x
	return int((x >> 8) % 6) + 1

# =============================================================================================
# Accesso ai dati

func cat(id: String) -> Dictionary:
	return catalogo["unita"][id] if id.begins_with("u") else catalogo["capi"][id]

func esercito(id: String) -> String:
	return cat(id)["es"]

func lato_di(id: String) -> int:
	return FR if esercito(id) == "FR" else AL

func tipo(id: String) -> String:
	return cat(id)["t"]

func forza(id: String) -> int:
	var c := cat(id)
	return int(c["r"]) if s["unita"][id]["rid"] else int(c["f"])

func ma(id: String) -> int:
	return int(cat(id)["ma"])

## Corpo (francesi e prussiani) o nazione (anglo-alleati) per la demoralizzazione
func gruppo_dem(id: String) -> String:
	var c := cat(id)
	if c["es"] == "AA":
		return "AA:" + c["naz"]
	return c["es"] + ":" + c["c"]

func nome(id: String) -> String:
	return cat(id)["n"]

func sulla_mappa(id: String) -> bool:
	if id.begins_with("c"):
		return s["capi"][id]["st"] == "mappa"
	return s["unita"][id]["st"] == "mappa"

func turno_label() -> String:
	return scen["turni"][mini(int(s["turno"]), scen["turni"].size() - 1)]

func notte() -> bool:
	return turno_label().begins_with("N")

func pioggia() -> bool:
	return turno_label().begins_with("R")

func senza_combattimento() -> bool:
	return notte() or pioggia()

func ora() -> String:
	var t := turno_label()
	if t[0] in ["N", "R"]:
		t = t.substr(1)
	return t.substr(0, 2) + ":" + t.substr(2, 2)

func giorno() -> int:
	if scen.has("giorni"):
		return int(scen["giorni"][mini(int(s["turno"]), scen["giorni"].size() - 1)])
	return int(scen["giorno"])

# ---------- occupazione

func _ricalcola() -> void:
	_occ.clear()
	_capi_hex.clear()
	_zoc_cache.clear()
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] == "mappa":
			if not _occ.has(u["h"]):
				_occ[u["h"]] = []
			_occ[u["h"]].append(id)
	for id in s["capi"]:
		var c: Dictionary = s["capi"][id]
		if c["st"] == "mappa" and c["h"] != "":
			if not _capi_hex.has(c["h"]):
				_capi_hex[c["h"]] = []
			_capi_hex[c["h"]].append(id)

func unita_in(h: String, lato := -1) -> Array:
	var out := []
	for id in _occ.get(h, []):
		if lato < 0 or lato_di(id) == lato:
			out.append(id)
	return out

func capi_in(h: String, lato := -1) -> Array:
	var out := []
	for id in _capi_hex.get(h, []):
		if lato < 0 or lato_di(id) == lato:
			out.append(id)
	return out

func lato_hex(h: String) -> int:
	var l: Array = _occ.get(h, [])
	return lato_di(l[0]) if not l.is_empty() else -1

func nemico_in(h: String, lato: int) -> bool:
	var l := lato_hex(h)
	return l >= 0 and l != lato

## Esagono controllato (ZOC) dal lato `lato_zoc`
func zoc(h: String, lato_zoc: int) -> bool:
	var k := "%s|%d" % [h, lato_zoc]
	if _zoc_cache.has(k):
		return _zoc_cache[k]
	var r := false
	if Mappa.terreno(h) != "castello":
		for v in Mappa.vicini(h):
			if lato_hex(v) == lato_zoc and not (Mappa.fiume(v, h) and not Mappa.ponte(v, h)):
				r = true
				break
	_zoc_cache[k] = r
	return r

func in_ezoc(id: String) -> bool:
	var u: Dictionary = s["unita"][id]
	return u["st"] == "mappa" and zoc(u["h"], 1 - lato_di(id))

func sp_in(h: String, lato := -1) -> int:
	var t := 0
	for id in unita_in(h, lato):
		t += forza(id)
	return t

# =============================================================================================
# Demoralizzazione

func dem_unita(id: String) -> bool:
	if campagna():
		return bool(s["dem"].get(gruppo_dem(id), false))
	return bool(s["dem"].get(esercito(id), false))

## Livelli dei Folio, con i modificatori
func livello_folio(es: String, dis := false) -> int:
	var k: String = s["scen"]
	var tl := turno_label()
	var v := 999
	match k:
		"ligny":
			if es == "PR":
				v = 74 if dis else 55
				var occ := 0
				for h in ["3755", "3854", "3855", "3955", "3256", "3357", "3457"]:
					if int(s["occup"].get(h, -1)) == FR:
						occ += 3
				v -= occ
			elif es == "FR" and not dis:
				v = 55
		"quatrebras":
			if es == "FR" and not dis:
				v = 10 if tl in ["1400", "1500"] else 25
			elif es == "AA":
				v = 40 if dis else 25
		"wavre":
			if es == "FR" and not dis:
				v = 30 + int(s["pv"][FR])
			elif es == "PR":
				v = 50 if dis else 40
		"bellealliance":
			if es == "FR" and not dis:
				v = 60 + 10 * int(s["mod"].get("fr_bonus", 0))
			elif es == "AA":
				v = (55 if dis else 45) + (10 if s["contatto_pr"] else 0) - (20 if s["mod"].get("waterloo", false) else 0)
			elif es == "PR":
				v = 35 if dis else 25
	if es == "FR" and not dis:
		v -= int(s["guardia"])
	return v

func livello_corpo(g: String) -> int:
	var p := g.split(":")
	if p[0] == "AA":
		return int(Dati.DEM_NAZIONI.get(p[1], 99))
	var base: int = int(Dati.DEM_CORPI.get(p[0], {}).get(p[1], 99))
	return base - int(s["mod"].get("lv:" + g, 0))

func perdite_corpo(g: String) -> int:
	if g.begins_with("AA:"):
		return int(s["perdite_corpo"].get("AA", 0))
	return int(s["perdite_corpo"].get(g, 0))

func _controlla_demoralizzazione() -> void:
	if campagna():
		var gruppi := {}
		for id in s["unita"]:
			gruppi[gruppo_dem(id)] = true
		for g in gruppi:
			var d := perdite_corpo(g) >= livello_corpo(g)
			if d != bool(s["dem"].get(g, false)):
				s["dem"][g] = d
				_annuncio("%s %s" % [_nome_gruppo(g), "è demoralizzato" if d else "si è ripreso dalla demoralizzazione"])
		return
	for es in ["FR", "PR", "AA"]:
		var lv := livello_folio(es)
		if lv >= 999:
			continue
		if not s["dem"].get(es, false) and int(s["perdite"][es]) >= lv:
			s["dem"][es] = true
			_annuncio("%s è demoralizzato (%d punti di perdite)" % [Dati.ESERCITI[es], int(s["perdite"][es])])
			if s["scen"] == "bellealliance" and es != "FR":
				s["mod"]["fr_bonus"] = int(s["mod"].get("fr_bonus", 0)) + 1
		var ld := livello_folio(es, true)
		if ld < 999 and not s["dis"].get(es, false) and int(s["perdite"][es]) >= ld:
			s["dis"][es] = true
			_annuncio("%s si è disintegrato" % Dati.ESERCITI[es])

func _nome_gruppo(g: String) -> String:
	var p := g.split(":")
	if p[0] == "AA":
		return "Il contingente " + {"BR": "britannico", "KGL": "della Legione tedesca", "HAN": "hannoveriano", "BRU": "di Brunswick", "NAS": "di Nassau", "NL": "olandese-belga"}.get(p[1], p[1])
	return "Il %s %s" % [Dati.NOMI_CORPI.get(p[1], p[1] + " corpo"), "francese" if p[0] == "FR" else "prussiano"]

# =============================================================================================
# Sequenza di gioco

func richiesta() -> Dictionary:
	if finita():
		return {}
	if not s["pendente"].is_empty():
		return s["pendente"]
	return {"k": s["fase"], "lato": int(s["lato"])}

func _inizio_turno_giocatore() -> void:
	# inizio del turno di un lato: rifornimento, comando, riorganizzazione, rinforzi disponibili
	s["fase"] = "movimento"
	s["entrate"] = {}
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		u["mosso"] = false
		u["att"] = false
		u["dif"] = false
		u["avz"] = false
	for id in s["capi"]:
		s["capi"][id]["mosso"] = false
	if campagna():
		if int(s["lato"]) == FR and turno_label() in ["0900", "R0900"] and giorno() > 16:
			_rifornimento()
		if not notte():
			_riorganizza(int(s["lato"]))
		_calcola_comando(int(s["lato"]))
		_controlla_demoralizzazione()
	var arrivi := 0
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] == "arrivo" and int(u["t"]) <= int(s["turno"]) and lato_di(id) == int(s["lato"]):
			arrivi += 1
	for id in s["capi"]:
		var c: Dictionary = s["capi"][id]
		if c["st"] == "arrivo" and int(c.get("t", 0)) <= int(s["turno"]) and lato_di(id) == int(s["lato"]):
			# i capi arrivano direttamente sull'esagono d'ingresso
			c["st"] = "mappa"
			c["h"] = str(c["e"]).split("|")[0]
	_ricalcola()
	if arrivi > 0:
		_log("%s: %d rinforzi possono entrare." % [Dati.LATI[s["lato"]], arrivi])

func _fine_movimento() -> bool:
	# controllo dell'impilamento
	for h in _occ:
		var n: int = _occ[h].size()
		if n > (1 if Mappa.terreno(h) == "castello" else 2):
			return false
	if senza_combattimento():
		_fine_turno_giocatore()
	else:
		s["fase"] = "combattimento"
		s["batt"] = []
	return true

func ammassati() -> Array:
	var out := []
	for h in _occ:
		if _occ[h].size() > (1 if Mappa.terreno(h) == "castello" else 2):
			out.append(h)
	return out

func _fine_turno_giocatore() -> void:
	if int(s["lato"]) == FR:
		s["lato"] = AL
		_inizio_turno_giocatore()
		return
	_fine_turno()

func _fine_turno() -> void:
	# punti a fine turno e avanzamento del segnalino
	if s["scen"] == "quatrebras" and int(s["occup"].get("1641", -1)) >= 0:
		var l := int(s["occup"]["1641"])
		s["pv"][l] = int(s["pv"][l]) + 1
	_controlla_vittoria(false)
	if finita():
		return
	s["turno"] = int(s["turno"]) + 1
	if int(s["turno"]) >= scen["turni"].size():
		_controlla_vittoria(true)
		return
	s["lato"] = FR
	_log("[b]%s — %d giugno, ore %s%s[/b]" % ["Turno %d" % (int(s["turno"]) + 1), giorno(), ora(), "  (notte)" if notte() else ("  (pioggia)" if pioggia() else "")])
	_inizio_turno_giocatore()

# =============================================================================================
# Applicazione delle decisioni

func applica(d: Dictionary) -> bool:
	eventi = []
	if finita():
		return false
	var rq := richiesta()
	var ok := false
	match d.get("a", ""):
		"muovi":
			ok = rq["k"] == "movimento" and _muovi(d)
		"entra":
			ok = rq["k"] == "movimento" and _entra(d)
		"esci":
			ok = rq["k"] == "movimento" and _esci(d)
		"capo":
			ok = rq["k"] == "movimento" and _muovi_capo(d)
		"attacco":
			ok = rq["k"] == "combattimento" and _attacco(d)
		"avanza":
			ok = rq["k"] == "avanza" and _avanza(d)
		"fine":
			if rq["k"] == "movimento":
				ok = _fine_movimento()
			elif rq["k"] == "combattimento":
				_combattimenti_obbligati()
				if s["pendente"].is_empty() and not finita():
					_fine_turno_giocatore()
				ok = true
			elif rq["k"] == "avanza":
				ok = _avanza({"u": ""})
	if ok:
		s["azioni"] = int(s["azioni"]) + 1
		_ricalcola()
		_controlla_demoralizzazione()
		_controlla_vittoria(false)
	return ok

# ---------- movimento

## Costo per passare da a a b per l'unità (o capo, che muove come cavalleria)
func costo_passo(a: String, b: String, tp: String, dem: bool) -> float:
	if not Mappa.passabile(a, b):
		return INF
	if Mappa.strada(a, b):
		return 0.5
	var c := Dati.costo_terreno(Mappa.terreno(b), tp, dem)
	if Mappa.sentiero(a, b):
		c = minf(c, 1.0)
	elif Mappa.ruscello(a, b):
		c += 2.0
	return c

## Esagoni raggiungibili: {esagono: {"c": costo, "da": precedente}}
func raggiungibili(id: String, partenza := "", costo0 := 0.0) -> Dictionary:
	var lato := lato_di(id)
	var leader := id.begins_with("c")
	var h0: String = partenza
	if h0 == "":
		h0 = s["capi"][id]["h"] if leader else s["unita"][id]["h"]
	var tp := "C" if leader else tipo(id)
	var dem := (not leader) and campagna() and dem_unita(id)
	var mpa: float = float(10 if leader and int(cat(id)["cap"]) > 0 else (6 if leader else ma(id)))
	if leader and campagna() and s["capi"][id].get("dem", false):
		dem = true
	var ooc := (not leader) and campagna() and not in_comando(id)
	var out := {h0: {"c": costo0, "da": ""}}
	if not leader and partenza == "" and zoc(h0, 1 - lato):
		return out
	var coda := [h0]
	while not coda.is_empty():
		# estrae il più economico
		var bi := 0
		for i in coda.size():
			if out[coda[i]]["c"] < out[coda[bi]]["c"]:
				bi = i
		var h: String = coda[bi]
		coda.remove_at(bi)
		var c0: float = out[h]["c"]
		# chi entra in un esagono controllato dal nemico si ferma
		if h != h0 and not leader and zoc(h, 1 - lato):
			continue
		if h == h0 and not leader and costo0 > 0 and zoc(h, 1 - lato):
			continue
		for v in Mappa.vicini(h):
			if nemico_in(v, lato):
				continue
			if leader:
				if not capi_in(v, 1 - lato).is_empty():
					continue
				if zoc(v, 1 - lato) and unita_in(v, lato).is_empty():
					continue
			else:
				if zoc(v, 1 - lato) and (senza_combattimento() or ooc):
					continue
			var c := c0 + costo_passo(h, v, tp, dem)
			if c > mpa + 0.001:
				continue
			if not out.has(v) or c < out[v]["c"] - 0.001:
				out[v] = {"c": c, "da": h}
				if not coda.has(v):
					coda.append(v)
	return out

func percorso(rg: Dictionary, h: String) -> Array:
	var out := []
	var x := h
	while x != "" and rg.has(x):
		out.push_front(x)
		x = rg[x]["da"]
	return out

func puo_muovere(id: String) -> bool:
	var u: Dictionary = s["unita"][id]
	return u["st"] == "mappa" and not u["mosso"] and lato_di(id) == int(s["lato"]) and not in_ezoc(id)

func _muovi(d: Dictionary) -> bool:
	var id: String = d.get("u", "")
	if not s["unita"].has(id) or not puo_muovere(id):
		return false
	var h: String = d.get("h", "")
	var rg := raggiungibili(id)
	if not rg.has(h) or h == s["unita"][id]["h"]:
		return false
	var da: String = s["unita"][id]["h"]
	ultimo_mov[id] = int(s["turno"])
	s["unita"][id]["h"] = h
	s["unita"][id]["mosso"] = true
	for x in percorso(rg, h):
		_occupa(x, int(s["lato"]))
	_sposta_capi_nemici(h)
	_ricalcola()
	eventi.append({"k": "mossa", "u": id, "da": da, "a": h, "p": percorso(rg, h)})
	return true

func ingressi(id: String) -> Array:
	var out := []
	for e in str(s["unita"][id].get("e", "")).split("|"):
		if e != "" and Mappa.esiste(e) and not nemico_in(e, lato_di(id)):
			out.append(e)
	return out

func arrivi_disponibili(lato: int) -> Array:
	var out := []
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] == "arrivo" and int(u["t"]) >= 0 and int(u["t"]) <= int(s["turno"]) and lato_di(id) == lato:
			out.append(id)
	return out

## Raggiungibili per un rinforzo: entra pagando il terreno dell'esagono d'ingresso più la coda
func raggiungibili_arrivo(id: String) -> Dictionary:
	var tot := {}
	for e in ingressi(id):
		var coda: float = float(int(s["entrate"].get(e, 0)) / 2)
		var c0 := Dati.costo_terreno(Mappa.terreno(e), tipo(id), false) + coda
		if c0 > ma(id):
			continue
		var rg := raggiungibili(id, e, c0)
		for h in rg:
			if not tot.has(h) or rg[h]["c"] < tot[h]["c"]:
				tot[h] = rg[h]
				tot[h]["ing"] = e
	return tot

func _entra(d: Dictionary) -> bool:
	var id: String = d.get("u", "")
	if not s["unita"].has(id) or not (id in arrivi_disponibili(int(s["lato"]))):
		return false
	var rg := raggiungibili_arrivo(id)
	var h: String = d.get("h", "")
	if not rg.has(h):
		return false
	var e: String = rg[h]["ing"]
	s["entrate"][e] = int(s["entrate"].get(e, 0)) + 1
	s["unita"][id]["st"] = "mappa"
	s["unita"][id]["h"] = h
	s["unita"][id]["mosso"] = true
	_occupa(h, int(s["lato"]))
	_ricalcola()
	_log("%s entra in gioco (%s)." % [nome(id), Mappa.sigla(h)])
	eventi.append({"k": "mossa", "u": id, "da": e, "a": h, "p": [e, h]})
	return true

## Uscite valide: Wavre (bordo ovest, righe 1-17) e campagna (B0605 verso Bruxelles, solo francesi)
func uscita_valida(id: String, h: String) -> bool:
	var lato := lato_di(id)
	match s["scen"]:
		"wavre":
			return Mappa.col(h) == 29 and Mappa.riga(h) <= 17
		"campagna":
			return lato == FR and h == "0605"
	return false

func _esci(d: Dictionary) -> bool:
	var id: String = d.get("u", "")
	if not s["unita"].has(id):
		return false
	var u: Dictionary = s["unita"][id]
	var lato := lato_di(id)
	if lato != int(s["lato"]) or u["st"] != "mappa" or u["mosso"]:
		return false
	var h: String = d.get("h", u["h"])
	var rg := raggiungibili(id)
	if not rg.has(h) or not uscita_valida(id, h):
		return false
	if rg[h]["c"] + Dati.costo_terreno(Mappa.terreno(h), tipo(id)) > ma(id) + 0.001:
		return false
	if zoc(h, 1 - lato):
		return false
	u["st"] = "uscita"
	u["mosso"] = true
	var sp := forza(id)
	match s["scen"]:
		"wavre":
			if lato == FR:
				s["pv"][FR] = int(s["pv"][FR]) + 5 * sp
			elif int(s["turno"]) <= 3:
				s["pv"][AL] = int(s["pv"][AL]) + sp
		"campagna":
			s["uscite"]["FR"] = int(s["uscite"]["FR"]) + sp
	_log("%s esce dalla mappa (%d PF)." % [nome(id), sp])
	_ricalcola()
	return true

func _occupa(h: String, lato: int) -> void:
	s["occup"][h] = lato
	if s["scen"] == "bellealliance" and lato == FR and h in ["0607", "0708", "0709"]:
		if not s["mod"].get("waterloo", false):
			s["mod"]["waterloo"] = true
			_annuncio("I Francesi entrano a Waterloo: i livelli anglo-alleati scendono di 20")

## Capi nemici soli in un esagono: spostati sulla più vicina unità amica
func _sposta_capi_nemici(h: String) -> void:
	_ricalcola()
	var l := lato_hex(h)
	for c in capi_in(h):
		if lato_di(c) != l:
			_ricolloca_capo(c)

func _ricolloca_capo(c: String) -> void:
	var l := lato_di(c)
	var h0: String = s["capi"][c]["h"]
	var best := ""
	var bd := 999
	for id in s["unita"]:
		if lato_di(id) == l and s["unita"][id]["st"] == "mappa":
			var d := Mappa.distanza(h0, s["unita"][id]["h"])
			if d < bd:
				bd = d
				best = s["unita"][id]["h"]
	if best == "":
		s["capi"][c]["st"] = "elim"
	else:
		s["capi"][c]["h"] = best

func _muovi_capo(d: Dictionary) -> bool:
	var c: String = d.get("c", "")
	if not s["capi"].has(c) or lato_di(c) != int(s["lato"]) or s["capi"][c]["st"] != "mappa" or s["capi"][c].get("mosso", false):
		return false
	var rg := raggiungibili(c)
	var h: String = d.get("h", "")
	if not rg.has(h) or h == s["capi"][c]["h"]:
		return false
	s["capi"][c]["h"] = h
	s["capi"][c]["mosso"] = true
	_ricalcola()
	return true

# =============================================================================================
# Comando (campagna)

func in_comando(id: String) -> bool:
	if not campagna():
		return true
	if notte():
		return false
	return bool(s["comando"].get(id, false))

## Distanza di comando: passi che non attraversano nemici né esagoni controllati senza amici
func _raggio_comando(h0: String, lato: int, raggio: int) -> Dictionary:
	var out := {h0: 0}
	var coda := [h0]
	while not coda.is_empty():
		var h: String = coda.pop_front()
		if out[h] >= raggio:
			continue
		for v in Mappa.vicini(h):
			if out.has(v) or not Mappa.passabile(h, v) or nemico_in(v, lato):
				continue
			if zoc(v, 1 - lato) and unita_in(v, lato).is_empty():
				# si può arrivare a un'unità in quell'esagono ma non oltre
				out[v] = raggio
				continue
			out[v] = out[h] + 1
			coda.append(v)
	return out

func _calcola_comando(lato: int) -> void:
	s["comando"] = {}
	if notte():
		return
	var es_l := ["FR"] if lato == FR else ["PR", "AA"]
	var riorg: Dictionary = s.get("riorg_capi", {})
	for es in es_l:
		var comandanti := []
		var ufficiali := {}
		for c in s["capi"]:
			if s["capi"][c]["st"] != "mappa" or catalogo["capi"][c]["es"] != es:
				continue
			if int(catalogo["capi"][c]["cap"]) > 0:
				comandanti.append(c)
			elif not riorg.has(c):
				ufficiali[catalogo["capi"][c]["des"]] = c
		var unita := []
		for id in s["unita"]:
			if s["unita"][id]["st"] == "mappa" and esercito(id) == es:
				unita.append(id)
		var ufficiali_ok := {}
		var diretti := {}
		comandanti.sort_custom(func(a, b): return int(catalogo["capi"][a]["cap"]) > int(catalogo["capi"][b]["cap"]))
		for cm in comandanti:
			var cap := int(catalogo["capi"][cm]["cap"])
			var rg := _raggio_comando(s["capi"][cm]["h"], lato, 5)
			# ufficiali più vicini
			var cand := []
			for des in ufficiali:
				var o: String = ufficiali[des]
				if not ufficiali_ok.has(des) and rg.has(s["capi"][o]["h"]):
					cand.append([rg[s["capi"][o]["h"]], des])
			cand.sort()
			var n := 0
			for x in cand:
				if n >= cap:
					break
				ufficiali_ok[x[1]] = true
				n += 1
			# unità comandate direttamente: prima quelle a contatto col nemico
			var dir := []
			for id in unita:
				if rg.has(s["unita"][id]["h"]) and not diretti.has(id):
					dir.append([0 if in_ezoc(id) else 1, rg[s["unita"][id]["h"]], id])
			dir.sort()
			var k := 0
			for x in dir:
				if k >= cap:
					break
				diretti[x[2]] = true
				k += 1
		for des in ufficiali_ok:
			s["comando"][ufficiali[des]] = true
			var rg3 := _raggio_comando(s["capi"][ufficiali[des]]["h"], lato, 3)
			for id in unita:
				if str(cat(id)["des"]).split("/")[-1] == des or cat(id)["c"] == des:
					if rg3.has(s["unita"][id]["h"]):
						s["comando"][id] = true
		for id in diretti:
			s["comando"][id] = true
	# chi difende fuori comando nel turno avversario
	var od: Dictionary = s.get("ooc_dif", {})
	for id in od.keys():
		if lato_di(id) == lato:
			od.erase(id)
	for id in s["unita"]:
		if lato_di(id) == lato and s["unita"][id]["st"] == "mappa" and not s["comando"].get(id, false):
			od[id] = true
	s["ooc_dif"] = od

# =============================================================================================
# Riorganizzazione e rifornimento (campagna)

func ufficiale_di(id: String) -> String:
	var des: String = cat(id)["c"] if esercito(id) != "AA" else cat(id)["des"]
	for c in s["capi"]:
		if catalogo["capi"][c]["es"] == esercito(id) and catalogo["capi"][c]["des"] == des and int(catalogo["capi"][c]["cap"]) == 0:
			return c
	return ""

func _riorganizza(lato: int) -> void:
	s["riorg_capi"] = {}
	var per_uff := {}
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] != "riorg" or lato_di(id) != lato or int(u.get("dal", 99999)) >= int(s["turno"]):
			continue
		var o := ufficiale_di(id)
		if o == "" or s["capi"][o]["st"] != "mappa":
			continue
		var h: String = s["capi"][o]["h"]
		var vicino := false
		for x in s["unita"]:
			if lato_di(x) != lato and s["unita"][x]["st"] == "mappa" and Mappa.distanza(h, s["unita"][x]["h"]) <= 10:
				vicino = true
				break
		if vicino:
			continue
		if not per_uff.has(o):
			per_uff[o] = []
		per_uff[o].append(id)
	for o in per_uff:
		var h: String = s["capi"][o]["h"]
		s["riorg_capi"][o] = true
		var g := gruppo_dem(per_uff[o][0])
		if bool(s["dem"].get(g, false)) and dado() >= 5:
			for id in per_uff[o]:
				s["unita"][id]["st"] = "distrutta"
			_log("%s: la riorganizzazione fallisce, le unità sono perse." % nome(o))
			continue
		var n := 0
		for id in per_uff[o]:
			if unita_in(h).size() + n >= 2:
				break
			s["unita"][id]["st"] = "mappa"
			s["unita"][id]["h"] = h
			s["unita"][id]["rid"] = true
			n += 1
			_togli_perdita(id)
			_log("%s riorganizza %s (forza ridotta)." % [nome(o), nome(id)])
		_ricalcola()

func _togli_perdita(id: String) -> void:
	var g := gruppo_dem(id)
	var k := "AA" if g.begins_with("AA:") else g
	s["perdite_corpo"][k] = maxi(0, int(s["perdite_corpo"].get(k, 0)) - int(cat(id)["f"]))

func bordo(h: String) -> String:
	# quale bordo della mappa tocca l'esagono (n, s, e, o) — "" se interno
	var c := Mappa.col(h)
	var r := Mappa.riga(h)
	var tutti := Mappa._intorno(h)
	var dir := ["n", "e", "e", "s", "o", "o"]
	var b := ""
	for i in 6:
		if not Mappa.esiste(tutti[i]):
			if dir[i] == "s" or (dir[i] in ["e", "o"] and b == ""):
				b = dir[i]
			elif dir[i] == "n" and b == "":
				b = "n"
	if c <= 1:
		b = "o"
	elif c >= 57:
		b = "e"
	elif r <= 1:
		b = "n"
	return b

func _fonte_rifornimento(es: String, h: String) -> bool:
	var b := bordo(h)
	match es:
		"FR":
			return b == "s"
		"PR":
			return b == "e"
		"AA":
			return b == "n" or b == "o"
	return false

static var _strade := {}

## Esagono attraversato da una strada o da un sentiero (la digitalizzazione dei tracciati non è perfetta:
## la rete di rifornimento collega gli esagoni stradali adiacenti)
func _ha_strada(h: String) -> bool:
	if _strade.is_empty():
		for k in Mappa.lati:
			var v: String = Mappa.lati[k]
			if v.contains("r") or v.contains("s"):
				var p := String(k).split("-")
				_strade[p[0]] = true
				_strade[p[1]] = true
	return _strade.has(h)

func _rifornimento() -> void:
	for es in ["FR", "PR", "AA"]:
		var lato := FR if es == "FR" else AL
		# rete stradale collegata a un bordo valido
		var rete := {}
		var coda := []
		for h in Mappa.esagoni:
			if _fonte_rifornimento(es, h) and not nemico_in(h, lato):
				rete[h] = true
				coda.append(h)
		while not coda.is_empty():
			var h: String = coda.pop_back()
			for v in Mappa.vicini(h):
				if not rete.has(v) and _ha_strada(v) and Mappa.passabile(h, v) and not nemico_in(v, lato):
					rete[v] = true
					coda.append(v)
		for id in s["unita"]:
			if esercito(id) != es or s["unita"][id]["st"] != "mappa":
				continue
			var ok := false
			var vis := {s["unita"][id]["h"]: 0}
			var q := [s["unita"][id]["h"]]
			while not q.is_empty() and not ok:
				var h: String = q.pop_front()
				if rete.has(h):
					ok = true
					break
				if vis[h] >= 5:
					continue
				for v in Mappa.vicini(h):
					if not vis.has(v) and Mappa.passabile(h, v) and not nemico_in(v, lato):
						vis[v] = vis[h] + 1
						q.append(v)
			if not ok:
				_elimina(id, false)
				_log("%s è senza rifornimento ed è eliminato." % nome(id))
	_ricalcola()

# =============================================================================================
# Combattimento

func puo_bombardare(id: String, bersaglio: String) -> bool:
	var u: Dictionary = s["unita"][id]
	if not (tipo(id) in ["A", "HA"]) or u["st"] != "mappa" or in_ezoc(id):
		return false
	if Mappa.terreno(bersaglio) == "castello":
		return false
	var d := Mappa.distanza(u["h"], bersaglio)
	if d < 1 or d > 2:
		return false
	if d == 2:
		return linea_di_tiro(u["h"], bersaglio)
	return true

func _blocca(h: String) -> bool:
	return Mappa.terreno(h) in ["bosco", "citta", "castello"]

## Linea di tiro a distanza 2: esagono intermedio, oppure lato fra due esagoni
func linea_di_tiro(a: String, b: String) -> bool:
	var comuni := []
	for v in Mappa.vicini(a):
		if Mappa.adiacenti(v, b):
			comuni.append(v)
	if comuni.size() == 1:
		var m: String = comuni[0]
		return not _blocca(m) and not Mappa.cresta(a, m) and not Mappa.cresta(m, b)
	if comuni.size() == 2:
		var m1: String = comuni[0]
		var m2: String = comuni[1]
		if Mappa.cresta(m1, m2):
			return false
		if _blocca(m1) and _blocca(m2):
			return false
		return true
	return comuni.size() > 0

## Forza in attacco di un'unità (cavalleria dimezzata in bosco o palude)
func forza_att(id: String) -> float:
	var f := float(forza(id))
	var h: String = str(s["unita"][id].get("h", ""))
	if tipo(id) == "C" and Mappa.esagoni.has(h) and Mappa.terreno(h) in ["bosco", "palude"]:
		f = ceilf(f / 2.0)
	return f

## Calcolo di un attacco: {ok, motivo, att, dif, col, bomb, adiac, multi...}
func valuta_attacco(d: Dictionary) -> Dictionary:
	var lato := int(s["lato"])
	var dif_hex: Array = []
	for h in d.get("dif", []):
		if not dif_hex.has(h):
			dif_hex.append(h)
	var att_ids: Array = []
	for x in d.get("att", []):
		if not att_ids.has(x):
			att_ids.append(x)
	var r := {"ok": false, "motivo": ""}
	if dif_hex.is_empty() or att_ids.is_empty():
		r["motivo"] = "manca il bersaglio o gli attaccanti"
		return r
	var difensori := []
	for h in dif_hex:
		var us := unita_in(h, 1 - lato)
		if us.is_empty():
			r["motivo"] = "nessun nemico in %s" % Mappa.sigla(h)
			return r
		for id in us:
			if s["unita"][id]["dif"] or s["unita"][id]["avz"]:
				r["motivo"] = "%s è già stato attaccato" % nome(id)
				return r
			difensori.append(id)
	var adiac := []
	var bomb := []
	var tutti := att_ids.duplicate()
	# le unità nello stesso esagono di un attaccante adiacente attaccano insieme
	for id in att_ids:
		if not s["unita"].has(id):
			return r
		var h: String = s["unita"][id]["h"]
		for x in unita_in(h, lato):
			if not tutti.has(x) and not s["unita"][x]["att"] and in_ezoc(x):
				tutti.append(x)
	for id in tutti:
		var u: Dictionary = s["unita"][id]
		if lato_di(id) != lato or u["st"] != "mappa" or u["att"] or u["avz"]:
			r["motivo"] = "%s non può attaccare" % nome(id)
			return r
		var vicino_a_tutti := true
		for h in dif_hex:
			if not Mappa.adiacenti(u["h"], h) or (Mappa.fiume(u["h"], h) and not Mappa.ponte(u["h"], h)):
				vicino_a_tutti = false
		if in_ezoc(id):
			if not vicino_a_tutti:
				r["motivo"] = "%s deve essere adiacente a tutti i difensori" % nome(id)
				return r
			if campagna() and not in_comando(id):
				pass
			adiac.append(id)
		elif tipo(id) in ["A", "HA"]:
			var ok := false
			for h in dif_hex:
				if puo_bombardare(id, h):
					ok = true
			if not ok:
				r["motivo"] = "%s non ha il bersaglio a tiro" % nome(id)
				return r
			bomb.append(id)
		else:
			r["motivo"] = "%s non è a contatto col nemico" % nome(id)
			return r
	if adiac.is_empty() and dif_hex.size() > 1:
		r["motivo"] = "il solo bombardamento colpisce un esagono"
		return r
	# fuori comando (campagna): non attacca se non è già a contatto
	var ooc := false
	if campagna():
		for id in tutti:
			if not in_comando(id):
				if not in_ezoc(id):
					r["motivo"] = "%s è fuori comando" % nome(id)
					return r
				ooc = true
	# forza
	var att := 0.0
	var tipi := {}
	for id in tutti:
		att += forza_att(id)
		tipi[tipo(id).substr(0, 1) if tipo(id) != "HA" else "A"] = true
	var dif := 0.0
	var castello_fant := false
	for h in dif_hex:
		var base := 0.0
		for id in unita_in(h, 1 - lato):
			var f := float(forza(id))
			if tipo(id) == "C" and Mappa.terreno(h) in ["bosco", "palude"]:
				f = ceilf(f / 2.0)
			base += f
		var molt := 1.0
		match Mappa.terreno(h):
			"citta":
				molt = 2.0
			"castello":
				molt = 3.0
		# ruscello o ponte: raddoppio se tutti gli attacchi adiacenti passano da lì
		var ruscello := not adiac.is_empty()
		for id in adiac:
			if not Mappa.acqua(s["unita"][id]["h"], h):
				ruscello = false
		if ruscello:
			molt = maxf(molt, 2.0)
		dif += base * molt
		if Mappa.terreno(h) == "castello":
			for id in unita_in(h, 1 - lato):
				if tipo(id) == "I" and not dem_unita(id) and (not campagna() or in_comando_dif(id)):
					castello_fant = true
	var col := Dati.colonna(att, dif)
	if s["opzioni"].get("armi_combinate", true) and dif_hex.size() == 1 and tipi.has("I") and tipi.has("C") and tipi.has("A"):
		col = mini(col + 1, 9)
	if castello_fant:
		col = mini(col, 7)
	var max_col := col
	if d.has("col"):
		col = clampi(int(d["col"]), 0, max_col)
	r.merge({"ok": true, "dif_hex": dif_hex, "att": att, "dif": dif, "col": col, "col_max": max_col, "adiac": adiac, "bomb": bomb,
		"difensori": difensori, "tutti": tutti, "ooc": ooc, "castello": castello_fant,
		"armi": dif_hex.size() == 1 and tipi.has("I") and tipi.has("C") and tipi.has("A")}, true)
	return r

func in_comando_dif(id: String) -> bool:
	# lo stato di comando del difensore è quello calcolato nel suo ultimo turno; si approssima col raggio attuale
	return not s.get("ooc_dif", {}).has(id)

func _attacco(d: Dictionary) -> bool:
	var v := valuta_attacco(d)
	if not v["ok"]:
		return false
	var lato := int(s["lato"])
	var dif_hex: Array = v["dif_hex"]
	var dd := dado()
	var ris: String = Dati.TRC[dd - 1][int(v["col"])]
	var orig := ris
	if v["castello"] and ris == "DR":
		ris = "NE"
	if v["ooc"] and ris in ["DE", "DR"]:
		ris = "AR"
	var tutti_ooc_dif := campagna()
	for id in v["difensori"]:
		if in_comando_dif(id):
			tutti_ooc_dif = false
	if tutti_ooc_dif and ris == "AE":
		ris = "AR"
	for id in v["tutti"]:
		s["unita"][id]["att"] = true
	for id in v["difensori"]:
		s["unita"][id]["dif"] = true
	var rep := {"att": [], "dif": [], "dif_hex": dif_hex, "col": Dati.COLONNE[int(v["col"])], "dado": dd,
		"ris": ris, "orig": orig, "fa": v["att"], "fd": v["dif"], "lato": lato, "elim": [], "rit": [], "bomb": v["bomb"].duplicate()}
	for id in v["tutti"]:
		rep["att"].append(id)
	for id in v["difensori"]:
		rep["dif"].append(id)
	var hex_att := {}
	for id in v["adiac"]:
		hex_att[s["unita"][id]["h"]] = true
	# primo combattimento fra prussiani e francesi a La Belle Alliance
	if s["scen"] == "bellealliance" and not s["contatto_pr"]:
		var pr := false
		for id in v["tutti"] + v["difensori"]:
			if esercito(id) == "PR":
				pr = true
		if pr:
			s["contatto_pr"] = true
			_annuncio("Prussiani e Francesi si scontrano: i livelli anglo-alleati salgono di 10")
	var guardia := false
	if lato == FR:
		for id in v["tutti"]:
			var des: String = cat(id)["des"]
			if des in ["Gren/Gd", "Chas/Gd"] or (not campagna() and des.ends_with("Gd") and tipo(id) == "I"):
				guardia = true
	var dem_prima: Dictionary = s["dem"].duplicate()
	var liberati := []    # esagoni lasciati liberi dal perdente
	causa = ris
	match ris:
		"AE":
			for id in v["adiac"]:
				liberati.append(s["unita"][id]["h"])
				_elimina(id)
				rep["elim"].append(id)
		"AR":
			for id in v["adiac"]:
				var h0: String = s["unita"][id]["h"]
				if _ritira(id):
					rep["rit"].append(id)
				else:
					rep["elim"].append(id)
				liberati.append(h0)
		"DE", "EX":
			var sp_dif := 0
			for id in v["difensori"]:
				sp_dif += forza(id)
				_elimina(id)
				rep["elim"].append(id)
			liberati = dif_hex.duplicate()
			if ris == "EX":
				causa = "EXatt"
				for id in _scegli_scambio(v["adiac"], sp_dif):
					_elimina(id)
					rep["elim"].append(id)
		"DR":
			for id in v["difensori"]:
				if _ritira(id):
					rep["rit"].append(id)
				else:
					rep["elim"].append(id)
			liberati = dif_hex.duplicate()
	causa = ""
	_ricalcola()
	for h in liberati.duplicate():
		_capi_rimasti_soli(h)
	_controlla_demoralizzazione()
	if guardia and s["opzioni"].get("guardia", true) and ris in ["AE", "AR", "EX"]:
		var spezzato := false
		for k in s["dem"]:
			if s["dem"][k] and not dem_prima.get(k, false) and not k.begins_with("FR"):
				spezzato = true
		if not spezzato:
			if campagna():
				# i corpi i cui ufficiali sono entro 10 esagoni dall'attacco
				var hg: String = dif_hex[0]
				for c in s["capi"]:
					var k: Dictionary = catalogo["capi"][c]
					if k["es"] == "FR" and int(k["cap"]) == 0 and s["capi"][c]["st"] == "mappa" and Mappa.distanza(s["capi"][c]["h"], hg) <= 10:
						s["mod"]["lv:FR:" + k["des"]] = int(s["mod"].get("lv:FR:" + k["des"], 0)) + 7
				_annuncio("La Guardia imperiale è respinta! I corpi francesi vacillano (livelli -7)")
			else:
				s["guardia"] = int(s["guardia"]) + 20
				_annuncio("La Guardia imperiale è respinta! Il livello francese scende di 20")
			_controlla_demoralizzazione()
	_log(_testo_battaglia(rep))
	s["ultima_battaglia"] = rep
	eventi.append({"k": "battaglia", "rep": rep})
	# avanzata dopo il combattimento
	var vincitore := -1
	var cand := []
	var vuoti := []
	for h in liberati:
		if unita_in(h).is_empty() and Mappa.terreno(h) != "castello":
			vuoti.append(h)
	if not vuoti.is_empty():
		if ris in ["DE", "DR", "EX"]:
			vincitore = lato
			for id in v["adiac"]:
				if s["unita"][id]["st"] == "mappa" and not dem_unita(id):
					for h in vuoti:
						if Mappa.adiacenti(s["unita"][id]["h"], h) and Mappa.passabile(s["unita"][id]["h"], h):
							cand.append([id, h])
		elif ris in ["AE", "AR"]:
			vincitore = 1 - lato
			for id in v["difensori"]:
				if s["unita"][id]["st"] == "mappa" and not dem_unita(id) and (not campagna() or in_comando_dif(id)):
					for h in vuoti:
						if Mappa.adiacenti(s["unita"][id]["h"], h) and Mappa.passabile(s["unita"][id]["h"], h):
							cand.append([id, h])
	if not cand.is_empty():
		s["pendente"] = {"k": "avanza", "lato": vincitore, "cand": cand}
	return true

func _testo_battaglia(rep: Dictionary) -> String:
	var a := []
	for id in rep["att"]:
		a.append(nome(id))
	var d := []
	for id in rep["dif"]:
		d.append(nome(id))
	var t := "%s attacca %s a %s: %s contro %s, colonna %s, dado %d — [b]%s[/b]" % [
		", ".join(a), ", ".join(d), ", ".join(rep["dif_hex"].map(func(h): return Mappa.sigla(h))),
		_num(rep["fa"]), _num(rep["fd"]), rep["col"], rep["dado"], Dati.NOMI_RISULTATO.get(rep["ris"], rep["ris"])]
	if not rep["elim"].is_empty():
		t += ". Eliminati: " + ", ".join(rep["elim"].map(func(x): return nome(x)))
	return t + "."

func _num(x: float) -> String:
	return str(int(x)) if x == floorf(x) else "%.1f" % x

## Scambio: si eliminano attaccanti adiacenti con forza stampata almeno pari a quella dei difensori
func _scegli_scambio(adiac: Array, sp: int) -> Array:
	var best := []
	var best_tot := 999999
	var n := adiac.size()
	for mask in range(1, 1 << mini(n, 12)):
		var tot := 0
		var sel := []
		for i in mini(n, 12):
			if mask & (1 << i):
				tot += forza(adiac[i])
				sel.append(adiac[i])
		if tot >= sp and tot < best_tot:
			best_tot = tot
			best = sel
	if best.is_empty():
		return adiac.duplicate()
	return best

func _elimina(id: String, riorganizzabile := true) -> void:
	var u: Dictionary = s["unita"][id]
	var es := esercito(id)
	var sp := forza(id)
	var pieno: bool = not u["rid"] and int(cat(id)["r"]) > 0
	if campagna():
		u["st"] = "riorg" if (pieno and riorganizzabile) else "distrutta"
		u["dal"] = int(s["turno"])
		var g := gruppo_dem(id)
		var k := "AA" if g.begins_with("AA:") else g
		s["perdite_corpo"][k] = int(s["perdite_corpo"].get(k, 0)) + int(cat(id)["f"])
	else:
		u["st"] = "elim"
	s["perdite"][es] = int(s["perdite"][es]) + sp
	# statistica per le prove automatiche (non fa parte dello stato della partita)
	var kc := "%s:%s" % [es, causa if causa != "" else "altro"]
	stat[kc] = int(stat.get(kc, 0)) + sp
	# punti vittoria per le perdite
	match s["scen"]:
		"quatrebras", "wavre", "ligny":
			var l := 1 - lato_di(id)
			s["pv"][l] = int(s["pv"][l]) + sp
	_ricalcola()

## Ritirata di un esagono; restituisce false se l'unità è eliminata
func _ritira(id: String) -> bool:
	var lato := lato_di(id)
	var h0: String = s["unita"][id]["h"]
	_ricalcola()
	var best := ""
	var bv := -INF
	var catena := []
	for v in Mappa.vicini(h0):
		if not Mappa.passabile(h0, v) or nemico_in(v, lato) or zoc(v, 1 - lato):
			continue
		var amici := unita_in(v, lato)
		if Mappa.terreno(v) == "castello" and not amici.is_empty():
			continue
		var limite := 1 if Mappa.terreno(v) == "castello" else 2
		var val := _valore_ritirata(v, lato)
		var sposta := []
		if amici.size() >= limite:
			# spostamento (7.6): un'unità amica cede il posto, anche a catena, se ha dove andare
			sposta = _catena_spostamento(v, lato, {h0: true, v: true}, 3)
			if sposta.is_empty():
				continue
			val -= 3.0 + sposta.size()
		if val > bv:
			bv = val
			best = v
			catena = sposta
	if best == "":
		if diagnosi:
			var mot := []
			for v in Mappa.vicini(h0):
				if not Mappa.passabile(h0, v):
					mot.append("imp")
				elif nemico_in(v, lato):
					mot.append("nem")
				elif zoc(v, 1 - lato):
					mot.append("zoc" + ("+am" if not unita_in(v, lato).is_empty() else ""))
				else:
					mot.append("pieno")
			stat["blocchi"] = stat.get("blocchi", []) + [" ".join(mot)]
			var dt := int(s["turno"]) - int(ultimo_mov.get(id, -9))
			var kk := "fermo_da_%d" % mini(dt, 3)
			stat[kk] = int(stat.get(kk, 0)) + 1
		_elimina(id)
		return false
	# la catena è in ordine dall'esagono di arrivo verso l'ultimo spostato: si applica dal fondo
	for i in range(catena.size() - 1, -1, -1):
		var p: PackedStringArray = String(catena[i]).split(">")
		s["unita"][p[0]]["h"] = p[1]
	s["unita"][id]["h"] = best
	_ricalcola()
	return true

## Cerca chi spostare da h (pieno) e dove; se anche la destinazione è piena si prosegue a catena.
## Restituisce ["id>esagono", ...] oppure [] se nessuna catena è possibile.
func _catena_spostamento(h: String, lato: int, visti: Dictionary, prof: int) -> Array:
	if Mappa.terreno(h) == "castello" or prof <= 0:
		return []
	var pieni := []
	for x in unita_in(h, lato):
		for v in Mappa.vicini(h):
			if visti.has(v) or not Mappa.passabile(h, v) or nemico_in(v, lato) or zoc(v, 1 - lato):
				continue
			var lim := 1 if Mappa.terreno(v) == "castello" else 2
			var occ := unita_in(v, lato).size()
			if occ < lim:
				return [x + ">" + v]
			if Mappa.terreno(v) != "castello":
				pieni.append([x, v])
	for c in pieni:
		var v2: Dictionary = visti.duplicate()
		v2[c[1]] = true
		var resto := _catena_spostamento(c[1], lato, v2, prof - 1)
		if not resto.is_empty():
			return [c[0] + ">" + c[1]] + resto
	return []

func _valore_ritirata(h: String, lato: int) -> float:
	var v := 0.0
	for id in s["unita"]:
		if lato_di(id) != lato and s["unita"][id]["st"] == "mappa":
			var d := Mappa.distanza(h, s["unita"][id]["h"])
			if d <= 4:
				v += float(d) * forza(id) * 0.1
	match Mappa.terreno(h):
		"citta", "bosco":
			v += 1.0
	v -= unita_in(h, lato).size() * 0.5
	return v

func _capi_rimasti_soli(h: String) -> void:
	if not unita_in(h).is_empty():
		return
	for c in capi_in(h):
		if dado() <= 2:
			s["capi"][c]["st"] = "elim"
			_annuncio("%s è caduto sul campo" % nome(c))
		else:
			_ricolloca_capo(c)
	_ricalcola()

func _avanza(d: Dictionary) -> bool:
	var p: Dictionary = s["pendente"]
	var id: String = d.get("u", "")
	if id != "":
		var ok := false
		var h: String = d.get("h", "")
		for c in p["cand"]:
			if c[0] == id and (h == "" or c[1] == h):
				ok = true
				h = c[1]
		if not ok:
			return false
		s["unita"][id]["h"] = h
		s["unita"][id]["avz"] = true
		_occupa(h, lato_di(id))
		_sposta_capi_nemici(h)
		_log("%s avanza in %s." % [nome(id), Mappa.sigla(h)])
	s["pendente"] = {}
	_ricalcola()
	if p.get("poi_fine", false):
		_combattimenti_obbligati()
		if s["pendente"].is_empty() and not finita():
			_fine_turno_giocatore()
	return true

# ---------- obblighi di combattimento

## Esagoni nemici che devono ancora essere attaccati e unità che devono ancora attaccare
func obblighi() -> Dictionary:
	var lato := int(s["lato"])
	var nemici := {}
	var amici := []
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] != "mappa" or lato_di(id) != lato or u["att"] or u["avz"]:
			continue
		if Mappa.terreno(u["h"]) == "castello":
			continue
		if not in_ezoc(id):
			continue
		var bersagli := []
		for v in Mappa.vicini(u["h"]):
			if Mappa.fiume(u["h"], v) and not Mappa.ponte(u["h"], v):
				continue
			for e in unita_in(v, 1 - lato):
				if not s["unita"][e]["dif"] and not s["unita"][e]["avz"]:
					bersagli.append(v)
					break
		if not bersagli.is_empty():
			amici.append(id)
			for b in bersagli:
				nemici[b] = true
	return {"amici": amici, "nemici": nemici.keys()}

func _combattimenti_obbligati() -> void:
	# alla fine della fase: gli attacchi obbligatori non dichiarati si risolvono da soli
	var guard := 0
	while guard < 60 and s["pendente"].is_empty() and not finita():
		guard += 1
		var ob := obblighi()
		if ob["amici"].is_empty():
			break
		var e: String = ob["nemici"][0]
		var att := []
		for id in ob["amici"]:
			if Mappa.adiacenti(s["unita"][id]["h"], e):
				att.append(id)
		if att.is_empty():
			break
		if not _attacco({"dif": [e], "att": att}):
			for id in att:
				s["unita"][id]["att"] = true
		_ricalcola()
	if not s["pendente"].is_empty():
		s["pendente"]["poi_fine"] = true

# =============================================================================================
# Vittoria

func _controlla_vittoria(fine: bool) -> void:
	if finita():
		return
	var k: String = s["scen"]
	var v := -1
	var perche := ""
	match k:
		"ligny":
			if s["dem"].get("FR", false):
				v = AL
				perche = "L'Armée du Nord è demoralizzata."
			elif s["dem"].get("PR", false) and int(s["perdite"]["FR"]) < 35:
				v = FR
				perche = "I Prussiani sono demoralizzati prima che i Francesi perdano 35 punti."
			elif s["dis"].get("PR", false):
				v = FR
				perche = "L'esercito prussiano si è disintegrato."
			elif fine:
				v = AL
				perche = "I Prussiani hanno tenuto il campo fino a sera."
		"quatrebras":
			if s["dem"].get("FR", false):
				v = AL
				perche = "I Francesi sono demoralizzati: vittoria automatica alleata."
			elif s["dis"].get("AA", false):
				v = FR
				perche = "Gli Anglo-alleati si sono disintegrati: vittoria automatica francese."
			elif fine:
				if int(s["occup"].get("1641", -1)) >= 0:
					var l := int(s["occup"]["1641"])
					s["pv"][l] = int(s["pv"][l]) + 5
				v = FR if int(s["pv"][FR]) > int(s["pv"][AL]) else AL
				perche = "Punti vittoria: Francesi %d, Alleati %d." % [int(s["pv"][FR]), int(s["pv"][AL])]
		"wavre":
			if s["dem"].get("FR", false):
				v = AL
				perche = "Le truppe di Grouchy sono demoralizzate."
			elif s["dis"].get("PR", false):
				v = FR
				perche = "Il corpo prussiano si è disintegrato."
			elif fine:
				var rimasti := 0
				for id in s["unita"]:
					if esercito(id) == "PR" and s["unita"][id]["st"] == "mappa":
						rimasti += forza(id)
				s["pv"][FR] = int(s["pv"][FR]) + rimasti
				v = FR if int(s["pv"][FR]) > int(s["pv"][AL]) else AL
				perche = "Punti vittoria: Francesi %d (di cui %d per i Prussiani rimasti), Prussiani %d." % [int(s["pv"][FR]), rimasti, int(s["pv"][AL])]
		"bellealliance":
			if s["dem"].get("FR", false):
				v = AL
				perche = "L'Armée du Nord è demoralizzata e abbandona il campo."
			elif s["dis"].get("AA", false) or (s["dem"].get("AA", false) and s["dem"].get("PR", false)):
				v = FR
				perche = "Wellington e Blücher sono travolti: Napoleone ha vinto a Waterloo."
			elif fine:
				v = AL
				perche = "Al calar della sera gli Alleati tengono ancora il campo."
		"campagna":
			var p := punti_campagna()
			if p >= 230:
				v = FR
				perche = "I Francesi raggiungono %d punti vittoria: Bruxelles è aperta." % p
			elif fine:
				v = AL
				perche = "Fine della campagna: i Francesi si fermano a %d punti vittoria (ne servivano 230)." % p
	if v >= 0:
		s["esito"] = {"vince": v, "perche": perche}
		_log("[b]Fine della partita: vincono i %s.[/b] %s" % [Dati.LATI[v], perche])
		eventi.append({"k": "fine"})

func punti_campagna() -> int:
	var p := 0
	for id in s["unita"]:
		var st: String = s["unita"][id]["st"]
		if st in ["riorg", "distrutta"]:
			p += int(cat(id)["f"]) * (1 if lato_di(id) == AL else -1)
	var usc := 2 * int(s["uscite"]["FR"])
	if usc >= 40:
		usc *= 2
	return p + usc

# =============================================================================================
# Registro

func _log(t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > 400:
		s["log"] = s["log"].slice(-400)

func _annuncio(t: String) -> void:
	_log("[b]" + t + "[/b]")
	eventi.append({"k": "annuncio", "t": t})
