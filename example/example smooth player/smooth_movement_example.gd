extends RigidCharacterBody3D


const ACCELRATION_CURVE: Curve = preload("res://example/example smooth player/smooth_acceleration_curve.tres")
const SPEED: float = 3.0
const JUMP_HEIGHT: float = 1.1

@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head

var _wants_to_jump: bool


func _ready() -> void:
	super()
	mass = 60.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = (body.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	linear_damp = 0.0
	
	if direction or _wants_to_jump:
		if is_on_floor():
			acceleration_magnitude = 15.0
		else:
			acceleration_magnitude = 9.8
		target_velocity.x = SPEED * direction.x
		target_velocity.z = SPEED * direction.z
	else:
		if is_on_floor():
			linear_damp = 20.0
		target_velocity.x = 0.0
		target_velocity.z = 0.0
	
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		body.rotate_y(-deg_to_rad(event.relative.x * 0.08))
		head.rotate_x(-deg_to_rad(event.relative.y * 0.08))
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("ui_accept") and is_on_floor():
		_wants_to_jump = true
		var velocity: float = sqrt(2.0 * get_gravity().length() * JUMP_HEIGHT)
		apply_central_impulse(mass * velocity * up_direction)
	else:
		_wants_to_jump = false


func modify_move_force(move_force: Vector3) -> Vector3:
	var horizontal_velocity: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var x_offset: float = ((horizontal_velocity.x * basis.x)).normalized().dot(
			(target_velocity.x * basis.x).normalized())
	var z_offset: float =((horizontal_velocity.z * basis.z)).normalized().dot(
			(target_velocity.z * basis.z).normalized())
	
	if x_offset < 0.0:
		move_force.x *= ACCELRATION_CURVE.sample(x_offset)
	if z_offset < 0.0:
		move_force.z *= ACCELRATION_CURVE.sample(z_offset)
	
	return move_force
