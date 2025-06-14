extends Node2D

signal leave_for_level(new_level_name)


@onready var level1_opt = $Level1
@onready var level2_opt = $Level2
@onready var player_waiter = $"1pPlayerWaiter"

func reset():
	visible = false
	modulate.a = 0
	level1_opt.disabled = true
	level1_opt.reset()
	level2_opt.disabled = true
	level2_opt.reset()
	player_waiter.reset()


var tween
func enter_scene():
	visible = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 1, 1)
	tween.tween_callback(func():
		level1_opt.disabled = false
		level2_opt.disabled = false
	)
	player_waiter.set_wait_for_player(true)


func _ready():
	level1_opt.all_player_ready.connect(func(): leave_scene('level1_tutorial'))
	level2_opt.all_player_ready.connect(func(): leave_scene('level2_tutorial'))
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
	


func _process(delta: float) -> void:
	pass
