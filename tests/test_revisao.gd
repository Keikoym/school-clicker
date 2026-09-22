extends SceneTree

const ARQUIVO := "res://tests/progresso-teste.json"
var falhas: int = 0
var total: int = 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(condicao: bool, descricao: String) -> void:
	total += 1
	if condicao:
		print("PASSOU: " + descricao)
	else:
		falhas += 1
		push_error("FALHOU: " + descricao)

func escrever(texto: String) -> void:
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	arquivo.store_string(texto)
	arquivo.close()

func _run() -> void:
	escrever('{"versao":1,"qi":0}')
	var cena = load("res://principalgame.tscn").instantiate()
	var main = cena.get_node("Main")
	var texturas = main.texturas_botao_clique
	main.set_script(load("res://tests/main_save_isolado.gd"))
	main.texturas_botao_clique = texturas
	root.add_child(cena)
	current_scene = cena
	await process_frame
	main.timer_autoclick.stop()
	main.qi = 2000
	main.colecao.comprar_item("casmurro")
	main.colas = 3
	main.salvar_progresso()
	main.qi = 0
	main.colas = 0
	main.carregar_progresso()
	verificar(main.colas == 3, "Estoque de colas persiste em disco")
	verificar(main.qi == 1860 and main.colecao.adquiridos.has("casmurro"), "Funções reais de save/load restauram QI e livro")
	main.qi = 777
	main.salvar_progresso()
	main.qi = 0
	main.carregar_progresso()
	verificar(main.qi == 777 and not FileAccess.file_exists(ARQUIVO + ".tmp"), "Substituição do save existente conclui sem temporário")
	escrever('{"versao":999,"qi":4321}')
	print("CENÁRIO ESPERADO: recusar save de versão futura")
	main.carregar_progresso()
	main.salvar_progresso()
	verificar(main.salvamento_bloqueado and FileAccess.get_file_as_string(ARQUIVO).contains("4321"), "Save futuro é preservado após tentativa de autosave")
	escrever("save corrompido de teste")
	print("CENÁRIO ESPERADO: recusar JSON inválido")
	main.carregar_progresso()
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	verificar(FileAccess.get_file_as_string(ARQUIVO) == "save corrompido de teste", "Fechamento não sobrescreve save inválido")
	escrever('{"versao":1,"qi":999}')
	main.carregar_progresso()
	verificar(not main.salvamento_bloqueado and main.qi == 999, "Save válido reabilita gravação")
	main.iniciar_modo_prova2()
	verificar(not main.modo_prova_ativo, "Prova 2 não pode iniciar antes da aprovação na Prova 1")
	main.iniciar_modo_prova()
	await create_timer(0.5).timeout
	var prova = main.find_child("Prova1", true, false)
	main.colas = 2
	prova.minigame_instanciado_atual.ajuda_cola.usar()
	var gravado: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	verificar(gravado.get("colas", -1) == 1, "Uso da cola grava estoque imediatamente em disco")
	prova.vidas = 2
	main.iniciar_modo_prova()
	verificar(prova.vidas == 2, "Iniciar prova ativa novamente não reinicia vidas")
	var saldo: int = main.qi
	for nome in ["BotaoUpgradeClique", "BotaoGeradorQI", "BotaoMultiplicadorClique", "BotaoMultiplicadorPassivo", "BotaoEventoEspecial", "BotaoEventoEspecial2"]:
		main.find_child(nome, true, false).pressed.emit()
	verificar(main.qi == saldo and prova.vidas == 2, "Sinais de compra durante prova não gastam QI nem reiniciam prova")
	main.colecao.mensagens.append("Teste de aviso")
	main.colecao.atualizar()
	await process_frame
	verificar(not main.colecao.aviso.visible, "Aviso de conquista não cobre prova")
	prova._on_tempo_geral_esgotado()
	await create_timer(1.4).timeout
	main.colecao.abrir()
	await process_frame
	verificar(not main.colecao.aviso.visible, "Aviso não cobre a mochila")
	main.colecao.fechar()
	await process_frame
	await process_frame
	verificar(main.colecao.aviso.visible, "Aviso pendente aparece ao retornar ao jogo")
	main.timer_salvamento.stop()
	cena.queue_free()
	await process_frame
	print("RESULTADO REVISÃO: %d verificações, %d falhas" % [total, falhas])
	quit(1 if falhas else 0)
