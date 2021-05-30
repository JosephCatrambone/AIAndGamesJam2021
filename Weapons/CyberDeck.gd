extends Node2D

export(float) var max_use_distance:float = 32
onready var ray:RayCast2D = $UseRay

func fire():
	# WHAT DID YOU DO, RAY?
	# Find the object to which we want to attach:
	ray.cast_to = self.get_parent().face_direction * max_use_distance
	ray.force_raycast_update()
	var collider = ray.get_collider()
	if collider:
		var cpu = collider.get_node("CPU")
		if cpu:
			Globals.terminal_ref.attach_to_cpu(cpu)
	#inst.transform = self.get_parent().global_transform
	#inst.direction = self.get_parent().face_direction
	#inst.shooter = self.get_parent()
	#inst.add_to_group("Projectiles")
	#get_tree().get_root().add_child(inst)
