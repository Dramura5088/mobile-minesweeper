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
@export var backgroundColor:Color 	= Color.DIM_GRAY
@export var emptyTileColor:Color 	= Color.WEB_GRAY
@export var gridColor:Color 		= Color.BLACK
@export var lockedGridColor:Color 	= Color.DARK_RED

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
	#drawGrid()
	for pos in grid:
		grid[pos].createCustomMesh()
	queue_redraw()

func drawGrid():
	draw_line(Vector2(0,screen_size.y/2),Vector2(screen_size.x,screen_size.y/2), backgroundColor, screen_size.y)
	
	for gridPos in grid:
		var worldPos: Vector2 = gridPosToWorldPos(Vector2(gridPos.x,gridPos.y))
		
		var bottom_left  = Vector2(worldPos.x,worldPos.y)
		var top_left	 = bottom_left + Vector2(0,screen_sizeScale.y)
		var bottom_right = bottom_left + Vector2(screen_sizeScale.x,0)
		var top_right	 = bottom_right + Vector2(0,screen_sizeScale.y)
		
		var centre		 = bottom_left + screen_sizeScale/2
		
		draw_line(bottom_left,top_left, gridColor, gridLinesWidth) # Left Line
		draw_line(bottom_left,bottom_right,gridColor, gridLinesWidth) # Bottom Line
		
		if gridPos.x == gridXSize -1 || gridPos.y == gridYSize -1:
			draw_line(top_left,top_right, gridColor, gridLinesWidth) # Top Line
			draw_line(top_right, bottom_right, gridColor, gridLinesWidth) # Right Line
		
		if grid[gridPos].label == null:
			var offset: Vector2 = Vector2(0,screen_sizeScale.y/2)
			draw_line(bottom_left + offset, bottom_right + offset, emptyTileColor, offset.y*2)
		
		draw_circle(gridPos,.5,Color.ALICE_BLUE)
		# Debug draw bomb location.
		if grid[gridPos].isBomb && debug:
			draw_circle(centre,bufferSize,Color.RED)
	for gridPos in lockedGrid:
		var worldPos: Vector2 = gridPosToWorldPos(Vector2(gridPos.x,gridPos.y))
		
		var bottom_left  = Vector2(worldPos.x,worldPos.y)
		var top_left	 = bottom_left + Vector2(0,screen_sizeScale.y)
		var bottom_right = bottom_left + Vector2(screen_sizeScale.x,0)
		var top_right	 = bottom_right + Vector2(0,screen_sizeScale.y)
		
		var centre		 = bottom_left + screen_sizeScale/2

		draw_line(top_left, bottom_right, lockedGridColor, lockedGridLinesWidth)
		draw_line(bottom_left, top_right, lockedGridColor, lockedGridLinesWidth)
	
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
