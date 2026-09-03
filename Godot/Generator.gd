class_name TinyAStar3DGenerator
extends RefCounted


static func generate(tree: SceneTree, astar: TinyAstar3D) -> void:
	for i: int in 10:
		
		var grp: String = TinyAStar3DVolume.GROUP_ID + str(i)
		
		if not tree.has_group(grp):
			continue
		
		var nodes: Array[Node] = tree.get_nodes_in_group(grp)
		
		for node: Node in nodes:
			if node is TinyAStar3DVolume:
				
				# Skip pointless. Grid defaults to traversible
				if i == 0 and node.priority == 0 and node.is_traversible == false:
					continue
				
				_generate_from_volume(astar, node)


static func _generate_from_volume(astar: TinyAstar3D, node: TinyAStar3DVolume) -> void:
	var points: Array[Vector3i] = node.get_grid_points_in_box(
			astar.GetWorldSize(), astar.GetGridSize())
	
	for point: Vector3i in points:
		astar.SetTraversable(point, node.is_traversible)
