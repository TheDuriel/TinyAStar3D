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


func get_grid_points_in_box(astar: TinyAstar3D) -> Array[Vector3i]:
	var world_size: Vector3 = astar.GetWorldSize()
	var world_min: Vector3 = -world_size * 0.5
	
	var grid_size: Vector3i = astar.GetGridSize()
	
	var cell_size: Vector3 = astar.GetCellSize()
	
	var box_size: Vector3i = size
	var box_transform: Transform3D = global_transform
	var box_origin: Vector3 = box_transform.origin
	var box_basis: Basis = box_transform.basis
	var box_half_size: Vector3 = box_size * 0.5
	
	var result: Array[Vector3i] = []

	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.z <= 0:
		return result


	# Get the three local axes in world space.
	#
	# Basis.x/y/z are the transformed local X/Y/Z axes.
	var axis_x := box_basis.x
	var axis_y := box_basis.y
	var axis_z := box_basis.z

	# Their lengths contain the object's scale.
	var scale_x := axis_x.length()
	var scale_y := axis_y.length()
	var scale_z := axis_z.length()

	if scale_x == 0.0 or scale_y == 0.0 or scale_z == 0.0:
		return result

	# Normalize them so they represent pure directions.
	axis_x /= scale_x
	axis_y /= scale_y
	axis_z /= scale_z

	# object_size is in the object's unscaled local space,
	# so account for the transform scale here.
	var half_size := Vector3(
		box_size.x * scale_x * 0.5,
		box_size.y * scale_y * 0.5,
		box_size.z * scale_z * 0.5
	)


	# Calculate the world-space AABB of the oriented box.
	var extent := Vector3(
		abs(axis_x.x) * half_size.x +
		abs(axis_y.x) * half_size.y +
		abs(axis_z.x) * half_size.z,

		abs(axis_x.y) * half_size.x +
		abs(axis_y.y) * half_size.y +
		abs(axis_z.y) * half_size.z,

		abs(axis_x.z) * half_size.x +
		abs(axis_y.z) * half_size.y +
		abs(axis_z.z) * half_size.z
	)

	var box_min := box_origin - extent
	var box_max := box_origin + extent

	# Find the grid-cell range overlapping the AABB.
	var min_x := clampi(
		int(floor((box_min.x - world_min.x) / cell_size.x)),
		0,
		grid_size.x - 1
	)

	var min_y := clampi(
		int(floor((box_min.y - world_min.y) / cell_size.y)),
		0,
		grid_size.y - 1
	)

	var min_z := clampi(
		int(floor((box_min.z - world_min.z) / cell_size.z)),
		0,
		grid_size.z - 1
	)

	var max_x := clampi(
		int(ceil((box_max.x - world_min.x) / cell_size.x)),
		0,
		grid_size.x
	)

	var max_y := clampi(
		int(ceil((box_max.y - world_min.y) / cell_size.y)),
		0,
		grid_size.y
	)

	var max_z := clampi(
		int(ceil((box_max.z - world_min.z) / cell_size.z)),
		0,
		grid_size.z
	)

	# Test only cells within the box's AABB.
	for z in range(min_z, max_z):
		for y in range(min_y, max_y):
			for x in range(min_x, max_x):

				var point := world_min + Vector3(
					(x + 0.5) * cell_size.x,
					(y + 0.5) * cell_size.y,
					(z + 0.5) * cell_size.z
				)

				# Vector from box center to the point.
				var relative: Vector3 = point - box_origin

				# Project onto each oriented box axis.
				var local_x := relative.dot(axis_x)
				var local_y := relative.dot(axis_y)
				var local_z := relative.dot(axis_z)

				# Exact oriented-box containment test.
				if abs(local_x) <= half_size.x \
				and abs(local_y) <= half_size.y \
				and abs(local_z) <= half_size.z:
					result.append(Vector3i(x, y, z))

	return result
