extends Node2D

var startGame = false

# ENABLE FOR DEBUG DRAWS & ETC
@export var debug:bool = false

# UI SCALING
var screen_size
var screen_sizeScale:Vector2

# GAME VARIABLES
var gridXSize:  int = 10
var gridYSize:  int = 10
var bombs: int = 10
var currentBombs: int = 0
var viewPort:Viewport

# SETTINGS
@export var tileSize:float = 50
@export var dragStrength: float = 2.5
@export var maxScale:float=2.0
@export var minScale:float=.9
@export var scrollSpeed:float=4

# COLORS
@export var backgroundColor:Color 	= Color.WEB_GRAY
@export var veiledTileColor:Color 	= Color.DIM_GRAY
@export var unveiledTileColor:Color 		= Color.WEB_GRAY
@export var lockedunveiledTileColor:Color 	= Color.ORANGE_RED

# RANDOM GENERATION
var rng = RandomNumberGenerator.new()

# PRESET
@export var tileLabel_Scene: PackedScene
@export var tileMesh_Scene: PackedScene

# DRAG
var isDragging:bool = false
var originalPos:Vector2
var dragStart:Vector2
@export var dragThreshold:float = 5
var positionOffset:Vector2 = Vector2.ZERO

# GRIDS
var grid:Dictionary
var lockedGrid:Dictionary

@warning_ignore("shadowed_global_identifier")
func gameSetup(menu:Node2D, xSize:int, ySize:int, bombsAmount:int, seed:int):
	gridXSize = xSize
	gridYSize = ySize
	bombs = bombsAmount
	rng.seed = seed

	# Set Viewport
	viewPort = menu.get_viewport()
	originalPos = self.position
	screen_size = viewPort.size

	currentBombs = 0

	screen_sizeScale = Vector2.ONE * tileSize
	grid = {}
	lockedGrid = {}

	# TILES
	for x in range(gridXSize):
		for y in range(gridYSize):
			var pos:Vector2i = Vector2i(x,y)
			var worldPos:Vector2 = gridPosToWorldPos(pos)
			var gridObject = Tile.new(pos, worldPos, screen_sizeScale, false, tileMesh_Scene,tileLabel_Scene, self)
			grid[pos] = gridObject

	# BOMB
	for pos in grid.keys():
		if rng.randi_range(0, gridXSize * gridYSize) <= bombs && bombs >= currentBombs:
			grid[pos].isBomb = true
			currentBombs += 1
			
	for pos in grid.keys():
		grid[pos].nearbyBombs(grid, lockedGrid, false)

	startGame = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if startGame == false: return
	
	if Input.is_action_just_pressed("LeftClick"):
		dragStart = viewPort.get_mouse_position()
		isDragging = true
	if Input.is_action_just_released("LeftClick"):
		var dragDistance = dragStart.distance_to(viewPort.get_mouse_position())
		isDragging = false
		if dragDistance > dragThreshold: # DRAG
			queue_redraw()
		else: # NOT DRAG
			onTilePressLeftClick()
	
	if Input.is_action_just_pressed("RightClick"):
		dragStart = viewPort.get_mouse_position()
		isDragging = true
	if Input.is_action_just_released("RightClick"):
		var dragDistance = dragStart.distance_to(viewPort.get_mouse_position())
		isDragging = false
		if dragDistance > dragThreshold: # DRAG
			queue_redraw()
		else: # NOT DRAG
			onTilePressRightClick()

	var zoomAmount = delta * scrollSpeed

	if Input.is_action_just_released("ScrollUp"):
		var new_scale = Vector2(clamp(self.scale.x + zoomAmount, minScale, maxScale),clamp(self.scale.y + zoomAmount, minScale, maxScale))
		var scale_diff = (self.scale.length()/new_scale.length()) - 1
		#print(scale_diff)
		self.scale = new_scale
		if (new_scale.x != minScale and new_scale.x != maxScale) or (new_scale.y != minScale and new_scale.y != maxScale):
			self.positionOffset -= screen_size * -scale_diff * zoomAmount/2
			self.position = originalPos + positionOffset

	elif Input.is_action_just_released("ScrollDown"):
		var new_scale = Vector2(clamp(self.scale.x - zoomAmount, minScale, maxScale),clamp(self.scale.y - zoomAmount, minScale, maxScale))
		var scale_diff = (self.scale.length()/new_scale.length()) - 1
		#print(scale_diff)
		self.scale = new_scale
		if (new_scale.x != minScale and new_scale.x != maxScale) or (new_scale.y != minScale and new_scale.y != maxScale):
			self.positionOffset += screen_size * -scale_diff * zoomAmount/2
			self.position = originalPos + positionOffset

	if isDragging:
		var movementDifference:Vector2 = dragStart - viewPort.get_mouse_position() 
		positionOffset += movementDifference * delta * dragStrength
		self.position = originalPos + positionOffset

func onTilePressLeftClick():
	var mousePos: Vector2 = viewPort.get_mouse_position()
	var gridPos = worldPosToGridPos(mousePos)
	if gridPos in grid && gridPos not in lockedGrid:
		if grid[gridPos].label == null:
			grid[gridPos].createLabel()
			grid[gridPos].nearbyBombs(grid, lockedGrid)
		else:
			grid[gridPos].nearbyBombs(grid, lockedGrid)
		queue_redraw()

func onTilePressRightClick():
	var mousePos: Vector2 = viewPort.get_mouse_position()
	var gridPos = worldPosToGridPos(mousePos)
	if gridPos in grid && grid[gridPos].label == null:
		if gridPos not in lockedGrid:
			lockedGrid[gridPos] = grid[gridPos]
		else:
			lockedGrid.erase(gridPos)
		queue_redraw()

func _draw():
	if startGame == false: return
	
	@warning_ignore("shadowed_variable")
	var gridWithLabels:Dictionary = gridWithLabels()
	var gridWithoutLabels:Dictionary = gridWithLabels(true)
	for pos in grid:
		if grid[pos].label != null:
			grid[pos].generateNewMesh(gridWithLabels)
			grid[pos].mesh.modulate = unveiledTileColor
		elif pos not in lockedGrid:
			grid[pos].generateNewMesh(gridWithoutLabels)
			grid[pos].mesh.modulate = veiledTileColor
		else:
			grid[pos].generateNewMesh(lockedGrid)
			grid[pos].mesh.modulate = lockedunveiledTileColor
	queue_redraw()

func gridWithLabels(inverse:bool = false)->Dictionary:
	var grid_new = {}
	for pos in grid:
		if pos in lockedGrid:
			continue
		if grid[pos].label != null and not inverse:
			grid_new[pos] = grid[pos]
		elif grid[pos].label == null and inverse:
			grid_new[pos] = grid[pos]
	return grid_new

func gridPosToWorldPos(gridPos: Vector2i) -> Vector2:
	var _scale:Vector2 = screen_sizeScale
	_scale = Vector2(_scale.x * self.scale.x, _scale.y * self.scale.y)
	
	var x:float = gridPos.x * _scale.x
	var y:float = gridPos.y * _scale.y
	
	return Vector2(x,y) 

func worldPosToGridPos(worldPos: Vector2) -> Vector2i:
	var _scale:Vector2 = screen_sizeScale
	_scale = Vector2(_scale.x * self.scale.x, _scale.y * self.scale.y)

	var x:int = int(int(worldPos.x - positionOffset.x) / _scale.x)
	var y:int = int(int(worldPos.y - positionOffset.y) / _scale.y)
	return Vector2(x,y)
