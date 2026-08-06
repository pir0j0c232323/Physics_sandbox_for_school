extends RigidBody2D

@export var is_static = false

var is_selected = false
var selection_outline = null
var orig_color

func _ready() -> void:
	$Polygon2D.color = Color(1,1,1,1)

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().object_clicked(self)

func select_object():
	if is_selected:
		return
	is_selected = true
	
	var prizrac = $Polygon2D
	var temp_color = orig_color
	temp_color.a = 0.85
	prizrac.modulate = temp_color  #полупрозрачный
	
	var outline = Polygon2D.new()
	outline.polygon = $Polygon2D.polygon
	outline.modulate = Color(0,0,0,1)
	outline.position = Vector2(0, 0)
	outline.scale = Vector2($Polygon2D.scale.x * 1.25,$Polygon2D.scale.y * 1.25)
	outline.name = "SelectionOutline"
	
	
	add_child(outline)
	move_child(outline, 0)
	
	selection_outline = outline

func deselect_object():
		is_selected = false
		
		$Polygon2D.modulate = orig_color
		
		if selection_outline:
			selection_outline.queue_free()
			selection_outline = null

func set_color(color):
	orig_color = color
	$Polygon2D.modulate = color
