extends SceneTree

var falhas := 0
var total := 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(ok: bool, mensagem: String) -> void:
	total += 1
	if not ok:
		falhas += 1
		push_error("FALHOU: " + mensagem)

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/rework_" + nome + ".png")

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
	main.qi = 5000
	main.atualizar_interface()
	main._on_botao_loja_pressed()
	await create_timer(0.5).timeout
	await foto("loja")
	verificar(main.find_child("BotaoEventoEspecial", true, false).custo_upgrade == 400, "Prova 1 custa 400")
	verificar(main.find_child("BotaoEventoEspecial2", true, false).custo_upgrade == 1600, "Prova 2 custa 1600")
	var lapis = main.find_child("BotaoUpgradeClique", true, false)
	lapis.pressed.emit()
	verificar(main.qi == 4980 and lapis.custo_upgrade == 30, "Primeira compra e curva de preço")
	# Save legado com preços antigos: reprecificar sem alterar saldo nem níveis.
	var antigo: Dictionary = main._criar_dados_salvamento()
	antigo.upgrades.clique.custo = 9999
	antigo.upgrades.gerador = {"custo": 9999, "producao": 3}
	antigo.upgrades.multiplicador_clique = {"custo": 9999, "multiplicador": 1.3}
	antigo.upgrades.bonus_passivo = {"custo": 9999, "bonus": 0.20}
	main._aplicar_dados_salvamento(antigo)
	main._aplicar_dados_salvamento(antigo)
	verificar(main.qi == 4980 and main.valor_do_clique_base == 2 and lapis.custo_upgrade == 30, "Migração idempotente preserva saldo e nível")
	verificar(main.find_child("BotaoGeradorQI", true, false).custo_upgrade == 165, "Preço do gerador pelo nível salvo")
	verificar(main.find_child("BotaoMultiplicadorClique", true, false).custo_upgrade == 385, "Preço do multiplicador pelo nível salvo")
	verificar(main.find_child("BotaoMultiplicadorPassivo", true, false).custo_upgrade == 540, "Preço do corretivo pelo nível salvo")
	var col = main.colecao
	col.abrir()
	col._selecionar_aba("Conquistas")
	await foto("conquistas_inicio")
	verificar(col.cartoes_conquistas.size() == 7, "Sete cartões no mural")
	for item in col.CATALOGO:
		col.comprar_item(item.id)
	col.cliques = 73
	main.atualizar_interface()
	await foto("conquistas")
	verificar(col.cartoes_conquistas.cliques.barra.value == 73, "Barra acompanha progresso sem reabrir")
	verificar(col.cartoes_conquistas.primeiro.estado.text == "CONQUISTADA", "Cartão reflete conquista recém-obtida")
	col._filtrar_conquistas("Em progresso")
	verificar(not col.cartoes_conquistas.primeiro.cartao.visible and col.cartoes_conquistas.cliques.cartao.visible, "Filtro em progresso")
	col._filtrar_conquistas("Conquistadas")
	verificar(col.cartoes_conquistas.primeiro.cartao.visible and not col.cartoes_conquistas.cliques.cartao.visible, "Filtro conquistadas")
	col._selecionar_aba("Livros")
	await foto("biblioteca")
	col.fechar()
	main._on_botao_fechar_loja_pressed()
	await create_timer(0.4).timeout
	await foto("mesa")
	print("RESULTADO REWORK: %d verificações, %d falhas" % [total, falhas])
	cena.queue_free()
	await process_frame
	quit(1 if falhas else 0)
