extends Node2D

@export var gamePrefab:PackedScene
@export var extremeBtn:Button
@export var hardBtn:Button
@export var normalBtn:Button 

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	extremeBtn.pressed.connect(_loadExtreme)
	hardBtn.pressed.connect(_loadHard)
	normalBtn.pressed.connect(_loadNormal)
	self.get_node("Panel").size = Vector2(self.get_viewport().size.x,self.get_viewport().size.y)

func _loadExtreme():
	_loadGame(18,32, 115, rng.randi())

func _loadHard():
	_loadGame(12,22, 40, rng.randi())

func _loadNormal():
	_loadGame(9,16, 15, rng.randi())

func _loadGame(x:int, y:int, b:int, _seed:int):
	var game = gamePrefab.instantiate()
	game.get_node("Game").gameSetup(self,x,y,b,_seed)
	self.get_parent().add_child(game)
	
