extends Control

# As mesmas texturas são usadas na mochila e na mesa.
const SPRITES := {
	"casmurro": preload("res://assets/itens/dom_casmurro.png"),
	"macunaima": preload("res://assets/itens/macunaima.png"),
	"cortico": preload("res://assets/itens/o_cortico.png"),
	"caderno": preload("res://assets/itens/caderno_resumos.png"),
	"estojo": preload("res://assets/itens/estojo_completo.png"),
	"luminaria": preload("res://assets/itens/luminaria.png")
}
const POSICOES := {
	"casmurro": Rect2(65, 121, 77, 77),
	"macunaima": Rect2(96, 136, 77, 77),
	"cortico": Rect2(127, 151, 77, 77),
	"caderno": Rect2(73, 226, 68, 68),
	"luminaria": Rect2(442, 105, 92, 100)
}

var adquiridos: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func atualizar(itens: Dictionary) -> void:
	if adquiridos == itens:
		return
	adquiridos = itens.duplicate()
	queue_redraw()

func _draw() -> void:
	for id in POSICOES:
		if adquiridos.has(id):
			draw_texture_rect(SPRITES[id], POSICOES[id], false)
	# O estojo é o próprio botão da loja; Main atualiza sua aparência.
