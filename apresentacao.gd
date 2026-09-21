extends RefCounted

static func painel(cor: String, borda: String = "d4c6a2") -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(cor)
	estilo.border_color = Color(borda)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(9)
	return estilo

static func configurar(main: Control) -> void:
	var loja: Panel = main.janela_loja
	loja.add_theme_stylebox_override("panel", painel("f5eedb"))
	loja.find_child("FundoLoja", true, false).hide()
	var titulo: Label = loja.find_child("TituloLoja", true, false)
	titulo.text = "MATERIAIS DE ESTUDO"
	titulo.add_theme_font_size_override("font_size", 21)
	var nomes := ["BotaoUpgradeClique", "BotaoGeradorQI", "BotaoMultiplicadorClique", "BotaoMultiplicadorPassivo", "BotaoUpgrade3", "BotaoEventoEspecial", "BotaoEventoEspecial2"]
	for nome in nomes:
		var botao: Button = loja.find_child(nome, true, false)
		botao.add_theme_font_override("font", ThemeDB.fallback_font)
		botao.add_theme_font_size_override("font_size", 12)
		botao.add_theme_color_override("font_color", Color("243e34"))
		botao.add_theme_color_override("font_hover_color", Color("173c2d"))
		botao.add_theme_color_override("font_pressed_color", Color("173c2d"))
		botao.add_theme_color_override("font_disabled_color", Color("6e7167"))
		for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
			var estilo := painel("fffaf0")
			match estado:
				"hover": estilo = painel("e5f0e5", "3c8066")
				"pressed": estilo = painel("cde3d0", "3c8066")
				"disabled": estilo = painel("e7e3d6", "cbc7b9")
				"focus":
					estilo = painel("ffffff00", "b58125")
					estilo.set_border_width_all(2)
			estilo.content_margin_left = 42 if botao.get_child_count() > 0 else 8
			estilo.content_margin_right = 8
			botao.add_theme_stylebox_override(estado, estilo)
	var saldo := Label.new()
	saldo.name = "SaldoLoja"
	saldo.position = Vector2(32, 256)
	saldo.size = Vector2(476, 22)
	saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saldo.add_theme_font_size_override("font_size", 13)
	saldo.add_theme_color_override("font_color", Color("315e4b"))
	loja.add_child(saldo)
	var mensagem: Label = main.mensagem_loja
	mensagem.position = Vector2(32, 285)
	mensagem.size = Vector2(476, 28)
	mensagem.add_theme_font_override("font", ThemeDB.fallback_font)
	mensagem.add_theme_font_size_override("font_size", 12)
	mensagem.add_theme_constant_override("outline_size", 0)
	var dica := Label.new()
	dica.name = "ResumoEstudo"
	dica.position = Vector2(174, 281)
	dica.size = Vector2(292, 20)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica.add_theme_font_size_override("font_size", 12)
	dica.add_theme_color_override("font_color", Color("213f32"))
	dica.add_theme_color_override("font_outline_color", Color("fff5df"))
	dica.add_theme_constant_override("outline_size", 3)
	main.add_child(dica)
	# A arte antiga é maior que o retângulo de saída. Um botão textual evita corte.
	main.get_node("BotaoSair").hide()
	var sair := Button.new()
	sair.text = "Salvar e sair"
	sair.position = Vector2(12, 315)
	sair.size = Vector2(122, 30)
	sair.add_theme_stylebox_override("normal", painel("243e34"))
	sair.add_theme_stylebox_override("hover", painel("3c7057"))
	sair.add_theme_font_size_override("font_size", 12)
	sair.pressed.connect(main._on_botao_sair_pressed)
	main.add_child(sair)

static func atualizar(main: Control) -> void:
	var saldo: Label = main.janela_loja.get_node_or_null("SaldoLoja")
	if saldo:
		saldo.text = "%s QI disponíveis  ·  +%s/clique  ·  +%s/s" % [numero(main.qi), numero(main.obter_ganho_clique()), numero(main.obter_producao_passiva())]
	var resumo: Label = main.get_node_or_null("ResumoEstudo")
	if resumo:
		resumo.text = "+%s QI por clique  ·  +%s QI por segundo" % [numero(main.obter_ganho_clique()), numero(main.obter_producao_passiva())]
	main.contador_label.text = "QI: " + numero(main.qi)

static func numero(valor: int) -> String:
	if valor >= 1000000000: return "%.1f bi" % (valor / 1000000000.0)
	if valor >= 1000000: return "%.1f mi" % (valor / 1000000.0)
	if valor >= 10000: return "%.1f mil" % (valor / 1000.0)
	return str(valor)
