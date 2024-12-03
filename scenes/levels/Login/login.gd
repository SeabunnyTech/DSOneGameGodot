extends Node2D



enum Subscene {
	WELCOME,
	LOGOS,
}

var current_subscene = null
var scene_change_tween

# subscenes
@onready var welcome_subscene = $WelcomeSubscene
@onready var logo_subscene = $LogoSubscene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 這裡假設 subscene 都會實作 reset()
	# 而且 reset 完以後會消失, 就可以執行 enter_scene 進場
	for subscene in [welcome_subscene, logo_subscene]:
		subscene.reset()

	_fade_audio_stream($BackgroundMusic, true, 0.5)

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
		GameState.update_scene(GameState.GameScene.LEVEL1)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func on_leave():
	_fade_audio_stream($BackgroundMusic)



func _fade_audio_stream(audio_player, fade_in=false, duration = 2):
	var audio_tween = create_tween()
	var start_volume_db = -80.0 if fade_in else -10.0
	var target_volume_db = -10.0 if fade_in else -80.0

	audio_player.volume_db = start_volume_db
	audio_tween.tween_property(audio_player, "volume_db", target_volume_db, duration)
	if fade_in:
		audio_player.play()
	else:
		audio_tween.tween_callback(audio_player.stop)
