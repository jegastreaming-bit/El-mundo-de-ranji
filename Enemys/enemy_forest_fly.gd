extends CharacterBody2D

# Movimiento
@export var VELOCIDAD_PERSECUCION: float = 120.0
@export var VELOCIDAD_VOLVER: float = 100.0
@export var AMPLITUD_FLOTAR: float = 10.0     # Cuánto sube y baja flotando en reposo
@export var DETECCION: float = 500.0          # A qué distancia te detecta

# Vida
@export var VIDA_MAXIMA: int = 30             # Con 10 de daño por golpe, muere a los 3 golpes

# Ataque
@export var DANO: int = 20
@export var RANGO_X: float = 100.0            # Alcance horizontal del ataque
@export var RANGO_Y: float = 120.0            # Alcance vertical del ataque
@export var RETRASO_GOLPE: float = 0.3        # Segundos desde que empieza Attack hasta que pega
@export var DURACION_ATAQUE: float = 0.6      # Duración total del ataque
@export var COOLDOWN_ATAQUE: float = 1.0      # Espera entre ataques

var posicion_inicial: Vector2
var tiempo: float = 0.0
var atacando: bool = false
var puede_atacar: bool = true
var muerto: bool = false
var vida_actual: int = 0
var jugador: Node2D = null
var sprite: AnimatedSprite2D = null
var tween_golpe: Tween = null


func _ready() -> void:
	add_to_group("enemigo")                   # Así el jugador puede golpearla
	vida_actual = VIDA_MAXIMA
	posicion_inicial = global_position

	# Busca el AnimatedSprite2D sin importar cómo se llame
	for hijo in get_children():
		if hijo is AnimatedSprite2D:
			sprite = hijo
			break

	if sprite == null:
		push_error("La medusa necesita un nodo AnimatedSprite2D como hijo")
		set_physics_process(false)
		return

	sprite.play("Idle")


func _physics_process(delta: float) -> void:
	if muerto:
		return

	tiempo += delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")

	if atacando:
		velocity = Vector2.ZERO
	elif jugador_en_rango():
		velocity = Vector2.ZERO
		if puede_atacar:
			atacar()
		else:
			sprite.play("Idle")
	elif jugador_detectado():
		# Va hacia el jugador
		var dir = (jugador.global_position - global_position).normalized()
		velocity = dir * VELOCIDAD_PERSECUCION
		sprite.play("Idle")
	else:
		# Vuelve a su lugar y flota suavemente
		var objetivo = posicion_inicial + Vector2(0, sin(tiempo * 2.0) * AMPLITUD_FLOTAR)
		velocity = ((objetivo - global_position) * 4.0).limit_length(VELOCIDAD_VOLVER)
		sprite.play("Idle")

	move_and_slide()


# ---------- DETECCIÓN ----------

func jugador_detectado() -> bool:
	if jugador == null:
		return false
	return global_position.distance_to(jugador.global_position) <= DETECCION


func jugador_en_rango() -> bool:
	if jugador == null:
		return false
	var dx = abs(jugador.global_position.x - global_position.x)
	var dy = abs(jugador.global_position.y - global_position.y)
	return dx <= RANGO_X and dy <= RANGO_Y


# ---------- ATAQUE ----------

func atacar() -> void:
	atacando = true
	puede_atacar = false
	velocity = Vector2.ZERO
	sprite.play("Attack")
	print("Medusa: ataca")

	await get_tree().create_timer(RETRASO_GOLPE).timeout
	if muerto:
		return

	if jugador_en_rango() and jugador.has_method("take_damage"):
		print("Medusa: golpe conectado")
		jugador.take_damage(DANO)
	else:
		print("Medusa: golpe fallado")

	await get_tree().create_timer(max(DURACION_ATAQUE - RETRASO_GOLPE, 0.01)).timeout
	if muerto:
		return

	atacando = false
	sprite.play("Idle")

	await get_tree().create_timer(COOLDOWN_ATAQUE).timeout
	puede_atacar = true


# ---------- VIDA Y MUERTE ----------

func take_damage(cantidad: int) -> void:
	if muerto:
		return

	vida_actual -= cantidad
	print("Medusa: vida = ", vida_actual)

	# Destello rojo al recibir el golpe
	sprite.modulate = Color(1, 0.3, 0.3)
	tween_golpe = create_tween()
	tween_golpe.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

	if vida_actual <= 0:
		morir()


func morir() -> void:
	muerto = true
	atacando = false
	velocity = Vector2.ZERO
	remove_from_group("enemigo")

	if tween_golpe:
		tween_golpe.kill()

	# Desactiva todas las colisiones para que ya no estorbe
	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	# Se desvanece y se borra
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
