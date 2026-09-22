extends Control

# Sinal obrigatório que a Prova2 vai escutar para saber o que aconteceu
signal minigame_terminou(venceu: bool)

# --- BANCO DE DADOS DO QUIZ 2 ---
var banco_perguntas: Array[Dictionary] = [
	{"pergunta": "Qual movimento faz crítica social sem idealizar a vida?", "correta": "Realismo", "errada1": "Romantismo", "errada2": "Trovadorismo"},
	{"pergunta": "Quem escreveu 'Dom Casmurro'?", "correta": "Machado de Assis", "errada1": "Aluísio Azevedo", "errada2": "Oswald de Andrade"},
	{"pergunta": "Em que ano foi a Semana de Arte Moderna?", "correta": "1922", "errada1": "1930", "errada2": "1900"},
	{"pergunta": "Como chamam os versos sem métrica fixa?", "correta": "Versos livres", "errada1": "Sonetos", "errada2": "Versos brancos"},
	{"pergunta": "O Realismo reagiu contra qual movimento?", "correta": "Romantismo", "errada1": "Barroco", "errada2": "Parnasianismo"},
	{"pergunta": "Quem escreveu o livro 'Macunaíma'?", "correta": "Mário de Andrade", "errada1": "Oswald de Andrade", "errada2": "Manuel Bandeira"},
	{"pergunta": "O Realismo foca em qual tipo de análise?", "correta": "Psicológica e social", "errada1": "Idealização amorosa", "errada2": "Farsa e comédia"},
	{"pergunta": "Quem escreveu o Manifesto Antropófago?", "correta": "Oswald de Andrade", "errada1": "Machado de Assis", "errada2": "Castro Alves"},
	{"pergunta": "Qual era o foco da linguagem modernista?", "correta": "Fala cotidiana do povo", "errada1": "Norma culta tradicional", "errada2": "Português arcaico"},
	{"pergunta": "Quem escreveu a obra 'O Cortiço'?", "correta": "Aluísio Azevedo", "errada1": "Machado de Assis", "errada2": "Carlos Drummond"},
	{"pergunta": "Em qual cidade aconteceu a Semana de 1922?", "correta": "São Paulo", "errada1": "Salvador", "errada2": "Brasília"},
	{"pergunta": "O Modernismo defendia maior...", "correta": "Liberdade artística", "errada1": "Rigidez das regras", "errada2": "Cópia dos antigos"},
	{"pergunta": "Qual movimento costuma idealizar o amor e o herói?", "correta": "Romantismo", "errada1": "Realismo", "errada2": "Naturalismo"},
	{"pergunta": "'Dom Casmurro' é associado a qual movimento?", "correta": "Realismo", "errada1": "Modernismo", "errada2": "Barroco"},
	{"pergunta": "'Macunaíma' é uma obra do...", "correta": "Modernismo", "errada1": "Parnasianismo", "errada2": "Trovadorismo"},
	{"pergunta": "'O Cortiço' é uma obra do...", "correta": "Naturalismo", "errada1": "Romantismo", "errada2": "Parnasianismo"},
	{"pergunta": "O Naturalismo destaca a influência de quê?", "correta": "Meio e hereditariedade", "errada1": "Magia e feitiços", "errada2": "Heróis perfeitos"},
	{"pergunta": "Qual movimento valoriza muito a forma dos versos?", "correta": "Parnasianismo", "errada1": "Naturalismo", "errada2": "Realismo"},
	{"pergunta": "Quem escreveu 'Memórias Póstumas de Brás Cubas'?", "correta": "Machado de Assis", "errada1": "Mário de Andrade", "errada2": "Oswald de Andrade"},
	{"pergunta": "Os modernistas valorizaram a cultura...", "correta": "Brasileira", "errada1": "Apenas medieval", "errada2": "Apenas romana"}
]

var perguntas_disponiveis: Array[Dictionary] = []
var pergunta_atual: Dictionary
var texto_resposta_correta: String
var jogo_finalizado: bool = false
var ajuda_cola: Button
var perguntas_respondidas_nesta_prova: int = 0

@onready var label_pergunta: Label = find_child("TextoPergunta", true, false)
@onready var label_contador: Label = find_child("ContadorPerguntas", true, false) 
@onready var botao1: Button = find_child("Opcao1", true, false)
@onready var botao2: Button = find_child("Opcao2", true, false)
@onready var botao3: Button = find_child("Opcao3", true, false)
@onready var feedback_label: Label = find_child("FeedbackLabel", true, false)
@onready var barra_visual: ProgressBar = find_child("BarraVisual", true, false)

func _ready() -> void:
	ajuda_cola = preload("res://cola_quiz.gd").new()
	add_child(ajuda_cola)
	print("🚨 QUIZ 2: Inicializado com sucesso!")
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

	# SEGURANÇA: Aguarda um frame para que toda a interface esteja montada e a barra estabilizada
	await get_tree().process_frame
	puxar_nova_pergunta()

func _on_botao1_pressed() -> void: _on_opcao_escolhida(botao1)
func _on_botao2_pressed() -> void: _on_opcao_escolhida(botao2)
func _on_botao3_pressed() -> void: _on_opcao_escolhida(botao3)

func puxar_nova_pergunta() -> void:
	if ajuda_cola:
		ajuda_cola.usada = false
	_resetar_feedback_visual()
	# Atualiza o texto visual do contador na tela (ex: "0 / 5", "1 / 5")
	if label_contador:
		label_contador.text = "PORTUGUÊS • " + str(perguntas_respondidas_nesta_prova) + " / 5"

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
	if jogo_finalizado or botao_clicado.disabled: return
	jogo_finalizado = true
	
	botao1.disabled = true
	botao2.disabled = true
	botao3.disabled = true
	
	if botao_clicado.text == texto_resposta_correta:
		print("✨ Quiz 2: Resposta Correta!")
		botao_clicado.self_modulate = Color("73c66a")
		if feedback_label:
			feedback_label.text = "CORRETO!"
			feedback_label.modulate = Color("287234")
		perguntas_respondidas_nesta_prova += 1
		
		# Atualiza o contador na tela na hora para o jogador ver que contou o ponto!
		if label_contador:
			label_contador.text = "PORTUGUÊS • " + str(perguntas_respondidas_nesta_prova) + " / 5"
			
		await get_tree().create_timer(0.5).timeout
		puxar_nova_pergunta()
	else:
		print("💥 Quiz 2: Resposta Errada!")
		botao_clicado.self_modulate = Color("e06a5f")
		if feedback_label:
			feedback_label.text = "Correta: " + texto_resposta_correta
			feedback_label.modulate = Color("9b2f29")
		minigame_terminou.emit(false)

func _resetar_feedback_visual() -> void:
	for botao in [botao1, botao2, botao3]:
		if botao:
			botao.self_modulate = Color.WHITE
	if feedback_label:
		feedback_label.text = ""
