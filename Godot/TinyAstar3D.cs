using System;
using System.Collections.Generic;
using Godot;

namespace HEADSHOTTHEMOON.DotNet.TinyAstar3D;

[GlobalClass]
public partial class TinyAstar3D : GodotObject
{
	private Vector3 _world_size;
	private Vector3I _grid_size;
    private VoxelGrid _grid;
    private BitAStar _astar;

    // Must be called first.
    // Grid is lightweight and can be used in the editor.
    public void CreateGrid(Vector3I gridSize, Vector3 worldSize)
    {
	    _world_size = worldSize;
	    _grid_size = gridSize;
	    _grid = new VoxelGrid(gridSize.X, gridSize.Y, gridSize.Z);
    }
	
    // Must be called second.
    // AStar is heavy and may be undesirable to run in the editor
    public void CreateAStar()
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");
	    
	    _astar = new BitAStar(_grid);
    }

    public void Clear()
    {
	    _astar = null;
	    _grid = null;
    }
    
    // Returns an Array[Vector3i] of points
    // Failed queries will return an empty array.
    public Godot.Collections.Array<Vector3I> GetPath(Vector3I from , Vector3I to)
    {
	    if (_grid == null || _astar == null)
		    throw new InvalidOperationException("Grid or AStar is not set");
	    
	    List<int> idPath = _astar.FindPath(_grid.ToId(from.X, from.Y, from.Z), _grid.ToId(to.X, to.Y, to.Z));
	    
	    if (idPath == null || idPath.Count == 0)
		    return [];
	    
	    Godot.Collections.Array<Vector3I> gdPath = new Godot.Collections.Array<Vector3I>();
	    
	    foreach (int id in idPath)
	    {
		    _grid.ToCoordinates(id, out int x, out int y, out int z);
		    gdPath.Add(new Vector3I(x, y, z));
	    }

	    return gdPath;
    }
	
    public bool GetTraversable(Vector3I position)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");
	    
	    return _grid.IsTraversable(_grid.ToId(position.X, position.Y, position.Z));
    }
	
    public void SetTraversable(Vector3I position, bool state)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");
	    
	    _grid.SetTraversable(_grid.ToId(position.X, position.Y, position.Z), state);
    }
    
    public Vector3 GetWorldSize()
	    return _world_size;
    
    
    public Vector3I GetGridSize()
    {
	    return _grid_size;
    }
}
