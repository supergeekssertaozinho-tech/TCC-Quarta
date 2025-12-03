extends CharacterBody2D

# ============================================================
#  CONFIGURAÇÕES
# ============================================================
@export var move_speed: float = 100.0
@export var gravity: float = 1000.0
@export var patrol_distance: float = 200.0
@export var jump_force: float = 450.0

# Ativação opcional de sistemas
@export var use_gravity: bool = true
@export var use_raycast: bool = true

# ============================================================
#  ESTADO
# ============================================================
enum State { PATROL, ATTACK, FLEE }
var state: State = State.PATROL

var moving_right: bool = true
var start_position: Vector2
var player_ref: Node = null

# ============================================================
#  REFERÊNCIAS
# ============================================================
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var floor_check: RayCast2D = $RayCast2D
@onready var front_check: RayCast2D = $FrontCheck

# ============================================================
#  READY
# ============================================================
func _ready() -> void:
	start_position = global_position
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

# ============================================================
#  LOOP FÍSICO
# ============================================================
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	match state:
		State.PATROL:
			_patrol()
		State.ATTACK:
			_attack()
		State.FLEE:
			_flee()

	move_and_slide()

# ============================================================
#  GRAVIDADE
# ============================================================
func _apply_gravity(delta: float) -> void:
	if use_gravity:
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		velocity.y = 0.0

# ============================================================
#  PATRULHA
# ============================================================
func _patrol() -> void:
	# Movimento básico
	if moving_right:
		velocity.x = move_speed
	else:
		velocity.x = -move_speed

	# Limites da área de patrulha
	var max_right: float = start_position.x + patrol_distance
	var max_left: float = start_position.x - patrol_distance

	if moving_right and global_position.x >= max_right:
		moving_right = false
	elif (not moving_right) and global_position.x <= max_left:
		moving_right = true

	# Atualiza direção visual
	animation.flip_h = not moving_right

	# Atualiza posição dos RayCasts (frente)
	front_check.target_position.x = 12 if moving_right else -12

	# --- RAYCAST DE CHÃO (CORRIGIDO: só verifica se está no chão) ---
	if use_raycast and is_on_floor():
		floor_check.enabled = true
		floor_check.target_position.x = 12 if moving_right else -12

		if not floor_check.is_colliding():
			moving_right = not moving_right

	# --- PULO AUTOMÁTICO EM DEGRAU ---
	# Só pula se há colisão na frente e estiver no chão
	if front_check.is_colliding() and is_on_floor():
		velocity.y = -jump_force

# ============================================================
#  ATAQUE
# ============================================================
func _attack() -> void:
	if player_ref == null:
		state = State.PATROL
		return

	# direction explicit typed
	var direction: float = 0.0
	if player_ref is Node:
		direction = sign(player_ref.global_position.x - global_position.x)

	velocity.x = direction * move_speed * 1.6
	animation.flip_h = direction < 0.0

# ============================================================
#  FUGA
# ============================================================
func _flee() -> void:
	if player_ref == null:
		state = State.PATROL
		return

	var direction: float = 0.0
	if player_ref is Node:
		direction = -sign(player_ref.global_position.x - global_position.x)

	velocity.x = direction * move_speed * 1.4
	animation.flip_h = direction < 0.0

# ============================================================
#  DETECÇÃO DO PLAYER
# ============================================================
func _on_detection_area_body_entered(body: Node) -> void:
	# garante que o body é um Node e está no grupo Player
	if not (body is Node) or not body.is_in_group("Player"):
		return

	player_ref = body

	# obter hunger de forma segura e tipada
	var hunger: float = 0.0
	if body.has_variable("hunger"):
		hunger = float(body.hunger)
	elif body.has_method("get_hunger"):
		var v = body.call("get_hunger")
		hunger = float(v)
	# else hunger fica 0.0

	if hunger >= 80.0:
		state = State.ATTACK
	else:
		state = State.FLEE

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		state = State.PATROL
