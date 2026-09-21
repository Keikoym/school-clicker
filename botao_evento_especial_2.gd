extends Button

var custo_upgrade: int = preload("res://economia.gd").PROVA_2
var no_main: Node
var no_prova1: Node # Referência para a Prova1 (para saber quando ela foi vencida)
var no_prova2: Node # Referência para a Prova2 (que este botão vai abrir)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Começa invisível! Só vai aparecer quando a Prova 1 for completada
	visible = false
	
	# Sobe a árvore procurando as referências necessárias
	var atual = get_parent()
	while atual != null:
		if "qi" in atual:
			no_main = atual
		
		# Procura os nós das duas provas
		if atual.has_node("Prova1"):
			no_prova1 = atual.get_node("Prova1")
		if atual.has_node("Prova2"):
			no_prova2 = atual.get_node("Prova2")
			
		atual = atual.get_parent()
	
	if not no_main:
		print("AVISO: Botão do Seminário 2 não encontrou o script Main!")
	
	# CONEXÃO CRÍTICA: Escuta a Prova 1 para saber quando APARECER
	if no_prova1:
		print("✅ Botão do Seminário 2 se conectou à Prova1!")
		if not no_prova1.prova_finalizada.is_connected(_on_prova1_finalizada):
			no_prova1.prova_finalizada.connect(_on_prova1_finalizada)
	else:
		print("⚠️ AVISO: Botão do Seminário 2 não encontrou a 'Prova1'.")

	# CONEXÃO CRÍTICA 2: Escuta a Prova 2 para saber quando SUMIR de vez
	if no_prova2:
		print("✅ Botão do Seminário 2 se conectou à Prova2!")
		if not no_prova2.has_signal("prova_finalizada"):
			print("⚠️ AVISO: Prova2 precisa ter o sinal 'prova_finalizada' criado!")
		else:
			no_prova2.prova_finalizada.connect(_on_prova2_finalizada_com_sucesso)

	if not pressed.is_connected(_on_pressed_evento):
		pressed.connect(_on_pressed_evento)
		
	atualizar_texto_botao()

func _on_pressed_evento() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("🎰 BOTÃO DO SEMINÁRIO 2 CLICADO!")
	
	if no_main:
		print("Placar atual no Main: ", no_main.qi, " | Custo necessário: ", custo_upgrade)
		
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade 
			no_main.atualizar_interface() 
			no_main.mostrar_mensagem_loja("Seminário 2 iniciado. Boa prova!", true)
			
			print("✅ Prova 2 comprada! Avisando o Main...")
			
			# Chama a função no Main para abrir a Prova 2
			if no_main.has_method("iniciar_modo_prova2"):
				no_main.iniciar_modo_prova2()
			else:
				print("❌ Erro: Crie a função 'iniciar_modo_prova2' no seu Main!")
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para o Seminário 2.", false)
			print("❌ QI insuficiente para o Seminário 2! Precisa de: ", custo_upgrade)

# --- REVELA O BOTÃO QUANDO A PROVA 1 FOR CONCLUÍDA ---
func _on_prova1_finalizada() -> void:
	if no_prova1 and "ganhou_maratona" in no_prova1:
		if no_prova1.ganhou_maratona == true:
			print("🔓 PROVA 1 CONCLUÍDA! Liberando Botão do Seminário 2 na tela!")
			visible = true # O botão aparece para o jogador poder comprar
		else:
			# Se o player perdeu a Prova 1, o botão 2 garante que continua escondido
			visible = false 

# --- DELETA O BOTÃO SE A PROVA 2 FOR CONCLUÍDA COM SUCESSO ---
func _on_prova2_finalizada_com_sucesso() -> void:
	if no_prova2 and "ganhou_maratona" in no_prova2:
		if no_prova2.ganhou_maratona == true:
			print("🏆 PROVA 2 CONCLUÍDA COM SUCESSO! Deletando botão do Seminário 2...")
			queue_free()
		else:
			print("❌ Jogador perdeu a Prova 2, mantendo o botão ativo.")

func atualizar_texto_botao() -> void:
	text = "SEMINÁRIO 2 • PORTUGUÊS\nCusto: " + str(custo_upgrade) + " QI"
