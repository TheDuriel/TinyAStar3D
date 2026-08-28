# TinyAStar3D
Minimal fixed area AStar (for Godot Mono)

# What does this do?
This is a memory optimized version of AStar.

It does three things:

* Replace the node grid, weights, and connections with a single bitfield.
* Assume cardinal adjacency only.
* Simplify the heuristic for speed over accuracy.

What's the result?

* A X times reduction in memory usage.
* My own use cases involves graphs with dimensions of 400x400x400 cells. (64Million Nodes.)
* For comparison, Godot requires 2gb of memory to allocate that many points. **Without** connections.
* TinyAStar3D can do it in 8 megabytes.
* Total memory footprint for 64million nodes, in active use, is about 600mb

Is this actually good?

Maybe. It serves my use case well.

Wait a second, this isn't AStar anymore!

It's true, due to the drastic simplification it's arguably just an approximation and probably shouldn't qualify for the name.

Is is this for Godot?

A simple wrapper for Godot 4.x is included. The actual logic itself does not involve Godot in any way.

# Installation

This repository is designed to be loaded as a GIT Submodule. How you add these depends on your client of choice.

[Refer to this if you're mad enough to use the command line :P](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

Alternatively, download the zip from this page and unpack it into your project folder.


### Looking for more?

Check out Nylon! https://theduriel.itch.io/nylon

Nylon for Godot is a Deep Dialogue sequencing addon, perfect for making complex RPG dialogue, cutscenes, and more. It's easily modified and used over the network as well, and includes a template project that incldues **many many more** utility systems for quickly building up your own game. Including menu and game state management, option menus, save files, audio, and more.

### Support me!

I don't have a donation link. But instead of giving something for nothing, you can buy Nylon above! And get something in the process! :D

### Need support?

This repository is provided as is. However I will happily answer questions via twitter: https://twitter.com/the_duriel
