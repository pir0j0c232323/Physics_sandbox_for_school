extends Node

# Прелоады сцен
var new_ball = preload("res://сцены обьектов + их скрипты/круг.tscn")
var new_rectangle = preload("res://сцены обьектов + их скрипты/прямоугольник.tscn")
var new_triangle = preload("res://сцены обьектов + их скрипты/треугольник.tscn")

# Какая фигура выбрана для спавна
var number_selected_object = 0

@onready var drawer = $"../Shape_drawer"
@onready var sim = $"../SimulationController"
@onready var circle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/CircleButton
@onready var rectangle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/RectangleButton
@onready var triangle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/TriangleButton
@onready var gravity_button = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/World/GRAVITY

func _ready():
	if circle_button:
		circle_button.pressed.connect(_on_circle_pressed)
	if rectangle_button:
		rectangle_button.pressed.connect(_on_rectangle_pressed)
	if triangle_button:
		triangle_button.pressed.connect(_on_triangle_pressed)

func _on_circle_pressed():
	number_selected_object = 0
	print("Выбран: Круг")

func _on_rectangle_pressed():
	number_selected_object = 1
	print("Выбран: Прямоугольник")

func _on_triangle_pressed():
	number_selected_object = 2
	print("Выбран: Треугольник")

# Удобная обёртка: «создай то, что выбрано» — ей будет пользоваться ввод
func spawn_selected(position):
	create_object(number_selected_object, position)

func create_object(type, position):
	if not sim.can_edit():
		return
	var scene
	match type:
		0: scene = new_ball
		1: scene = new_rectangle
		2: scene = new_triangle
	
	if scene:
		var new_object = scene.instantiate()
		new_object.position = position
		get_parent().add_child(new_object)  # ВАЖНО: в Main, не в спавнер!
		new_object.mass = new_object.custom_mass
		new_object.set_color(new_object.custom_color)
		new_object.update_size()
		new_object.freeze = true
		new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
		print("Объект создан в позиции: ", position)
