extends Control

signal prova_finalizada

@export var lista_total_minigames: Array[PackedScene] = []

var minigames_escolhidos: Array[PackedScene] = []
var indice_minigame_atual: int = 0
var minigame_instanciado_atual: Node = null
var posicao_centro_prova: Vector2
var vidas: int = 3
var timer_geral_prova: Timer
var ganhou_maratona: bool = false
var encerrando: bool = false
var motivo_resultado: String = ""
@onready var indicador_vidas: Control = $ContainerVidas

@onready var resultado_painel: PanelContainer = find_child("ResultadoPainel", true, false)
@onready var resultado_titulo: Label = find_child("ResultadoTitulo", true, false)
@onready var resultado_detalhe: Label = find_child("ResultadoDetalhe", true, false)

func _ready() -> void:
	posicao_centro_prova = position
	visible = false
	timer_geral_prova = Timer.new()
	timer_geral_prova.one_shot = true
	timer_geral_prova.wait_time = 35.0
	timer_geral_prova.timeout.connect(_on_tempo_geral_esgotado)
	add_child(timer_geral_prova)

func iniciar_animacao_subida() -> void:
	indice_minigame_atual = 0
	vidas = 3
	ganhou_maratona = false
	encerrando = false
	motivo_resultado = ""
	minigames_escolhidos.clear()
	if resultado_painel:
		resultado_painel.visible = false
		resultado_painel.scale = Vector2.ONE
	atualizar_visual_vidas()
	position = Vector2(posicao_centro_prova.x, 700.0)
	visible = true
	var tween_prova = create_tween()
	tween_prova.tween_property(self, "position:y", posicao_centro_prova.y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_prova.tween_callback(sortear_e_comecar_maratona)

func sortear_e_comecar_maratona() -> void:
	if lista_total_minigames.is_empty():
		motivo_resultado = "Nenhuma atividade disponível"
		fechar_prova()
		return
	var copia_lista = lista_total_minigames.duplicate()
	copia_lista.shuffle()
	for i in range(min(5, copia_lista.size())):
		minigames_escolhidos.append(copia_lista[i])
	timer_geral_prova.start(35.0)
	proximo_minigame()

func proximo_minigame() -> void:
	if encerrando:
		return
	if is_instance_valid(minigame_instanciado_atual):
		minigame_instanciado_atual.queue_free()
	if timer_geral_prova.is_stopped():
		motivo_resultado = "Tempo esgotado" if motivo_resultado.is_empty() else motivo_resultado
		fechar_prova()
		return
	if indice_minigame_atual >= minigames_escolhidos.size():
		ganhou_maratona = true
		motivo_resultado = "5 respostas corretas"
		fechar_prova()
		return
	if vidas <= 0:
		motivo_resultado = "Vidas esgotadas"
		fechar_prova()
		return

	var cena_do_jogo = minigames_escolhidos[indice_minigame_atual]
	if cena_do_jogo == null:
		motivo_resultado = "Atividade indisponível"
		fechar_prova()
		return
	minigame_instanciado_atual = cena_do_jogo.instantiate()
	add_child(minigame_instanciado_atual)
	if minigame_instanciado_atual is Control:
		minigame_instanciado_atual.set_anchors_preset(Control.PRESET_FULL_RECT)
		minigame_instanciado_atual.position = Vector2.ZERO
		minigame_instanciado_atual.scale = Vector2.ONE
		minigame_instanciado_atual.visible = true
		minigame_instanciado_atual.mouse_filter = Control.MOUSE_FILTER_STOP
	if minigame_instanciado_atual.has_signal("minigame_terminou"):
		minigame_instanciado_atual.minigame_terminou.connect(_on_minigame_concluido)

func _on_minigame_concluido(venceu: bool) -> void:
	if encerrando:
		return
	if venceu:
		indice_minigame_atual += 1
		if indice_minigame_atual >= minigames_escolhidos.size():
			ganhou_maratona = true
			motivo_resultado = "5 respostas corretas"
			fechar_prova()
			return
		await get_tree().create_timer(0.35).timeout
		proximo_minigame()
		return

	vidas -= 1
	atualizar_visual_vidas()
	await get_tree().create_timer(0.6).timeout
	if encerrando:
		return
	if vidas <= 0:
		motivo_resultado = "Vidas esgotadas"
		fechar_prova()
	elif not timer_geral_prova.is_stopped() and is_instance_valid(minigame_instanciado_atual):
		if minigame_instanciado_atual.has_method("puxar_nova_pergunta"):
			minigame_instanciado_atual.puxar_nova_pergunta()

func _on_tempo_geral_esgotado() -> void:
	if encerrando:
		return
	motivo_resultado = "Tempo esgotado"
	_parar_barra_atual()
	fechar_prova()

func atualizar_visual_vidas() -> void:
	indicador_vidas.definir_vidas(vidas)

func _parar_barra_atual() -> void:
	if is_instance_valid(minigame_instanciado_atual):
		var barra = minigame_instanciado_atual.find_child("BarraVisual", true, false)
		if barra and barra.has_method("parar_barra"):
			barra.parar_barra()

func fechar_prova() -> void:
	if encerrando:
		return
	encerrando = true
	timer_geral_prova.stop()
	_parar_barra_atual()
	if is_instance_valid(minigame_instanciado_atual):
		minigame_instanciado_atual.queue_free()
	_exibir_resultado()
	await get_tree().create_timer(0.95).timeout
	var tween_prova = create_tween()
	tween_prova.tween_property(self, "position:y", 700.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_prova.tween_callback(func():
		visible = false
		prova_finalizada.emit()
	)

func _exibir_resultado() -> void:
	if not resultado_painel:
		return
	resultado_painel.visible = true
	resultado_painel.pivot_offset = resultado_painel.size / 2
	resultado_painel.scale = Vector2(0.72, 0.72)
	if ganhou_maratona:
		resultado_titulo.text = "APROVADO!"
		resultado_titulo.add_theme_color_override("font_color", Color("317b42"))
		resultado_detalhe.text = "5 respostas corretas"
	else:
		resultado_titulo.text = "TENTE NOVAMENTE"
		resultado_titulo.add_theme_color_override("font_color", Color("a13b32"))
		resultado_detalhe.text = motivo_resultado
	var tween_resultado = create_tween()
	tween_resultado.tween_property(resultado_painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
