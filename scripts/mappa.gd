## La mappa della campagna: le quattro mappe dei Folio unite sulla griglia comune (57 colonne x 67 righe).
## Esagoni con terreno e mappa di provenienza, lati con corsi d'acqua, creste, strade e sentieri.
class_name Mappa
extends RefCounted

static var esagoni := {}
static var lati := {}
static var larg := 4293.0
static var alt := 5809.0
static var DX := 73.78
static var DY := 85.06
static var tasselli := [2147, 2905]
static var _vic := {}
static var quote := {}         # mappa ridisegnata: c cresta, e paese, f fattoria
static var decorativi := []    # esagoni disegnati nelle mappe nuove ma fuori dal gioco
static var tasselli_nuova := []   # [{file, zona [x0,y0,x1,y1], tex [x0,y0,x1,y1]}] in pixel della mappa

static func carica() -> void:
	if not esagoni.is_empty():
		return
	var f := FileAccess.open("res://assets/mappa/mappa.json", FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	esagoni = d["esagoni"]
	lati = d["lati"]
	larg = float(d["larg"])
	alt = float(d["alt"])
	DX = float(d["DX"])
	DY = float(d["DY"])
	tasselli = d["tasselli"]
	if d.has("nuova"):
		quote = d["nuova"]["quote"]
		decorativi = d["nuova"]["decorativi"]
		tasselli_nuova = d["nuova"]["tasselli"]
	for k in esagoni:
		var v := []
		for n in _intorno(k):
			if esagoni.has(n):
				v.append(n)
		_vic[k] = v

## Centro di un esagono qualsiasi della griglia (anche fuori dal gioco), in pixel della mappa
static func pos_griglia(k: String) -> Vector2:
	var c := int(k.substr(0, 2))
	var r := int(k.substr(2, 2))
	return Vector2(0.6 * DX + c * DX, 0.4 * DY + (r + (0.5 if c % 2 == 0 else 0.0)) * DY)

static func col(h: String) -> int:
	return int(h.substr(0, 2))

static func riga(h: String) -> int:
	return int(h.substr(2, 2))

static func nome_hex(c: int, r: int) -> String:
	return "%02d%02d" % [c, r]

## I sei esagoni attorno (anche fuori mappa), in ordine: N, NE, SE, S, SO, NO
static func _intorno(h: String) -> Array:
	var c := col(h)
	var r := riga(h)
	var d: Array
	if c % 2 == 1:
		d = [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 0], [-1, -1]]
	else:
		d = [[0, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
	var out := []
	for x in d:
		out.append(nome_hex(c + x[0], r + x[1]))
	return out

static func esiste(h: String) -> bool:
	return esagoni.has(h)

static func vicini(h: String) -> Array:
	return _vic.get(h, [])

static func adiacenti(a: String, b: String) -> bool:
	return b in _vic.get(a, [])

static func terreno(h: String) -> String:
	return esagoni[h]["t"]

static func pos(h: String) -> Vector2:
	var e: Dictionary = esagoni[h]
	return Vector2(e["x"], e["y"])

## Il nome sulla mappa originale: lettera della mappa e numero dell'esagono (es. B0617)
static func sigla(h: String) -> String:
	if not esagoni.has(h):
		return h
	return "%s%s" % [esagoni[h]["m"], esagoni[h]["l"]]

static func lato(a: String, b: String) -> String:
	if a < b:
		return lati.get(a + "-" + b, "")
	return lati.get(b + "-" + a, "")

## Fiume (Dyle): si passa solo dai ponti
static func fiume(a: String, b: String) -> bool:
	return lato(a, b).begins_with("F")

static func ponte(a: String, b: String) -> bool:
	return lato(a, b).contains("p")

static func ruscello(a: String, b: String) -> bool:
	return lato(a, b).begins_with("T") and not lato(a, b).contains("p")

static func acqua(a: String, b: String) -> bool:
	var l := lato(a, b)
	return l.begins_with("T") or l.begins_with("F")

static func cresta(a: String, b: String) -> bool:
	return lato(a, b).contains("c")

static func strada(a: String, b: String) -> bool:
	return lato(a, b).contains("r")

static func sentiero(a: String, b: String) -> bool:
	return lato(a, b).contains("s")

static func passabile(a: String, b: String) -> bool:
	if fiume(a, b) and not ponte(a, b):
		return false
	var t := terreno(b)
	return t != "lago"

## Coordinate cubiche (colonne pari spostate in basso)
static func cubo(h: String) -> Vector2i:
	var c := col(h)
	var r := riga(h)
	return Vector2i(c, r - int((c + (c & 1)) / 2))

static func distanza(a: String, b: String) -> int:
	var p := cubo(a)
	var q := cubo(b)
	var dq := q.x - p.x
	var dr := q.y - p.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2)

static func entro(h: String, raggio: int) -> Array:
	var out := []
	var c := col(h)
	var r := riga(h)
	for dc in range(-raggio, raggio + 1):
		for dr in range(-raggio - 1, raggio + 2):
			var k := nome_hex(c + dc, r + dr)
			if esagoni.has(k) and distanza(h, k) <= raggio:
				out.append(k)
	return out

## Esagono che contiene un punto (pixel della mappa)
static func esagono_in(p: Vector2) -> String:
	var c0 := int(round((p.x - DX * 0.6) / DX))
	var best := ""
	var bd := INF
	for c in [c0 - 1, c0, c0 + 1]:
		var r0 := int(round((p.y - DY * 0.4) / DY - (0.5 if c % 2 == 0 else 0.0)))
		for r in [r0 - 1, r0, r0 + 1]:
			var k := nome_hex(c, r)
			if esagoni.has(k):
				var d := pos(k).distance_to(p)
				if d < bd:
					bd = d
					best = k
	return best if bd < DY * 0.62 else ""
