extends CharacterBody2D

# Movimiento
@export var VELOCIDAD: float = 150.0
@export var DISTANCIA_PATRULLA: float = 200.0

# Vida
@export var VIDA_MAXIMA: int = 30             # Con DANO_ATAQUE = 10 del jugador, muere a los 3 golpes

# Ataque
@export var DANO: int = 100
@export var RANGO_X: float = 120.0
@export var RANGO_Y: float = 200.0
@export var RETRASO_GOLPE: float = 0.3
@export var DURACION_ATAQUE: float = 0.6
@export var COOLDOWN_ATAQUE: float = 1.0

var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direccion: int = -1
var inicio_x: float = 0.0
var atacando: bool = false
var puede_atacar: bool = true
var muerto: bool = false
var vida_actual: int = 0
var jugador: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemigo")          # El jugador encuentra a los enemigos por este grupo
	vida_actual = VIDA_MAXIMA
	inicio_x = global_position.x
	sprite.play("Walk")


func _physics_process(delta: float) -> void:
	if muerto:
		return

	if not is_on_floor():
		velocity.y += gravedad * delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")

	if atacando:
		velocity.x = 0
	elif jugador_en_rango():
		if puede_atacar:
			atacar()
		else:
			velocity.x = 0
			mirar_al_jugador()
			sprite.play("Idle")
	else:
		patrullar()

	move_and_slide()


# ---------- PATRULLA ----------

func patrullar() -> void:
	if global_position.x <= inicio_x - DISTANCIA_PATRULLA:
		direccion = 1
	elif global_position.x >= inicio_x + DISTANCIA_PATRULLA:
		direccion = -1

	velocity.x = direccion * VELOCIDAD
	sprite.flip_h = direccion > 0
	sprite.play("Walk")


# ---------- ATAQUE ----------

func atacar() -> void:
	atacando = true
	puede_atacar = false
	velocity.x = 0
	mirar_al_jugador()
	sprite.play("Attack")

	await get_tree().create_timer(RETRASO_GOLPE).timeout

	# Si lo mataron durante el ataque, no pega
	if not muerto and jugador_en_rango() and jugador.has_method("take_damage"):
		jugador.take_damage(DANO)

	await get_tree().create_timer(max(DURACION_ATAQUE - RETRASO_GOLPE, 0.01)).timeout
	atacando = false

	await get_tree().create_timer(COOLDOWN_ATAQUE).timeout
	puede_atacar = true


func jugador_en_rango() -> bool:
	if jugador == null:
		return false
	var dx = abs(jugador.global_position.x - global_position.x)
	var dy = abs(jugador.global_position.y - global_position.y)
	return dx <= RANGO_X and dy <= RANGO_Y


func mirar_al_jugador() -> void:
	if jugador:
		sprite.flip_h = jugador.global_position.x > global_position.x


# ---------- VIDA Y MUERTE ----------

func take_damage(cantidad: int) -> void:
	if muerto:
		return

	vida_actual -= cantidad
	print("Enemigo: vida = ", vida_actual)

	# Destello rojo al recibir el golpe
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

	if vida_actual <= 0:
		morir()


func morir() -> void:
	muerto = true
	atacando = false
	velocity = Vector2.ZERO
	remove_from_group("enemigo")

	# Desactiva la colisión para que ya no estorbe
	$CollisionShape2D.set_deferred("disabled", true)

	# Se desvanece
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	# Espera a que terminen los temporizadores pendientes antes de borrarse
	await get_tree().create_timer(2.0).timeout
	queue_free()
