extends Control

# Fachada da loja: reutiliza as compras existentes, sem duplicar a economia.
var main: Node
var aba := "Melhorias"
var abas: Dictionary = {}
var cartoes: Array[Dictionary] = []
var lista: VBoxContainer
var rolagem: ScrollContainer
var saldo: Label
var legado: Control
const MELHORIAS := [
	["BotaoUpgradeClique", "Lápis melhor", "lapis"],
	["BotaoGeradorQI", "Apontador", "apontador"],
	["BotaoMultiplicadorClique", "Marca-texto", "marca_texto"],
	["BotaoMultiplicadorPassivo", "Corretivo", "corretivo"]
]

func _ready() -> void:
	name = "CatalogoLoja"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	legado = Control.new()
	legado.name = "LogicaCompras"
	get_parent().add_child(legado)
	# Conserva sinais, scripts e nomes procurados por Main e pelos saves.
	for filho in get_parent().get_children():
		if filho != self and filho != legado and filho.name != "BotaoFecharLoja" and filho.name != "MensagemLoja":
			filho.reparent(legado)
	legado.hide()
	var titulo := texto("LOJA DE ESTUDOS", 20)
	titulo.position = Vector2(16, 8)
	add_child(titulo)
	var conquistas := botao("Conquistas", abrir_diario.bind("Conquistas"))
	conquistas.position = Vector2(292, 10)
	conquistas.size = Vector2(104, 30)
	add_child(conquistas)
	var revisao := botao("Revisão", abrir_diario.bind("Revisão"))
	revisao.position = Vector2(400, 10)
	revisao.size = Vector2(84, 30)
	add_child(revisao)
	saldo = texto("", 12)
	saldo.position = Vector2(16, 38)
	add_child(saldo)
	var navegacao := HBoxContainer.new()
	navegacao.position = Vector2(16, 62)
	navegacao.size = Vector2(508, 30)
	navegacao.add_theme_constant_override("separation", 5)
	add_child(navegacao)
	for nome in ["Melhorias", "Livros", "Materiais", "Colas", "Provas"]:
		var item := botao(nome, selecionar.bind(nome))
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navegacao.add_child(item)
		abas[nome] = item
	rolagem = ScrollContainer.new()
	rolagem.position = Vector2(16, 100)
	rolagem.size = Vector2(508, 186)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(rolagem)
	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 7)
	rolagem.add_child(lista)
	main.mensagem_loja.position = Vector2(16, 292)
	main.mensagem_loja.size = Vector2(508, 32)
	main.mensagem_loja.add_theme_font_size_override("font_size", 11)
	selecionar(aba)

func texto(valor: String, tamanho: int = 12) -> Label:
	var label := Label.new()
	label.text = valor
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", Color("243e34"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func botao(valor: String, acao: Callable) -> Button:
	var b: Button = main.colecao._botao(valor, acao)
	b.add_theme_font_size_override("font_size", 11)
	return b

func abrir_diario(destino: String) -> void:
	main.colecao.abrir()
	main.colecao._selecionar_aba(destino)

func selecionar(destino: String) -> void:
	aba = destino
	cartoes.clear()
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.queue_free()
	rolagem.scroll_vertical = 0
	main.mensagem_loja.text = "Compras diretas nesta janela · Role para ver todos os itens · Esc: fechar."
	for nome in abas:
		abas[nome].add_theme_stylebox_override("normal", main.colecao._estilo("a77a2c" if nome == aba else "365b50"))
	if aba == "Melhorias":
		for item in MELHORIAS:
			var textura = load("res://assets/itens/" + item[2] + ".png")
			criar_cartao(item[0], item[1], "MELHORIA REPETÍVEL", textura)
	elif aba == "Livros" or aba == "Materiais":
		for item in main.colecao.CATALOGO:
			if item.tipo == aba:
				criar_cartao(item.id, item.nome, "COMPRA ÚNICA", main.colecao.ARTE_ITENS.SPRITES[item.id])
	elif aba == "Colas":
		criar_cartao("cola", "Cola de eliminação", "CONSUMÍVEL • 1 USO", null)
		var dica := texto("Cada uso elimina uma alternativa errada nas provas.\nNão responde por você nem devolve vidas. Uma por pergunta.", 12)
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(dica)
	else:
		criar_cartao("prova1", "Seminário 1 · Matemática", "5 ACERTOS • 3 VIDAS • 35 SEGUNDOS", null)
		criar_cartao("prova2", "Seminário 2 · Português", "5 ACERTOS • 3 VIDAS • 80 SEGUNDOS", null)
	atualizar()

func criar_cartao(id: String, titulo: String, categoria: String, textura: Texture2D) -> void:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", main.colecao._estilo("fffaf0"))
	lista.add_child(painel)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	painel.add_child(linha)
	if textura:
		var icone := TextureRect.new()
		icone.custom_minimum_size = Vector2(42, 55)
		icone.texture = textura
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(icone)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	linha.add_child(info)
	info.add_child(texto(categoria, 9))
	info.add_child(texto(titulo, 14))
	var beneficio := texto("")
	beneficio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(beneficio)
	var estado := texto("", 10)
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	estado.add_theme_color_override("font_color", Color("78601e"))
	info.add_child(estado)
	var comprar := botao("", comprar.bind(id))
	comprar.custom_minimum_size.x = 102
	comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(comprar)
	cartoes.append({"id": id, "beneficio": beneficio, "estado": estado, "botao": comprar})

func comprar(id: String) -> void:
	if main.modo_prova_ativo:
		return
	if id == "cola":
		main.comprar_cola()
	elif id.begins_with("Botao"):
		var origem = main.find_child(id, true, false)
		if is_instance_valid(origem) and not origem.disabled:
			origem.pressed.emit()
	elif id == "prova1" or id == "prova2":
		var segunda := id == "prova2"
		if (main.prova2_concluida if segunda else main.prova1_concluida) or (segunda and not main.prova1_concluida):
			return
		var origem = main.find_child("BotaoEventoEspecial2" if segunda else "BotaoEventoEspecial", true, false)
		if is_instance_valid(origem) and not origem.is_queued_for_deletion() and main.qi >= origem.custo_upgrade:
			origem.pressed.emit()
	else:
		var antes: bool = main.colecao.adquiridos.has(id)
		main.colecao.comprar_item(id)
		if not antes and main.colecao.adquiridos.has(id):
			main.mostrar_mensagem_loja("Item adquirido! Seu bônus e sua mesa foram atualizados.")
	atualizar()

func atualizar() -> void:
	if not saldo:
		return
	saldo.text = "%s QI  ·  +%s/clique  ·  +%s/s  ·  Colas: %d/%d" % [preload("res://apresentacao.gd").numero(main.qi), main.obter_ganho_clique(), main.obter_producao_passiva(), main.colas, main.LIMITE_COLAS]
	for cartao in cartoes:
		var id: String = cartao.id
		var custo := 0
		var bloqueado := false
		var estado := ""
		var beneficio := ""
		var acao := "Comprar"
		if id.begins_with("Botao"):
			var origem = main.find_child(id, true, false)
			custo = origem.custo_upgrade
			beneficio = main._descricao_melhoria(id)
		elif id == "cola":
			custo = main.CUSTO_COLA
			beneficio = "Elimina 1 alternativa errada.\nEstoque: %d de %d colas." % [main.colas, main.LIMITE_COLAS]
			bloqueado = main.colas >= main.LIMITE_COLAS
			estado = "Estoque cheio" if bloqueado else "Consumida ao usar; estoque salvo automaticamente."
		elif id == "prova1" or id == "prova2":
			var segunda := id == "prova2"
			custo = preload("res://economia.gd").PROVA_2 if segunda else preload("res://economia.gd").PROVA_1
			var concluida: bool = main.prova2_concluida if segunda else main.prova1_concluida
			bloqueado = concluida or (segunda and not main.prova1_concluida)
			estado = "Concluída ✓" if concluida else ("Passe no Seminário 1 para desbloquear." if bloqueado else "Custo por tentativa; produção pausa durante a prova.")
			beneficio = "Movimentos literários. Revise antes de começar." if segunda else "Operações matemáticas. Libera o Seminário 2."
			acao = "Iniciar"
		else:
			for item in main.colecao.CATALOGO:
				if item.id == id:
					custo = item.custo
					var ganhos: Array[String] = []
					if item.clique: ganhos.append("+%d QI/clique" % item.clique)
					if item.passivo: ganhos.append("+%d QI/s" % item.passivo)
					beneficio = " · ".join(ganhos) + "\n" + item.nota
					bloqueado = main.colecao.adquiridos.has(id)
					estado = "Adquirido ✓" if bloqueado else "Bônus permanente, somado após multiplicadores."
		cartao.beneficio.text = beneficio
		cartao.estado.text = estado if bloqueado or main.qi >= custo else "Faltam %d QI" % (custo - main.qi)
		cartao.botao.text = ("Concluído" if id.begins_with("prova") else "Adquirido") if bloqueado else "%s\n%d QI" % [acao, custo]
		if id == "cola" and bloqueado: cartao.botao.text = "Estoque cheio"
		if id == "prova2" and not main.prova1_concluida: cartao.botao.text = "Bloqueado"
		cartao.botao.disabled = bloqueado or main.qi < custo or main.modo_prova_ativo
