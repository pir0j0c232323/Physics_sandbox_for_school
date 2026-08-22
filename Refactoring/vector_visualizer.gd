extends Node2D

var show_vectors: bool = false

@export var velocity_scale: float = 0.25
@export var force_scale: float = 0.05 
@export var min_speed: float = 2.0

var vel_color: Color = Color(0.1, 0.9, 0.3, 0.9)
var gravity_color: Color = Color(0.2, 0.6, 1.0, 0.9)
var spring_color: Color = Color(1.0, 0.4, 0.1, 0.9)

# Кэш для сохранения скоростей
var last_velocities: Dictionary = {}

# !!! ВСТАВЬ СВОЙ ПУТЬ К КНОПКЕ "Векто" В КАВЫЧКИ НИЖЕ !!!
@onready var vector_button = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/VectorButton"
@onready var link_manager = $"../LinkManager"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if vector_button:
		vector_button.toggled.connect(_on_vector_button_toggled)

func _on_vector_button_toggled(button_pressed: bool):
	show_vectors = button_pressed
	queue_redraw()

func _process(_delta):
	if show_vectors:
		queue_redraw()

# Новая функция: следим за физикой каждый кадр движка
func _physics_process(_delta):
	if not show_vectors:
		return
		
	var is_global_pause = get_tree().paused or Engine.time_scale == 0.0
	var all_bodies = get_tree().root.find_children("*", "RigidBody2D", true, false)
	
	for obj in all_bodies:
		if is_instance_valid(obj):
			# Запоминаем скорость, ТОЛЬКО если объект движется и не заморожен
			if not is_global_pause and not obj.freeze:
				last_velocities[obj] = obj.linear_velocity

func _draw():
	if not show_vectors:
		return
		
	var gravity_val = ProjectSettings.get_setting("physics/2d/default_gravity")
	var is_global_pause = get_tree().paused or Engine.time_scale == 0.0
	var all_bodies = get_tree().root.find_children("*", "RigidBody2D", true, false)
	
	for obj in all_bodies:
		if not is_instance_valid(obj):
			continue
			
		var global_pos = obj.global_position
		# Считаем объект замороженным, если нажата глобальная пауза ИЛИ он сам получил freeze
		var is_frozen = obj.freeze or is_global_pause
		
		# --- 1. ВЕКТОР СКОРОСТИ ---
		var vel = obj.linear_velocity
		
		# Если объект на паузе, достаем его скорость из нашей "памяти"
		if is_frozen and last_velocities.has(obj):
			vel = last_velocities[obj]
		
		if vel.length() >= min_speed:
			var speed_val = snapped(vel.length(), 1.0) # Округляем до целых
			_draw_arrow(global_pos, vel * velocity_scale, vel_color, "v = " + str(speed_val) + " px/s")
		
		# --- 2. ВЕКТОР СИЛЫ ТЯЖЕСТИ ---
		var fg_vector = Vector2(0, obj.mass * gravity_val)
		var fg_value = snapped(obj.mass * gravity_val / 100.0, 0.1) # Округляем до десятых
		var fg_label = "Fg = " + str(fg_value) + " Н"
		_draw_arrow(global_pos, fg_vector * force_scale, gravity_color, fg_label)

	# --- 3. СИЛЫ УПРУГОСТИ ПРУЖИН ---
	if link_manager and "links_array" in link_manager:
		for link in link_manager.links_array:
			if link.get("is_spring", false) and is_instance_valid(link.get("joint")):
				var joint = link["joint"]
				var body_a = link.get("a")
				var body_b = link.get("b")
				
				if is_instance_valid(body_a) and is_instance_valid(body_b):
					var pos_a = body_a.to_global(link["local_a"])
					var pos_b = body_b.to_global(link["local_b"])
					
					var current_len = pos_a.distance_to(pos_b)
					var rest_len = joint.rest_length
					var delta_x = current_len - rest_len
					var f_magnitude = joint.stiffness * delta_x
					
					if abs(f_magnitude) > 1.0:
						var dir_a_to_b = (pos_b - pos_a).normalized()
						
						# Гарантированное преобразование в число с одним знаком после запятой
						var f_val = snapped(abs(f_magnitude) / 100.0, 0.1)
						var f_label = "Fупр = " + str(f_val) + " Н"
						
						if body_a is RigidBody2D:
							_draw_arrow(pos_a, dir_a_to_b * f_magnitude * force_scale, spring_color, f_label)
						if body_b is RigidBody2D:
							_draw_arrow(pos_b, -dir_a_to_b * f_magnitude * force_scale, spring_color, f_label)

func _draw_arrow(global_start: Vector2, vec: Vector2, color: Color, label: String):
	if vec.length() < 2.0:
		return
		
	var start_pos = to_local(global_start)
	var end_pos = start_pos + vec
	
	draw_line(start_pos, end_pos, color, 3.0)
	
	var angle = vec.angle()
	var arrow_size = 10.0
	var p1 = end_pos
	var p2 = end_pos + Vector2(-arrow_size, -arrow_size * 0.5).rotated(angle)
	var p3 = end_pos + Vector2(-arrow_size, arrow_size * 0.5).rotated(angle)
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)
	
	draw_string(ThemeDB.fallback_font, end_pos + Vector2(6, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
