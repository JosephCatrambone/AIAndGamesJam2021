extends Node

var rng:RandomNumberGenerator = RandomNumberGenerator.new()

# Expect the terminal to register itself.
var terminal_ref

# Map should register self, too.
var navigation_mesh_ref:Navigation2D
func get_nav_path(position:Vector2, target:Vector2) -> PoolVector2Array:
	if navigation_mesh_ref == null:
		print("Request for nav path before map registered.")
		return PoolVector2Array([])
	var path = navigation_mesh_ref.get_simple_path(position, target)
	return path

# Used for navigation to random places in the map.
var waypoints:PoolVector2Array
func register_waypoint(wp:Position2D):
	waypoints.append(wp.global_position)

func get_random_waypoint() -> Vector2:
	return self.random_choice(self.waypoints)

func random_choice(arr:Array):
	if len(arr) == 0:
		printerr("Random choice on empty array")
		return null
	return arr[Globals.rng.randi_range(0, len(arr)-1)]
