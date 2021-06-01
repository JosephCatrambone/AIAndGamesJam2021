extends Navigation2D

func _ready():
	# Register self.
	Globals.navigation_mesh_ref = self
