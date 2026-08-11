extends Node2D

# Прелоады сцен
var new_ball = preload("res://сцены обьектов + их скрипты/круг.tscn")
var new_rectangle = preload("res://сцены обьектов + их скрипты/прямоугольник.tscn")
var new_triangle = preload("res://сцены обьектов + их скрипты/треугольник.tscn")

# ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
var number_selected_object = 0
var selected_object = null
var selected_link = null
var grabbed_object = null
var is_dragging = false
var grab_offset
var original_layer = 1
var original_mask = 1
var state = "EDIT"

# Выделение и связи
var selected_objects = [] # Список всех выделенных объектов (через Shift)
var links_array = []      # Массив созданных связей и линий
var bodies_collide = true 

# UI элементы
@onready var menu_button: MenuButton = $CanvasLayer/VBoxContainer/HBoxContainer/MenuButton
@onready var mechanics_panel = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel
@onready var molecular_panel = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MolecularPanel
@onready var electricity_panel = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/ElectricityPanel
@onready var right_tabs = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer

# Кнопки механики
@onready var circle_button = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/CircleButton
@onready var rectangle_button = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/RectangleButton
@onready var triangle_button = $CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/TriangleButton

# Кнопки старт\пауза\редакт\скорость
@onready var play_pause_button = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/Play_Pause_Button
@onready var edit_button = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/edit_button
@onready var speed_slider = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/HSlider

# Кнопки параметра мира
@onready var gravity_button = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/World/GRAVITY

# Кнопки параметра связей
@onready var length_spin = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Length_SpinBox"
@onready var stiffness_spin =$"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Stiffness_SpinBox"
@onready var auto_length_check = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/AutoLength_CheckBox"
@onready var nit_button = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Nit_Button"
@onready var pruzina_button = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Pruzina_Button2"
@onready var Static_CheckBox = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Static_CheckBox
@onready var colision_objects = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/HBoxContainer/collision_object"

# Кнопки параметра обьекты
@onready var Mass_SpinBox = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/SpinBox
@onready var Scale_SpinBox = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Scale_SpinBox
@onready var Color_picedbuton_object = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ColorPickerButton

# Побочки от кретина
@onready var label_collision_buton = $"CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/HBoxContainer/Длинна2"

func _ready():
	# === НАСТРОЙКА МЕНЮ ===
	menu_button.custom_minimum_size = Vector2(60, 60)
	menu_button.text = "☰"
	print("Слайдер: ", speed_slider)
	
	length_spin.value_changed.connect(func(_val): update_selected_link())
	stiffness_spin.value_changed.connect(func(_val): update_selected_link())
	
	# === ПОДКЛЮЧЕНИЕ КНОПОК ===
	if circle_button:
		circle_button.pressed.connect(_on_circle_pressed)
	if rectangle_button:
		rectangle_button.pressed.connect(_on_rectangle_pressed)
	if triangle_button:
		triangle_button.pressed.connect(_on_triangle_pressed)
	
	if play_pause_button:
		play_pause_button.text = "▶"
		play_pause_button.pressed.connect(on_play_pause_pressed)
	if edit_button:
		edit_button.pressed.connect(on_edit_pressed)
		edit_button.text = "🔧"
	if speed_slider:
		speed_slider.value_changed.connect(on_speed_changed)
		
	# кнопки панели мира
	if gravity_button:
		gravity_button.toggled.connect(on_gravity_pressed)
		
	# кнопки панели объектов
	if Static_CheckBox:
		Static_CheckBox.toggled.connect(on_static_toggled)
	if Mass_SpinBox:
		Mass_SpinBox.value_changed.connect(on_mass_changed)
	if Scale_SpinBox:
		Scale_SpinBox.value_changed.connect(on_scale_changed)
	if Color_picedbuton_object:
		Color_picedbuton_object.color_changed.connect(on_color_object_chanded)
		
	# кнопки панели связей
	if nit_button:
		nit_button.pressed.connect(_on_nit_button_pressed)
	if pruzina_button:
		pruzina_button.pressed.connect(_on_pruzina_button_pressed)
	if colision_objects:
		colision_objects.toggled.connect(on_collision_object_pressed)
	
	_show_panel(0)
	update_ui()

func can_edit() -> bool:
	return state != "PLAY"

func _on_menu_selected(id):
	_show_panel(id)

func _show_panel(index):
	mechanics_panel.visible = (index == 0)
	molecular_panel.visible = (index == 1)
	electricity_panel.visible = (index == 2)

# === ОБРАБОТЧИКИ КНОПОК ФИГУР ===
func _on_circle_pressed():
	number_selected_object = 0
	print("Выбран: Круг")

func _on_rectangle_pressed():
	number_selected_object = 1
	print("Выбран: Прямоугольник")

func _on_triangle_pressed():
	number_selected_object = 2
	print("Выбран: Треугольник")

# === ФИЗИЧЕСКОЕ ДВИЖЕНИЕ И ОБНОВЛЕНИЕ СВЯЗЕЙ ===
func _physics_process(delta: float) -> void:
	var world_pos = get_global_mouse_position()
	if is_dragging == true and is_instance_valid(grabbed_object):
		grabbed_object.global_position = world_pos + grab_offset
		
	# Динамически обновляем концы нити/шарнира за каждым объектом
	for link in links_array:
		if is_instance_valid(link["a"]) and is_instance_valid(link["b"]) and is_instance_valid(link["line"]):
			var pos_a = link["a"].global_position
			var pos_b = link["b"].global_position
			
			# Если это пружина — рисуем зигзаг, если нить — обычную прямую линию
			if link.get("is_spring", false):
				update_spring_line(link["line"], pos_a, pos_b)
			else:
				link["line"].set_point_position(0, pos_a)
				link["line"].set_point_position(1, pos_b)
		else:
			if is_instance_valid(link["joint"]): link["joint"].queue_free()
			if is_instance_valid(link["line"]): link["line"].queue_free()
			if is_instance_valid(link.get("area")): link["area"].queue_free()

# === ОБРАБОТКА КЛИКОВ ПО МИРУ ===
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		# 1. СНАЧАЛА проверяем, не кликнули ли мы по физическому объекту
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_point(query)
		
		if result.size() > 0:
			var clicked_object = result[0].collider
			if clicked_object is RigidBody2D:
				# Если кликнули по объекту — сбрасываем выделение связи и выделяем объект
				deselect_link()
				
				if Input.is_key_pressed(KEY_SHIFT):
					if clicked_object in selected_objects:
						deselect_single_object(clicked_object)
					else:
						add_to_selection(clicked_object)
				else:
					deselect_all_objects()
					add_to_selection(clicked_object)
					start_grab(clicked_object)
				return # Прерываем клик, чтобы он не ушел на линии
		
		# 2. ЕСЛИ ПОД КУРСОРОМ НЕТ ОБЪЕКТА — проверяем, не кликнули ли по линии связи
		var found_link = false
		for link in links_array:
			if is_instance_valid(link["a"]) and is_instance_valid(link["b"]):
				var dist = Geometry2D.get_closest_point_to_segment_uncapped(mouse_pos, link["a"].global_position, link["b"].global_position).distance_to(mouse_pos)
				if dist < 10.0:
					select_link(link)
					found_link = true
					break
		
		# 3. Если не кликнули ни туда, ни сюда — сбрасываем всё и спавним новый объект
		if not found_link:
			if selected_link != null or selected_objects.size() != 0:
				deselect_link()
				deselect_all_objects()
				return
			else:
				create_object(number_selected_object, mouse_pos)
			
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop_grab()
		
	if event.is_action_pressed("delete_all"):
		delete_all_objects()
	if event.is_action_pressed("delete_selected"):
		delete_selected_object()

func handle_left_click():
	if not can_edit(): return
	
	var world_pos = get_global_mouse_position()
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		var clicked_object = result[0].collider
		if clicked_object is RigidBody2D:
			# Множественный выбор через Shift
			if Input.is_key_pressed(KEY_SHIFT):
				if clicked_object in selected_objects:
					deselect_single_object(clicked_object)
				else:
					add_to_selection(clicked_object)
			else:
				# Если кликнули без Shift — выделяем только один объект и можем его тащить
				deselect_all_objects()
				add_to_selection(clicked_object)
				start_grab(clicked_object)
	else:
		# Клик в пустоту — сбрасываем выделение и спавним объект
		deselect_all_objects()
		create_object(number_selected_object, world_pos)

# === ЛОГИКА ВЫДЕЛЕНИЯ ===
func add_to_selection(object):
	if not object in selected_objects:
		selected_objects.append(object)
		object.select_object()
		
		# Синхронизируем инспектор с последним выделенным объектом
		selected_object = object
		sync_inspector_ui(object)
		right_tabs.current_tab = 1 # Вкладка "Объект"

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
	right_tabs.current_tab = 0 # Вкладка "Мир"

func sync_inspector_ui(object):
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	Static_CheckBox.set_block_signals(true)
	
	Mass_SpinBox.value = object.custom_mass
	Scale_SpinBox.value = object.custom_scale
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

# === СОЗДАНИЕ ОБЪЕКТОВ ===
func create_object(type, position):
	if not can_edit(): return
	var scene
	match type:
		0: scene = new_ball
		1: scene = new_rectangle
		2: scene = new_triangle
	
	if scene:
		var new_object = scene.instantiate()
		new_object.position = position
		add_child(new_object)
		new_object.mass = new_object.custom_mass
		new_object.set_color(new_object.custom_color)
		new_object.update_size()
		new_object.freeze = true
		new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
		print("Объект создан в позиции: ", position)

# === СОЗДАНИЕ СВЯЗЕЙ ===
func _on_pruzina_button_pressed():
	try_create_connection(1) # 1 - Пружина

func _on_nit_button_pressed():
	try_create_connection(2) # 2 - Нить

func on_collision_object_pressed(value):
	if selected_link != null:
		selected_link["collide"] = value
		selected_link["joint"].disable_collision = not value
	else:
		bodies_collide = value
	update_collision_label(value)

func try_create_connection(link_type: int):
	if selected_objects.size() < 2:
		print("⚠️ Выделите как минимум 2 объекта (зажав Shift)!")
		return
	
	# Соединяем объекты из списка последовательно (цепочкой)
	for i in range(selected_objects.size() - 1):
		create_joint(selected_objects[i], selected_objects[i + 1], link_type)

func create_joint(object_a, object_b, link_type):
	var joint = DampedSpringJoint2D.new()
	var line = Line2D.new()
	
	# Создаем Area2D и коллизию для возможности кликать по линии мышкой
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	
	# Настройка визуальной линии
	line.width = 3.0
	line.z_index = 10 # Отрисовываем поверх объектов
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	
	# Настройка формы коллизии по текущим позициям объектов
	shape.a = object_a.global_position
	shape.b = object_b.global_position
	collision.shape = shape
	area.add_child(collision)
	
	# Добавляем элементы на сцену
	add_child(line)
	add_child(area)
	
	# Вычисляем длину: автоматически или из SpinBox
	var dist = object_a.global_position.distance_to(object_b.global_position)
	var final_length = dist
	
	if not auto_length_check.button_pressed and length_spin:
		final_length = length_spin.value
	
	# Настройки физики джойнта
	joint.global_position = object_a.global_position
	joint.length = final_length
	joint.rest_length = final_length
	
	if link_type == 1:
		# 1: ПРУЖИНА (Мягкая, берем жесткость из SpinBox)
		joint.stiffness = stiffness_spin.value if stiffness_spin else 10.0
		joint.damping = 0.01
		joint.disable_collision = not bodies_collide
		line.default_color = Color.CYAN
		print("🔗 Создана Пружина. Длина: ", final_length, ", жесткость: ", joint.stiffness)
		
		
		
	elif link_type == 2:
		# 2: НИТЬ / ВЕРЁВКА (Жесткая)
		joint.stiffness = 64.0
		joint.damping = 2.0
		joint.disable_collision = not bodies_collide
		line.default_color = Color.WHITE
		print("🔗 Создана Нить. Длина: ", final_length)

	add_child(joint)

	# Указываем пути к телам ТОЛЬКО ПОСЛЕ add_child
	joint.node_a = object_a.get_path()
	joint.node_b = object_b.get_path()

	# Сохраняем всё в общий массив связей
	links_array.append({
		"joint": joint,
		"line": line,
		"area": area,
		"a": object_a,
		"b": object_b,
		"is_spring": (link_type == 1), # true для пружины, false для нити
		"collide": bodies_collide
	})

# === УДАЛЕНИЕ И ПЕРЕТАСКИВАНИЕ ===
func delete_all_objects():
	is_dragging = false
	grabbed_object = null
	for child in get_children():
		if child is RigidBody2D:
			child.queue_free()
	deselect_all_objects()
	print("Все объекты удалены!")

func delete_selected_object():
	for obj in selected_objects:
		if is_instance_valid(obj):
			if obj == grabbed_object:
				is_dragging = false
				grabbed_object = null
			obj.queue_free()
	selected_objects.clear()
	selected_object = null
	reset_inspector_ui()
	print("Выделенные объекты удалены!")

func start_grab(object):
	if not can_edit(): return
	elif grabbed_object == null:
		grabbed_object = object
		grab_offset = object.global_position - get_global_mouse_position()
		grabbed_object.freeze = true
		original_layer = grabbed_object.collision_layer
		original_mask = grabbed_object.collision_mask
		grabbed_object.collision_layer = 0
		grabbed_object.collision_mask = 0
		is_dragging = true

func stop_grab():
	if is_dragging == true and grabbed_object != null and is_instance_valid(grabbed_object):
		grabbed_object.collision_layer = original_layer
		grabbed_object.collision_mask = original_mask
		
		if state == "EDIT" or state == "PAUSE" or grabbed_object.is_static:
			grabbed_object.freeze = true
		else:
			grabbed_object.freeze = false
			
		grabbed_object.linear_velocity = Vector2.ZERO
		grabbed_object.angular_velocity = 0
		
	is_dragging = false
	grabbed_object = null

# === ИНТЕРФЕЙС И СИМУЛЯЦИИ ===
func update_ui():
	if state == "PLAY":
		play_pause_button.text = "⏸️"
		play_pause_button.add_theme_color_override("font_color", Color.YELLOW)
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color", Color.WEB_GRAY)
	elif state == "PAUSE":
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color", Color.LIME_GREEN)
		edit_button.disabled = false
		edit_button.text = "🔧"
		edit_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color", Color.BLUE)
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color", Color.WEB_GRAY)

func update_collision_label(value):
	if value == true:
		colision_objects.text = "КОЛЛИЗИЯ ВКЛ"
	else:
		colision_objects.text = "КОЛЛИЗИЯ ВЫКЛ"

func start_simulation():
	if is_dragging == true and is_instance_valid(grabbed_object):
		stop_grab()
	for child in get_children():
		if child is RigidBody2D and not child.is_static:
			child.freeze = false
			child.mass = child.custom_mass
			child.set_color(child.custom_color)
	state = "PLAY"

func stop_simulation():
	for child in get_children():
		if child is RigidBody2D:
			child.freeze = true
			child.linear_velocity = Vector2.ZERO
			child.angular_velocity = 0
	state = "EDIT"

func pause_simulation():
	for child in get_children():
		if child is RigidBody2D:
			child.freeze = true
	state = "PAUSE"

func resume_simulation():
	for child in get_children():
		if child is RigidBody2D and not child.is_static:
			child.freeze = false

func on_play_pause_pressed():
	if state == "EDIT":
		start_simulation()
		state = "PLAY"
	elif state == "PLAY":
		pause_simulation()
		state = "PAUSE"
	else: 
		resume_simulation()
		state = "PLAY"
	update_ui()

func on_gravity_pressed(value):
	if value == true:
		gravity_button.text = "ГРАВИТАЦИЯ ВКЛ"
	else:
		gravity_button.text = "ГРАВИТАЦИЯ ВЫКЛ"
	for child in get_children():
		if child is RigidBody2D:
			child.gravity_scale = 1 if value else 0

func on_edit_pressed():
	if state == "PAUSE":
		stop_simulation()
		state = "EDIT"
		update_ui()

func on_speed_changed(value):
	Engine.time_scale = value 

func on_mass_changed(value):
	if selected_object is RigidBody2D:
		selected_object.custom_mass = value
		if state == "PAUSE" or state == "EDIT":
			selected_object.mass = value

func on_scale_changed(value):
	if selected_object:
		selected_object.custom_scale = value
		if selected_object.has_method("update_size"):
			selected_object.update_size()

func on_color_object_chanded(new_color):
	if selected_object:
		selected_object.custom_color = new_color
		if state == "PAUSE" or state == "EDIT":
			selected_object.set_color(new_color)

func on_static_toggled(toggled_on: bool):
	if selected_object:
		selected_object.set_static(toggled_on)
		if state == "PLAY":
			selected_object.freeze = toggled_on
		else:
			selected_object.freeze = true

func update_selected_link():
	if selected_link and is_instance_valid(selected_link["joint"]):
		var j = selected_link["joint"]
		
		if not auto_length_check.button_pressed:
			j.length = length_spin.value
			j.rest_length = length_spin.value
		
		# Обновляем жесткость, только если это пружина (у пружины stiffness обычно < 60)
		if j.stiffness < 60: 
			j.stiffness = stiffness_spin.value

func select_link(link):
	deselect_link() # Сброс старого выделения
	selected_link = link
	link["line"].default_color = Color.RED # Подсветка выбранной связи красным
	colision_objects.set_block_signals(true)
	colision_objects.button_pressed = link["collide"]
	colision_objects.set_block_signals(false)
	print("Выбрана связь")

func deselect_link():
	if selected_link and is_instance_valid(selected_link["line"]):
		selected_link["line"].default_color = Color.WHITE # Возврат обычного цвета
		colision_objects.set_block_signals(true)
	colision_objects.button_pressed = bodies_collide
	colision_objects.set_block_signals(false)
	selected_link = null

func update_spring_line(line: Line2D, a: Vector2, b: Vector2):
	var dir = b - a
	var length = dir.length()
	if length < 1.0: return
	
	var unit_dir = dir.normalized()
	var perp = Vector2(-unit_dir.y, unit_dir.x) # Перпендикуляр к линии связи
	
	var coil_width = 10.0  # Ширина (размах) витков пружины
	var segments = 12      # Количество сегментов (должно быть чётным)
	
	# Если точек у линии меньше или больше нужного — пересоздаем их
	if line.get_point_count() != segments + 1:
		line.clear_points()
		for i in range(segments + 1):
			line.add_point(Vector2.ZERO)
			
	# Начало и конец пружины жестко привязаны к объектам
	line.set_point_position(0, a)
	line.set_point_position(segments, b)
	
	# Промежуточные точки образуют зигзаг (витки)
	for i in range(1, segments):
		var t = float(i) / segments
		var base_pos = a + dir * t
		
		# Чередуем знак, чтобы точки уходили то влево, то вправо от центральной оси
		var sign_val = 1 if (i % 2 == 1) else -1
		
		# Делаем первые и последние витки чуть поуже для красоты, средние — полной ширины
		var current_width = coil_width
		if i == 1 or i == segments - 1:
			current_width = coil_width * 0.5
			
		line.set_point_position(i, base_pos + perp * current_width * sign_val)
