extends Node2D

signal level1_tutorial_1(num_visible_players: int)
signal level1_tutorial_2(num_visible_players: int)
signal level1_tutorial_3(num_visible_players: int)
signal level1_tutorial_4(num_visible_players: int)
signal level1_tutorial_5(num_visible_players: int)
signal level1_tutorial_6(num_visible_players: int)
signal level1_tutorial_end(num_visible_players: int)
signal level1_countdown_3(num_visible_players: int)
signal level1_countdown_2(num_visible_players: int)
signal level1_countdown_1(num_visible_players: int)
signal level1_game_mode(num_visible_players: int)
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
			
		if previous_level_state == "tutorial_2" and rotation_count >= 1:
			return "tutorial_3"
			
		if previous_level_state == "tutorial_3" and (rotation_count >= 5 or state_timer >= 20.0):
			return "tutorial_4"
			
		if previous_level_state == "tutorial_4" and state_timer >= 5.0:
			return "tutorial_5"
			
		if previous_level_state == "tutorial_5" and state_timer >= 5.0:
			return "tutorial_6"
			
		if previous_level_state == "tutorial_6" and state_timer >= 5.0:
			rotation_count = 0
			return "tutorial_end"
			
		if previous_level_state == "tutorial_end" and state_timer >= 3.0:
			return "countdown"
			
		if previous_level_state == "countdown" and state_timer >= 3.0:
			return "game_mode"
				
		return previous_level_state

var rotation_count: int = 0
var state_timer: float = 0.0

const Electron = preload("res://scenes/characters/electron.tscn")
var electrons = []
var electron_container: Node2D
var max_electrons = 20

func spawn_electron(spawn_position: Vector2, target_position: Vector2):
	if electrons.size() >= max_electrons:
		return
	
	var electron = Electron.instantiate()
	electron_container.add_child(electron, true)
	electron.position = spawn_position
	
	# Random type based on rotation speed
	var random_type = randi() % 3  # Returns 0, 1, or 2
	electron.set_type(random_type)
	
	electrons.append(electron)

func set_tutorial_player_visible(toggle_visible: bool) -> void:
	var tutorial_player = $TutorialMimicPlayer if num_visible_players == 1 else $TutorialMimicPlayer2
	tutorial_player.visible = toggle_visible

func _ready():
	electron_container = Node2D.new()
	electron_container.name = "Electrons"
	$".".add_child(electron_container)  # Add to Player1UI instead of root
	
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player.visible:
			player.connect("rotation_detected", _on_player_rotation_detected)
			player.connect("full_rotation_completed", _on_player_full_rotation_completed)
			num_visible_players += 1

	# Start the turbine animations
	$Player1UI/TurbineBackRotate.play("rotate")
	$Player1UI/TurbineFrontRotate.play("rotate")

func _process(delta):
	state_timer += delta

	var current_state = level_state

	if current_state != previous_level_state:
		DebugMessage.info("current_state: " + current_state)
		DebugMessage.info("previous_level_state: " + previous_level_state)

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
				rotation_count = 0
				level1_tutorial_end.emit(num_visible_players)
			"game_mode":
				level1_game_mode.emit(num_visible_players)
			"game_over":
				level1_game_over.emit(num_visible_players)
		
		previous_level_state = current_state
	
	# Handle countdown state separately since it needs continuous updates
	if current_state == "countdown":
		if state_timer < 1.0:
			level1_countdown_3.emit(num_visible_players)
		elif state_timer < 2.0:
			level1_countdown_2.emit(num_visible_players)
		elif state_timer < 3.0:
			level1_countdown_1.emit(num_visible_players)
	
	if current_state == "game_mode":
		DebugMessage.info("rotation_count: " + str(rotation_count))
		pass

func _on_player_rotation_detected(_player: Node2D, clockwise: bool, speed: float):
	$Player1UI/TurbineBackRotate.speed_scale = speed * (1 if clockwise else -1) * 3
	$Player1UI/TurbineFrontRotate.speed_scale = speed * (1 if clockwise else -1) * 3

func _on_player_full_rotation_completed(_player: Node2D, clockwise: bool):
	rotation_count += 1

	var spawn_pos = _player.position
	var target_pos = $Player1UI/TurbineFrontRotate.position
	spawn_electron(spawn_pos, target_pos)
