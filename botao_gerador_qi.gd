extends Button

# Sinal personalizado enviado para o Main para ativar a produção por segundo
signal gerador_comprado(producao_por_segundo)

var custo_upgrade: int = preload("res://economia.gd").preco("gerador", 0)
var producao_atual: int = 0

# Referência direta para o nó principal (Main) do jogo
var no_main: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Encontra o script do Main subindo a árvore de nós de forma segura
	var atual = get_parent()
	while atual != null:
		if "qi" in atual:
			no_main = atual
			break
		atual = atual.get_parent()
	
	# Conecta o sinal do próprio botão à função do Main
	if no_main:
		if not gerador_comprado.is_connected(no_main._on_gerador_comprado):
			gerador_comprado.connect(no_main._on_gerador_comprado)
	else:
		print("AVISO: Botão Gerador não encontrou o script Main!")

	# Conecta o clique físico do botão
	if not pressed.is_connected(_on_pressed_gerador):
		pressed.connect(_on_pressed_gerador)
		
	atualizar_texto_botao()

func _on_pressed_gerador() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("BOTÃO GERADOR FOI CLICADO!")
	
	if no_main:
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade  # Gasta o QI do jogador
			
			producao_atual += 1          # Aumenta a produção (+1 QI/segundo)
			custo_upgrade = preload("res://economia.gd").preco("gerador", producao_atual)
			
			atualizar_texto_botao()
			no_main.atualizar_interface() # Atualiza o placar do topo
			
			# --- BUSCA E POSICIONAMENTO DO APONTADOR ---
			var raiz_da_cena = get_tree().current_scene
			var no_apontador = raiz_da_cena.find_child("Apontador", true, false)
			
			if no_apontador:
				# Força a visibilidade do Node2D
				no_apontador.visible = true
				
				# Força a visibilidade de todos os filhos dele
				for filho in no_apontador.get_children():
					if "visible" in filho:
						filho.visible = true
				
				# Procura a Label lá dentro
				var label_valor = no_apontador.find_child("ValorPassivoLabel", true, false) as Label
				if label_valor:
					# 1. Atualiza o texto com o bônus correto
					var bonus_porcentagem = no_main.multiplicador_passivo_bonus if "multiplicador_passivo_bonus" in no_main else 0.0
					var valor_final = round(producao_atual + (producao_atual * bonus_porcentagem))
					label_valor.text = "+" + str(valor_final) + "/s"
					
					# 2. FORÇA A POSIÇÃO EM CIMA:
					# Se a Label for FILHA do Apontador, mudamos a posição local dela.
					# Se ela estiver um pouco pro lado, você pode mudar o X (0) e o Y (-60) até ficar perfeito.
					label_valor.position = Vector2(-10, -17)
					
					print("✅ Sucesso: Texto posicionado acima do Apontador!")
				else:
					print("⚠️ AVISO: Não achou a 'ValorPassivoLabel' dentro do Apontador.")
			else:
				print("❌ ERRO CRÍTICO: Não achou nenhum nó chamado 'Apontador'!")
			
			# Dispara o sinal avisando o Main
			no_main.animar_objeto_comprado(no_apontador)
			no_main.mostrar_mensagem_loja("Produção automática: +" + str(producao_atual) + " QI/s", true)
			gerador_comprado.emit(producao_atual)
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para o apontador.", false)
			print("Você não tem QI suficiente para o Apontador!")
	else:
		print("Erro: O botão gerador não está conectado ao Main.")

func atualizar_texto_botao() -> void:
	text = "APONTADOR  +1 QI/s\nCusto: " + str(custo_upgrade) + " QI"
