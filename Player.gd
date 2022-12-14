extends KinematicBody2D

var speed := 500
var velocity := Vector2()

onready var tween := $Tween
onready var camera := $Camera2D

puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_velocity = Vector2() setget puppet_velocity_set

func puppet_velocity_set(new_value) -> void:
	puppet_position = new_value

func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	tween.start()

func _ready():
	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			camera.make_current()

func _process(_delta) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			velocity = Vector2()
			
			if Input.is_action_pressed("ui_left"):
				velocity.x -= 1

			if Input.is_action_pressed("ui_right"):
				velocity.x += 1

			if Input.is_action_pressed("ui_up"):
				velocity.y -= 1

			if Input.is_action_pressed("ui_down"):
				velocity.y += 1
			
			velocity = velocity.normalized() * speed
			velocity = move_and_slide(velocity)
		else:
			if not tween.is_active():
				move_and_slide(puppet_velocity * speed)

puppet var puppet_hp = max_puppet_hp setget puppet_hp_set
puppet var max_puppet_hp = 100
var health := 100
var max_health := health

func puppet_hp_set(new_value):
	puppet_hp = clamp(new_value, 0, max_puppet_hp)
	if get_tree().has_network_peer():
		if not is_network_master():
			health = puppet_hp

func damage(dmg):
	var value = health - dmg
	health = clamp(value, 0, max_health)

	if get_tree().has_network_peer():
		if is_network_master():
			rset("puppet_hp", health)
			if health <= 0:
				self.rpc("die")

sync func die() -> void:
	self.queue_free()


sync func update_position(pos):
	# function for updating player position outside this script
	global_position = pos
	puppet_position = pos

func _on_Network_tick_rate_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			self.rset_unreliable("puppet_position", global_position)
			self.rset_unreliable("puppet_velocity", velocity)
