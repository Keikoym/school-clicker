extends Button

var custo_upgrade: int = 12 # Custo do upgrade
var no_main: Node
var no_prova: Node # Referência para a Prova1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Encontra o script do Main e a Prova1 subindo a árvore de nós de forma segura
	var atual = get_parent()
	while atual != null:
		if "qi" in atual:
			no_main = atual
		
		if atual.has_node("Prova1"):
			no_prova = atual.get_node("Prova1")
		elif atual.name == "Prova1":
			no_prova = atual
			
		atual = atual.get_parent()
	
	if not no_main:
		print("AVISO: Botão do Seminário não encontrou o script Main!")
	
	# CONEXÃO CRÍTICA: Escuta o sinal de finalização da prova
	if no_prova:
		print("✅ Botão do Seminário se conectou à Prova1 com sucesso!")
		if not no_prova.prova_finalizada.is_connected(_on_prova_finalizada_com_sucesso):
			no_prova.prova_finalizada.connect(_on_prova_finalizada_com_sucesso)
	else:
		print("⚠️ AVISO: Botão do Seminário não encontrou o nó 'Prova1' na árvore.")

	if not pressed.is_connected(_on_pressed_evento):
		pressed.connect(_on_pressed_evento)
		
	atualizar_texto_botao()

func _on_pressed_evento() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("🎰 BOTÃO DO SEMINÁRIO CLICADO!")
	
	if no_main:
		print("Placar atual do jogador no Main: ", no_main.qi, " | Custo necessário: ", custo_upgrade)
		
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade 
			no_main.atualizar_interface() 
			no_main.mostrar_mensagem_loja("Seminário 1 iniciado. Boa prova!", true)
			
			print("✅ Item especial comprado com sucesso! Avisando o Main...")
			
			if no_main.has_method("iniciar_modo_prova"):
				no_main.iniciar_modo_prova()
			else:
				print("❌ Erro: A função iniciar_modo_prova não foi encontrada no Main.")
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para o Seminário 1.", false)
			print("❌ Você não tem QI suficiente! Precisa de: ", custo_upgrade)
	else:
		print("❌ Erro: O botão de evento não encontrou o Main de jeito nenhum.")

# --- FUNÇÃO CORRIGIDA QUE FAZ O BOTÃO SUMIR APENAS NA VITÓRIA ---
func _on_prova_finalizada_com_sucesso() -> void:
	# Agora o botão verifica a variável real de conclusão e não apenas as vidas restantes
	if no_prova and "ganhou_maratona" in no_prova:
		if no_prova.ganhou_maratona == true:
			print("🏆 PROVA CONCLUÍDA COM SUCESSO! Deletando o botão do Seminário...")
			queue_free() # Destrói o botão para sumir do mapa
		else:
			print("❌ O jogador perdeu a prova (Tempo ou Vidas), mantendo botão ativo para nova tentativa.")

func atualizar_texto_botao() -> void:
	text = "SEMINÁRIO 1\nCusto: " + str(custo_upgrade) + " QI"
