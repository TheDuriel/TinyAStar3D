@tool
class_name TinyAStar3DVolume
extends Node3D

const GROUP_ID: String = "_tinyastar3dvolume"
const MATERIAL_UID: String = "uid://bilmhd1i35lu6"

# Lowest goes first.
# Dynamic volumes should be given a priority above 0.
@export_range(0, 9, 1) var priority: int = 0:
	set(value):
		priority = clampi(value, 0, 9)
@export var size: Vector3i = Vector3i(1, 1, 1):
	set(value):
		size = Vector3i(max(value.x, 1), max(value.y, 1), max(value.z, 1))
		if _mesh: _mesh.size = size
@export var is_traversible: bool = false

var _mesh: BoxMesh
var _material: StandardMaterial3D = load(MATERIAL_UID)
var _mesh_instance: MeshInstance3D


func _init() -> void:
	if Engine.is_editor_hint():
		
		_mesh = BoxMesh.new()
		_mesh.material = _material
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.mesh = _mesh
		add_child(_mesh_instance)


func _ready() -> void:
	add_to_group(GROUP_ID + str(priority))


func get_grid_points_in_box(world_size: Vector3, grid_size: Vector3i) -> Array[Vector3i]:
	var object_size: Vector3i = size
	var object_transform: Transform3D = global_transform
	var result: Array[Vector3i] = []
	
	if world_size.x <= 0.0 or world_size.y <= 0.0 or world_size.z <= 0.0:
		return result
	
	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.z <= 0:
		return result
	
	# Transform world-space points into the box's local space.
	var inverse_transform: Transform3D = object_transform.affine_inverse()
	
	# The box is centered on its transform origin.
	var half_size: Vector3 = object_size * 0.5
	
	# Only test grid points that could possibly be inside the box.
	var local_corners: Array[Vector3] = [
		Vector3(-half_size.x, -half_size.y, -half_size.z),
		Vector3( half_size.x, -half_size.y, -half_size.z),
		Vector3(-half_size.x,  half_size.y, -half_size.z),
		Vector3( half_size.x,  half_size.y, -half_size.z),
		Vector3(-half_size.x, -half_size.y,  half_size.z),
		Vector3( half_size.x, -half_size.y,  half_size.z),
		Vector3(-half_size.x,  half_size.y,  half_size.z),
		Vector3( half_size.x,  half_size.y,  half_size.z)]
	
	var world_min: Vector3 = Vector3(INF, INF, INF)
	var world_max: Vector3 = Vector3(-INF, -INF, -INF)
	
	for corner: Vector3 in local_corners:
		var world_corner: Vector3 = object_transform * corner
		world_min = world_min.min(world_corner)
		world_max = world_max.max(world_corner)
	
	# Clamp the world-space bounding box to the grid's valid range.
	var min_grid: Vector3i = Vector3i(
		clampi(int(floor(world_min.x / world_size.x * grid_size.x)), 0, grid_size.x - 1),
		clampi(int(floor(world_min.y / world_size.y * grid_size.y)), 0, grid_size.y - 1),
		clampi(int(floor(world_min.z / world_size.z * grid_size.z)), 0, grid_size.z - 1))
	
	var max_grid: Vector3i = Vector3i(
		clampi(int(ceil(world_max.x / world_size.x * grid_size.x)), 0, grid_size.x),
		clampi(int(ceil(world_max.y / world_size.y * grid_size.y)), 0, grid_size.y),
		clampi(int(ceil(world_max.z / world_size.z * grid_size.z)), 0, grid_size.z))
	
	for z: int in range(min_grid.z, max_grid.z):
		for y: int in range(min_grid.y, max_grid.y):
			for x: int in range(min_grid.x, max_grid.x):
				# Grid point in world space.
				var world_point: Vector3 = Vector3(
					(x + 0.5) * world_size.x / grid_size.x,
					(y + 0.5) * world_size.y / grid_size.y,
					(z + 0.5) * world_size.z / grid_size.z)
				
				# Convert to box-local coordinates.
				var local_point: Vector3 = inverse_transform * world_point
				
				# Test against the unscaled local box.
				if abs(local_point.x) <= half_size.x \
				and abs(local_point.y) <= half_size.y \
				and abs(local_point.z) <= half_size.z:
					result.append(Vector3i(x, y, z))
	
	return result
