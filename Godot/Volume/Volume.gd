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

	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.z <= 0:
		return result

	if object_size.x < 0.0 or object_size.y < 0.0 or object_size.z < 0.0:
		return result

	# World-space bounds.
	var world_min := -world_size * 0.5
	var cell_size := Vector3(
		world_size.x / grid_size.x,
		world_size.y / grid_size.y,
		world_size.z / grid_size.z
	)

	# Transform the 8 box corners into world space.
	var half_size := object_size * 0.5
	var object_basis := object_transform.basis
	var origin := object_transform.origin

	# For an oriented box, the world-space AABB extents
	# are the absolute basis rows multiplied by the local half-size.
	var aabb_extents := Vector3(
		abs(object_basis[0].x) * half_size.x
			+ abs(object_basis[1].x) * half_size.y
			+ abs(object_basis[2].x) * half_size.z,

		abs(object_basis[0].y) * half_size.x
			+ abs(object_basis[1].y) * half_size.y
			+ abs(object_basis[2].y) * half_size.z,

		abs(object_basis[0].z) * half_size.x
			+ abs(object_basis[1].z) * half_size.y
			+ abs(object_basis[2].z) * half_size.z
	)

	var box_min := origin - aabb_extents
	var box_max := origin + aabb_extents

	# Convert the AABB into a range of candidate grid indices.
	# These are cell indices, not world coordinates.
	var min_grid := Vector3i(
		clampi(int(floor((box_min.x - world_min.x) / cell_size.x)), 0, grid_size.x - 1),
		clampi(int(floor((box_min.y - world_min.y) / cell_size.y)), 0, grid_size.y - 1),
		clampi(int(floor((box_min.z - world_min.z) / cell_size.z)), 0, grid_size.z - 1)
	)

	var max_grid := Vector3i(
		clampi(int(ceil((box_max.x - world_min.x) / cell_size.x)), 0, grid_size.x),
		clampi(int(ceil((box_max.y - world_min.y) / cell_size.y)), 0, grid_size.y),
		clampi(int(ceil((box_max.z - world_min.z) / cell_size.z)), 0, grid_size.z)
	)

	# If the box is entirely outside the world.
	if min_grid.x >= max_grid.x \
	or min_grid.y >= max_grid.y \
	or min_grid.z >= max_grid.z:
		return result

	# Only transform candidate points.
	var inverse_transform := object_transform.affine_inverse()

	for z in range(min_grid.z, max_grid.z):
		for y in range(min_grid.y, max_grid.y):
			for x in range(min_grid.x, max_grid.x):
				var world_point := world_min + Vector3(
					(x + 0.5) * cell_size.x,
					(y + 0.5) * cell_size.y,
					(z + 0.5) * cell_size.z
				)

				var local_point := inverse_transform * world_point

				if abs(local_point.x) <= half_size.x \
				and abs(local_point.y) <= half_size.y \
				and abs(local_point.z) <= half_size.z:
					result.append(Vector3i(x, y, z))

	return result
