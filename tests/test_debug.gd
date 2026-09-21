extends SceneTree

var falhas := 0
var total := 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas += 1
		push_error("FALHOU: " + texto)
	else:
		print("PASSOU: " + texto)

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/" + nome + ".png")

func _run() -> void:
	var menu = load("res://menu_principal.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(0.5).timeout
	await foto("revisao_menu")
	menu.queue_free()
	await process_frame
	var cena = load("res://principalgame.tscn").instantiate()
	var main = cena.get_node("Main")
	# Usa as funções reais de save em arquivo separado do progresso do jogador.
	var texturas = main.texturas_botao_clique
	main.set_script(load("res://tests/main_save_isolado.gd"))
	main.texturas_botao_clique = texturas
	var arquivo := FileAccess.open("res://tests/progresso-teste.json", FileAccess.WRITE)
	arquivo.store_string('{"versao":1,"qi":321}')
	arquivo.close()
	root.add_child(cena)
	current_scene = cena
	await process_frame
	main.timer_autoclick.stop()
	await foto("revisao_jogo")
	var dev = main.ferramentas
	dev.adicionar_qi()
	verificar(main.qi == 321, "QI de debug exige ativação")
	dev.abrir("dev")
	dev.iniciar_debug()
	dev.adicionar_qi()
	verificar(main.debug_ativo and main.qi == 1321, "Debug concede QI somente na sessão")
	main.salvar_progresso()
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	main.solicitar_salvamento()
	verificar(FileAccess.get_file_as_string("res://tests/progresso-teste.json").contains("321") and not FileAccess.get_file_as_string("res://tests/progresso-teste.json").contains("1321"), "Salvar e fechar em debug preservam arquivo anterior")
	verificar(main.timer_salvamento.is_stopped(), "Debug bloqueia autosave")
	await foto("revisao_debug")
	dev.abrir("notas")
	await foto("revisao_notas")
	verificar(dev.conteudo.get_child_count() > 4, "Notas exibem histórico")
	dev.fechar()
	main.colecao.comprar_item("casmurro")
	main.prova1_concluida = true
	main._aplicar_progressao_provas()
	await process_frame
	dev.encerrar_debug()
	await process_frame
	main = current_scene.get_node("Main")
	main.timer_autoclick.stop()
	verificar(not main.debug_ativo and main.qi == 321, "Encerrar restaura saldo e desativa debug")
	verificar(not main.colecao.adquiridos.has("casmurro"), "Compra de teste é descartada")
	verificar(not main.prova1_concluida and main.find_child("BotaoEventoEspecial", true, false) != null, "Prova e botão removido são restaurados")
	main.modo_prova_ativo = true
	main.ferramentas.abrir("dev")
	main.ferramentas.iniciar_debug()
	verificar(not main.ferramentas.painel.visible and not main.debug_ativo, "Ferramentas bloqueadas durante prova")
	main.modo_prova_ativo = false
	main.salvamento_bloqueado = true
	main.ferramentas.iniciar_debug()
	verificar(not main.debug_ativo, "Save inválido impede ativação debug")
	for caminho in ["res://minigames_quiz.tscn", "res://minigames_quiz2.tscn"]:
		var quiz = load(caminho).instantiate()
		root.add_child(quiz)
		await process_frame
		await process_frame
		var resultados: Array[bool] = []
		quiz.minigame_terminou.connect(func(venceu: bool): resultados.append(venceu))
		quiz.perguntas_disponiveis.clear()
		quiz.puxar_nova_pergunta()
		verificar(resultados.is_empty() and not quiz.pergunta_atual.is_empty(), "Banco esgotado não aprova: " + caminho)
		quiz.banco_perguntas.clear()
		quiz.perguntas_disponiveis.clear()
		quiz.puxar_nova_pergunta()
		verificar(resultados == [false], "Banco vazio não causa divisão por zero: " + caminho)
		quiz.queue_free()
		await process_frame
	current_scene.queue_free()
	await process_frame
	print("RESULTADO DEBUG: %d verificações, %d falhas" % [total, falhas])
	quit(1 if falhas else 0)