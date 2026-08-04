extends Node2D

var new_ball = preload("res://rigid_body_2d.tscn")
var new_rectangle = preload("res://прямоугольник.tscn")
var new_triangle = preload("res://треугольник.tscn")
var selected_object = null
var number_selected_object = 0

func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Подключаем кнопки (пути могут отличаться, проверь свои!)
	var button_ball = $"../CanvasLayer/VBoxContainer/TopPanel/HBoxContainer/CircleButton"
	var button_rectangle = $"../CanvasLayer/VBoxContainer/TopPanel/HBoxContainer/RectangleButton"
	var button_triangle = $"../CanvasLayer/VBoxContainer/TopPanel/HBoxContainer/TriangleButton"
	
	if button_ball:
		button_ball.pressed.connect(_button_pressed.bind(0))
	if button_rectangle:
		button_rectangle.pressed.connect(_button_pressed.bind(1))
	if button_triangle:
		button_triangle.pressed.connect(_button_pressed.bind(2))

func _button_pressed(type):
	number_selected_object = type
	print("Выбран тип: ", type)

func handle_left_click():
	var world_pos = get_global_mouse_position()
	
	# Проверяем что под мышкой
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(query)
	
	# Круг
	if number_selected_object == 0:
		if result.size() == 0:
			create_object(new_ball, world_pos)
		else:
			handle_click_on_object(result)
	
	# Прямоугольник
	elif number_selected_object == 1:
		if result.size() == 0:
			create_object(new_rectangle, world_pos)
		else:
			handle_click_on_object(result)
	
	# Треугольник
	elif number_selected_object == 2:
		if result.size() == 0:
			create_object(new_triangle, world_pos)
		else:
			handle_click_on_object(result)

func create_object(scene, position):
	var new_object = scene.instantiate()
	new_object.position = position
	
	var random_color = Color(randf(), randf(), randf(), 1)
	if new_object.has_method("set_color"):
		new_object.set_color(random_color)
	
	add_child(new_object)
	print("Объект создан в позиции: ", position)

func handle_click_on_object(result):
	var clicked_object = result[0].collider
	if clicked_object is RigidBody2D:
		select_object(clicked_object)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click()
	
	# Ctrl+Delete: Удаление всех
	if event.is_action_pressed("delete_all"):
		for child in get_children():
			if child is RigidBody2D:
				child.queue_free()
		selected_object = null
		print("Все объекты удалены!")
	
	# Delete: Удаление выделенного
	if event.is_action_pressed("delete_selected"):
		if selected_object != null:
			selected_object.queue_free()
			selected_object = null
			print("Объект удалён!")

func select_object(object):
	if selected_object != null and is_instance_valid(selected_object):
		selected_object.deselect_object()
	
	selected_object = object
	selected_object.select_object()
	print("Объект выделен")

func object_clicked(object):
	select_object(object)

func ball_clicked(object):
	select_object(object)
