@tool
@icon("res://sprites/debug.png")
extends Node2D
## Debug visualization for understanding IK solver behavior.
enum VisualizationMode {
	OFF,             ## No debug rendering - clean view
	JOINTS,          ## Just red circles at segment positions
	DIRECTIONS,      ## Joints + green direction vectors
	WAVE_VECTORS,    ## Joints + cyan perpendicular vectors (wave displacement)
	SEGMENT_LENGTHS, ## Joints + connecting lines color-coded by stretch (shows constraint violations)
	FULL             ## All visualizations enabled
}

## Reference to the Arm node to query for segment data each frame.
@export var arm: Arm

@export_group("Visualization Control")
## Current visualization mode - change in inspector to switch modes
@export var current_mode: VisualizationMode = VisualizationMode.JOINTS:
	set(value):
		current_mode = value
		queue_redraw()

@export_group("Joint Visualization")
## Visible marker at each joint - increase if hard to see at high zoom levels
@export_range(0.5, 10.0, 0.5) var point_size: float = 3.0
## High contrast color helps spots issues like overlapping segments
@export var point_color: Color = Color.RED

@export_group("Direction Vectors")
## Long enough to see direction clearly but not so long it clutters the view
@export_range(1.0, 10.0, 0.0) var direction_length: float = 10.0
## Distinct from wave vectors for quick visual differentiation
@export var direction_color: Color = Color.GREEN
## Thin lines reduce visual noise while remaining visible
@export_range(0.5, 5.0, 0.5) var direction_width: float = 1.0

@export_group("Wave Vectors")
## Shows both sides of perpendicular to visualize wave displacement range
@export_range(1.0, 10.0, 0.0) var wave_length: float = 10.0
## Cyan stands out against most backgrounds without being overwhelming
@export var wave_color: Color = Color.CYAN
## Slightly thicker than direction to emphasize the wave analysis
@export_range(0.5, 5.0, 0.5) var wave_width: float = 2.0

@export_group("Segment Length Visualization")
## Color when segment is at correct length (within tolerance)
@export var length_correct_color: Color = Color.GREEN
## Color when segment is slightly stretched (noticeable but minor)
@export var length_warning_color: Color = Color.YELLOW
## Color when segment is badly stretched (constraint violation)
@export var length_error_color: Color = Color.RED
## Percentage deviation before showing warning (5% = 0.05)
@export_range(0.01, 0.2, 0.01) var length_warning_threshold: float = 0.05
## Percentage deviation before showing error (10% = 0.10)
@export_range(0.05, 0.5, 0.01) var length_error_threshold: float = 0.10
## Width of segment length connecting lines
@export_range(1.0, 5.0, 0.5) var segment_line_width: float = 2.0


## Matches Arm's physics update rate to avoid stale data.
## Queries segments fresh each frame instead of caching.
func _physics_process(_delta: float) -> void:
	# Only redraw if we have a valid arm reference and mode is not OFF
	if current_mode != VisualizationMode.OFF and arm and arm.has_method("get_segments"):
		queue_redraw()


## Godot's immediate mode rendering - queries fresh segment data and issues draw commands.
## No storage needed, just render what we see.
func _draw() -> void:
	# Early exit if mode is OFF or no arm reference
	if current_mode == VisualizationMode.OFF:
		return

	if not arm or not arm.has_method("get_segments"):
		return

	var segments: Array[Vector2] = arm.get_segments()

	# Need at least two segments to calculate directions
	if segments.size() < 2:
		return

	# Determine what to draw based on current mode
	var draw_joints: bool = current_mode != VisualizationMode.OFF
	var draw_directions: bool = current_mode == VisualizationMode.DIRECTIONS or current_mode == VisualizationMode.FULL
	var draw_waves: bool = current_mode == VisualizationMode.WAVE_VECTORS or current_mode == VisualizationMode.FULL
	var draw_lengths: bool = current_mode == VisualizationMode.SEGMENT_LENGTHS or current_mode == VisualizationMode.FULL

	# Draw segment length lines first (so they appear behind joints)
	if draw_lengths:
		_draw_segment_lengths(segments)

	# Draw joint circles
	if draw_joints:
		for pos in segments:
			draw_circle(pos, point_size, point_color)

	# Draw direction and/or wave vectors
	if draw_directions or draw_waves:
		for i in range(1, segments.size()):
			var vec: Vector2 = segments[i] - segments[i - 1]
			var direction: Vector2 = vec.normalized()
			var perpendicular: Vector2 = direction.orthogonal()
			var pos: Vector2 = segments[i]

			if draw_directions:
				draw_line(pos, pos + direction * direction_length, direction_color, direction_width)

			# Draw both directions because sine waves oscillate - this shows the full range
			if draw_waves:
				draw_line(pos, pos + perpendicular * wave_length, wave_color, wave_width)
				draw_line(pos, pos - perpendicular * wave_length, wave_color, wave_width)


## Draw segment connecting lines color-coded by stretch amount
func _draw_segment_lengths(segments: Array[Vector2]) -> void:
	if not arm or not arm.has_method("get_segment_lengths"):
		# Arm doesn't expose segment_lengths, draw neutral colored lines
		for i in range(1, segments.size()):
			draw_line(segments[i - 1], segments[i], length_correct_color, segment_line_width)
		return

	var target_lengths: Array = arm.get_segment_lengths()

	# Safety check - ensure arrays match
	if target_lengths.size() != segments.size() - 1:
		return

	for i in range(target_lengths.size()):
		var start_pos: Vector2 = segments[i]
		var end_pos: Vector2 = segments[i + 1]
		var actual_length: float = start_pos.distance_to(end_pos)
		var target_length: float = target_lengths[i]

		# Calculate deviation percentage
		var deviation: float = abs(actual_length - target_length) / target_length

		# Choose color based on deviation
		var line_color: Color = length_correct_color
		if deviation >= length_error_threshold:
			line_color = length_error_color
		elif deviation >= length_warning_threshold:
			line_color = length_warning_color

		# Draw connecting line
		draw_line(start_pos, end_pos, line_color, segment_line_width)
