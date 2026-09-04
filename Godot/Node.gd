@tool
class_name TinyAStar3DNode
extends Node
# Node wrapper for TinyAStar3D
# Makes interfacing with Volumes and the Debug preview easier
# Simply attach it to your level scene


@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR)
var draw_debug: bool = false:
	set(value):
		draw_debug = value
		_toggle_draw_debug()
		
# Size of the AStar Grid to span across the world
# Should be divisible by 64
@export var grid_size: Vector3i = Vector3i(256, 256, 256):
	set(value):
		grid_size = Vector3(
			clampi(value.x + 64 if value.x > grid_size.x else value.x - 64 if value.x < grid_size.x else grid_size.x, 64, 512),
			clampi(value.y + 64 if value.y > grid_size.y else value.y - 64 if value.y < grid_size.y else grid_size.y, 64, 512),
			clampi(value.z + 64 if value.z > grid_size.z else value.z - 64 if value.z < grid_size.z else grid_size.z, 64, 512))
# Any arbitrary size. The world is always centered on 0,0,0
@export var world_size: Vector3 = Vector3(1024.0, 1024.0, 1024.0)

var _astar: TinyAstar3D = TinyAstar3D.new()
var _debug_view: TinyAStar3DDebugView


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		draw_debug = false


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func initialize() -> void:
	_astar.Clear()
	
	_build_grid()
	_build_astar()


func _build_grid() -> void:
	_astar.CreateGrid(grid_size, world_size)
	_generate_from_tree()


func _build_astar() -> void:
	# Never build the actual heuristic in the editor
	if Engine.is_editor_hint():
		return
	
	_astar.CreateAStar()


func is_traversible(world_position: Vector3) -> bool:
	return _astar.GetTraversable(_astar.WorldToGrid(world_position))


func set_traversible(world_position: Vector3, can_traverse: bool) -> void:
	_astar.SetTraversable(_astar.WorldToGrid(world_position), can_traverse)


func _generate_from_tree() -> void:
	for i: int in 10:
		
		var grp: String = TinyAStar3DVolume.GROUP_ID + str(i)
		
		if not get_tree().has_group(grp):
			continue
		
		var nodes: Array[Node] = get_tree().get_nodes_in_group(grp)
		
		for node: Node in nodes:
			if node is TinyAStar3DVolume:
				
				node.set_astar(_astar)
				
				# Skip pointless. Grid defaults to traversible
				if i == 0 and node.priority == 0 and node.is_traversible == true:
					continue
				
				_generate_from_volume(node)


func _generate_from_volume(node: TinyAStar3DVolume) -> void:
	var points: Array[Vector3i] = node.get_grid_points_in_box(_astar)
	
	for point: Vector3i in points:
		_astar.SetTraversable(point, node.is_traversible)


func _on_node_added(node: Node) -> void:
	if node is TinyAStar3DVolume:
		node.set_astar(_astar)


func _toggle_draw_debug() -> void:
	if not is_node_ready():
		return
	
	if not draw_debug:
		if _debug_view:
			_debug_view.queue_free()
		return
	
	initialize()
	_debug_view = TinyAStar3DDebugView.new(_astar)
	add_child(_debug_view)
