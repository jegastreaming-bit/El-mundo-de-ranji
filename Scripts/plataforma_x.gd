extends AnimatableBody2D

@export var velocidad: float = 2.0    # Qué tan rápido completa el ciclo
@export var distancia: float = 150.0  # Cuántos píxeles se mueve a los lados desde el centro

var posicion_inicial: float
var tiempo: float = 0.0

func _ready() -> void:
	# Guardamos la posición X inicial de la plataforma
	posicion_inicial = global_position.x

func _physics_process(delta: float) -> void:
	tiempo += delta * velocidad
	# Usamos global_position.x para moverla horizontalmente de forma infinita y suave
	global_position.x = posicion_inicial + sin(tiempo) * distancia
