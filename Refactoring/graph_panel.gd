extends Control

# Настройки графика
@export var max_data_points: int = 200 # Сколько точек хранится в истории
@export var update_interval: float = 0.05 # Интервал обновления (в секундах)

var time_accumulator: float = 0.0
var data_history: Array[float] = []

# Цвет элементов
var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
var axis_color: Color = Color(0.7, 0.7, 0.7, 0.8)
var line_color: Color = Color(0.0, 0.9, 1.0, 1.0) # Голубая линия графика

# Ссылки на внешние менеджеры
@onready var selection_manager = $"../../../../SelectionManager"
@onready var link_manager = $"../../../../LinkManager"
@onready var param_selector = $"../HBoxContainer/ParamSelector"
@onready var clear_button = $"../HBoxContainer/ClearButton"

# Выбранный режим: 0 = Скорость v(t), 1 = Позиция Y(t), 2 = Сила пружины F(t)
var selected_mode: int = 0 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Заполняем выпадающий список
	if param_selector:
		param_selector.clear()
		param_selector.add_item("Скорость v(t)")
		param_selector.add_item("Высота Y(t)")
		param_selector.add_item("Сила упругости Fупр(t)")
		param_selector.add_item("Сила тяжести Fmg(t)")
		param_selector.item_selected.connect(_on_param_selected)
		
	if clear_button:
		clear_button.pressed.connect(clear_data)

func _on_param_selected(index: int):
	selected_mode = index
	clear_data()

func clear_data():
	data_history.clear()
	queue_redraw()

func _process(delta):
	# Не записываем данные во время глобальной паузы
	if get_tree().paused or Engine.time_scale == 0.0:
		return
		
	time_accumulator += delta
	if time_accumulator >= update_interval:
		time_accumulator = 0.0
		_collect_data_point()
		queue_redraw()

func _collect_data_point():
	var new_val: float = 0.0
	var has_valid_target: bool = false
	
	# 1. Если выделена ПРУЖИНА (через link_manager)
	if link_manager and link_manager.selected_link != null:
		var link = link_manager.selected_link
		if link.get("is_spring", false) and is_instance_valid(link.get("joint")):
			var joint = link["joint"]
			var pos_a = link["a"].to_global(link["local_a"])
			var pos_b = link["b"].to_global(link["local_b"])
			var delta_x = pos_a.distance_to(pos_b) - joint.rest_length
			var f_spring = joint.stiffness * delta_x
			
			if selected_mode == 2: # F(t)
				new_val = abs(f_spring) / 100.0
			elif selected_mode == 1: # Y(t)
				new_val = delta_x
			else: # v(t)
				new_val = abs(f_spring)
			has_valid_target = true
			
	# 2. Если выделена ФИГУРА (через selection_manager)
	elif selection_manager and "selected_object" in selection_manager:
		var obj = selection_manager.selected_object
		if is_instance_valid(obj) and obj is RigidBody2D:
			if selected_mode == 0: # Скорость v(t)
				new_val = obj.linear_velocity.length()
			elif selected_mode == 1: # Высота Y(t)
				new_val = -obj.global_position.y
			elif selected_mode == 3: # Сила тяжести Fg(t) (НАШ НОВЫЙ ИНДЕКС!)
				# Формула: Масса * Гравитацию. Делим на 100 для удобного масштаба.
				new_val = obj.mass * ProjectSettings.get_setting("physics/2d/default_gravity") / 100.0
			has_valid_target = true
			
	if has_valid_target:
		data_history.append(new_val)
		if data_history.size() > max_data_points:
			data_history.pop_front()

func _draw():
	var rect_size = size
	
	# --- 1. Фон и сетка ---
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.1, 0.1, 0.12, 0.85), true)
	draw_rect(Rect2(Vector2.ZERO, rect_size), axis_color, false, 1.5)
	
	# Горизонтальная центральная линия / сетка
	var grid_lines = 4
	for i in range(1, grid_lines):
		var y = (rect_size.y / grid_lines) * i
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), grid_color, 1.0)
		
	if data_history.size() < 2:
		draw_string(ThemeDB.fallback_font, Vector2(10, rect_size.y / 2), "Выделите объект или пружину...", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
		return

	# --- 2. Поиск Мин/Макс для масштабирования ---
	var min_val = data_history.min()
	var max_val = data_history.max()
	
	# Защита от деления на 0 при константном значении
	if abs(max_val - min_val) < 0.001:
		max_val += 1.0
		min_val -= 1.0
		
	var padding = (max_val - min_val) * 0.1
	max_val += padding
	min_val -= padding

	# --- 3. Отрисовка линии графика ---
	var step_x = rect_size.x / float(max_data_points - 1)
	var points = PackedVector2Array()
	
	for i in range(data_history.size()):
		var val = data_history[i]
		# Перевод значения в координату Y контейнера
		var norm_y = (val - min_val) / (max_val - min_val)
		var pixel_y = rect_size.y - (norm_y * rect_size.y)
		var pixel_x = i * step_x
		points.append(Vector2(pixel_x, pixel_y))

	if points.size() > 1:
		draw_polyline(points, line_color, 2.0)

	# --- 4. Текстовые подписи текущих значений ---
	var last_val = data_history.back()
	var val_text = "Сейчас: " + str(snapped(last_val, 0.1))
	var max_text = "Макс: " + str(snapped(max_val, 0.1))
	var min_text = "Мин: " + str(snapped(min_val, 0.1))
	
	draw_string(ThemeDB.fallback_font, Vector2(5, 15), max_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)
	draw_string(ThemeDB.fallback_font, Vector2(5, rect_size.y - 5), min_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)
	draw_string(ThemeDB.fallback_font, Vector2(rect_size.x - 90, 15), val_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, line_color)
