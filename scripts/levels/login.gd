extends Node2D

# 改成比較好維護，可讀性高，也比較安全的 subnode 初始化方式
@onready var containers: Dictionary = {
	"logo": $LoginLogoContainer,
	"tutorial": $LoginTutorialContainer,
	"select_level": $LoginSelectLevelContainer
}

@onready var logos: Dictionary = {
	"player1": {
		"logo": $LoginLogoContainer/LoginLogo,
		"portal": $LoginLogoContainer/Portal
	},
	"player2": {
		"logo": $LoginLogoContainer/LoginLogo2,
		"portal": $LoginLogoContainer/Portal2
	}
}

@onready var tutorial: Dictionary = {
	"player1": {
		"mimic_player": $LoginTutorialContainer/LoginTutorialMimicPlayer,
		"portal": $LoginTutorialContainer/Portal
	},
	"player2": {
		"mimic_player": $LoginTutorialContainer/LoginTutorialMimicPlayer2,
		"portal": $LoginTutorialContainer/Portal2
	}
}

@onready var level_areas: Dictionary = {
	"level1": {
		"area": $LoginSelectLevelContainer/Level1,
		"portal": $LoginSelectLevelContainer/Level1/PortalArea
	},
	"level2": {
		"area": $LoginSelectLevelContainer/Level2,
		"portal": $LoginSelectLevelContainer/Level2/PortalArea
	}
}

signal login_start
signal login_signup(num_visible_players: int)
signal login_wait_for_players
signal login_tutorial(num_visible_players: int)
signal login_select_level
signal logout

var portal_detection_enabled: bool = true

var visible_players = Vector2i(0, 0) # (player1, player2) where 1=visible, 0=invisible
var signup_players = Vector2i(0, 0) # (player1, player2) where 1=signed up, 0=not signed up
var ready_players = Vector2i(0, 0) # (player1, player2) where 1=ready, 0=not ready

var screen_width = Globals.get_viewport_size().x
var previous_num_visible_players: int = 0
var previous_login_state: String = "start"
var login_state: String:
	get:
		var num_visible_players = visible_players.length_squared()
		var num_signup_players = signup_players.length_squared()
		# var num_ready_players = ready_players.length_squared()
		
		if num_visible_players == 0:
			return "start"

		if num_signup_players == 0 and previous_login_state == "start":
			return "signup"

		if signup_players[0] == visible_players[0] \
			and signup_players[1] == visible_players[1]:
			return "tutorial"
		elif num_signup_players != 0:
			return "wait_for_players"

		if ready_players[0] == visible_players[0] \
			and ready_players[1] == visible_players[1]:
			return "select_level"

		if previous_login_state == "tutorial":
			return "tutorial"
		elif previous_login_state == "select_level":
			return "select_level"
		else:
			return "signup"

func _ready():
	previous_login_state = login_state
	previous_num_visible_players = visible_players.length_squared()

	containers["logo"].show()
	containers["tutorial"].hide()
	
	# TODO: 這裡的動畫是物理效果，可以移到別的位置
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(logos["player1"]["logo"], "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(logos["player1"]["portal"], "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	containers["logo"].z_index = -1
	containers["logo"].portal_signup.connect(_on_portal_signup)
	containers["logo"].portal_signup_exited.connect(_on_portal_signup_exited)
	containers["tutorial"].portal_ready.connect(_on_portal_ready)
	containers["tutorial"].portal_ready_exited.connect(_on_portal_ready_exited)

	# Set initial colors using PlayerManager colors
	LoginAnimations.set_logo_color(logos["player1"]["logo"], PlayerManager.player_colors.player1.inactive)
	LoginAnimations.set_logo_color(logos["player1"]["portal"], PlayerManager.player_colors.player1.inactive.lightened(0.5))

	# Connect visibility changed signals
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("visibility_changed", _on_player_visibility_changed.bind(player))
			player.connect("countdown_complete", _on_player_countdown_complete)

	# Connect level selection areas
	level_areas["level1"]["portal"].body_entered.connect(func(body): _on_select_level_area_entered(body, "level1"))
	level_areas["level1"]["portal"].body_exited.connect(_on_select_level_area_exited)
	
	level_areas["level2"]["portal"].body_entered.connect(func(body): _on_select_level_area_entered(body, "level2"))
	level_areas["level2"]["portal"].body_exited.connect(_on_select_level_area_exited)
	
func _process(_delta):
	var current_state = login_state
	var current_num_visible_players = visible_players.length_squared()

	if current_state != previous_login_state:
		# State has changed, emit appropriate signals
		match current_state:
			"start":
				transition_to_scene("signup")
				login_start.emit(current_num_visible_players)
			"signup":
				transition_to_scene("signup")
				login_signup.emit(current_num_visible_players)
			"wait_for_players":
				login_wait_for_players.emit()
			"tutorial":
				transition_to_scene("tutorial")
				position_portals("tutorial")
				login_tutorial.emit(current_num_visible_players)
			"select_level":
				transition_to_scene("select_level")
				login_select_level.emit(current_num_visible_players)
			"transition":
				transition_to_next_level()
		
		previous_login_state = current_state

	if current_num_visible_players != previous_num_visible_players:
		match current_state:
			"signup":
				login_signup.emit(current_num_visible_players)
			"tutorial":
				login_tutorial.emit(current_num_visible_players)
		previous_num_visible_players = current_num_visible_players

func position_portals(scene: String = "signup"):
	var target_pos_x_1 = screen_width / 2
	var target_pos_x_2 = 2 * screen_width / 3
	
	match scene:
		"signup":
			if logos["player2"]["logo"].visible:
				target_pos_x_1 = screen_width / 3
			LoginAnimations.tween_signup_positions(self, logos, target_pos_x_1, target_pos_x_2)
		"tutorial":
			if tutorial["player2"]["mimic_player"].visible:
				target_pos_x_1 = screen_width / 3
			LoginAnimations.tween_tutorial_positions(self, tutorial, target_pos_x_1, target_pos_x_2)


func disable_portal_detection(portal: Sprite2D):
	portal.get_node("PortalArea").set_deferred("monitoring", false)
	portal.get_node("PortalArea").set_deferred("monitorable", false)

func enable_portal_detection(portal: Sprite2D):
	portal.get_node("PortalArea").set_deferred("monitoring", true)
	portal.get_node("PortalArea").set_deferred("monitorable", true)

func transition_to_scene(scene: String):
	var tween = create_tween()
	tween.set_parallel(true)
	
	match scene:
		"signup":
			# Fade out tutorial
			tween.tween_property(containers["tutorial"], "modulate:a", 0.0, 1.0)
			tween.tween_property(containers["logo"], "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				containers["logo"].show()
				containers["tutorial"].hide()
				containers["select_level"].hide()
				enable_portal_detection(logos["player1"]["portal"])
				enable_portal_detection(logos["player2"]["portal"])
				disable_portal_detection(tutorial["player1"]["portal"])
				disable_portal_detection(tutorial["player2"]["portal"])
				disable_portal_detection(level_areas["level1"]["area"])
				disable_portal_detection(level_areas["level2"]["area"])
			)
		"tutorial":
			# Fade out login logo
			tween.tween_property(containers["logo"], "modulate:a", 0.0, 1.0)
			tween.tween_property(containers["tutorial"], "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				containers["logo"].hide()
				containers["tutorial"].show()
				containers["select_level"].hide()
				disable_portal_detection(logos["player1"]["portal"])
				disable_portal_detection(logos["player2"]["portal"])
				enable_portal_detection(tutorial["player1"]["portal"])
				enable_portal_detection(tutorial["player2"]["portal"])
				disable_portal_detection(level_areas["level1"]["area"])
				disable_portal_detection(level_areas["level2"]["area"])
			)
		"select_level":
			tween.tween_property(containers["tutorial"], "modulate:a", 0.0, 1.0)
			tween.tween_property(containers["logo"], "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				containers["tutorial"].hide()
				containers["logo"].hide()
				containers["select_level"].show()
				disable_portal_detection(logos["player1"]["portal"])
				disable_portal_detection(logos["player2"]["portal"])
				disable_portal_detection(tutorial["player1"]["portal"])
				disable_portal_detection(tutorial["player2"]["portal"])
				enable_portal_detection(level_areas["level1"]["area"])
				enable_portal_detection(level_areas["level2"]["area"])
			)

func transition_to_next_level():
	# Add a short delay before transitioning
	await get_tree().create_timer(3.0).timeout
	# Replace this with your actual code to load the next level
	print("Transitioning to the next level")
	# get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _on_portal_signup(player: Node):
	var is_player1 = player == PlayerManager.player1
	if player.visible:
		signup_players[0 if is_player1 else 1] = 1
		LoginAnimations.set_logo_color(
			logos["player1"]["portal"] if is_player1 else logos["player2"]["portal"], 
			Color.hex(0x0164827F)
		)

func _on_portal_signup_exited(player: Node):
	var is_player1 = player == PlayerManager.player1
	signup_players[0 if is_player1 else 1] = 0
	
	var player_colors = PlayerManager.player_colors.player1 if is_player1 else PlayerManager.player_colors.player2

	if is_player1:
		LoginAnimations.set_logo_color(logos["player1"]["logo"], player_colors.active)
		LoginAnimations.set_logo_color(logos["player1"]["portal"], player_colors.active.lightened(0.5))
	else:
		LoginAnimations.set_logo_color(logos["player2"]["logo"], player_colors.active)
		LoginAnimations.set_logo_color(logos["player2"]["portal"], player_colors.active.lightened(0.5))

func _on_portal_ready(player: Node):
	ready_players[0 if player == PlayerManager.player1 else 1] = 1

func _on_portal_ready_exited(player: Node):
	ready_players[0 if player == PlayerManager.player1 else 1] = 0

func _on_player_visibility_changed(player: Node2D):
	var is_player1 = player == PlayerManager.player1
	var player_colors = PlayerManager.player_colors.player1 if is_player1 else PlayerManager.player_colors.player2
	var logo = logos["player1"]["logo"] if is_player1 else logos["player2"]["logo"]
	var portal = logos["player1"]["portal"] if is_player1 else logos["player2"]["portal"]

	if player.visible:
		if is_player1:
			visible_players[0] = 1
		else:
			visible_players[1] = 1
			tutorial["player2"]["mimic_player"].visible = true
			tutorial["player2"]["portal"].visible = true
			logo.visible = true
			portal.visible = true
			LoginAnimations.show_logo(logo, portal)
			position_portals(login_state)
			
		LoginAnimations.set_logo_color(logo, player_colors.active)
		LoginAnimations.set_logo_color(portal, player_colors.active.lightened(0.5))
		LoginAnimations.create_droplet_merge(logo)
		LoginAnimations.create_ripple_effect(portal)
	else:
		if is_player1:
			visible_players[0] = 0
			LoginAnimations.set_logo_color(logo, player_colors.inactive)
			LoginAnimations.set_logo_color(portal, player_colors.inactive.lightened(0.5))
		else:
			visible_players[1] = 0
			tutorial["player2"]["mimic_player"].visible = false
			tutorial["player2"]["portal"].visible = false
			await LoginAnimations.hide_logo(logos)
			logos["player2"]["logo"].visible = false
			logos["player2"]["portal"].visible = false
			position_portals(login_state)
			
		if signup_players[1 if not is_player1 else 0] == 1:
			_on_portal_signup_exited(player)

	position_portals("signup")

func _on_player_countdown_complete(player: Node2D):
	var num_ready_players = visible_players.length_squared()

	# Check if we're in select_level state
	if login_state == "select_level":
		PlayerManager.freeze_player_detection = true
		# Add a short delay before transitioning
		await get_tree().create_timer(1.0).timeout
		# Change scene based on number of players
		var scene_path = "res://scenes/levels/%s_%dp.tscn" % [player.selected_level, num_ready_players]
		get_tree().change_scene_to_file(scene_path)

func _on_select_level_area_entered(player: Node2D, level: String) -> void:
	if player.visible:
		# Store the selected level before starting countdown
		player.selected_level = level
		player.start_progress_countdown()

func _on_select_level_area_exited(player: Node2D) -> void:
	player.stop_progress_countdown()

func _on_ui_skip_area_exited(player: Node2D) -> void:
	player.stop_progress_countdown()
	pass # Replace with function body.

func _on_ui_skip_area_entered(player: Node2D) -> void:
	player.start_progress_countdown()
	pass # Replace with function body.

func _on_ui_return_area_exited(player: Node2D) -> void:
	player.stop_progress_countdown()
	pass # Replace with function body.

func _on_ui_return_area_entered(player: Node2D) -> void:
	player.start_progress_countdown()
	pass # Replace with function body.
