
extends Node

var links_array = []
var selected_link = null
var bodies_collide = true

# === ПЕРЕМЕННЫЕ ДЛЯ ИНСТРУМЕНТОВ И МАГНИТОВ ===
enum ToolMode { NONE, SPRING, ROPE, MAGNET }
var current_tool = ToolMode.NONE
var first_object = null
var first_anchor_local = Vector2.ZERO # Локальная точка первого объекта

var preview_line: Line2D = null
var magnet_crosshair: Node2D = null # Зеленый лазерный прицел для магнитов

# Твои актуальные пути к элементам сверху
@onready var selection = $"../SelectionManager"
@onready var tab_container = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer"
@onready var length_spin = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer2/Length_SpinBox"
@onready var stiffness_spin = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer2/HBoxContainer/Stiffness_SpinBox"
@onready var k_container = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer2/HBoxContainer"
@onready var auto_length_check = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer/AutoLength_CheckBox"
@onready var nit_button = $"../CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/NitButton"
@onready var pruzina_button = $"../CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/PruzinaButton"
@onready var magnet_button = $"../CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/MagnetButton"
@onready var colision_objects = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer/collision_object"
@onready var label_collision_buton = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/HBoxContainer/Длинна2"

func _ready():
	if length_spin:
		length_spin.value_changed.connect(func(_val): update_selected_link())
	if stiffness_spin:
		stiffness_spin.value_changed.connect(func(_val): update_selected_link())
	if nit_button:
		nit_button.pressed.connect(func(): _select_tool(ToolMode.ROPE))
	if pruzina_button:
		pruzina_button.pressed.connect(func(): _select_tool(ToolMode.SPRING))
	if magnet_button:
		magnet_button.pressed.connect(func(): _select_tool(ToolMode.MAGNET))
	if colision_objects:
		colision_objects.toggled.connect(on_collision_object_pressed)
		
	# Линия предпросмотра
	preview_line = Line2D.new()
	preview_line.width = 3.0
	preview_line.z_index = 15
	preview_line.default_color = Color(1.0, 1.0, 0.0, 0.6)
	preview_line.visible = false
	get_parent().call_deferred("add_child", preview_line)
	
	# Прицел для расстановки магнитов
	magnet_crosshair = Node2D.new()
	magnet_crosshair.z_index = 20
	magnet_crosshair.draw.connect(_on_magnet_crosshair_draw)
	get_parent().call_deferred("add_child", magnet_crosshair)
	k_container.hide()
func _process(_delta):
	magnet_crosshair.queue_redraw()
	magnet_crosshair.visible = (current_tool == ToolMode.MAGNET)
	
	var mouse_pos = preview_line.get_global_mouse_position()
	var space_state = preview_line.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	var result = space_state.intersect_point(query)

	var target_snap_pos = mouse_pos
	if result and (current_tool == ToolMode.SPRING or current_tool == ToolMode.ROPE):
		target_snap_pos = get_snap_position(mouse_pos, result[0]["collider"])

	# Если выбран первый объект и мы тянем связь
	if first_object != null and is_instance_valid(first_object) and preview_line.visible:
		var pos_a = first_object.to_global(first_anchor_local)
		var pos_b = target_snap_pos
		
		if current_tool == ToolMode.SPRING:
			update_spring_line(preview_line, pos_a, pos_b)
		elif current_tool == ToolMode.ROPE:
			if preview_line.get_point_count() != 2:
				preview_line.clear_points()
				preview_line.add_point(pos_a)
				preview_line.add_point(pos_b)
			else:
				preview_line.set_point_position(0, pos_a)
				preview_line.set_point_position(1, pos_b)
	_update_k_ui_visibility()

func get_dynamic_anchors(body: Node2D) -> Array:
	var anchors = []
	anchors.append(body.global_position) # Добавляем центр фигуры
	
	for child in body.get_children():
		if child is Polygon2D:
			for p in child.polygon:
				anchors.append(body.to_global(p)) # Добавляем каждый угол фигуры
		elif child.is_in_group("magnets"):
			anchors.append(child.global_position) # Добавляем магниты
			
	return anchors

func get_snap_position(mouse_pos: Vector2, body: Node2D) -> Vector2:
	var best_pos = mouse_pos
	var best_dist = 20.0 
	
	var anchors = get_dynamic_anchors(body)
	for anchor in anchors:
		var dist = mouse_pos.distance_to(anchor)
		if dist < best_dist:
			best_dist = dist
			best_pos = anchor
			
	return best_pos

func _on_magnet_crosshair_draw():
	if current_tool == ToolMode.MAGNET:
		var p = magnet_crosshair.get_local_mouse_position()
		# Лазерные линии-заглушки для точного выравнивания
		magnet_crosshair.draw_line(Vector2(p.x - 2000, p.y), Vector2(p.x + 2000, p.y), Color(0, 1, 0, 0.4), 1.0)
		magnet_crosshair.draw_line(Vector2(p.x, p.y - 2000), Vector2(p.x, p.y + 2000), Color(0, 1, 0, 0.4), 1.0)
		magnet_crosshair.draw_circle(p, 5, Color.RED)

func _physics_process(_delta):
	for link in links_array:
		if is_instance_valid(link["a"]) and is_instance_valid(link["b"]) and is_instance_valid(link["line"]):
			var pos_a = link["a"].to_global(link["local_a"])
			var pos_b = link["b"].to_global(link["local_b"])
			
			if link.get("is_spring", false):
				update_spring_line(link["line"], pos_a, pos_b)
			else:
				link["line"].set_point_position(0, pos_a)
				link["line"].set_point_position(1, pos_b)
		else:
			if is_instance_valid(link["joint"]): link["joint"].queue_free()
			if is_instance_valid(link["line"]): link["line"].queue_free()
			if is_instance_valid(link.get("area")): link["area"].queue_free()

# === ЛОГИКА ИНСТРУМЕНТОВ И КЛИКОВ ===

func _select_tool(tool_mode: int):
	current_tool = tool_mode
	first_object = null
	if preview_line:
		preview_line.visible = false
	print("🛠 Выбран инструмент: ", tool_mode)

func _input(event):
	if current_tool == ToolMode.NONE:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
			get_viewport().set_input_as_handled() 
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_select_tool(ToolMode.NONE)
			print("❌ Инструмент отменен")

func _handle_left_click():
	var mouse_pos = preview_line.get_global_mouse_position()
	var space_state = preview_line.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	var result = space_state.intersect_point(query)
	
	if result:
		var clicked_object = result[0]["collider"]
		
		# Если выбран инструмент магнита — ставим магнит на объект
		if current_tool == ToolMode.MAGNET:
			create_magnet_on_body(clicked_object, mouse_pos)
			return
			
		var snap_pos = get_snap_position(mouse_pos, clicked_object)
		
		# Первый клик связи
		if first_object == null:
			first_object = clicked_object
			first_anchor_local = clicked_object.to_local(snap_pos)
			preview_line.clear_points()
			preview_line.add_point(snap_pos)
			preview_line.add_point(mouse_pos)
			preview_line.visible = true
			
		# Второй клик связи
		elif first_object != clicked_object:
			var link_type = 1 if current_tool == ToolMode.SPRING else 2
			var second_anchor_local = clicked_object.to_local(snap_pos)
			create_joint(first_object, clicked_object, link_type, first_anchor_local, second_anchor_local)
			
			_select_tool(ToolMode.NONE)
			_open_connection_panel()

func create_magnet_on_body(body: Node2D, global_pos: Vector2):
	var magnet = Node2D.new()
	magnet.add_to_group("magnets")
	body.add_child(magnet)
	magnet.global_position = global_pos
	
	magnet.draw.connect(func():
		magnet.draw_circle(Vector2.ZERO, 6.0, Color.RED)
		magnet.draw_arc(Vector2.ZERO, 10.0, 0, TAU, 16, Color.ORANGE, 2.0)
	)
	magnet.queue_redraw()
	print("🧲 Установлен магнит на объекте: ", body.name)

func _open_connection_panel():
	if tab_container:
		for i in range(tab_container.get_tab_count()):
			if tab_container.get_tab_title(i) == "Связь" or tab_container.get_tab_title(i) == "СВЯЗЬ":
				tab_container.current_tab = i
				break

# === СОЗДАНИЕ И УПРАВЛЕНИЕ СВЯЗЯМИ ===

func on_collision_object_pressed(value):
	if selected_link != null:
		selected_link["collide"] = value
		selected_link["joint"].disable_collision = not value
	else:
		bodies_collide = value
	update_collision_label(value)

func update_collision_label(value):
	if value:
		label_collision_buton.text = "КОЛЛИЗИЯ ТЕЛ ВКЛ"
	else:
		label_collision_buton.text = "КОЛЛИЗИЯ ТЕЛ ВЫКЛ"

func create_joint(object_a, object_b, link_type, local_a, local_b):
	var joint = DampedSpringJoint2D.new()
	var line = Line2D.new()
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	
	var pos_a = object_a.to_global(local_a)
	var pos_b = object_b.to_global(local_b)
	
	line.width = 3.0
	line.z_index = 10
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	
	shape.a = pos_a
	shape.b = pos_b
	collision.shape = shape
	area.add_child(collision)
	
	get_parent().add_child(line) 
	get_parent().add_child(area) 
	
	var final_length = pos_a.distance_to(pos_b)
	if not auto_length_check.button_pressed and length_spin:
		final_length = length_spin.value
	
	joint.global_position = pos_a
	joint.length = final_length
	joint.rest_length = final_length
	
	if link_type == 1:
		joint.stiffness = stiffness_spin.value if stiffness_spin else 10.0
		joint.damping = 0.01
		joint.disable_collision = not bodies_collide
		line.default_color = Color.CYAN
	elif link_type == 2:
		joint.stiffness = 64.0
		joint.damping = 2.0
		joint.disable_collision = not bodies_collide
		line.default_color = Color.WHITE
	
	get_parent().add_child(joint) 
	joint.node_a = object_a.get_path()
	joint.node_b = object_b.get_path()
	
	var new_link = {
		"joint": joint,
		"line": line,
		"area": area,
		"a": object_a,
		"b": object_b,
		"local_a": local_a,
		"local_b": local_b,
		"is_spring": (link_type == 1),
		"collide": bodies_collide
	}
	links_array.append(new_link)
	select_link(new_link)

func update_selected_link():
	if selected_link and is_instance_valid(selected_link["joint"]):
		var j = selected_link["joint"]
		if not auto_length_check.button_pressed:
			j.length = length_spin.value
			j.rest_length = length_spin.value
		if j.stiffness < 60:
			j.stiffness = stiffness_spin.value

func select_link(link):
	deselect_link()
	selected_link = link
	link["line"].default_color = Color.RED
	colision_objects.set_block_signals(true)
	colision_objects.button_pressed = link["collide"]
	colision_objects.set_block_signals(false)
	update_collision_label(link["collide"])
	print("Выбрана связь")

func deselect_link():
	if selected_link and is_instance_valid(selected_link["line"]):
		selected_link["line"].default_color = Color.WHITE
	colision_objects.set_block_signals(true)
	colision_objects.button_pressed = bodies_collide
	colision_objects.set_block_signals(false)
	update_collision_label(bodies_collide)
	selected_link = null

func update_spring_line(line: Line2D, a: Vector2, b: Vector2):
	var dir = b - a
	var length = dir.length()
	if length < 1.0: return
	
	var unit_dir = dir.normalized()
	var perp = Vector2(-unit_dir.y, unit_dir.x)
	
	var coil_width = 10.0
	var segments = 12
	
	if line.get_point_count() != segments + 1:
		line.clear_points()
		for i in range(segments + 1):
			line.add_point(Vector2.ZERO)
	
	line.set_point_position(0, a)
	line.set_point_position(segments, b)
	
	for i in range(1, segments):
		var t = float(i) / segments
		var base_pos = a + dir * t
		var sign_val = 1 if (i % 2 == 1) else -1
		var current_width = coil_width
		if i == 1 or i == segments - 1:
			current_width = coil_width * 0.5
		line.set_point_position(i, base_pos + perp * current_width * sign_val)

func _update_k_ui_visibility():
	# 1. Активен ли режим создания пружины
	var is_creating_spring = (current_tool == ToolMode.SPRING)
	
	# 2. Выделена ли уже созданная пружина
	var is_spring_selected = false
	if selected_link != null and selected_link.get("is_spring", false):
		is_spring_selected = true
		
	# Показываем контейнер с k только при создании или выделении пружины
	if k_container:
		k_container.visible = is_creating_spring or is_spring_selected
