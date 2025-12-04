extends Area2D

@export var hunger_amount: float = 20.0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		if body.hunger_system: 
			body.hunger_system.add_hunger(hunger_amount) 
		
		queue_free()
