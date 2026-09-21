extends SceneTree

var falhas: int = 0
var verificacoes: int = 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		push_error("FALHOU: " + descricao)
	else:
		print("PASSOU: " + descricao)

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
	verificar(main.qi == 0, "Progresso isolado do save pessoal")
	main.botao_clique.pressed.emit()
	verificar(main.qi == 1, "Clique concede 1 QI")
	main.qi = 10000
	main.atualizar_interface()
	var compras = ["BotaoUpgradeClique", "BotaoGeradorQI", "BotaoMultiplicadorClique", "BotaoMultiplicadorPassivo"]
	for nome in compras:
		var botao = main.find_child(nome, true, false)
		var custo: int = botao.custo_upgrade
		var saldo: int = main.qi
		botao.pressed.emit()
		verificar(main.qi == saldo - custo, "Custo correto: " + nome)
		verificar(botao.tooltip_text.contains("→"), "Prévia atualizada: " + nome)
	verificar(main.valor_do_clique_base == 2 and is_equal_approx(main.multiplicador_clique, 1.2), "Upgrades de clique aplicados")
	verificar(main.qi_por_segundo_base == 1 and is_equal_approx(main.multiplicador_passivo_bonus, 0.15), "Upgrades passivos aplicados")
	var saldo: int = main.qi
	main._on_timer_timeout()
	verificar(main.qi == saldo + 1, "Produção passiva e arredondamento")
	main._on_botao_loja_pressed()
	await create_timer(0.1).timeout
	main._on_botao_fechar_loja_pressed()
	await create_timer(0.1).timeout
	main._on_botao_loja_pressed()
	await create_timer(0.5).timeout
	verificar(main.janela_loja.visible and main.janela_loja.position.is_equal_approx(main.posicao_centro_loja), "Reabrir durante fechamento mantém loja aberta no lugar certo")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/loja.png")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await create_timer(0.4).timeout
	verificar(not main.janela_loja.visible, "Esc fecha a loja pelo sistema de entrada")
	main._on_botao_clique_mouse_entered()
	main._on_botao_loja_mouse_entered()
	main._on_botao_clique_mouse_exited()
	await create_timer(0.2).timeout
	verificar(main.botao_clique.scale.is_equal_approx(Vector2.ONE) and main.botao_loja.scale.is_equal_approx(Vector2(1.07, 1.07)), "Hover independente entre botões")
	main._on_botao_loja_mouse_exited()
	var dados: Dictionary = main._criar_dados_salvamento()
	main.qi = 0
	main._aplicar_dados_salvamento(dados)
	verificar(main.qi == int(dados.qi) and main.valor_do_clique_base == 2, "Restauração dos dados de progresso em memória")
	var prova2 = main.find_child("BotaoEventoEspecial2", true, false)
	verificar(not prova2.visible, "Prova 2 bloqueada no início")
	main._on_botao_loja_pressed()
	main.iniciar_modo_prova()
	await create_timer(0.5).timeout
	verificar(main.modo_prova_ativo and not main.janela_loja.visible, "Prova interrompe abertura da loja")
	saldo = main.qi
	main.botao_clique.pressed.emit()
	main._on_timer_timeout()
	verificar(main.qi == saldo, "Clique e produção pausam durante prova")
	var prova1 = main.find_child("Prova1", true, false)
	verificar(prova1.vidas == 3 and not prova1.timer_geral_prova.is_stopped(), "Prova inicia com 3 vidas e tempo ativo")
	for i in range(5):
		prova1._on_minigame_concluido(true)
		await create_timer(0.4).timeout
	await create_timer(1.4).timeout
	verificar(main.prova1_concluida and prova2.visible and not main.modo_prova_ativo, "Vitória da Prova 1 libera Prova 2 e retoma jogo")
	main.iniciar_modo_prova2()
	await create_timer(0.5).timeout
	var prova = main.find_child("Prova2", true, false)
	prova._on_tempo_geral_esgotado()
	await create_timer(1.4).timeout
	verificar(not main.modo_prova_ativo and not main.prova2_concluida and prova2.visible, "Tempo esgotado permite tentar a Prova 2 novamente")
	print("RESULTADO: %d verificações, %d falhas" % [verificacoes, falhas])
	cena.queue_free()
	await process_frame
	quit(1 if falhas else 0)
