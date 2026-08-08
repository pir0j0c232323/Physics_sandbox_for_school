extends SubViewport

func _ready():
	size = Vector2i(1920, 1080)
	print("Размер установлен: ", size)
	
	# 2. Включаем обработку ввода
	handle_input_locally = true
	print("Обработка ввода: включена")
	
	# 3. Включаем прозрачный фон (если нужно)
	transparent_bg = true
	print("Прозрачный фон: включен")
	
	var camera = get_node("Node2D/Camera2D")
	if camera:
		camera.make_current
		camera.position = Vector2.ZERO
		print("Камера настроена в позиции: ", camera.position)
	
	var world_root = get_node("Node2D")
	if world_root:
		world_root.position = Vector2.ZERO
		print("Node2D настроен в позиции: ", world_root.position)
	
	# 7. Настраиваем SubViewportContainer
	var container = get_parent()
	if container is SubViewportContainer:
		container.stretch = true
		container.mouse_filter = Control.MOUSE_FILTER_STOP
		print("SubViewportContainer настроен")
	
	print("=== SubViewport полностью настроен! ===")
