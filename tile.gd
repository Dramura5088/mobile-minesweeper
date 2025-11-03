class_name Tile extends Node

var parent:Node2D

var gridPosition: Vector2i
var worldPosition: Vector2
var tileScale:Vector2

var isBomb: bool
var labelPrefab: PackedScene
var label: Label

@warning_ignore("shadowed_variable")
func _init(gridPosition: Vector2i, worldPosition:Vector2, tileScale:Vector2, isBomb: bool, labelPrefab:PackedScene, parent:Node2D):
	self.parent = parent
	
	self.gridPosition = gridPosition
	self.worldPosition = worldPosition
	self.tileScale = tileScale
	
	self.isBomb = isBomb
	
	self.labelPrefab = labelPrefab
	self.label = null

func nearbyBombs(grid:Dictionary, lockedGrid:Dictionary ,unveilIfNoBombs:bool = true) -> int:
	var bombs:int = 0
	var lockedTiles:int = 0
	for x in range(gridPosition.x-1, gridPosition.x+2):
		for y in range(gridPosition.y-1, gridPosition.y+2):
			var pos = Vector2i(x,y)
			if pos == gridPosition:
				continue
			
			if pos in grid and grid[pos].isBomb:
				bombs += 1
			if pos in lockedGrid:
				lockedTiles += 1
	
	if bombs == 0 && unveilIfNoBombs:
		unveilNearbyTiles(grid, lockedGrid, true)
	elif bombs - lockedTiles <= 0 && unveilIfNoBombs:
		unveilNearbyTiles(grid, lockedGrid, false)
	setLabel(str(bombs))
	return bombs

func unveilNearbyTiles(grid:Dictionary, lockedGrid:Dictionary, unveilIfNoBombs:bool = true):
		for x in range(gridPosition.x-1, gridPosition.x+2):
			for y in range(gridPosition.y-1, gridPosition.y+2):
				var pos = Vector2i(x,y)
				if pos in grid && grid[pos].label == null && pos not in lockedGrid:
					grid[pos].createLabel()
					grid[pos].nearbyBombs(grid, lockedGrid, unveilIfNoBombs)

func setLabel(text:String):
	if (label == null): return
	label.text = text

func createLabel():
	label = labelPrefab.instantiate()
	parent.add_child(label)
	
	label.size = tileScale
	label.position = worldPosition
	label.name = "X:" + str(gridPosition.x) + " Y:" + str(gridPosition.y)
