extends Node2D

signal level1_tutorial_1(num_visible_players: int)
signal level1_tutorial_2(num_visible_players: int)
signal level1_tutorial_3(num_visible_players: int)
signal level1_tutorial_4(num_visible_players: int)
signal level1_tutorial_5(num_visible_players: int)
signal level1_tutorial_6(num_visible_players: int)
signal level1_tutorial_end(num_visible_players: int)
signal countdown_3(num_visible_players: int)
signal countdown_2(num_visible_players: int)
signal countdown_1(num_visible_players: int)
signal level1_game_over(num_visible_players: int)

var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0

var previous_level_state: String = ""
var level_state: String:
	get:
		if previous_level_state == "":
			return "tutorial_1"
		if previous_level_state == "tutorial_1" and state_timer >= 3.0:
			return "tutorial_2"
			
		if previous_level_state == "tutorial_2" and tutorial_rotation_count >= 1:
			return "tutorial_3"
			
		if previous_level_state == "tutorial_3" and (tutorial_rotation_count >= 5 or state_timer >= 20.0):
			return "tutorial_4"
			
		if previous_level_state == "tutorial_4" and state_timer >= 3.0:
			return "tutorial_5"
			
		if previous_level_state == "tutorial_5" and state_timer >= 3.0:
			return "tutorial_6"
			
		if previous_level_state == "tutorial_6" and state_timer >= 3.0:
			return "tutorial_end"
			
		if previous_level_state == "tutorial_end" and state_timer >= 3.0:
			return "countdown"
			
		if previous_level_state == "countdown":
			if state_timer >= 3.0:
				return "game"
			else:
				return "countdown"
				
		return previous_level_state

var tutorial_rotation_count: int = 0
var state_timer: float = 0.0

func set_tutorial_player_visible(visible: bool) -> void:
	var tutorial_player = $LoginTutorialPlayer if num_visible_players == 1 else $LoginTutorialPlayer2
	tutorial_player.visible = visible

func _ready():
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player.visible:
			player.connect("rotation_detected", _on_player_rotation_detected)
			num_visible_players += 1

	DebugMessage.info("num_visible_players: " + str(num_visible_players))
	# Start the turbine animations
	$Player1UI/TurbineBackRotate.play("rotate")
	$Player1UI/TurbineFrontRotate.play("rotate")

func _process(delta):
	state_timer += delta

	var current_state = level_state

	if current_state != previous_level_state:
		DebugMessage.info("current_state: " + current_state)
		DebugMessage.info("previous_level_state: " + previous_level_state)

		# State transition handling
		match previous_level_state:
			"tutorial_4":
				$HUD.hide()
			"tutorial_5":
				$HUD.show()
		
		# Reset timer on state change
		state_timer = 0.0

		# Emit signals for new state
		match current_state:
			"tutorial_1":
				set_tutorial_player_visible(true)
				level1_tutorial_1.emit(num_visible_players)
			"tutorial_2":
				set_tutorial_player_visible(false)
				level1_tutorial_2.emit(num_visible_players)
			"tutorial_3":
				level1_tutorial_3.emit(num_visible_players)
			"tutorial_4":
				level1_tutorial_4.emit(num_visible_players)
			"tutorial_5":
				level1_tutorial_5.emit(num_visible_players)
			"tutorial_6":
				level1_tutorial_6.emit(num_visible_players)
			"tutorial_end":
				level1_tutorial_end.emit(num_visible_players)
			"game_over":
				level1_game_over.emit(num_visible_players)
		
		previous_level_state = current_state
	
	# Handle countdown state separately since it needs continuous updates
	if current_state == "countdown":
		if state_timer < 1.0:
			countdown_3.emit(num_visible_players)
		elif state_timer < 2.0:
			countdown_2.emit(num_visible_players)
		elif state_timer < 3.0:
			countdown_1.emit(num_visible_players)


func _on_player_rotation_detected(_player: Node2D, clockwise: bool, speed: float):
	$Player1UI/TurbineBackRotate.speed_scale = speed * (1 if clockwise else -1) * 3
	$Player1UI/TurbineFrontRotate.speed_scale = speed * (1 if clockwise else -1) * 3
