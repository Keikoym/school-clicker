extends SceneTree

var total := 0
var falhas := 0

func _initialize() -> void:
	run.call_deferred()

func verificar(ok: bool, descricao: String) -> void:
	total += 1
	if not ok:
		falhas += 1
		push_error("FALHOU: " + descricao)

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/loja_nova_" + nome + ".png")

func run() -> void:
	var cena = load("res://principalgame.tscn").instantiate()
	var main = cena.get_node("Main")
	var texturas = main.texturas_botao_clique
	main.set_script(load("res://tests/main_isolado.gd"))
	main.texturas_botao_clique = texturas
	root.add_child(cena)
	current_scene = cena
	await process_frame
	main.timer_autoclick.stop()
	var loja = main.catalogo_loja
	verificar(loja.abas.size() == 5, "Cinco categorias diretas")
	main.comprar_cola()
	verificar(main.colas == 0 and main.qi == 0, "Compra sem saldo bloqueada")
	main.qi = 5000
	main.atualizar_interface()
	main._on_botao_loja_pressed()
	await create_timer(0.5).timeout
	await foto("melhorias")
	await clicar(loja.cartoes[0].botao)
	verificar(main.valor_do_clique_base == 2 and main.qi == 4980, "Compra reutiliza upgrade original")
	await clicar(loja.abas["Livros"])
	verificar(loja.aba == "Livros", "Clique real troca categoria")
	await clicar(loja.cartoes[0].botao)
	verificar(main.colecao.adquiridos.has("casmurro") and not main.colecao.painel.visible, "Compra livro sem outra janela")
	var antes: int = main.qi
	loja.comprar("casmurro")
	verificar(main.qi == antes, "Colecionável não é cobrado duas vezes")
	await foto("livros")
	verificar(not main.colecao.aviso.visible, "Aviso de conquista não cobre loja")
	loja.selecionar("Materiais")
	await foto("materiais")
	loja.selecionar("Colas")
	for i in range(6): loja.comprar("cola")
	verificar(main.colas == 5 and main.qi == antes - 500, "Limite de cinco colas sem cobrança extra")
	await foto("colas")
	var save: Dictionary = main._criar_dados_salvamento()
	main.colas = 0
	main._aplicar_dados_salvamento(save)
	verificar(main.colas == 5, "Estoque restaura do save")
	save.erase("colas")
	main._aplicar_dados_salvamento(save)
	verificar(main.colas == 0, "Save legado inicia sem colas")
	main.colas = 5
	loja.selecionar("Provas")
	antes = main.qi
	loja.comprar("prova2")
	verificar(main.qi == antes and not main.modo_prova_ativo, "Prova 2 bloqueada sem gastar")
	await foto("provas")
	for numero in [1, 2]:
		if numero == 2:
			main.prova1_concluida = true
			main._aplicar_progressao_provas()
			main.atualizar_interface()
		loja.comprar("prova%d" % numero)
		await create_timer(0.5).timeout
		await process_frame
		var prova = main.get_node("Prova%d" % numero)
		var quiz = prova.minigame_instanciado_atual
		verificar(is_instance_valid(quiz), "Quiz %d iniciou" % numero)
		var estoque: int = main.colas
		antes = main.qi
		main.comprar_cola()
		verificar(main.qi == antes and main.colas == estoque, "Não compra durante prova")
		await clicar(quiz.ajuda_cola)
		var eliminadas := 0
		var correta: Button
		var removida: Button
		for b in [quiz.botao1, quiz.botao2, quiz.botao3]:
			if b.disabled:
				eliminadas += 1
				removida = b
			if b.text == quiz.texto_resposta_correta: correta = b
		verificar(eliminadas == 1 and is_instance_valid(correta) and not correta.disabled, "Elimina só uma errada na prova %d" % numero)
		verificar(main.colas == estoque - 1 and prova.vidas == 3 and quiz.perguntas_respondidas_nesta_prova == 0, "Consome sem mudar vidas/acertos")
		quiz.ajuda_cola.usar()
		verificar(main.colas == estoque - 1, "Segundo uso na mesma pergunta bloqueado")
		quiz._on_opcao_escolhida(removida)
		verificar(not quiz.jogo_finalizado and prova.vidas == 3, "Alternativa eliminada não responde")
		await foto("prova%d" % numero)
		quiz.puxar_nova_pergunta()
		verificar(not quiz.ajuda_cola.usada and not quiz.botao1.disabled and not quiz.botao2.disabled and not quiz.botao3.disabled, "Próxima pergunta restaura alternativas")
		quiz.jogo_finalizado = true
		quiz.ajuda_cola.usar()
		verificar(main.colas == estoque - 1, "Bloqueia durante feedback")
		quiz.jogo_finalizado = false
		main.colas = 0
		quiz.ajuda_cola.usar()
		verificar(main.colas == 0 and not quiz.ajuda_cola.usada, "Sem estoque não elimina")
		main.colas = 2
		prova.timer_geral_prova.stop()
		quiz.ajuda_cola.usar()
		verificar(main.colas == 2, "Tempo esgotado não consome")
		prova.fechar_prova()
		await create_timer(1.4).timeout
	print("LOJA E COLAS: %d verificações, %d falhas" % [total, falhas])
	cena.queue_free()
	await process_frame
	quit(1 if falhas else 0)

func clicar(botao: Button) -> void:
	await process_frame
	var posicao: Vector2 = root.get_final_transform() * botao.get_global_rect().get_center()
	for pressionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.position = posicao
		evento.pressed = pressionado
		Input.parse_input_event(evento)
		await process_frame
