extends Node2D

@onready var musica_principal: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayerPrincipal")
@onready var musica_prova: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayerProva")

func iniciar_modo_prova() -> void:
	if musica_principal:
		musica_principal.stop()
	if musica_prova:
		musica_prova.play()

func fechar_prova() -> void:
	if musica_prova:
		musica_prova.stop()
	if musica_principal:
		musica_principal.play()
