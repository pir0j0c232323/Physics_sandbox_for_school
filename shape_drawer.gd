extends Node2D

enum State { IDLE, DRAW, ADJUST}
var state: State = State.IDLE

var draw_tool: int = 0
var first_point: Vector2 = Vector2.ZERO
var current_point: Vector2 = Vector2.ZERO
var defolt_punctir_color: Color = Color.AZURE
var defolt_punctir_tolshina: float = 2.0
var defolt_prizrac_color: Color = Color(1, 1, 1, 0.3)
var defolt_prizrak_tolshina = 5

@onready var spawner = $"../ObjectSpawner"

func is_active() -> bool:
	return state != State.IDLE

func begin_draw(pos:Vector2):
	first_point = pos
	current_point = pos
	state = State.DRAW
	visible = true
	print("✏️ DRAW: начали с точки ", pos)

func _process(delta: float):
	if state == State.DRAW:
		current_point = get_global_mouse_position()
		queue_redraw()
	elif state == State.IDLE:
		visible = false

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

func _draw():
	print(" draw вызван")
	if draw_tool == 0:
		var radius = first_point.distance_to(current_point)
		var napravlenie = (current_point - first_point).normalized()
		var t = 0.0
		while  t < radius:
			var nachalo = first_point + napravlenie*t
			var konec = first_point + napravlenie*min(t+10.0, radius)
			draw_line(nachalo, konec, defolt_punctir_color, defolt_punctir_tolshina)
			t += 10.0 + 6.0
		var points = PackedVector2Array()
		for i in range(48):
			var angle = i / 48.0 * TAU
			points.append(first_point + Vector2(cos(angle), sin(angle))*radius)
		draw_colored_polygon(points, defolt_prizrac_color)         
		draw_arc(first_point,radius, 0, TAU, 48, defolt_prizrac_color, defolt_prizrak_tolshina)
		var center_of_radius = (first_point + current_point)/2
		var text_radius = "R = %.2f" % radius
		draw_string(ThemeDB.fallback_font, center_of_radius + Vector2(8, -8), text_radius, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		
