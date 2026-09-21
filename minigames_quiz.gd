extends Control

# Sinal obrigatório que a Prova1 vai escutar para saber o que aconteceu
signal minigame_terminou(venceu: bool)

# --- BANCO DE DADOS ---
var banco_perguntas: Array[Dictionary] = [
	{"pergunta": "Quanto é 7 + 8?", "correta": "15", "errada1": "14", "errada2": "16"},
	{"pergunta": "Quanto é 4 x 6?", "correta": "24", "errada1": "20", "errada2": "28"},
	{"pergunta": "Quanto é 15 - 9?", "correta": "6", "errada1": "5", "errada2": "7"},
	{"pergunta": "Quanto é 20 / 4?", "correta": "5", "errada1": "4", "errada2": "6"},
	{"pergunta": "Quanto é 11 + 13?", "correta": "24", "errada1": "22", "errada2": "25"},
	{"pergunta": "Quanto é 7 x 3?", "correta": "21", "errada1": "18", "errada2": "24"},
	{"pergunta": "Quanto é 10 + 15?", "correta": "25", "errada1": "20", "errada2": "30"},
	{"pergunta": "Quanto é 9 x 4?", "correta": "36", "errada1": "32", "errada2": "40"},
	{"pergunta": "Quanto é 18 - 6?", "correta": "12", "errada1": "10", "errada2": "14"},
	{"pergunta": "Quanto é 24 / 6?", "correta": "4", "errada1": "3", "errada2": "5"},
	{"pergunta": "Quanto é 35 - 17?", "correta": "18", "errada1": "16", "errada2": "19"},
	{"pergunta": "Quanto é 7 x 6?", "correta": "42", "errada1": "36", "errada2": "48"},
	{"pergunta": "Quanto é 64 / 8?", "correta": "8", "errada1": "7", "errada2": "9"},
	{"pergunta": "Quanto é 19 + 14?", "correta": "33", "errada1": "32", "errada2": "34"},
	{"pergunta": "Quanto é 50 - 28?", "correta": "22", "errada1": "20", "errada2": "24"},
	{"pergunta": "Quanto é 9 x 8?", "correta": "72", "errada1": "64", "errada2": "81"},
	{"pergunta": "Quanto é 81 / 9?", "correta": "9", "errada1": "8", "errada2": "7"},
	{"pergunta": "Quanto é 27 + 16?", "correta": "43", "errada1": "41", "errada2": "45"},
	{"pergunta": "Quanto é 60 - 34?", "correta": "26", "errada1": "24", "errada2": "28"},
	{"pergunta": "Quanto é 4 x 12?", "correta": "48", "errada1": "44", "errada2": "52"},
	{"pergunta": "Quanto é 42 / 6?", "correta": "7", "errada1": "6", "errada2": "8"},
	{"pergunta": "Quanto é 38 + 25?", "correta": "63", "errada1": "61", "errada2": "65"},
	{"pergunta": "Quanto é 75 - 49?", "correta": "26", "errada1": "25", "errada2": "27"},
	{"pergunta": "Quanto é 8 x 7?", "correta": "56", "errada1": "54", "errada2": "58"},
	{"pergunta": "Quanto é 56 / 7?", "correta": "8", "errada1": "6", "errada2": "9"},
	{"pergunta": "Quanto é 47 + 18?", "correta": "65", "errada1": "63", "errada2": "67"},
	{"pergunta": "Quanto é 90 - 53?", "correta": "37", "errada1": "35", "errada2": "39"},
	{"pergunta": "Quanto é 3 x 15?", "correta": "45", "errada1": "40", "errada2": "50"},
	{"pergunta": "Quanto é 72 / 8?", "correta": "9", "errada1": "8", "errada2": "10"},
	{"pergunta": "Quanto é 20 + 20 + 20 + 7?", "correta": "67", "errada1": "69", "errada2": "68"}
	]

var perguntas_disponiveis: Array[Dictionary] = []
var pergunta_atual: Dictionary
var texto_resposta_correta: String
var jogo_finalizado: bool = false
var perguntas_respondidas_nesta_prova: int = 0

@onready var label_pergunta: Label = find_child("TextoPergunta", true, false)
@onready var label_contador: Label = find_child("ContadorPerguntas", true, false) # <-- Referência do texto de contagem
@onready var botao1: Button = find_child("Opcao1", true, false)
@onready var botao2: Button = find_child("Opcao2", true, false)
@onready var botao3: Button = find_child("Opcao3", true, false)
@onready var feedback_label: Label = find_child("FeedbackLabel", true, false)
@onready var barra_visual: ProgressBar = find_child("BarraVisual", true, false)

func _ready() -> void:
	randomize()
	perguntas_disponiveis = banco_perguntas.duplicate()
	perguntas_respondidas_nesta_prova = 0
	
	if barra_visual and barra_visual.has_method("resetar_barra"):
		barra_visual.resetar_barra()
	
	# Conexões de segurança dos botões
	if botao1.pressed.is_connected(_on_botao1_pressed): botao1.pressed.disconnect(_on_botao1_pressed)
	if botao2.pressed.is_connected(_on_botao2_pressed): botao2.pressed.disconnect(_on_botao2_pressed)
	if botao3.pressed.is_connected(_on_botao3_pressed): botao3.pressed.disconnect(_on_botao3_pressed)
	
	botao1.pressed.connect(_on_botao1_pressed)
	botao2.pressed.connect(_on_botao2_pressed)
	botao3.pressed.connect(_on_botao3_pressed)

	puxar_nova_pergunta()

func _on_botao1_pressed() -> void: _on_opcao_escolhida(botao1)
func _on_botao2_pressed() -> void: _on_opcao_escolhida(botao2)
func _on_botao3_pressed() -> void: _on_opcao_escolhida(botao3)

func puxar_nova_pergunta() -> void:
	_resetar_feedback_visual()
	# Atualiza o texto visual do contador na tela (ex: "0 / 5", "1 / 5")
	if label_contador:
		label_contador.text = str(perguntas_respondidas_nesta_prova) + " / 5"

	# Se já respondeu as 5 corretas necessárias, finaliza com vitória
	if perguntas_respondidas_nesta_prova >= 5:
		if barra_visual and barra_visual.has_method("parar_barra"):
			barra_visual.parar_barra()
		minigame_terminou.emit(true)
		return
		
	if perguntas_disponiveis.is_empty():
		perguntas_disponiveis = banco_perguntas.duplicate()
	if perguntas_disponiveis.is_empty():
		jogo_finalizado = true
		minigame_terminou.emit(false)
		return
	jogo_finalizado = false
	
	var indice_sorteado = randi() % perguntas_disponiveis.size()
	pergunta_atual = perguntas_disponiveis[indice_sorteado]
	perguntas_disponiveis.remove_at(indice_sorteado)
	
	texto_resposta_correta = pergunta_atual["correta"]
	label_pergunta.text = pergunta_atual["pergunta"]
	
	var opcoes = [pergunta_atual["correta"], pergunta_atual["errada1"], pergunta_atual["errada2"]]
	opcoes.shuffle()
	
	botao1.text = opcoes[0]
	botao2.text = opcoes[1]
	botao3.text = opcoes[2]
	
	botao1.disabled = false
	botao2.disabled = false
	botao3.disabled = false
	
	# Garante que a barra continue se movendo livremente
	if barra_visual:
		barra_visual.parado = false

func _on_opcao_escolhida(botao_clicado: Button) -> void:
	if jogo_finalizado: return
	jogo_finalizado = true
	
	botao1.disabled = true
	botao2.disabled = true
	botao3.disabled = true
	
	if botao_clicado.text == texto_resposta_correta:
		print("✨ Resposta Correta!")
		botao_clicado.self_modulate = Color("73c66a")
		if feedback_label:
			feedback_label.text = "CORRETO!"
			feedback_label.modulate = Color("287234")
		perguntas_respondidas_nesta_prova += 1
		
		# Atualiza o contador na tela na hora para o jogador ver que contou o ponto!
		if label_contador:
			label_contador.text = str(perguntas_respondidas_nesta_prova) + " / 5"
			
		await get_tree().create_timer(0.5).timeout
		puxar_nova_pergunta()
	else:
		print("💥 Resposta Errada!")
		botao_clicado.self_modulate = Color("e06a5f")
		if feedback_label:
			feedback_label.text = "RESPOSTA ERRADA"
			feedback_label.modulate = Color("9b2f29")
		minigame_terminou.emit(false)

func _resetar_feedback_visual() -> void:
	for botao in [botao1, botao2, botao3]:
		if botao:
			botao.self_modulate = Color.WHITE
	if feedback_label:
		feedback_label.text = ""
