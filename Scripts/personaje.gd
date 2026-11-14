extends CharacterBody2D

signal vida_cambiada(vida_actual, vida_maxima)
signal jugador_murio

# Movimiento
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
@export var MAX_JUMPS: int = 3

# Vida
@export var VIDA_MAXIMA: int = 100
@export var TIEMPO_INVULNERABLE: float = 1.0

# Ataque
@export var DANO_ATAQUE: int = 10
@export var ALCANCE_X: float = 150.0      # Qué tan lejos pega hacia adelante
@export var ALCANCE_Y: float = 200.0      # Tolerancia vertical
@export var COOLDOWN_ATAQUE: float = 0.4
@export var DURACION_ANIM_ATAQUE: float = 0.3

# Caída al vacío
@export var KILL_Y: float = 1000.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_count: int = 0
var respawn_position: Vector2 = Vector2.ZERO
var vida_actual: int = 0
var invulnerable: bool = false
var puede_atacar: bool = true
var atacando: bool = false

@onready var ranji = $Ranji


func _ready() -> void:
	add_to_group("player")
	respawn_position = global_position
	vida_actual = VIDA_MAXIMA
	vida_cambiada.emit(vida_actual, VIDA_MAXIMA)


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

	# 3. Atacar
	if Input.is_action_just_pressed("atacar") and puede_atacar:
		atacar()

	# 4. Movimiento horizontal
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. Girar a Ranji
	if direction > 0:
		ranji.flip_h = true
	elif direction < 0:
		ranji.flip_h = false

	# 6. Movimiento y colisiones
	move_and_slide()

	# 7. Animaciones (no pisa la animación de ataque mientras ataca)
	if not atacando:
		if not is_on_floor():
			if velocity.y < 0:
				ranji.play("Jump")
			else:
				ranji.play("Fall")
		elif direction != 0:
			ranji.play("Left")
		else:
			ranji.play("Idle")

	# 8. Caída al vacío
	if global_position.y > KILL_Y:
		respawn()


# ---------- ATAQUE ----------

func atacar() -> void:
	puede_atacar = false
	atacando = true

	# Reproduce la animación solo si la tienes creada con el nombre "Attack"
	if ranji.sprite_frames and ranji.sprite_frames.has_animation("Attack"):
		ranji.play("Attack")

	golpear_enemigos()

	await get_tree().create_timer(DURACION_ANIM_ATAQUE).timeout
	atacando = false

	await get_tree().create_timer(max(COOLDOWN_ATAQUE - DURACION_ANIM_ATAQUE, 0.01)).timeout
	puede_atacar = true


func golpear_enemigos() -> void:
	var mira_derecha: bool = ranji.flip_h          # Tu convención: flip_h = true mira a la derecha
	var dir: float = 1.0 if mira_derecha else -1.0

	for enemigo in get_tree().get_nodes_in_group("enemigo"):
		var dx = enemigo.global_position.x - global_position.x
		var dy = abs(enemigo.global_position.y - global_position.y)

		# Solo golpea a los que están al frente (con un margen pequeño hacia atrás)
		var al_frente = dx * dir >= -20.0
		var en_alcance = abs(dx) <= ALCANCE_X and dy <= ALCANCE_Y

		if al_frente and en_alcance and enemigo.has_method("take_damage"):
			enemigo.take_damage(DANO_ATAQUE)


# ---------- VIDA ----------

func take_damage(cantidad: int) -> void:
	if invulnerable:
		return

	vida_actual = max(vida_actual - cantidad, 0)
	vida_cambiada.emit(vida_actual, VIDA_MAXIMA)

	if vida_actual <= 0:
		morir()
	else:
		activar_invulnerabilidad()


func heal(cantidad: int) -> void:
	vida_actual = min(vida_actual + cantidad, VIDA_MAXIMA)
	vida_cambiada.emit(vida_actual, VIDA_MAXIMA)


func activar_invulnerabilidad() -> void:
	invulnerable = true

	var tween = create_tween().set_loops(int(TIEMPO_INVULNERABLE / 0.2))
	tween.tween_property(ranji, "modulate:a", 0.3, 0.1)
	tween.tween_property(ranji, "modulate:a", 1.0, 0.1)

	await get_tree().create_timer(TIEMPO_INVULNERABLE).timeout
	ranji.modulate.a = 1.0
	invulnerable = false


func morir() -> void:
	jugador_murio.emit()
	respawn()


# ---------- REAPARICIÓN ----------

func respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	jump_count = 0
	vida_actual = VIDA_MAXIMA
	invulnerable = false
	atacando = false
	puede_atacar = true
	ranji.modulate.a = 1.0
	vida_cambiada.emit(vida_actual, VIDA_MAXIMA)
