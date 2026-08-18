extends Node2D

# Выделение объектов
var selected_objects = []
var selected_object = null

var info_color: Color = Color(0.9, 0.95, 1.0)   

var object_editing = false
var handle_angle: float = 0.0
var typed_text: String = ""

var typed_armed: bool = true   
var nach: float = 0.0          
var kon: float = 0.0           
var size_tween: Tween = null

var _snap: Array = []

var grabbed_axis: String = ""  
var active_axis: String = ""    
var grabbed_index: int = -1   # какую вершину полигона держим
var grabbed_sign: int = 1

@onready var camera = $"../Camera2D"
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
	z_index = 2
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
	if drawer.is_active() or sim.state != "EDIT":
		return
	var zoom_level = camera.zoom.x if camera else 1.0
	var obj = _selected_circle()
	if obj:
		_draw_circle_overlay(obj, zoom_level)
	var rect = _selected_rect()
	if rect:
		_draw_rect_overlay(rect, zoom_level)
	var poly = _selected_poly()
	if poly:
		_draw_poly_overlay(poly, zoom_level)

func _draw_circle_overlay(obj, zoom_level: float):
	var pos = handle_position(obj)
	var typed_r = typed_text.to_float() if typed_text.is_valid_float() else 0.0
	
	if object_editing or typed_r > 0:
		var show_r = typed_r if typed_r > 0 else obj.get_size_px()
		var show_pos = obj.global_position + Vector2(show_r, 0).rotated(handle_angle)
		draw_dashed_line(obj.global_position, show_pos, Color(0.05, 0.05, 0.05, 0.7), 2.0 / zoom_level, 6.0 / zoom_level)
		if typed_r > 0:
			draw_dashed_circle(obj.global_position, typed_r, Color(0.05, 0.05, 0.05, 0.9), 4.0 / zoom_level)
		var label = typed_text if typed_text != "" else "%.2f" % obj.get_size_px()
		var outward = (show_pos - obj.global_position).normalized()
		var label_pos = show_pos + outward * (18.0 / zoom_level)
		draw_string(ThemeDB.fallback_font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, int(12.0 / zoom_level), Color.DARK_GRAY)
	
	draw_cad_handle(pos, 4.5)

func _draw_rect_overlay(rect, zoom_level: float):
	for h in _rect_handles(rect):
		var active = (object_editing and grabbed_axis == h["axis"]) or (not object_editing and active_axis == h["axis"])
		draw_cad_handle(h["pos"], 4.5, active)
	
	var axis = grabbed_axis if object_editing else active_axis
	if axis != "" and (object_editing or typed_text != "" or active_axis != ""):
		var s = rect.get_size_px()
		# пунктир от середины стороны до противоположной середины
		var a: Vector2
		var b: Vector2
		if axis == "W":
			a = rect.to_global(Vector2(-s.x / 2, 0))
			b = rect.to_global(Vector2(s.x / 2, 0))
		else:
			a = rect.to_global(Vector2(0, -s.y / 2))
			b = rect.to_global(Vector2(0, s.y / 2))
		draw_dashed_line(a, b, info_color, 1.5 / zoom_level, 6.0 / zoom_level)
		
		var value = s.x if axis == "W" else s.y
		var label = axis + " " + (typed_text if typed_text != "" else "%.2f" % value)
		var outward = (Vector2(1, 0) if axis == "W" else Vector2(0, 1)).rotated(rect.global_rotation)
		draw_string(ThemeDB.fallback_font, b + outward * (18.0 / zoom_level), label, HORIZONTAL_ALIGNMENT_CENTER, -1, int(12.0 / zoom_level), info_color)

func _draw_poly_overlay(poly, zoom_level: float):
	for i in range(poly.get_points_count()):
		draw_cad_handle(poly.get_point_world(i), 4.5, object_editing and grabbed_index == i)
	
	# живой угол у вершины, которую тянем
	if object_editing and grabbed_index >= 0 and grabbed_index < poly.get_points_count():
		var n = poly.get_points_count()
		var i = grabbed_index
		var v = poly.get_point_world(i)
		var prev = poly.get_point_world((i - 1 + n) % n)
		var next = poly.get_point_world((i + 1) % n)
		var deg = abs(rad_to_deg((prev - v).angle_to(next - v)))
		var outward = (v - poly.global_position).normalized()
		draw_string(ThemeDB.fallback_font, v + outward * (18.0 / zoom_level), "%.1f°" % deg, HORIZONTAL_ALIGNMENT_CENTER, -1, int(12.0 / zoom_level), info_color)

func _process(delta):
	if object_editing:
		if sim.state != "EDIT":
			object_editing = false
			grabbed_axis = ""
			queue_redraw()
			return
		var mouse = get_global_mouse_position()
		var circ = _selected_circle()
		if circ:
			handle_angle = (mouse - circ.global_position).angle()
			circ.set_size_px(mouse.distance_to(circ.global_position))
			sync_inspector_ui(circ)
			queue_redraw()
			return
		var rect = _selected_rect()
		if rect:
			var local = rect.to_local(mouse)
			var s = rect.get_size_px()
			if grabbed_axis == "W":
				var fixed = -grabbed_sign * s.x / 2.0
				var new_w = max(5.0, grabbed_sign * (local.x - fixed))
				rect.set_size_px(new_w, s.y)
				rect.global_position += Vector2(grabbed_sign * (new_w - s.x) / 2.0, 0).rotated(rect.global_rotation)
			else:
				var fixed = -grabbed_sign * s.y / 2.0
				var new_h = max(5.0, grabbed_sign * (local.y - fixed))
				rect.set_size_px(s.x, new_h)
				rect.global_position += Vector2(0, grabbed_sign * (new_h - s.y) / 2.0).rotated(rect.global_rotation)
			sync_inspector_ui(rect)
			queue_redraw()
			return
		var poly = _selected_poly()
		if poly and grabbed_index >= 0:
			poly.set_point_world(grabbed_index, mouse)
			queue_redraw()
			return

	var obj = selected_object if is_instance_valid(selected_object) else null
	var snap = [
		obj.get_instance_id() if obj else 0,
		obj.get_size_px() if obj and obj.has_method("get_size_px") else -1,
		obj.global_position if obj else Vector2.ZERO,
		obj.global_rotation if obj else 0.0,
		camera.zoom.x if camera else 1.0,
		sim.state,
		drawer.is_active(),
		active_axis,
	]
	if snap != _snap:
		_snap = snap
		queue_redraw()

func _unhandled_input(event: InputEvent):
	if drawer.is_active() or sim.state != "EDIT":
		return
	if not _selected_circle() and not _selected_rect():
		return
	if event is InputEventKey and event.pressed:
		var c = event.unicode
		if (c >= 48 and c <= 57) and typed_text.length() < 7:
			if typed_armed:              
				typed_text = ""
				typed_armed = false
			if size_tween:             
				size_tween.kill()
			typed_text += char(c)
			_apply_typed()
		elif (c == 46 or c == 44) and not "." in typed_text:     # точка или запятая
			typed_text += "."
		elif event.keycode == KEY_BACKSPACE:                     # стереть символ
			typed_text = typed_text.left(typed_text.length() - 1)
			_apply_typed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			var circ = _selected_circle()
			var rect = _selected_rect()
			if typed_text.is_valid_float():
				var v = max(1.0, typed_text.to_float())
				if circ:
					kon = v
					animate_size(circ)
				elif rect:
					var axis = grabbed_axis if object_editing else active_axis
					var s = rect.get_size_px()
					if axis == "W":
						rect.set_size_px(v, s.y)
					elif axis == "H":
						rect.set_size_px(s.x, v)
					sync_inspector_ui(rect)
			typed_text = ""
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_W and not object_editing and _selected_rect():
			active_axis = "W"
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_H and not object_editing and _selected_rect():
			active_axis = "H"
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_ESCAPE:
			typed_text = ""
			typed_armed = true
			queue_redraw()

func _apply_typed():
	queue_redraw()

func add_to_selection(object):
	if not object in selected_objects:
		selected_objects.append(object)
		object.select_object()
		selected_object = object
		handle_angle = object.global_rotation
		sync_inspector_ui(object)
		right_tabs.current_tab = 1
		typed_text = ""
		typed_armed = true
		active_axis = "W" if _selected_rect() else ""
		grabbed_axis = ""
		grabbed_index = -1

func deselect_single_object(object):
	if object in selected_objects:
		object.deselect_object()
		selected_objects.erase(object)
		typed_text = ""
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
	typed_text = ""

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
	if size_tween: size_tween.kill()
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
	if size_tween: size_tween.kill()
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
	return obj.global_position + Vector2(obj.get_size_px(), 0).rotated(handle_angle)

func _selected_circle():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_size_px") and not (obj.get_size_px() is Vector2):
		return obj
	return null

func try_grab_handle(pos) -> bool:
	if sim.state != "EDIT":
		return false
	var cam = get_viewport().get_camera_2d()
	var zoom_level = cam.zoom.x if cam else 1.0
	var grab_radius = 12.0 / zoom_level
	
	var circ = _selected_circle()
	if circ and pos.distance_to(handle_position(circ)) <= grab_radius:
		if size_tween: size_tween.kill()
		typed_text = ""
		typed_armed = true
		grabbed_axis = ""
		object_editing = true
		return true
	
	var rect = _selected_rect()
	if rect:
		for h in _rect_handles(rect):
			if pos.distance_to(h["pos"]) <= grab_radius:
				if size_tween: size_tween.kill()
				typed_text = ""
				typed_armed = true
				active_axis = h["axis"]
				grabbed_axis = h["axis"]
				grabbed_sign = h["sign"]
				object_editing = true
				return true
	var poly = _selected_poly()
	if poly:
		for i in range(poly.get_points_count()):
			if pos.distance_to(poly.get_point_world(i)) <= grab_radius:
				typed_text = ""
				typed_armed = true
				grabbed_index = i
				object_editing = true
				return true
	return false

func draw_cad_handle(pos: Vector2, screen_half: float, active: bool = false):
	var z = camera.zoom.x if camera else 1.0
	var half = screen_half / z
	var halo = 1.5 / z
	var points = PackedVector2Array([
		pos + Vector2(0, -half),
		pos + Vector2(half, 0),
		pos + Vector2(0, half),
		pos + Vector2(-half, 0),
	])
	var halo_points = PackedVector2Array([
		pos + Vector2(0, -(half + halo)),
		pos + Vector2(half + halo, 0),
		pos + Vector2(0, half + halo),
		pos + Vector2(-(half + halo), 0),
	])
	draw_colored_polygon(halo_points, Color(0.1, 0.1, 0.1, 0.9))
	# активная ручка — ярче, чтобы было видно, какую держишь
	draw_colored_polygon(points, Color(0.45, 0.8, 1.0) if active else Color(0.15, 0.55, 1.0))

func release_handle():
	if grabbed_axis != "":
		active_axis = grabbed_axis   # запоминаем, что редактировали последним
	object_editing = false
	grabbed_axis = ""
	grabbed_sign = 1
	grabbed_index = -1

func animate_size(obj):
	nach = obj.get_size_px()               # текущий размер (даже посреди анимации!)
	if size_tween:
		size_tween.kill()
	var delta = abs(kon - nach)
	# маленькое изменение — плавно (~0.35с), огромное — почти мгновенно (~0.08с)
	var duration = clamp(0.4 - delta / 4000.0, 0.15, 0.4)
	size_tween = create_tween()
	size_tween.set_trans(Tween.TRANS_CUBIC)   
	size_tween.set_ease(Tween.EASE_OUT) 
	size_tween.tween_method(_smooth_set.bind(obj), nach, kon, duration)
	size_tween.tween_callback(func():
		if is_instance_valid(obj):
			sync_inspector_ui(obj)
	)

func _smooth_set(value: float, obj):
	if is_instance_valid(obj):
		obj.set_size_px(value)
	queue_redraw()

func draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float):
	var z = camera.zoom.x if camera else 1.0
	# штрихи ~8 экранных пикселей, промежутки ~6 — независимо от зума и радиуса
	var screen_len = TAU * radius * z
	var count = clampi(int(screen_len / 14.0), 8, 80)
	var step = TAU / count
	for i in range(count):
		draw_arc(center, radius, i * step, i * step + step * 0.6, 6, color, width)

func _selected_rect():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_size_px") and obj.get_size_px() is Vector2:
		return obj
	return null

func _rect_handles(obj) -> Array:
	var s = obj.get_size_px()
	return [
		{"pos": obj.to_global(Vector2(s.x / 2, 0)), "axis": "W", "sign": 1},
		{"pos": obj.to_global(Vector2(-s.x / 2, 0)), "axis": "W", "sign": -1},
		{"pos": obj.to_global(Vector2(0, s.y / 2)), "axis": "H", "sign": 1},
		{"pos": obj.to_global(Vector2(0, -s.y / 2)), "axis": "H", "sign": -1},
	]

func _selected_poly():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_point_world"):
		return obj
	return null
