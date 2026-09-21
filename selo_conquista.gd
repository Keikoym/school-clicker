extends Control

var conquistada: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func definir(valor: bool) -> void:
	if valor != conquistada:
		conquistada = valor
		queue_redraw()

func _draw() -> void:
	var centro := Vector2(24, 26)
	var cor := Color("d8aa42") if conquistada else Color("a2ada4")
	draw_colored_polygon(PackedVector2Array([Vector2(12, 36), Vector2(12, 59), Vector2(24, 51), Vector2(36, 59), Vector2(36, 36)]), Color("3c725f") if conquistada else Color("c4cabd"))
	draw_circle(centro, 21, cor)
	draw_arc(centro, 17, 0, TAU, 40, Color("fff0bb") if conquistada else Color("dce0d4"), 2, true)
	var estrela := PackedVector2Array()
	for i in range(10):
		var angulo := -PI / 2.0 + i * PI / 5.0
		var raio := 11.0 if i % 2 == 0 else 5.0
		estrela.append(centro + Vector2(cos(angulo), sin(angulo)) * raio)
	draw_colored_polygon(estrela, Color("fff8df") if conquistada else Color("e8ecdf"))
