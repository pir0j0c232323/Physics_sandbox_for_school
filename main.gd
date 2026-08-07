extends Node2D

# Прелоады сцен
var new_ball = preload("res://rigid_body_2d.tscn")
var new_rectangle = preload("res://прямоугольник.tscn")
var new_triangle = preload("res://треугольник.tscn")

# Текущий выбранный тип объекта
var number_selected_object = 0
var selected_object = null
var grabbed_object = null
var is_dragging = false
var grab_offset
var original_layer = 1
var original_mask = 1
var state = "EDIT"

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
@onready var edit_button =$CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/edit_button
@onready var speed_slider =$CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/HSlider
# Кнопки параметра мира
@onready var gravity_button = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/World/GRAVITY
# Кнопки параметра обьектов
@onready var Mass_SpinBox = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/SpinBox
@onready var Scale_SpinBox = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Scale_SpinBox
@onready var Color_picedbuton_object = $CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ColorPickerButton

func _ready():
	# === НАСТРОЙКА МЕНЮ ===
	menu_button.custom_minimum_size = Vector2(60, 60)
	menu_button.text = "☰"
	print("Слайдер: ", speed_slider)
	

	# === ПОДКЛЮЧЕНИЕ КНОПОК  ===
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
	# кнопки панели обьектов
	if Mass_SpinBox:
		Mass_SpinBox.value_changed.connect(on_mass_changed)
	if Scale_SpinBox:
		Scale_SpinBox.value_changed.connect(on_scale_changed)
	if Color_picedbuton_object:
		Color_picedbuton_object.color_changed.connect(on_color_object_chanded)
	
	
	# Показываем механику по умолчанию
	_show_panel(0)
	update_ui()

func _on_menu_selected(id):
	_show_panel(id)

func _show_panel(index):
	mechanics_panel.visible = (index == 0)
	molecular_panel.visible = (index == 1)
	electricity_panel.visible = (index == 2)

# === ОБРАБОТЧИКИ КНОПОК ===
func _on_circle_pressed():
	number_selected_object = 0
	print("Выбран: Круг")

func _on_rectangle_pressed():
	number_selected_object = 1
	print("Выбран: Прямоугольник")

func _on_triangle_pressed():
	number_selected_object = 2
	print("Выбран: Треугольник")

# === ФИЗИЧЕСКОЕ ДВИЖЕНИЕ ===
func _physics_process(delta: float) -> void:
	var world_pos = get_global_mouse_position()
	if is_dragging == true and is_instance_valid(grabbed_object):
		grabbed_object.global_position = world_pos + grab_offset
		
	for child in get_children():
		if child is RigidBody2D:
			print("Кадр | name=", child.name, " scale=", child.scale)

# === ОБРАБОТКА КЛИКОВ ПО МИРУ ===
func _unhandled_input(event: InputEvent):
	# Левый клик мыши
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_left_click()
	#отпускание левой кнопки мышки
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop_grab()
	# Удаление объектов
	if event.is_action_pressed("delete_all"):
		delete_all_objects()
	if event.is_action_pressed("delete_selected"):
		delete_selected_object()
	if event.is_action_pressed("ui_cancel"):
		deselect_object()

func handle_left_click():
	var world_pos = get_global_mouse_position()
	
	# Проверяем что под курсором
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(query)
	
	# Если ничего нет — создаём объект
	if not can_edit(): return
	elif result.size() == 0:
		create_object(number_selected_object, world_pos)
	else:
		# Если кликнули на объект — выделяем его
		var clicked_object = result[0].collider
		if clicked_object is RigidBody2D:
			select_object(clicked_object)
			start_grab(clicked_object)

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
		
		# Случайный цвет
		var random_color = Color(randf(), randf(), randf(), 1)
		if new_object.has_method("set_color"):
			new_object.set_color(random_color)
		
		add_child(new_object)
		new_object.mass = new_object.custom_mass
		new_object.scale = Vector2(new_object.custom_scale, new_object.custom_scale)
		new_object.set_color(new_object.custom_color)
		new_object.freeze = true
		new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
		print("Объект создан в позиции: ", position, "МАССА", new_object.mass)

func select_object(object):
	deselect_object()
	selected_object = object
	print("Выделен объект, его custom_scale =", object.custom_scale)
	selected_object.select_object()
	
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	
	Mass_SpinBox.value = object.custom_mass
	Scale_SpinBox.value = object.custom_scale
	Color_picedbuton_object.color = object.custom_color
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)
	
	print("Объект выделен")
	right_tabs.current_tab = 1 #обьекты

func deselect_object():
	if selected_object != null and is_instance_valid(selected_object):
		selected_object.deselect_object()
	selected_object = null
	right_tabs.current_tab = 0 #мир
	
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	
	Mass_SpinBox.value = 0
	Scale_SpinBox.value = 0
	Color_picedbuton_object.color = Color.WHITE
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)

func object_clicked(object):
	select_object(object)

func ball_clicked(object):
	select_object(object)

func delete_all_objects():
	is_dragging = false
	grabbed_object = null
	for child in get_children():
		if child is RigidBody2D:
			child.queue_free()
	selected_object = null
	print("Все объекты удалены!")

func delete_selected_object():
	if selected_object != null:
		if selected_object == grabbed_object:
			is_dragging = false
			grabbed_object = null
		selected_object.queue_free()
		selected_object = null
		print("Объект удалён!")

func start_grab(object):
	if not can_edit(): return
	elif grabbed_object == null:
		grabbed_object = object
		grab_offset = object.global_position - get_global_mouse_position()
		grabbed_object.freeze = true
		#исходная колизия
		original_layer = grabbed_object.collision_layer
		original_mask = grabbed_object.collision_mask
		#призрак
		grabbed_object.collision_layer = 0
		grabbed_object.collision_mask = 0
		is_dragging = true

func stop_grab():
	if is_dragging == true and grabbed_object != null and is_instance_valid(grabbed_object):
		grabbed_object.collision_layer = original_layer
		grabbed_object.collision_mask = original_mask
		if state == "EDIT":
			selected_object.freeze = true
		else:
			grabbed_object.freeze = false
		grabbed_object.linear_velocity = Vector2.ZERO
		grabbed_object.angular_velocity = 0
	is_dragging = false
	grabbed_object = null

# /// Отрисовщик кнопок на ui ///
func update_ui():
	if state == "PLAY":
		play_pause_button.text = "⏸️"
		play_pause_button.add_theme_color_override("font_color",Color.YELLOW)
		
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color",Color.WEB_GRAY)
	elif state == "PAUSE":
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color",Color.LIME_GREEN)
		
		edit_button.disabled = false
		edit_button.text = "🔧"
		edit_button.add_theme_color_override("font_color",Color.WHITE)
	else:
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color",Color.BLUE)
		
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color",Color.WEB_GRAY)
# /// СИМУЛЯЦИИ /// 
func start_simulation():
	if is_dragging == true and is_instance_valid(grabbed_object):
		stop_grab()
	for child in get_children():
		if child is RigidBody2D and not child.is_static:
			child.freeze = false
			child.mass = child.custom_mass
			#child.scale = Vector2(child.custom_scale, child.custom_scale)
			# Синхронизируем дочерние визуальные узлы с родительским scale
			for visual_child in child.get_children():
				if visual_child is Polygon2D or visual_child is Sprite2D:
					visual_child.scale = Vector2(child.custom_scale, child.custom_scale)
			print("После применения scale =", child.scale)
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
			child.freeze = true # НЕ обнуляем скорости!
			state = "PAUSE"    

func resume_simulation():
	for child in get_children():
		if child is RigidBody2D:
			child.freeze = false

func on_play_pause_pressed():
	if state == "EDIT":
		start_simulation() #EDIT→PLAY
		state = "PLAY"
	elif state == "PLAY":
		pause_simulation() #PLAY→PAUSE
		state = "PAUSE"
	else: 
		resume_simulation() #PAUSE→PLAY
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
		stop_simulation() #PAUSE→EDIT
		state = "EDIT"
		update_ui()

func on_speed_changed(value):
	Engine.time_scale = value 

func on_mass_changed(value):
	if selected_object is RigidBody2D:
		selected_object.custom_mass = value
		print("🟡 on_mass_changed сработал! value =", value)
		if state == "PAUSE" or state == "EDIT":
			selected_object.mass = value

func on_scale_changed(value):
	if selected_object:
		selected_object.custom_scale = value
		print("Scale изменён: custom_scale =", selected_object.custom_scale)
		print("🔴 on_scale_changed сработал! value =", value)
		if state == "PAUSE" or state == "EDIT":
			selected_object.scale = Vector2(value, value)

func on_color_object_chanded(new_color):
	if selected_object:
		selected_object.custom_color = new_color
		print("🔵 on_color сработал! color =", new_color)
		if state == "PAUSE" or state == "EDIT":
			selected_object.set_color(new_color)


# /// ТАБЛИЦА СОСТОЯНИЙ ///
func can_edit():
	return state == "EDIT" or state == "PAUSE"
