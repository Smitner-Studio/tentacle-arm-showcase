@tool
@icon("res://svg/tentacle_icon.svg")
class_name Arm extends Node2D
## Procedural tentacle arm showcasing FABRIK IK with a wave (hello)
##
## This script shows a multi-pass approach to believable procedural animation:
## 1. FABRIK IK gets the arm pointing at targets accurately
## 2. Constraints prevent the physics from breaking (stretching, compression)
## 3. Wave motion adds life and organic feel
## 4. Final constraint pass keeps everything in check. ¯\_(⊙_ʖ⊙)_/¯
##
## The @tool annotation makes it work in the editor, cool.

#region Exports
@export_group("Node References")
## Main tentacle
@export var base_node: Line2D:
	set(value):
		base_node = value
		if base_node:
			_base_position = base_node.position
		_apply_line_width()
		_apply_width_curve()
		_initialize_segments()

## Shadow tentacle (spooky)
@export var shadow_node: Line2D:
	set(value):
		shadow_node = value
		_apply_line_width()
		_apply_width_curve()

## Optional target node to track. If not set, tracks mouse position instead.
@export var target: Node2D

@export_group("IK Configuration")
## More _segments = smoother curves but higher computation cost. Start low, increase if jerky.
## The setter rebuilds the segment arrays so you can see changes immediately in the editor.
@export_range(3, 50, 1) var num__segments: int = 24:
	set(value):
		num__segments = value
		_initialize_segments()
## Total arm length. IK will compress the arm when target is closer than this distance.
## The setter recalculates segment lengths for immediate visual feedback in the editor.
@export_range(10.0, 128.0, 1.0) var max_length: float = 128.0:
	set(value):
		max_length = value
		_initialize_segments()
## Higher iterations = more accurate target tracking but diminishing returns after 3-4.
@export_range(1, 10, 1) var ik_iterations: int = 2
## Higher iterations = more rigid _segments. Too low and the arm will stretch/compress.
@export_range(1, 20, 1) var constraint_iterations: int = 10
## Enable or disable constraints
@export var enable_contraint: bool = true

@export_group("Wave Motion")
## Perpendicular displacement. Too high destroys the IK targeting, too low looks stiff.
@export_range(0.0, 5.0, 0.5) var wave_amplitude: float = 2.5
## Controls wavelength. Higher values create tighter, more frequent waves along the arm.
@export_range(0.0, 5, 0.1) var wave_frequency: float = 2.0
## Animation speed multiplier. Independent from physics delta for artistic control.
@export_range(0.0, 10.0, 0.1) var wave_speed: float = 3.0

@export_group("Visual Properties")
## Base width of the Line2D in pixels. The width_curve modulates this value along the length.
## Keeping this synchronized ensures the shadow perfectly matches the main tentacle.
@export_range(1.0, 100.0, 0.5) var line_width: float = 24.0:
	set(value):
		line_width = value
		_apply_line_width()
## Width curve controls tapering from base (thick) to tip (thin). Keeping this in code
## ensures the shadow Line2D matches the main Line2D perfectly - no manual sync needed.
## The setter ensures live updates in the editor when you modify the curve.
@export var width_curve: Curve:
	set(value):
		width_curve = value
		_apply_width_curve()



@export_group("Shadow")
## Subtle shadow at arm base creates depth without overwhelming the visual
@export var min_shadow_offset: Vector2 = Vector2(0, 5)
## Exaggerated shadow at tip emphasizes the arm reaching outward
@export var max_shadow_offset: Vector2 = Vector2(0, 20)

#endregion

#region Private Var
var _segments: Array[Vector2] = []
var _segment_lengths: Array[float] = []
var _base_position: Vector2
var _wave_time: float = 0.0
#endregion

## Runs on scene load and sets up segments.
## Separate from _initialize_segments() so setters can rebuild segments during editing.
func _ready() -> void:
	if base_node:
		_base_position = base_node.position
	_initialize_segments()


## Runs each physics frame applying IK, constraints, wave motion, then constraints again.
func _physics_process(delta: float) -> void:
	var target_pos: Vector2 = target.global_position if target else get_global_mouse_position()
	solve_ik(target_pos)

	apply_constraints()
	apply_wave_motion(delta)
	apply_constraints()

	update_line2d()


## Two-pass FABRIK IK: backward pass pulls tip to target, forward pass anchors base.
## Iterate both to satisfy tip and base constraints simultaneously.
func solve_ik(target_position: Vector2) -> void:

	# Set the tip to the target ( ͡° ͜ʖ ͡°)
	_segments[-1] = target_position

	for _iter in range(ik_iterations):
		# Backward: Start from the known good tip position and work back
		# After this pass, tip is correct but base has drifted
		for i in range(num__segments - 1, -1, -1):
			var vec: Vector2 = _segments[i] - _segments[i + 1]
			var direction: Vector2 = vec.normalized()
			_segments[i] = _segments[i + 1] + direction * _segment_lengths[i]

		# Forward: Re-anchor the base and propagate correct lengths forward
		# After this pass, base is correct but tip has moved slightly off target
		# That's why we iterate - each iteration gets closer to satisfying both
		_segments[0] = _base_position
		for i in range(num__segments):
			var vec: Vector2 = _segments[i + 1] - _segments[i]
			var direction: Vector2 = vec.normalized()
			_segments[i + 1] = _segments[i] + direction * _segment_lengths[i]


## moves both _segments toward each other to fix segment stretching. (ಠ_ಠ)
## Multiple iterations let corrections ripple through the chain.
func apply_constraints() -> void:
	if not enable_contraint:
		return
	_segments[0] = _base_position

	for _iter in range(constraint_iterations):
		for i in range(num__segments):
			var current_vec: Vector2 = _segments[i + 1] - _segments[i]
			var distance: float = current_vec.length()

			# Segments can overlap during extreme IK solving (rapid target movements).
			# If that happens _segments can stay stuck.
			# If the distance is small, separate them with an arbitrary direction.
			if distance < 0.0001:
				_segments[i + 1] = _segments[i] + Vector2.RIGHT * _segment_lengths[i]
				continue

			# Calculate the error between current and target length
			var target_vec: Vector2 = current_vec.normalized() * _segment_lengths[i]
			var error_vec: Vector2 = target_vec - current_vec

			# Apply 25% of error to each segment (bilateral correction = 50% total)
			# Base is immovable anchor point - only its neighbor moves toward it
			if i > 0:
				_segments[i] -= error_vec * 0.25
			_segments[i + 1] += error_vec * 0.25

		_segments[0] = _base_position


## Adds sine wave displacement perpendicular to arm direction so waves don't fight IK.
## Phase-based animation creates traveling waves from base to tip.
func apply_wave_motion(delta: float) -> void:

	# No amplitude, no wave!!
	# (╯°o°）╯︵ ┻━┻
	if wave_amplitude <= 0.0:
		return

	_wave_time += delta * wave_speed

	var total_length: float = 0.0
	for length in _segment_lengths:
		total_length += length

	var accumulated_length: float = 0.0
	for i in range(1, _segments.size()):
		accumulated_length += _segment_lengths[i - 1]

		# Normalized position (0-1) along the arm determines wave phase offset
		var t: float = accumulated_length / total_length

		var vec: Vector2 = _segments[i] - _segments[i - 1]
		var direction: Vector2 = vec.normalized()
		var perpendicular: Vector2 = direction.orthogonal()

		# Phase combines time (animation) with position (traveling wave) ᶘ ◕ᴥ◕ᶅ
		var wave_phase: float = _wave_time + t * wave_frequency * TAU
		var wave_offset: float = sin(wave_phase) * wave_amplitude
		_segments[i] += perpendicular * wave_offset


## Updates Line2D points
## Shadow offset interpolates from small (base) to large (tip) for depth trick.
func update_line2d() -> void:
	base_node.clear_points()
	for pos in _segments:
		base_node.add_point(base_node.to_local(pos))

	if shadow_node:
		shadow_node.clear_points()
		for i in range(_segments.size()):
			var t: float = float(i) / float(_segments.size() - 1)
			var shadow_offset: Vector2 = min_shadow_offset.lerp(max_shadow_offset, t)
			var offset_pos: Vector2 = _segments[i] + shadow_offset
			shadow_node.add_point(shadow_node.to_local(offset_pos))


## Rebuilds segment arrays when num__segments or max_length change.
## Starts with straight horizontal line so IK has valid initial positions.
func _initialize_segments() -> void:
	# Early exit if called from setter before nodes are ready
	if not base_node:
		return

	# Clear and rebuild arrays
	_segments.clear()
	_segment_lengths.clear()

	_segments.append(_base_position)
	for i in range(num__segments):
		# Equal-length _segments simplify math and create even wave distribution
		var length: float = max_length / num__segments
		_segment_lengths.append(length)
		_segments.append(_base_position + Vector2(length * (i + 1), 0))

	# Update visual immediately for editor feedback
	update_line2d()


## Syncs width to both Line2Ds so shadow matches main tentacle perfectly.
## Setter pattern enables live editor updates with @tool.
func _apply_line_width() -> void:
	# Null checks because setter runs before _ready() during scene load
	if base_node:
		base_node.width = line_width
	if shadow_node:
		shadow_node.width = line_width


## Syncs width curve to both Line2Ds.
## Runs in setter for live editor updates, includes null checks since setters run before _ready().
func _apply_width_curve() -> void:
	if not width_curve:
		return

	# Null checks because setter runs before _ready() during scene load
	if base_node:
		base_node.width_curve = width_curve
	if shadow_node:
		shadow_node.width_curve = width_curve


## Returns live segment positions for external nodes to read. (Debug Draw etc)
func get_segments() -> Array[Vector2]:
	return _segments


## Returns target segment lengths for constraint visualization
func get_segment_lengths() -> Array:
	return _segment_lengths
