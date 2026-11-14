extends CharacterBody2D

const EnemyFWalk = 300
const Gravedad = 70
func _ready():
	velocity.x = -EnemyFWalk 
	$AnimatedSprite2D.play("Walk")
	
func _physics_process(delta):
	velocity.y += Gravedad
	
	if is_on_wall():
		if !$AnimatedSprite2D.flip_h:
			velocity.x = EnemyFWalk
		else:
			velocity.x = -EnemyFWalk
			
		if velocity.x < 0:
			$AnimatedSprite2D.flip_h = false
		elif velocity.x > 0:
			$AnimatedSprite2D.flip_h = true
		
	#hola hola probando
	
	
	move_and_slide()
