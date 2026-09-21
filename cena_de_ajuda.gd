extends Control

@onready var painel: Control = $Margem
@onready var botao_voltar: Button = find_child("BotaoVoltar", true, false)
@onready var transicao: ColorRect = $Transicao

var voltando: bool = false

func _ready() -> void:
	if botao_voltar and not botao_voltar.pressed.is_connected(_on_botao_voltar_pressed):
		botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	
	painel.modulate.a = 0.0
	painel.scale = Vector2(0.97, 0.97)
	painel.pivot_offset = painel.size / 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(painel, "modulate:a", 1.0, 0.25)
	tween.tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_botao_voltar_pressed() -> void:
	if voltando:
		return
	voltando = true
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transicao, "color:a", 1.0, 0.2)
	await tween.finished
	var resultado = get_tree().change_scene_to_file("res://menu_principal.tscn")
	if resultado != OK:
		printerr("Erro ao voltar para o menu. Código: ", resultado)
		voltando = false
		transicao.color.a = 0.0
		transicao.mouse_filter = Control.MOUSE_FILTER_IGNORE
