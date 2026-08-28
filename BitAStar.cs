#nullable enable
using System;
using System.Collections.Generic;

namespace HEADSHOTTHEMOON.DotNet.TinyAstar3D;

public sealed class BitAStar
{
    
    private const byte Unvisited = 0;
    private const byte Open = 1;
    private const byte Closed = 2;

    private const byte NoParent = 0;
    private const byte ParentMinusX = 1;
    private const byte ParentPlusX = 2;
    private const byte ParentMinusY = 3;
    private const byte ParentPlusY = 4;
    private const byte ParentMinusZ = 5;
    private const byte ParentPlusZ = 6;
    private readonly VoxelGrid _grid;

    // Valid only when _state[id] != Unvisited.
    private readonly int[] _gScore;

    // 0 = unvisited
    // 1 = open
    // 2 = closed
    private readonly byte[] _state;
    private readonly List<int> _touched = new List<int>();

    // Two parent directions per byte.
    //
    // 0 = no parent
    // 1 = parent is -X
    // 2 = parent is +X
    // 3 = parent is -Y
    // 4 = parent is +Y
    // 5 = parent is -Z
    // 6 = parent is +Z
    private readonly byte[] _parentDirection;

    private readonly MinHeap _open;

    // Higher values make the search greedier/faster, but produce worse paths.
    private readonly int _heuristicWeight;


    public BitAStar(VoxelGrid grid, int heuristicWeight = 2)
    {
        _grid = grid ?? throw new ArgumentNullException(nameof(grid));

        if (heuristicWeight < 1)
            throw new ArgumentOutOfRangeException(nameof(heuristicWeight));

        _heuristicWeight = heuristicWeight;

        int count = grid.NodeCount;
        _state = new byte[count];
        _gScore = new int[count];

        _parentDirection = new byte[(count + 1) / 2];

        _open = new MinHeap();
    }


    // Returns null if no path exists.
    public List<int>? FindPath(int start, int goal)
    {
        foreach (int id in _touched)
            _state[id] = Unvisited;
        
        ValidateId(start);
        ValidateId(goal);

        if (!_grid.IsTraversableUnchecked(start) || !_grid.IsTraversableUnchecked(goal))
            return null;

        if (start == goal)
            return [start];

        _open.Clear();

        _gScore[start] = 0;

        SetParentDirection(start, NoParent);
        
        _touched.Add(start);
        _state[start] = Open;

        int h = ManhattanDistance(start, goal);

        _open.Push(start, h, h);

        while (_open.Count > 0)
        {
            int current = _open.Pop();

            // A node can occur multiple times in the heap.
            if (_state[current] == Closed)
                continue;

            _state[current] = Closed;

            if (current == goal)
                return ReconstructPath(start, goal);

            ExpandNeighbors(current, goal);
        }
        
        return null;
    }

    // ------------------------------------------------------------
    // Neighbor expansion
    // ------------------------------------------------------------

    private void ExpandNeighbors(int current, int goal)
    {
        int currentG = _gScore[current];

        int width = _grid.Width;
        int height = _grid.Height;
        int strideZ = _grid.StrideZ;

        int x = current % width;
        int yz = current / width;
        int y = yz % height;
        int z = yz / height;

        // -X
        if (x > 0)
            TryRelax(current - 1, currentG, goal, ParentPlusX);
        // +X
        if (x + 1 < width)
            TryRelax(current + 1, currentG, goal, ParentMinusX);
        // -Y
        if (y > 0)
            TryRelax(current - width, currentG, goal, ParentPlusY);
        // +Y
        if (y + 1 < height)
            TryRelax(current + width, currentG, goal, ParentMinusY);
        // -Z
        if (z > 0)
            TryRelax(current - strideZ, currentG, goal, ParentPlusZ);
        // +Z
        if (z + 1 < _grid.Depth)
            TryRelax(current + strideZ, currentG, goal, ParentMinusZ);
    }

    private void TryRelax(int neighbor, int currentG, int goal, byte parentDirection)
    {
        if (!_grid.IsTraversableUnchecked(neighbor))
            return;

        byte state = _state[neighbor];

        if (state == Closed)
            return;

        int tentativeG = currentG + 1;

        // If already open with an equally good or better route,
        // there is nothing to do.
        if (state == Open && tentativeG >= _gScore[neighbor])
            return;
        

        _gScore[neighbor] = tentativeG;

        SetParentDirection(neighbor, parentDirection);
        
        if (_state[neighbor] == Unvisited)
            _touched.Add(neighbor);
        
        _state[neighbor] = Open;

        int h = ManhattanDistance(neighbor, goal);

        // Weighted A*:
        //
        // f = g + weight * h
        //
        // weight = 1 -> normal A*
        // weight > 1 -> greedier/faster
        int f = tentativeG + h * _heuristicWeight;

        _open.Push(neighbor, f, h);
    }

    private int ManhattanDistance(int a, int b)
    {
        int width = _grid.Width;
        int height = _grid.Height;
        int strideZ = _grid.StrideZ;

        int ax = a % width;
        int ay = (a / width) % height;
        int az = a / strideZ;

        int bx = b % width;
        int by = (b / width) % height;
        int bz = b / strideZ;

        return Math.Abs(ax - bx) + Math.Abs(ay - by) + Math.Abs(az - bz);
    }

    
    private List<int> ReconstructPath(int start, int goal)
    {
        var path = new List<int>();

        int current = goal;

        while (current != start)
        {
            path.Add(current);

            byte direction = GetParentDirection(current);

            current = direction switch
            {
                ParentMinusX => current - 1,
                ParentPlusX => current + 1,
                ParentMinusY => current - _grid.Width,
                ParentPlusY => current + _grid.Width,
                ParentMinusZ => current - _grid.StrideZ,
                ParentPlusZ => current + _grid.StrideZ,
                _ => throw new InvalidOperationException("Invalid parent direction.")
            };
        }

        path.Add(start);

        path.Reverse();

        return path;
    }


    private byte GetParentDirection(int id)
    {
        int index = id >> 1;
        byte value = _parentDirection[index];

        if ((id & 1) == 0)
            return (byte)(value & 0x0F);

        return (byte)(value >> 4);
    }

    private void SetParentDirection(int id, byte direction)
    {
        int index = id >> 1;
        byte old = _parentDirection[index];

        if ((id & 1) == 0)
            _parentDirection[index] = (byte)((old & 0xF0) | direction);
        else
            _parentDirection[index] = (byte)((old & 0x0F) | (direction << 4));
        
    }

    private void ValidateId(int id)
    {
        if ((uint)id >= (uint)_grid.NodeCount)
            throw new ArgumentOutOfRangeException(nameof(id));
    }

    // Binary min heap
    private sealed class MinHeap
    {
        private int[] _ids;
        private int[] _fScores;
        private int[] _hScores;

        public int Count { get; private set; }

        public MinHeap()
        {
            const int initialCapacity = 1024;
            
            _ids = new int[initialCapacity];
            _fScores = new int[initialCapacity];
            _hScores = new int[initialCapacity];
        }

        public void Clear() { Count = 0; }

        public void Push(int id, int fScore, int hScore)
        {
            EnsureCapacity(Count + 1);

            int index = Count++;

            // Bubble upward.
            while (index > 0)
            {
                int parent = (index - 1) >> 1;

                // Primary ordering: F.
                // Secondary ordering: H.
                // When F is equal, favor the node that is
                // geometrically closer to the goal.
                if (IsLessOrEqual(_fScores[parent], _hScores[parent], fScore, hScore))
                    break;
                
                _ids[index] = _ids[parent];
                _fScores[index] = _fScores[parent];
                _hScores[index] = _hScores[parent];
                
                index = parent;
            }

            _ids[index] = id;
            _fScores[index] = fScore;
            _hScores[index] = hScore;
        }

        public int Pop()
        {
            if (Count == 0)
                throw new InvalidOperationException("Heap is empty.");

            int result = _ids[0];

            Count--;

            if (Count == 0)
                return result;

            int lastId = _ids[Count];
            int lastF = _fScores[Count];
            int lastH = _hScores[Count];

            int index = 0;

            while (true)
            {
                int left = index * 2 + 1;

                if (left >= Count)
                    break;

                int right = left + 1;

                int child = left;

                if (right < Count && IsLess(_fScores[right], _hScores[right], _fScores[left], _hScores[left]))
                    child = right;

                if (!IsLess(_fScores[child], _hScores[child], lastF, lastH))
                    break;
                
                _ids[index] = _ids[child];
                _fScores[index] = _fScores[child];
                _hScores[index] = _hScores[child];

                index = child;
            }

            _ids[index] = lastId;
            _fScores[index] = lastF;
            _hScores[index] = lastH;

            return result;
        }

        private void EnsureCapacity(int required)
        {
            if (required <= _ids.Length)
                return;

            int newCapacity = _ids.Length * 2;

            while (newCapacity < required)
                newCapacity *= 2;

            Array.Resize(ref _ids, newCapacity);
            Array.Resize(ref _fScores, newCapacity);
            Array.Resize(ref _hScores, newCapacity);
        }

        private static bool IsLess(int fA, int hA, int fB, int hB)
        {
            if (fA != fB)
                return fA < fB;

            return hA < hB;
        }

        private static bool IsLessOrEqual(int fA, int hA, int fB, int hB)
        {
            if (fA != fB)
                return fA < fB;

            return hA <= hB;
        }
    }
}
