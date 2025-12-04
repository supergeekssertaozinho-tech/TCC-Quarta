extends CharacterBody2D

# ================================
# CONFIGURAÇÕES
# ================================
@export var move_speed: float = 100.0
@export var gravity: float = 1000.0
@export var patrol_distance: float = 200.0
@export var jump_force: float = 450.0
@export var use_gravity: bool = true
@export var use_raycast: bool = true

# Estados
enum State { PATROL, ATTACK, FLEE }
var state: State = State.PATROL

# Movimento
var moving_right: bool = true
var start_position: Vector2 = Vector2.ZERO

# Referência do Player (inicializada nula)
var player_ref: CharacterBody2D = null

# ================================
# NODES
# ================================
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var floor_check: RayCast2D = $RayCast2D
@onready var front_check: RayCast2D = $FrontCheck

# ================================
# READY
# ================================
func _ready() -> void:
	start_position = global_position

	# Conecta sinais de detecção (usa detection_area que já existe)
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Área para ser comido (assumindo que é Area2D filho)
	if $Area2D:
		$Area2D.body_entered.connect(_on_body_entered)

# ================================
# PHYSICS PROCESS
# ================================
func _physics_process(delta: float) -> void:
	if use_gravity and not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.PATROL:
			_patrol()
		State.ATTACK:
			_attack()
		State.FLEE:
			_flee()

	move_and_slide()

# ================================
# PATRULHA
# ================================
func _patrol() -> void:
	# movimento básico com tipagem explícita
	if moving_right:
		velocity.x = move_speed
	else:
		velocity.x = -move_speed

	var max_r: float = start_position.x + patrol_distance
	var max_l: float = start_position.x - patrol_distance

	if moving_right and global_position.x >= max_r:
		moving_right = false
	elif (not moving_right) and global_position.x <= max_l:
		moving_right = true

	# Atualiza Raycast frontal (se existir)
	if front_check:
		front_check.target_position.x = 12 if moving_right else -12

	# Raycast de chão (só se estiver no chão para evitar "flip" no ar)
	if use_raycast and is_on_floor() and floor_check:
		floor_check.enabled = true
		floor_check.target_position.x = 12 if moving_right else -12

		if not floor_check.is_colliding():
			moving_right = not moving_right

	# Pulo automático para obstáculos (não executa se estiver fugindo)
	if front_check and front_check.is_colliding() and is_on_floor():
		velocity.y = -jump_force

	if animation:
		animation.flip_h = not moving_right

# ================================
# ATAQUE
# ================================
func _attack() -> void:
	if player_ref == null:
		state = State.PATROL
		return

	var direction: float = 0.0
	# garante que player_ref é um Node válido
	if player_ref is Node:
		direction = sign(player_ref.global_position.x - global_position.x)

	velocity.x = direction * move_speed * 1.6
	if animation:
		animation.flip_h = direction < 0.0

# ================================
# FUGA
# ================================
func _flee() -> void:
	if player_ref == null:
		state = State.PATROL
		return

	var direction: float = 0.0
	if player_ref is Node:
		direction = -sign(player_ref.global_position.x - global_position.x)

	velocity.x = direction * move_speed * 1.4
	if animation:
		animation.flip_h = direction < 0.0

# ================================
# DETECÇÃO DO PLAYER
# ================================
func _on_detection_area_body_entered(body: Node) -> void:
	# verifica grupo global 'Player'
	if not body.is_in_group("Player"):
		return

	player_ref = body as CharacterBody2D

	# Pega fome real com tipagem explícita
	var hunger: float = 100.0
	if player_ref and player_ref.hunger_system:
		hunger = float(player_ref.hunger_system.current_hunger)

	# Decide comportamento
	if hunger >= 60.0:
		state = State.ATTACK
	else:
		state = State.FLEE

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		state = State.PATROL

# ================================
# PLAYER PODE COMER O INIMIGO
# ================================
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	var player: CharacterBody2D = body as CharacterBody2D

	# Só pode ser comido com fome < 60%
	if player and player.hunger_system:
		var player_hunger: float = float(player.hunger_system.current_hunger)
		if player_hunger < 60.0:
			# chama o método público do hunger_system (se existir)
			if player.hunger_system.has_method("add_hunger"):
				player.hunger_system.add_hunger(25.0)
			else:
				# fallback: tenta ajustar variável diretamente
				if "hunger" in player.hunger_system and "max_hunger" in player.hunger_system:
					player.hunger_system.hunger = clamp(player.hunger_system.hunger + 25.0, 0.0, float(player.hunger_system.max_hunger))
			queue_free()
