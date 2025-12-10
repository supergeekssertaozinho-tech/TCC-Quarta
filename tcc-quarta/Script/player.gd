extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0

@export var hunger_system: Node = null
@export var gravity_enabled: bool = true

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var collect_sound: AudioStreamPlayer2D =  $CollectSound  # 🔊 SOM DE COLETA

var is_dead := false


func _ready():
	if hunger_system and hunger_system.has_signal("hunger_zero"):
		hunger_system.hunger_zero.connect(_on_hunger_zero)
	else:
		push_warning("hunger_system não está configurado corretamente no Player!")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# ==========================
	# GRAVIDADE
	# ==========================
	if gravity_enabled and not is_on_floor():
		velocity += get_gravity() * delta

	# ==========================
	# PULO
	# ==========================
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

		if not jump_sound.playing:
			jump_sound.play()

	# ==========================
	# MOVIMENTO LATERAL
	# ==========================
	var dir := Input.get_axis("ui_left", "ui_right")

	if dir != 0:
		velocity.x = dir * SPEED

		# SOM DE PASSO
		if is_on_floor() and not footstep_player.playing:
			footstep_player.play()

		animation.flip_h = dir < 0

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		if footstep_player.playing:
			footstep_player.stop()

	# se estiver no ar, não tocar passos
	if not is_on_floor() and footstep_player.playing:
		footstep_player.stop()

	# ==========================
	# MOVER
	# ==========================
	move_and_slide()

	# ==========================
	# DETECTAR KILLZONE
	# ==========================
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("KillZone"):
			_on_death()
			return


# ============================================================
# SOM DA COLETA (CHAMADO PELO DONUT)
# ============================================================
func play_collect_sound():
	if not collect_sound.playing:
		collect_sound.play()


# ============================================================
# MORTE DO PLAYER
# ============================================================
func _on_death():
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	if footstep_player.playing:
		footstep_player.stop()

	death_sound.play()

	await death_sound.finished

	_restart_scene()


# ============================================================
# FOME ZERO
# ============================================================
func _on_hunger_zero():
	_on_death()


# ============================================================
# REINICIA A CENA
# ============================================================
func _restart_scene():
	get_tree().call_deferred(
		"change_scene_to_file",
		get_tree().current_scene.scene_file_path
	)
