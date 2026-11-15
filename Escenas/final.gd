extends CharacterBody2D

# Movimiento
@export var VELOCIDAD: float = 120.0
@export var INVERTIR_SPRITE: bool = false    # Márcalo si el boss mira al lado contrario

# Vida
@export var VIDA_MAXIMA: int = 100           # Con 10 de daño por golpe, muere a los 10 golpes
@export var TIEMPO_HIT: float = 0.3          # Segundos que se queda aturdido al recibir un golpe

# Ataque
@export var DANO: int = 25
@export var RANGO_X: float = 150.0           # Alcance horizontal del ataque
@export var RANGO_Y: float = 200.0           # Alcance vertical
@export var RETRASO_GOLPE: float = 0.4       # Segundos desde que empieza Attack hasta que pega
@export var DURACION_ATAQUE: float = 0.8     # Duración total del ataque
@export var COOLDOWN_ATAQUE: float = 1.2     # Espera entre ataques

var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var vida_actual: int = 0
var atacando: bool = false
var puede_atacar: bool = true
var aturdido: bool = false
var muerto: bool = false
var jugador: Node2D = null
var sprite: AnimatedSprite2D = null


func _ready() -> void:
	add_to_group("enemigo")                  # Así el jugador puede golpearlo
	vida_actual = VIDA_MAXIMA

	for hijo in get_children():
		if hijo is AnimatedSprite2D:
			sprite = hijo
			break

	if sprite == null:
		push_error("El boss necesita un nodo AnimatedSprite2D como hijo")
		set_physics_process(false)
		return

	reproducir("Idle")


func _physics_process(delta: float) -> void:
	if muerto:
		return

	if not is_on_floor():
		velocity.y += gravedad * delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")

	if jugador == null or atacando or aturdido:
		velocity.x = 0
	elif jugador_en_rango():
		velocity.x = 0
		mirar_al_jugador()
		if puede_atacar:
			atacar()
		else:
			reproducir("Idle")
	else:
		# Camina hacia el jugador
		var dir = sign(jugador.global_position.x - global_position.x)
		velocity.x = dir * VELOCIDAD
		mirar_al_jugador()
		reproducir("Walk")

	move_and_slide()


# ---------- UTILIDADES ----------

func reproducir(nombre: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(nombre):
		if sprite.animation != nombre or not sprite.is_playing():
			sprite.play(nombre)


func mirar_al_jugador() -> void:
	if jugador == null:
		return
	var a_la_derecha = jugador.global_position.x > global_position.x
	sprite.flip_h = a_la_derecha != INVERTIR_SPRITE


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
	velocity.x = 0
	sprite.play("Attack")

	await get_tree().create_timer(RETRASO_GOLPE).timeout
	if muerto:
		return

	if not aturdido and jugador_en_rango() and jugador.has_method("take_damage"):
		jugador.take_damage(DANO)

	await get_tree().create_timer(max(DURACION_ATAQUE - RETRASO_GOLPE, 0.01)).timeout
	if muerto:
		return

	atacando = false

	await get_tree().create_timer(COOLDOWN_ATAQUE).timeout
	puede_atacar = true


# ---------- VIDA Y MUERTE ----------

func take_damage(cantidad: int) -> void:
	if muerto:
		return

	vida_actual -= cantidad
	print("Boss: vida = ", vida_actual)

	if vida_actual <= 0:
		morir()
		return

	# Reacción al golpe: se interrumpe el ataque y se aturde un momento
	aturdido = true
	atacando = false
	sprite.play("Hit")

	await get_tree().create_timer(TIEMPO_HIT).timeout
	if muerto:
		return
	aturdido = false
	puede_atacar = true


func morir() -> void:
	muerto = true
	atacando = false
	velocity = Vector2.ZERO
	remove_from_group("enemigo")

	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
