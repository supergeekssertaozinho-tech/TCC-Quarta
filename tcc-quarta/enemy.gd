extends CharacterBody2D

# --- Configurações ---
@export var move_speed: float = 100.0
@export var gravity: float = 1000.0
@export var patrol_distance: float = 200.0

# Enable/Disable
@export var use_gravity: bool = true
@export var use_raycast: bool = true

# --- Estado ---
enum State { PATROL, ATTACK, FLEE }
var state: State = State.PATROL
var moving_right: bool = true
var start_position: Vector2
var player_ref: Node = null

# --- Referências que EXISTEM ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $Area2D
@onready var floor_check: RayCast2D = $RayCast2D

func _ready() -> void:
	start_position = global_position

	# Conexões corretas
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	# Gravidade opcional
	if use_gravity:
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Estados
	match state:
		State.PATROL:
			_patrol()
		State.ATTACK:
			_attack()
		State.FLEE:
			_flee()

	move_and_slide()

# --- Patrulha ---
func _patrol() -> void:
	velocity.x = move_speed if moving_right else -move_speed

	# Limites da patrulha
	var max_right = start_position.x + patrol_distance
	var max_left = start_position.x - patrol_distance

	if moving_right and global_position.x >= max_right:
		moving_right = false
	elif not moving_right and global_position.x <= max_left:
		moving_right = true

	# RayCast opcional (evitar cair)
	if use_raycast:
		floor_check.enabled = true
		floor_check.target_position.x = 12 if moving_right else -12

		if not floor_check.is_colliding():
			moving_right = not moving_right

	# Flip horizontal
	sprite.flip_h = not moving_right

# --- Ataque ---
func _attack() -> void:
	if not player_ref:
		state = State.PATROL
		return

	var direction = sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.6
	sprite.flip_h = direction < 0

# --- Fuga ---
func _flee() -> void:
	if not player_ref:
		state = State.PATROL
		return

	var direction = -sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.4
	sprite.flip_h = direction < 0

# --- Detecção ---
func _on_detection_area_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	player_ref = body

	var hunger: float = body.hunger if body.has_variable("hunger") else 0

	if hunger >= 80:
		state = State.ATTACK
	else:
		state = State.FLEE

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		state = State.PATROL
