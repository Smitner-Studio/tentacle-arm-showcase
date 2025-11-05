@tool
@icon("res://sprites/target.png")
class_name ArmTarget extends Node2D

## Left-click and drag to move the target around the viewport.

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Check if click is within target bounds (using sprite size if available)
				var local_click := get_global_mouse_position()
				var distance := global_position.distance_to(local_click)

				# Start dragging if click is within 32 pixels
				if distance < 32.0:
					dragging = true
					drag_offset = global_position - local_click
					get_viewport().set_input_as_handled()
			else:
				# Release drag
				dragging = false

	elif event is InputEventMouseMotion and dragging:
		# Update position while dragging
		global_position = get_global_mouse_position() + drag_offset
		get_viewport().set_input_as_handled()
