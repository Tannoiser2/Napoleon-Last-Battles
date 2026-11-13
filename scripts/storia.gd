class_name Storia
extends RefCounted
## «Come andò»: la campagna ricostruita ora per ora da assets/dati/storia.json.
## Usa lo stato del Motore (stesse pedine, stessa mappa) ma non le sue regole: a ogni turno ogni
## gruppo marcia verso le posizioni storiche assegnate (per le strade, entro i suoi punti movimento),
## poi si applicano le perdite documentate. Nessuna decisione, nessun dado.

var m: Motore
var dati: Dictionary
var turno := -1                 # ultimo turno mostrato
var ordini := {}                # gruppo -> ordine in corso
var campi := {}                 # esagono bersaglio -> {esagono: costo per arrivarci}
var eventi := {}                # turno -> voce di storia.json
var gruppo_di := {}             # unità -> gruppo speciale (Girard, Durutte, Guardia...)

func _init(mo: Motore) -> void:
	m = mo
	var f := FileAccess.open("res://assets/dati/storia.json", FileAccess.READ)
	dati = JSON.parse_string(f.get_as_text())
	for v in dati["turni"]:
		eventi[int(v["t"])] = v
	for g in dati["gruppi"]:
		for u in dati["gruppi"][g]:
			gruppo_di[u] = g

func ultimo_turno() -> int:
	return m.scen["turni"].size() - 1

func voce(t: int) -> Dictionary:
	return eventi.get(t, {})

## Unità di un gruppo: "FR:II" (corpo, senza chi sta in un gruppo speciale), un gruppo speciale, o un'unità
func membri(g: String) -> Array:
	var out := []
	if m.s["unita"].has(g):
		return [g] if m.s["unita"][g]["st"] == "mappa" else []
	if dati["gruppi"].has(g):
		for u in dati["gruppi"][g]:
			if m.s["unita"].has(u) and m.s["unita"][u]["st"] == "mappa":
				out.append(u)
		return out
	var p := g.split(":")
	for id in m.s["unita"]:
		if m.s["unita"][id]["st"] != "mappa" or gruppo_di.has(id):
			continue
		if m.esercito(id) == p[0] and str(m.cat(id)["c"]) == p[1]:
			out.append(id)
	return out

## Grafo della mappa (indici interi, costi della fanteria) costruito una volta
var _idx := {}
var _nomi := []
var _archi := []     # per nodo: [[vicino, costo], ...]  (costo per entrare nel vicino)
func _grafo() -> void:
	if not _nomi.is_empty():
		return
	for h in Mappa.esagoni:
		_idx[h] = _nomi.size()
		_nomi.append(h)
	for h in _nomi:
		var l := []
		for n in Mappa.vicini(h):
			var c := m.costo_passo(h, n, "I", false)
			if c != INF:
				l.append([_idx[n], c])
		_archi.append(l)

## Costo (in punti movimento della fanteria) da ogni esagono fino a h, per le strade
func campo(h: String) -> PackedFloat32Array:
	if campi.has(h):
		return campi[h]
	_grafo()
	var n := _nomi.size()
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(9999.0)
	var s0: int = _idx[h]
	dist[s0] = 0.0
	var secchi := {0: [s0]}
	var k := 0
	var massimo := 0
	while k <= massimo:
		if secchi.has(k):
			for a in secchi[k]:
				if int(round(dist[a] * 2.0)) != k:
					continue
				# il costo per andare da b ad a è quello di entrare in a: archi simmetrici a meno del terreno
				for e in _archi[a]:
					var bb: int = e[0]
					var c: float = _costo_entrata(bb, a)
					if c >= 9999.0:
						continue
					var nd := dist[a] + c
					if nd < dist[bb] - 0.01:
						dist[bb] = nd
						var kb := int(round(nd * 2.0))
						if not secchi.has(kb):
							secchi[kb] = []
						secchi[kb].append(bb)
						massimo = maxi(massimo, kb)
			secchi.erase(k)
		k += 1
	campi[h] = dist
	return dist

func _costo_entrata(da: int, a: int) -> float:
	for e in _archi[da]:
		if e[0] == a:
			return e[1]
	return 9999.0

func _posti(o: Dictionary) -> Array:
	if o.has("h"):
		return o["h"]
	var c: String = o["c"]
	var r := int(o.get("r", 1))
	var lista := []
	for h in Mappa.esagoni:
		var d := Mappa.distanza(h, c)
		if d <= r and Mappa.terreno(h) != "lago":
			lista.append([d, h])
	lista.sort()
	var out := []
	for x in lista:
		out.append(x[1])
		out.append(x[1])
	return out

## Avanza di un turno. Restituisce {"percorsi": {id: [esagoni]}, "attacchi": [[da, a, lato]]}
func passo(anima := true) -> Dictionary:
	turno += 1
	m.s["turno"] = turno
	var out := {"percorsi": {}, "attacchi": []}
	# arrivi
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if u["st"] == "arrivo" and int(u["t"]) <= turno:
			u["st"] = "mappa"
			u["h"] = str(u["e"]).split("|")[0]
			out["percorsi"][id] = [u["h"]]
	for c in m.s["capi"]:
		var k: Dictionary = m.s["capi"][c]
		if k["st"] == "arrivo" and int(k["t"]) <= turno:
			k["st"] = "mappa"
			k["h"] = str(k["e"]).split("|")[0]
	var v := voce(turno)
	for p in v.get("perdite", []):
		if p.get("prima", false):
			_perdita(p)
	_rifai_occ()
	# nuovi ordini, nell'ordine scritto (chi si ritira libera il posto a chi avanza)
	var sequenza := []
	for o in v.get("ordini", []):
		ordini[o["g"]] = o
		sequenza.append(o["g"])
	for g in ordini:
		if not sequenza.has(g):
			sequenza.push_front(g)
	for g in sequenza:
		_esegui(ordini[g], out["percorsi"])
		# gli ordini a una singola unità valgono un turno: poi torna agli ordini del suo corpo
		if m.s["unita"].has(g):
			ordini.erase(g)
	# attacchi (solo da mostrare)
	for a in v.get("attacchi", []):
		var su: String = a["su"]
		var visti := {}
		for id in membri(a["da"]):
			var h: String = m.s["unita"][id]["h"]
			if visti.has(h) or Mappa.distanza(h, su) > 2 or h == su:
				continue
			visti[h] = true
			out["attacchi"].append([h, su, m.lato_di(id)])
	# perdite
	for p in v.get("perdite", []):
		if not p.get("prima", false):
			_perdita(p)
	# capi: comandanti dove dice la storia, ufficiali al centro del proprio corpo
	for c in v.get("capi", []):
		ordini["capo:" + str(c["c"])] = c
	_muovi_capi(out["percorsi"])
	m._ricalcola()
	return out

func _perdita(p: Dictionary) -> void:
	if p.has("c"):
		if m.s["capi"].has(p["c"]):
			m.s["capi"][p["c"]]["st"] = "elim"
		return
	var lista := membri(p["g"])
	var n := int(p.get("n", lista.size()))
	lista.sort_custom(func(a, b): return _vicinanza_nemico(a) < _vicinanza_nemico(b))
	for i in mini(n, lista.size()):
		m.s["unita"][lista[i]]["st"] = "elim"
		var es := m.esercito(lista[i])
		m.s["perdite"][es] = int(m.s["perdite"][es]) + m.forza(lista[i])

func _vicinanza_nemico(id: String) -> int:
	var h: String = m.s["unita"][id]["h"]
	var best := 99
	for x in m.s["unita"]:
		if m.s["unita"][x]["st"] == "mappa" and m.lato_di(x) != m.lato_di(id):
			best = mini(best, Mappa.distanza(h, m.s["unita"][x]["h"]))
	return best

func _esegui(o: Dictionary, percorsi: Dictionary) -> void:
	if str(o.get("g", "")).begins_with("capo:") or o.has("c") and not o.has("g"):
		return
	var unita := membri(o["g"])
	if unita.is_empty():
		return
	var posti := _posti(o).duplicate()
	var ancora: String = o.get("c", posti[0])
	# assegnazione: i posti sono in ordine di importanza (prima il villaggio da prendere, poi il resto);
	# a ogni posto va l'unità libera più vicina
	var base := posti.duplicate()
	while posti.size() < unita.size() and not base.is_empty():
		posti.append_array(base)
	var libere := unita.duplicate()
	for meta in posti:
		if libere.is_empty():
			break
		var bi := 0
		var bd := 9999
		for i in libere.size():
			var d := Mappa.distanza(m.s["unita"][libere[i]]["h"], meta)
			if d < bd:
				bd = d
				bi = i
		var id: String = libere[bi]
		libere.remove_at(bi)
		_marcia(id, meta, ancora, percorsi)

## Occupazione aggiornata durante il passo (lo stato del motore si ricalcola alla fine)
var _occ := {}       # esagono -> [unità francesi, unità alleate]
func _rifai_occ() -> void:
	_occ = {}
	for id in m.s["unita"]:
		if m.s["unita"][id]["st"] == "mappa":
			_conta(m.s["unita"][id]["h"], m.lato_di(id), 1)

func _conta(h: String, lato: int, d: int) -> void:
	if not _occ.has(h):
		_occ[h] = [0, 0]
	_occ[h][lato] += d

func _nemico(h: String, lato: int) -> bool:
	return _occ.has(h) and int(_occ[h][1 - lato]) > 0

## La pedina marcia verso il suo posto: da lontano segue il campo dei costi della meta del gruppo
## (le strade), da vicino sceglie fra gli esagoni raggiungibili quello più vicino al posto.
func _marcia(id: String, meta: String, ancora: String, percorsi: Dictionary) -> void:
	var u: Dictionary = m.s["unita"][id]
	var h0: String = u["h"]
	if h0 == meta or not Mappa.esagoni.has(meta):
		return
	var lato := m.lato_di(id)
	var tp := m.tipo(id)
	var ma := float(m.cat(id)["ma"])
	# esagoni raggiungibili in questo turno (costi veri del tipo di unità, mai fra i nemici)
	var rg := {h0: [0.0, ""]}
	var coda := [h0]
	while not coda.is_empty():
		var a: String = coda.pop_front()
		for b in Mappa.vicini(a):
			if _nemico(b, lato):
				continue
			var c := m.costo_passo(a, b, tp, false)
			if c == INF:
				continue
			var nc: float = float(rg[a][0]) + c
			# almeno un esagono a turno si fa sempre (come nel gioco)
			if nc > ma and a != h0:
				continue
			if not rg.has(b) or nc < float(rg[b][0]) - 0.01:
				rg[b] = [nc, a]
				coda.append(b)
	var lontano := Mappa.distanza(h0, meta) > 5
	var cp := campo(ancora if lontano else meta)
	var best := h0
	var bv := INF
	for h in rg:
		var v := float(cp[_idx[h]]) * 10.0 + float(rg[h][0]) * 0.1
		if not lontano:
			v += float(Mappa.distanza(h, meta)) * 30.0
		if v < bv:
			bv = v
			best = h
	if best == h0:
		return
	var strada := [best]
	while strada[0] != h0:
		strada.push_front(rg[strada[0]][1])
	_conta(h0, lato, -1)
	_conta(best, lato, 1)
	u["h"] = best
	if percorsi.has(id):
		percorsi[id].append_array(strada.slice(1))
	else:
		percorsi[id] = strada

func _muovi_capi(percorsi: Dictionary) -> void:
	for c in m.s["capi"]:
		var k: Dictionary = m.s["capi"][c]
		if k["st"] != "mappa":
			continue
		var meta := ""
		if ordini.has("capo:" + c):
			meta = ordini["capo:" + c]["h"]
		elif int(m.catalogo["capi"][c]["cap"]) == 0:
			var somma := Vector2.ZERO
			var lista := []
			for id in m.s["unita"]:
				if m.s["unita"][id]["st"] == "mappa" and m.esercito(id) == m.catalogo["capi"][c]["es"] and str(m.cat(id)["c"]) == str(m.catalogo["capi"][c]["des"]):
					lista.append(id)
					somma += Mappa.pos(m.s["unita"][id]["h"])
			if lista.is_empty():
				continue
			var p := somma / float(lista.size())
			var bd := INF
			for id in lista:
				var d := Mappa.pos(m.s["unita"][id]["h"]).distance_to(p)
				if d < bd:
					bd = d
					meta = m.s["unita"][id]["h"]
		if meta == "" or meta == k["h"]:
			continue
		# i capi vanno veloci (a cavallo): fino a 3 tratte di marcia per turno
		var cp := campo(meta)
		var h: String = k["h"]
		var strada := [h]
		var speso := 0.0
		var guard := 0
		while h != meta and guard < 60:
			guard += 1
			var best := ""
			var bv: float = cp[_idx[h]]
			for n in Mappa.vicini(h):
				if cp[_idx[n]] < bv - 0.01 and not _nemico(n, m.lato_di(c)):
					bv = cp[_idx[n]]
					best = n
			if best == "":
				break
			speso += m.costo_passo(h, best, "C", false)
			if speso > 12.0:
				break
			h = best
			strada.append(h)
		k["h"] = h
		percorsi[c] = strada

## Riporta la storia al turno t ricominciando da capo (senza animazioni)
func vai_a(t: int) -> void:
	m.nuova({"scen": "campagna", "seed": 1})
	turno = -1
	ordini = {}
	for i in t + 1:
		passo(false)
