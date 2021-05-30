extends Node2D

export(PackedScene) var projectile
export(float) var muzzle_velocity:float = 3.0
export(float) var firing_rate:float = 1.0
var time_to_refire = 0.0

func _process(delta):
	time_to_refire -= delta

func fire():
	if time_to_refire > 0:
		return

	if firing_rate == 0.0:
		time_to_refire = 0
	else:
		time_to_refire = 1 / firing_rate

	var inst:Node2D = projectile.instance()
	inst.transform = self.get_parent().global_transform
	inst.direction = self.get_parent().face_direction
	inst.speed = self.muzzle_velocity
	inst.shooter = self.get_parent()
	inst.add_to_group("Projectiles")
	get_tree().get_root().add_child(inst)
