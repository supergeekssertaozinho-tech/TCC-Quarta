extends Area2D

@export var hunger_gain: float = 10.0  # quanto recupera

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.hunger_system:
		var hs = body.hunger_system

		# 1. Se existir um método add_hunger(), use-o (versão ideal)
		if hs.has_method("add_hunger"):
			hs.add_hunger(hunger_gain)

		# 2. Caso não tenha método, mas tenha variável hunger...
		elif "hunger" in hs and "max_hunger" in hs:
			hs.hunger = clamp(hs.hunger + hunger_gain, 0.0, hs.max_hunger)

		# 3. Remove o donut
		queue_free()
