class_name HybridCharacterBody3D
extends Node3D


@export var character_body: CharacterBody3D
@export var physics_body: RigidCharacterBody3D

var curr_velocity: Vector3:
	get():
		if use_physics_body:
			return physics_body.linear_velocity
		return character_body.velocity
var target_velocity: Vector3
var acceleration: float = 15.0:
	set(value):
		acceleration = value
		physics_body.acceleration = value
var use_physics_body: bool = false


func _ready() -> void:
	physics_body.process_mode = Node.PROCESS_MODE_DISABLED


func move_and_slide(delta: float) -> void:
	if use_physics_body:
		character_body.global_position = physics_body.global_position
		handle_physics()
		check_physics_collision()
	else:
		handle_character(delta)
		check_character_collision()


func handle_character(delta: float) -> void:
	if not character_body.is_on_floor():
		character_body.velocity += character_body.get_gravity() * delta
	
	if target_velocity:
		character_body.velocity.x = move_toward(character_body.velocity.x, target_velocity.x, acceleration * delta)
		character_body.velocity.z = move_toward(character_body.velocity.z, target_velocity.z, acceleration * delta)
	else:
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, acceleration * delta)
		character_body.velocity.z = move_toward(character_body.velocity.z, 0, acceleration * delta)
	
	character_body.move_and_slide()


func check_character_collision() -> void:
	for i in character_body.get_slide_collision_count():
		var collision = character_body.get_slide_collision(i)
		var body = collision.get_collider()
		if body is RigidBody3D:
			start_physics_mode()
			return


func start_physics_mode() -> void:
	character_body.process_mode = Node.PROCESS_MODE_DISABLED
	physics_body.global_transform = character_body.global_transform
	physics_body.linear_velocity = character_body.velocity
	physics_body.process_mode = Node.PROCESS_MODE_INHERIT
	use_physics_body = true


func handle_physics() -> void:
	if target_velocity:
		physics_body.target_velocity.x = target_velocity.x
		physics_body.target_velocity.z = target_velocity.z
	else:
		physics_body.target_velocity.x = 0
		physics_body.target_velocity.z = 0
	
	physics_body.move_and_slide()


func check_physics_collision() -> void:
	var state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(physics_body.get_rid())
	var is_colliding_with_rigid_body: bool = false
	
	for i in state.get_contact_count():
		var collider: Object = state.get_contact_collider_object(i)
		if collider is RigidBody3D:
			var direction: Vector3 = physics_body.target_velocity.normalized()
			if direction.dot(state.get_contact_local_normal(i)) < 0.0:
				is_colliding_with_rigid_body = true
				break
	
	if is_colliding_with_rigid_body:
		return
	
	stop_physics_mode()


func stop_physics_mode() -> void:
	character_body.process_mode = Node.PROCESS_MODE_INHERIT
	character_body.velocity = physics_body.linear_velocity
	physics_body.process_mode = Node.PROCESS_MODE_DISABLED
	use_physics_body = false
