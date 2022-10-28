extends KinematicBody2D

onready var Attack_delay := $Attack_delay

var direction := Vector2.ZERO
export var speed := 5
export var weapon_damage := 20
var target_player = null

puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_direction = Vector2() setget puppet_direction_set

func puppet_position_set(new_value):
	puppet_position = new_value
	$Tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	$Tween.start()

func puppet_direction_set(new_value):
	puppet_direction = new_value

func _ready():
	for player in Persistent_nodes.get_children():
		# this will focus first valid player
		if is_instance_valid(player):
			target_player = player
			break

func _physics_process(_delta):
	direction = Vector2.ZERO
	if is_instance_valid(target_player):
		# normalized, bc we dont want get float vector
		direction = global_position.direction_to(target_player.global_position).normalized()
		
		# we will call function on player "damage" with value "weapon_damage"
		for player in $AttackDistance.get_overlapping_bodies():
			if player.is_in_group("Player") and Attack_delay.is_stopped():
				player.damage(weapon_damage)
				Attack_delay.start(1)

	var _move = move_and_collide(direction * speed)


func _on_PlayerDetect_body_entered(player):
	if player.is_in_group("Player"):
		target_player = player


func _on_Network_tick_rate_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			self.rset_unreliable("puppet_position", global_position)
			self.rset_unreliable("puppet_direction", direction)
