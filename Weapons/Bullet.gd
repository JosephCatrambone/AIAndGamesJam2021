extends Area2D

signal hit(body)

export(float) var damage
export(float) var speed
var direction:Vector2
var shooter

func _ready():
	self.connect("body_entered", self, "on_hit")

func _process(delta):
	self.translate(self.direction.normalized() * speed * delta)

func on_hit(body):
	if body == self.shooter:
		return  # IGNORE
	else:
		emit_signal("hit", body)
		if body.has_method("damage"):
			body.damage(self.damage)
		self.queue_free()
