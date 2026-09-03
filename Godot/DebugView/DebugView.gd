class_name TinyAStar3DDebugView
extends Node3D

const DIMENSIONS: Vector3i = Vector3i(8, 16, 8)
const COUNT: int = DIMENSIONS.x * DIMENSIONS.y * DIMENSIONS.z


var _multi: MultiMeshInstance3D = MultiMeshInstance3D.new()
var _mesh: MultiMesh = MultiMesh.new()
var _primitive: BoxMesh = BoxMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _star: TinyAstar3D
var _camera: Camera3D


func _init(astar: TinyAstar3D) -> void:
	_star = astar
	
	_material.vertex_color_use_as_albedo = true
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	_material.distance_fade_min_distance = 1.0
	
	_primitive.material = _material
	_primitive.size = Vector3(0.2, 0.2, 0.2)
	
	_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_mesh.use_colors = true
	_mesh.mesh = _primitive
	
	_multi.multimesh = _mesh
	
	add_child(_multi)
	
	_mesh.instance_count = COUNT


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

	cpos += -_camera.transform.basis.z * (DIMENSIONS.z / 2)
	var gorigin: Vector3i = _star.WorldToGrid(cpos)
	
	for x: int in DIMENSIONS.x:
		for y: int in DIMENSIONS.y:
			for z: int in DIMENSIONS.z:
				var index: int = x + DIMENSIONS.x * (y + DIMENSIONS.y * z)
				
				@warning_ignore("integer_division")
				var grid_pos: Vector3i = Vector3i(x, y, z) - (DIMENSIONS / 2)
				grid_pos += gorigin
				
				if not _star.IsInsideGrid(grid_pos):
					_mesh.set_instance_transform(index, Transform3D(Basis(), Vector3.ZERO))
					_mesh.set_instance_color(index, Color.BLACK)
					continue
				
				var state: bool = _star.GetTraversable(grid_pos)
				var world_pos: Vector3 = _star.GridToWorld(grid_pos)
				_mesh.set_instance_transform(index, Transform3D(Basis(), world_pos))
				_mesh.set_instance_color(index, Color.GREEN if state else Color.RED)
