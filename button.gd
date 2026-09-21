extends Button

# Mantido no save por compatibilidade com versões anteriores.
var subindo: bool = false

# Guarda a porcentagem atual (começa em 100%)
var volume_porcentagem: int = 100

# Nome do canal de áudio no Godot (o padrão para o jogo todo é "Master")
@export var nome_canal_audio: String = "Master"

var indice_canal: int
var no_main: Node

func _ready() -> void:
	# Pega o ID do canal de áudio pelo nome
	indice_canal = AudioServer.get_bus_index(nome_canal_audio)
	var atual = get_parent()
	while atual != null:
		if atual.has_method("solicitar_salvamento"):
			no_main = atual
			break
		atual = atual.get_parent()
	
	# Conecta o clique do botão a nossa função
	if not pressed.is_connected(_on_botao_volume_pressed):
		pressed.connect(_on_botao_volume_pressed)
		
	atualizar_visual_e_audio()

func _on_botao_volume_pressed() -> void:
	volume_porcentagem -= 25
	if volume_porcentagem < 0:
		volume_porcentagem = 100
	subindo = false

	atualizar_visual_e_audio()
	if no_main:
		no_main.call("solicitar_salvamento")

func atualizar_visual_e_audio() -> void:
	# 1. Atualiza o texto do botão para o jogador ver
	text = "SOM  " + str(volume_porcentagem) + "%"
	
	# 2. Converte a porcentagem (0 a 100) para a escala Linear (0.0 a 1.0)
	var volume_linear: float = volume_porcentagem / 100.0
	
	# 3. Converte Linear para Decibéis (dB), que é o que o Godot usa de verdade
	var volume_db: float = linear_to_db(volume_linear)
	
	# 4. Aplica o volume diretamente no canal do Godot
	if indice_canal >= 0:
		AudioServer.set_bus_volume_db(indice_canal, volume_db)
	
	# Se o volume for 0%, silencia o canal completamente para não gastar processamento à toa
	if indice_canal >= 0:
		AudioServer.set_bus_mute(indice_canal, volume_porcentagem == 0)
	
	print("🎵 Volume alterado para: ", volume_porcentagem, "% (", volume_db, " dB)")
