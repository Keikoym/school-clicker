extends Control

const CAMINHO_SAVE: String = "user://school_clicker_save.json"
const VERSAO_SAVE: int = 1
const INTERVALO_AUTOSAVE: float = 2.0

# --- SISTEMA DE MUDANCA DE APARENCIA ---
@export var texturas_botao_clique: Array[Texture2D] = []
var cliques_acumulados: int = 0
var indice_aparencia_atual: int = 0
var total_cliques_geral: int = 0
var mudancas_rapidas_restantes: int = 0

# --- CONTROLE DO MODO PROVA ---
var modo_prova_ativo: bool = false

# Variaveis principais de pontos
var debug_ativo: bool = false
var estado_antes_debug: Dictionary = {}
var estado_restaurar_debug: Dictionary = {}
var ferramentas: CanvasLayer

var qi: int = 0
var valor_do_clique_base: int = 1

# Variaveis: Controle do Multiplicador
var multiplicador_clique: float = 1.0

# Guarda quanto QI o jogador ganha sozinho por segundo
var qi_por_segundo_base: int = 0
var multiplicador_passivo_bonus: float = 0.0

# Progresso permanente das provas
var prova1_concluida: bool = false
var prova2_concluida: bool = false

# Referencias para os nos da cena
@onready var contador_label: Label = $Label
@onready var botao_clique: TextureButton = $BotaoClique
@onready var janela_loja: Panel = find_child("JanelaLoja", true, false)
@onready var botao_loja: TextureButton = $BotaoLoja
@onready var mensagem_loja: Label = find_child("MensagemLoja", true, false)

# AUDIO CONTROLS
@onready var musica_principal: AudioStreamPlayer2D = get_parent().get_node_or_null("AudioStreamPlayerPrincipal")
@onready var musica_prova: AudioStreamPlayer2D = get_parent().get_node_or_null("AudioStreamPlayerProva")

var posicao_centro_loja: Vector2
var timer_autoclick: Timer
var timer_salvamento: Timer
var carregando_salvamento: bool = false
var salvamento_bloqueado: bool = false
var tween_botao_clique: Tween
var tween_hover_clique: Tween
var tween_hover_loja: Tween
var tween_loja: Tween
var tween_mensagem_loja: Tween
var colecao: CanvasLayer
var camada_loja: CanvasLayer
var itens_mesa: Control

func _ready() -> void:
	_configurar_loja_modal()
	preload("res://apresentacao.gd").configurar(self)
	if janela_loja:
		posicao_centro_loja = janela_loja.position
		janela_loja.visible = false
		
	timer_autoclick = Timer.new()
	timer_autoclick.wait_time = 1.0
	timer_autoclick.autostart = true
	timer_autoclick.timeout.connect(_on_timer_timeout)
	add_child(timer_autoclick)

	timer_salvamento = Timer.new()
	timer_salvamento.one_shot = true
	timer_salvamento.wait_time = INTERVALO_AUTOSAVE
	timer_salvamento.timeout.connect(salvar_progresso)
	add_child(timer_salvamento)
	
	if texturas_botao_clique.size() > 0 and botao_clique:
		botao_clique.texture_normal = texturas_botao_clique[0]
		botao_clique.pivot_offset = botao_clique.size / 2
		botao_clique.mouse_entered.connect(_on_botao_clique_mouse_entered)
		botao_clique.mouse_exited.connect(_on_botao_clique_mouse_exited)

	if botao_loja:
		botao_loja.pivot_offset = botao_loja.size / 2
		botao_loja.mouse_entered.connect(_on_botao_loja_mouse_entered)
		botao_loja.mouse_exited.connect(_on_botao_loja_mouse_exited)
		
	# CONEXÃO PROVA 1
	var no_prova1 = find_child("Prova1", true, false)
	if no_prova1:
		no_prova1.visible = false
		if no_prova1.has_signal("prova_finalizada"):
			if not no_prova1.prova_finalizada.is_connected(finalizar_modo_prova):
				no_prova1.prova_finalizada.connect(finalizar_modo_prova)
			
	# CONEXÃO PROVA 2
	var no_prova2 = find_child("Prova2", true, false)
	if no_prova2:
		no_prova2.visible = false
		if no_prova2.has_signal("prova_finalizada"):
			if not no_prova2.prova_finalizada.is_connected(finalizar_modo_prova):
				no_prova2.prova_finalizada.connect(finalizar_modo_prova)
			
	if musica_prova:
		musica_prova.process_mode = Node.PROCESS_MODE_ALWAYS
		
	if musica_principal and not musica_principal.playing:
		musica_principal.play()
		
	itens_mesa = preload("res://itens_mesa.gd").new()
	itens_mesa.name = "ItensMesa"
	add_child(itens_mesa)
	move_child(itens_mesa, botao_clique.get_index())
	colecao = preload("res://colecao.gd").new()
	add_child(colecao)
	if estado_restaurar_debug.is_empty():
		carregar_progresso()
	else:
		carregando_salvamento = true
		_aplicar_dados_salvamento(estado_restaurar_debug)
		carregando_salvamento = false
		estado_restaurar_debug.clear()
	atualizar_interface()
	ferramentas = preload("res://painel_desenvolvedor.gd").new()
	add_child(ferramentas)

func _configurar_loja_modal() -> void:
	camada_loja = CanvasLayer.new()
	camada_loja.name = "CamadaLoja"
	camada_loja.layer = 5
	add_child(camada_loja)
	var bloqueio := ColorRect.new()
	bloqueio.name = "BloqueioLoja"
	bloqueio.color = Color(0.08, 0.12, 0.10, 0.55)
	bloqueio.mouse_filter = Control.MOUSE_FILTER_STOP
	camada_loja.add_child(bloqueio)
	bloqueio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	janela_loja.reparent(camada_loja)
	janela_loja.position = Vector2(50, 15)
	janela_loja.mouse_filter = Control.MOUSE_FILTER_STOP
	camada_loja.hide()

func _on_timer_timeout() -> void:
	if obter_producao_passiva() > 0 and not modo_prova_ativo:
		var producao_final = obter_producao_passiva()
		qi += producao_final
		atualizar_interface()
		solicitar_salvamento()
		
		var posicao_do_texto = Vector2(320, 100) 
		var no_apontador = find_child("Apontador", true, false)
		if no_apontador and no_apontador.visible:
			posicao_do_texto = no_apontador.position + Vector2(20, -30)
		
		criar_texto_flutuante(posicao_do_texto, "+" + str(producao_final))

func atualizar_interface() -> void:
	if contador_label:
		if obter_producao_passiva() > 0:
			var exibicao_final_passivo = obter_producao_passiva()
			contador_label.text = "QI: " + str(qi) + " (+" + str(exibicao_final_passivo) + "/s)"
		else:
			contador_label.text = "QI: " + str(qi)
	_aplicar_visibilidade_objetos()
	_atualizar_disponibilidade_loja()
	preload("res://apresentacao.gd").atualizar(self)
	if colecao:
		colecao.atualizar()
		if itens_mesa:
			itens_mesa.atualizar(colecao.adquiridos)

func obter_ganho_clique() -> int:
	return int(round(valor_do_clique_base * multiplicador_clique)) + (int(colecao.bonus_clique) if colecao else 0)

func obter_producao_passiva() -> int:
	return int(round(qi_por_segundo_base + qi_por_segundo_base * multiplicador_passivo_bonus)) + (int(colecao.bonus_passivo) if colecao else 0)

# --- SISTEMA DO MODO PROVA ---

func iniciar_modo_prova() -> void:
	if modo_prova_ativo or prova1_concluida:
		return
	camada_loja.hide()
	if colecao:
		colecao.fechar()
	if tween_loja and tween_loja.is_valid():
		tween_loja.kill()
	modo_prova_ativo = true
	solicitar_salvamento()
	print("🚨 MODO PROVA 1 ATIVADO NO MAIN!")
	
	if musica_principal:
		musica_principal.stop()
	if musica_prova:
		musica_prova.play()
	
	if janela_loja:
		janela_loja.position.x = 700
		janela_loja.visible = false
	
	var no_prova1 = find_child("Prova1", true, false)
	
	if no_prova1 and no_prova1.has_method("iniciar_animacao_subida"):
		no_prova1.iniciar_animacao_subida()
	else:
		print("❌ ERRO NO MAIN: Não encontrou o nó Prova1 ou a função 'iniciar_animacao_subida' sumiu dele!")

# --- NOVA FUNÇÃO: ABRE A PROVA 2 PELO BOTÃO DO SEMINÁRIO 2 ---
func iniciar_modo_prova2() -> void:
	if modo_prova_ativo or not prova1_concluida or prova2_concluida:
		return
	camada_loja.hide()
	if colecao:
		colecao.fechar()
	if tween_loja and tween_loja.is_valid():
		tween_loja.kill()
	modo_prova_ativo = true
	solicitar_salvamento()
	print("🚨 MODO PROVA 2 ATIVADO NO MAIN!")
	
	if musica_principal:
		musica_principal.stop()
	if musica_prova:
		musica_prova.play()
	
	# Fecha a loja para focar na prova
	if janela_loja:
		janela_loja.position.x = 700
		janela_loja.visible = false
	
	var no_prova2 = find_child("Prova2", true, false)
	
	if no_prova2 and no_prova2.has_method("iniciar_animacao_subida"):
		no_prova2.iniciar_animacao_subida()
	else:
		print("❌ ERRO NO MAIN: Não encontrou o nó Prova2 ou a função 'iniciar_animacao_subida' sumiu dele!")

func finalizar_modo_prova() -> void:
	modo_prova_ativo = false
	print("🏆 MODO PROVA FINALIZADO NO MAIN!")

	var no_prova1 = find_child("Prova1", true, false)
	var no_prova2 = find_child("Prova2", true, false)
	if no_prova1 and no_prova1.ganhou_maratona:
		prova1_concluida = true
	if no_prova2 and no_prova2.ganhou_maratona:
		prova2_concluida = true

	_aplicar_progressao_provas()
	
	if musica_prova:
		musica_prova.stop()
	if musica_principal:
		musica_principal.play()
		
	atualizar_interface()
	solicitar_salvamento()

# --- UPGRADES ---

func _on_bonus_passivo_atualizado(novo_bonus: float) -> void:
	multiplicador_passivo_bonus = novo_bonus
	atualizar_interface()
	solicitar_salvamento()

func _on_multiplicador_melhorado(novo_multiplicador: float) -> void:
	multiplicador_clique = novo_multiplicador
	atualizar_interface()
	solicitar_salvamento()

func _on_gerador_comprado(nova_producao: int) -> void:
	qi_por_segundo_base = nova_producao
	atualizar_interface()
	solicitar_salvamento()

func _on_clique_melhorado(novo_valor: int) -> void:
	valor_do_clique_base = novo_valor
	atualizar_interface()
	solicitar_salvamento()

# --- CLIQUE PRINCIPAL ---

func _on_botao_clique_pressed() -> void:
	if modo_prova_ativo:
		return
		
	var ganho_final = obter_ganho_clique()
	qi += ganho_final
	if colecao:
		colecao.registrar_clique()
	atualizar_interface()
	solicitar_salvamento()
	efeito_pulinho_botao()
	
	if texturas_botao_clique.size() > 1:
		cliques_acumulados += 1
		total_cliques_geral += 1
		
		if total_cliques_geral >= 200:
			total_cliques_geral = 0
			mudancas_rapidas_restantes = 3
			cliques_acumulados = 0
		
		var limite_cliques: int = 1 if mudancas_rapidas_restantes > 0 else 15
		
		if cliques_acumulados >= limite_cliques:
			cliques_acumulados = 0
			indice_aparencia_atual = (indice_aparencia_atual + 1) % texturas_botao_clique.size()
			if botao_clique:
				botao_clique.texture_normal = texturas_botao_clique[indice_aparencia_atual]
			
			if mudancas_rapidas_restantes > 0:
				mudancas_rapidas_restantes -= 1
	
	criar_texto_flutuante(get_local_mouse_position(), "+" + str(ganho_final))

func efeito_pulinho_botao() -> void:
	if botao_clique:
		if tween_hover_clique and tween_hover_clique.is_valid():
			tween_hover_clique.kill()
		if tween_botao_clique and tween_botao_clique.is_valid():
			tween_botao_clique.kill()
		botao_clique.pivot_offset = botao_clique.size / 2
		tween_botao_clique = create_tween()
		tween_botao_clique.tween_property(botao_clique, "scale", Vector2(0.96, 0.96), 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_botao_clique.tween_property(botao_clique, "scale", Vector2(1.035, 1.035), 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_botao_clique.tween_property(botao_clique, "scale", Vector2.ONE, 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _on_botao_clique_mouse_entered() -> void:
	_animar_hover(botao_clique, Vector2(1.018, 1.018))

func _on_botao_clique_mouse_exited() -> void:
	_animar_hover(botao_clique, Vector2.ONE)

func _on_botao_loja_mouse_entered() -> void:
	_animar_hover(botao_loja, Vector2(1.07, 1.07))

func _on_botao_loja_mouse_exited() -> void:
	_animar_hover(botao_loja, Vector2.ONE)

func _animar_hover(controle: Control, escala_destino: Vector2) -> void:
	if not controle:
		return
	var tween_anterior: Tween = tween_hover_loja if controle == botao_loja else tween_hover_clique
	if tween_anterior and tween_anterior.is_valid():
		tween_anterior.kill()
	if controle == botao_clique and tween_botao_clique and tween_botao_clique.is_valid():
		tween_botao_clique.kill()
	var tween := create_tween()
	tween.tween_property(controle, "scale", escala_destino, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if controle == botao_loja:
		tween_hover_loja = tween
	else:
		tween_hover_clique = tween

func criar_texto_flutuante(posicao: Vector2, texto: String) -> void:
	var texto_mais_um = Label.new()
	texto_mais_um.text = texto
	texto_mais_um.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto_mais_um.position = posicao
	texto_mais_um.modulate = Color(0, 0, 0, 1)
	texto_mais_um.z_index = 1
	if contador_label.label_settings:
		texto_mais_um.label_settings = contador_label.label_settings
	add_child(texto_mais_um)
	
	var tween_texto = create_tween()
	var posicao_final = texto_mais_um.position + Vector2(0, -40)
	tween_texto.tween_property(texto_mais_um, "position", posicao_final, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_texto.parallel().tween_property(texto_mais_um, "modulate", Color(0, 0, 0, 0), 0.6)
	tween_texto.tween_callback(texto_mais_um.queue_free)

func _on_botao_sair_pressed() -> void:
	salvar_progresso()
	get_tree().quit()

# --- LOJA (RETORNADA AO SISTEMA DE MOVIMENTO ORIGINAL X=700) ---

func _on_botao_loja_pressed() -> void:
	if modo_prova_ativo: 
		return
		
	if not janela_loja:
		janela_loja = find_child("JanelaLoja", true, false)
		
	if janela_loja:
		camada_loja.show()
		if tween_loja and tween_loja.is_valid():
			tween_loja.kill()
		if not janela_loja.visible:
			janela_loja.position.x = 700
		janela_loja.visible = true
		
		if mensagem_loja:
			mensagem_loja.text = "Passe o mouse para detalhes. Esc: fechar."
			mensagem_loja.modulate = Color.WHITE
		var nova_posicao_final = posicao_centro_loja
		tween_loja = create_tween()
		tween_loja.tween_property(janela_loja, "position", nova_posicao_final, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_botao_fechar_loja_pressed() -> void:
	if janela_loja:
		if tween_loja and tween_loja.is_valid():
			tween_loja.kill()
		tween_loja = create_tween()
		tween_loja.tween_property(janela_loja, "position", Vector2(700, posicao_centro_loja.y), 0.3)
		tween_loja.tween_callback(func():
			janela_loja.visible = false
			camada_loja.hide()
		)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if janela_loja and janela_loja.visible and not modo_prova_ativo:
			_on_botao_fechar_loja_pressed()
			get_viewport().set_input_as_handled()

func mostrar_mensagem_loja(texto: String, sucesso: bool = true) -> void:
	if not mensagem_loja:
		return
	if tween_mensagem_loja and tween_mensagem_loja.is_valid():
		tween_mensagem_loja.kill()
	mensagem_loja.text = texto
	mensagem_loja.modulate = Color("3f7a38") if sucesso else Color("a33c32")
	mensagem_loja.scale = Vector2(0.96, 0.96)
	mensagem_loja.pivot_offset = mensagem_loja.size / 2
	tween_mensagem_loja = create_tween()
	tween_mensagem_loja.tween_property(mensagem_loja, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animar_objeto_comprado(objeto: CanvasItem) -> void:
	if not objeto:
		return
	objeto.visible = true
	if objeto is Control:
		var controle := objeto as Control
		controle.pivot_offset = controle.size / 2
		controle.scale = Vector2(0.55, 0.55)
		controle.modulate.a = 0.25
		var tween_objeto = create_tween()
		tween_objeto.tween_property(controle, "scale", Vector2(1.08, 1.08), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_objeto.parallel().tween_property(controle, "modulate:a", 1.0, 0.16)
		tween_objeto.tween_property(controle, "scale", Vector2.ONE, 0.1)

func _atualizar_disponibilidade_loja() -> void:
	var nomes_botoes := [
		"BotaoUpgradeClique",
		"BotaoGeradorQI",
		"BotaoMultiplicadorClique",
		"BotaoMultiplicadorPassivo",
		"BotaoEventoEspecial",
		"BotaoEventoEspecial2"
	]
	for nome in nomes_botoes:
		var botao = find_child(nome, true, false)
		if not is_instance_valid(botao) or botao.is_queued_for_deletion():
			continue
		if "custo_upgrade" in botao:
			var custo := int(botao.custo_upgrade)
			botao.disabled = qi < custo
			var disponibilidade := "Disponível para comprar" if qi >= custo else "Faltam " + str(custo - qi) + " QI"
			botao.tooltip_text = _descricao_melhoria(nome) + "\n" + disponibilidade

func _descricao_melhoria(nome: String) -> String:
	var clique_atual := obter_ganho_clique()
	var passivo_atual := obter_producao_passiva()
	var extra_clique: int = int(colecao.bonus_clique) if colecao else 0
	var extra_passivo: int = int(colecao.bonus_passivo) if colecao else 0
	match nome:
		"BotaoUpgradeClique":
			var proximo := int(round((valor_do_clique_base + 1) * multiplicador_clique)) + extra_clique
			return "QI por clique: %d → %d" % [clique_atual, proximo]
		"BotaoGeradorQI":
			var proximo := int(round((qi_por_segundo_base + 1) + (qi_por_segundo_base + 1) * multiplicador_passivo_bonus)) + extra_passivo
			return "QI por segundo: %d → %d" % [passivo_atual, proximo]
		"BotaoMultiplicadorClique":
			var multiplicador := 1.2 if multiplicador_clique == 1.0 else multiplicador_clique + 0.1
			var proximo := int(round(valor_do_clique_base * multiplicador)) + extra_clique
			return "Multiplicador: %.1fx → %.1fx\nQI por clique: %d → %d" % [multiplicador_clique, multiplicador, clique_atual, proximo]
		"BotaoMultiplicadorPassivo":
			var bonus := 0.15 if multiplicador_passivo_bonus == 0.0 else multiplicador_passivo_bonus + 0.05
			var proximo := int(round(qi_por_segundo_base + qi_por_segundo_base * bonus)) + extra_passivo
			var descricao := "Bônus passivo: %.0f%% → %.0f%%\nQI por segundo: %d → %d" % [multiplicador_passivo_bonus * 100, bonus * 100, passivo_atual, proximo]
			if qi_por_segundo_base == 0:
				descricao += "\nEste bônus melhora o apontador; não multiplica os itens da coleção."
			return descricao
		"BotaoEventoEspecial":
			return "Inicia a Prova 1. Vença para liberar o Seminário 2."
		"BotaoEventoEspecial2":
			return "Português: Modernismo, Realismo e outros movimentos.\n5 acertos • 3 vidas • 80 segundos. Revise na biblioteca!"
	return ""

# --- SALVAMENTO E CARREGAMENTO ---

func solicitar_salvamento() -> void:
	if debug_ativo or carregando_salvamento or salvamento_bloqueado or not timer_salvamento:
		return
	if timer_salvamento.is_stopped():
		timer_salvamento.start()

func salvar_progresso() -> void:
	if debug_ativo or carregando_salvamento or salvamento_bloqueado or not is_inside_tree():
		return

	var caminho := _obter_caminho_save()
	var temporario := caminho + ".tmp"
	var arquivo := FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		printerr("Não foi possível salvar o progresso. Erro: ", FileAccess.get_open_error())
		return

	arquivo.store_string(JSON.stringify(_criar_dados_salvamento(), "\t"))
	arquivo.flush()
	var erro := arquivo.get_error()
	arquivo.close()
	if erro != OK:
		printerr("Falha ao gravar save temporário: ", erro)
		return
	erro = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporario), ProjectSettings.globalize_path(caminho))
	if erro != OK:
		printerr("Não foi possível substituir o save: ", erro)
		return
	print("💾 Progresso salvo em ", caminho)

func _obter_caminho_save() -> String:
	return CAMINHO_SAVE

func carregar_progresso() -> void:
	if not FileAccess.file_exists(_obter_caminho_save()):
		print("💾 Nenhum save encontrado; iniciando um novo progresso.")
		return

	var arquivo := FileAccess.open(_obter_caminho_save(), FileAccess.READ)
	if arquivo == null:
		salvamento_bloqueado = true
		printerr("Não foi possível abrir o save. Erro: ", FileAccess.get_open_error())
		return

	var conteudo := arquivo.get_as_text()
	arquivo.close()
	var dados = JSON.parse_string(conteudo)
	if typeof(dados) != TYPE_DICTIONARY:
		salvamento_bloqueado = true
		printerr("Save inválido: o conteúdo não é um dicionário JSON.")
		return

	var versao := int(dados.get("versao", 0))
	if versao > VERSAO_SAVE:
		salvamento_bloqueado = true
		printerr("Save criado por uma versão mais nova do jogo; carregamento cancelado.")
		return

	salvamento_bloqueado = false
	carregando_salvamento = true
	_aplicar_dados_salvamento(dados)
	carregando_salvamento = false
	print("💾 Progresso carregado de ", _obter_caminho_save())

func _criar_dados_salvamento() -> Dictionary:
	var dados := {
		"versao": VERSAO_SAVE,
		"colecao": colecao.salvar() if colecao else {},
		"qi": qi,
		"clique": {
			"valor_base": valor_do_clique_base,
			"multiplicador": multiplicador_clique,
			"cliques_acumulados": cliques_acumulados,
			"total_cliques_geral": total_cliques_geral,
			"mudancas_rapidas_restantes": mudancas_rapidas_restantes,
			"indice_aparencia": indice_aparencia_atual
		},
		"producao_passiva": {
			"qi_por_segundo_base": qi_por_segundo_base,
			"bonus": multiplicador_passivo_bonus
		},
		"upgrades": {},
		"provas": {
			"prova1_concluida": prova1_concluida,
			"prova2_concluida": prova2_concluida
		},
		"audio": {}
	}

	var botao_upgrade_clique = find_child("BotaoUpgradeClique", true, false)
	if botao_upgrade_clique:
		dados["upgrades"]["clique"] = {
			"custo": botao_upgrade_clique.custo_upgrade,
			"valor": botao_upgrade_clique.valor_do_clique_atual
		}

	var botao_gerador = find_child("BotaoGeradorQI", true, false)
	if botao_gerador:
		dados["upgrades"]["gerador"] = {
			"custo": botao_gerador.custo_upgrade,
			"producao": botao_gerador.producao_atual
		}

	var botao_multiplicador = find_child("BotaoMultiplicadorClique", true, false)
	if botao_multiplicador:
		dados["upgrades"]["multiplicador_clique"] = {
			"custo": botao_multiplicador.custo_upgrade,
			"multiplicador": botao_multiplicador.multiplicador_atual
		}

	var botao_passivo = find_child("BotaoMultiplicadorPassivo", true, false)
	if botao_passivo:
		dados["upgrades"]["bonus_passivo"] = {
			"custo": botao_passivo.custo_upgrade,
			"bonus": botao_passivo.bonus_porcentagem_total
		}

	var botao_volume = get_node_or_null("Button")
	if botao_volume:
		dados["audio"] = {
			"volume_porcentagem": botao_volume.volume_porcentagem,
			"subindo": botao_volume.subindo
		}

	return dados

func _aplicar_dados_salvamento(dados: Dictionary) -> void:
	qi = max(0, int(dados.get("qi", qi)))
	if colecao:
		colecao.carregar(_obter_dicionario(dados, "colecao"))

	var clique: Dictionary = _obter_dicionario(dados, "clique")
	valor_do_clique_base = max(1, int(clique.get("valor_base", valor_do_clique_base)))
	multiplicador_clique = max(1.0, float(clique.get("multiplicador", multiplicador_clique)))
	cliques_acumulados = max(0, int(clique.get("cliques_acumulados", cliques_acumulados)))
	total_cliques_geral = max(0, int(clique.get("total_cliques_geral", total_cliques_geral)))
	mudancas_rapidas_restantes = max(0, int(clique.get("mudancas_rapidas_restantes", mudancas_rapidas_restantes)))
	indice_aparencia_atual = max(0, int(clique.get("indice_aparencia", indice_aparencia_atual)))
	if texturas_botao_clique.size() > 0:
		indice_aparencia_atual %= texturas_botao_clique.size()
		botao_clique.texture_normal = texturas_botao_clique[indice_aparencia_atual]

	var producao_passiva: Dictionary = _obter_dicionario(dados, "producao_passiva")
	qi_por_segundo_base = max(0, int(producao_passiva.get("qi_por_segundo_base", qi_por_segundo_base)))
	multiplicador_passivo_bonus = max(0.0, float(producao_passiva.get("bonus", multiplicador_passivo_bonus)))

	_aplicar_estado_upgrades(_obter_dicionario(dados, "upgrades"))

	var provas: Dictionary = _obter_dicionario(dados, "provas")
	prova1_concluida = bool(provas.get("prova1_concluida", false))
	prova2_concluida = bool(provas.get("prova2_concluida", false))
	if prova2_concluida:
		prova1_concluida = true
	_aplicar_progressao_provas()

	_aplicar_estado_audio(_obter_dicionario(dados, "audio"))
	_aplicar_visibilidade_objetos()
	atualizar_interface()

func _aplicar_estado_upgrades(upgrades: Dictionary) -> void:
	var botao_upgrade_clique = find_child("BotaoUpgradeClique", true, false)
	var dados_clique: Dictionary = _obter_dicionario(upgrades, "clique")
	if botao_upgrade_clique:
		botao_upgrade_clique.valor_do_clique_atual = max(1, int(dados_clique.get("valor", valor_do_clique_base)))
		valor_do_clique_base = botao_upgrade_clique.valor_do_clique_atual
		botao_upgrade_clique.custo_upgrade = preload("res://economia.gd").preco("clique", valor_do_clique_base - 1)
		botao_upgrade_clique.atualizar_texto_botao()

	var botao_gerador = find_child("BotaoGeradorQI", true, false)
	var dados_gerador: Dictionary = _obter_dicionario(upgrades, "gerador")
	if botao_gerador:
		botao_gerador.producao_atual = max(0, int(dados_gerador.get("producao", qi_por_segundo_base)))
		qi_por_segundo_base = botao_gerador.producao_atual
		botao_gerador.custo_upgrade = preload("res://economia.gd").preco("gerador", qi_por_segundo_base)
		botao_gerador.atualizar_texto_botao()

	var botao_multiplicador = find_child("BotaoMultiplicadorClique", true, false)
	var dados_multiplicador: Dictionary = _obter_dicionario(upgrades, "multiplicador_clique")
	if botao_multiplicador:
		botao_multiplicador.multiplicador_atual = max(1.0, float(dados_multiplicador.get("multiplicador", multiplicador_clique)))
		multiplicador_clique = botao_multiplicador.multiplicador_atual
		botao_multiplicador.custo_upgrade = preload("res://economia.gd").preco("multiplicador", preload("res://economia.gd").nivel_multiplicador(multiplicador_clique))
		botao_multiplicador.atualizar_texto_botao()

	var botao_passivo = find_child("BotaoMultiplicadorPassivo", true, false)
	var dados_passivo: Dictionary = _obter_dicionario(upgrades, "bonus_passivo")
	if botao_passivo:
		botao_passivo.bonus_porcentagem_total = max(0.0, float(dados_passivo.get("bonus", multiplicador_passivo_bonus)))
		multiplicador_passivo_bonus = botao_passivo.bonus_porcentagem_total
		botao_passivo.custo_upgrade = preload("res://economia.gd").preco("passivo", preload("res://economia.gd").nivel_passivo(multiplicador_passivo_bonus))
		botao_passivo.atualizar_texto_botao()

func _aplicar_progressao_provas() -> void:
	var botao_prova1 = find_child("BotaoEventoEspecial", true, false)
	var botao_prova2 = find_child("BotaoEventoEspecial2", true, false)

	if botao_prova1:
		if prova1_concluida:
			if not botao_prova1.is_queued_for_deletion():
				botao_prova1.queue_free()
		else:
			botao_prova1.visible = true

	if botao_prova2:
		if prova2_concluida:
			if not botao_prova2.is_queued_for_deletion():
				botao_prova2.queue_free()
		else:
			botao_prova2.visible = prova1_concluida

func _aplicar_visibilidade_objetos() -> void:
	var lapis = get_node_or_null("LapisMesa")
	if lapis:
		lapis.visible = valor_do_clique_base > 1
	if botao_loja and colecao:
		var completo: bool = colecao.adquiridos.has("estojo")
		botao_loja.self_modulate = Color.WHITE if completo else Color(0.68, 0.68, 0.68, 1.0)
		botao_loja.tooltip_text = "Estojo completo • abrir loja" if completo else "Abrir loja • adquira o estojo completo na biblioteca"
	var no_apontador = find_child("Apontador", true, false)
	if no_apontador:
		no_apontador.visible = qi_por_segundo_base > 0
		if no_apontador.visible:
			for filho in no_apontador.get_children():
				if "visible" in filho:
					filho.visible = true
		var label_passivo = no_apontador.find_child("ValorPassivoLabel", true, false) as Label
		if label_passivo:
			var producao_final = round(qi_por_segundo_base + (qi_por_segundo_base * multiplicador_passivo_bonus))
			label_passivo.text = "+" + str(producao_final) + "/s"
			label_passivo.position = Vector2(-10, -17)

	var no_marca_texto = find_child("MarcaTexto", true, false)
	if no_marca_texto:
		no_marca_texto.visible = multiplicador_clique > 1.0
		var label_multiplicador = no_marca_texto.find_child("ValorMultiplicadorLabel", true, false) as Label
		if label_multiplicador:
			label_multiplicador.text = str(multiplicador_clique) + "x"

	var no_corretivo = find_child("Corretivo", true, false)
	if no_corretivo:
		no_corretivo.visible = multiplicador_passivo_bonus > 0.0
		var label_bonus = no_corretivo.find_child("ValorBonusLabel", true, false) as Label
		if label_bonus:
			label_bonus.text = "+" + str(round(multiplicador_passivo_bonus * 100)) + "%"

func _aplicar_estado_audio(audio: Dictionary) -> void:
	var botao_volume = get_node_or_null("Button")
	if not botao_volume:
		return
	botao_volume.volume_porcentagem = clamp(int(audio.get("volume_porcentagem", botao_volume.volume_porcentagem)), 0, 100)
	botao_volume.subindo = bool(audio.get("subindo", botao_volume.subindo))
	botao_volume.atualizar_visual_e_audio()

func _obter_dicionario(dados: Dictionary, chave: String) -> Dictionary:
	var valor = dados.get(chave, {})
	return valor if typeof(valor) == TYPE_DICTIONARY else {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		salvar_progresso()
