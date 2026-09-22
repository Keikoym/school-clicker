extends Button

var quiz: Control
var main: Node
var usada := false

func _ready() -> void:
	quiz = get_parent()
	var ancestral: Node = quiz.get_parent()
	while ancestral and not ancestral.has_method("consumir_cola"):
		ancestral = ancestral.get_parent()
	main = ancestral
	position = Vector2(184, 14)
	size = Vector2(128, 30)
	add_theme_font_size_override("font_size", 12)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(estado, preload("res://apresentacao.gd").painel("365b50" if estado != "disabled" else "797d70"))
	add_theme_color_override("font_color", Color("fff6dc"))
	add_theme_color_override("font_disabled_color", Color("fff6dc"))
	tooltip_text = "Gasta 1 cola e elimina 1 alternativa errada. Uma vez por pergunta."
	pressed.connect(usar)
	quiz.label_contador.position.x = 318
	quiz.label_contador.size.x = 300
	quiz.label_contador.add_theme_font_size_override("font_size", 15)
	atualizar()

func _process(_delta: float) -> void:
	atualizar()

func atualizar() -> void:
	text = "Cola usada" if usada else "Usar cola (%d)" % (main.colas if main else 0)
	disabled = usada or not main or main.colas <= 0 or quiz.jogo_finalizado or quiz.texto_resposta_correta.is_empty()
	if main and main.modo_prova_ativo:
		disabled = disabled or quiz.get_parent().encerrando or quiz.get_parent().timer_geral_prova.is_stopped()
	else:
		disabled = true

func usar() -> void:
	if usada or not main or quiz.jogo_finalizado or quiz.texto_resposta_correta.is_empty():
		return
	var erradas: Array[Button] = []
	for botao in [quiz.botao1, quiz.botao2, quiz.botao3]:
		if not botao.disabled and botao.text != quiz.texto_resposta_correta:
			erradas.append(botao)
	if erradas.is_empty() or not main.consumir_cola(quiz):
		return
	usada = true
	var removida: Button = erradas.pick_random()
	removida.disabled = true
	removida.text = "— Alternativa eliminada —"
	removida.self_modulate = Color("99958c")
	atualizar()
