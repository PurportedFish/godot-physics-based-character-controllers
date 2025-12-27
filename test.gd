@tool
extends CollisionShape3D
class_name ConeCollider3D

@export var radius: float = 1.0 : set = _set_radius
@export var height: float = 2.0 : set = _set_height
@export var spike_height: float = 0.5 : set = _set_spike_height
@export_range(3, 32, 1) var resolution: int = 8 : set = _set_resolution

var new_shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()

func _ready() -> void:
	_update_collision_shape()

func _set_radius(new_radius: float) -> void:
	radius = max(new_radius, 0.1)  # Prevent zero or negative radius
	_update_collision_shape()

func _set_height(new_height: float) -> void:
	height = max(new_height, 0.1)  # Prevent zero or negative height
	_update_collision_shape()

func _set_spike_height(new_spike_height: float) -> void:
	spike_height = max(new_spike_height, 0.0)  # Allow zero but not negative
	_update_collision_shape()

func _set_resolution(new_resolution: int) -> void:
	resolution = clamp(new_resolution, 3, 32)  # Limit resolution for performance
	_update_collision_shape()

func _trigger_update_shape(_value: bool) -> void:
	_update_collision_shape()

func _update_collision_shape() -> void:
	var points: PackedVector3Array = _generate_cylinder_points()
	new_shape.points = points
	shape = new_shape

func _generate_cylinder_points() -> PackedVector3Array:
	var points: PackedVector3Array = []
	
	# Top circle vertices (at height)
	for i in range(resolution):
		var angle: float = (i * 2.0 * PI) / resolution
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		points.append(Vector3(x, height / 2.0, z))
	
	# Bottom circle vertices (at base, before spike)
	for i in range(resolution):
		var angle: float = (i * 2.0 * PI) / resolution
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		points.append(Vector3(x, -height / 2.0, z))
	
	# Spike tip (center of the triangular fan)
	points.append(Vector3(0, -height / 2.0 - spike_height, 0))
	
	return points
