extends CharacterBody2D

const EnemyFWalk = 300
const Gravedad = 70

@export var DANO: int = 100               # 100 = te mata de un golpe, 10 = te quita poca vida
@export var RETRASO_GOLPE: float = 0.3    # Segundos desde que empieza Attack hasta que pega
@export var COOLDOWN_ATAQUE: float = 1.0  # Espera entre ataques

var atacando: bool = false
var puede_atacar: bool = true
var jugador_en_rango: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_ataque: Area2D = $ZonaAtaque


func _ready():
	velocity.x = -EnemyFWalk
	sprite.play("Walk")

	zona_ataque.body_entered.connect(_on_zona_ataque_body_entered)
	zona_ataque.body_exited.connect(_on_zona_ataque_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	velocity.y += Gravedad

	# Si el jugador está en rango, ataca
	if jugador_en_rango and puede_atacar and not atacando:
		iniciar_ataque()

	if atacando:
		velocity.x = 0
	else:
		# Tu patrullaje original
		if is_on_wall():
			if !sprite.flip_h:
				velocity.x = EnemyFWalk
			else:
				velocity.x = -EnemyFWalk

			if velocity.x < 0:
				sprite.flip_h = false
			elif velocity.x > 0:
				sprite.flip_h = true

	move_and_slide()


func iniciar_ataque() -> void:
	print("Enemigo: empieza ataque")
	atacando = true
	puede_atacar = false

	# Mirar hacia el jugador
	sprite.flip_h = jugador_en_rango.global_position.x > global_position.x
	sprite.play("Attack")

	# Esperar un momento y pegar el golpe
	await get_tree().create_timer(RETRASO_GOLPE).timeout

	if jugador_en_rango and jugador_en_rango.has_method("take_damage"):
		print("Enemigo: GOLPE al jugador")
		jugador_en_rango.take_damage(DANO)
	else:
		print("Enemigo: el jugador salió del rango, golpe fallado")


func _on_animation_finished() -> void:
	if sprite.animation == "Attack":
		atacando = false
		sprite.play("Walk")
		velocity.x = EnemyFWalk if sprite.flip_h else -EnemyFWalk

		await get_tree().create_timer(COOLDOWN_ATAQUE).timeout
		puede_atacar = true


func _on_zona_ataque_body_entered(body: Node2D) -> void:
	print("ZonaAtaque detectó: ", body.name)
	if body.is_in_group("player"):
		print("Es el jugador")
		jugador_en_rango = body


func _on_zona_ataque_body_exited(body: Node2D) -> void:
	if body == jugador_en_rango:
		jugador_en_rango = null
