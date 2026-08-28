using System;

namespace HEADSHOTTHEMOON.DotNet.TinyAstar3D;

public sealed class VoxelGrid
{
    public int Width { get; }
    public int Height { get; }
    public int Depth { get; }

    public int StrideY => Width;
    public int StrideZ { get; }

    public int NodeCount { get; }

    // One bit per voxel
    // 1 = traversable
    // 0 = blocked
    private readonly ulong[] _traversable;

    public VoxelGrid(int width, int height, int depth)
    {
        if (width <= 0)
            throw new ArgumentOutOfRangeException(nameof(width));

        if (height <= 0)
            throw new ArgumentOutOfRangeException(nameof(height));

        if (depth <= 0)
            throw new ArgumentOutOfRangeException(nameof(depth));

        long count = (long)width * height * depth;

        if (count > int.MaxValue)
            throw new ArgumentException("Grid is too large for int voxel IDs.");

        Width = width;
        Height = height;
        Depth = depth;

        NodeCount = (int)count;

        StrideZ = checked(width * height);

        _traversable = new ulong[(NodeCount + 63) / 64];

        // New grids are completely traversable by default.
        Array.Fill(
            _traversable,
            ulong.MaxValue);

        // The last word may contain unused bits if the number
        // of voxels isn't evenly divisible by 64.
        // Those bits must remain zero.
        int unusedBits = (_traversable.Length * 64) - NodeCount;

        if (unusedBits > 0)
        {
            _traversable[^1] = ulong.MaxValue >> unusedBits;
        }
    }

    public int ToId(int x, int y, int z)
    {
        if ((uint)x >= (uint)Width)
            throw new ArgumentOutOfRangeException(nameof(x));

        if ((uint)y >= (uint)Height)
            throw new ArgumentOutOfRangeException(nameof(y));

        if ((uint)z >= (uint)Depth)
            throw new ArgumentOutOfRangeException(nameof(z));

        return x + Width * (y + Height * z);
    }

    public void ToCoordinates(int id, out int x, out int y, out int z)
    {
        ValidateId(id);

        x = id % Width;

        int yz = id / Width;

        y = yz % Height;
        z = yz / Height;
    }

    public bool IsTraversable(int id)
    {
        ValidateId(id);

        return IsTraversableUnchecked(id);
    }

    internal bool IsTraversableUnchecked(int id)
    {
        int word = id >> 6;
        int bit = id & 63;

        return (_traversable[word] & (1UL << bit)) != 0;
    }
    
    public void SetTraversable(int id, bool value)
    {
        ValidateId(id);

        int word = id >> 6;
        int bit = id & 63;

        ulong mask = 1UL << bit;

        if (value)
            _traversable[word] |= mask;
        else
            _traversable[word] &= ~mask;
    }
    
    public void SetTraversable(int x, int y, int z, bool value)
    {
        SetTraversable(ToId(x, y, z), value);
    }
    
    public void SetBlocked(int id)
    {
        SetTraversable(id, false);
    }
    
    public void SetBlocked(int x, int y, int z)
    {
        SetTraversable(x, y, z, false);
    }
    
    public void SetWalkable(int id)
    {
        SetTraversable(id, true);
    }

    public void SetWalkable(int x, int y, int z)
    {
        SetTraversable(x, y, z, true);
    }

    private void ValidateId(int id)
    {
        if ((uint)id >= (uint)NodeCount)
            throw new ArgumentOutOfRangeException(nameof(id));
    }
}
