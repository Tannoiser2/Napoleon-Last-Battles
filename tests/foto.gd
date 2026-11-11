extends SceneTree
## Screenshot dell'interfaccia: xvfb-run godot --path . -s res://tests/foto.gd -- <modo> [scenario]
## modo: menu | nuova | partita | movimento | combattimento | attacco_ia | plance | tabelle | vista | fine
var main
func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()
func shot(nome: String):
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/shot_%s.png" % nome)
	print("shot ", nome)
func _run():
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "menu"
	var sc: String = args[1] if args.size() > 1 else "bellealliance"
	await shot("menu")
	if modo.begins_with("menu_"):
		main.scelta_scen = modo.substr(5)
		main._menu_scheda()
		await shot(modo)
		quit(); return
	if modo == "menu":
		quit(); return
	if modo == "nuova":
		main._menu_nuova()
		await shot("nuova")
		quit(); return
	main.scelta_scen = sc
	main.scelta_modo = "ia"
	if "--pedine2015" in OS.get_cmdline_user_args():
		main.pedine_2015 = true
	main.scelta_lato = 1 if modo == "attacco_ia" else 0
	if "--capi" in OS.get_cmdline_user_args():
		main.opz_scelte["capi_comando"] = true
	main._avvia_locale()
	if "--rif" in OS.get_cmdline_user_args():
		main.vedi_rif = true
		main._aggiorna_evidenze()
	if "--comando" in OS.get_cmdline_user_args():
		main.vedi_comando = true
		main._aggiorna_evidenze()
	if modo == "attacco_ia":
		# l'IA francese attacca: si aspetta il primo pannello di battaglia e il suo esito
		main.velocita = 20.0
		var t0 := Time.get_ticks_msec()
		while not main.batt_aperta and Time.get_ticks_msec() - t0 < 120000:
			await process_frame
		await create_timer(4.5).timeout
		await shot("attacco_ia")
		quit(); return
	await shot("partita_" + sc)
	if modo == "partita":
		quit(); return
	if modo == "movimento":
		for id in main.m.s["unita"]:
			if main.m.puo_muovere(id) and main.m.lato_di(id) == 0:
				main._clic(main.m.s["unita"][id]["h"])
				main._centra_su(main.m.s["unita"][id]["h"], 9.0)
				break
		await shot("movimento")
		quit(); return
	if modo == "effetti":
		# parabola dell'artiglieria e unità eliminata (scatto a metà effetto)
		var art := ""
		var bers := ""
		for id in main.m.s["unita"]:
			if main.m.lato_di(id) == 0 and main.m.tipo(id) in ["A", "HA"] and main.m.s["unita"][id]["st"] == "mappa":
				art = id
				break
		var ha: String = main.m.s["unita"][art]["h"]
		for id in main.m.s["unita"]:
			if main.m.lato_di(id) == 1 and main.m.s["unita"][id]["st"] == "mappa" and Mappa.distanza(ha, main.m.s["unita"][id]["h"]) <= 4:
				bers = main.m.s["unita"][id]["h"]
				break
		if bers == "":
			bers = Mappa.vicini(Mappa.vicini(ha)[0])[0]
		main._centra_su(bers, 6.0)
		main.nodo_evid.add_child(main._parabola(ha, bers, Color(0.98, 0.62, 0.1)))
		var vittima: String = main.m.unita_in(bers, 1)[0] if not main.m.unita_in(bers, 1).is_empty() else ""
		if vittima != "":
			var n = main.nodi_pezzi[vittima]
			main.nodi_pezzi.erase(vittima)
			main._anima_eliminazione(n)
		await create_timer(0.12).timeout
		root.get_viewport().get_texture().get_image().save_png("/tmp/shot_effetti.png")
		await create_timer(0.35).timeout
		root.get_viewport().get_texture().get_image().save_png("/tmp/shot_effetti2.png")
		print("shot effetti")
		quit(); return
	if modo == "plance":
		main._plance_popup()
		await shot("plance")
		quit(); return
	if modo == "tabelle":
		main._tabelle_popup()
		await shot("tabelle")
		quit(); return
	if modo == "vista":
		main.pitch = -0.55
		main.distanza = 7.0
		main._aggiorna_camera()
		await shot("vista")
		quit(); return
	# l'IA gioca anche per il lato umano fino al combattimento o alla fine
	main.velocita = 50.0
	var passi := 0
	while passi < 4000 and not main.m.finita():
		await process_frame
		var r: Dictionary = main.m.richiesta()
		if modo == "combattimento" and r.get("k", "") == "combattimento" and main._chi(int(r["lato"])) == "io":
			var ob: Dictionary = main.m.obblighi()
			if not ob["nemici"].is_empty():
				main._clic(ob["nemici"][0])
				main._centra_su(ob["nemici"][0], 8.0)
				await shot("combattimento")
				var d: Dictionary = {"a": "attacco", "dif": main.sel_dif.duplicate(), "att": main.sel_att.keys()}
				await main._invia(d)
				await create_timer(0.15).timeout
				root.get_viewport().get_texture().get_image().save_png("/tmp/shot_battaglia_frecce.png")
				await create_timer(1.6).timeout
				root.get_viewport().get_texture().get_image().save_png("/tmp/shot_battaglia_riga.png")
				main._finale_battaglia()
				await shot("battaglia_esito")
				var rq: Dictionary = main.m.richiesta()
				if rq.get("k", "") == "avanza":
					var c: Array = rq["cand"][0]
					main._clic(main.m.s["unita"][c[0]]["h"])
					if main.sel_avanza != "":
						main._clic(c[1])
					await shot("avanzata")
					print("AVANZATA ", main.m.s["unita"][c[0]]["h"] == c[1], " richiesta ora ", main.m.richiesta().get("k", ""), " pannello aperto ", main.batt_aperta)
				quit(); return
		if main.popup_aperto:
			main._chiudi_popup()
			main.coda_rapporti.clear()
		if main.batt_aperta:
			main.coda_rapporti.clear()
			main._chiudi_battaglia(true)
		if r.is_empty() or main._chi(int(r["lato"])) != "io":
			continue
		var d: Dictionary = main.ia[int(r["lato"])].decidi(r)
		await main._invia(d)
		passi += 1
	for i in 30: await process_frame
	await shot("fine")
	quit()
