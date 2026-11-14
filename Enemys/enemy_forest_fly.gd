extends CharacterBody2D

enum Estado { ESPERANDO, CAYENDO, IMPACTO, SUBIENDO }

@export var velocidad_caida := 700.0
@export var aceleracion_caida := 2500.0
@export var velocidad_subida := 90.0
@export var tiempo_en_suelo := 0.7

var estado: Estado = Estado.ESPERANDO
var posicion_inicial: Vector2

func _ready():
	posicion_inicial = global_position
	$Deteccion.body_entered.connect(_on_deteccion_body_entered)
	$Danio.body_entered.connect(_on_danio_body_entered)

func _physics_process(delta):
	match estado:
		Estado.ESPERANDO:
			velocity = Vector2.ZERO

		Estado.CAYENDO:
			velocity.y = move_toward(velocity.y, velocidad_caida, aceleracion_caida * delta)
			move_and_slide()
			if is_on_floor():
				_impacto()

		Estado.IMPACTO:
			velocity = Vector2.ZERO

		Estado.SUBIENDO:
			velocity = Vector2(0, -velocidad_subida)
			move_and_slide()
			if global_position.y <= posicion_inicial.y:
				global_position = posicion_inicial
				estado = Estado.ESPERANDO

func _impacto():
	estado = Estado.IMPACTO
	velocity = Vector2.ZERO
	# Aquí puedes poner animación, partículas o sacudida de cámara
	await get_tree().create_timer(tiempo_en_suelo).timeout
	estado = Estado.SUBIENDO

func _on_deteccion_body_entered(body):
	if body.is_in_group("jugador") and estado == Estado.ESPERANDO:
		estado = Estado.CAYENDO

func _on_danio_body_entered(body):
	if body.is_in_group("jugador") and body.has_method("recibir_danio"):
		body.recibir_danio()
