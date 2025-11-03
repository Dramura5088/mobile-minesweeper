extends Node2D

@export var gridXSize:  int = 10
@export var gridYSize:  int = 10
@export var bufferSize: int = 10
@export var bombs: int = 10
var currentBombs: int = 0

@export var seed:int = 42
var rng = RandomNumberGenerator.new()

@export var tile_scene: PackedScene

var screen_size
var screen_sizeScale:Vector2

var grid:Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Ready")
	screen_size = get_viewport().size
	
	var x_scaled = (screen_size.x-bufferSize) / gridXSize
	var y_scaled = (screen_size.y-bufferSize) / gridYSize
	
	rng.seed = seed
	currentBombs = 0
	
	screen_sizeScale = Vector2(x_scaled, y_scaled)
	grid = {}
	# TILES
	for x in range(gridXSize):
		for y in range(gridYSize):
			var pos:Vector2i = Vector2i(x,y)
			var gridObject = Tile.new(pos, false)
			grid[pos] = gridObject
	
	# BOMB
	for pos in grid.keys():
		if rng.randi_range(0, gridXSize * gridYSize) <= bombs && bombs >= currentBombs:
			grid[pos].isBomb = true
			currentBombs += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print("Process")
	#queue_redraw()
	pass

func _draw():
	drawGrid()

func drawGrid():
	#print("Draw")
	for x in range(gridXSize):
		for y in range(gridYSize):
			var x_s = x * screen_sizeScale.x + bufferSize/2
			var y_s = y * screen_sizeScale.y + bufferSize/2
			
			var bottom_left  = Vector2(x_s,y_s)
			var top_left	 = bottom_left + Vector2(0,screen_sizeScale.y)
			var bottom_right = bottom_left + Vector2(screen_sizeScale.x,0)
			var top_right	 = bottom_right + Vector2(0,screen_sizeScale.y)
			
			var centre		 = bottom_left + screen_sizeScale/2
			
			var col = Color.AZURE
			draw_line(bottom_left,top_left,col, 1) # Left Line
			draw_line(bottom_left,bottom_right,col, 1) # Bottom Line
			
			if x == gridXSize -1 || y == gridYSize -1:
				draw_line(top_left,top_right, col, 1) # Top Line
				draw_line(top_right, bottom_right, col, 1 ) # Right Line
			
			if grid[Vector2i(x,y)].isBomb:
				draw_circle(centre,bufferSize,Color.RED)
