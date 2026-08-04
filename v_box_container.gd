extends VBoxContainer

@onready var menu_button: MenuButton = $HBoxContainer/MenuButton
@onready var mechanics_panel = $HBoxContainer/ToolsContainer/MechanicsPanel
@onready var molecular_panel = $HBoxContainer/ToolsContainer/MolecularPanel
@onready var electricity_panel = $HBoxContainer/ToolsContainer/ElectricityPanel

func _ready():
	
	# Получаем PopupMenu из MenuButton
	var popup = menu_button.get_popup()
	
	# Добавляем три пункта меню
	popup.add_item("Механика", 0)
	popup.add_item("Молекулярка", 1)
	popup.add_item("Электричество", 2)
	
	# Подключаем сигнал - когда выберут пункт меню
	popup.id_pressed.connect(_on_menu_selected)
	
	# По умолчанию показываем Механику
	_show_panel(0)

func _on_menu_selected(id):
	# id = 0 (Механика), 1 (Молекулярка), 2 (Электричество)
	_show_panel(id)

func _show_panel(index):
	# Скрываем все панели
	mechanics_panel.visible = false
	molecular_panel.visible = false
	electricity_panel.visible = false
	
	# Показываем нужную
	match index:
		0:
			mechanics_panel.visible = true
			print("Показана панель: Механика")
		1:
			molecular_panel.visible = true
			print("Показана панель: Молекулярка")
		2:
			electricity_panel.visible = true
			print("Показана панель: Электричество")
