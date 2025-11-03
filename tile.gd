class_name Tile extends Node

var gridPosition: Vector2i
var isBomb: bool
var label: Label

func _init(gridPosition: Vector2i, isBomb: bool, label:Label):
	self.gridPosition = gridPosition
	self.isBomb = isBomb
	self.label = label

func nearbyBombs(grid:Dictionary) -> int:
	var bombs:int = 0
	for x in range(gridPosition.x-1, gridPosition.x+1):
		for y in range(gridPosition.y-1, gridPosition.y+1):
			var pos = Vector2i(x,y)
			if pos == gridPosition:
				continue
			elif pos in grid and grid[pos].isBomb:
				bombs += 1
	return bombs

func setLabel():
	pass
