class_name Tile extends Node

var parent:Node2D

var gridPosition: Vector2i
var worldPosition: Vector2
var tileScale:Vector2

var isBomb: bool

var labelPrefab: PackedScene
var label: Label

var meshPrefab: PackedScene
var mesh: MeshInstance2D


@warning_ignore("shadowed_variable")
func _init(gridPosition: Vector2i, worldPosition:Vector2, tileScale:Vector2, isBomb: bool, meshPrefab: PackedScene,labelPrefab:PackedScene, parent:Node2D):
	self.parent = parent
	
	self.gridPosition = gridPosition
	self.worldPosition = worldPosition
	self.tileScale = tileScale
	
	self.isBomb = isBomb
	
	self.labelPrefab = labelPrefab
	self.label = null
	
	self.meshPrefab = meshPrefab
	self.mesh = null
	
	# MESH GEN SETUP
	#self.meshTopLeft = Vector2(0,0)
	#self.meshTopRight = Vector2(self.tileScale.x,0)
	#self.meshBottomLeft = Vector2(0,-self.tileScale.y)
	#self.meshBottomRight = Vector2(self.tileScale.x,-self.tileScale.y)


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
	label.name += " X:" + str(gridPosition.x) + " Y:" + str(gridPosition.y)
	self.label = label

func createMesh():
	mesh = meshPrefab.instantiate()
	parent.add_child(mesh)
	mesh.position = worldPosition
	mesh.name += " X:" + str(gridPosition.x) + " Y:" + str(gridPosition.y)
	self.mesh = mesh

func createCustomMesh():
	if self.mesh == null:
		createMesh()
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# MESH GEN
	var meshTopLeft:Vector2 		= Vector2(0,tileScale.y)
	var meshTopRight:Vector2 		= Vector2(tileScale.x,tileScale.y)
	var meshBottomLeft:Vector2 		= Vector2(0,0)
	var meshBottomRight:Vector2 	= Vector2(tileScale.x, 0)

	var precision:int = 10
	
	var center 						= tileScale/2.0 
	var meshMiddleLeft:Vector2 		= Vector2(0.0,tileScale.y/2.0)
	var meshMiddleRight:Vector2 	= Vector2(tileScale.x, tileScale.y/2.0)
	var meshMiddleTop:Vector2 		= Vector2(tileScale.x/2.0,tileScale.y)
	var meshMiddleBottom:Vector2 	= Vector2(tileScale.x/2.0,0)
	
	# TOP LEFT
	for vertex in createMeshCurvedCorner(10.0, meshTopLeft, meshMiddleTop, meshMiddleLeft, center, true, false, false, false):
		st.add_vertex(vertex)
	
	# TOP RIGHT
	for vertex in createMeshCurvedCorner(10.0, meshMiddleTop, meshTopRight, center, meshMiddleRight, false, true, false, false):
		st.add_vertex(vertex)
	
	# BOT LEFT
	for vertex in createMeshCurvedCorner(10.0, meshMiddleLeft, center, meshBottomLeft, meshMiddleBottom, false, false, true, false):
		st.add_vertex(vertex)
	
	# BOT RIGHT
	for vertex in createMeshCurvedCorner(10.0, center, meshMiddleRight, meshMiddleBottom, meshBottomRight, false, false, false, true):
		st.add_vertex(vertex)
	
	self.mesh.mesh=st.commit()

func createMeshCurvedCorner(precision:int, topLeft:Vector2, topRight:Vector2, bottomLeft:Vector2, bottomRight:Vector2, curvedTL:bool, curvedTR:bool, curvedBL:bool, curvedBR:bool) -> Array:
	var verticies:Array = []
	for i in range(precision):
		var i_next_normalized:float = float(i+1) / float(precision)
		var i_normalized:float = float(i) / float(precision)
		
		var y_top 		= tileScale.y/2.0 * i_next_normalized
		var y_bottom 	= tileScale.y/2.0 * i_normalized
		
		var TL:Vector2 = bottomLeft + Vector2(0, y_top)
		var TR:Vector2 = bottomLeft + Vector2(tileScale.y/2, y_top)
		var BL:Vector2 = bottomLeft + Vector2(0, y_bottom)
		var BR:Vector2 = bottomLeft + Vector2(tileScale.x/2, y_bottom)
		
		if curvedTL:
			TL = bezierCurvePoint(bottomLeft, topLeft, topRight, i_next_normalized)
			BL = bezierCurvePoint(bottomLeft, topLeft, topRight, i_normalized)
		elif curvedTR:
			TR = bezierCurvePoint(bottomRight, topRight, topLeft, i_next_normalized)
			BR = bezierCurvePoint(bottomRight, topRight, topLeft, i_normalized)
		elif curvedBL:
			TL = bezierCurvePoint(bottomRight, bottomLeft, topLeft, i_next_normalized)
			BL = bezierCurvePoint(bottomRight, bottomLeft, topLeft, i_normalized)
		elif curvedBR:
			TR = bezierCurvePoint(bottomLeft, bottomRight, topRight, i_next_normalized)
			BR = bezierCurvePoint(bottomLeft, bottomRight, topRight, i_normalized)
		
		for vertex in createQuadList(TL, TR, BL, BR):
			verticies.append(Vector3(vertex.x,vertex.y,0))
	
	return verticies

func createQuadList(topLeft:Vector2, topRight:Vector2, bottomLeft:Vector2, bottomRight:Vector2) -> Array:
	return [ topLeft, topRight, bottomLeft, topRight, bottomRight, bottomLeft]
	
func bezierCurvePoint(start:Vector2, mid:Vector2, end:Vector2, midTime:float) -> Vector2:
	var t:float = midTime
	var rt:float = 1.0 - t
	# b(t) = (1-t)^2 * b0 + 2t(1-t)b1 + t^2 * b2
	return (rt * rt * start) + (2 * t * rt * mid) + (t * t * end);
