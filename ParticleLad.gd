extends Sprite

var y_vel
var x_vel
var rot_vel

func _ready():
	randomize()
	y_vel = -rand_range(200, 400)
	x_vel = rand_range(-200, 200)
	rot_vel = rand_range(40, 160) * sign(x_vel)

func _process(dt):
	y_vel += 600 * dt
	
	global_position.x += x_vel * dt
	global_position.y += y_vel * dt
	rotation_degrees += rot_vel * dt
	
	if global_position.y > 800:
		queue_free()
