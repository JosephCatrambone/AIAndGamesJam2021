extends KinematicBody2D

signal dead

export(int) var max_health:int = 10
var health:int = 1

# Movement bits
export(float) var move_speed:float = 1.0
var face_direction:Vector2 = Vector2()
var move_direction:Vector2 = Vector2()

# Interaction bits
var fire:bool = false
var interact:bool = false

# AI bits
var motion_controller:MotionController

# Graphical components + display
export(Array, Texture) var spritesheets:Array
onready var sprite:Sprite = $Sprite
onready var anim_player:AnimationPlayer = $AnimationPlayer
onready var anim_tree:AnimationTree = $AnimationTree

# Shooty bits
var weapon:Node
export(PackedScene) var starting_weapon

func _ready():
	# Randomize look, maybe.
	if len(spritesheets) > 0:
		self.move_speed = Globals.rng.randi_range(5, 16)
		sprite.texture = spritesheets[Globals.rng.randi_range(0, len(spritesheets)-1)]
		sprite.region_enabled = true
		sprite.region_rect = Rect2(48*Globals.rng.randi_range(0, 3), 128*Globals.rng.randi_range(0, 1), 48, 128)
	
	motion_controller = self.get_node("MotionController")
	if starting_weapon != null:
		var new_weapon = starting_weapon.instance()
		self.equip(new_weapon)

func equip(new_weapon):
	# Unequip the old one maybe.
	if self.weapon != null:
		self.remove_child(self.weapon)
		self.weapon.queue_free()
	self.add_child(new_weapon)
	self.weapon = new_weapon

func _process(delta):
	if motion_controller != null:
		motion_controller.update()
		var direction = Vector2(motion_controller.get_x_axis(), motion_controller.get_y_axis())
		self.move_direction = direction
		if direction:
			self.face_direction = direction
		fire = motion_controller.get_fire_button()
		interact = motion_controller.get_interact_button()
	self.move_and_slide(move_direction.normalized() * move_speed)
	
	if fire and weapon != null:
		weapon.fire()
	
	_update_animations()

func _update_animations():
	# Some animation handling
	var state_machine:AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]
	if self.move_direction:
		state_machine.travel("Moving")
		anim_tree["parameters/Moving/blend_position"] = self.move_direction
	else:
		state_machine.travel("Idle")
		anim_tree["parameters/Idle/blend_position"] = self.face_direction
