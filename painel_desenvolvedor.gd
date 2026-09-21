extends CanvasLayer

var main: Node
var painel: PanelContainer
var conteudo: VBoxContainer
var titulo: Label
var acesso: HBoxContainer
var indicador: Label
var metricas: Label
var ativar: Button
var adicionar: Button
var sair_debug: Button
var aba := ""

func _ready() -> void:
	layer = 30
	if get_parent().has_method("obter_ganho_clique"):
		main = get_parent()
	acesso = HBoxContainer.new()
	add_child(acesso)
	acesso.position = Vector2(8, 5)
	acesso.add_child(_botao("Novidades", abrir.bind("notas")))
	acesso.add_child(_botao("Desenvolvedor", abrir.bind("dev")))
	indicador = _label("DEBUG • progresso temporário", 12)
	indicador.custom_minimum_size.x = 230
	indicador.add_theme_color_override("font_color", Color("ffdb78"))
	acesso.add_child(indicador)
	painel = PanelContainer.new()
	add_child(painel)
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel.offset_left = 18
	painel.offset_right = -18
	painel.offset_top = 38
	painel.offset_bottom = -14
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("192e2b")
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(14)
	painel.add_theme_stylebox_override("panel", estilo)
	var coluna := VBoxContainer.new()
	painel.add_child(coluna)
	var cabecalho := HBoxContainer.new()
	coluna.add_child(cabecalho)
	titulo = _label("", 20)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(titulo)
	cabecalho.add_child(_botao("Fechar", fechar))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(scroll)
	conteudo = VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 10)
	scroll.add_child(conteudo)
	painel.hide()

func _label(texto: String, tamanho: int = 14) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", Color("f3ecd5"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _botao(texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 13)
	botao.pressed.connect(acao)
	return botao

func abrir(destino: String) -> void:
	if main and (main.modo_prova_ativo or main.colecao.painel.visible):
		return
	if not main and get_parent().trocando_de_cena:
		return
	aba = destino
	for filho in conteudo.get_children():
		conteudo.remove_child(filho)
		filho.queue_free()
	metricas = null
	ativar = null
	adicionar = null
	sair_debug = null
	titulo.text = "NOTAS DE ATUALIZAÇÃO" if aba == "notas" else "DESENVOLVEDOR"
	if aba == "notas":
		for entrada in preload("res://notas_atualizacao.gd").HISTORICO:
			conteudo.add_child(_label(entrada.data + "  |  " + entrada.titulo, 16))
			for mudanca in entrada.mudancas:
				conteudo.add_child(_label("• " + mudanca, 13))
	else:
		conteudo.add_child(_label("Modo debug", 18))
		conteudo.add_child(_label("Teste compras e acompanhe os valores do jogo. Ao encerrar o debug, o progresso anterior é restaurado.", 13))
		if main:
			metricas = _label("")
			conteudo.add_child(metricas)
			var linha := HBoxContainer.new()
			conteudo.add_child(linha)
			ativar = _botao("Ativar debug", iniciar_debug)
			adicionar = _botao("+1.000 QI", adicionar_qi)
			sair_debug = _botao("Encerrar debug", encerrar_debug)
			for botao in [ativar, adicionar, sair_debug]:
				linha.add_child(botao)
		else:
			conteudo.add_child(_label("Entre em JOGAR e abra Desenvolvedor para ativar a sessão debug."))
	painel.show()
	_process(0.0)

func fechar() -> void:
	painel.hide()

func _process(_delta: float) -> void:
	indicador.visible = main != null and main.debug_ativo
	acesso.visible = not main or (not main.modo_prova_ativo and not main.colecao.painel.visible and not main.janela_loja.visible)
	if metricas and painel.visible:
		metricas.text = "FPS: %d  |  QI: %d  |  QI/clique: %d  |  QI/s: %d\nSave: %s" % [Engine.get_frames_per_second(), main.qi, main.obter_ganho_clique(), main.obter_producao_passiva(), "desativado nesta sessão debug" if main.debug_ativo else ("bloqueado: arquivo inválido" if main.salvamento_bloqueado else "normal")]
		ativar.disabled = main.debug_ativo or main.salvamento_bloqueado
		adicionar.disabled = not main.debug_ativo
		sair_debug.disabled = not main.debug_ativo

func iniciar_debug() -> void:
	if not main or main.debug_ativo or main.modo_prova_ativo or main.salvamento_bloqueado:
		return
	# Snapshot em memória: sair do debug restaura também progresso ainda não salvo.
	main.estado_antes_debug = main._criar_dados_salvamento().duplicate(true)
	main.debug_ativo = true
	main.timer_salvamento.stop()

func adicionar_qi() -> void:
	if main and main.debug_ativo and not main.modo_prova_ativo:
		main.qi += 1000
		main.atualizar_interface()

func encerrar_debug() -> void:
	if not main or not main.debug_ativo or main.modo_prova_ativo:
		return
	# Recriar a cena restaura inclusive botões de provas removidos durante testes.
	var estado: Dictionary = main.estado_antes_debug.duplicate(true)
	var cena: Node = load("res://principalgame.tscn").instantiate()
	var novo_main = cena.get_node("Main")
	novo_main.estado_restaurar_debug = estado
	var anterior := get_tree().current_scene
	get_tree().root.add_child(cena)
	get_tree().current_scene = cena
	anterior.queue_free()

func _input(event: InputEvent) -> void:
	if painel.visible:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			fechar()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and not painel.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()