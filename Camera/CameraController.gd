extends Camera2D

export(float) var max_smooth_follow:float = 128 # If a target is more than this many units away, just snap to them.
export(float) var lookahead_distance:float = 8
export(NodePath) var follow_target_path:NodePath
var follow_target:Node2D

var previous_position:Vector2

func _ready():
	follow_target = get_node(follow_target_path)

func set_position(target:Vector2):
	self.global_position = target
	self.previous_position = target

func _process(delta):
	# Figure out which way we're going and move in that direction.
	#var new_position = follow_target.global_position
	#var delta_1 = 
	var delta_position:Vector2 = follow_target.global_position - self.global_position
	if delta_position.length_squared() > max_smooth_follow:
		self.smoothing_enabled = false
		self.global_position = follow_target.global_position
		self.smoothing_enabled = true
	else:
		self.global_position = follow_target.global_position
		
	# Offset will let us look in the direction we're going.
	var velocity = delta_position / max(0.1, delta)
	var previous_velocity = (self.global_position - self.previous_position) / max(0.1, delta)
	var lookahead = lookahead_distance * (previous_velocity + velocity) / 2
	#self.offset = 0.9*self.offset + 0.1*lookahead
	self.offset = lookahead*0.01 + self.offset*0.99
	
	self.previous_position = self.global_position
