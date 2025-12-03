extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0

@export var hunger_system: Node = null
@export var gravity_enabled: bool = true

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if hunger_system:
		hunger_system.hunger_zero.connect(_on_hunger_zero)
	else:
		push_warning("hunger_system não está configurado no Player!")

func _physics_process(delta: float) -> void:
	# GRAVIDADE
	if gravity_enabled and not is_on_floor():
		velocity += get_gravity() * delta

	# PULO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# MOVIMENTO
	var dir := Input.get_axis("ui_left", "ui_right")

	if dir != 0:
		velocity.x = dir * SPEED
		if dir > 0:
			animation.flip_h = false
		else:
			animation.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# ============================================================
#  FOME ZERO → RESET IMEDIATO
# ============================================================
func _on_hunger_zero():
	_restart_scene()

# ============================================================
#  REINICIA A CENA TODA
# ============================================================
func _restart_scene():
	get_tree().call_deferred("change_scene_to_file", get_tree().current_scene.scene_file_path)
