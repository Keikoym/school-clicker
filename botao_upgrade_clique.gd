extends Button

# Sinal personalizado enviado para o Main
signal clique_melhorado(novo_valor)

var custo_upgrade: int = 25
var valor_do_clique_atual: int = 1

# Referência direta para o nó principal (Main) do jogo
var no_main: Node

func _ready() -> void:
	# Força o filtro do mouse a não ignorar o clique
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Encontra o script do Main subindo a árvore de nós de forma segura
	var atual = get_parent()
	while atual != null:
		if "qi" in atual:
			no_main = atual
			break
		atual = atual.get_parent()
	
	# Se achou o Main, conecta o sinal de melhoria automaticamente nele
	if no_main:
		clique_melhorado.connect(no_main._on_clique_melhorado)
	else:
		print("AVISO: Botão de Upgrade não encontrou o script Main!")

	# Conecta o clique físico do botão à função abaixo por código (Garantido!)
	if not pressed.is_connected(_on_pressed_upgrade):
		pressed.connect(_on_pressed_upgrade)
		
	atualizar_texto_botao()

# Função que roda ao clicar neste botão
func _on_pressed_upgrade() -> void:
	if no_main and no_main.modo_prova_ativo:
		return
	print("BOTÃO DE COMPRA FOI CLICADO!")
	
	if no_main:
		if no_main.qi >= custo_upgrade:
			no_main.qi -= custo_upgrade  # Tira o QI do jogador no Main
			
			valor_do_clique_atual += 1   # Melhora o poder do clique
			custo_upgrade = int(custo_upgrade * 1.8) # Aumenta o custo
			
			atualizar_texto_botao()
			no_main.atualizar_interface() # Atualiza o placar do topo
			no_main.mostrar_mensagem_loja("Clique melhorado para " + str(valor_do_clique_atual) + " QI!", true)
			
			# Dispara o sinal atualizando o multiplicador de cliques no Main
			clique_melhorado.emit(valor_do_clique_atual)
		else:
			no_main.mostrar_mensagem_loja("QI insuficiente para este upgrade.", false)
			print("Você não tem QI suficiente!")
	else:
		print("Erro: O botão não está conectado ao Main.")

func atualizar_texto_botao() -> void:
	text = "LÁPIS MELHOR  +1/clique\nCusto: " + str(custo_upgrade) + " QI"
