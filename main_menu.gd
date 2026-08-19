extends Control

@onready var background = $Background
@onready var video_player = $Panel/VideoStreamPlayer
@onready var scroll = $Panel/ScrollContainer
#текст 
@onready var themes =$Panel/theme
@onready var glavnii = $Background/name

var bg_bee = preload("res://texturs/Frame 2.png") 
var bg_peach = preload("res://texturs/white ui.png")
var bg_mint = preload("res://texturs/mint theme ui.png")
var bg_standart = preload("res://texturs/standart ui.png")
var bg_standartblack = preload("res://texturs/standarblackt ui.png")

func _ready():
	load_saved_theme()
	# Гарантируем, что меню всегда открывается в окне
	get_window().mode = Window.MODE_WINDOWED
	# Автоматически выставляем центр кнопок (ровно половина от их размера)
	$VBoxContainer/CreateButton.pivot_offset = $VBoxContainer/CreateButton.size / 2.0
	$NastroikiButton.pivot_offset = $NastroikiButton.size / 2.0
	$VBoxContainer/StoryButton.pivot_offset = $VBoxContainer/StoryButton.size / 2.0
	$VBoxContainer/LevelsButton.pivot_offset = $VBoxContainer/LevelsButton.size / 2.0
	
	# Твой код, который уже был написан:
	$VBoxContainer/StoryButton.pressed.connect(_on_story_button_pressed)
	$VBoxContainer/LevelsButton.pressed.connect(_on_levels_button_pressed)
	$NastroikiButton.pressed.connect(_on_nastroiki_button_pressed)
	$Panel/ScrollContainer/SettingsMenu/BeeButton.pressed.connect(_on_bee_theme_pressed)
	$Panel/ScrollContainer/SettingsMenu/PeachButton.pressed.connect(_on_peach_theme_pressed)
	$Panel/ScrollContainer/SettingsMenu/MintButton.pressed.connect(_on_mint_theme_pressed)
	$Panel/ScrollContainer/SettingsMenu/standart.pressed.connect(_on_standart_theme_pressed)
	$Panel/ScrollContainer/SettingsMenu/standartblack.pressed.connect(_on_standartblack_theme_pressed)
	# Наведение мыши на кнопку «СЮЖЕТ»
	$VBoxContainer/StoryButton.mouse_entered.connect(_on_story_button_mouse_entered)
	$VBoxContainer/StoryButton.mouse_exited.connect(_on_story_button_mouse_exited)
	
	# Наведение мыши на кнопку создать
	$VBoxContainer/CreateButton.mouse_entered.connect(_on_create_button_mouse_entered)
	$VBoxContainer/CreateButton.mouse_exited.connect(_on_create_button_mouse_exited)
	
	# Наведение мыши на кнопку «настройки»
	$NastroikiButton.mouse_entered.connect(_on_nastroiki_button_mouse_entered)
	$NastroikiButton.mouse_exited.connect(_on_nastroiki_button_mouse_exited)
	
	
	# Наведение мыши на кнопку «ВСЕ УРОВНИ»
	$VBoxContainer/LevelsButton.mouse_entered.connect(_on_levels_button_mouse_entered)
	$VBoxContainer/LevelsButton.mouse_exited.connect(_on_levels_button_mouse_exited)
	


func _on_story_button_pressed():
	print("Нажали на кнопку СЮЖЕТ!")

func _on_levels_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")



# === АНИМАЦИИ  ===

func _on_story_button_mouse_entered():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/StoryButton, "scale", Vector2(1.1, 1.1), 0.1)

func _on_story_button_mouse_exited():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/StoryButton, "scale", Vector2(1.0, 1.0), 0.1)

func _on_levels_button_mouse_entered():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/LevelsButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_levels_button_mouse_exited():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/LevelsButton, "scale", Vector2(1.0, 1.0), 0.1)
	
func _on_nastroiki_button_mouse_entered():
	var tween = create_tween()
	tween.tween_property($NastroikiButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_nastroiki_button_mouse_exited():
	var tween = create_tween()
	tween.tween_property($NastroikiButton, "scale", Vector2(1.0, 1.0), 0.1)
	
func _on_create_button_mouse_entered():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/CreateButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_create_button_mouse_exited():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/CreateButton, "scale", Vector2(1.0, 1.0), 0.1)
	

# === ЛОГИКА НАСТРОЕК И ТЕМ ===

func _on_nastroiki_button_pressed():
	var is_open = scroll.visible and themes.visible
	scroll.visible = !is_open 
	themes.visible = !is_open
	video_player.visible = is_open   
 
#ПРИМЕНЕНИЕ ТЕМ (Кнопки просто вызывают сохранение и саму тему)
func _on_bee_theme_pressed():
	save_theme("bee")
	apply_theme("bee")

func _on_peach_theme_pressed():
	save_theme("peach")
	apply_theme("peach")
		
func _on_mint_theme_pressed():
	save_theme("mint")
	apply_theme("mint")
	
func _on_standart_theme_pressed():
	save_theme("standart")
	apply_theme("standart")
	
func _on_standartblack_theme_pressed():
	save_theme("standartblack")
	apply_theme("standartblack")


# === УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ТЕМ (Пункт 4) ===
func apply_theme(theme_name: String):
	var target_color = Color("ffffffff")
	
	match theme_name:
		"bee":
			background.texture = bg_bee
			target_color = Color("000000ff")
		"peach":
			background.texture = bg_peach
			target_color = Color("FF5D60")
		"mint":
			background.texture = bg_mint
			target_color = Color("008f26ff")
		"standart":
			background.texture = bg_standart
			target_color = Color("000000ff")
		"standartblack":
			background.texture = bg_standartblack
			target_color = Color("ffffffff")
		_: # Дефолтный вариант на случай ошибки
			background.texture = bg_standart
			target_color = Color("000000ff")

	# Применяем цвет ко всем нужным элементам интерфейса
	if has_node("Background/name"):
		$Background/name.modulate = target_color
	if has_node("Panel/theme"):
		$Panel/theme.modulate = target_color


const CONFIG_PATH = "user://settings.cfg"

# Функция сохранения выбранной темы
func save_theme(theme_name: String):
	var config = ConfigFile.new()
	config.set_value("settings", "selected_theme", theme_name)
	config.save(CONFIG_PATH)

# Функция загрузки темы при старте
func load_saved_theme():
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var theme_name = config.get_value("settings", "selected_theme", "standart")
		apply_theme(theme_name)
	else:
		apply_theme("standart") # Если файла нет, ставим стандартную
		

	
