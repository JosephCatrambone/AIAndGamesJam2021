extends KinematicBody2D

# Animation control
onready var anim_player:AnimationPlayer = $AnimationPlayer
onready var anim_tree:AnimationTree = $AnimationTree

# Obstacle detection and navigation
onready var ray:RayCast2D = $RayCast2D
export(float) var max_speed:float = 32.0
export(float) var distance_before_popping_nav_point:float = 1.0
var face_direction:Vector2 = Vector2(0, 1)  # Not updated if move-dir is zero.
var move_direction:Vector2  # Previous move direction
var path:PoolVector2Array

# State management
enum { SIT, STAND, WALK }
var state = SIT
var happiness:float = 1.0

func _ready():
	pass

func _process(delta):
	# Update all shared state components.
	_update_animation()
	match self.state:
		SIT:
			_process_sit(delta)
		STAND:
			_process_stand(delta)
		WALK:
			_process_walk(delta)
	
func _update_animation():
	var state_machine:AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]
	match self.state:
		SIT:
			if happiness > 0.9:
				state_machine.travel("IdleWag")
			else:
				state_machine.travel("IdleSit")
		STAND:
			state_machine.travel("IdleStand")
		WALK:
			state_machine.travel("Walk")
	anim_tree["parameters/Walk/blend_position"] = self.face_direction
	anim_tree["parameters/IdleStand/blend_position"] = self.face_direction
	anim_tree["parameters/IdleSit/blend_position"] = self.face_direction
	anim_tree["parameters/IdleWag/blend_position"] = self.face_direction

func _process_sit(delta):
	if Input.is_action_just_pressed("ui_accept"):
		self.state = STAND

func _process_stand(delta):
	if Input.is_action_just_pressed("ui_accept"):
		self.path = Globals.get_nav_path(self.global_position, Vector2(Globals.rng.randf_range(-100, 100), Globals.rng.randf_range(-100, 100)))
		self.state = WALK

func _process_walk(delta):
	if path.empty():
		self.state = STAND
		return
	# Can we pop our current nav point?
	var delta_position = path[0] - self.global_position
	if delta_position.length_squared() < distance_before_popping_nav_point:
		path.remove(0)
		return
	# No?  Then move towards it.
	# One small hack: if dx/dy is really small, like less than a pixel or so, drop it to zero.
	if abs(delta_position.x) < 0.5:
		delta_position.x = 0
	if abs(delta_position.y) < 0.5:
		delta_position.y = 0
	move_direction = Vector2(sign(delta_position.x), sign(delta_position.y))
	self.move_and_slide(move_direction.normalized()*self.max_speed)
	if move_direction:
		self.face_direction = move_direction

# Win condition!
signal win
func _on_win_area_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		print("Win!")
		emit_signal("win")
