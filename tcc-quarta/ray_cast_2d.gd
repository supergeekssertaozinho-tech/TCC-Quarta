extends CharacterBody2D

# --- Configurações de movimento ---
@export var move_speed: float = 100.0
@export var gravity: float = 1000.0
@export var patrol_distance: float = 200.0

# --- Estado ---
enum State { PATROL, ATTACK, FLEE }
var state: State = State.PATROL
var moving_right: bool = true
var start_position: Vector2
var player_ref: Node = null

# --- Referências a nós filhos ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	start_position = global_position

	# Conecta sinais de detecção
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Executa lógica conforme o estado
	match state:
		State.PATROL:
			_patrol()
		State.ATTACK:
			_attack()
		State.FLEE:
			_flee()

	move_and_slide()

# --- Movimentação de patrulha ---
func _patrol() -> void:
	velocity.x = move_speed if moving_right else -move_speed

	# Limites da patrulha
	if moving_right and global_position.x > start_position.x + patrol_distance:
		moving_right = false
	elif not moving_right and global_position.x < start_position.x - patrol_distance:
		moving_right = true

	sprite.flip_h = not moving_right

# --- Comportamento de ataque ---
func _attack() -> void:
	if not player_ref:
		state = State.PATROL
		return

	var direction := sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.6
	sprite.flip_h = direction < 0

# --- Comportamento de fuga ---
func _flee() -> void:
	if not player_ref:
		state = State.PATROL
		return

	var direction := -sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.4
	sprite.flip_h = direction < 0

# --- Detecção do Player ---
func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_ref = body

		# Checa o valor de fome do player (de 0 a 100)
		var hunger := body.hunger if body.has_variable("hunger") else 0

		if hunger >= 80:
			state = State.ATTACK
		else:
			state = State.FLEE

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		state = State.PATROL
