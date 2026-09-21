extends SceneTree

const ITENS := [
	["dom_casmurro", "Dom Casmurro"], ["macunaima", "Macunaíma"], ["o_cortico", "O Cortiço"],
	["caderno_resumos", "Caderno de resumos"], ["estojo_completo", "Estojo completo"],
	["luminaria", "Luminária"], ["lapis", "Lápis"], ["apontador", "Apontador"],
	["marca_texto", "Marca-texto"], ["corretivo", "Corretivo"]
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var falhas := 0
	var tela := Control.new()
	root.add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color("f2ecd9")
	tela.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var titulo := Label.new()
	titulo.text = "SCHOOL CLICKER • NOVOS SPRITES"
	titulo.position = Vector2(22, 10)
	titulo.add_theme_color_override("font_color", Color("30473d"))
	titulo.add_theme_font_size_override("font_size", 19)
	tela.add_child(titulo)
	for i in range(ITENS.size()):
		var caminho: String = "res://assets/itens/" + ITENS[i][0] + ".png"
		var imagem := Image.load_from_file(caminho)
		if imagem == null or imagem.is_empty() or imagem.detect_alpha() == Image.ALPHA_NONE or imagem.get_pixel(0, 0).a != 0.0:
			falhas += 1
			push_error("Sprite sem transparência válida: " + caminho)
		else:
			print("PASSOU: PNG com transparência: " + ITENS[i][0])
		var textura = load(caminho)
		if textura == null:
			falhas += 1
			continue
		var pos := Vector2(20 + (i % 5) * 123, 46 + (i / 5) * 150)
		var sprite := TextureRect.new()
		sprite.position = pos
		sprite.size = Vector2(106, 112)
		sprite.texture = textura
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tela.add_child(sprite)
		var nome := Label.new()
		nome.text = ITENS[i][1]
		nome.position = pos + Vector2(0, 115)
		nome.size.x = 110
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.add_theme_font_size_override("font_size", 11)
		nome.add_theme_color_override("font_color", Color("30473d"))
		tela.add_child(nome)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/sprites_catalogo.png")
	print("RESULTADO SPRITES: 10 arquivos, %d falhas" % falhas)
	tela.queue_free()
	await process_frame
	quit(1 if falhas else 0)
