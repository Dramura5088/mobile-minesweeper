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

#@warning_ignore("unused_parameter")
#func createCustomMesh(grid:Dictionary, lockedGrid:Dictionary):
	#if self.mesh == null:
		#createMesh()
	#
	#var a_mesh = ArrayMesh.new()
	#var verticies := PackedVector3Array([
		#Vector3(0,0,0) * tileScale.x,
		#Vector3(1,0,0) * tileScale.x,
		#Vector3(0,-1,0) * tileScale.x,
	#])
	#
	#var indicies := PackedInt32Array([
		#0,1,2
	#])
#
	#var array = []
	#array.resize(Mesh.ARRAY_MAX)
	#array[Mesh.ARRAY_VERTEX] = verticies
	#array[Mesh.ARRAY_INDEX] = indicies
	#a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	#self.mesh.mesh = a_mesh
	#print(a_mesh)

func createCustomMesh():
	
	if self.mesh == null:
		createMesh()
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	st.add_vertex(Vector3(0,0,0))
	st.add_vertex(Vector3(1,0,0))
	st.add_vertex(Vector3(0,1,0))
	
	
	var mesh = st.commit()
	self.mesh.mesh=mesh

func createQuad(topLeft:Vector3, topRight:Vector3, bottomLeft:Vector3, bottomRight:Vector3):
	pass
	
func bezierCurvePoint(start:Vector3, mid:Vector3, end:Vector3, t:float):
	pass
	
	
