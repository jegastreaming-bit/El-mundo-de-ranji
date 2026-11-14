extends CharacterBody2D

const EnemyFWalk = 300
const Gravedad = 70

# Ataque (NUEVO)
@export var DANO: int = 10                 # Vida que le quita al jugador
@export var FRAME_DANO: int = 2            # Frame de la animación Attack donde pega el golpe
@export var COOLDOWN_ATAQUE: float = 1.0   # Segundos de espera entre ataques

var atacando: bool = false                 # NUEVO
var puede_atacar: bool = true              # NUEVO
var jugador_en_rango: Node2D = null        # NUEVO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_ataque: Area2D = $ZonaAtaque   # NUEVO


func _ready():
	velocity.x = -EnemyFWalk
	sprite.play("Walk")

	# NUEVO: conexiones por código
	zona_ataque.body_entered.connect(_on_zona_ataque_body_entered)
	zona_ataque.body_exited.connect(_on_zona_ataque_body_exited)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	velocity.y += Gravedad

	# NUEVO: si el jugador está en rango y puede atacar, ataca
	if jugador_en_rango and puede_atacar and not atacando:
		iniciar_ataque()

	if atacando:
		velocity.x = 0   # Se queda quieto mientras ataca
	else:
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


# ---------- ATAQUE (NUEVO) ----------

func iniciar_ataque() -> void:
	atacando = true
	puede_atacar = false
	velocity.x = 0

	# Voltea al enemigo hacia el jugador (flip_h = true significa mirar a la derecha)
	sprite.flip_h = jugador_en_rango.global_position.x > global_position.x

	sprite.play("Attack")


# El golpe cae en un frame específico de la animación
func _on_frame_changed() -> void:
	if sprite.animation == "Attack" and sprite.frame == FRAME_DANO:
		if jugador_en_rango and jugador_en_rango.has_method("take_damage"):
			jugador_en_rango.take_damage(DANO)


func _on_animation_finished() -> void:
	if sprite.animation == "Attack":
		atacando = false
		sprite.play("Walk")

		# Retoma la dirección según hacia dónde mira
		velocity.x = EnemyFWalk if sprite.flip_h else -EnemyFWalk

		# Espera antes de poder atacar otra vez
		await get_tree().create_timer(COOLDOWN_ATAQUE).timeout
		puede_atacar = true


func _on_zona_ataque_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_en_rango = body


func _on_zona_ataque_body_exited(body: Node2D) -> void:
	if body == jugador_en_rango:
		jugador_en_rango = null
