extends Control

var vidas: int = 3
var animacao: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	tooltip_text = "Cada resposta errada custa uma vida."

func definir_vidas(valor: int) -> void:
	var perdeu := valor < vidas
	vidas = clampi(valor, 0, 3)
	queue_redraw()
	if animacao and animacao.is_valid():
		animacao.kill()
	modulate = Color.WHITE
	if perdeu:
		modulate = Color("ffada4")
		animacao = create_tween()
		animacao.tween_property(self, "modulate", Color.WHITE, 0.3)

func _draw() -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("fff6e4")
	fundo.border_color = Color("d9c6a5")
	fundo.set_border_width_all(1)
	fundo.set_corner_radius_all(9)
	draw_style_box(fundo, Rect2(Vector2.ZERO, size))
	var forma := PackedVector2Array([Vector2(0, 6), Vector2(3, 2), Vector2(8, 2), Vector2(12, 6), Vector2(16, 2), Vector2(21, 2), Vector2(24, 6), Vector2(24, 12), Vector2(12, 24), Vector2(0, 12)])
	for i in range(3):
		var pontos := PackedVector2Array()
		for ponto in forma:
			pontos.append(ponto + Vector2(10 + i * 30, 8))
		var cor := Color("d65054") if i < vidas else Color("ded7cb")
		draw_colored_polygon(pontos, cor)
		pontos.append(pontos[0])
		draw_polyline(pontos, Color("9f343e") if i < vidas else Color("b6ad9e"), 1.5, true)
		if i < vidas:
			draw_line(Vector2(14 + i * 30, 15), Vector2(17 + i * 30, 12), Color("ffb9b0"), 2, true)
	draw_string(ThemeDB.fallback_font, Vector2(105, 17), "VIDAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("7c6654"))
	draw_string(ThemeDB.fallback_font, Vector2(108, 32), "%d / 3" % vidas, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("44352e"))
