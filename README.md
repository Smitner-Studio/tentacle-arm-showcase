# Tentacle Arm

A Godot 4.5 project showcasing procedural tentacle animation using FABRIK with some flare.

## Features

- Mouse tracking, yay.
- Adjustable tentacle appearance (thickness, tapering, colors)
- Organic wave motion with tunable amplitude, frequency, and speed
- Cool rendering with shadow and outline
- Debug visualization
- In Editor editting, yes.

The project uses GL Compatibility renderer and runs at 1920x1080 with integer scaling.

## IK System

The tentacle uses a multi-stage physics approach updated every frame:

1. **FABRIK solver** - Bidirectional algorithm pulls segments toward target
2. **Constraint pass** - Enforces fixed segment lengths and anchors base position
3. **Wave motion** - Applies perpendicular sine waves for organic movement
4. **Second constraint pass** - Re-applies constraints after wave displacement


## License

MIT License - see [License](LICENSE.txt) for details.
