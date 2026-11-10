## Napoleon's Last Battles — interfaccia: mappa 3D delle quattro battaglie con le pedine originali,
## menu, scelta dello scenario, pannelli di movimento e combattimento, plance dei corpi, partita online.
extends Node

const F_TITOLO_B := preload("res://assets/font/OldStandard-Bold.ttf")
const F_BASE := preload("res://assets/font/OldStandard-Regular.ttf")
const F_CORSIVO := preload("res://assets/font/OldStandard-Italic.ttf")

const C_CARTA := Color(0.95, 0.91, 0.82)
const C_CARTA_SCURA := Color(0.87, 0.81, 0.69)
const C_INCHIOSTRO := Color(0.13, 0.11, 0.12)
const C_BLU := Color(0.12, 0.18, 0.38)
const C_BLU_SCURO := Color(0.06, 0.08, 0.17)
const C_ROSSO := Color(0.66, 0.11, 0.1)
const C_ORO := Color(0.86, 0.7, 0.34)
const C_SPENTO := Color(0.42, 0.38, 0.36)
const COL_LATO := [Color(0.26, 0.45, 0.85), Color(0.75, 0.16, 0.12)]
const SALVA_LOCALE := "user://partita_napoleonlb.json"
const SC := 0.01
const SCENARI := ["ligny", "quatrebras", "wavre", "bellealliance", "campagna"]

var F_TESTO: Font
var F_GRASSETTO: Font
var F_TITOLO: Font

var ui: CanvasLayer
var schermo: Control
var net: Rete
var m: Motore
var ia: Array = []

var mondo: Node3D
var cam: Camera3D
var nodo_pezzi: Node3D
var nodo_evid: Node3D
var bersaglio_cam := Vector3(20, 0, 30)
var distanza := 18.0
var yaw := 0.0
var pitch := -1.1
var trascina := 0
var mouse_prec := Vector2.ZERO
var mouse_giu := Vector2.ZERO
var tocchi := {}
var due_dita := false
var cache_tex := {}
var cache_mat := {}

var in_partita := false
var umani := [true, false]
var online := false
var codice := ""
var mio_posto := 0
var posti_lati := [0, -1]
var attesa := 0.0
var velocita := 1.0
var aspetto_rete := false
var invio_in_corso := false
var salvataggio_in_corso := false
var ultimo_salvataggio := 0.0
var popup: Control
var popup_aperto := false
var coda_rapporti: Array = []
# battaglia mostrata nel pannello in basso (tabella animata)
var batt_pannello: PanelContainer
var batt_rep: Dictionary = {}
var batt_aperta := false
var batt_pre := false         # pedine ancora nelle posizioni di prima del combattimento
var batt_gen := 0             # cambia quando l'animazione va interrotta
var batt_celle: Array = []    # [riga][colonna]
var batt_righe: Array = []    # intestazioni delle righe (dado)
var batt_colonne: Array = []  # intestazioni delle colonne (rapporto)
var batt_dado: Dado
var batt_lbl_ris: Label
var batt_lbl_dett: Label
var batt_bottoni: HBoxContainer
var sel_avanza := ""
var salta_fase := ""          # turno|lato: combattimenti dell'IA mostrati solo nel registro
var carattere_ia := 1

# selezione
var sel_hex := ""
var sel_unita := ""
var sel_capo := ""
var rag := {}
var hover := ""
var sel_dif: Array = []
var sel_att := {}
var sel_col := -1
var vista_alta := false

# scelte del menu
var scelta_scen := "bellealliance"
var scelta_lato := 0
var scelta_modo := "ia"
var opz_armi := true
var opz_guardia := true
var opz_opzionali := false

# interfaccia
var lbl_titolo: Label
var lbl_data: Label
var lbl_fase: Label
var lbl_pv: Label
var pannello_info: VBoxContainer
var scroll_info: ScrollContainer
var box_azioni: VBoxContainer
var lbl_stato: Label
var diario: RichTextLabel
var pannello_diario: PanelContainer
var tip: PanelContainer
var tip_lbl: Label
var notifica: VBoxContainer
var on_nome: LineEdit
var on_codice: LineEdit
var on_stato: Label
var on_lato: OptionButton
var on_scen: OptionButton
var lobby_box: VBoxContainer

func _ready() -> void:
	F_TESTO = F_BASE
	F_GRASSETTO = F_TITOLO_B
	var fv := FontVariation.new()
	fv.base_font = F_TITOLO_B
	fv.spacing_glyph = 1
	F_TITOLO = fv
	Mappa.carica()
	Motore.carica_catalogo()
	_costruisci_mondo()
	ui = CanvasLayer.new()
	add_child(ui)
	schermo = Control.new()
	schermo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schermo.theme = _tema()
	ui.add_child(schermo)
	net = Rete.new()
	add_child(net)
	mostra_menu()

# =============================================================================================
# Stile

func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_TESTO
	t.default_font_size = 20
	var bn := stile(C_CARTA, C_BLU, 2, 3)
	var bh := stile(Color(1.0, 0.97, 0.89), C_ROSSO, 2, 3)
	var bp := stile(C_CARTA_SCURA, C_ROSSO, 3, 3)
	var bd := stile(Color(0.78, 0.74, 0.68, 0.7), Color(0.45, 0.42, 0.4), 1, 3)
	for k in [["normal", bn], ["hover", bh], ["pressed", bp], ["disabled", bd], ["focus", stile(Color(0, 0, 0, 0), C_ROSSO, 2, 3)]]:
		t.set_stylebox(k[0], "Button", k[1])
	t.set_font("font", "Button", F_GRASSETTO)
	t.set_color("font_color", "Button", C_BLU_SCURO)
	t.set_color("font_hover_color", "Button", C_ROSSO)
	t.set_color("font_pressed_color", "Button", C_ROSSO)
	t.set_color("font_hover_pressed_color", "Button", C_ROSSO)
	t.set_color("font_disabled_color", "Button", Color(0.42, 0.4, 0.38))
	t.set_color("font_color", "Label", C_INCHIOSTRO)
	t.set_stylebox("normal", "LineEdit", stile(Color(1, 0.98, 0.93), C_INCHIOSTRO, 2, 3))
	t.set_color("font_color", "LineEdit", C_INCHIOSTRO)
	t.set_stylebox("panel", "PanelContainer", stile(C_CARTA, C_BLU, 2, 4))
	t.set_color("default_color", "RichTextLabel", C_INCHIOSTRO)
	t.set_stylebox("normal", "OptionButton", bn)
	t.set_stylebox("hover", "OptionButton", bh)
	t.set_stylebox("pressed", "OptionButton", bp)
	t.set_color("font_color", "OptionButton", C_BLU_SCURO)
	t.set_stylebox("panel", "PopupMenu", stile(C_CARTA, C_INCHIOSTRO, 2, 3))
	t.set_color("font_color", "PopupMenu", C_INCHIOSTRO)
	t.set_color("font_hover_color", "PopupMenu", C_ROSSO)
	t.set_stylebox("hover", "PopupMenu", stile(Color(1.0, 0.95, 0.85), Color(0, 0, 0, 0), 0, 2))
	t.set_color("font_color", "CheckBox", C_INCHIOSTRO)
	t.set_color("font_hover_color", "CheckBox", C_ROSSO)
	t.set_color("font_pressed_color", "CheckBox", C_INCHIOSTRO)
	t.set_color("font_hover_pressed_color", "CheckBox", C_ROSSO)
	return t

func stile(bg: Color, bordo := Color(0, 0, 0, 0), spessore := 0, raggio := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func etichetta(testo: String, font: Font = null, size := 20, col := C_INCHIOSTRO) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", font if font != null else F_TESTO)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func riga_lbl(testo: String, font: Font = null, size := 20, col := C_INCHIOSTRO) -> Label:
	var l := etichetta(testo, font, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

func bottone(testo: String, cb: Callable, size := 18, larg := 0.0) -> Button:
	var b := Button.new()
	b.text = testo
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	if larg > 0:
		b.custom_minimum_size.x = larg
	return b

func pannello(bg := C_CARTA, bordo := C_BLU) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stile(bg, bordo, 2, 5))
	return p

func tex(path: String) -> Texture2D:
	if not cache_tex.has(path):
		cache_tex[path] = load(path)
	return cache_tex[path]

func immagine(path: String, w: float, h: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(w, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func img_pedina(id: String, ridotta := false) -> String:
	if ridotta and ResourceLoader.exists("res://assets/pedine/%sr.webp" % id):
		return "res://assets/pedine/%sr.webp" % id
	return "res://assets/pedine/%s.webp" % id

func pulisci() -> void:
	for c in schermo.get_children():
		c.queue_free()
	in_partita = false
	popup = null
	popup_aperto = false
	coda_rapporti.clear()
	batt_aperta = false
	batt_rep = {}
	batt_pannello = null

# =============================================================================================
# Mondo 3D

func _costruisci_mondo() -> void:
	mondo = Node3D.new()
	add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.06, 0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.95, 0.9, 0.82)
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	mondo.add_child(env)
	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-58, 35, 0)
	luce.light_energy = 0.8
	luce.light_color = Color(1.0, 0.95, 0.86)
	luce.shadow_enabled = true
	luce.directional_shadow_max_distance = 26.0
	mondo.add_child(luce)
	cam = Camera3D.new()
	cam.fov = 40
	cam.far = 250
	mondo.add_child(cam)
	var lx := Mappa.larg * SC
	var lz := Mappa.alt * SC
	# tavolo di legno scuro
	var tav := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(lx * 3.5, lz * 3)
	tav.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.16, 0.1, 0.07)
	mt.roughness = 0.85
	tav.material_override = mt
	tav.position = Vector3(lx / 2, -0.07, lz / 2)
	mondo.add_child(tav)
	var bordo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lx + 0.3, 0.06, lz + 0.3)
	bordo.mesh = bm
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.1, 0.13, 0.27)
	bordo.material_override = mb
	bordo.position = Vector3(lx / 2, -0.032, lz / 2)
	mondo.add_child(bordo)
	# le quattro mappe originali, unite (in quattro tasselli per le texture)
	var tw: float = float(Mappa.tasselli[0])
	var th: float = float(Mappa.tasselli[1])
	for j in 2:
		for i in 2:
			var w: float = minf(tw, Mappa.larg - i * tw)
			var h: float = minf(th, Mappa.alt - j * th)
			var mp := MeshInstance3D.new()
			var pq := PlaneMesh.new()
			pq.size = Vector2(w * SC, h * SC)
			mp.mesh = pq
			var mm := StandardMaterial3D.new()
			mm.albedo_texture = _con_mipmap("res://assets/mappa/mappa_%d%d.webp" % [j, i])
			mm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mp.material_override = mm
			mp.position = Vector3((i * tw + w / 2) * SC, 0, (j * th + h / 2) * SC)
			mondo.add_child(mp)
	nodo_evid = Node3D.new()
	mondo.add_child(nodo_evid)
	nodo_pezzi = Node3D.new()
	mondo.add_child(nodo_pezzi)
	_aggiorna_camera()

func _con_mipmap(path: String) -> Texture2D:
	var t: Texture2D = load(path)
	var img := t.get_image()
	if img == null:
		return t
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _centra_su(h: String, d := -1.0) -> void:
	if h == "" or not Mappa.esiste(h):
		return
	var p := Mappa.pos(h)
	bersaglio_cam = Vector3(p.x * SC, 0, p.y * SC)
	if d > 0:
		distanza = d
	_aggiorna_camera()

func _aggiorna_camera() -> void:
	pitch = clampf(pitch, -1.53, -0.42)
	distanza = clampf(distanza, 2.2, 60.0)
	bersaglio_cam.x = clampf(bersaglio_cam.x, 0, Mappa.larg * SC)
	bersaglio_cam.z = clampf(bersaglio_cam.z, 0, Mappa.alt * SC)
	var dir := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))
	cam.position = bersaglio_cam + dir * distanza
	cam.look_at(bersaglio_cam, Vector3.UP)

func _v3(h: String, alt := 0.0) -> Vector3:
	var p := Mappa.pos(h)
	return Vector3(p.x * SC, alt, p.y * SC)

func _mat_img(path: String) -> StandardMaterial3D:
	if cache_mat.has(path):
		return cache_mat[path]
	var mt := StandardMaterial3D.new()
	mt.albedo_texture = _con_mipmap(path)
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cache_mat[path] = mt
	return mt

func _mat_colore(c: Color, trasp := false, senza_luce := false) -> StandardMaterial3D:
	var k := "%s|%s|%s" % [c.to_html(), trasp, senza_luce]
	if cache_mat.has(k):
		return cache_mat[k]
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	if trasp:
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if senza_luce:
		mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cache_mat[k] = mt
	return mt

const LATO_PEDINA := 0.52
const SPESSORE := 0.05

## Una pedina di cartone: lati del colore della nazione, faccia con l'immagine originale
func _pedina(path: String, colore: Color, lato := LATO_PEDINA) -> Node3D:
	var n := Node3D.new()
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lato, SPESSORE, lato)
	base.mesh = bm
	base.material_override = _mat_colore(colore.darkened(0.3))
	base.position.y = SPESSORE / 2
	n.add_child(base)
	var faccia := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(lato, lato)
	faccia.mesh = q
	faccia.material_override = _mat_img(path)
	faccia.position.y = SPESSORE + 0.0015
	n.add_child(faccia)
	return n

func _colore_unita(id: String) -> Color:
	return Dati.NAZ.get(Motore.catalogo["unita"][id]["naz"], {}).get("col", Color.GRAY) if id.begins_with("u") else (COL_LATO[0] if Motore.catalogo["capi"][id]["es"] == "FR" else COL_LATO[1])

func _aggiorna_pezzi() -> void:
	for c in nodo_pezzi.get_children():
		c.queue_free()
	if m == null:
		return
	var esagoni := {}
	var forzati: Dictionary = batt_rep.get("pos", {}) if (batt_aperta and batt_pre) else {}
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		var hu := ""
		if forzati.has(id):
			hu = forzati[id]
		elif u["st"] == "mappa":
			hu = u["h"]
		if hu != "":
			if not esagoni.has(hu):
				esagoni[hu] = []
			esagoni[hu].append(id)
	for id in m.s["capi"]:
		var c: Dictionary = m.s["capi"][id]
		if c["st"] == "mappa" and c["h"] != "":
			if not esagoni.has(c["h"]):
				esagoni[c["h"]] = []
			esagoni[c["h"]].append(id)
	for h in esagoni:
		var lista: Array = esagoni[h]
		# prima le unità, poi i capi sopra
		lista.sort_custom(func(a, b): return a.begins_with("u") and b.begins_with("c"))
		var pila := Node3D.new()
		pila.position = _v3(h)
		nodo_pezzi.add_child(pila)
		var i := 0
		for id in lista:
			var capo: bool = id.begins_with("c")
			var path: String = img_pedina(id, (not capo) and m.s["unita"][id]["rid"])
			var p := _pedina(path, _colore_unita(id), LATO_PEDINA * (0.82 if capo else 1.0))
			p.position = Vector3(i * 0.05, i * (SPESSORE + 0.004), -i * 0.05)
			if not capo:
				var u: Dictionary = m.s["unita"][id]
				if u["mosso"] or u["att"]:
					p.position.y += 0.0
				# segno di unità che ha già agito: un filo di luce sotto
			pila.add_child(p)
			i += 1
		# segnalini di stato
		var demo := false
		var ooc := false
		for id in lista:
			if id.begins_with("u"):
				if m.dem_unita(id):
					demo = true
				if m.campagna() and m.lato_di(id) == int(m.s["lato"]) and not m.in_comando(id) and not m.notte():
					ooc = true
		if demo or ooc:
			var lb := Label3D.new()
			lb.text = ("D" if demo else "") + (" FC" if ooc else "")
			lb.font = F_TITOLO_B
			lb.font_size = 56
			lb.pixel_size = 0.004
			lb.outline_size = 12
			lb.modulate = Color(1, 0.95, 0.85)
			lb.outline_modulate = C_ROSSO.darkened(0.3)
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lb.no_depth_test = true
			lb.position = Vector3(-0.22, i * (SPESSORE + 0.004) + 0.1, 0.22)
			pila.add_child(lb)

# ---------- evidenziazioni

func _esagono_mesh(colore: Color, raggio := 0.42, alt := 0.004) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raggio
	cm.bottom_radius = raggio
	cm.height = alt
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _mat_colore(colore, colore.a < 1.0, true)
	return mi

func _anello(colore: Color, r := 0.44) -> Node3D:
	var n := Node3D.new()
	for i in 6:
		var a := deg_to_rad(i * 60)
		var b := deg_to_rad((i + 1) * 60)
		var pa := Vector3(cos(a) * r, 0.012, sin(a) * r)
		var pb := Vector3(cos(b) * r, 0.012, sin(b) * r)
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(pa.distance_to(pb), 0.014, 0.05)
		seg.mesh = bm
		seg.material_override = _mat_colore(colore, false, true)
		seg.position = (pa + pb) / 2
		seg.rotation.y = -atan2(pb.z - pa.z, pb.x - pa.x)
		n.add_child(seg)
	return n

## Freccia piatta dall'esagono da all'esagono a, disegnata sopra le pedine (con un bordo scuro)
func _freccia(da: String, a: String, colore: Color, tratteggiata := false) -> Node3D:
	var p0 := _v3(da)
	var p1 := _v3(a)
	var dir := p1 - p0
	var lung := dir.length()
	var n := Node3D.new()
	if lung < 0.01:
		return n
	n.position = p0 + Vector3(0, 0.2, 0)
	n.rotation.y = -atan2(dir.z, dir.x)
	var ini := 0.16
	var fin := lung - 0.14
	n.add_child(_mesh_freccia(ini - 0.02, fin + 0.035, 0.26, 0.085, 0.2, colore.darkened(0.65), tratteggiata, 10))
	n.add_child(_mesh_freccia(ini, fin, 0.22, 0.055, 0.155, colore, tratteggiata, 11))
	return n

func _mesh_freccia(ini: float, fin: float, punta: float, mezza: float, mezza_punta: float, colore: Color, tratt: bool, prio: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corpo_fin := fin - punta
	var tratti := []
	if tratt:
		var x := ini
		while x < corpo_fin:
			tratti.append([x, minf(x + 0.12, corpo_fin)])
			x += 0.2
	else:
		tratti.append([ini, corpo_fin])
	for tr in tratti:
		var x0: float = tr[0]
		var x1: float = tr[1]
		st.add_vertex(Vector3(x0, 0, -mezza))
		st.add_vertex(Vector3(x1, 0, -mezza))
		st.add_vertex(Vector3(x1, 0, mezza))
		st.add_vertex(Vector3(x0, 0, -mezza))
		st.add_vertex(Vector3(x1, 0, mezza))
		st.add_vertex(Vector3(x0, 0, mezza))
	st.add_vertex(Vector3(corpo_fin, 0, -mezza_punta))
	st.add_vertex(Vector3(fin, 0, 0))
	st.add_vertex(Vector3(corpo_fin, 0, mezza_punta))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var k := "freccia|%s|%d" % [colore.to_html(), prio]
	if not cache_mat.has(k):
		var mt := StandardMaterial3D.new()
		mt.albedo_color = colore
		mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mt.cull_mode = BaseMaterial3D.CULL_DISABLED
		mt.no_depth_test = true
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mt.render_priority = prio
		cache_mat[k] = mt
	mi.material_override = cache_mat[k]
	return mi

## Frecce di un attacco: dagli esagoni degli attaccanti a quello difeso (tratteggiate per il bombardamento)
func _frecce_attacco(att: Array, dif: Array, pos: Dictionary, colore: Color) -> void:
	var fatte := {}
	for id in att:
		var h: String = pos.get(id, m.s["unita"][id]["h"])
		if h == "":
			continue
		var bersaglio := ""
		var bomb := true
		for d in dif:
			if Mappa.adiacenti(h, d):
				bersaglio = d
				bomb = false
				break
		if bersaglio == "":
			var bd := 99
			for d in dif:
				var dd := Mappa.distanza(h, d)
				if dd < bd:
					bd = dd
					bersaglio = d
		var k := h + ">" + bersaglio
		if bersaglio == "" or fatte.has(k):
			continue
		fatte[k] = true
		nodo_evid.add_child(_freccia(h, bersaglio, Color(0.95, 0.68, 0.12) if bomb else colore, bomb))

func _aggiorna_evidenze() -> void:
	for c in nodo_evid.get_children():
		c.queue_free()
	if m == null:
		return
	for h in rag:
		var e := _esagono_mesh(Color(0.25, 0.8, 0.3, 0.36))
		e.position = _v3(h, 0.006)
		nodo_evid.add_child(e)
	if _fase_mia("movimento") and sel_unita != "" and m.s["unita"].has(sel_unita):
		for h in rag:
			if m.uscita_valida(sel_unita, h):
				var a := _anello(Color(0.95, 0.75, 0.1))
				a.position = _v3(h)
				nodo_evid.add_child(a)
	if sel_hex != "":
		var a := _anello(C_ORO)
		a.position = _v3(sel_hex)
		nodo_evid.add_child(a)
	if _fase_mia("combattimento"):
		var ob := m.obblighi()
		for h in ob["nemici"]:
			if not sel_dif.has(h):
				var e := _esagono_mesh(Color(0.95, 0.55, 0.1, 0.3))
				e.position = _v3(h, 0.007)
				nodo_evid.add_child(e)
		for h in sel_dif:
			var e := _esagono_mesh(Color(0.9, 0.08, 0.05, 0.45))
			e.position = _v3(h, 0.008)
			nodo_evid.add_child(e)
		for id in sel_att:
			var hh: String = m.s["unita"][id]["h"]
			var a := _anello(Color(0.2, 0.35, 0.95))
			a.position = _v3(hh)
			nodo_evid.add_child(a)
		if not sel_dif.is_empty():
			_frecce_attacco(sel_att.keys(), sel_dif, {}, Color(0.86, 0.12, 0.06))
	var rq := m.richiesta()
	if rq.get("k", "") == "avanza" and not batt_pre:
		for c in rq["cand"]:
			var e := _esagono_mesh(Color(0.2, 0.5, 0.95, 0.4))
			e.position = _v3(c[1], 0.008)
			nodo_evid.add_child(e)
			if _fase_mia("avanza"):
				# le unità che possono avanzare: anello d'oro, più marcato per quella scelta
				var hu: String = m.s["unita"][c[0]]["h"]
				var an := _anello(Color(1, 0.85, 0.2) if c[0] != sel_avanza else Color(1, 1, 1), 0.46)
				an.position = _v3(hu)
				nodo_evid.add_child(an)
				var an2 := _anello(C_ORO.darkened(0.2), 0.38)
				an2.position = _v3(hu)
				nodo_evid.add_child(an2)
				if c[0] == sel_avanza:
					nodo_evid.add_child(_freccia(hu, c[1], Color(0.2, 0.5, 0.95)))
	if batt_aperta and not batt_rep.is_empty():
		var pos: Dictionary = batt_rep.get("pos", {})
		for h in batt_rep["dif_hex"]:
			var e := _esagono_mesh(Color(0.9, 0.08, 0.05, 0.42))
			e.position = _v3(h, 0.008)
			nodo_evid.add_child(e)
		if batt_pre:
			_frecce_attacco(batt_rep["att"], batt_rep["dif_hex"], pos, Color(0.86, 0.12, 0.06))
	if hover != "" and hover != sel_hex:
		var a := _anello(Color(1, 1, 1, 1), 0.42)
		a.position = _v3(hover)
		nodo_evid.add_child(a)

# ---------- input sulla mappa (mouse e tocco: un dito sposta, due dita pizzicano e ruotano)

func _esagono_sotto(pos: Vector2) -> String:
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	if absf(d.y) < 0.0001:
		return ""
	var t := -o.y / d.y
	if t < 0:
		return ""
	var p := o + d * t
	return Mappa.esagono_in(Vector2(p.x / SC, p.z / SC))

func _unhandled_input(ev: InputEvent) -> void:
	if not in_partita or popup_aperto:
		return
	if ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			tocchi[st.index] = st.position
		else:
			tocchi.erase(st.index)
		due_dita = tocchi.size() >= 2
		if due_dita:
			trascina = 0
		return
	if ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		if tocchi.size() >= 2 and tocchi.has(sd.index):
			var ids: Array = tocchi.keys()
			var altro: int = ids[1] if ids[0] == sd.index else ids[0]
			var a0: Vector2 = tocchi[sd.index]
			var b0: Vector2 = tocchi[altro]
			var a1: Vector2 = sd.position
			var d0 := a0.distance_to(b0)
			var d1 := a1.distance_to(b0)
			if d0 > 10 and d1 > 10:
				distanza = clampf(distanza * d0 / d1, 2.2, 60.0)
			var ang := (a1 - b0).angle() - (a0 - b0).angle()
			yaw -= wrapf(ang, -PI, PI)
			# il punto medio che scorre sposta la mappa
			_sposta((a1 - a0) * 0.5)
			tocchi[sd.index] = a1
			_aggiorna_camera()
		elif tocchi.has(sd.index):
			tocchi[sd.index] = sd.position
		return
	if due_dita and (ev is InputEventMouseMotion or ev is InputEventMouseButton):
		if ev is InputEventMouseButton and not (ev as InputEventMouseButton).pressed:
			trascina = 0
			if tocchi.size() < 2:
				due_dita = false
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distanza *= 0.9
			_aggiorna_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distanza *= 1.1
			_aggiorna_camera()
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if mb.pressed:
				trascina = mb.button_index
				mouse_prec = mb.position
				mouse_giu = mb.position
			else:
				if mb.button_index == MOUSE_BUTTON_LEFT and mb.position.distance_to(mouse_giu) < 10:
					_clic(_esagono_sotto(mb.position))
				elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.position.distance_to(mouse_giu) < 8:
					_annulla_selezione()
					_aggiorna_tutto()
				trascina = 0
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if trascina == MOUSE_BUTTON_LEFT and mm.position.distance_to(mouse_giu) > 10:
			_sposta(mm.position - mouse_prec)
		elif trascina == MOUSE_BUTTON_RIGHT or trascina == MOUSE_BUTTON_MIDDLE:
			yaw -= (mm.position - mouse_prec).x * 0.006
			pitch -= (mm.position - mouse_prec).y * 0.004
			_aggiorna_camera()
		mouse_prec = mm.position
		var h := _esagono_sotto(mm.position)
		if h != hover:
			hover = h
			_aggiorna_evidenze()
			_mostra_tip(h, mm.position)
		elif h != "" and tip != null:
			tip.position = mm.position + Vector2(22, 22)
	elif ev is InputEventMagnifyGesture:
		distanza /= (ev as InputEventMagnifyGesture).factor
		_aggiorna_camera()
	elif ev is InputEventPanGesture:
		_sposta(-(ev as InputEventPanGesture).delta * 8.0)

func _sposta(d: Vector2) -> void:
	var f := distanza * 0.0011
	var dx := Vector3(cos(yaw), 0, -sin(yaw))
	var dz := Vector3(sin(yaw), 0, cos(yaw))
	bersaglio_cam -= dx * d.x * f + dz * d.y * f
	_aggiorna_camera()

func _mostra_tip(h: String, pos: Vector2) -> void:
	if tip == null:
		return
	if h == "" or m == null:
		tip.visible = false
		return
	var righe := ["%s — %s" % [Mappa.sigla(h), Dati.NOMI_TERRENO.get(Mappa.terreno(h), "")]]
	for l in [0, 1]:
		var ids := m.unita_in(h, l)
		if not ids.is_empty():
			righe.append("%s: %s" % [Dati.LATI_BREVI[l], ", ".join(ids.map(func(x): return "%s %d-%d" % [m.nome(x), m.forza(x), m.ma(x)]))])
		var cp := m.capi_in(h, l)
		if not cp.is_empty():
			righe.append("   " + ", ".join(cp.map(func(x): return m.nome(x))))
	if rag.has(h):
		righe.append("Costo %s PM" % _num(rag[h]["c"]))
	tip_lbl.text = "\n".join(righe)
	tip.position = pos + Vector2(22, 22)
	tip.visible = true

func _num(x) -> String:
	var f := float(x)
	return str(int(f)) if f == floorf(f) else "%.1f" % f

# =============================================================================================
# Menu

func _sfondo() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.1, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	schermo.add_child(bg)

func _scheda_centrale(w: float, h: float) -> VBoxContainer:
	var box := pannello()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(w, h)
	box.position = Vector2(-w / 2.0, -h / 2.0)
	box.add_theme_stylebox_override("panel", stile(C_CARTA, C_BLU, 5, 6))
	schermo.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	return v

func _intestazione(v: VBoxContainer, titolo: String, sotto: String) -> void:
	var t := etichetta(titolo, F_TITOLO, 46, C_BLU)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := etichetta(sotto, F_CORSIVO, 24, C_ROSSO)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)

func mostra_menu() -> void:
	pulisci()
	m = null
	_aggiorna_pezzi_vuoti()
	bersaglio_cam = Vector3(Mappa.larg * SC / 2, 0, Mappa.alt * SC / 2)
	distanza = 46.0
	pitch = -1.0
	yaw = 0.3
	_aggiorna_camera()
	_sfondo()
	var box := pannello()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(1120, 720)
	box.position = Vector2(-560, -360)
	box.add_theme_stylebox_override("panel", stile(C_CARTA, C_BLU, 5, 6))
	schermo.add_child(box)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 26)
	box.add_child(hb)
	hb.add_child(immagine("res://assets/ui/copertina.webp", 440, 550))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	var t := etichetta("NAPOLEON'S\nLAST BATTLES", F_TITOLO, 52, C_BLU)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := etichetta("La campagna di Waterloo, 16-18 giugno 1815", F_CORSIVO, 25, C_ROSSO)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var s2 := etichetta("Ligny · Quatre Bras · Wavre · La Belle Alliance", F_GRASSETTO, 19, C_INCHIOSTRO)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s2)
	v.add_child(HSeparator.new())
	v.add_child(bottone("Nuova partita", _menu_nuova, 26))
	if FileAccess.file_exists(SALVA_LOCALE):
		v.add_child(bottone("Continua la partita salvata", _menu_continua, 22))
	v.add_child(bottone("Riprendi la partita salvata su Firebase", _continua_firebase, 20))
	v.add_child(bottone("Gioca online con un amico", _menu_online, 22))
	v.add_child(bottone("Le regole in breve", _menu_regole, 20))
	var nota := etichetta("Quadrigioco SPI del 1976 (Kevin Zucker), regole riviste. Versione digitale per uso personale, dal modulo Tabletop Simulator.", F_CORSIVO, 16, C_SPENTO)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func _aggiorna_pezzi_vuoti() -> void:
	for c in nodo_pezzi.get_children():
		c.queue_free()
	for c in nodo_evid.get_children():
		c.queue_free()

func _menu_nuova() -> void:
	pulisci()
	_sfondo()
	var v := _scheda_centrale(1300, 830)
	_intestazione(v, "Scegli la battaglia", "Quattro giochi in uno, e la campagna che li unisce")
	var schede := HBoxContainer.new()
	schede.add_theme_constant_override("separation", 10)
	v.add_child(schede)
	var g := ButtonGroup.new()
	var descr := etichetta("", F_TESTO, 18)
	for k in SCENARI:
		var sc: Dictionary = Motore.scenari[k]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		schede.add_child(col)
		col.add_child(immagine("res://assets/ui/%s.webp" % k, 240, 150))
		var b := Button.new()
		b.text = sc["titolo"]
		b.toggle_mode = true
		b.button_group = g
		b.custom_minimum_size = Vector2(240, 0)
		b.add_theme_font_size_override("font_size", 20)
		b.button_pressed = k == scelta_scen
		var kk: String = k
		b.pressed.connect(func():
			scelta_scen = kk
			descr.text = _descrizione_scenario(kk))
		col.add_child(b)
		col.add_child(riga_lbl(sc["data"], F_CORSIVO, 16, C_SPENTO))
	descr.text = _descrizione_scenario(scelta_scen)
	descr.custom_minimum_size.y = 110
	v.add_child(descr)
	v.add_child(HSeparator.new())
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 10)
	v.add_child(r)
	var opz := [["Comando i Francesi", "ia", 0], ["Comando gli Alleati", "ia", 1], ["Due giocatori qui", "due", 0], ["Guardo l'IA", "guarda", 0]]
	var gruppo := ButtonGroup.new()
	for o in opz:
		var b := Button.new()
		b.text = o[0]
		b.toggle_mode = true
		b.button_group = gruppo
		b.add_theme_font_size_override("font_size", 18)
		b.button_pressed = o[1] == scelta_modo and (o[1] != "ia" or o[2] == scelta_lato)
		b.pressed.connect(func():
			scelta_modo = o[1]
			scelta_lato = o[2])
		r.add_child(b)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 10)
	v.add_child(r2)
	r2.add_child(riga_lbl("Avversario:", F_GRASSETTO, 19))
	var g2 := ButtonGroup.new()
	for o in [["prudente", 0], ["normale", 1], ["aggressivo", 2]]:
		var b := Button.new()
		b.text = o[0]
		b.toggle_mode = true
		b.button_group = g2
		b.add_theme_font_size_override("font_size", 17)
		b.button_pressed = carattere_ia == o[1]
		b.pressed.connect(func(): carattere_ia = o[1])
		r2.add_child(b)
	var r3 := HBoxContainer.new()
	r3.add_theme_constant_override("separation", 20)
	v.add_child(r3)
	for o in [["Armi combinate (+1 colonna)", "armi"], ["Guardia imperiale", "guardia"], ["Rinforzi francesi opzionali (Quatre Bras)", "opz"]]:
		var cb := CheckBox.new()
		cb.text = o[0]
		cb.add_theme_font_size_override("font_size", 17)
		match o[1]:
			"armi": cb.button_pressed = opz_armi
			"guardia": cb.button_pressed = opz_guardia
			"opz": cb.button_pressed = opz_opzionali
		var kk: String = o[1]
		cb.toggled.connect(func(on): _opzione(kk, on))
		r3.add_child(cb)
	var r4 := HBoxContainer.new()
	r4.add_theme_constant_override("separation", 14)
	v.add_child(r4)
	r4.add_child(bottone("Alle armi!", _avvia_locale, 26, 300))
	r4.add_child(bottone("Indietro", mostra_menu, 20))

func _opzione(k: String, on: bool) -> void:
	match k:
		"armi":
			opz_armi = on
		"guardia":
			opz_guardia = on
		"opz":
			opz_opzionali = on

func _descrizione_scenario(k: String) -> String:
	match k:
		"ligny":
			return "16 giugno, 14:00-20:00. Napoleone attacca i tre corpi prussiani di Blücher trincerati nei villaggi lungo il ruscello di Ligny. Vincono i Francesi se demoralizzano i Prussiani prima di perdere 35 punti (o se li disintegrano); altrimenti vincono i Prussiani. Ogni villaggio di Ligny e St-Amand preso abbassa i livelli prussiani di 3."
		"quatrebras":
			return "16 giugno, 14:00-20:00. Ney contro la sola divisione olandese di Perponcher, mentre arrivano i rinforzi di Wellington. Punti: 1 per ogni punto forza nemico eliminato, 1 a turno per chi tiene l'incrocio di Quatre Bras, 5 per chi lo tiene a fine partita."
		"wavre":
			return "18 giugno, 12:00-19:00. Grouchy insegue i Prussiani di Thielmann sulla Dyle. I Francesi guadagnano 5 punti per ogni punto forza che esce dal bordo ovest (verso Waterloo), i Prussiani 1 per ogni punto che esce entro le 15:00; a fine partita i Francesi contano anche i Prussiani rimasti."
		"bellealliance":
			return "18 giugno, 12:00-19:00. Waterloo: l'Armée du Nord contro Wellington sul crinale di Mont-St-Jean, mentre da est arriva Bülow. I Francesi vincono demoralizzando sia gli Anglo-alleati sia i Prussiani, o disintegrando gli Anglo-alleati."
		"campagna":
			return "16-18 giugno, 36 turni con notti e pioggia. Le quattro mappe unite: comando dei capi, riorganizzazione delle unità, demoralizzazione dei singoli corpi, rifornimento. I Francesi vincono arrivando a 230 punti (perdite nemiche, uscite verso Bruxelles da B0605)."
	return ""

func _avvia_locale() -> void:
	online = false
	match scelta_modo:
		"ia":
			umani = [scelta_lato == 0, scelta_lato == 1]
		"due":
			umani = [true, true]
		_:
			umani = [false, false]
	m = Motore.new()
	m.nuova(_cfg_partita(int(Time.get_unix_time_from_system()) % 1000000))
	_prepara_ia()
	_apri_partita()
	_salva(true)

func _cfg_partita(seed: int) -> Dictionary:
	return {"scen": scelta_scen, "seed": seed, "armi_combinate": opz_armi, "guardia": opz_guardia, "opzionali": opz_opzionali}

func _prepara_ia() -> void:
	ia = [IA.new(m), IA.new(m)]
	for x in ia:
		x.carattere = carattere_ia

func _menu_continua() -> void:
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.READ)
	if f == null:
		return
	var st = JSON.parse_string(f.get_as_text())
	if not (st is Dictionary):
		_avviso("Il salvataggio è illeggibile.")
		return
	_carica_stato(st)

func _continua_firebase() -> void:
	_avviso("Cerco la partita salvata su Firebase...")
	var st := await net.carica_partita()
	if st.is_empty():
		_avviso("Nessuna partita salvata su Firebase per questo dispositivo. " + net.last_error)
		return
	_carica_stato(st)

func _carica_stato(st: Dictionary) -> void:
	online = false
	m = Motore.new()
	m.importa(st.get("motore", st))
	var u = st.get("umani", [true, false])
	umani = [bool(u[0]), bool(u[1])] if u is Array and u.size() == 2 else [true, false]
	carattere_ia = int(st.get("carattere", 1))
	_prepara_ia()
	_apri_partita()

func _avviso(t: String) -> void:
	_notifica(t)

func _testo_regole() -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(1030, 0)
	rt.add_theme_font_override("normal_font", F_TESTO)
	rt.add_theme_font_override("bold_font", F_GRASSETTO)
	rt.add_theme_font_override("italics_font", F_CORSIVO)
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		rt.add_theme_font_size_override(k, 19)
	rt.text = Guida.TESTO
	return rt

func _menu_regole() -> void:
	pulisci()
	_sfondo()
	var v := _scheda_centrale(1100, 860)
	v.add_child(etichetta("Le regole in breve", F_TITOLO, 40, C_BLU))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1060, 700)
	v.add_child(sc)
	sc.add_child(_testo_regole())
	v.add_child(bottone("Indietro", mostra_menu, 20))

# =============================================================================================
# Online

func _menu_online() -> void:
	pulisci()
	_sfondo()
	var v := _scheda_centrale(900, 720)
	v.add_child(etichetta("Gioca online", F_TITOLO, 44, C_BLU))
	v.add_child(etichetta("Chi crea la stanza sceglie battaglia e parte; l'amico entra con il codice di 4 lettere e prende l'altra. Se l'amico non c'è, l'altra parte la guida l'IA.", F_TESTO, 19))
	var r1 := HBoxContainer.new()
	v.add_child(r1)
	r1.add_child(riga_lbl("Il tuo nome:  ", F_GRASSETTO, 20))
	on_nome = LineEdit.new()
	on_nome.custom_minimum_size = Vector2(300, 0)
	on_nome.text = str(net.load_session().get("name", "Maresciallo"))
	on_nome.max_length = 20
	r1.add_child(on_nome)
	var r0 := HBoxContainer.new()
	r0.add_theme_constant_override("separation", 10)
	v.add_child(r0)
	r0.add_child(riga_lbl("Battaglia:  ", F_GRASSETTO, 20))
	on_scen = OptionButton.new()
	for k in SCENARI:
		on_scen.add_item(Motore.scenari[k]["titolo"])
	on_scen.selected = SCENARI.find(scelta_scen)
	r0.add_child(on_scen)
	r0.add_child(riga_lbl("  La tua parte:  ", F_GRASSETTO, 20))
	on_lato = OptionButton.new()
	on_lato.add_item("Francesi")
	on_lato.add_item("Alleati")
	r0.add_child(on_lato)
	v.add_child(bottone("Crea una stanza", _online_crea, 24))
	var r2 := HBoxContainer.new()
	v.add_child(r2)
	on_codice = LineEdit.new()
	on_codice.placeholder_text = "CODICE"
	on_codice.max_length = 4
	on_codice.custom_minimum_size = Vector2(160, 0)
	r2.add_child(on_codice)
	r2.add_child(bottone("Entra", _online_entra, 24))
	var sess := net.load_session()
	if str(sess.get("room", "")) != "":
		r2.add_child(bottone("Rientra in %s" % sess["room"], func():
			on_codice.text = str(sess["room"])
			_online_entra(), 20))
	on_stato = etichetta("", F_TESTO, 20, C_ROSSO)
	v.add_child(on_stato)
	lobby_box = VBoxContainer.new()
	v.add_child(lobby_box)
	v.add_child(bottone("Indietro", mostra_menu, 20))

func _online_crea() -> void:
	on_stato.text = "Creo la stanza..."
	net._save({"name": on_nome.text})
	scelta_scen = SCENARI[maxi(0, on_scen.selected)]
	var c := await net.create_room(on_nome.text, {"lato": on_lato.selected, "scen": scelta_scen})
	if c == "":
		on_stato.text = "Non riesco a creare la stanza: " + net.last_error
		return
	codice = c
	mio_posto = 0
	net.remember_room(c, 0)
	on_stato.text = "Stanza %s creata. Dai il codice all'amico, poi premi Inizia." % c
	_lobby(true)

func _online_entra() -> void:
	var c := on_codice.text.strip_edges().to_upper()
	if c.length() != 4:
		on_stato.text = "Il codice ha 4 lettere."
		return
	on_stato.text = "Entro nella stanza %s..." % c
	net._save({"name": on_nome.text})
	var p := await net.join_room(c, on_nome.text, 2)
	if p < 0:
		on_stato.text = "Non riesco a entrare (stanza piena, inesistente o già iniziata). " + net.last_error
		return
	codice = c
	mio_posto = p
	net.remember_room(c, p)
	var room := await net.room(c)
	if room.get("status", "") == "playing":
		_avvia_da_stanza(room)
		return
	on_stato.text = "Sei nella stanza %s. Aspetta che chi l'ha creata inizi." % c
	_lobby(false)

func _lobby(host: bool) -> void:
	for ch in lobby_box.get_children():
		ch.queue_free()
	var lista := etichetta("", F_TESTO, 20)
	lobby_box.add_child(lista)
	if host:
		lobby_box.add_child(bottone("Inizia la partita", _online_inizia, 24))
	while is_instance_valid(lista) and not in_partita:
		var room := await net.room(codice)
		if not is_instance_valid(lista):
			return
		var seats := Rete._as_dict(room.get("seats", {}))
		var t := "Nella stanza:\n"
		for k in seats:
			t += "  %d. %s\n" % [int(k) + 1, seats[k].get("name", "?")]
		lista.text = t
		if not host and room.get("status", "") == "playing":
			_avvia_da_stanza(room)
			return
		await get_tree().create_timer(1.5).timeout

func _online_inizia() -> void:
	var room := await net.room(codice)
	var seats := Rete._as_dict(room.get("seats", {}))
	var cfg = JSON.parse_string(str(room.get("cfg", "{}")))
	var lato_host: int = int(cfg.get("lato", 0)) if cfg is Dictionary else 0
	var lati := [-1, -1]
	lati[lato_host] = 0
	if seats.has("1"):
		lati[1 - lato_host] = 1
	var game := _cfg_partita(int(Time.get_unix_time_from_system()) % 1000000)
	game["scen"] = str(cfg.get("scen", scelta_scen)) if cfg is Dictionary else scelta_scen
	game["lati"] = lati
	if not await net.start_room(codice, game):
		on_stato.text = "Non riesco a iniziare: " + net.last_error
		return
	room["game"] = JSON.stringify(game)
	_avvia_da_stanza(room)

func _avvia_da_stanza(room: Dictionary) -> void:
	var game = JSON.parse_string(str(room.get("game", "{}")))
	if not (game is Dictionary):
		on_stato.text = "Dati della partita illeggibili."
		return
	online = true
	posti_lati = [int(game["lati"][0]), int(game["lati"][1])]
	umani = [posti_lati[0] == mio_posto, posti_lati[1] == mio_posto]
	m = Motore.new()
	m.nuova(game)
	_prepara_ia()
	var log := await net.get_decisions(codice, 0)
	var guard := 0
	while not m.finita() and guard < 40000:
		guard += 1
		var n := int(m.s["azioni"])
		if not log.has(n):
			break
		if not m.applica(log[n]):
			push_warning("decisione %d rifiutata nel riavvio" % n)
			break
	_apri_partita()

## Chi decide per un lato: "io", "ia" (calcolata qui), "remoto" (si aspetta dalla rete)
func _chi(lato: int) -> String:
	if not online:
		return "io" if umani[lato] else "ia"
	if posti_lati[lato] == mio_posto:
		return "io"
	if posti_lati[lato] < 0:
		return "ia" if mio_posto == 0 else "remoto"
	return "remoto"

# =============================================================================================
# La partita

func _apri_partita() -> void:
	pulisci()
	in_partita = true
	sel_hex = ""
	_annulla_selezione()
	_costruisci_hud()
	_aggiorna_tutto()
	_inquadra_scenario()

func _inquadra_scenario() -> void:
	var somma := Vector2.ZERO
	var n := 0
	for id in m.s["unita"]:
		if m.s["unita"][id]["st"] == "mappa":
			somma += Mappa.pos(m.s["unita"][id]["h"])
			n += 1
	if n > 0:
		var p := somma / n
		bersaglio_cam = Vector3(p.x * SC, 0, p.y * SC)
	distanza = 30.0 if m.campagna() else 17.0
	pitch = -1.12
	yaw = 0.0
	_aggiorna_camera()

func _costruisci_hud() -> void:
	var barra := PanelContainer.new()
	barra.add_theme_stylebox_override("panel", stile(C_BLU_SCURO, C_ORO, 0, 0))
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.custom_minimum_size.y = 62
	schermo.add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	barra.add_child(hb)
	lbl_titolo = riga_lbl(m.scen["titolo"].to_upper(), F_TITOLO, 28, C_ORO)
	hb.add_child(lbl_titolo)
	lbl_data = riga_lbl("", F_GRASSETTO, 21, Color(0.97, 0.94, 0.86))
	hb.add_child(lbl_data)
	lbl_fase = riga_lbl("", F_TESTO, 21, Color(0.97, 0.94, 0.86))
	lbl_fase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_fase.clip_text = true
	hb.add_child(lbl_fase)
	lbl_pv = riga_lbl("", F_TESTO, 19, C_ORO)
	hb.add_child(lbl_pv)
	for b in [["Registro", _mostra_diario], ["Plance", _plance_popup], ["Tabelle", _tabelle_popup], ["Vista", _cambia_vista], ["Regole", _regole_popup], ["Menu", _menu_partita]]:
		var bt := bottone(b[0], b[1], 16)
		hb.add_child(bt)
	var sx := pannello(Color(0.96, 0.92, 0.83, 0.96))
	sx.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sx.offset_top = 74
	sx.offset_bottom = -12
	sx.offset_left = 12
	sx.offset_right = 470
	schermo.add_child(sx)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	sx.add_child(col)
	lbl_stato = etichetta("", F_CORSIVO, 19, C_BLU)
	col.add_child(lbl_stato)
	box_azioni = VBoxContainer.new()
	box_azioni.add_theme_constant_override("separation", 6)
	col.add_child(box_azioni)
	col.add_child(HSeparator.new())
	scroll_info = ScrollContainer.new()
	scroll_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_info.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll_info)
	pannello_info = VBoxContainer.new()
	pannello_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pannello_info.add_theme_constant_override("separation", 6)
	scroll_info.add_child(pannello_info)
	pannello_diario = pannello(Color(0.96, 0.92, 0.83, 0.96))
	pannello_diario.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	pannello_diario.offset_top = 74
	pannello_diario.offset_bottom = -12
	pannello_diario.offset_left = -560
	pannello_diario.offset_right = -12
	pannello_diario.visible = false
	schermo.add_child(pannello_diario)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.add_theme_font_override("normal_font", F_TESTO)
	diario.add_theme_font_override("bold_font", F_GRASSETTO)
	diario.add_theme_font_size_override("normal_font_size", 17)
	diario.add_theme_font_size_override("bold_font_size", 17)
	pannello_diario.add_child(diario)
	tip = pannello(Color(1, 0.98, 0.92, 0.95))
	tip.visible = false
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schermo.add_child(tip)
	tip_lbl = etichetta("", F_TESTO, 16)
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tip.add_child(tip_lbl)
	notifica = VBoxContainer.new()
	notifica.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notifica.offset_top = 84
	notifica.offset_left = -340
	notifica.offset_right = 340
	notifica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schermo.add_child(notifica)

func _notifica(t: String) -> void:
	if notifica == null or not is_instance_valid(notifica):
		if on_stato != null and is_instance_valid(on_stato):
			on_stato.text = t
		return
	var p := pannello(Color(0.99, 0.96, 0.88, 0.97), C_ROSSO)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := etichetta(t, F_GRASSETTO, 20, C_BLU)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	notifica.add_child(p)
	var tw := create_tween()
	tw.tween_interval(3.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)

func _mostra_diario() -> void:
	pannello_diario.visible = not pannello_diario.visible

func _cambia_vista() -> void:
	vista_alta = not vista_alta
	if vista_alta:
		pitch = -1.53
		yaw = 0.0
	else:
		pitch = -1.12
	_aggiorna_camera()

func _menu_partita() -> void:
	var v := _apri_popup("Menu", 580)
	v.add_child(bottone("Torna alla partita", _chiudi_popup, 22))
	v.add_child(bottone("Salva ora (anche su Firebase)", func():
		_salva(true)
		_chiudi_popup()
		_notifica("Partita salvata"), 20))
	var gv := HBoxContainer.new()
	gv.add_child(riga_lbl("Velocità dell'IA: ", F_GRASSETTO, 18))
	for x in [["lenta", 0.5], ["normale", 1.0], ["veloce", 3.0]]:
		gv.add_child(bottone(x[0], func(): velocita = x[1], 16))
	v.add_child(gv)
	v.add_child(bottone("Inquadra la battaglia", func():
		_chiudi_popup()
		_inquadra_scenario(), 18))
	v.add_child(bottone("Esci al menu principale", func():
		_salva(true)
		mostra_menu(), 20))

func _apri_popup(titolo: String, larg := 900, alto := 0) -> VBoxContainer:
	_chiudi_popup()
	popup_aperto = true
	var velo := ColorRect.new()
	velo.color = Color(0.03, 0.04, 0.08, 0.55)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	schermo.add_child(velo)
	popup = velo
	var box := pannello()
	box.add_theme_stylebox_override("panel", stile(C_CARTA, C_BLU, 4, 6))
	box.custom_minimum_size = Vector2(larg, alto)
	velo.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(etichetta(titolo, F_TITOLO, 30, C_BLU))
	box.resized.connect(func(): _adatta_popup(box, velo))
	_adatta_popup.call_deferred(box, velo)
	return v

func _adatta_popup(p: Control, velo: Control) -> void:
	if not is_instance_valid(p) or not is_instance_valid(velo):
		return
	var vs := velo.size
	var mn := p.get_combined_minimum_size()
	if p.size.y > mn.y + 2 or p.size.x > mn.x + 2:
		p.size = mn
	p.position = ((vs - p.size) / 2.0).max(Vector2(10, 10))

func _chiudi_popup() -> void:
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	popup = null
	popup_aperto = false

func _regole_popup() -> void:
	var v := _apri_popup("Le regole in breve", 1100)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1060, 640)
	v.add_child(sc)
	sc.add_child(_testo_regole())
	v.add_child(bottone("Chiudi", _chiudi_popup, 20))

## Le tabelle: TRC e terreni, come sul foglio originale
func _tabelle_popup() -> void:
	var v := _apri_popup("Tabella dei risultati del combattimento", 1150)
	var g := GridContainer.new()
	g.columns = 11
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 3)
	v.add_child(g)
	g.add_child(_cella("Dado", true))
	for c in Dati.COLONNE:
		g.add_child(_cella(c, true))
	for r in 6:
		g.add_child(_cella(str(r + 1), true))
		for c in 10:
			g.add_child(_cella(Dati.TRC[r][c], false, r % 2 == 0))
	v.add_child(etichetta("AE attaccante eliminato · AR l'attaccante si ritira di un esagono · DR il difensore si ritira · DE difensore eliminato · EX scambio: il difensore è eliminato e l'attaccante perde almeno altrettanti punti stampati. Oltre 6-1 vale 6-1, sotto 1-5 vale 1-5; armi combinate: una colonna a destra.", F_TESTO, 17))
	v.add_child(etichetta("Effetti del terreno", F_TITOLO, 24, C_BLU))
	var t := GridContainer.new()
	t.columns = 3
	t.add_theme_constant_override("h_separation", 18)
	v.add_child(t)
	for r in [["Terreno", "Punti movimento", "Combattimento"], ["Aperto", "1", "nessun effetto"], ["Bosco", "4 cavalleria, 2 fanteria e artiglieria", "cavalleria a metà"],
			["Palude", "4 cavalleria, 2 fanteria e artiglieria", "cavalleria a metà"], ["Cresta (lato)", "+0", "blocca il tiro d'artiglieria"],
			["Strada (lato)", "1/2", "terreno dell'esagono"], ["Sentiero (lato)", "1", "terreno dell'esagono"], ["Fattoria fortificata", "2", "difensore triplicato; fanteria: massimo 4-1 e DR senza effetto"],
			["Paese", "1", "difensore raddoppiato"], ["Fiume (lato)", "solo dai ponti", "attacco solo dai ponti o col tiro"],
			["Ruscello (lato)", "+2", "difensore raddoppiato se attaccato solo da lì"], ["Ponte (lato)", "+0", "difensore raddoppiato se attaccato solo da lì"]]:
		for i in 3:
			t.add_child(riga_lbl(r[i], F_GRASSETTO if r[0] == "Terreno" else F_TESTO, 17, C_BLU if r[0] == "Terreno" else C_INCHIOSTRO))
	var rb := HBoxContainer.new()
	rb.add_child(bottone("Il foglio originale delle tabelle", func():
		var v2 := _apri_popup("Tabelle originali (in inglese)", 900)
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(880, 700)
		v2.add_child(sc)
		sc.add_child(immagine("res://assets/ui/tabelle.webp", 860, 1112))
		v2.add_child(bottone("Chiudi", _chiudi_popup, 20)), 17))
	rb.add_child(bottone("Chiudi", _chiudi_popup, 20))
	v.add_child(rb)

func _cella(t: String, intest: bool, chiara := false) -> Control:
	var p := PanelContainer.new()
	var bg := C_BLU if intest else (Color(0.98, 0.87, 0.4) if chiara else Color(0.99, 0.96, 0.88))
	var sb := stile(bg, Color(0, 0, 0, 0), 0, 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(88, 0)
	var l := riga_lbl(t, F_GRASSETTO, 18, Color(1, 0.96, 0.86) if intest else (C_ROSSO if t in ["DE", "EX"] else C_INCHIOSTRO))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Plance: le perdite e la demoralizzazione di ogni esercito sulle plance originali dei corpi
func _plance_popup() -> void:
	var v := _apri_popup("Plance degli eserciti", 1240)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(1200, 640)
	tabs.add_theme_stylebox_override("panel", stile(C_CARTA, C_BLU, 1, 2))
	tabs.add_theme_stylebox_override("tab_selected", stile(C_BLU, C_BLU, 1, 2))
	tabs.add_theme_stylebox_override("tab_unselected", stile(C_CARTA_SCURA, C_BLU, 1, 2))
	tabs.add_theme_stylebox_override("tab_hovered", stile(Color(1, 0.96, 0.88), C_ROSSO, 1, 2))
	tabs.add_theme_color_override("font_selected_color", Color(1, 0.96, 0.86))
	tabs.add_theme_color_override("font_unselected_color", C_BLU_SCURO)
	tabs.add_theme_color_override("font_hovered_color", C_ROSSO)
	tabs.add_theme_font_override("font", F_GRASSETTO)
	v.add_child(tabs)
	for es in ["FR", "PR", "AA"]:
		var sc := ScrollContainer.new()
		sc.name = Dati.ESERCITI[es]
		tabs.add_child(sc)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		sc.add_child(col)
		col.add_child(_plancia(es))
		col.add_child(_stato_esercito(es))
	v.add_child(bottone("Chiudi", _chiudi_popup, 20))

func _plancia(es: String) -> Control:
	var base := Control.new()
	var W := 1160.0
	var H := W * 434.0 / 911.0
	base.custom_minimum_size = Vector2(W, H)
	var img := immagine("res://assets/ui/plancia_%s.webp" % es, W, H)
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.size = Vector2(W, H)
	base.add_child(img)
	# riquadri (frazioni della plancia): ritardo, riorganizzabili, eliminate per sempre
	var box := {"ritardo": Rect2(0.035, 0.32, 0.205, 0.56), "riorg": Rect2(0.268, 0.32, 0.205, 0.56), "perse": Rect2(0.49, 0.22, 0.505, 0.66)}
	var liste := {"ritardo": [], "riorg": [], "perse": []}
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if m.esercito(id) != es:
			continue
		match u["st"]:
			"riorg":
				liste["ritardo" if int(u.get("dal", 0)) >= int(m.s["turno"]) else "riorg"].append(id)
			"distrutta", "elim":
				liste["perse"].append(id)
	var lato := 46.0
	for k in liste:
		var r: Rect2 = box[k]
		var x0 := r.position.x * W
		var y0 := r.position.y * H
		var per_riga := maxi(1, int(r.size.x * W / (lato + 4)))
		var i := 0
		for id in liste[k]:
			var t := immagine(img_pedina(id, m.s["unita"][id]["rid"] or k != "perse"), lato, lato)
			t.position = Vector2(x0 + (i % per_riga) * (lato + 4), y0 + int(i / per_riga) * (lato + 4))
			t.size = Vector2(lato, lato)
			base.add_child(t)
			i += 1
	return base

func _stato_esercito(es: String) -> Control:
	var v := VBoxContainer.new()
	if m.campagna():
		var gruppi := {}
		for id in m.s["unita"]:
			if m.esercito(id) == es:
				gruppi[m.gruppo_dem(id)] = true
		var righe := []
		var ks := gruppi.keys()
		ks.sort()
		for g in ks:
			righe.append("%s: perdite %d su %d%s" % [m._nome_gruppo(g).substr(3 if es != "AA" else 0), m.perdite_corpo(g), m.livello_corpo(g), "  — DEMORALIZZATO" if m.s["dem"].get(g, false) else ""])
		v.add_child(etichetta("\n".join(righe), F_TESTO, 18))
	else:
		var lv := m.livello_folio(es)
		var ld := m.livello_folio(es, true)
		if lv < 999:
			v.add_child(etichetta("Perdite %d · demoralizzazione a %d%s%s" % [int(m.s["perdite"][es]), lv, (" · disintegrazione a %d" % ld) if ld < 999 else "", "  — DEMORALIZZATO" if m.s["dem"].get(es, false) else ""], F_GRASSETTO, 20, C_BLU))
		else:
			v.add_child(etichetta("Perdite %d" % int(m.s["perdite"][es]), F_GRASSETTO, 20, C_BLU))
	var arr := []
	for id in m.s["unita"]:
		if m.esercito(id) == es and m.s["unita"][id]["st"] == "arrivo":
			arr.append("%s (%s, %s)" % [m.nome(id), m.scen["turni"][int(m.s["unita"][id]["t"])].trim_prefix("N").trim_prefix("R"), Mappa.sigla(str(m.s["unita"][id]["e"]).split("|")[0])])
	if not arr.is_empty():
		v.add_child(etichetta("In arrivo: " + ", ".join(arr), F_TESTO, 17, C_SPENTO))
	return v

# ---------- aggiornamento

func _fase_mia(k: String) -> bool:
	if m == null or m.finita():
		return false
	var r := m.richiesta()
	return r.get("k", "") == k and _chi(int(r["lato"])) == "io"

func _aggiorna_tutto() -> void:
	if m == null or lbl_data == null:
		return
	lbl_data.text = "%d giugno, ore %s · turno %d di %d" % [m.giorno(), m.ora(), mini(int(m.s["turno"]) + 1, m.scen["turni"].size()), m.scen["turni"].size()]
	var r := m.richiesta()
	if m.finita():
		lbl_fase.text = "Partita finita"
	else:
		var fase: String = {"movimento": "movimento", "combattimento": "combattimento", "avanza": "avanzata dopo il combattimento"}.get(r.get("k", ""), "")
		lbl_fase.text = "%s — %s%s" % [Dati.LATI[m.s["lato"]], fase, "  (notte)" if m.notte() else ("  (pioggia)" if m.pioggia() else "")]
	if m.campagna():
		lbl_pv.text = "Punti vittoria francesi %d / 230" % m.punti_campagna()
	elif m.s["scen"] in ["quatrebras", "wavre"]:
		lbl_pv.text = "Punti  Francia %d · Alleati %d" % [int(m.s["pv"][0]), int(m.s["pv"][1])]
	else:
		var t := []
		for es in ["FR", "PR", "AA"]:
			var lv := m.livello_folio(es)
			if lv < 999:
				t.append("%s %d/%d" % [{"FR": "Fra", "PR": "Pru", "AA": "Ang"}[es], int(m.s["perdite"][es]), lv])
		lbl_pv.text = "Perdite " + " · ".join(t)
	diario.text = "\n".join(m.s["log"].slice(-180))
	_aggiorna_pezzi()
	_aggiorna_evidenze()
	_aggiorna_pannello()

func _aggiorna_pannello() -> void:
	for c in box_azioni.get_children():
		c.queue_free()
	for c in pannello_info.get_children():
		c.queue_free()
	if m.finita():
		lbl_stato.text = "La partita è finita."
		box_azioni.add_child(bottone("Vedi il risultato", _mostra_fine, 20))
		_info_esagono(sel_hex)
		return
	var r := m.richiesta()
	var lato := int(r.get("lato", 0))
	var chi := _chi(lato)
	if chi != "io":
		lbl_stato.text = "Tocca a: %s%s" % [Dati.LATI[lato], " (IA)" if chi == "ia" else " (in attesa dell'avversario)"]
		_info_esagono(sel_hex)
		return
	match r["k"]:
		"movimento":
			lbl_stato.text = "%s: movimento. Tocca un esagono con le tue unità, scegli l'unità e poi la destinazione (in verde)." % Dati.LATI[lato]
			var fine := bottone("Fine del movimento", func():
				_annulla_selezione()
				_invia({"a": "fine"}), 21)
			box_azioni.add_child(fine)
			var amm := m.ammassati()
			if not amm.is_empty():
				box_azioni.add_child(etichetta("Troppe unità in %s: al massimo due per esagono (una nelle fattorie)." % ", ".join(amm.map(func(h): return Mappa.sigla(h))), F_GRASSETTO, 17, C_ROSSO))
			_pannello_movimento(lato)
		"combattimento":
			lbl_stato.text = "%s: combattimento. Tocca un esagono nemico (in arancio quelli da attaccare per forza), scegli chi attacca e premi «Attacca»." % Dati.LATI[lato]
			_pannello_combattimento(lato)
		"avanza":
			lbl_stato.text = "Il nemico ha lasciato l'esagono: un'unità vincitrice può avanzare. Tocca sulla mappa un'unità con l'anello d'oro; l'esagono libero è in blu."
			if not batt_aperta:
				box_azioni.add_child(bottone("Nessuna avanzata", func(): _invia({"a": "avanza", "u": ""}), 18))
			var viste := {}
			for c in r["cand"]:
				if not viste.has(c[0]):
					viste[c[0]] = true
					pannello_info.add_child(_riga_unita(c[0]))
			_info_esagono(sel_hex)

func _info_esagono(h: String) -> void:
	if h == "" or m == null:
		pannello_info.add_child(etichetta("Tocca un esagono per vederne il contenuto. Trascina per spostare la mappa; rotella o pizzico per lo zoom; tasto destro o due dita per ruotare (anche su iPad).", F_CORSIVO, 17, C_SPENTO))
		return
	pannello_info.add_child(etichetta("%s — %s" % [Mappa.sigla(h), Dati.NOMI_TERRENO.get(Mappa.terreno(h), "")], F_TITOLO, 22, C_BLU))
	for l in [0, 1]:
		var ids := m.unita_in(h, l)
		var capi := m.capi_in(h, l)
		if ids.is_empty() and capi.is_empty():
			continue
		pannello_info.add_child(etichetta(Dati.LATI[l], F_GRASSETTO, 19, COL_LATO[l].darkened(0.35)))
		for id in ids:
			pannello_info.add_child(_riga_unita(id))
		for c in capi:
			pannello_info.add_child(_riga_capo(c))

func _riga_unita(id: String, cb := Callable()) -> Control:
	var u: Dictionary = m.s["unita"][id]
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	rr.add_child(immagine(img_pedina(id, u["rid"]), 52, 52))
	var c := m.cat(id)
	var extra := []
	if u["rid"]:
		extra.append("ridotta")
	if u["mosso"]:
		extra.append("mossa")
	if u["att"]:
		extra.append("ha attaccato")
	if m.dem_unita(id):
		extra.append("demoralizzata")
	if m.campagna() and u["st"] == "mappa" and m.lato_di(id) == int(m.s["lato"]) and not m.in_comando(id):
		extra.append("fuori comando")
	var testo := "%s  %d-%d\n%s, %s%s" % [m.nome(id), m.forza(id), m.ma(id), Dati.TIPI[c["t"]], Dati.NAZ[c["naz"]]["nome"], (" · " + ", ".join(extra)) if not extra.is_empty() else ""]
	if cb.is_valid():
		var b := Button.new()
		b.text = testo
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		b.button_pressed = sel_unita == id or sel_att.has(id)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(cb)
		rr.add_child(b)
	else:
		var l := etichetta(testo, F_TESTO, 16)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rr.add_child(l)
	return rr

func _riga_capo(c: String, cb := Callable()) -> Control:
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	rr.add_child(immagine(img_pedina(c), 52, 52))
	var k: Dictionary = Motore.catalogo["capi"][c]
	var testo := "%s\n%s" % [m.nome(c), ("comandante, capacità %d" % int(k["cap"])) if int(k["cap"]) > 0 else ("ufficiale: " + Dati.NOMI_CORPI.get(k["des"], Dati.NOMI_DIVISIONI.get(k["des"], k["des"])))]
	if cb.is_valid():
		var b := Button.new()
		b.text = testo
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		b.button_pressed = sel_capo == c
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(cb)
		rr.add_child(b)
	else:
		rr.add_child(etichetta(testo, F_TESTO, 16))
	return rr

# ---------- movimento

func _pannello_movimento(lato: int) -> void:
	var arr := m.arrivi_disponibili(lato)
	if not arr.is_empty():
		pannello_info.add_child(etichetta("Rinforzi che possono entrare", F_GRASSETTO, 19, C_BLU))
		for id in arr:
			var x: String = id
			pannello_info.add_child(_riga_unita(id, func(): _scegli_unita(x, true)))
		pannello_info.add_child(HSeparator.new())
	if sel_unita != "" and m.s["unita"].has(sel_unita):
		var u: Dictionary = m.s["unita"][sel_unita]
		if u["st"] == "mappa":
			for h in rag:
				if m.uscita_valida(sel_unita, h) and not m.zoc(h, 1 - lato):
					var hh: String = h
					box_azioni.add_child(bottone("%s esce dalla mappa da %s" % [m.nome(sel_unita), Mappa.sigla(h)], func(): _invia({"a": "esci", "u": sel_unita, "h": hh}), 17))
					break
	if sel_hex == "":
		_info_esagono("")
		return
	pannello_info.add_child(etichetta("%s — %s" % [Mappa.sigla(sel_hex), Dati.NOMI_TERRENO.get(Mappa.terreno(sel_hex), "")], F_TITOLO, 22, C_BLU))
	for id in m.unita_in(sel_hex, lato):
		var x: String = id
		if m.puo_muovere(id):
			pannello_info.add_child(_riga_unita(id, func(): _scegli_unita(x, false)))
		else:
			pannello_info.add_child(_riga_unita(id))
			if m.in_ezoc(id) and not m.s["unita"][id]["mosso"]:
				pannello_info.add_child(etichetta("   a contatto col nemico: non può muovere", F_CORSIVO, 15, C_ROSSO))
	if m.campagna():
		for c in m.capi_in(sel_hex, lato):
			var x: String = c
			if not m.s["capi"][c].get("mosso", false):
				pannello_info.add_child(_riga_capo(c, func(): _scegli_capo(x)))
			else:
				pannello_info.add_child(_riga_capo(c))
	for id in m.unita_in(sel_hex, 1 - lato):
		pannello_info.add_child(_riga_unita(id))

func _scegli_unita(id: String, arrivo: bool) -> void:
	sel_capo = ""
	if sel_unita == id:
		sel_unita = ""
		rag = {}
	else:
		sel_unita = id
		rag = m.raggiungibili_arrivo(id) if arrivo else m.raggiungibili(id)
		if arrivo:
			var e := ""
			for h in rag:
				if rag[h].has("ing"):
					e = rag[h]["ing"]
					break
			_centra_su(e)
		else:
			rag.erase(m.s["unita"][id]["h"])
	_aggiorna_evidenze()
	_aggiorna_pannello()

func _scegli_capo(c: String) -> void:
	sel_unita = ""
	if sel_capo == c:
		sel_capo = ""
		rag = {}
	else:
		sel_capo = c
		rag = m.raggiungibili(c)
		rag.erase(m.s["capi"][c]["h"])
	_aggiorna_evidenze()
	_aggiorna_pannello()

func _annulla_selezione() -> void:
	sel_unita = ""
	sel_capo = ""
	rag = {}
	sel_dif = []
	sel_att = {}
	sel_col = -1
	if m != null and in_partita:
		_aggiorna_evidenze()

func _clic(h: String) -> void:
	if m == null:
		return
	if _fase_mia("movimento") and h != "" and rag.has(h):
		var d := {}
		if sel_capo != "":
			d = {"a": "capo", "c": sel_capo, "h": h}
		elif m.s["unita"][sel_unita]["st"] == "arrivo":
			d = {"a": "entra", "u": sel_unita, "h": h}
		else:
			d = {"a": "muovi", "u": sel_unita, "h": h}
		_annulla_selezione()
		await _invia(d)
		sel_hex = h
		# seleziona la prossima unità ancora da muovere nello stesso esagono
		_aggiorna_tutto()
		return
	if _fase_mia("combattimento") and h != "":
		_clic_combattimento(h)
		return
	if _fase_mia("avanza") and h != "":
		if batt_pre:
			_finale_battaglia()
		_clic_avanza(h)
		return
	sel_hex = h
	_annulla_selezione()
	if _fase_mia("movimento") and h != "":
		for id in m.unita_in(h, int(m.s["lato"])):
			if m.puo_muovere(id):
				sel_hex = h
				_scegli_unita(id, false)
				_aggiorna_tutto()
				return
	_aggiorna_tutto()

# ---------- combattimento

func _clic_combattimento(h: String) -> void:
	var lato := int(m.s["lato"])
	sel_hex = h
	if m.nemico_in(h, lato):
		var gia := false
		for id in m.unita_in(h, 1 - lato):
			if m.s["unita"][id]["dif"]:
				gia = true
		if gia:
			_notifica("Quel nemico è già stato attaccato in questa fase.")
		elif sel_dif.has(h):
			sel_dif.erase(h)
		else:
			sel_dif.append(h)
		_proponi_attaccanti()
	elif m.lato_hex(h) == lato:
		for id in m.unita_in(h, lato):
			if sel_att.has(id):
				sel_att.erase(id)
			elif not m.s["unita"][id]["att"]:
				sel_att[id] = true
	sel_col = -1
	_aggiorna_evidenze()
	_aggiorna_pannello()

func _proponi_attaccanti() -> void:
	var lato := int(m.s["lato"])
	sel_att = {}
	if sel_dif.is_empty():
		return
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if u["st"] != "mappa" or m.lato_di(id) != lato or u["att"] or u["avz"]:
			continue
		if m.in_ezoc(id):
			var ok := true
			for h in sel_dif:
				if not Mappa.adiacenti(u["h"], h) or (Mappa.fiume(u["h"], h) and not Mappa.ponte(u["h"], h)):
					ok = false
			if ok and (not m.campagna() or m.in_comando(id) or m.in_ezoc(id)):
				sel_att[id] = true
		elif m.tipo(id) in ["A", "HA"]:
			for h in sel_dif:
				if m.puo_bombardare(id, h) and (not m.campagna() or m.in_comando(id)):
					sel_att[id] = true

func _pannello_combattimento(lato: int) -> void:
	var ob := m.obblighi()
	var fine_t := "Fine dei combattimenti"
	if not ob["nemici"].is_empty():
		fine_t += " (%d attacchi obbligati si risolvono da soli)" % ob["nemici"].size()
	var bf := bottone(fine_t, func():
		_annulla_selezione()
		_invia({"a": "fine"}), 18)
	bf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box_azioni.add_child(bf)
	if sel_dif.is_empty():
		if not ob["nemici"].is_empty():
			pannello_info.add_child(etichetta("Da attaccare per forza: %s." % ", ".join(ob["nemici"].map(func(h): return Mappa.sigla(h))), F_TESTO, 17, C_ROSSO))
		pannello_info.add_child(etichetta("Ogni unità a contatto col nemico deve attaccare, e ogni nemico a contatto deve essere attaccato. Un'unità attacca una sola volta e un nemico è attaccato una sola volta. L'artiglieria non a contatto può bombardare a 2 esagoni senza subire risultati.", F_CORSIVO, 16, C_SPENTO))
		if sel_hex != "":
			_info_esagono(sel_hex)
		return
	var d := {"dif": sel_dif, "att": sel_att.keys()}
	if sel_col >= 0:
		d["col"] = sel_col
	var v := m.valuta_attacco(d)
	pannello_info.add_child(etichetta("Bersaglio: " + ", ".join(sel_dif.map(func(h): return Mappa.sigla(h))), F_GRASSETTO, 19, C_ROSSO))
	for h in sel_dif:
		for id in m.unita_in(h, 1 - lato):
			pannello_info.add_child(_riga_unita(id))
	pannello_info.add_child(etichetta("Attaccanti (tocca per togliere o aggiungere; anche sulla mappa):", F_GRASSETTO, 17, C_BLU))
	var candidati := sel_att.keys()
	for id in m.s["unita"]:
		var u: Dictionary = m.s["unita"][id]
		if u["st"] == "mappa" and m.lato_di(id) == lato and not u["att"] and not candidati.has(id):
			for h in sel_dif:
				if (Mappa.adiacenti(u["h"], h) and m.in_ezoc(id)) or m.puo_bombardare(id, h):
					candidati.append(id)
					break
	for id in candidati:
		var x: String = id
		pannello_info.add_child(_riga_unita(id, func():
			if sel_att.has(x):
				sel_att.erase(x)
			else:
				sel_att[x] = true
			sel_col = -1
			_aggiorna_evidenze()
			_aggiorna_pannello()))
	if v["ok"]:
		var t := "Forza %s contro %s: colonna %s" % [_num(v["att"]), _num(v["dif"]), Dati.COLONNE[int(v["col"])]]
		if v["armi"] and m.s["opzioni"].get("armi_combinate", true):
			t += " (armi combinate)"
		if v["castello"]:
			t += " · fattoria: massimo 4-1"
		box_azioni.add_child(etichetta(t, F_GRASSETTO, 19, C_BLU))
		var rr := HBoxContainer.new()
		rr.add_child(bottone("Attacca!", func():
			var dd := {"a": "attacco", "dif": sel_dif.duplicate(), "att": sel_att.keys()}
			if sel_col >= 0:
				dd["col"] = sel_col
			_annulla_selezione()
			_invia(dd), 22))
		if int(v["col_max"]) > 0:
			var ob2 := OptionButton.new()
			for c in int(v["col_max"]) + 1:
				ob2.add_item("a " + Dati.COLONNE[c])
			ob2.selected = int(v["col"])
			ob2.item_selected.connect(func(i):
				sel_col = i
				_aggiorna_pannello())
			rr.add_child(riga_lbl("  colonna ", F_TESTO, 16))
			rr.add_child(ob2)
		box_azioni.add_child(rr)
	else:
		box_azioni.add_child(etichetta("Non si può: %s." % v["motivo"], F_TESTO, 17, C_ROSSO))
	box_azioni.add_child(bottone("Annulla la scelta", func():
		_annulla_selezione()
		_aggiorna_pannello(), 16))

# ---------- rapporti di battaglia

# ---------- battaglia: frecce sulla mappa e tabella che sale dal basso

const ALTEZZA_BATT := 404.0

func _prossima_battaglia() -> void:
	if coda_rapporti.is_empty() or batt_aperta:
		return
	batt_rep = coda_rapporti.pop_front()
	batt_aperta = true
	batt_pre = true
	sel_avanza = ""
	batt_gen += 1
	var gen := batt_gen
	_costruisci_pannello_battaglia()
	_inquadra_battaglia()
	_aggiorna_pezzi()
	_aggiorna_evidenze()
	_aggiorna_pannello()
	await _anima_battaglia(gen)

func _inquadra_battaglia() -> void:
	# il combattimento va nella metà alta dello schermo, sopra la tabella
	var c := Vector3.ZERO
	var n := 0
	for h in batt_rep["dif_hex"]:
		c += _v3(h)
		n += 1
	if n == 0:
		return
	c /= n
	var d := minf(distanza, 11.0)
	var meta := c + Vector3(sin(yaw), 0, cos(yaw)) * d * 0.28
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var da := bersaglio_cam
	var dd := distanza
	tw.tween_method(func(x: float):
		bersaglio_cam = da.lerp(meta, x)
		distanza = lerpf(dd, d, x)
		_aggiorna_camera(), 0.0, 1.0, 0.45)

func _stile_cella(tipo: String, chiara := false) -> StyleBoxFlat:
	var bg: Color
	match tipo:
		"intest":
			bg = C_BLU
		"intest_on":
			bg = C_ORO
		"colonna":
			bg = Color(0.99, 0.86, 0.45)
		"riga":
			bg = Color(0.7, 0.8, 0.98)
		"incrocio":
			bg = C_ROSSO
		_:
			bg = Color(0.97, 0.93, 0.83) if chiara else Color(0.99, 0.97, 0.9)
	var sb := stile(bg, C_BLU_SCURO if tipo == "incrocio" else Color(0, 0, 0, 0), 3 if tipo == "incrocio" else 0, 3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb

func _cella_batt(testo: String, tipo: String, chiara := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stile_cella(tipo, chiara))
	p.custom_minimum_size = Vector2(66, 34)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := riga_lbl(testo, F_GRASSETTO, 19, Color(1, 0.96, 0.86) if tipo == "intest" else C_INCHIOSTRO)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _imposta_cella(p: PanelContainer, tipo: String, chiara := false) -> void:
	p.add_theme_stylebox_override("panel", _stile_cella(tipo, chiara))
	var l: Label = p.get_child(0)
	var col := C_INCHIOSTRO
	if tipo == "intest":
		col = Color(1, 0.96, 0.86)
	elif tipo == "intest_on":
		col = C_BLU_SCURO
	elif tipo == "incrocio":
		col = Color(1, 0.97, 0.9)
	elif l.text in ["DE", "EX"]:
		col = C_ROSSO
	l.add_theme_color_override("font_color", col)

func _costruisci_pannello_battaglia() -> void:
	if batt_pannello != null and is_instance_valid(batt_pannello):
		batt_pannello.queue_free()
	var rep := batt_rep
	var pn := PanelContainer.new()
	var sb := stile(Color(0.96, 0.92, 0.83, 0.98), C_BLU, 3, 6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pn.add_theme_stylebox_override("panel", sb)
	pn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pn.offset_left = 490
	pn.offset_right = -12
	pn.offset_top = 20
	pn.offset_bottom = ALTEZZA_BATT + 20
	schermo.add_child(pn)
	batt_pannello = pn
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pn.add_child(v)
	# intestazione: chi attacca dove, forze e colonna
	var la := int(rep["lato"])
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 14)
	v.add_child(r1)
	var tit := riga_lbl("%s attaccano %s" % [Dati.LATI[la], ", ".join(rep["dif_hex"].map(func(h): return Mappa.sigla(h)))], F_TITOLO, 25, C_BLU)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.clip_text = true
	r1.add_child(tit)
	r1.add_child(riga_lbl("%s contro %s  ·  colonna %s" % [_num(rep["fa"]), _num(rep["fd"]), rep["col"]], F_GRASSETTO, 20, C_INCHIOSTRO))
	batt_dado = Dado.new(1, false, 40.0)
	r1.add_child(batt_dado)
	# la tabella
	var g := GridContainer.new()
	g.columns = 11
	g.add_theme_constant_override("h_separation", 3)
	g.add_theme_constant_override("v_separation", 3)
	v.add_child(g)
	batt_celle = []
	batt_righe = []
	batt_colonne = []
	g.add_child(_cella_batt("Dado", "intest"))
	for c in Dati.COLONNE:
		var hc := _cella_batt(c, "intest")
		batt_colonne.append(hc)
		g.add_child(hc)
	for r in 6:
		var hr := _cella_batt(str(r + 1), "intest")
		batt_righe.append(hr)
		g.add_child(hr)
		var riga := []
		for c in 10:
			var ce := _cella_batt(Dati.TRC[r][c], "", r % 2 == 0)
			_imposta_cella(ce, "", r % 2 == 0)
			riga.append(ce)
			g.add_child(ce)
		batt_celle.append(riga)
	# risultato e dettagli
	var r3 := HBoxContainer.new()
	r3.add_theme_constant_override("separation", 14)
	v.add_child(r3)
	var vr := VBoxContainer.new()
	vr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r3.add_child(vr)
	batt_lbl_ris = riga_lbl(" ", F_TITOLO, 26, C_ROSSO)
	vr.add_child(batt_lbl_ris)
	batt_lbl_dett = etichetta(" ", F_TESTO, 17)
	vr.add_child(batt_lbl_dett)
	batt_bottoni = HBoxContainer.new()
	batt_bottoni.add_theme_constant_override("separation", 10)
	r3.add_child(batt_bottoni)
	batt_bottoni.add_child(bottone("Salta", func(): _finale_battaglia(), 17))
	# entra dal basso
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pn, "offset_top", -ALTEZZA_BATT, 0.4)
	tw.parallel().tween_property(pn, "offset_bottom", -8.0, 0.4)

func _evidenzia_tabella(col: int, riga: int, incrocio := false) -> void:
	for c in batt_colonne.size():
		_imposta_cella(batt_colonne[c], "intest_on" if c == col else "intest")
	for r in batt_righe.size():
		_imposta_cella(batt_righe[r], "intest_on" if r == riga else "intest")
	for r in 6:
		for c in 10:
			var tp := ""
			if r == riga and c == col:
				tp = "incrocio" if incrocio else "colonna"
			elif c == col:
				tp = "colonna"
			elif r == riga:
				tp = "riga"
			_imposta_cella(batt_celle[r][c], tp, r % 2 == 0)

func _attendi(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _anima_battaglia(gen: int) -> void:
	var col := maxi(0, Dati.COLONNE.find(batt_rep["col"]))
	var dado := clampi(int(batt_rep["dado"]), 1, 6)
	await _attendi(0.45)
	# la colonna del rapporto di forze
	for c in col + 1:
		if gen != batt_gen:
			return
		_evidenzia_tabella(c, -1)
		await _attendi(0.05)
	await _attendi(0.35)
	# la riga scorre sui valori del dado e rallenta fino a fermarsi su quello uscito
	var passi := 12 + dado - 1
	for k in passi + 1:
		if gen != batt_gen:
			return
		var r := k % 6
		_evidenzia_tabella(col, r)
		batt_dado.valore = r + 1
		batt_dado.queue_redraw()
		await _attendi(0.04 + 0.24 * pow(float(k) / float(passi), 2.4))
	if gen != batt_gen:
		return
	_finale_battaglia()

## Mostra il risultato all'incrocio, aggiorna la mappa e offre l'avanzata o il seguito
func _finale_battaglia() -> void:
	if not batt_aperta or batt_pannello == null or not is_instance_valid(batt_pannello):
		return
	batt_gen += 1
	var rep := batt_rep
	var col := maxi(0, Dati.COLONNE.find(rep["col"]))
	var dado := clampi(int(rep["dado"]), 1, 6)
	_evidenzia_tabella(col, dado - 1, true)
	batt_dado.valore = dado
	batt_dado.queue_redraw()
	var cella: PanelContainer = batt_celle[dado - 1][col]
	cella.pivot_offset = cella.size / 2
	var tw := create_tween()
	tw.tween_property(cella, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(cella, "scale", Vector2.ONE, 0.18)
	var ris: String = rep["ris"]
	var testo: String = Dati.NOMI_RISULTATO.get(ris, ris)
	if str(rep.get("orig", ris)) != ris:
		testo = "%s: %s" % [Dati.NOMI_RISULTATO.get(rep["orig"], rep["orig"]), testo]
	batt_lbl_ris.text = testo.substr(0, 1).to_upper() + testo.substr(1)
	var det := []
	if not rep["elim"].is_empty():
		det.append("Eliminati: " + ", ".join(rep["elim"].map(func(x): return m.nome(x))))
	if not rep["rit"].is_empty():
		det.append("Si ritirano: " + ", ".join(rep["rit"].map(func(x): return m.nome(x))))
	batt_lbl_dett.text = ".  ".join(det) + ("." if not det.is_empty() else "")
	# ora la mappa mostra l'esito
	batt_pre = false
	_aggiorna_pezzi()
	_aggiorna_evidenze()
	_bottoni_battaglia()

func _bottoni_battaglia() -> void:
	for c in batt_bottoni.get_children():
		c.queue_free()
	if coda_rapporti.is_empty() and _fase_mia("avanza"):
		batt_lbl_dett.text += ("  " if batt_lbl_dett.text.strip_edges() != "" else "") + "Avanzata: tocca un'unità illuminata sulla mappa per farla avanzare."
		batt_bottoni.add_child(bottone("Nessuna avanzata", func():
			_chiudi_battaglia()
			_invia({"a": "avanza", "u": ""}), 19))
		_aggiorna_pannello()
		return
	var la := int(batt_rep["lato"])
	if _chi(la) != "io":
		batt_bottoni.add_child(bottone("Salta i prossimi in questa fase", func():
			salta_fase = "%d|%d" % [int(m.s["turno"]), la]
			coda_rapporti.clear()
			_chiudi_battaglia(), 17))
	elif not coda_rapporti.is_empty():
		batt_bottoni.add_child(bottone("Salta gli altri (%d)" % coda_rapporti.size(), func():
			coda_rapporti.clear()
			_chiudi_battaglia(), 17))
	batt_bottoni.add_child(bottone("Avanti", func(): _chiudi_battaglia(), 21))

func _chiudi_battaglia(subito := false) -> void:
	batt_gen += 1
	batt_aperta = false
	batt_pre = false
	batt_rep = {}
	sel_avanza = ""
	var pn := batt_pannello
	batt_pannello = null
	if pn != null and is_instance_valid(pn):
		if subito:
			pn.queue_free()
		else:
			var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(pn, "offset_top", 20.0, 0.25)
			tw.parallel().tween_property(pn, "offset_bottom", ALTEZZA_BATT + 20.0, 0.25)
			tw.tween_callback(pn.queue_free)
	if m != null:
		_aggiorna_tutto()

## Avanzata dopo il combattimento con un tocco sulla mappa: prima l'unità, poi (se serve) la destinazione
func _clic_avanza(h: String) -> void:
	var rq := m.richiesta()
	var dest := {}
	for c in rq["cand"]:
		if not dest.has(c[0]):
			dest[c[0]] = []
		dest[c[0]].append(c[1])
	if sel_avanza != "" and dest.get(sel_avanza, []).has(h):
		_avanza_con(sel_avanza, h)
		return
	var qui := []
	for id in dest:
		if m.s["unita"][id]["h"] == h:
			qui.append(id)
	if qui.is_empty():
		return
	var id: String = qui[0]
	if qui.has(sel_avanza) and qui.size() > 1:
		id = qui[(qui.find(sel_avanza) + 1) % qui.size()]
	if dest[id].size() == 1 and qui.size() == 1:
		_avanza_con(id, dest[id][0])
		return
	sel_avanza = id
	_notifica("%s: tocca l'esagono in blu dove avanzare%s." % [m.nome(id), " (tocca di nuovo per l'altra unità)" if qui.size() > 1 else ""])
	_aggiorna_evidenze()

func _avanza_con(id: String, h: String) -> void:
	sel_avanza = ""
	if batt_aperta:
		_chiudi_battaglia()
	_invia({"a": "avanza", "u": id, "h": h})

func _mostra_fine() -> void:
	var e: Dictionary = m.s["esito"]
	var vince := int(e.get("vince", -1))
	var v := _apri_popup("Vittoria dei %s" % Dati.LATI[vince] if vince >= 0 else "Fine", 780)
	v.add_child(etichetta(str(e.get("perche", "")), F_TESTO, 21))
	v.add_child(etichetta("Perdite: Francesi %d, Prussiani %d, Anglo-alleati %d." % [int(m.s["perdite"]["FR"]), int(m.s["perdite"]["PR"]), int(m.s["perdite"]["AA"])], F_TESTO, 19))
	var r := HBoxContainer.new()
	r.add_child(bottone("Guarda la mappa", _chiudi_popup, 20))
	r.add_child(bottone("Menu principale", mostra_menu, 20))
	v.add_child(r)

# =============================================================================================
# Ciclo: IA, rete, decisioni

func _process(delta: float) -> void:
	if not in_partita or m == null or m.finita():
		return
	if not coda_rapporti.is_empty() and not popup_aperto and not batt_aperta and _ci_sono_umani():
		_prossima_battaglia()
		return
	if popup_aperto or batt_aperta:
		return
	var r := m.richiesta()
	if r.is_empty():
		return
	var chi := _chi(int(r["lato"]))
	if chi == "ia":
		if invio_in_corso:
			return
		attesa += delta * velocita
		var pausa := 0.3 if r["k"] == "movimento" else 0.5
		if not _ci_sono_umani():
			pausa = 0.08
		if attesa >= pausa:
			attesa = 0.0
			var d: Dictionary = ia[int(r["lato"])].decidi(r)
			_invia(d)
	elif chi == "remoto" and not aspetto_rete:
		_aspetta_remoto()

func _ci_sono_umani() -> bool:
	return _chi(0) == "io" or _chi(1) == "io"

func _aspetta_remoto() -> void:
	aspetto_rete = true
	var n: int = m.s["azioni"]
	var d = await net.get_decision(codice, n)
	if d is Dictionary and not d.is_empty() and int(m.s["azioni"]) == n:
		_applica(d)
	else:
		await get_tree().create_timer(1.0).timeout
	aspetto_rete = false

func _invia(d: Dictionary) -> void:
	if invio_in_corso:
		return
	invio_in_corso = true
	if online:
		var n: int = m.s["azioni"]
		var ok := await net.post_decision(codice, n, d)
		if not ok:
			_notifica("Rete: non riesco a inviare la mossa (" + net.last_error + "). Riprova.")
			invio_in_corso = false
			return
	_applica(d)
	invio_in_corso = false

func _applica(d: Dictionary) -> void:
	var lato_prima: int = m.s["lato"]
	var turno_prima: int = m.s["turno"]
	var chi := _chi(int(m.richiesta().get("lato", lato_prima)))
	if not m.applica(d):
		if chi == "io":
			if d.get("a", "") == "fine" and m.richiesta().get("k", "") == "movimento":
				_notifica("Prima di finire: al massimo due unità per esagono.")
			else:
				_notifica("Mossa non valida")
		elif chi == "ia":
			# l'IA non deve bloccare la partita
			if not m.applica({"a": "fine"}):
				for h in m.ammassati():
					push_warning("ammassati " + h)
		_aggiorna_tutto()
		return
	for e in m.eventi:
		match e["k"]:
			"battaglia":
				var la := int(e["rep"]["lato"])
				if _ci_sono_umani() and not (_chi(la) != "io" and salta_fase == "%d|%d" % [int(m.s["turno"]), la]):
					coda_rapporti.append(e["rep"])
			"annuncio":
				_notifica(e["t"])
	if int(m.s["lato"]) != lato_prima or int(m.s["turno"]) != turno_prima:
		sel_hex = ""
		_annulla_selezione()
		_salva(false)
		if int(m.s["turno"]) != turno_prima and not m.finita():
			_notifica("%d giugno, ore %s%s" % [m.giorno(), m.ora(), " — notte" if m.notte() else (" — pioggia" if m.pioggia() else "")])
	_aggiorna_tutto()
	if m.finita():
		_salva(true)
		_mostra_fine()

func _salva(subito: bool) -> void:
	if online or m == null:
		return
	var st := {"motore": m.s, "umani": umani, "carattere": carattere_ia}
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(st))
		f.close()
	var ora := Time.get_unix_time_from_system()
	if (subito or ora - ultimo_salvataggio > 20.0) and not salvataggio_in_corso:
		ultimo_salvataggio = ora
		salvataggio_in_corso = true
		await net.salva_partita(st)
		salvataggio_in_corso = false
