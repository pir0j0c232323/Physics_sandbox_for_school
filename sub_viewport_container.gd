extends SubViewportContainer

# Сюда в Инспекторе перетащишь сцену шарика, когда тест пройдет
@export var ball_scene: PackedScene 

func _ready():
	# Гарантируем, что контейнер ловит мышь
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("Контейнер готов ловить клики!")

func _gui_input(event):
	# Проверяем, что это именно клик левой кнопкой мыши
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("=== ПОЙМАЛ КЛИК! ===")
		
		# Находим наш мир внутри
		var world_root = $SubViewport/Node2D
		if world_root == null:
			print("ОШИБКА: Node2D не найден!")
			return
		
		# Для начала создадим ПРОСТОЙ КРАСНЫЙ КВАДРАТ, чтобы исключить баги шарика
		var test_obj = ColorRect.new()
		test_obj.color = Color.RED
		test_obj.size = Vector2(100, 100)
		
		# Ставим его ровно туда, где кликнули (минус 50, чтобы центр квадрата был под курсором)
		test_obj.position = event.position - Vector2(50, 50)
		
		# Добавляем в мир
		world_root.add_child(test_obj)
		print("КРАСНЫЙ КВАДРАТ СОЗДАН В ПОЗИЦИИ: ", test_obj.position)
