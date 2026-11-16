## Il motore delle regole di Napoleon at War (SPI 1975): Marengo, Wagram, la battaglia delle Nazioni,
## Jena-Auerstadt. Le regole standard sono quasi quelle di Last Battles (stessa TRC, zone di controllo
## rigide, combattimento obbligatorio, tiro dell'artiglieria a due esagoni); cambiano l'impilamento (una
## sola unità per esagono), il terreno (pendii, terreno accidentato, palude, sentieri), la notte, e le
## regole esclusive di ciascun gioco: il primo turno e il contrattacco a Marengo, la demoralizzazione e
## l'arciduca Giovanni a Wagram, la ritirata notturna e la linea di comunicazione a Lipsia, la nebbia,
## le due battaglie e il transito fra le mappe a Jena-Auerstadt.
class_name MotoreNaw
extends Motore

var gioco := ""

# =============================================================================================
# Avvio

func nuova(cfg: Dictionary) -> void:
	carica_catalogo()
	var k: String = cfg.get("scen", "naw_marengo")
	scen = scenari[k]
	gioco = scen["gioco"]
	Mappa.carica("res://assets/naw/%s/mappa.json" % scen["mappa"])
	var var_: Dictionary = cfg.get("varianti", {})
	s = {
		"scen": k, "seed": int(cfg.get("seed", 1)), "rng": int(cfg.get("seed", 1)) * 7919 + 17,
		"turno": 0, "lato": int(scen.get("primo", FR)), "fase": "movimento", "azioni": 0,
		"unita": {}, "capi": {}, "log": [], "esito": {}, "pendente": {},
		"perdite": {"FR": 0, "PR": 0, "AA": 0, "AU": 0, "RU": 0, "SV": 0}, "perdite_corpo": {}, "pv": [0, 0],
		"occup": {}, "dem": {}, "dis": {}, "mod": {}, "uscite": {"FR": 0, "PR": 0, "AU": 0}, "pv_uscita": 0,
		"entrate": {}, "comando": {}, "contatto_pr": false, "guardia": 0, "opzionali": false,
		"opzioni": {"guardia": false}, "ultima_battaglia": {},
		"naw": {"varianti": var_, "perdite_campo": {}, "dem_campo": {}, "presi": {}, "contrattacco": -1},
	}
	var opz_j: String = str(var_.get("opzione", "A"))
	for e in scen["unita"]:
		_crea_unita(e["u"], e["h"], "mappa", 0)
	for r in scen["rinforzi"]:
		var o: String = str(r.get("opz", ""))
		if o != "":
			if not o.begins_with(opz_j):
				continue
			if o.ends_with("L") and not bool(var_.get("louis", false)):
				continue
		var e: String = r["e"]
		if r.get("bern", false) and bool(var_.get("bernadotte", false)):
			e = "0128"
		_crea_unita(r["u"], "", "arrivo", int(r["t"]))
		s["unita"][r["u"]]["e"] = e
		if r.get("giovanni", false):
			s["unita"][r["u"]]["giovanni"] = true
	_ricalcola()
	if scen.has("zone"):
		_schiera_zone()
	for id in scen.get("distrutte", []):
		_crea_unita(id, "", "elim", 0)
		s["perdite"][esercito(id)] = int(s["perdite"][esercito(id)]) + forza(id)
	_ricalcola()
	_log("[b]%s[/b] — %s, %s." % [scen["titolo"], scen["sotto"], scen["data"]])
	if gioco == "jena":
		_log("Opzione prussiana %s%s%s." % [opz_j, ", con le truppe di Luigi Ferdinando" if var_.get("louis", false) else "", "; Bernadotte marcia su Auerstadt" if var_.get("bernadotte", false) else ""])
	_inizio_turno_giocatore()

func importa(d: Dictionary) -> void:
	carica_catalogo()
	s = d
	scen = scenari[s["scen"]]
	gioco = scen["gioco"]
	Mappa.carica("res://assets/naw/%s/mappa.json" % scen["mappa"])
	_ricalcola()

## Wagram: i Francesi si schierano liberamente entro un certo raggio da un esagono (o su Lobau):
## qui le unità prendono i posti liberi più vicini al centro della loro zona, nell'ordine della tabella
func _schiera_zone() -> void:
	for z in scen["zone"]:
		var id: String = z["u"]
		var cand: Array = []
		if z["centro"] == "lobau":
			cand = scen["lobau"].duplicate()
		else:
			cand = Mappa.entro(z["centro"], int(z["raggio"]))
			cand.sort_custom(func(a, b): return Mappa.distanza(a, z["centro"]) < Mappa.distanza(b, z["centro"]))
		var h := ""
		for c in cand:
			if Mappa.terreno(c) != "lago" and unita_in(c).is_empty():
				h = c
				break
		_crea_unita(id, h, "mappa" if h != "" else "arrivo", 0)
		if h == "":
			s["unita"][id]["e"] = z["centro"]
		_ricalcola()

func campagna() -> bool:
	return false

func comando() -> bool:
	return false

func opz(_k: String) -> bool:
	return false

func nome_lato(l: int) -> String:
	return scen["lati"][l]

func testo_data() -> String:
	var t := mini(int(s["turno"]), scen["turni"].size() - 1)
	return "%s, %s · turno %d di %d" % [scen["giorni"][t], scen["ore"][t], t + 1, scen["turni"].size()]

func ora() -> String:
	return scen["ore"][mini(int(s["turno"]), scen["turni"].size() - 1)]

## Numero del turno sul segnalino originale (la battaglia delle Nazioni ha scenari che iniziano al 13)
func turno_gioco() -> int:
	return int(s["turno"]) + 1 + int(scen.get("turno0", 0))

func nebbia() -> bool:
	return turno_label().begins_with("F")

func pioggia() -> bool:
	return false

func senza_combattimento() -> bool:
	return notte()

func sulla_mappa(id: String) -> bool:
	return s["unita"][id]["st"] == "mappa"

# =============================================================================================
# Demoralizzazione

## Jena-Auerstadt: due battaglie separate (le righe 1-20 sono Jena, dalla 22 Auerstadt)
func campo(h: String) -> String:
	if gioco != "jena" or h == "":
		return ""
	return "J" if Mappa.riga(h) <= 20 else "A"

func dem_unita(id: String) -> bool:
	# a Wagram l'esercito demoralizzato non avanza più dopo il combattimento
	if gioco == "wagram":
		return bool(s["dem"].get(str(lato_di(id)), false))
	return false

func perdite_lato(l: int) -> int:
	var t := 0
	for es in s["perdite"]:
		if (es == "FR") == (l == FR):
			t += int(s["perdite"][es])
	return t

## Livello di demoralizzazione di un lato (in Jena-Auerstadt per campo di battaglia; 999 se non c'è)
func livello_naw(l: int, c := "") -> int:
	match gioco:
		"wagram":
			return 50 if l == FR else 45
		"nazioni":
			var t := turno_gioco()
			if t <= 5:
				return 100 if l == FR else 80
			if t <= 11:
				return 110 if l == FR else 120
			return 110 if l == FR else 160
		"jena":
			var v: Dictionary = s["naw"]["varianti"]
			var louis := bool(v.get("louis", false))
			if str(v.get("opzione", "A")) == "A":
				if c == "J":
					return 65 if l == FR else (21 if louis else 18)
				return 19 if l == FR else (20 if louis else 15)
			if c == "J":
				return 75 if l == FR else (60 if louis else 48)
			return 999
	return 999

func perdite_campo(l: int, c: String) -> int:
	return int(s["naw"]["perdite_campo"].get("%s%d" % [c, l], 0))

func dem_campo(c: String) -> int:
	return int(s["naw"]["dem_campo"].get(c, -1))

func _elimina(id: String, riorganizzabile := true) -> void:
	var h: String = s["unita"][id]["h"]
	var c := campo(h)
	super._elimina(id, riorganizzabile)
	if c != "":
		var k := "%s%d" % [c, lato_di(id)]
		s["naw"]["perdite_campo"][k] = int(s["naw"]["perdite_campo"].get(k, 0)) + forza(id)
	if gioco == "wagram":
		var l := 1 - lato_di(id)
		s["pv"][l] = int(s["pv"][l]) + forza(id)

func _controlla_demoralizzazione() -> void:
	match gioco:
		"wagram", "nazioni":
			var nuovi := []
			for l in [FR, AL]:
				if not s["dem"].get(str(l), false) and perdite_lato(l) >= livello_naw(l):
					nuovi.append(l)
			if gioco == "nazioni" and nuovi.size() == 2:
				# 17.3: se succede insieme, vince chi sta giocando il turno
				nuovi = [1 - int(s["lato"])]
			for l in nuovi:
				s["dem"][str(l)] = true
				_annuncio("%s: l'esercito è demoralizzato (%d punti persi)" % [nome_lato(l), perdite_lato(l)])
		"jena":
			for c in ["J", "A"]:
				if dem_campo(c) >= 0:
					continue
				var nuovi := []
				for l in [FR, AL]:
					if perdite_campo(l, c) >= livello_naw(l, c):
						nuovi.append(l)
				if nuovi.size() == 2:
					nuovi = [1 - int(s["lato"])]
				if not nuovi.is_empty():
					s["naw"]["dem_campo"][c] = int(nuovi[0])
					_annuncio("%s: i %s sono demoralizzati" % ["Jena" if c == "J" else "Auerstadt", nome_lato(int(nuovi[0]))])

# =============================================================================================
# Turni

func _inizio_turno_giocatore() -> void:
	super._inizio_turno_giocatore()
	var l := int(s["lato"])
	# Wagram 14.7: dal turno 7 all'11, con un 1 arriva l'arciduca Giovanni dal bordo sud-est
	if gioco == "wagram" and l == AL and int(s["turno"]) >= 6 and int(s["turno"]) <= 10 and not s["mod"].get("giovanni", false):
		var d := dado()
		if d == 1:
			s["mod"]["giovanni"] = true
			for id in s["unita"]:
				if s["unita"][id].get("giovanni", false):
					s["unita"][id]["t"] = int(s["turno"])
			_annuncio("Arriva l'arciduca Giovanni con l'Armata d'Italia! (dado 1)")
		else:
			_log("L'arciduca Giovanni non arriva (dado %d)." % d)
	# Marengo 15.2: il contrattacco dura tre fasi di combattimento francesi
	if gioco == "marengo" and l == FR:
		var c := int(s["naw"]["contrattacco"])
		if c >= 0 and int(s["turno"]) > c + 2:
			s["naw"]["contrattacco"] = -2

func _fine_turno_giocatore() -> void:
	if int(s["lato"]) == int(scen.get("primo", FR)):
		s["lato"] = 1 - int(s["lato"])
		_inizio_turno_giocatore()
		return
	_fine_turno()

func _fine_turno() -> void:
	_controlla_vittoria(false)
	if finita():
		return
	s["turno"] = int(s["turno"]) + 1
	if int(s["turno"]) >= scen["turni"].size():
		s["turno"] = scen["turni"].size() - 1
		_controlla_vittoria(true)
		return
	s["lato"] = int(scen.get("primo", FR))
	_log("[b]Turno %d — %s, %s%s[/b]" % [int(s["turno"]) + 1, scen["giorni"][int(s["turno"])], ora(), "  (notte)" if notte() else ("  (nebbia)" if nebbia() else "")])
	_inizio_turno_giocatore()

func _fine_movimento() -> bool:
	if not ammassati().is_empty():
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
		if _occ[h].size() > 1:
			out.append(h)
	return out

# =============================================================================================
# Movimento

func ma(id: String) -> int:
	var x := int(cat(id)["ma"])
	if nebbia():
		x = int(x / 2.0)
	if gioco == "marengo" and int(s["turno"]) == 0 and lato_di(id) == FR:
		x = int(x / 2.0)
	return maxi(1, x)

## Zona di controllo: a Wagram cavalleria e artiglieria non la estendono oltre un ruscello senza ponte
func zoc(h: String, lato_zoc: int) -> bool:
	var k := "%s|%d" % [h, lato_zoc]
	if _zoc_cache.has(k):
		return _zoc_cache[k]
	var r := false
	for v in Mappa.vicini(h):
		if lato_hex(v) != lato_zoc or blocca_zoc(v, h):
			continue
		if gioco == "wagram" and Mappa.ruscello(v, h):
			var tutti_cav := true
			for id in unita_in(v, lato_zoc):
				if tipo(id) == "I":
					tutti_cav = false
			if tutti_cav:
				continue
		r = true
		break
	_zoc_cache[k] = r
	return r

func blocca_zoc(a: String, b: String) -> bool:
	return Mappa.fiume(a, b) and not Mappa.ponte(a, b)

## Costo per passare da a a b (Tabella degli effetti del terreno di Napoleon at War)
func costo_passo(a: String, b: String, tp: String, _dem: bool, _lato := -1) -> float:
	if not Mappa.passabile(a, b):
		return INF
	var t := Mappa.terreno(b)
	if t == "palude" and not Mappa.strada(a, b):
		return INF
	if gioco == "jena" and notte() and t == "bosco":
		return INF
	if Mappa.strada(a, b):
		return 0.5
	var c := 1.0
	if t in ["bosco", "accidentato"]:
		c = 2.0
	if Mappa.sentiero(a, b):
		c = 1.0
	elif Mappa.ruscello(a, b):
		if gioco == "wagram" and tp != "I":
			return INF
		c += 2.0
	if Mappa.pendio(a, b) and Mappa.in_basso(a, b) == a:
		c += 1.0
	return c

## Ritirata notturna (Nazioni 16.1): di notte si può lasciare una zona di controllo nemica
func _ritirata_notturna() -> bool:
	return gioco == "nazioni" and notte()

func puo_muovere(id: String) -> bool:
	var u: Dictionary = s["unita"][id]
	if u["st"] != "mappa" or u["mosso"] or lato_di(id) != int(s["lato"]):
		return false
	# Nazioni 14.62: niente movimento francese nel primo turno dello scenario
	if gioco == "nazioni" and int(s["turno"]) == 0 and lato_di(id) == FR:
		return false
	# Wagram 15.3: le artiglierie 10-1 non lasciano Lobau (e non si muovono fuori dall'isola)
	return _ritirata_notturna() or not in_ezoc(id)

func raggiungibili(id: String, partenza := "", costo0 := 0.0) -> Dictionary:
	var lato := lato_di(id)
	var h0: String = partenza if partenza != "" else s["unita"][id]["h"]
	var tp := tipo(id)
	var mpa := float(ma(id))
	var out := {h0: {"c": costo0, "da": ""}}
	if partenza == "" and zoc(h0, 1 - lato) and not _ritirata_notturna():
		return out
	if partenza == "" and gioco == "nazioni" and int(s["turno"]) == 0 and lato == FR:
		return out
	var lobau: bool = gioco == "wagram" and int(cat(id)["ma"]) == 1
	var no_zoc := notte() or (gioco == "marengo" and int(s["turno"]) == 0 and lato == FR)
	var coda := [h0]
	while not coda.is_empty():
		var bi := 0
		for i in coda.size():
			if out[coda[i]]["c"] < out[coda[bi]]["c"]:
				bi = i
		var h: String = coda[bi]
		coda.remove_at(bi)
		var c0: float = out[h]["c"]
		if h != h0 and zoc(h, 1 - lato):
			continue
		for v in Mappa.vicini(h):
			if nemico_in(v, lato):
				continue
			if no_zoc and zoc(v, 1 - lato):
				continue
			if lobau and not (v in scen["lobau"]):
				continue
			var c := c0 + costo_passo(h, v, tp, false, lato)
			if c > mpa + 0.001:
				continue
			if not out.has(v) or c < out[v]["c"] - 0.001:
				out[v] = {"c": c, "da": h}
				if not coda.has(v):
					coda.append(v)
	return out

func _muovi(d: Dictionary) -> bool:
	var h: String = d.get("h", "")
	var id: String = d.get("u", "")
	# una sola unità per esagono alla fine del movimento (5.32)
	if s["unita"].has(id) and not unita_in(h, lato_di(id)).filter(func(x): return x != id).is_empty():
		return false
	return super._muovi(d)

## Gli ingressi dei rinforzi: un esagono occupato blocca l'ingresso; se sono tutti bloccati si entra
## dal più vicino libero dello stesso bordo
func ingressi(id: String) -> Array:
	var lato := lato_di(id)
	var lista: Array = Array(str(s["unita"][id].get("e", "")).split("|", false))
	var out := []
	for e in lista:
		if Mappa.esiste(e) and unita_in(e).is_empty() and _ingresso_ok(e, lato, id):
			out.append(e)
	if out.is_empty() and lista.size() <= 2 and not lista.is_empty() and Mappa.esiste(lista[0]):
		var b := bordo(lista[0])
		var vicini := Mappa.entro(lista[0], 4)
		vicini.sort_custom(func(a, c): return Mappa.distanza(a, lista[0]) < Mappa.distanza(c, lista[0]))
		for e in vicini:
			if bordo(e) == b and b != "" and unita_in(e).is_empty() and _ingresso_ok(e, lato, id):
				out.append(e)
				if out.size() >= 2:
					break
	return out

func _ingresso_ok(e: String, lato: int, id: String) -> bool:
	if gioco in ["jena", "nazioni"] or s["unita"][id].get("giovanni", false) or s["unita"][id].get("transito", false):
		return not zoc(e, 1 - lato)
	return true

func raggiungibili_arrivo(id: String) -> Dictionary:
	var tot := {}
	for e in ingressi(id):
		var c0 := 1.0
		if gioco == "jena":
			c0 = costo_passo(e, e, tipo(id), false) if Mappa.terreno(e) != "aperto" else 1.0
			for v in Mappa.vicini(e):
				if not Mappa.esiste(v):
					continue
				if Mappa.strada(e, v):
					c0 = 0.5
		var rg := raggiungibili(id, e, c0)
		for h in rg:
			if not tot.has(h) or rg[h]["c"] < tot[h]["c"]:
				tot[h] = rg[h]
				tot[h]["ing"] = e
	return tot

func _entra(d: Dictionary) -> bool:
	var h: String = d.get("h", "")
	var id: String = d.get("u", "")
	if not unita_in(h).is_empty():
		return false
	var ok := super._entra(d)
	if ok:
		s["unita"][id].erase("transito")
	return ok

func bordo(h: String) -> String:
	var tutti := Mappa._intorno(h)
	var dir := ["n", "e", "e", "s", "o", "o"]
	for i in 6:
		if not Mappa.esiste(tutti[i]):
			return dir[i]
	return ""

# ---------- uscite dalla mappa (Wagram: Austriaci a ovest; Jena-Auerstadt: transito e ritirate)

func uscita_valida(id: String, h: String) -> bool:
	var lato := lato_di(id)
	var c := Mappa.col(h)
	var r := Mappa.riga(h)
	match gioco:
		"wagram":
			return lato == AL and c == 1
		"jena":
			if lato == FR and _transito(h) != "":
				return true
			var cp := campo(h)
			if dem_campo(cp) < 0:
				return false
			if cp == "J":
				if lato == AL:
					return c >= 29 or r == 20
				return c >= 29 or r == 20 or c == 1
			if lato == AL:
				return r == 22
			return r == 22 or c == 1
	return false

## Sezione del binario di transito raggiungibile da un esagono di bordo (nord di Jena, sud di Auerstadt)
func _transito(h: String) -> String:
	var r := Mappa.riga(h)
	if r != 20 and r != 22:
		return ""
	return "ovest" if Mappa.col(h) >= 14 else "est"

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
	if rg[h]["c"] + 1.0 > ma(id) + 0.001 or zoc(h, 1 - lato):
		return false
	var sp := forza(id)
	u["mosso"] = true
	if gioco == "jena" and lato == FR and _transito(h) != "" and not d.get("ritira", false):
		# 17.1: tre caselle di transito, poi l'unità entra dall'altra mappa accanto alla stessa sezione
		var sez := _transito(h)
		var altra := 22 if Mappa.riga(h) == 20 else 20
		var ing := []
		for k in Mappa.esagoni:
			if Mappa.riga(k) == altra and (Mappa.col(k) >= 14) == (sez == "ovest"):
				ing.append(k)
		u["st"] = "arrivo"
		u["h"] = ""
		u["t"] = int(s["turno"]) + 3
		u["e"] = "|".join(ing)
		u["transito"] = true
		_log("%s entra nel binario di transito %s: arriverà sull'altra mappa fra tre turni." % [nome(id), sez])
	else:
		u["st"] = "uscita"
		if gioco == "wagram":
			s["pv"][AL] = int(s["pv"][AL]) + sp
		elif gioco == "jena" and lato == FR and campo(h) == "J" and (Mappa.col(h) >= 29 or Mappa.riga(h) == 20):
			s["uscite"]["FR"] = int(s["uscite"]["FR"]) + sp
		_log("%s esce dalla mappa (%d punti forza)." % [nome(id), sp])
	_ricalcola()
	return true

# =============================================================================================
# Combattimento

func _blocca(h: String) -> bool:
	return Mappa.terreno(h) in ["bosco", "citta"]

## 8.3: la linea di tiro è bloccata solo da boschi e paesi (non dai pendii); lungo un lato serve che lo siano entrambi
func linea_di_tiro(a: String, b: String) -> bool:
	var comuni := []
	for v in Mappa.vicini(a):
		if Mappa.adiacenti(v, b):
			comuni.append(v)
	if comuni.size() == 1:
		return not _blocca(comuni[0])
	if comuni.size() == 2:
		return not (_blocca(comuni[0]) and _blocca(comuni[1]))
	return comuni.size() > 0

func puo_bombardare(id: String, bersaglio: String) -> bool:
	var u: Dictionary = s["unita"][id]
	if tipo(id) != "A" or u["st"] != "mappa" or in_ezoc(id) or nebbia() or notte():
		return false
	var d := Mappa.distanza(u["h"], bersaglio)
	if d < 1 or d > 2:
		return false
	return d == 1 or linea_di_tiro(u["h"], bersaglio)

## Wagram 15.2: cavalleria e artiglieria non attaccano attraverso un ruscello senza ponte
func _attacco_vietato(id: String, h: String) -> bool:
	var a: String = s["unita"][id]["h"]
	if Mappa.fiume(a, h) and not Mappa.ponte(a, h):
		return true
	return gioco == "wagram" and tipo(id) != "I" and Mappa.ruscello(a, h)

func contrattacco_attivo() -> bool:
	var c := int(s["naw"]["contrattacco"])
	return gioco == "marengo" and c >= 0 and int(s["turno"]) <= c + 2

func contrattacco_possibile() -> bool:
	return gioco == "marengo" and int(s["lato"]) == FR and int(s["naw"]["contrattacco"]) == -1 and int(s["turno"]) >= 8 and s["fase"] == "combattimento"

func applica(d: Dictionary) -> bool:
	if d.get("a", "") == "contrattacco":
		eventi = []
		if not contrattacco_possibile():
			return false
		s["naw"]["contrattacco"] = int(s["turno"])
		_annuncio("Il contrattacco di Bonaparte! Per tre turni gli attacchi francesi valgono il doppio")
		s["azioni"] = int(s["azioni"]) + 1
		return true
	return super.applica(d)

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
	for id in att_ids:
		if not s["unita"].has(id):
			return r
		var u: Dictionary = s["unita"][id]
		if lato_di(id) != lato or u["st"] != "mappa" or u["att"] or u["avz"]:
			r["motivo"] = "%s non può attaccare" % nome(id)
			return r
		if in_ezoc(id):
			for h in dif_hex:
				if not Mappa.adiacenti(u["h"], h) or _attacco_vietato(id, h):
					r["motivo"] = "%s deve essere adiacente a tutti i difensori (e non oltre un fiume)" % nome(id)
					return r
			adiac.append(id)
		elif tipo(id) == "A":
			var ok := false
			for h in dif_hex:
				if puo_bombardare(id, h):
					ok = true
			if not ok:
				r["motivo"] = "%s non ha il bersaglio a tiro%s" % [nome(id), " (nebbia: niente tiro a distanza)" if nebbia() else ""]
				return r
			bomb.append(id)
		else:
			r["motivo"] = "%s non è a contatto col nemico" % nome(id)
			return r
	if adiac.is_empty() and dif_hex.size() > 1:
		r["motivo"] = "il solo bombardamento colpisce un esagono"
		return r
	var note := []
	var righe_att := []
	var att := 0.0
	var doppio := lato == FR and contrattacco_attivo()
	for id in att_ids:
		var f := float(forza(id)) * (2.0 if doppio else 1.0)
		att += f
		righe_att.append([nome(id), forza(id), f, "bombarda" if bomb.has(id) else ""])
	if doppio:
		note.append("Contrattacco francese: forza in attacco raddoppiata (15.2)")
	var dif := 0.0
	var righe_dif := []
	for h in dif_hex:
		var base := 0.0
		for id in unita_in(h, 1 - lato):
			base += float(forza(id))
			righe_dif.append([nome(id), forza(id), float(forza(id)), ""])
		var perche := ""
		match Mappa.terreno(h):
			"citta":
				perche = "paese"
			"accidentato":
				perche = "terreno accidentato"
			"palude":
				perche = "palude"
		if perche == "" and not adiac.is_empty():
			var acqua := true
			var pend := true
			for id in adiac:
				var a: String = s["unita"][id]["h"]
				if not Mappa.adiacenti(a, h):
					continue
				if not (Mappa.ruscello(a, h) or Mappa.ponte(a, h)):
					acqua = false
				if not (Mappa.pendio(a, h) and Mappa.in_basso(a, h) == a):
					pend = false
			if acqua:
				perche = "attaccato solo attraverso ruscelli o ponti"
			elif pend:
				perche = "attaccato solo dal basso, su per il pendio"
		if perche != "":
			note.append("%s: difesa ×2 (%s)" % [Mappa.sigla(h), perche])
			base *= 2.0
		dif += base
	var col := Dati.colonna(att, dif)
	# Jena-Auerstadt 18.11: una colonna in meno per chi attacca demoralizzato, una in più contro i demoralizzati
	if gioco == "jena":
		var c := campo(dif_hex[0])
		var dc := dem_campo(c)
		if dc == lato:
			col -= 1
			note.append("Attaccanti demoralizzati: una colonna a sinistra")
		elif dc == 1 - lato:
			col += 1
			note.append("Difensori demoralizzati: una colonna a destra")
	col = clampi(col, 0, 9)
	var max_col := col
	if d.has("col"):
		col = clampi(int(d["col"]), 0, max_col)
		if col < max_col:
			note.append("Colonna ridotta volontariamente a %s (7.9)" % Dati.COLONNE[col])
	r.merge({"ok": true, "dif_hex": dif_hex, "att": att, "dif": dif, "col": col, "col_max": max_col, "adiac": adiac, "bomb": bomb,
		"difensori": difensori, "tutti": att_ids, "ooc": false, "castello": false, "armi": false, "note": note,
		"righe_att": righe_att, "righe_dif": righe_dif, "capo_att": "", "capo_dif": ""}, true)
	return r

## Obblighi di combattimento: chi è nella zona di controllo nemica attacca, chi ha nemici accanto è attaccato
func obblighi() -> Dictionary:
	var lato := int(s["lato"])
	var nemici := {}
	var amici := []
	for id in s["unita"]:
		var u: Dictionary = s["unita"][id]
		if u["st"] != "mappa" or lato_di(id) != lato or u["att"] or u["avz"]:
			continue
		if not in_ezoc(id):
			continue
		var bersagli := []
		for v in Mappa.vicini(u["h"]):
			if _attacco_vietato(id, v):
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

# ---------- ritirata e spostamento: una sola unità per esagono

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
		if Mappa.terreno(v) == "palude" and not Mappa.strada(h0, v):
			continue
		var val := _valore_ritirata(v, lato)
		var sposta := []
		if not unita_in(v, lato).is_empty():
			sposta = _catena_spostamento(v, lato, {h0: true, v: true}, 3)
			if sposta.is_empty():
				continue
			val -= 3.0 + sposta.size()
		if val > bv:
			bv = val
			best = v
			catena = sposta
	if best == "":
		_elimina(id)
		return false
	for i in range(catena.size() - 1, -1, -1):
		var p: PackedStringArray = String(catena[i]).split(">")
		s["unita"][p[0]]["h"] = p[1]
		_log("%s cede il posto e si sposta in %s." % [nome(p[0]), Mappa.sigla(p[1])])
	s["unita"][id]["h"] = best
	_ricalcola()
	return true

func _catena_spostamento(h: String, lato: int, visti: Dictionary, prof: int) -> Array:
	if prof <= 0:
		return []
	var pieni := []
	for x in unita_in(h, lato):
		for v in Mappa.vicini(h):
			if visti.has(v) or not Mappa.passabile(h, v) or nemico_in(v, lato) or zoc(v, 1 - lato):
				continue
			if Mappa.terreno(v) == "palude" and not Mappa.strada(h, v):
				continue
			if unita_in(v, lato).is_empty():
				return [x + ">" + v]
			pieni.append([x, v])
	for c in pieni:
		var v2: Dictionary = visti.duplicate()
		v2[c[1]] = true
		var resto := _catena_spostamento(c[1], lato, v2, prof - 1)
		if not resto.is_empty():
			return [c[0] + ">" + c[1]] + resto
	return []

func _occupa(h: String, lato: int) -> void:
	s["occup"][h] = lato
	# Wagram 17.11: punti austriaci la prima volta che si entra ad Aspern, Essling, Gross Enzersdorf
	if gioco == "wagram" and lato == AL:
		for k in [["aspern", 25, "Aspern"], ["essling", 30, "Essling"], ["enzersdorf", 35, "Gross Enzersdorf"]]:
			if h in scen[k[0]] and not s["naw"]["presi"].get(k[0], false):
				s["naw"]["presi"][k[0]] = true
				s["pv"][AL] = int(s["pv"][AL]) + int(k[1])
				_annuncio("Gli Austriaci entrano a %s: +%d punti vittoria" % [k[2], k[1]])

# =============================================================================================
# Vittoria

func _sp_entro(l: int, centro: String, raggio: int) -> int:
	var t := 0
	for id in s["unita"]:
		if s["unita"][id]["st"] == "mappa" and lato_di(id) == l and Mappa.distanza(s["unita"][id]["h"], centro) <= raggio:
			t += forza(id)
	return t

func _occupato_da(h: String, l: int) -> bool:
	return lato_hex(h) == l

## Testo per la barra in alto: perdite, livelli, punti
func testo_punteggio() -> String:
	match gioco:
		"marengo":
			return "Perdite  Francesi %d · Austriaci %d%s" % [perdite_lato(FR), perdite_lato(AL), "  · CONTRATTACCO" if contrattacco_attivo() else ""]
		"wagram":
			return "Punti  Francia %d · Austria %d · perdite %d/50 e %d/45" % [punti_wagram(FR, false), punti_wagram(AL, false), perdite_lato(FR), perdite_lato(AL)]
		"nazioni":
			return "Perdite  Francesi %d/%d · Alleati %d/%d" % [perdite_lato(FR), livello_naw(FR), perdite_lato(AL), livello_naw(AL)]
		"jena":
			var t := "Jena: Fr %d/%d, Pr %d/%d" % [perdite_campo(FR, "J"), livello_naw(FR, "J"), perdite_campo(AL, "J"), livello_naw(AL, "J")]
			if livello_naw(FR, "A") < 999:
				t += " · Auerstadt: Fr %d/%d, Pr %d/%d" % [perdite_campo(FR, "A"), livello_naw(FR, "A"), perdite_campo(AL, "A"), livello_naw(AL, "A")]
			return t
	return ""

func punti_wagram(l: int, fine: bool) -> int:
	var p := int(s["pv"][l])
	if l == FR:
		for id in s["unita"]:
			if s["unita"][id]["st"] == "mappa" and lato_di(id) == FR and s["unita"][id]["h"] in scen["alture"]:
				p += forza(id)
	elif fine:
		for k in [["aspern", 25], ["essling", 30], ["enzersdorf", 35]]:
			for h in scen[k[0]]:
				if _occupato_da(h, AL):
					p += int(k[1])
					break
	return p

## Nazioni 17.5: a fine partita i Francesi tagliati fuori dalla linea di comunicazione (2131) sono eliminati
func _linea_comunicazione() -> void:
	var meta: String = scen["linea"]
	if not Mappa.esiste(meta):
		return
	var ok := {}
	if not (nemico_in(meta, FR) or zoc(meta, AL)):
		ok[meta] = true
		var coda := [meta]
		while not coda.is_empty():
			var h: String = coda.pop_back()
			for v in Mappa.vicini(h):
				if ok.has(v) or not Mappa.passabile(h, v) or nemico_in(v, FR) or zoc(v, AL):
					continue
				ok[v] = true
				coda.append(v)
	var tagliati := []
	for id in s["unita"].keys():
		var u: Dictionary = s["unita"][id]
		if u["st"] == "mappa" and lato_di(id) == FR and not ok.has(u["h"]):
			# l'unità stessa può stare in una zona nemica: conta se un vicino è sulla linea
			var collegata := false
			for v in Mappa.vicini(u["h"]):
				if ok.has(v) and Mappa.passabile(u["h"], v):
					collegata = true
			if not collegata:
				tagliati.append(id)
	for id in tagliati:
		_elimina(id)
	if not tagliati.is_empty():
		_annuncio("%d unità francesi tagliate fuori da Lipsia (2131) sono perdute" % tagliati.size())
		_controlla_demoralizzazione()

func _controlla_vittoria(fine: bool) -> void:
	if finita():
		return
	var v := -1
	var perche := ""
	match gioco:
		"marengo":
			if fine:
				var el_au := perdite_lato(AL)
				var el_fr := perdite_lato(FR)
				var geo_fr := _sp_entro(FR, scen["marengo"], 4) >= 10
				var geo_au := _occupato_da(scen["marengo"], AL) and _occupato_da(scen["pietrabuona"], AL)
				var tot_fr := el_au >= 33 and geo_fr
				var tot_au := el_fr >= 30 and geo_au
				if geo_fr and geo_au:
					v = 2
					perche = "Entrambi tengono i loro obiettivi: pareggio."
				elif tot_fr:
					v = FR
					perche = "I Francesi hanno eliminato %d punti austriaci e tengono Marengo." % el_au
				elif tot_au:
					v = AL
					perche = "Gli Austriaci hanno eliminato %d punti francesi e tengono Marengo e Pietrabuona." % el_fr
				elif el_au < 33 and el_fr < 30 and (geo_fr or geo_au):
					v = FR if geo_fr else AL
					perche = "Nessuno ha inflitto abbastanza perdite: vince chi tiene i suoi obiettivi."
				else:
					v = 2
					perche = "Nessuno raggiunge le condizioni di vittoria: pareggio."
		"wagram":
			if fine:
				var pf := punti_wagram(FR, true)
				var pa := punti_wagram(AL, true)
				if pf < 75:
					v = AL
					perche = "I Francesi hanno solo %d punti (ne servono almeno 75): vince l'Austria (%d punti)." % [pf, pa]
				elif pf == pa:
					v = 2
					perche = "Punti pari (%d): pareggio." % pf
				else:
					v = FR if pf > pa else AL
					var a := maxf(pf, pa)
					var b := maxf(1.0, minf(pf, pa))
					var grado := "decisiva" if a / b >= 2.0 else ("netta" if a / b >= 1.5 else "di misura")
					perche = "Punti vittoria: Francia %d, Austria %d — vittoria %s." % [pf, pa, grado]
		"nazioni":
			var df: bool = s["dem"].get(str(FR), false)
			var da: bool = s["dem"].get(str(AL), false)
			if df or da:
				v = AL if df else FR
				perche = "L'esercito %s è demoralizzato: la battaglia è decisa." % ("francese" if df else "alleato")
			elif fine:
				_linea_comunicazione()
				if s["dem"].get(str(FR), false):
					v = AL
					perche = "Le unità tagliate fuori da Lipsia demoralizzano l'esercito francese."
				else:
					v = 2
					perche = "Nessun esercito è demoralizzato: pareggio (perdite: Francesi %d, Alleati %d)." % [perdite_lato(FR), perdite_lato(AL)]
		"jena":
			if fine:
				var pv := _punti_jena()
				if pv[0] == pv[1]:
					v = 2
					perche = "Punti vittoria pari (%d a %d): pareggio." % pv
				else:
					v = FR if pv[0] > pv[1] else AL
					var diff: int = abs(int(pv[0]) - int(pv[1]))
					perche = "Punti vittoria: Francesi %d, Prussiani %d — vittoria %s." % [pv[0], pv[1], "decisiva" if diff >= 3 else ("sostanziale" if diff == 2 else "marginale")]
	if v >= 0:
		s["esito"] = {"vince": v, "perche": perche}
		_log("[b]Fine della partita: %s.[/b] %s" % ["pareggio" if v == 2 else "vincono i " + nome_lato(v), perche])
		eventi.append({"k": "fine"})

## Jena-Auerstadt 19.1: punti vittoria [francesi, prussiani]
func _punti_jena() -> Array:
	var a: bool = str(s["naw"]["varianti"].get("opzione", "A")) == "A"
	var fr := 0
	var pr := 0
	var el_pr := perdite_lato(AL)
	var el_fr := maxi(1, perdite_lato(FR))
	var rap := float(el_pr) / float(el_fr)
	if a:
		if rap <= 2.0:
			pr += 1
		else:
			fr += 2
	else:
		if rap <= 1.0:
			pr += 1
		else:
			fr += 1
	if dem_campo("J") == AL:
		fr += 1 if a else 2
	if dem_campo("J") == FR:
		pr += 3
	if a and dem_campo("A") == AL:
		fr += 1
	if a and dem_campo("A") == FR:
		pr += 2
	if el_pr < 48:
		pr += 3 if a else 2
	if a and int(s["uscite"]["FR"]) >= 125:
		fr += 2
	return [fr, pr]
