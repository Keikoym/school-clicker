extends ProgressBar

const DURACAO: float = 80.0
var parado: bool = false
var tempo_restante: float = DURACAO

@onready var tempo_texto: Label = find_child("TempoTexto", true, false)

func _ready() -> void:
	resetar_barra()

func _process(delta: float) -> void:
	if parado:
		return
	tempo_restante = maxf(0.0, tempo_restante - delta)
	value = (tempo_restante / DURACAO) * 100.0
	_atualizar_texto()
	if tempo_restante <= 0.0:
		parado = true

func parar_barra() -> void:
	parado = true

func resetar_barra() -> void:
	parado = false
	tempo_restante = DURACAO
	value = 100.0
	_atualizar_texto()

func _atualizar_texto() -> void:
	if tempo_texto:
		tempo_texto.text = str(ceili(tempo_restante)) + "s"
