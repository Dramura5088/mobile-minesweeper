extends Button

@export var mainMenu:PackedScene

func _ready() -> void:
	self.pressed.connect(_loadMainMenu)

#func _process(delta: float) -> void:
	#self.position = -self.get_parent().positionOffset
	#self.scale = Vector2(1/self.get_parent().screen_sizeScale.x, 1/self.get_parent().screen_sizeScale.y)
	
	
func _loadMainMenu():
	#get_tree().change_scene_to_packed(mainMenu)
	var menu = mainMenu
	get_tree().root.add_child(menu)
	self.get_parent().queue_free()
