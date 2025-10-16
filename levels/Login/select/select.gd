extends Node2D

signal leave_for_level(new_level_name)


@onready var level_options = [$Level1, $Level2, $Level3]
@onready var player_waiter = $"1pPlayerWaiter"

func reset():
	visible = false
	modulate.a = 0
	for level_option in level_options:
		level_option.disabled = true
		level_option.reset()
	player_waiter.reset()


var tween
func enter_scene():
	visible = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 1, 1)
	tween.tween_callback(func():
		for level_option in level_options:
			level_option.disabled = false
	)
	player_waiter.set_wait_for_player(true)


func _ready():
	
	for level_option in level_options:
		level_option.all_player_ready.connect(func(): leave_scene(level_option.level_name))
	player_waiter.player_lost_for_too_long.connect(func(): leave_scene('welcome'))



func leave_scene(new_level_name):
	player_waiter.set_wait_for_player(false)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, 1)
	tween.tween_callback(func():
		reset()
		leave_for_level.emit(new_level_name)
	)
