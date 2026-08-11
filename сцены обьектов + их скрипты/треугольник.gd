extends RigidBody2D

@export var is_static = false
@export var custom_mass = 1.0
@export var custom_color = Color.WHITE
@export var custom_scale = 1.0

const OUTLINE_WIDTH = 4.0
const DEBUG_OUTLINE = true

var is_selected = false
var selection_outline = null
var orig_color

func _ready() -> void:
	orig_color = custom_color
	$Polygon2D.modulate = orig_color
	
	


func set_static(value: bool):
	is_static = value
	refresh_outline()
	
func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().object_clicked(self)

func _base_size() -> float:
	var min_x: float = INF
	var max_x: float = -INF
	for p in $Polygon2D.polygon:
		if p.x < min_x:
			min_x = p.x
		if p.x > max_x:
			max_x = p.x
	return max_x - min_x

func _outline_add() -> float:
	return (2.0 * OUTLINE_WIDTH) / _base_size()

func refresh_outline():
	if selection_outline == null:
		print("RECT: обводка ещё не создана!")
		return
	var add = _outline_add()
	selection_outline.scale = Vector2($Polygon2D.scale.x + add, $Polygon2D.scale.y + add)
	if DEBUG_OUTLINE:
		if is_static:
			selection_outline.modulate = Color.RED # Если статичный - красная обводка
		else:
			selection_outline.modulate = Color(1, 1, 0) # Если обычный - желтая обводка
		#print("RECT base=", _base_size(), " add=", add, " scale=", $Polygon2D.scale)

func update_size():
	$Polygon2D.scale = Vector2(custom_scale, custom_scale)
	# Ищем collision-ноду под любым именем — больше никаких крашей
	var col = get_node_or_null("CollisionShape2D")
	if col == null:
		col = get_node_or_null("CollisionPolygon2D")
	if col != null:
		col.scale = Vector2(custom_scale, custom_scale)
	refresh_outline()

func select_object():
	if is_selected:
		return
	is_selected = true

	# 1. Прозрачность
	var temp_color = orig_color
	temp_color.a = 0.85
	$Polygon2D.modulate = temp_color

	# 2. Обводка
	var outline = Polygon2D.new()
	outline.polygon = $Polygon2D.polygon
	outline.position = Vector2(0, 0)
	outline.name = "SelectionOutline"
	add_child(outline)
	move_child(outline, 0)
	selection_outline = outline

	# 3. Пересчёт в конце
	refresh_outline()

func deselect_object():
	is_selected = false
	$Polygon2D.modulate = orig_color
	if selection_outline:
		selection_outline.queue_free()
		selection_outline = null

func set_color(color):
	orig_color = color
	custom_color = color
	$Polygon2D.modulate = color
	
