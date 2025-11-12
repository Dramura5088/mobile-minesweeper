extends Node2D

# ENABLE FOR DEBUG DRAWS & ETC
@export var debug:bool = false

# SETTINGS
@export var gridXSize:  int = 10
@export var gridYSize:  int = 10
@export var bufferSize: int = 10
@export var bombs: int = 10

# LINE WIDTH
@export var gridLinesWidth:int = 5
@export var lockedGridLinesWidth:int = 10

# COLORS
@export var backgroundColor:Color 	= Color.WEB_GRAY
@export var veiledTileColor:Color 	= Color.DIM_GRAY
@export var unveiledTileColor:Color 		= Color.WEB_GRAY
@export var lockedunveiledTileColor:Color 	= Color.ORANGE_RED

# FOR UI
var currentBombs: int = 0
var viewPort:Viewport

# RANDOM GENERATION
@export var gameSeed:int = 42
var rng = RandomNumberGenerator.new()

# PRESET
@export var tileLabel_Scene: PackedScene
@export var tileMesh_Scene: PackedScene

# UI SCALING
var screen_size
var screen_sizeScale:Vector2

# DRAG
var isDragging:bool = false
var originalPos:Vector2
var dragStart:Vector2
@export var dragThreshold:float = 5
var positionOffset:Vector2 = Vector2.ZERO

# GRIDS
var grid:Dictionary
var lockedGrid:Dictionary

# MESH GEN
var color1:Color = Color.DIM_GRAY
var color3:Color = Color.WEB_GRAY


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Ready")
	viewPort = get_viewport()
	originalPos = self.position
	screen_size = viewPort.size
	
	rng.seed = gameSeed
	currentBombs = 0
	
	screen_sizeScale = getScreenSizeScale()
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
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

	if isDragging:
		var movementDifference:Vector2 = dragStart - viewPort.get_mouse_position() 
		positionOffset += movementDifference * delta
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
	var _scale:Vector2 = getScreenSizeScale()
	
	var x:float = gridPos.x * _scale.x + bufferSize/2.0
	var y:float = gridPos.y * _scale.y + bufferSize/2.0
	
	return Vector2(x,y)
	
func worldPosToGridPos(worldPos: Vector2) -> Vector2i:
	var _scale:Vector2 = getScreenSizeScale()

	var x:int = int(int(worldPos.x - positionOffset.x) / _scale.x)
	var y:int = int(int(worldPos.y - positionOffset.y) / _scale.y)
	
	return Vector2(x,y)
	
func getScreenSizeScale() -> Vector2:
	return Vector2((screen_size.x-bufferSize) / gridXSize,(screen_size.y-bufferSize) / gridYSize)
