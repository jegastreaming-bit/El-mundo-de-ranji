extends CharacterBody2D

# Movimiento
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
@export var MAX_JUMPS: int = 3

# Reaparición (NUEVO)
@export var KILL_Y: float = 1000.0  # Altura del vacío, ajústala a tu nivel

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_count: int = 0
var respawn_position: Vector2 = Vector2.ZERO  # NUEVO

# Referencia al personaje
@onready var ranji = $Ranji


# NUEVO: guarda la posición inicial al empezar el juego
func _ready() -> void:
	respawn_position = global_position


func _physics_process(delta: float) -> void:

	# 1. Gravedad y saltos
	if is_on_floor():
		jump_count = 0
	else:
		velocity.y += gravity * delta

	# 2. Saltar
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_count += 1

	# 3. Movimiento horizontal
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
		print("Velocidad actual: ", SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4. Girar a Ranji
	if direction > 0:
		ranji.flip_h = true
	elif direction < 0:
		ranji.flip_h = false

	# 5. Movimiento y colisiones
	move_and_slide()

	# 6. Animaciones
	if not is_on_floor():
		if velocity.y < 0:
			ranji.play("Jump")
		else:
			ranji.play("Fall")
	elif direction != 0:
		ranji.play("Left")
	else:
		ranji.play("Idle")

	# 7. Caída al vacío (NUEVO)
	if global_position.y > KILL_Y:
		respawn()


# NUEVO: devuelve al personaje al inicio
func respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	jump_count = 0
