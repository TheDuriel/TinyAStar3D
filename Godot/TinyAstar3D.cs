using System;
using System.Collections.Generic;
using Godot;

namespace HEADSHOTTHEMOON.DotNet.TinyAstar3D;

[GlobalClass]
public partial class TinyAstar3D : GodotObject
{
	private Vector3I _gridSize;
	private Vector3 _worldSize;

    private VoxelGrid _grid;
    private BitAStar _astar;

    // Must be called first.
    // Grid is lightweight and can be used in the editor.
    public void CreateGrid(Vector3I gridSize, Vector3 worldSize)
    {
	    _gridSize = gridSize;
	    _worldSize = worldSize;
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
	    
	    return IsInsideGrid(position) && _grid.IsTraversable(_grid.ToId(position.X, position.Y, position.Z));
    }
	
    public void SetTraversable(Vector3I position, bool state)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");

	    if (!IsInsideGrid(position))
		    return;
	    
	    _grid.SetTraversable(_grid.ToId(position.X, position.Y, position.Z), state);
    }
    
    public Vector3I GetGridSize()
    {
	    return _gridSize;
    }

    public Vector3 GetWorldSize()
    {
	    return _worldSize;
    }

    public Vector3I WorldToGrid(Vector3 worldPosition)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");

	    Vector3 cellSize = _worldSize / _gridSize;
	    Vector3 gridPosition = worldPosition / cellSize;
	    gridPosition = gridPosition.Round();
	    gridPosition += _gridSize / 2;

	    return (Vector3I)gridPosition;
    }

    public Vector3 GridToWorld(Vector3I gridPosition)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");

	    Vector3 cellSize = _worldSize / _gridSize;
	    Vector3 worldPosition = gridPosition * cellSize;
	    worldPosition -= _worldSize / 2;
	    
	    return worldPosition;
    }

    public bool IsInsideWorld(Vector3I worldPosition)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");

	    if (worldPosition.X < -_worldSize.X / 2 || worldPosition.X >= _worldSize.X / 2)
		    return false;
	    else if (worldPosition.Y < -_worldSize.Y / 2 || worldPosition.Y >= _worldSize.Z / 2)
		    return false;
	    else if (worldPosition.Z < -_worldSize.Z / 2 || worldPosition.Y >= _worldSize.Z / 2)
		    return false;
	    
	    return true;
    }
    public bool IsInsideGrid(Vector3I gridPosition)
    {
	    if (_grid == null)
		    throw new InvalidOperationException("Grid is not set");

	    if (gridPosition.X < 0 || gridPosition.X >= _gridSize.X)
		    return false;
	    else if (gridPosition.Y < 0 || gridPosition.Y >= _gridSize.Y)
		    return false;
	    else if (gridPosition.Z < 0 || gridPosition.Z >= _gridSize.Z)
		    return false;
	    
	    return true;
    }
}
