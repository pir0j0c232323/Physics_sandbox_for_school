extends Node2D

# Выделение объектов
var selected_objects = []
var selected_object = null

var object_editing = false

@onready var drawer = $"../Shape_drawer"
@onready var sim = $"../SimulationController"
@onready var right_tabs = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer
@onready var Mass_SpinBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/SpinBox
@onready var Scale_SpinBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Scale_SpinBox
@onready var Color_picedbuton_object = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ColorPickerButton
@onready var Static_CheckBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Static_CheckBox
@onready var Height_SpinBox = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Height_SpinBox"
@onready var Height_Label =$"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Label5"
@onready var Size_Label = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Label2"


func _ready():
	if Mass_SpinBox:
		Mass_SpinBox.value_changed.connect(on_mass_changed)
	if Scale_SpinBox:
		Scale_SpinBox.value_changed.connect(on_scale_changed)
	if Color_picedbuton_object:
		Color_picedbuton_object.color_changed.connect(on_color_object_chanded)
	if Static_CheckBox:
		Static_CheckBox.toggled.connect(on_static_toggled)
	if Height_SpinBox:
		Height_SpinBox.value_changed.connect(on_height_changed)

func _draw():
	if drawer.is_active() or not sim.can_edit():
		return
	var obj = _selected_circle()
	if obj:
		draw_circle(handle_position(obj), 4, Color.WHITE)

func _process(delta):
	if object_editing:
		var obj = _selected_circle()
		if not obj:
			object_editing = false
			return
		obj.set_size_px(get_global_mouse_position().distance_to(obj.global_position))
		sync_inspector_ui(obj)
		queue_redraw()
	elif not drawer.is_active() and sim.can_edit() and _selected_circle():
		queue_redraw()   

func add_to_selection(object):
	if not object in selected_objects:
		selected_objects.append(object)
		object.select_object()
		selected_object = object
		sync_inspector_ui(object)
		right_tabs.current_tab = 1

func deselect_single_object(object):
	if object in selected_objects:
		object.deselect_object()
		selected_objects.erase(object)
		if selected_object == object:
			selected_object = selected_objects.back() if selected_objects.size() > 0 else null

func deselect_all_objects():
	for obj in selected_objects:
		if is_instance_valid(obj):
			obj.deselect_object()
	selected_objects.clear()
	selected_object = null
	reset_inspector_ui()
	right_tabs.current_tab = 0

func sync_inspector_ui(object):
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	Static_CheckBox.set_block_signals(true)
	
	Mass_SpinBox.value = object.custom_mass
	if object.has_method("get_size_px"):
		var size = object.get_size_px()
		if size is Vector2:                      # прямоугольник
			Scale_SpinBox.value = size.x
			Height_SpinBox.value = size.y
			Height_SpinBox.visible = true
			Height_Label.visible = true
			Size_Label.text = "ШИРИНА (W)"
		else:                                     # круг
			Scale_SpinBox.value = size
			Height_SpinBox.visible = false
			Height_Label.visible = false
			Size_Label.text = "РАДИУС"
	else:                                         # треугольник и прочие
		Scale_SpinBox.value = object.custom_scale
		Height_SpinBox.visible = false
		Height_Label.visible = false
		Size_Label.text = "РАЗМЕР"
	Color_picedbuton_object.color = object.custom_color
	Static_CheckBox.button_pressed = object.is_static
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)
	Static_CheckBox.set_block_signals(false)

func reset_inspector_ui():
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	Static_CheckBox.set_block_signals(true)
	
	Mass_SpinBox.value = 0
	Scale_SpinBox.value = 0
	Color_picedbuton_object.color = Color.WHITE
	Static_CheckBox.button_pressed = false
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)
	Static_CheckBox.set_block_signals(false)

func on_mass_changed(value):
	if selected_object is RigidBody2D:
		selected_object.custom_mass = value
		if sim.state == "PAUSE" or sim.state == "EDIT":
			selected_object.mass = value

func on_scale_changed(value):
	if not selected_object:
		return
	if selected_object.has_method("set_size_px"):
		if selected_object.has_method("get_size_px") and selected_object.get_size_px() is Vector2:
			var s = selected_object.get_size_px()
			selected_object.set_size_px(value, s.y)
		else:
			selected_object.set_size_px(value)
	else:
		selected_object.custom_scale = value
		if selected_object.has_method("update_size"):
			selected_object.update_size()

func on_height_changed(value):
	if not selected_object:
		return
	if selected_object.has_method("get_size_px") and selected_object.get_size_px() is Vector2:
		var s = selected_object.get_size_px()
		selected_object.set_size_px(s.x, value)

func on_color_object_chanded(new_color):
	if selected_object:
		selected_object.custom_color = new_color
		if sim.state == "PAUSE" or sim.state == "EDIT":
			selected_object.set_color(new_color)

func on_static_toggled(toggled_on: bool):
	if selected_object:
		selected_object.set_static(toggled_on)
		if sim.state == "PLAY":
			selected_object.freeze = toggled_on
		else:
			selected_object.freeze = true

func handle_position(obj):
	return obj.global_position + Vector2(obj.get_size_px(), 0).rotated(obj.global_rotation)

func _selected_circle():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_size_px") and not (obj.get_size_px() is Vector2):
		return obj
	return null

func try_grab_handle(pos) -> bool:
	var obj = _selected_circle()
	if obj and pos.distance_to(handle_position(obj)) <= 12:
		object_editing = true
		return true
	return false
