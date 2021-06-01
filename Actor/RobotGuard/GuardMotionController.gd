extends MotionController

# Handles most of the guard AI.  Simple state machine.
# Eventually expose this to a CPU.

onready var vision_cone_display:Polygon2D = $VisionConeDisplay
onready var vision_cone:Area2D = $VisionCone
onready var ray:RayCast2D = $RayCast2D
export(float) var look_distance:float = 10
var potential_visible_bodies = []

enum GuardState { 
	IDLE,
	WANDER,
	FOLLOW_PATH,
	PURSUE,
}
var state = GuardState.WANDER

# For all states, we need to track DX/DY.
# A bit of duplicative code because the parent actor has 'facing' and 'movement', but whatever.
var dxdy:Vector2 = Vector2()

# For pathing.
export(float) var distance_before_popping_nav_point:float = 1.0
var active_path:PoolVector2Array

# For wandering.
export(float) var time_between_turns:float = 1.0
var time_to_next_turn:float = 0.0

func _ready():
	vision_cone.connect("body_entered", self, "add_visible_candidate")
	vision_cone.connect("body_exited", self, "remove_visible_candidate")

func _process(delta):
	match self.state:
		GuardState.IDLE:
			pass
		GuardState.WANDER:
			_process_wander(delta)
		GuardState.FOLLOW_PATH:
			_process_follow(delta)
		GuardState.PURSUE:
			pass

func _process_wander(delta):
	time_to_next_turn -= delta
	if time_to_next_turn < 0:
		time_to_next_turn = time_between_turns
		var rng = RandomNumberGenerator.new()
		var facing:Vector2 = get_parent().face_direction
		var angle = facing.angle()
		angle += PI/2.0 * rng.randi_range(0, 3)
		dxdy = Vector2(cos(angle), sin(angle))

func _process_follow(delta):
	# If the active point is none AND the active path is empty, we're done.
	if self.active_path.empty():
		self.state = GuardState.WANDER
		return
	# Otherwise, move towards an active path.
	var delta_position = self.active_path[0]
	if delta_position < distance_before_popping_nav_point*delta:
		self.active_path.remove(0)
		return  # Resume next cycle.
	self.dxdy = Vector2(sign(delta_position.x), sign(delta_position.y))

func start_follow(target:Vector2):
	# TODO: Don't hardcode this name.
	var navmesh:Navigation2D = get_tree().get_root().get_node("NavMesh")
	self.active_path = navmesh.get_simple_path(self.global_position, target)

func add_visible_candidate(candidate):
	self.potential_visible_bodies.append(candidate)

func remove_visible_candidate(candidate):
	if candidate in self.potential_visible_bodies:
		self.potential_visible_bodies.erase(candidate)
	
func update():
	# Get facing direction from parent.  Let the parent deal with rotation.
	var facing:Vector2 = get_parent().face_direction
	
	# Set the rotation of the vision cone and the polygon 2d to the rotation of the parent.
	var angle = facing.angle()
	vision_cone.rotation = angle
	vision_cone_display.rotation = angle
	
	# Update the raycast forward.
	#ray.cast_to = facing.normalized() * look_distance
	# Go over the list of things we might see and raycast to them.
	for body in self.potential_visible_bodies:
		ray.cast_to = body.global_position  # This may be the wrong coordinate system.
		ray.force_raycast_update()
		if ray.get_collider() != null:
			pass
			#cpu.memory[BUMP_REPORT] = 1
			# CPU code will clear bump.

func get_x_axis() -> float:
	return dxdy.x

func get_y_axis() -> float:
	return dxdy.y

func get_fire_button() -> bool:
	return false

func get_interact_button() -> bool:
	return false
