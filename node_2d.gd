extends Node2D

func _ready():
	print("Main запустился!")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("=== КЛИК МЫШЬЮ ===")
		
		# Получаем узлы
		var sub_viewport = $".."
		var world_root = $"."
		var camera = $Camera2D
		
		print("SubViewport найден: ", sub_viewport != null)
		print("WorldRoot найден: ", world_root != null)
		print("Camera найден: ", camera != null)
		
		# Получаем позицию мыши в координатах SubViewport
		var mouse_in_viewport = sub_viewport.get_mouse_position()
		print("Позиция мыши в SubViewport: ", mouse_in_viewport)
		
		# Создаем ПРОСТОЙ ColorRect (гарантированно видимый!)
		var test_object = ColorRect.new()
		test_object.color = Color.RED
		test_object.size = Vector2(100, 100)  # Большой размер чтобы точно видеть
		test_object.position = mouse_in_viewport - Vector2(50, 50)  # Центрируем по клику
		
		print("Создаем объект в позиции: ", test_object.position)
		print("Добавляем в: ", world_root.get_path())
		
		world_root.add_child(test_object)
		
		print("ОБЪЕКТ ДОБАВЛЕН!")
		print("Дочерние узлы WorldRoot: ", world_root.get_children())
