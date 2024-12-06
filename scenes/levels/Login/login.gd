extends Node2D



enum Subscene {
	WELCOME,
	LOGOS,
}

@export var tutorial_music: AudioStream


var current_subscene = null
var scene_change_tween

# subscenes
@onready var welcome_subscene = $WelcomeSubscene
@onready var logo_subscene = $LogoSubscene
@onready var level1_1p = $Level1_1p
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 這裡假設 subscene 都會實作 reset()
	# 而且 reset 完以後會消失, 就可以執行 enter_scene 進場
	for subscene in [welcome_subscene, logo_subscene, level1_1p]:
		subscene.reset()

	GlobalAudioPlayer.play_music(tutorial_music, 0.5)

	_connect_transitions()

	welcome_subscene.enter_scene()


func _connect_transitions():
	# 連接 welcome 到 logo scene
	welcome_subscene.go_next_scene.connect(func():
		current_subscene = Subscene.LOGOS
		logo_subscene.enter_scene()
	)

	# 從 LogoSubscene 倒退回 Welcome
	logo_subscene.go_welcome_scene.connect(func():
		current_subscene = Subscene.WELCOME
		welcome_subscene.enter_scene()
	)
	
	logo_subscene.go_tutorial_scene.connect(func(player_num):
		level1_1p.enter_scene()
		#GameState.jump_to_scene_and_play(GameState.GameScene.LEVEL1)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 這是在需要退出這整個子場景的情況下使用
func on_leave():
	GlobalAudioPlayer.fade_out()
