extends Button

# Sinal personalizado que envia o novo multiplicador para o Main
signal multiplicador_melhorado(novo_multiplicador)

var custo_upgrade: int = 250       # Começa custando 250 QI
var multiplicador_atual: float = 1.0

# Referência para o Main
var no_main: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var atual = get_parent()
	while atual != null:
		if "qi" in atual:
			no_main = atual
			break
		atual = atual.get_parent()
	
	if no_main:
		if not multiplicador_melhorado.is_connected(no_main._on_multiplicador_melhorado):
			multiplicador_melhorado.connect(no_main._on_multiplicador_melhorado)
	else:
		print("AVISO: Botão Multiplicador não encontrou o script Main!")

	if not pressed.is_connected(_on_pressed_multiplicador):
		pressed.connect(_on_pressed_multiplicador)
		
	atualizar_texto_botao()

func _on_pressed_multiplicador() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("BOTÃO MULTIPLICADOR CLICADO!")
	
	if no_main:
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade  # Gasta o QI
			
			if multiplicador_atual == 1.0:
				multiplicador_atual = 1.2
			else:
				multiplicador_atual += 0.1
			
			custo_upgrade = int(custo_upgrade * 2.2)
			
			atualizar_texto_botao()
			no_main.atualizar_interface()
			
			# --- NOSSA NOVA LÓGICA DE APARECER O MARCA TEXTO ---
			# Procura o nó MarcaTexto diretamente dentro do Main
			var no_marca_texto = no_main.find_child("MarcaTexto", true, false)
			if no_marca_texto:
				# Faz o objeto aparecer na tela!
				no_marca_texto.visible = true
				
				# Se você tiver uma label dentro dele para mostrar o multiplicador atual (ex: ValorMultiplicadorLabel)
				var label_valor = no_marca_texto.find_child("ValorMultiplicadorLabel", true, false) as Label
				if label_valor:
					label_valor.text = str(multiplicador_atual) + "x"
				no_main.animar_objeto_comprado(no_marca_texto)
			no_main.mostrar_mensagem_loja("Multiplicador de clique: " + str(multiplicador_atual) + "x", true)
			
			# Envia o sinal para o Main atualizar o multiplicador dos cliques
			multiplicador_melhorado.emit(multiplicador_atual)
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para o marca-texto.", false)
			print("QI insuficiente para o Multiplicador!")

func atualizar_texto_botao() -> void:
	text = "MARCA-TEXTO  " + str(multiplicador_atual) + "x\nCusto: " + str(custo_upgrade) + " QI"
