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

# TODO: 寫法還是不理想，要讓 node 更降低耦合度才行
@onready var player_visuals: Dictionary = {
	"player1": {
		"logo": logos["player1"]["logo"],
		"portal": logos["player1"]["portal"],
		"colors": PlayerManager.player_colors["player1"],
		"tutorial_elements": {}
	},
	"player2": {
		"logo": logos["player2"]["logo"],
		"portal": logos["player2"]["portal"],
		"colors": PlayerManager.player_colors["player2"],
		"tutorial_elements": {
			"mimic_player": tutorial["player2"]["mimic_player"],
			"portal": tutorial["player2"]["portal"]
		}
	}
}

var screen_width = Globals.get_viewport_size().x

func _ready():
	GameState.login_state_updated.connect(_on_login_state_updated)

	containers["logo"].show()
	containers["tutorial"].hide()
	
	# TODO: 這裡的動畫是物理效果，可以移到別的位置
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(logos["player1"]["logo"], "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(logos["player1"]["portal"], "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	containers["logo"].z_index = -1

	# Set initial colors using PlayerManager colors
	LoginAnimations.set_logo_color(logos["player1"]["logo"], PlayerManager.player_colors.player1.inactive)
	LoginAnimations.set_logo_color(logos["player1"]["portal"], PlayerManager.player_colors.player1.inactive.lightened(0.5))


	# Connect level selection areas
	# TODO: 放到 game_state 裡面
	level_areas["level1"]["portal"].body_entered.connect(func(body): _on_level_portal_entered(body, "level1"))
	level_areas["level1"]["portal"].body_exited.connect(func(body): _on_level_portal_exited(body, "level1"))
	
	level_areas["level2"]["portal"].body_entered.connect(func(body): _on_level_portal_entered(body, "level2"))
	level_areas["level2"]["portal"].body_exited.connect(func(body): _on_level_portal_exited(body, "level2"))

func _process(_delta):
	pass

func position_portals(scene: GameState.GameStage):
	var target_pos_x_1 = screen_width / 2
	var target_pos_x_2 = 2 * screen_width / 3
	
	match scene:
		GameState.GameStage.LOGIN_SIGNUP:
			if logos["player2"]["logo"].visible:
				target_pos_x_1 = screen_width / 3
			LoginAnimations.tween_signup_positions(self, logos, target_pos_x_1, target_pos_x_2)
		GameState.GameStage.LOGIN_TUTORIAL:
			if tutorial["player2"]["mimic_player"].visible:
				target_pos_x_1 = screen_width / 3
			LoginAnimations.tween_tutorial_positions(self, tutorial, target_pos_x_1, target_pos_x_2)

func disable_portal_detection(portal: Sprite2D):
	portal.get_node("PortalArea").set_deferred("monitoring", false)
	portal.get_node("PortalArea").set_deferred("monitorable", false)

func enable_portal_detection(portal: Sprite2D):
	portal.get_node("PortalArea").set_deferred("monitoring", true)
	portal.get_node("PortalArea").set_deferred("monitorable", true)

func transition_to_next_level():
	# Add a short delay before transitioning
	await get_tree().create_timer(3.0).timeout
	# Replace this with your actual code to load the next level
	print("Transitioning to the next level")
	# get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _on_login_state_updated(state_info: Dictionary):
	# DebugMessage.info("login_state_updated: %s" % state_info)
	match state_info.stage:
		GameState.GameStage.LOGIN_START:
			_handle_login_start(state_info)
		GameState.GameStage.LOGIN_SIGNUP:
			_handle_login_signup(state_info)
		GameState.GameStage.LOGIN_WAIT_FOR_SECOND_PLAYER:
			_handle_wait_for_player(state_info)
		GameState.GameStage.LOGIN_TUTORIAL:
			_handle_tutorial(state_info)
		GameState.GameStage.LOGIN_SELECT_LEVEL:
			_handle_level_select(state_info)

# TODO: 以下 handler 中的 tween 寫法還是不理想，之後可以合併
func _handle_login_start(_state_info: Dictionary) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
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

func _handle_login_signup(state_info: Dictionary) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(containers["logo"], "modulate:a", 1.0, 1.0)
	tween.tween_property(containers["tutorial"], "modulate:a", 0.0, 1.0)
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

	_handle_player_visibility_animation("player1", state_info.get("player1_visible", false), state_info)
	_handle_player_visibility_animation("player2", state_info.get("player2_visible", false), state_info)

func _handle_wait_for_player(state_info: Dictionary) -> void:
	# # 顯示等待第二位玩家的 UI
	containers["logo"].show()
	containers["tutorial"].hide()
	
	for player_id in ["player1", "player2"]:
		var _is_visible = state_info[player_id + "_visible"]
		var logo = logos[player_id]["logo"]
		var portal = logos[player_id]["portal"]
		
		if not _is_visible and player_id == "player2":
			tutorial["player2"]["mimic_player"].visible = false
			tutorial["player2"]["portal"].visible = false
			await LoginAnimations.hide_logo(logos)
			logo.visible = false
			portal.visible = false
	
func _handle_tutorial(state_info: Dictionary) -> void:
	# 顯示教學 UI
	
	var tween = create_tween()
	tween.set_parallel(true)
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

	_handle_player_visibility_animation("player1", state_info.get("player1_visible", false), state_info)
	_handle_player_visibility_animation("player2", state_info.get("player2_visible", false), state_info)

func _handle_level_select(_state_info: Dictionary) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
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

func _handle_player_visibility_animation(player_id: String, _is_visible: bool, state_info: Dictionary) -> void:
	var visuals = player_visuals[player_id]
	
	if _is_visible:
		_show_player_visuals(player_id, visuals, state_info)
	else:
		_hide_player_visuals(player_id, visuals, state_info)

func _show_player_visuals(player_id: String, visuals: Dictionary, state_info: Dictionary) -> void:
	# 處理基本視覺元素
	visuals.logo.visible = true
	visuals.portal.visible = true
	
	# 處理玩家特定的教學元素
	if player_id == "player2" and visuals.tutorial_elements:
		_show_tutorial_elements(visuals.tutorial_elements)
	
	# 應用視覺效果
	_apply_visual_effects(visuals, true)
	
	# 更新位置
	position_portals(state_info.stage)

func _hide_player_visuals(player_id: String, visuals: Dictionary, state_info: Dictionary) -> void:
	if player_id == "player1":
		# Player 1 只需要改變顏色
		_apply_inactive_colors(visuals)
	else:
		# Player 2 需要隱藏所有元素
		await _hide_player2_elements(visuals)
		position_portals(state_info.stage)

func _show_tutorial_elements(elements: Dictionary) -> void:
	for element in elements.values():
		element.visible = true

func _hide_tutorial_elements(elements: Dictionary) -> void:
	for element in elements.values():
		element.visible = false

func _apply_visual_effects(visuals: Dictionary, is_active: bool) -> void:
	var color = visuals.colors.active if is_active else visuals.colors.inactive
	var portal_color = color.lightened(0.5)
	
	LoginAnimations.set_logo_color(visuals.logo, color)
	LoginAnimations.set_logo_color(visuals.portal, portal_color)
	
	if is_active:
		LoginAnimations.create_droplet_merge(visuals.logo)
		LoginAnimations.create_ripple_effect(visuals.portal)

func _apply_inactive_colors(visuals: Dictionary) -> void:
	_apply_visual_effects(visuals, false)

func _hide_player2_elements(visuals: Dictionary) -> void:
	await LoginAnimations.hide_logo(logos)
	visuals.logo.visible = false
	visuals.portal.visible = false
	if visuals.tutorial_elements:
		_hide_tutorial_elements(visuals.tutorial_elements)

func _on_level_portal_entered(player: Node, level: String) -> void:
	if player.visible:
		SignalBus.level_portal_entered.emit(player, level)

func _on_level_portal_exited(player: Node, level: String) -> void:
	SignalBus.level_portal_exited.emit(player, level)

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

func _exit_tree():
	PlayerManager.clear_viewports()
