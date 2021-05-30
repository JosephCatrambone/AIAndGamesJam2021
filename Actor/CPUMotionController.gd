extends MotionController

# Reads a CPU from the parent and uses that to set drive.
onready var cpu = $"../CPU"
onready var ray:RayCast2D = $RayCast2D
export(float) var look_distance:float = 10

const MOVE_X_ADDRESS = 0xF0
const MOVE_Y_ADDRESS = 0xF1
const BUMP_REPORT = 0xF2

func update():
	# Get facing direction from parent.  Let the parent deal with rotation.
	var facing:Vector2 = get_parent().face_direction
	ray.cast_to = facing.normalized() * look_distance
	if ray.get_collider() != null:
		cpu.memory[BUMP_REPORT] = 1
		# CPU code will clear bump.

func get_x_axis() -> float:
	return (cpu.memory[MOVE_X_ADDRESS] - 128) / 128.0

func get_y_axis() -> float:
	return (cpu.memory[MOVE_Y_ADDRESS] - 128) / 128.0

func get_fire_button() -> bool:
	return false

func get_interact_button() -> bool:
	return false
