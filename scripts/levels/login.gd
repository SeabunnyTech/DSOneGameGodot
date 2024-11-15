extends Node2D

@onready var login_logo_container = $LoginLogoContainer
@onready var login_tutorial_container = $LoginTutorialContainer
@onready var login_select_level_container = $LoginSelectLevelContainer

@onready var login_logo = $LoginLogoContainer/LoginLogo
@onready var login_portal = $LoginLogoContainer/Portal
@onready var login_logo2 = $LoginLogoContainer/LoginLogo2
@onready var login_portal2 = $LoginLogoContainer/Portal2

@onready var tutorial_player = $LoginTutorialContainer/LoginTutorialPlayer
@onready var tutorial_portal = $LoginTutorialContainer/Portal
@onready var tutorial_player2 = $LoginTutorialContainer/LoginTutorialPlayer2
@onready var tutorial_portal2 = $LoginTutorialContainer/Portal2

@onready var level1_area = $LoginSelectLevelContainer/Level1
@onready var level1_portal = $LoginSelectLevelContainer/Level1/PortalArea
@onready var level2_area = $LoginSelectLevelContainer/Level2
@onready var level2_portal = $LoginSelectLevelContainer/Level2/PortalArea

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

	login_tutorial_container.hide()
	login_logo_container.show()

	var tween = create_tween()

	# Create parallel tweens for login_logo and login_portal
	tween.set_parallel(true)

	tween.tween_property(login_logo, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(login_portal, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	login_logo_container.z_index = -1 # TODO: Fix login logo is on top of playerss
	
	login_logo_container.portal_signup.connect(_on_portal_signup)
	login_logo_container.portal_signup_exited.connect(_on_portal_signup_exited)
	login_tutorial_container.portal_ready.connect(_on_portal_ready)
	login_tutorial_container.portal_ready_exited.connect(_on_portal_ready_exited)

	# Set initial colors using PlayerManager colors
	set_logo_color(login_logo, PlayerManager.player_colors.player1.inactive)
	set_logo_color(login_portal, PlayerManager.player_colors.player1.inactive.lightened(0.5))

	# Connect visibility changed signals
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("visibility_changed", _on_player_visibility_changed.bind(player))
			player.connect("countdown_complete", _on_player_countdown_complete)

	# Connect level selection areas
	level1_portal.body_entered.connect(func(body): _on_select_level_area_entered(body, "level1"))
	level1_portal.body_exited.connect(_on_select_level_area_exited)
	
	level2_portal.body_entered.connect(func(body): _on_select_level_area_entered(body, "level2"))
	level2_portal.body_exited.connect(_on_select_level_area_exited)
	
func _process(_delta):
	var current_state = login_state
	var current_num_visible_players = visible_players.length_squared()

	if current_state != previous_login_state:
		# State has changed, emit appropriate signals
		match current_state:
			"start":
				transition_to_scene("signup")
				login_start.emit()
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
				login_select_level.emit()
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

func set_logo_color(node, new_color: Color, duration: float = 0.5):

	var tween = create_tween()

	if node.material is ShaderMaterial:
		if not node.material.resource_local_to_scene:
			node.material = node.material.duplicate()
		var current_color = node.material.get_shader_parameter("tint_color")
		tween.tween_method(
			func(c): node.material.set_shader_parameter("tint_color", c),
			current_color,
			new_color,
			duration
		)
	else:
		var current_color = node.modulate
		tween.tween_property(node, "modulate", new_color, duration)
		tween.tween_property(node, "modulate:a", current_color.a * new_color.a, duration)

func create_ripple_effect(node):
	var tween = create_tween()
	
	# 波紋擴散效果
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 0.8, 1.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	# 重置到初始狀態
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(node, "modulate:a", 1.0, 0.0)
	tween.finished.connect(func(): 
		if node.visible:  # Only restart if still visible
			create_ripple_effect(node))

func create_droplet_merge(node):
	var tween = create_tween()
	# 先向兩側分開
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.4) \
		.set_trans(Tween.TRANS_SINE)
	# 快速合併並向上突起
	tween.tween_property(node, "scale", Vector2(0.9, 1.1), 0.2) \
		.set_trans(Tween.TRANS_CUBIC)
	# 壓扁效果
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.2) \
		.set_trans(Tween.TRANS_BOUNCE)
	# 輕微震盪
	tween.tween_property(node, "scale", Vector2(0.95, 1.05), 0.15) \
		.set_trans(Tween.TRANS_SINE)
	# 恢復正常
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.6)

	tween.finished.connect(func(): 
		if node.visible:  # Only restart if still visible
			create_droplet_merge(node))

func show_player2_logo():
	login_logo2.visible = true
	login_portal2.visible = true
	
	# Animate the new logo
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(login_logo2, "scale", Vector2(1, 1), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(login_portal2, "scale", Vector2(1, 1), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func hide_player2_logo():
	if login_logo2.visible:
		# First, kill any running animations
		var kill_tween = create_tween()
		kill_tween.tween_callback(func():
			# Reset to normal scale before starting hide animation
			login_logo2.scale = Vector2(0.1, 0.1)
			login_portal2.scale = Vector2(0.1, 0.1)
		)
		await kill_tween.finished

		# Animate back to player1's position before hiding
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(login_logo, "position", login_logo.position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(login_portal, "position", login_portal.position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

		await tween.finished

		# Second tween for scale
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(login_logo2, "scale", Vector2(0.1, 0.1), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(login_portal2, "scale", Vector2(0.1, 0.1), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.finished.connect(func():
			login_logo2.visible = false
			login_portal2.visible = false
			login_logo2.scale = Vector2(0.1, 0.1)
			login_portal2.scale = Vector2(0.1, 0.1)
		)

		await tween.finished
		position_portals("signup") # Animate player1 logo back to center
		
func position_portals(scene: String = "signup"):
	var screen_width = get_viewport_rect().size.x
	var target_pos_x_1 = screen_width / 2
	var target_pos_x_2 = 2 * screen_width / 3

	var tween = create_tween()
	tween.set_parallel(true)

	match scene:
		"signup":
			if login_logo2.visible:
				target_pos_x_1 = screen_width / 3
			tween.tween_property(login_logo, "position:x", target_pos_x_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(login_portal, "position:x", target_pos_x_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(login_logo2, "position:x", target_pos_x_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(login_portal2, "position:x", target_pos_x_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		"tutorial":
			if tutorial_player2.visible:
				target_pos_x_1 = screen_width / 3
			tween.tween_property(tutorial_player, "position:x", target_pos_x_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(tutorial_portal, "position:x", target_pos_x_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(tutorial_player2, "position:x", target_pos_x_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(tutorial_portal2, "position:x", target_pos_x_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

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
			tween.tween_property(login_tutorial_container, "modulate:a", 0.0, 1.0)
			tween.tween_property(login_logo_container, "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				login_logo_container.show()
				login_tutorial_container.hide()
				login_select_level_container.hide()
				enable_portal_detection(login_portal)
				enable_portal_detection(login_portal2)
				disable_portal_detection(tutorial_portal)
				disable_portal_detection(tutorial_portal2)
				disable_portal_detection(level1_area)
				disable_portal_detection(level2_area)
			)
		"tutorial":
			# Fade out login logo
			tween.tween_property(login_logo_container, "modulate:a", 0.0, 1.0)
			tween.tween_property(login_tutorial_container, "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				login_logo_container.hide()
				login_tutorial_container.show()
				login_select_level_container.hide()
				disable_portal_detection(login_portal)
				disable_portal_detection(login_portal2)
				enable_portal_detection(tutorial_portal)
				enable_portal_detection(tutorial_portal2)
				disable_portal_detection(level1_area)
				disable_portal_detection(level2_area)
			)
		"select_level":
			tween.tween_property(login_tutorial_container, "modulate:a", 0.0, 1.0)
			tween.tween_property(login_logo_container, "modulate:a", 1.0, 1.0)
			tween.finished.connect(func():
				login_tutorial_container.hide()
				login_logo_container.hide()
				login_select_level_container.show()
				disable_portal_detection(login_portal)
				disable_portal_detection(login_portal2)
				disable_portal_detection(tutorial_portal)
				disable_portal_detection(tutorial_portal2)
				enable_portal_detection(level1_area)
				enable_portal_detection(level2_area)
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
		set_logo_color(
			login_portal if is_player1 else login_portal2, 
			Color.hex(0x0164827F)
		)

func _on_portal_signup_exited(player: Node):
	var is_player1 = player == PlayerManager.player1
	signup_players[0 if is_player1 else 1] = 0
	
	var player_colors = PlayerManager.player_colors.player1 if is_player1 else PlayerManager.player_colors.player2

	if is_player1:
		set_logo_color(login_logo, player_colors.active)
		set_logo_color(login_portal, player_colors.active.lightened(0.5))
	else:
		set_logo_color(login_logo2, player_colors.active)
		set_logo_color(login_portal2, player_colors.active.lightened(0.5))

func _on_portal_ready(player: Node):
	ready_players[0 if player == PlayerManager.player1 else 1] = 1

func _on_portal_ready_exited(player: Node):
	ready_players[0 if player == PlayerManager.player1 else 1] = 0

func _on_player_visibility_changed(player: Node2D):
	var is_player1 = player == PlayerManager.player1
	var player_colors = PlayerManager.player_colors.player1 if is_player1 else PlayerManager.player_colors.player2
	var logo = login_logo if is_player1 else login_logo2
	var portal = login_portal if is_player1 else login_portal2
	
	if player.visible:
		if is_player1:
			visible_players[0] = 1
		else:
			visible_players[1] = 1
			tutorial_player2.visible = true
			tutorial_portal2.visible = true
			show_player2_logo()
			
		set_logo_color(logo, player_colors.active)
		set_logo_color(portal, player_colors.active.lightened(0.5))
		create_droplet_merge(logo)
		create_ripple_effect(portal)
	else:
		if is_player1:
			visible_players[0] = 0
			set_logo_color(logo, player_colors.inactive)
			set_logo_color(portal, player_colors.inactive.lightened(0.5))
		else:
			visible_players[1] = 0
			tutorial_player2.visible = false
			tutorial_portal2.visible = false
			hide_player2_logo()
			
		if signup_players[1 if not is_player1 else 0] == 1:
			_on_portal_signup_exited(player)

	position_portals(login_state)

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
