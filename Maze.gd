
extends Node2D

@export var maze_size: int = 15
@export var cell_size: int = 48
@export var wall_width: float = 4.0
@export var player_scene: PackedScene

# Directions
const DIRS = {
	"N": Vector2(0, -1),
	"S": Vector2(0, 1),
	"E": Vector2(1, 0),
	"W": Vector2(-1, 0)
}
const OPP = {"N":"S","S":"N","E":"W","W":"E"}

# Cell class (with diagonals stored but kept closed by generator to mirror Python behavior)
class Cell:
	var x: int
	var y: int
	var walls := {
		"N": true, "S": true, "E": true, "W": true,
		"NE": true, "NW": true, "SE": true, "SW": true
	}
	var visited: bool = false
	func _init(_x:int,_y:int):
		x = _x
		y = _y

# Runtime containers
var grid: Array = []
var walls_parent: Node2D

# Entrance/exit coords
var entrance_cell: Vector2
var exit_cell: Vector2

func _ready():
	# Optional: preload Player if you exported it
	if not player_scene:
		# try to load `res://Player.tscn` by default if not set in editor
		if ResourceLoader.exists("res://Player.tscn"):
			player_scene = load("res://Player.tscn")

	walls_parent = Node2D.new()
	walls_parent.name = "MazeWalls"
	add_child(walls_parent)

	# Win label (assumes parent scene has a Label named WinLabel at root)
	var win_label = get_node_or_null("../WinLabel")
	if win_label:
		win_label.visible = false

	generate_and_draw()

# Public: regenerate maze (callable from editor or button)
func generate_and_draw():
	clear_walls()
	_generate_grid(maze_size)
	_carve_passages()
	_open_entrance_exit()
	_build_walls_and_colliders()
	_spawn_player_at_exit()

func _generate_grid(size:int):
	grid.clear()
	for x in size:
		var col:Array = []
		for y in size:
			col.append(Cell.new(x, y))
		grid.append(col)

func _in_bounds(x:int,y:int)->bool:
	return x >= 0 and x < maze_size and y >= 0 and y < maze_size

func _carve_passages():
	# Iterative DFS starting from bottom-center (like your Python)
	var start_x = int(maze_size / 2)
	var start_y = maze_size - 1
	var stack = [Vector2(start_x, start_y)]

	while stack.size() > 0:
		var pos = stack[-1]
		var cx = int(pos.x)
		var cy = int(pos.y)
		var cell:Cell = grid[cx][cy]
		cell.visited = true

		var dirs = DIRS.keys()
		dirs.shuffle()

		var moved = false
		for d in dirs:
			var dp = DIRS[d]
			var nx = cx + int(dp.x)
			var ny = cy + int(dp.y)
			if _in_bounds(nx, ny):
				var neighbor:Cell = grid[nx][ny]
				if not neighbor.visited:
					# remove both walls
					cell.walls[d] = false
					neighbor.walls[OPP[d]] = false
					stack.append(Vector2(nx, ny))
					moved = true
					break
		if not moved:
			stack.pop()

	# Keep diagonal corner walls True to prevent corner cutting (matches original Python behavior)
	for x in maze_size:
		for y in maze_size:
			var c:Cell = grid[x][y]
			c.walls["NE"] = true
			c.walls["NW"] = true
			c.walls["SE"] = true
			c.walls["SW"] = true

func _open_entrance_exit():
	var cx = int(maze_size / 2)
	grid[cx][0].walls["N"] = false # entrance at top center
	grid[cx][maze_size - 1].walls["S"] = false # exit at bottom center
	entrance_cell = Vector2(cx, 0)
	exit_cell = Vector2(cx, maze_size - 1)

# Remove previous walls children
func clear_walls():
	if walls_parent and walls_parent.is_inside_tree():
		walls_parent.queue_free()
	walls_parent = Node2D.new()
	walls_parent.name = "MazeWalls"
	add_child(walls_parent)

# Helper: create a wall segment as StaticBody2D with rectangular collision and a Line2D visual
func _create_wall_segment(a:Vector2, b:Vector2):
	var body = StaticBody2D.new()
	var mid = (a + b) * 0.5
	body.position = mid
	var dir = b - a
	body.rotation = dir.angle()

	var length = dir.length()
	var shape = RectangleShape2D.new()
	# RectangleShape2D.size expects Vector2(width, height)
	shape.size = Vector2(length, wall_width)

	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2.ZERO
	body.add_child(col)
	walls_parent.add_child(body)

	# Visual line for the wall
	var visual = Line2D.new()
	visual.width = wall_width
	visual.default_color = Color(1,1,1)
	visual.add_point(a)
	visual.add_point(b)
	walls_parent.add_child(visual)

func _create_corner_block(pos:Vector2):
	# Small square collider to block diagonal corner crossing
	var body = StaticBody2D.new()
	body.position = pos
	var shape = RectangleShape2D.new()
	shape.size = Vector2(wall_width, wall_width)
	var cs = CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	walls_parent.add_child(body)

func _build_walls_and_colliders():
	# For each cell, draw its 4 cardinal walls and a small corner block for each diagonal wall
	for x in maze_size:
		for y in maze_size:
			var cell:Cell = grid[x][y]
			var top_left = Vector2(x * cell_size, y * cell_size)
			var top_right = top_left + Vector2(cell_size, 0)
			var bottom_left = top_left + Vector2(0, cell_size)
			var bottom_right = top_left + Vector2(cell_size, cell_size)

			# North
			if cell.walls["N"]:
				_create_wall_segment(top_left, top_right)
			# South
			if cell.walls["S"]:
				_create_wall_segment(bottom_left, bottom_right)
			# West
			if cell.walls["W"]:
				_create_wall_segment(top_left, bottom_left)
			# East
			if cell.walls["E"]:
				_create_wall_segment(top_right, bottom_right)

			# Diagonal corner blocks (NE,NW,SE,SW) -- placed at the corner points
			var corner_offset = Vector2(0,0)
			if cell.walls["NE"]:
				_create_corner_block(top_right)
			if cell.walls["NW"]:
				_create_corner_block(top_left)
			if cell.walls["SE"]:
				_create_corner_block(bottom_right)
			if cell.walls["SW"]:
				_create_corner_block(bottom_left)

	# Optionally, create an outer boundary so player can't leave
	var outer_tl = Vector2(0,0)
	var outer_tr = Vector2(maze_size * cell_size, 0)
	var outer_bl = Vector2(0, maze_size * cell_size)
	var outer_br = Vector2(maze_size * cell_size, maze_size * cell_size)
	_create_wall_segment(outer_tl, outer_tr)
	_create_wall_segment(outer_tr, outer_br)
	_create_wall_segment(outer_br, outer_bl)
	_create_wall_segment(outer_bl, outer_tl)

func _spawn_player_at_exit():
	if not player_scene:
		return
	# Remove existing players
	for child in get_tree().get_nodes_in_group("player_spawn"):
		child.queue_free()

	var player = player_scene.instantiate()
	player.position = Vector2(exit_cell.x * cell_size + cell_size * 0.5, exit_cell.y * cell_size + cell_size * 0.5)
	player.name = "Player"
	player.add_to_group("player_spawn")
	get_tree().root.get_current_scene().add_child(player)

	# If WinLabel exists in parent scene, hide it
	var win_label = get_node_or_null("../WinLabel")
	if win_label:
		win_label.visible = false

func check_player_reached_entrance(player_pos:Vector2):
	var px = int(player_pos.x / cell_size)
	var py = int(player_pos.y / cell_size)
	if px == int(entrance_cell.x) and py == int(entrance_cell.y):
		var win_label = get_node_or_null("../WinLabel")
		if win_label:
			win_label.text = "You Win!"
			win_label.visible = true
