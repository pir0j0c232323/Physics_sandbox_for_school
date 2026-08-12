extends Node2D

enum State { IDLE, DRAW, ADJUST}
var state: State = State.IDLE

var draw_tool: int = 0
var first_point: Vector2 = Vector2.ZERO
var current_point: Vector2 = Vector2.ZERO
var pen_position: Vector2 = Vector2.ZERO
var defolt_punctir_color: Color = Color.AZURE
var defolt_punctir_tolshina: float = 2.0
var defolt_prizrac_color: Color = Color(1, 1, 1, 0.3)
var defolt_prizrak_tolshina = 5

var first_point_of_object 
var second_point_of_object 
var thirt_point_of_object 
var fourth_point_of_object

var is_adjusting = false

@onready var spawner = $"../ObjectSpawner"
@onready var selection = $"../SelectionManager"

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
	elif state == State.ADJUST and is_adjusting == true:
		current_point = get_global_mouse_position()
		queue_redraw()

func _unhandled_input(event: InputEvent):
	if state == State.IDLE:
		return
		
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and state == State.DRAW:
			state = State.ADJUST
			print("🔧 ADJUST: призрак замер, можно править")
			
		if event.pressed and state == State.ADJUST:
			var distance_to_pen = get_global_mouse_position().distance_to(pen_position)
			if distance_to_pen <= 12:
				is_adjusting = true
		else:
			is_adjusting = false
	
	if event.is_action_pressed("ui_cancel"):
		cancel()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if state == State.ADJUST:
			confirm()


func cancel():
	state = State.IDLE
	print("❌ Чертёж отменён")

func confirm():
	if draw_tool == 0:
		var distance = first_point.distance_to(current_point)
		if distance<0.01:
			print("⚠️ Слишком маленький - пропускаю")
			state = State.IDLE
			return
		var obj = spawner.create_circle(first_point, distance)
		selection.add_to_selection(obj)
		print("✅ СОЗДАТЬ: tool=", draw_tool, " p1=", first_point, " p2=", current_point)
	elif draw_tool == 1:
		var W = abs(current_point.x - first_point.x)
		var H = abs(current_point.y - first_point.y)
		if W < 5 or H < 5:
			print("⚠️ Слишком маленький - пропускаю")
			state = State.IDLE
			return
		var obj = spawner.create_rectangle(first_point, current_point)
		selection.add_to_selection(obj)
	state = State.IDLE
	

#func draw_punktir_for_object():
	#while  t < radius:
			#var nachalo = first_point + napravlenie*t
			#var konec = first_point + napravlenie*min(t+10.0, radius)
			#draw_line(nachalo, konec, defolt_punctir_color, defolt_punctir_tolshina)
			#t += 10.0 + 6.0

func _draw():
	print(" draw вызван")
	if draw_tool == 0:
		var radius = first_point.distance_to(current_point)
		var napravlenie = (current_point - first_point).normalized()
		var t = 0.0
		#draw_punktir_for_object()
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
		pen_position = first_point + (napravlenie*radius)
		draw_circle(pen_position, 6, Color.WHITE)
	elif draw_tool == 1:
		var dioganal = first_point.distance_to(current_point)
		var napravlenie = (current_point - first_point).normalized()
		var t = 0.0
		#draw_punktir_for_object()
		while  t < dioganal:
			var nachalo = first_point + napravlenie*t
			var konec = first_point + napravlenie*min(t+10.0, dioganal)
			draw_line(nachalo, konec, defolt_punctir_color, defolt_punctir_tolshina)
			t += 10.0 + 6.0
		var points = PackedVector2Array()
		first_point_of_object = first_point
		second_point_of_object = Vector2(first_point.x, current_point.y)
		thirt_point_of_object = current_point
		fourth_point_of_object = Vector2(current_point.x, first_point.y)
		points.append(first_point_of_object)
		points.append(second_point_of_object)
		points.append(thirt_point_of_object)
		points.append(fourth_point_of_object)
		draw_colored_polygon(points, defolt_prizrac_color)
		points.append(points[0]) 
		draw_polyline(points, Color(1, 1, 1, 0.6), 2.0)
		var w = second_point_of_object.distance_to(thirt_point_of_object)
		var h = first_point_of_object.distance_to(second_point_of_object)
		var center_of_w = (second_point_of_object + thirt_point_of_object) / 2
		var center_of_h = (first_point_of_object + second_point_of_object) / 2
		var text_w = "W = %.2f" % w
		var text_h = "H = %.2f" % h
		draw_string(ThemeDB.fallback_font, center_of_h + Vector2(8, -8), text_h, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		draw_string(ThemeDB.fallback_font, center_of_w + Vector2(8, -8), text_w, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		pen_position = first_point + (napravlenie*dioganal)
		draw_circle(pen_position, 6, Color.WHITE)
