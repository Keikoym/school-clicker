extends SceneTree

var falhas: int = 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas += 1
		push_error("FALHOU: " + descricao)
	else:
		print("PASSOU: " + descricao)

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/" + nome + ".png")

func clicar(posicao: Vector2) -> void:
	posicao = root.get_final_transform() * posicao
	var movimento := InputEventMouseMotion.new()
	movimento.position = posicao
	Input.parse_input_event(movimento)
	await process_frame
	for pressionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.position = posicao
		evento.pressed = pressionado
		Input.parse_input_event(evento)
		await process_frame

func _run() -> void:
	var cena = load("res://principalgame.tscn").instantiate()
	var main = cena.get_node("Main")
	var texturas = main.texturas_botao_clique
	main.set_script(load("res://tests/main_isolado.gd"))
	main.texturas_botao_clique = texturas
	root.add_child(cena)
	current_scene = cena
	await process_frame
	main.timer_autoclick.stop()
	verificar(main.itens_mesa.adquiridos.is_empty(), "Mesa começa sem colecionáveis não comprados")
	main.qi = 20000
	for nome in ["BotaoUpgradeClique", "BotaoGeradorQI", "BotaoMultiplicadorClique", "BotaoMultiplicadorPassivo"]:
		main.find_child(nome, true, false).pressed.emit()
	for item in main.colecao.CATALOGO:
		main.colecao.comprar_item(item.id)
	await create_timer(0.5).timeout
	main.colecao.mensagens.clear()
	main.colecao.exibindo_aviso = false
	verificar(main.itens_mesa.adquiridos.size() == 6, "Todos os itens comprados aparecem na mesa")
	verificar(main.contador_label.position.y >= 300, "Contador de QI no rodapé")
	await foto("mesa_completa")
	main._on_botao_loja_pressed()
	await create_timer(0.5).timeout
	var volume = main.get_node("Button")
	var volume_anterior: int = volume.volume_porcentagem
	var fechar = main.find_child("BotaoFecharLoja", true, false)
	await clicar(fechar.get_global_rect().get_center())
	await create_timer(0.4).timeout
	verificar(not main.janela_loja.visible, "Clique real no X fecha o estojo")
	verificar(volume.volume_porcentagem == volume_anterior, "X não altera volume")
	await clicar(volume.get_global_rect().get_center())
	verificar(volume.volume_porcentagem == 75, "Volume funciona após fechar o estojo")
	await clicar(main.botao_loja.get_global_rect().get_center())
	await create_timer(0.5).timeout
	verificar(main.janela_loja.visible, "Clique no estojo da mesa reabre loja")
	await foto("estojo_aberto")
	await clicar(fechar.get_global_rect().get_center())
	await create_timer(0.4).timeout
	verificar(not main.janela_loja.visible and volume.volume_porcentagem == 75, "X funciona repetidamente sem acionar som")
	for nome in ["Prova1", "Prova2"]:
		if nome == "Prova1":
			main.iniciar_modo_prova()
		else:
			main.prova1_concluida = true
			main.iniciar_modo_prova2()
		await create_timer(0.5).timeout
		var prova = main.find_child(nome, true, false)
		verificar(prova.indicador_vidas.vidas == 3, nome + ": três corações no início")
		await foto(nome.to_lower() + "_vidas3")
		prova.vidas = 1
		prova.atualizar_visual_vidas()
		await create_timer(0.4).timeout
		verificar(prova.indicador_vidas.vidas == 1, nome + ": perda de vidas refletida no indicador")
		await foto(nome.to_lower() + "_vidas1")
		prova._on_tempo_geral_esgotado()
		await create_timer(1.4).timeout
	var estado: Dictionary = main._criar_dados_salvamento()
	main.itens_mesa.atualizar({})
	main._aplicar_dados_salvamento(estado)
	verificar(main.itens_mesa.adquiridos.size() == 6, "Itens da mesa reaparecem ao carregar progresso")
	print("RESULTADO MESA: %d falhas" % falhas)
	cena.queue_free()
	await process_frame
	quit(1 if falhas else 0)
