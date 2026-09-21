extends SceneTree

func _initialize() -> void:
	var falhas := 0
	var total := 0
	for nome in DirAccess.get_files_at("res://"):
		if nome.ends_with(".gd"):
			total += 1
			var script = load("res://" + nome)
			if script == null or not script.can_instantiate():
				falhas += 1
				push_error("Script inválido: " + nome)
	print("AUDITORIA: %d scripts, %d falhas" % [total, falhas])
	quit(1 if falhas else 0)
