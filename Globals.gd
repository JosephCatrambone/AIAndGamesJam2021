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
