extends Node

var grabbed_object = null
var is_dragging = false
var grab_offset
var original_layer = 1
var original_mask = 1

@onready var sim = $"../SimulationController"
@onready var spawner = $"../ObjectSpawner"
@onready var selection = $"../SelectionManager"
@onready var links = $"../LinkManager"
@onready var drawer = $"../Shape_drawer"

func _physics_process(_delta):
	if is_dragging == true and is_instance_valid(grabbed_object):
		grabbed_object.global_position = get_parent().get_global_mouse_position() + grab_offset
		apply_snapping()

func _unhandled_input(event):
	if drawer.is_active():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_parent().get_global_mouse_position()
		
		if event.double_click:
			if selection.try_delete_vertex(mouse_pos):
				return
			if selection.try_add_vertex(mouse_pos):
				return
		if selection.try_grab_handle(mouse_pos):
			return
		
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		var space_state = get_parent().get_world_2d().direct_space_state
		var result = space_state.intersect_point(query)
		
		if result.size() > 0:
			var clicked_object = result[0].collider
			if clicked_object is RigidBody2D:
				links.deselect_link()
				if Input.is_key_pressed(KEY_SHIFT):
					if clicked_object in selection.selected_objects:
						selection.deselect_single_object(clicked_object)
					else:
						selection.add_to_selection(clicked_object)
				else:
					selection.deselect_all_objects()
					selection.add_to_selection(clicked_object)
					start_grab(clicked_object)
				return
		
		var found_link = false
		for link in links.links_array:
			if is_instance_valid(link["a"]) and is_instance_valid(link["b"]):
				var dist = Geometry2D.get_closest_point_to_segment_uncapped(mouse_pos, link["a"].global_position, link["b"].global_position).distance_to(mouse_pos)
				if dist < 10.0:
					links.select_link(link)
					found_link = true
					break
		
		if not found_link:
			if links.selected_link != null or selection.selected_objects.size() != 0:
				links.deselect_link()
				selection.deselect_all_objects()
				return
			else:
				drawer.draw_tool = spawner.number_selected_object
				drawer.begin_draw(mouse_pos)
				#spawner.spawn_selected(mouse_pos)

	
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop_grab()
		selection.release_handle()
	
	if event.is_action_pressed("delete_all"):
		delete_all_objects()
	if event.is_action_pressed("delete_selected"):
		delete_selected_object()

func start_grab(object):
	if not sim.can_edit(): return
	elif grabbed_object == null:
		grabbed_object = object
		grab_offset = object.global_position - get_parent().get_global_mouse_position()
		grabbed_object.freeze = true
		original_layer = grabbed_object.collision_layer
		original_mask = grabbed_object.collision_mask
		grabbed_object.collision_layer = 0
		grabbed_object.collision_mask = 0
		is_dragging = true

func stop_grab():
	if is_dragging == true and grabbed_object != null and is_instance_valid(grabbed_object):
		grabbed_object.collision_layer = original_layer
		grabbed_object.collision_mask = original_mask
		if sim.state == "EDIT" or sim.state == "PAUSE" or grabbed_object.is_static:
			grabbed_object.freeze = true
		else:
			grabbed_object.freeze = false
		grabbed_object.linear_velocity = Vector2.ZERO
		grabbed_object.angular_velocity = 0
	is_dragging = false
	grabbed_object = null

func delete_all_objects():
	is_dragging = false
	grabbed_object = null
	for child in get_parent().get_children():
		if child is RigidBody2D:
			child.queue_free()
	selection.deselect_all_objects()
	print("Все объекты удалены!")

func delete_selected_object():
	for obj in selection.selected_objects:
		if is_instance_valid(obj):
			if obj == grabbed_object:
				is_dragging = false
				grabbed_object = null
			obj.queue_free()
	selection.selected_objects.clear()
	selection.selected_object = null
	selection.reset_inspector_ui()
	print("Выделенные объекты удалены!")

func get_dynamic_anchors(body: Node2D) -> Array:
	var anchors = []
	if not is_instance_valid(body): return anchors
	
	anchors.append(body.global_position) # Центр объекта
	
	for child in body.get_children():
		if child is Polygon2D:
			for p in child.polygon:
				# Используем global_position самого полигона для точности
				anchors.append(child.to_global(p))
		elif child.is_in_group("magnets"):
			anchors.append(child.global_position)
			
	return anchors
	
func apply_snapping():
	var snap_distance = 25.0
	var best_offset = Vector2.ZERO
	var min_dist = snap_distance
	var found_snap = false

	# Желаемая позиция объекта строго за мышкой
	var target_pos = get_parent().get_global_mouse_position() + grab_offset
	
	# Временно смещаем объект туда, куда хочет мышь, чтобы правильно посчитать точки
	grabbed_object.global_position = target_pos

	var other_bodies = get_parent().get_children()
	var my_anchors = get_dynamic_anchors(grabbed_object)

	for other_body in other_bodies:
		if other_body == grabbed_object or not (other_body is RigidBody2D): 
			continue
		
		var other_anchors = get_dynamic_anchors(other_body)
		
		for my_anchor in my_anchors:
			for other_anchor in other_anchors:
				var dist = my_anchor.distance_to(other_anchor)
				if dist < min_dist:
					min_dist = dist
					found_snap = true
					best_offset = other_anchor - my_anchor

	# Если нашли магнит, применяем смещение поверх позиции мыши
	if found_snap:
		grabbed_object.global_position = target_pos + best_offset
	else:
		grabbed_object.global_position = target_pos
