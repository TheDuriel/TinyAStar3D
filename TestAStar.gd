class_name TestAStar
extends Node

var _astar: TinyAstar3D = TinyAstar3D.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	
	const SIZE: Vector3i = Vector3i(400, 400, 400)
	const FROM: Vector3i = Vector3i(0, 0, 0)
	const TO: Vector3i = Vector3i(399, 399, 399)
	
	
	printt("AStar Init", SIZE)
	_astar.initialize(SIZE)
	
	await get_tree().create_timer(5.0).timeout
	
	printt("AStar Test Path", FROM, TO)
	var start_time: float = Time.get_ticks_msec()
	
	for i: int in 1:
		var path: Array[Vector3i] = _astar.get_path(FROM, TO)
	
		printt("Path length:", path.size())
	
	var end_time: float = Time.get_ticks_msec()
	
	printt("Time Taken to generate path:", end_time - start_time, "ms")
	
