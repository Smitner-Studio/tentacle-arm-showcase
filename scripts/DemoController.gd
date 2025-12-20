@tool

extends Node2D
## Demo controller for eye add/remove API
##
## Demonstrates the dynamic eye API from Arm.gd:
## - Space/Enter: Add a new eye (prints count or "No room!")
## - Escape: Remove the last added eye

@export_tool_button("Add Eye") var add_eye_action = _add_eye
@export_tool_button("Remove Eye") var remove_eye_action = _remove_eye

@export var arm: Arm




## Stack of added eyes for undo functionality
var _added_eyes: Array = []

func _add_eye() -> void:
	var new_eye = arm.add_eye()
	if new_eye:
		_added_eyes.append(new_eye)
		print("Added eye! Total: ", arm.get_eye_count())
	else:
		print("No room for more eyes!")

func _remove_eye() -> void:
	if _added_eyes.size() > 0:
		var last_eye = _added_eyes.pop_back()
		arm.remove_eye(last_eye)
		print("Removed eye! Total: ", arm.get_eye_count())
	else:
		print("No eyes to remove!")

func _input(event: InputEvent) -> void:
	if not arm:
		return

	# Space/Enter: Add eye
	if event.is_action_pressed("ui_accept"):
		_add_eye()

	# Escape: Remove last added eye
	if event.is_action_pressed("ui_cancel"):
		_remove_eye()
		
