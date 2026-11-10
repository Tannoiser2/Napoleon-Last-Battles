extends SceneTree
func _initialize():
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Mappa.carica()
	var t0 := Time.get_ticks_msec()
	var mi: MeshInstance3D = main._mappa_esagoni()
	var am: ArrayMesh = mi.mesh
	print("mappa 3D: %d ms, %d vertici, %d triangoli" % [Time.get_ticks_msec() - t0, am.surface_get_array_len(0), am.surface_get_array_index_len(0) / 3])
	quit()
