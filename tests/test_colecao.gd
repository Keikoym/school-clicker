extends SceneTree

var verificacoes: int = 0
var falhas: int = 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if condicao:
		print("PASSOU: " + descricao)
	else:
		falhas += 1
		push_error("FALHOU: " + descricao)

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/" + nome + ".png")

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
	var colecao = main.colecao
	verificar(not main.find_child("BotaoUpgrade3", true, false).disabled, "Botão da biblioteca ativo")
	colecao.comprar_item("casmurro")
	verificar(colecao.adquiridos.is_empty() and main.qi == 0, "Compra sem saldo bloqueada")
	main.qi = 5000
	main.find_child("BotaoUpgrade3", true, false).pressed.emit()
	verificar(colecao.painel.visible, "Botão abre a mochila")
	await foto("biblioteca")
	colecao.botoes["casmurro"].pressed.emit()
	verificar(main.qi == 4880 and main.obter_ganho_clique() == 2, "Livro comprado pelo botão aplica custo e bônus")
	colecao.comprar_item("casmurro")
	verificar(main.qi == 4880 and colecao.bonus_clique == 1, "Compra duplicada bloqueada")
	colecao.comprar_item("inexistente")
	verificar(main.qi == 4880, "ID desconhecido não altera saldo")
	for id in ["macunaima", "cortico", "caderno", "estojo", "luminaria"]:
		colecao.comprar_item(id)
	verificar(colecao.adquiridos.size() == 6 and main.qi == 2560, "Seis compras cobram os custos definidos")
	verificar(main.obter_ganho_clique() == 8 and main.obter_producao_passiva() == 9, "Coleção concede +7/clique e +9/s")
	main._on_timer_timeout()
	verificar(main.qi == 2569, "Itens produzem sem apontador")
	main.find_child("BotaoUpgradeClique", true, false).pressed.emit()
	verificar(main.obter_ganho_clique() == 9, "Upgrade original preserva bônus da coleção")
	var dados: Dictionary = main._criar_dados_salvamento()
	var arquivo := FileAccess.open("res://tests/colecao-roundtrip.json", FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()
	arquivo = FileAccess.open("res://tests/colecao-roundtrip.json", FileAccess.READ)
	var carregados: Dictionary = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	main._aplicar_dados_salvamento(carregados)
	main._aplicar_dados_salvamento(carregados)
	verificar(colecao.adquiridos.size() == 6 and main.obter_ganho_clique() == 9, "JSON em disco restaura coleção sem duplicar bônus")
	var antigos := dados.duplicate(true)
	antigos.erase("colecao")
	main._aplicar_dados_salvamento(antigos)
	verificar(colecao.adquiridos.is_empty() and main.obter_ganho_clique() == 2, "Save antigo sem coleção continua compatível")
	main._aplicar_dados_salvamento(carregados)
	for i in range(100):
		main._on_botao_clique_pressed()
	verificar(colecao.conquistas.has("cliques") and colecao.conquistas.size() == 5, "Conquistas de cliques, livros e materiais")
	colecao._selecionar_aba("Materiais")
	await foto("materiais")
	colecao._selecionar_aba("Conquistas")
	await foto("conquistas")
	colecao._selecionar_aba("Revisão")
	await foto("revisao")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	verificar(not colecao.painel.visible, "Esc fecha a mochila")
	main.prova1_concluida = true
	main._aplicar_progressao_provas()
	main.atualizar_interface()
	await process_frame
	main.find_child("BotaoEventoEspecial2", true, false).pressed.emit()
	await create_timer(0.6).timeout
	var prova = main.find_child("Prova2", true, false)
	var quiz = prova.minigame_instanciado_atual
	verificar(quiz.banco_perguntas.size() == 20, "Banco de 20 questões de Português")
	await foto("portugues")
	var saldo: int = main.qi
	colecao.comprar_item("casmurro")
	colecao.abrir()
	verificar(main.qi == saldo and not colecao.painel.visible, "Mochila bloqueada durante a prova")
	for botao in [quiz.botao1, quiz.botao2, quiz.botao3]:
		if botao.text != quiz.texto_resposta_correta:
			botao.pressed.emit()
			break
	verificar(prova.vidas == 2 and quiz.feedback_label.text.begins_with("Correta:"), "Erro tira uma vida e mostra resposta correta")
	await create_timer(1.9).timeout
	var vistas: Array[String] = []
	for i in range(5):
		verificar(not vistas.has(quiz.label_pergunta.text), "Pergunta sem repetição %d" % (i + 1))
		vistas.append(quiz.label_pergunta.text)
		for botao in [quiz.botao1, quiz.botao2, quiz.botao3]:
			if botao.text == quiz.texto_resposta_correta:
				botao.pressed.emit()
				break
		await create_timer(0.65).timeout
	await create_timer(1.4).timeout
	verificar(main.prova2_concluida and not main.modo_prova_ativo, "Cinco respostas reais concluem a prova de Português")
	verificar(colecao.conquistas.size() == 7, "Todas as sete conquistas podem ser obtidas")
	var estado: Dictionary = colecao.salvar()
	colecao.carregar(estado)
	verificar(colecao.conquistas.size() == 7 and colecao.cliques == 100, "Conquistas e cliques persistem")
	await create_timer(8.0).timeout
	print("RESULTADO COLEÇÃO: %d verificações, %d falhas" % [verificacoes, falhas])
	cena.queue_free()
	await process_frame
	quit(1 if falhas else 0)
