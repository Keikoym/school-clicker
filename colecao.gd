extends CanvasLayer

const ARTE_ITENS = preload("res://itens_mesa.gd")

const CATALOGO := [
	{"id": "casmurro", "nome": "Dom Casmurro", "tipo": "Livros", "custo": 140, "clique": 1, "passivo": 0, "nota": "Machado de Assis • Realismo\nInvestiga ciúme, memória e relações sociais."},
	{"id": "macunaima", "nome": "Macunaíma", "tipo": "Livros", "custo": 320, "clique": 2, "passivo": 0, "nota": "Mário de Andrade • Modernismo\nMistura lendas, fala popular e cultura brasileira."},
	{"id": "cortico", "nome": "O Cortiço", "tipo": "Livros", "custo": 550, "clique": 0, "passivo": 4, "nota": "Aluísio Azevedo • Naturalismo\nExplora a influência do meio sobre as pessoas."},
	{"id": "caderno", "nome": "Caderno de resumos", "tipo": "Materiais", "custo": 80, "clique": 1, "passivo": 0, "nota": "Organize as ideias e fortaleça seus cliques."},
	{"id": "estojo", "nome": "Estojo completo", "tipo": "Materiais", "custo": 200, "clique": 0, "passivo": 2, "nota": "Tudo à mão para estudar: produção automática."},
	{"id": "luminaria", "nome": "Luminária de estudo", "tipo": "Materiais", "custo": 950, "clique": 3, "passivo": 3, "nota": "Uma mesa preparada para longas leituras."}
]
const MEDALHAS := [
	["cliques", "Pegando o ritmo", "Dê 100 cliques.", 100],
	["primeiro", "Primeira leitura", "Adquira um livro.", 1],
	["biblioteca", "Pequena biblioteca", "Colecione os três livros.", 3],
	["materiais", "Mesa preparada", "Colecione os três materiais.", 3],
	["colecionador", "Mochila completa", "Adquira os seis colecionáveis.", 6],
	["prova1", "Primeira aprovação", "Vença o Seminário 1.", 1],
	["prova2", "Leitor aprovado", "Vença o Seminário de Português.", 1]
]

var main: Node
var adquiridos: Dictionary = {}
var conquistas: Dictionary = {}
var cliques: int = 0
var bonus_clique: int = 0
var bonus_passivo: int = 0
var painel: Control
var lista: VBoxContainer
var saldo: Label
var aviso: Label
var aba: String = "Livros"
var botoes: Dictionary = {}
var abas_botoes: Dictionary = {}
var cartoes_conquistas: Dictionary = {}
var resumo_conquistas: Label
var barra_conquistas: ProgressBar
var filtro_conquistas: String = "Todas"
var filtros: Dictionary = {}
var mensagens: Array[String] = []
var exibindo_aviso: bool = false
var tempo_aviso: float = 0.0

func _ready() -> void:
	main = get_parent()
	layer = 10
	_montar_interface()
	var acesso = main.find_child("BotaoUpgrade3", true, false)
	acesso.disabled = false
	acesso.text = "BIBLIOTECA E MATERIAIS\nLivros • Itens • Conquistas"
	acesso.tooltip_text = "Colecione melhorias permanentes e acompanhe suas conquistas."
	var modelo = main.find_child("BotaoUpgradeClique", true, false)
	for estado in ["normal", "hover", "pressed"]:
		acesso.add_theme_stylebox_override(estado, modelo.get_theme_stylebox(estado))
	for estado in ["font_color", "font_hover_color", "font_pressed_color"]:
		acesso.add_theme_color_override(estado, modelo.get_theme_color(estado))
	acesso.pressed.connect(abrir)

func _estilo(cor: String) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(cor)
	estilo.set_corner_radius_all(10)
	estilo.border_color = Color("d5c9ac")
	estilo.set_border_width_all(1)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	return estilo

func _texto(texto: String, tamanho: int = 13) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", Color("302c26"))
	return label

func _botao(texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 13)
	botao.add_theme_stylebox_override("normal", _estilo("365b50"))
	botao.add_theme_stylebox_override("hover", _estilo("487a69"))
	botao.add_theme_stylebox_override("pressed", _estilo("244438"))
	botao.add_theme_stylebox_override("disabled", _estilo("797d70"))
	botao.add_theme_color_override("font_color", Color("fff6dc"))
	botao.add_theme_color_override("font_hover_color", Color.WHITE)
	botao.add_theme_color_override("font_pressed_color", Color("fff6dc"))
	botao.add_theme_color_override("font_disabled_color", Color("f1ead9"))
	var foco := _estilo("365b50")
	foco.bg_color.a = 0.0
	foco.border_color = Color("d7a841")
	foco.set_border_width_all(2)
	botao.add_theme_stylebox_override("focus", foco)
	botao.custom_minimum_size.y = 30
	botao.pressed.connect(acao)
	return botao

func _montar_interface() -> void:
	painel = Control.new()
	add_child(painel)
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color(0.08, 0.12, 0.10, 0.8)
	painel.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var papel := PanelContainer.new()
	painel.add_child(papel)
	papel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	papel.offset_left = 22
	papel.offset_right = -22
	papel.offset_top = 16
	papel.offset_bottom = -16
	papel.add_theme_stylebox_override("panel", _estilo("f3ecd5"))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	papel.add_child(coluna)
	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var titulo := _texto("MINHA MOCHILA", 21)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(_botao("Voltar ×", fechar))
	saldo = _texto("")
	coluna.add_child(saldo)
	var abas := HBoxContainer.new()
	coluna.add_child(abas)
	for nome in ["Livros", "Materiais", "Conquistas", "Revisão"]:
		var botao := _botao(nome, _selecionar_aba.bind(nome))
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		abas.add_child(botao)
		abas_botoes[nome] = botao
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	rolagem.add_child(lista)
	coluna.add_child(_texto("Melhorias permanentes  ·  Revisão gratuita  ·  Esc para voltar", 11))
	painel.hide()
	aviso = _texto("", 14)
	aviso.add_theme_stylebox_override("normal", _estilo("f5d781"))
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	aviso.offset_top = 64
	aviso.offset_bottom = 92
	aviso.hide()

func _process(delta: float) -> void:
	# Durante provas, preserve a leitura de vidas, respostas e cronômetro.
	aviso.visible = exibindo_aviso and not main.modo_prova_ativo and not painel.visible and not main.camada_loja.visible
	if aviso.visible:
		tempo_aviso -= delta
		if tempo_aviso <= 0.0:
			exibindo_aviso = false
			aviso.hide()
	if not exibindo_aviso and not mensagens.is_empty() and not main.modo_prova_ativo and not painel.visible and not main.camada_loja.visible:
		_mostrar_aviso()

func abrir() -> void:
	if main.modo_prova_ativo:
		return
	aviso.hide()
	painel.show()
	_selecionar_aba(aba)

func fechar() -> void:
	painel.hide()

func _input(event: InputEvent) -> void:
	if painel.visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		fechar()
		get_viewport().set_input_as_handled()

func _selecionar_aba(nome: String) -> void:
	aba = nome
	botoes.clear()
	cartoes_conquistas.clear()
	filtros.clear()
	resumo_conquistas = null
	barra_conquistas = null
	for chave in abas_botoes:
		abas_botoes[chave].add_theme_stylebox_override("normal", _estilo("a77a2c" if chave == aba else "365b50"))
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.queue_free()
	if aba == "Conquistas":
		_montar_conquistas()
	elif aba == "Revisão":
		var resumo := _texto("PORTUGUÊS • GUIA RÁPIDO\n\nModernismo: liberdade artística, versos livres e fala cotidiana.\nSemana de Arte Moderna: São Paulo, 1922.\nMacunaíma: Mário de Andrade. Manifesto Antropófago: Oswald.\n\nRealismo: crítica social e análise psicológica, sem idealização.\nDom Casmurro e Memórias Póstumas: Machado de Assis.\n\nRomantismo: emoção e idealização do amor e dos heróis.\nNaturalismo: influência do meio e da hereditariedade.\nO Cortiço: Aluísio Azevedo.\nParnasianismo: cuidado com a forma e a métrica dos versos.", 13)
		resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(resumo)
	else:
		for item in CATALOGO:
			if item.tipo != aba:
				continue
			var cartao := PanelContainer.new()
			cartao.add_theme_stylebox_override("panel", _estilo("e4dcc4"))
			lista.add_child(cartao)
			var linha := HBoxContainer.new()
			cartao.add_child(linha)
			var icone := TextureRect.new()
			icone.custom_minimum_size = Vector2(64, 64)
			icone.texture = ARTE_ITENS.SPRITES[item.id]
			icone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			linha.add_child(icone)
			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			linha.add_child(info)
			info.add_child(_texto(item.nome, 15))
			var nota := _texto(item.nota, 11)
			nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(nota)
			var beneficios: Array[String] = []
			if item.clique > 0: beneficios.append("+%d QI/clique" % item.clique)
			if item.passivo > 0: beneficios.append("+%d QI/s" % item.passivo)
			info.add_child(_texto("  ·  ".join(beneficios), 12))
			var comprar := _botao("", comprar_item.bind(item.id))
			comprar.custom_minimum_size.x = 112
			linha.add_child(comprar)
			botoes[item.id] = comprar
	atualizar()

func comprar_item(id: String) -> void:
	if main.modo_prova_ativo or adquiridos.has(id):
		return
	for item in CATALOGO:
		if item.id == id and main.qi >= int(item.custo):
			main.qi -= int(item.custo)
			adquiridos[id] = true
			_recalcular_bonus()
			main.atualizar_interface()
			main.solicitar_salvamento()
			return

func _recalcular_bonus() -> void:
	bonus_clique = 0
	bonus_passivo = 0
	for item in CATALOGO:
		if adquiridos.has(item.id):
			bonus_clique += int(item.clique)
			bonus_passivo += int(item.passivo)

func registrar_clique() -> void:
	cliques += 1

func _progresso(id: String) -> int:
	match id:
		"cliques": return cliques
		"primeiro", "biblioteca":
			return int(adquiridos.has("casmurro")) + int(adquiridos.has("macunaima")) + int(adquiridos.has("cortico"))
		"materiais": return int(adquiridos.has("caderno")) + int(adquiridos.has("estojo")) + int(adquiridos.has("luminaria"))
		"colecionador": return adquiridos.size()
		"prova1": return int(main.prova1_concluida)
		"prova2": return int(main.prova2_concluida)
	return 0

func atualizar() -> void:
	for medalha in MEDALHAS:
		if not conquistas.has(medalha[0]) and _progresso(medalha[0]) >= int(medalha[3]):
			conquistas[medalha[0]] = true
			if not main.carregando_salvamento:
				mensagens.append("Conquista desbloqueada: " + medalha[1])
				main.solicitar_salvamento()
	if not exibindo_aviso and not mensagens.is_empty() and not main.modo_prova_ativo and not painel.visible and not main.camada_loja.visible:
		_mostrar_aviso()
	if not painel.visible:
		return
	_atualizar_conquistas()
	saldo.text = "%d QI   •   Coleção: %d/6   •   Conquistas: %d/7" % [main.qi, adquiridos.size(), conquistas.size()]
	for item in CATALOGO:
		if botoes.has(item.id):
			var botao: Button = botoes[item.id]
			var comprado := adquiridos.has(item.id)
			botao.text = "Adquirido ✓" if comprado else "Comprar\n%d QI" % item.custo
			botao.disabled = comprado or main.qi < int(item.custo)
			botao.tooltip_text = "Já está na sua coleção" if comprado else ("Comprar melhoria permanente" if main.qi >= int(item.custo) else "Faltam %d QI" % (int(item.custo) - main.qi))

func _mostrar_aviso() -> void:
	exibindo_aviso = true
	aviso.text = mensagens.pop_front()
	aviso.show()
	tempo_aviso = 2.5

func salvar() -> Dictionary:
	return {"adquiridos": adquiridos.duplicate(), "conquistas": conquistas.duplicate(), "cliques": cliques}

func carregar(dados: Dictionary) -> void:
	adquiridos.clear()
	conquistas.clear()
	var itens: Dictionary = main._obter_dicionario(dados, "adquiridos")
	var medalhas: Dictionary = main._obter_dicionario(dados, "conquistas")
	for item in CATALOGO:
		if itens.get(item.id, false) == true:
			adquiridos[item.id] = true
	for medalha in MEDALHAS:
		if medalhas.get(medalha[0], false) == true:
			conquistas[medalha[0]] = true
	cliques = maxi(0, int(dados.get("cliques", 0)))
	_recalcular_bonus()

# As referências permitem atualizar as barras sem reconstruir a lista a cada clique.
func _montar_conquistas() -> void:
	var resumo := PanelContainer.new()
	resumo.add_theme_stylebox_override("panel", _estilo("e7d6a8"))
	lista.add_child(resumo)
	var conteudo := VBoxContainer.new()
	resumo.add_child(conteudo)
	resumo_conquistas = _texto("", 17)
	conteudo.add_child(resumo_conquistas)
	conteudo.add_child(_texto("Cada conquista registra uma etapa da sua jornada.", 11))
	barra_conquistas = _barra()
	barra_conquistas.max_value = MEDALHAS.size()
	conteudo.add_child(barra_conquistas)
	var linha := HBoxContainer.new()
	lista.add_child(linha)
	for nome in ["Todas", "Em progresso", "Conquistadas"]:
		var botao := _botao(nome, _filtrar_conquistas.bind(nome))
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(botao)
		filtros[nome] = botao
	for medalha in MEDALHAS:
		var cartao := PanelContainer.new()
		cartao.name = "Conquista_" + medalha[0]
		lista.add_child(cartao)
		var interior := HBoxContainer.new()
		interior.add_theme_constant_override("separation", 12)
		cartao.add_child(interior)
		var selo := preload("res://selo_conquista.gd").new()
		selo.custom_minimum_size = Vector2(48, 64)
		interior.add_child(selo)
		var coluna := VBoxContainer.new()
		coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		interior.add_child(coluna)
		var topo := HBoxContainer.new()
		coluna.add_child(topo)
		var titulo := _texto(medalha[1], 14)
		titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		topo.add_child(titulo)
		var estado := _texto("", 11)
		topo.add_child(estado)
		coluna.add_child(_texto(medalha[2], 12))
		var barra := _barra()
		barra.max_value = int(medalha[3])
		coluna.add_child(barra)
		cartoes_conquistas[medalha[0]] = {"cartao": cartao, "selo": selo, "estado": estado, "barra": barra}
	_atualizar_conquistas()

func _barra() -> ProgressBar:
	var barra := ProgressBar.new()
	barra.custom_minimum_size.y = 8
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("ddd4bc")
	fundo.set_corner_radius_all(4)
	var preenchimento := fundo.duplicate()
	preenchimento.bg_color = Color("3c8066")
	barra.add_theme_stylebox_override("background", fundo)
	barra.add_theme_stylebox_override("fill", preenchimento)
	return barra

func _filtrar_conquistas(nome: String) -> void:
	filtro_conquistas = nome
	_atualizar_conquistas()

func _atualizar_conquistas() -> void:
	if not is_instance_valid(resumo_conquistas):
		return
	resumo_conquistas.text = "SEU MURAL  ·  %d de %d conquistas" % [conquistas.size(), MEDALHAS.size()]
	barra_conquistas.value = conquistas.size()
	for nome in filtros:
		filtros[nome].add_theme_stylebox_override("normal", _estilo("a77a2c" if nome == filtro_conquistas else "365b50"))
	for medalha in MEDALHAS:
		var id: String = medalha[0]
		var dados: Dictionary = cartoes_conquistas[id]
		var completa := conquistas.has(id)
		var atual := mini(_progresso(id), int(medalha[3]))
		dados.cartao.visible = filtro_conquistas == "Todas" or (filtro_conquistas == "Conquistadas" and completa) or (filtro_conquistas == "Em progresso" and not completa)
		dados.cartao.add_theme_stylebox_override("panel", _estilo("fff2ce" if completa else "ebe6d7"))
		dados.selo.definir(completa)
		dados.estado.text = "CONQUISTADA" if completa else "%d / %d" % [atual, medalha[3]]
		dados.estado.add_theme_color_override("font_color", Color("78601e") if completa else Color("5a635c"))
		dados.barra.value = int(medalha[3]) if completa else atual
