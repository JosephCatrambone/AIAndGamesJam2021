extends StaticBody2D

onready var anim_player:AnimationPlayer = $AnimationPlayer
#onready var anim_tree:AnimationTree = $AnimationTree
#var state_machine:AnimationNodeStateMachinePlayback

# For checking the cards.
onready var cpu = $CPU

var countdown_active:bool = true
export(float) var time_to_close:float = 1.0
var time_until_close:float = 0.0

func _ready():
	#state_machine = anim_tree["parameters/playback"]
	#state_machine.start("Idle_Closed")
	close()

func _process(delta):
	if countdown_active:
		if time_until_close <= 0:
			time_until_close = 0.0
		else:
			time_until_close -= delta
			# If we _transition_ to below zero, close this.
			if time_until_close < 0:
				close()

	#anim_tree["parameters/conditions/closed"] = time_until_close <= 0.0
	#anim_tree["parameters/conditions/open"] = time_until_close > 0

func open():
	anim_player.play("Opening")
	yield(anim_player, "animation_finished")
	anim_player.play("Idle_Open")
	#state_machine.travel("Idle_Open")

func close():
	countdown_active = false
	time_until_close = 0.0
	anim_player.play("Closing")
	yield(anim_player, "animation_finished")
	anim_player.play("Idle_Closed")
	#state_machine.travel("Idle_Closed")

func _on_proximity_enter(body):
	# If two people walk by, don't replay the animation but reset the close time.
	if time_until_close <= 0 and should_open(body):
		open()

func _on_proximity_exit(body):
	if is_open():
		# Don't start countdown until someone leaves.
		countdown_active = true
		time_until_close = time_to_close
	
func is_open():
	return time_until_close >= 0

func should_open(body):
	# Check if the body has a card.  If so, load those instructions for a check.
	# Load our CPU and run 100 steps.
	cpu.memory[0xF0] = 0x00
	cpu.memory[0xF1] = 0x01
	cpu.memory[0xF2] = 0x02
	cpu.memory[0xF3] = 0x03
	cpu.memory[0xE0] = 0x01  # Start!
	for _i in range(100):
		cpu.step()
	return  cpu.memory[0xE1] == 0x01
