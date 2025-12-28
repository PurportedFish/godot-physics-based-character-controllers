extends HybridCharacterBody3D


var speed: float = 3.0

@onready var camera: Camera3D = $CharacterBody3D/Camera3D


func _ready() -> void:
	super()
	
	physics_body.axis_lock_angular_x = true
	physics_body.axis_lock_angular_y = true
	physics_body.axis_lock_angular_z = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var dir: Vector3 = (character_body.transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	target_velocity = speed * dir
	
	move_and_slide(delta)
	
	print(curr_velocity.length())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		character_body.rotate_y(-deg_to_rad(event.relative.x * 0.08))
		camera.rotate_x(-deg_to_rad(event.relative.y * 0.08))
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
