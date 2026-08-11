extends Node2D

# Модули — вся логика теперь живёт в них
@onready var sim = $SimulationController
@onready var spawner = $ObjectSpawner
@onready var selection = $SelectionManager
@onready var links = $LinkManager
@onready var input_handler = $InputHandler
@onready var ui = $UIController

func _ready():
	print("🧩 Модули загружены: ", sim.name, spawner.name, selection.name, links.name, input_handler.name, ui.name)
