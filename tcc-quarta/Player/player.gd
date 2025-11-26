extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var start_position: Vector2
var fall_timer: float = 0.0
var is_falling := false

var hunger_timer: float = 0.0
var is_starving := false

# Referência para o nó de Fome (arraste no editor)
@export var hunger_system: Node = null

@export var gravity_enabled: bool = true


func _ready():
	start_position = global_position

	# Conecta sinal da fome
	if hunger_system:
		hunger_system.hunger_zero.connect(_on_hunger_zero)
	else:
		push_warning("hunger_system não está configurado no Player!")


func _physics_process(delta: float) -> void:
	# -------------------------------
	# GRAVIDADE
	# -------------------------------
	if gravity_enabled and not is_on_floor():
		velocity += get_gravity() * delta

	# -------------------------------
	# PULO
	# -------------------------------
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# -------------------------------
	# MOVIMENTO
	# -------------------------------
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# -------------------------------
	# DETECTAR QUEDA
	# -------------------------------
	if global_position.y > 1000 and !is_falling:
		is_falling = true
		fall_timer = 0.0

	if is_falling:
		fall_timer += delta
		if fall_timer >= 5.0:
			reset_player()

	# -------------------------------
	# CONTAGEM DE MORTE POR FOME
	# -------------------------------
	if is_starving:
		hunger_timer += delta
		if hunger_timer >= 5.0:
			reset_player()


# ============================================================
#  Chamado quando o script da Fome emitir "hunger_zero"
# ============================================================
func _on_hunger_zero():
	if !is_starving:
		is_starving = true
		hunger_timer = 0.0



# ============================================================
#  RESETA PLAYER
# ============================================================
func reset_player():
	global_position = start_position
	velocity = Vector2.ZERO
	is_falling = false
	is_starving = false
	hunger_timer = 0.0
