@tool
class_name Eye extends Node2D
## Eye component with smooth tracking
##
## A reusable eye that follows a target position with smooth interpolation.
## Uses eye_tracking.gdshader for UV-based pupil scrolling with eyelid
## overlay and mask cutout.
##
## IMPORTANT: For multiple eyes, ensure ShaderMaterial has
## resource_local_to_scene = true, otherwise all eyes share uniforms.

@export var eye_sprite: Sprite2D:
	set(value):
		eye_sprite = value

@export_range(0.0, 16.0, 0.5) var max_distance: float = 3.0

@export_range(0.1, 20.0, 0.1) var tracking_speed: float = 5.0

## The position the eye should look at (set via set_target)
var _tracking_target: Vector2 = Vector2.ZERO

## Internal: smoothly interpolated position sent to shader
var _current_target: Vector2 = Vector2.ZERO

func set_target(target: Vector2) -> void:
	_tracking_target = target

func _process(delta: float) -> void:
	if not eye_sprite:
		return
	if not eye_sprite.material is ShaderMaterial:
		return

	# Smooth interpolation toward _tracking_target
	_current_target = _current_target.lerp(_tracking_target, tracking_speed * delta)

	var shader_mat := eye_sprite.material as ShaderMaterial
	var offset: Vector2 = _current_target - eye_sprite.global_position

	# Clamp in GDScript (runs once per frame, not per pixel)
	var dist: float = offset.length()
	if dist > max_distance:
		offset = offset / dist * max_distance  # Reuse length for direction

	# Send pre-clamped offset to shader (rounded to integers for pixel-perfect)
	shader_mat.set_shader_parameter("target_offset", Vector2i(offset.round()))
