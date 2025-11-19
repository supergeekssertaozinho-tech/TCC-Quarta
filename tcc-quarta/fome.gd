extends Control

@onready var bar = $ColorRect          # Caminho para o ColorRect
@export var decrease_rate: float = 50.0  # Pixels por segundo

var original_width: float

func _ready() -> void:
	original_width = bar.size.x        # Salva o tamanho inicial

func _process(delta: float) -> void:
	# Diminui a largura com o tempo
	bar.size.x -= decrease_rate * delta

	# Garante que não fique negativa
	if bar.size.x < 0:
		bar.size.x = 0
