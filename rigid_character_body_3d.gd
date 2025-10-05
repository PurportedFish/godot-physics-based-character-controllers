class_name RigidCharacterBody3D
extends RigidBody3D
## A 3D physics body specialized for characters moved by physics simulation and scripts.
##
## [RigidCharacterBody3D] is a [RigidBody3D] intended to be user-controlled. The body
## is moved by calling [method move_and_slide] after setting the [member acceleration_magnitude] 
## and [member target_velocity].

enum PlatformOnLeave {
	ADD_VELOCITY, ## Add the last platform velocity to the [member linear_velocity] when the body leaves a moving platform.
	ADD_UPWARD_VELOCITY, ## Add the last platform upward velocity to the [member linear_velocity] when the body leaves a moving platform, but any downward motion is ignored.
	DO_NOTHING ## Do nothing when leaving a moving platform.
}

## Vector pointing upwards, used for slope behavior calculations.
@export var up_direction: Vector3 = Vector3.UP
## A vertical position on the body. Collision points above the [member neck_height] is the first
## requirement to be considered a ceiling collision.
@export var neck_height: float = 1.5
## The minimum angle of a collision to be considered a ceiling if the contact position also occurs
## above [member neck_height].
@export_range(0.0, 180, 1.0, "radians_as_degrees") var ceiling_min_angle: float = deg_to_rad(105.0)
@export_group("Floor", "floor")
## If [code]true[/code], the body will not slide on slopes when calling [method move_and_slide]
## when the body is standing still. [br][br]
## If [code]false[/code], the body will slide on floor's slopes when velocity applies a downward force.
@export var floor_stop_on_slope: bool = true
## If [code]false[/code] (by default), the body will move faster on downward slopes and slower on upward slopes. [br][br]
## If [code]true[/code], the body will always move at the same speed on the ground no matter the slope.
@export var floor_constant_speed: bool = false
## A vertical position on the body. Collision points below the [member knee_height] is the first
## requirement to be considered a floor collision.
@export var floor_knee_height: float = 0.5
## The maximum angle of a collision to be considered a floor if the contact position also occurs
## below [member knee_height].
@export_range(0.0, 180, 1.0, "radians_as_degrees") var floor_max_angle: float = deg_to_rad(45.0)
@export_group("Moving Platform", "platform")
## If [code]true[/code], the body will move in the same velocity while on top of an [AnimatableBody3D]. [br][br]
## If [code]false[/code], the body will not be affected while on top of an [AnimatableBody3D].
@export var platform_move_with_moving_platform: bool = true
## Sets the behavior to apply when the body leaves a moving platofrm. By default, to be physically accurate,
## when the body leaves the last platform velocity is applied.
@export var platform_on_leave: PlatformOnLeave

## The target velocity (typically in meters per second) that the body tries to reach. Used and modified
## during calls to [method move_and_slide].
var target_velocity: Vector3 = Vector3.ZERO
## The acceleration used to calculate forces. The higher the acceleration, the faster the body reaches
## [member target_velocity]. It is important to note that a high acceleration and high target speed
## results in a high calculated force being applied to the body. Therefore, collisions with heavier objects
## can result in unrealistic behavior such as a 1 kg [RigidCharacterBody3D] pushing a 100 kg [RigidBody3D].
## If a high acceleration and speed are intended for the body but with alternative collision behavior,
## consider modifying [member acceleration_magnitude] in [method _integrate_forces] to detect if any
## collisions body objects are [RigidBody3D]s and modify the acceleration accordingly.
var acceleration_magnitude: float = 15.0

var _initial_parent: Node
var _state: PhysicsDirectBodyState3D
var _floor_normal: Vector3 = Vector3.ZERO
var _is_on_ceiling: bool = false
var _is_on_floor: bool = false
var _is_on_wall: bool = false


func _ready() -> void:
	_initial_parent = get_parent()
	
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.0
	
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	
	contact_monitor = true
	max_contacts_reported = 16

## Applies forces the body to reach [member target_velocity].
func move_and_slide() -> void:
	_detect_ceiling_floor_wall()
	
	if not target_velocity:
		return
	
	var move_magnitude: float = mass * acceleration_magnitude
	var move_force: Vector3 = move_magnitude * target_velocity.normalized()
	var target_speed: float = target_velocity.length()
	
	move_force = modify_move_force(move_force)
	
	if _is_on_floor:
		if _floor_normal.is_normalized() and move_force.normalized().dot(_floor_normal) > 0.1:
			move_force = move_force.slide(_floor_normal)
		if not floor_constant_speed and target_velocity.normalized().dot(_floor_normal) < -0.1:
			move_force *= clampf(_floor_normal.dot(up_direction), -1.0, 1.0)
			target_speed = target_velocity.slide(_floor_normal).length()
	
	var horizontal_velocity: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var drag_scale: float = horizontal_velocity.length() / target_speed
	var drag_force: Vector3 = move_magnitude * drag_scale * -horizontal_velocity.normalized()
	
	apply_force(move_force + drag_force)


## Override this method to modify the move force before it is applied to the body. [param move_force]
## is equal to [code]mass * acceleration_magnitude * target_velocity.normalized()[/code]
func modify_move_force(move_force: Vector3) -> Vector3:
	return move_force


## Returns [code]true[/code] if the body collided with the ceiling on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member neck_height] and [member ceiling_min_angle] are used
## to determine whether a surface is "ceiling" or not.
func is_on_ceiling() -> bool:
	return _is_on_ceiling

## Returns [code]true[/code] if the body collided only with the ceiling on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member neck_height] and [member ceiling_min_angle] are used
## to determine whether a surface is "ceiling" or not.
func is_on_ceiling_only() -> bool:
	return _is_on_ceiling and not (_is_on_floor or _is_on_wall)

## Returns [code]true[/code] if the body collided with the floor on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member up_direction], [member knee_height] and [member floor_max_angle] are used
## to determine whether a surface is "floor" or not.
func is_on_floor() -> bool:
	return _is_on_floor

## Returns [code]true[/code] if the body collided only with the floor on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member up_direction], [member knee_height] and [member floor_max_angle] are used
## to determine whether a surface is "floor" or not.
func is_on_floor_only() -> bool:
	return _is_on_floor and not (_is_on_ceiling or _is_on_wall)

## Returns [code]true[/code] if the body collided with the wall on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member knee_height] and [member neck_height] are used
## to determine whether a surface is "wall" or not.
func is_on_wall() -> bool:
	return _is_on_wall

## Returns [code]true[/code] if the body collided only with the wall on the last call of [method move_and_slide]. 
## Otherwise, returns [code]false[/code]. The [member knee_height] and [member neck_height] are used
## to determine whether a surface is "wall" or not.
func is_on_wall_only() -> bool:
	return _is_on_wall and not (_is_on_ceiling or _is_on_floor)


func _detect_ceiling_floor_wall() -> void:
	_floor_normal = Vector3.ZERO
	_state = PhysicsServer3D.body_get_direct_state(get_rid())
	
	_is_on_ceiling = false
	_is_on_floor = false
	_is_on_wall = false
	
	var moving_platform: AnimatableBody3D = null
	
	for i in _state.get_contact_count():
		var collider: Object = _state.get_contact_collider_object(i)
		var contact_position: Vector3 = to_local(_state.get_contact_collider_position(i))
		var normal: Vector3 = _state.get_contact_local_normal(i)
		var contact_angle: float = acos(normal.dot(up_direction))
		
		if (
			contact_position.y > floor_knee_height 
			and contact_position.y < neck_height
			and contact_angle > floor_max_angle
			and contact_angle < ceiling_min_angle
		):
			_is_on_wall = true
			continue
		
		if (
			contact_position.y >= neck_height 
			and (
				contact_angle >= ceiling_min_angle 
				or is_equal_approx(contact_angle, ceiling_min_angle)
			)
		):
			_is_on_ceiling = true
			continue
		
		if normal.y > _floor_normal.y:
			_floor_normal = normal
			if collider is AnimatableBody3D:
				moving_platform = collider
			else:
				moving_platform = null
		
		if contact_angle <= floor_max_angle or is_equal_approx(contact_angle, floor_max_angle):
			_is_on_floor = true
			
			if not floor_stop_on_slope:
				continue
			
			var normal_force: Vector3 = -get_gravity().length() * mass * Vector3.DOWN.slide(normal)
			apply_central_force(normal_force)
	
	if platform_move_with_moving_platform:
		if moving_platform:
			reparent(moving_platform)
		elif _is_on_floor:
			reparent(_initial_parent)
		
		if get_parent() is AnimatableBody3D:
			var platform_velocity: Vector3 = PhysicsServer3D.body_get_state(
					get_parent().get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
			print(linear_velocity)
			if not _is_on_floor and linear_velocity.dot(platform_velocity) <= 0.0:
				if platform_on_leave == PlatformOnLeave.ADD_VELOCITY:
					linear_velocity += platform_velocity
				elif  (
					platform_on_leave == PlatformOnLeave.ADD_UPWARD_VELOCITY 
					and platform_velocity.y > 0.0
				):
					linear_velocity.y += platform_velocity.y
				reparent(_initial_parent)
