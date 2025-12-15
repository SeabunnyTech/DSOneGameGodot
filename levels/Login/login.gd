extends Control


# 使用一個 dict 避免需要新增變數名稱
var level_res_paths = {
	"welcome"	:	"res://levels/Login/welcome/welcome.tscn",
	"logos"		:	"res://levels/Login/logos/logos.tscn",
	"select"		:	"res://levels/Login/select/select.tscn",
	"level1_tutorial"	:	"res://levels/wheelgame/level1_1p_tutorial.tscn",
	"level1_1p"	:	"res://levels/wheelgame/level1_1p.tscn",
	"level1_2p"	:	'res://levels/wheelgame/level1_2p.tscn',
	"level2_tutorial"	:	"res://levels/level2/level2_tutorial.tscn",
	"level2_1p"	:	"res://levels/level2/level2_1p.tscn",
	"level2_2p"	:	"res://levels/level2/level2_2p.tscn",
	"level3_tutorial"	:	"res://levels/solargame/level3_tutorial.tscn",
	"level3_1p"	:	"res://levels/solargame/level3_1p.tscn",
	"level3_2p"	:	"res://levels/solargame/level3_2p.tscn",}

var level_objs = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 這裡假設 subscene 都會實作 reset()
	# 而且 reset 完以後會消失, 就可以執行 enter_scene 進場
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)

	# 先 preload 所有 level
	for level_name in level_res_paths:
		level_objs[level_name] = load(level_res_paths[level_name])

	enter_scene("level3_2p")
	#enter_scene("level3_tutorial")
	#enter_scene("level1_tutorial")
	#enter_scene("welcome")


func enter_scene(scene_name):
	var new_scene = level_objs[scene_name].instantiate()

	# 必須先 add_child 才能觸發 on ready
	add_child(new_scene)

	# 相容先前的做法: 先 reset 再 enter_scene()
	print('entering ', scene_name)
	new_scene.reset()
	new_scene.enter_scene()

	# 連接轉換信號
	new_scene.leave_for_level.connect(func(new_level_name):
		enter_scene(new_level_name)
		new_scene.queue_free()
	)



# 這是在需要退出這整個子場景的情況下使用
func on_leave():
	GlobalAudioPlayer.fade_out()
