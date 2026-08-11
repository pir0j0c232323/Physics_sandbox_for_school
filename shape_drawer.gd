extends Node2D

enum State { IDLE, DRAW, ADJUST}
var state: State = State.IDLE

var draw_tool: int = 0
var first_point: Vector2 = Vector2.ZERO
var current_point: Vector2 = Vector2.ZERO

@onready var spawner = $"../ObjectSpawner"

func is_active() -> bool:
	return state != State.IDLE

func begin_draw(pos:Vector2):
	first_point = pos
	current_point = pos
	state = State.DRAW
	print("✏️ DRAW: начали с точки ", pos)

func _process(delta: float):
	if state == State.DRAW:
		current_point = get_global_mouse_position()

func _unhandled_input(event: InputEvent):
	if state == State.IDLE:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and state == State.DRAW:
			state = State.ADJUST
			print("🔧 ADJUST: призрак замер, можно править")
			
	if event.is_action_pressed("ui_cancel"):
		cancel()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if state == State.ADJUST:
			confirm()

func cancel():
	state = State.IDLE
	print("❌ Чертёж отменён")
	
func confirm():
	print("✅ СОЗДАТЬ: tool=", draw_tool, " p1=", first_point, " p2=", current_point)
	state = State.IDLE
