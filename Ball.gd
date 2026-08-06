extends RigidBody2D

@export var is_static = false

var is_selected = false
var selection_outline = null
var orig_color

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().ball_clicked(self)

func select_object():
	if is_selected:
		return
	is_selected = true
	
	var temp_color = orig_color
	temp_color.a = 0.85
	$Sprite2D.modulate = temp_color  #полупрозрачный
	
	var outline = Sprite2D.new()
	outline.texture = $Sprite2D.texture
	outline.scale = Vector2($Sprite2D.scale.x + 0.01,$Sprite2D.scale.y + 0.01)
	outline.modulate = Color(0,0,0,1)
	outline.position = Vector2(0, 0)
	outline.name = "SelectionOutline"
	
	add_child(outline)
	move_child(outline, 0)
	
	selection_outline = outline

func deselect_object():
	is_selected = false
		
	$Sprite2D.modulate = orig_color
		
	if selection_outline:
		selection_outline.queue_free()
		selection_outline = null

func set_color(color):
	orig_color = color
	$Sprite2D.modulate = color
	
