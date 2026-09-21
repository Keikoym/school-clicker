extends Button

# Sinal personalizado que envia o bônus passivo total para o Main
signal bonus_passivo_atualizado(novo_bonus)

var custo_upgrade: int = preload("res://economia.gd").preco("passivo", 0)
var bonus_porcentagem_total: float = 0.0

# Referência para o Main
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
	
	# Conecta o sinal de forma segura
	if no_main:
		if not bonus_passivo_atualizado.is_connected(no_main._on_bonus_passivo_atualizado):
			bonus_passivo_atualizado.connect(no_main._on_bonus_passivo_atualizado)
	else:
		print("AVISO: Botão de Bônus Passivo não encontrou o script Main!")

	if not pressed.is_connected(_on_pressed_bonus_passivo):
		pressed.connect(_on_pressed_bonus_passivo)
		
	atualizar_texto_botao()

func _on_pressed_bonus_passivo() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("BOTÃO DE BÔNUS PASSIVO CLICADO!")
	
	if no_main:
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade  # Gasta o QI
			
			# Primeira compra dá 15% (0.15). As próximas adicionam 5% (0.05)
			if bonus_porcentagem_total == 0.0:
				bonus_porcentagem_total = 0.15
			else:
				bonus_porcentagem_total += 0.05
			
			custo_upgrade = preload("res://economia.gd").preco("passivo", preload("res://economia.gd").nivel_passivo(bonus_porcentagem_total))
			
			atualizar_texto_botao()
			no_main.atualizar_interface()
			
			# --- NOSSA NOVA LÓGICA DE APARECER O CORRETIVO ---
			# Procura o nó Corretivo diretamente dentro do Main
			var no_corretivo = no_main.find_child("Corretivo", true, false)
			if no_corretivo:
				# Faz o objeto aparecer na tela!
				no_corretivo.visible = true
				
				# Se você tiver uma label dentro dele para mostrar a porcentagem atual (ex: ValorBonusLabel)
				var label_valor = no_corretivo.find_child("ValorBonusLabel", true, false) as Label
				if label_valor:
					label_valor.text = "+" + str(round(bonus_porcentagem_total * 100)) + "%"
				no_main.animar_objeto_comprado(no_corretivo)
			no_main.mostrar_mensagem_loja("Bônus passivo: +" + str(round(bonus_porcentagem_total * 100)) + "%", true)
			
			# CORRIGIDO: Envia o sinal para o Main aplicar o bônus passivo no jogo!
			bonus_passivo_atualizado.emit(bonus_porcentagem_total)
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para o corretivo.", false)
			print("QI insuficiente para o Bônus Passivo!")

func atualizar_texto_botao() -> void:
	var porcentagem_texto = str(round(bonus_porcentagem_total * 100))
	text = "CORRETIVO  +" + porcentagem_texto + "% passivo\nCusto: " + str(custo_upgrade) + " QI"
