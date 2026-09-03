class_name TinyAStar3DDebugView
extends Node3D

const DIMENSIONS: Vector3i = Vector3i(16, 16, 16)


var _multi: MultiMeshInstance3D = MultiMeshInstance3D.new()
var _mesh: MultiMesh = MultiMesh.new()
var _primitive: BoxMesh = BoxMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _star: TinyAstar3D
var _camera: Camera3D


func _init(astar: TinyAstar3D) -> void:
	_star = astar
	
	_material.albedo_color = Color.RED
	_material.no_depth_test = true
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_material.disable_receive_shadows = true
	
	_primitive.material = _material
	_primitive.size = Vector3(0.2, 0.2, 0.2)
	
	_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_mesh.instance_count = DIMENSIONS.x * DIMENSIONS.y * DIMENSIONS.z
	_mesh.mesh = _primitive
	
	_multi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_multi.multimesh = _mesh
	
	add_child(_multi)


func _ready() -> void:
	global_position = Vector3.ZERO
	
	if Engine.is_editor_hint():
		_camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	else:
		_camera = Game.camera_controller.camera_3d


func _physics_process(_delta: float) -> void:
	if not _camera:
		return
	if not _star:
		return
	
	var cpos: Vector3 = _camera.global_position
	cpos += -_camera.transform.basis.z * (DIMENSIONS.z * 2)
	var gorigin: Vector3i = _star.WorldToGrid(cpos)
	
	var points: Array[Vector3] = []
	
	for x: int in DIMENSIONS.x:
		for y: int in DIMENSIONS.y:
			for z: int in DIMENSIONS.z:
				
				@warning_ignore("integer_division")
				var grid_pos: Vector3i = Vector3i(x, y, z) - (DIMENSIONS / 2)
				grid_pos += gorigin
				
				if not _star.IsInsideGrid(grid_pos):
					continue
				
				var state: bool = _star.GetTraversable(grid_pos)
				if state:
					continue
				
				var world_pos: Vector3 = _star.GridToWorld(grid_pos)
				points.append(world_pos)
	
	var count: int = points.size()
	_mesh.visible_instance_count = count
	
	for index: int in count:
		_mesh.set_instance_transform(index, Transform3D(Basis(), points[index]))
