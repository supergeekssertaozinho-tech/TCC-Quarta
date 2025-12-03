extends Control

signal hunger_zero

@onready var bar = $ColorRect
@export var decrease_rate: float = 50.0

var original_width: float

func _ready() -> void:
	original_width = bar.size.x

func _process(delta: float) -> void:
	# Diminui a fome
	bar.size.x -= decrease_rate * delta

	# DEBUG → mostrar no console sempre
	print("HUNGER VALUE: ", bar.size.x)

	# Impedir valor negativo
	if bar.size.x <= 0:
		bar.size.x = 0
		emit_signal("hunger_zero")  # sinal de fome zerada

func get_hunger_value() -> float:
	return bar.size.x
