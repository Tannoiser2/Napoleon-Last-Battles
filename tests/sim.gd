extends SceneTree
## Partite automatiche IA contro IA: controlla che finiscano e mostra gli esiti.
## godot --headless --path . -s res://tests/sim.gd -- <scenario> [partite] [--log]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var sc: String = args[0] if args.size() > 0 else "bellealliance"
	var n := int(args[1]) if args.size() > 1 else 2
	var vinte := {-1: 0, 0: 0, 1: 0}
	var off := int(args[2]) if args.size() > 2 and str(args[2]).is_valid_int() else 0
	for p in range(off, off + n):
		var t0 := Time.get_ticks_msec()
		var mo := Motore.new()
		mo.nuova({"scen": sc, "seed": p * 7919 + 3})
		mo.diagnosi = "--diagnosi" in args
		var ia: Array = [IA.new(mo), IA.new(mo)]
		if "--fr_vecchia" in args:
			ia[0] = IAVecchia.new(mo)
		if "--al_vecchia" in args:
			ia[1] = IAVecchia.new(mo)
		for a in args:
			if str(a).contains("="):
				var kv := str(a).split("=")
				for x in ia:
					if x is IA:
						x.set(kv[0], float(kv[1]))
		var passi := 0
		var conta := {}
		var rifiuti := 0
		while not mo.finita() and passi < 20000:
			var rq := mo.richiesta()
			if rq.is_empty():
				push_error("nessuna richiesta")
				break
			var d: Dictionary = ia[int(rq["lato"])].decidi(rq)
			conta[d.get("a", "?")] = conta.get(d.get("a", "?"), 0) + 1
			if not mo.applica(d):
				rifiuti += 1
				if rifiuti < 8:
					print("RIFIUTATA ", rq.get("k"), " ", d)
				if not mo.applica({"a": "fine"}):
					print("BLOCCO ", rq, " ammassati ", mo.ammassati())
					break
			passi += 1
		var e: Dictionary = mo.s["esito"]
		vinte[int(e.get("vince", -1))] += 1
		print("V%d %s %d: %s turno %d passi %d rifiuti %d | %s | perdite %s pv %s dem %s | %s | %d ms" % [int(e.get("vince", -1)), sc, p, "FINITA" if mo.finita() else "NON FINITA", int(mo.s["turno"]) + 1, passi, rifiuti, e.get("perche", ""), str(mo.s["perdite"]), str(mo.s["pv"]), str(mo.s["dem"]), str(conta), Time.get_ticks_msec() - t0])
		if sc == "ligny":
			var nv := 0
			for h in ["3755", "3854", "3855", "3955", "3256", "3357", "3457"]:
				if int(mo.s["occup"].get(h, -1)) == 0:
					nv += 1
			mo.stat["villaggi_FR"] = nv
			mo.stat["turno_fine"] = int(mo.s["turno"]) + 1
		print("STAT ", JSON.stringify(mo.stat))
		if "--log" in args:
			for l in mo.s["log"]:
				print("   ", l)
	print("esiti (nessuno, Francia, Alleati): ", vinte)
	quit()
