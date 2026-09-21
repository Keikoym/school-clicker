extends Control

@onready var conteudo: Control = $Conteudo
@onready var transicao: ColorRect = $Transicao

var trocando_de_cena: bool = false

func _ready() -> void:
	add_child(preload("res://painel_desenvolvedor.gd").new())
	conteudo.modulate.a = 0.0
	conteudo.position.y += 12.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(conteudo, "modulate:a", 1.0, 0.35)
	tween.tween_property(conteudo, "position:y", conteudo.position.y - 12.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_bota_ojogar_pressed() -> void:
	_trocar_cena("res://principalgame.tscn")

func _on_bota_oajuda_pressed() -> void:
	_trocar_cena("res://CenaDeAjuda.tscn")

func _on_bota_osair_pressed() -> void:
	if trocando_de_cena:
		return
	trocando_de_cena = true
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transicao, "color:a", 1.0, 0.2)
	await tween.finished
	get_tree().quit()

func _trocar_cena(caminho: String) -> void:
	if trocando_de_cena:
		return
	trocando_de_cena = true
	transicao.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transicao, "color:a", 1.0, 0.2)
	await tween.finished
	var resultado = get_tree().change_scene_to_file(caminho)
	if resultado != OK:
		printerr("Erro ao trocar de cena. Código: ", resultado)
		trocando_de_cena = false
		transicao.color.a = 0.0
		transicao.mouse_filter = Control.MOUSE_FILTER_IGNORE
