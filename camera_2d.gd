extends Camera2D

const zoom_speed = 0.1
@onready var camera = $"."
@onready var central_panel = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/CentralPanel"

func _unhandled_input(event: InputEvent):

	# /// ZOOM - камеры ///
	if event is InputEventMouseButton:
		var mouse_world_before = get_global_mouse_position()
		var hovered = get_viewport().gui_get_hovered_control()
		
		# Проверяем: мышь над UI, И этот UI НЕ внутри central_panel
		if hovered != null and not hovered.is_ancestor_of(central_panel):
			return
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.1
			print("Zoom IN: ", zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= 1.1
			print("Zoom OUT: ", zoom)
		
		var mouse_world_after = get_global_mouse_position()
		var offset = mouse_world_before - mouse_world_after
		position += offset

# /// передвижение камеры ///
	
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			camera.position -= event.relative/zoom 
