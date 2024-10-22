extends Node2D


@onready var login_logo_container = $LoginLogoContainer

@onready var login_logo = $LoginLogoContainer/LoginLogo
@onready var portal = $LoginLogoContainer/Portal
@onready var login_logo2 = $LoginLogoContainer/LoginLogo2
@onready var portal2 = $LoginLogoContainer/Portal2

var visible_players: int = 0

signal ready_to_start(players: int)
signal wait_for_players

func _ready():
	var tween = create_tween()

	# Create parallel tweens for login_logo and portal
	tween.set_parallel(true)

	tween.tween_property(login_logo, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(portal, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	login_logo_container.z_index = -1 # TODO: Fix login logo is on top of playerss
	
	login_logo_container.portal_signup.connect(_on_portal_signup)
	login_logo_container.portal_signup_exited.connect(_on_portal_signup_exited)

	# Set initial colors
	set_logo_color(login_logo, Color.hex(0x8F8F8FFF))
	set_logo_color(portal, Color.hex(0x8F8F8F7F))

	# Connect visibility changed signals
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("visibility_changed", _on_player_visibility_changed.bind(player))

func _process(_delta):
	# Level-specific update logic
	pass
	# Other level-specific methods

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
		
func create_breathing_effect(node):
	var tween = create_tween().set_loops() # 設置循環播放
	
	# 放大和縮小的動畫序列
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func create_droplet_effect(node):
	var tween = create_tween().set_loops()
	
	# 初始狀態略微壓縮
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.3)\
		.set_trans(Tween.TRANS_SINE)
	# 落下並壓扁
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.2)\
		.set_trans(Tween.TRANS_CUBIC)
	# 小彈跳
	tween.tween_property(node, "scale", Vector2(0.9, 1.1), 0.15)\
		.set_trans(Tween.TRANS_SINE)
	# 恢復原狀
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.5)

func create_ripple_effect(node):
	var tween = create_tween().set_loops()
	
	# 創建波紋擴散效果
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 0.8, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	# 重置到初始狀態
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(node, "modulate:a", 1.0, 0.0)
	
func create_droplet_merge(node):
	var tween = create_tween().set_loops()
	
	# 先向兩側分開
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.4)\
		.set_trans(Tween.TRANS_SINE)
	# 快速合併並向上突起
	tween.tween_property(node, "scale", Vector2(0.9, 1.1), 0.2)\
		.set_trans(Tween.TRANS_CUBIC)
	# 壓扁效果
	tween.tween_property(node, "scale", Vector2(1.1, 0.9), 0.2)\
		.set_trans(Tween.TRANS_BOUNCE)
	# 輕微震盪
	tween.tween_property(node, "scale", Vector2(0.95, 1.05), 0.15)\
		.set_trans(Tween.TRANS_SINE)
	# 恢復正常
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.25)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.6)

func show_player2_logo():
	login_logo2.visible = true
	portal2.visible = true
	
	# Animate the new logo
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(login_logo2, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(portal2, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func hide_player2_logo():
	if login_logo2.visible:
		# Animate back to player1's position before hiding
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(login_logo, "position", login_logo.position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(portal, "position", login_logo.position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_callback(func():
			login_logo2.visible = false
			portal2.visible = false
			position_logos(false)  # Animate player1 logo back to center
		)
		
func position_logos(animated: bool = false):
	var screen_width = get_viewport_rect().size.x
	var target_pos_1 = Vector2(screen_width / 2, login_logo.position.y)
	var target_pos_2 = Vector2(2 * screen_width / 3, login_logo.position.y)

	var tween = create_tween()
	tween.set_parallel(true)

	if login_logo2.visible:
		target_pos_1.x = screen_width / 3
	
	if animated:
		tween.tween_property(login_logo, "position", target_pos_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(portal, "position", target_pos_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		
		if login_logo2.visible:
			tween.tween_property(login_logo2, "position", target_pos_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(portal2, "position", target_pos_2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	else:
		tween.tween_property(login_logo, "position", target_pos_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(portal, "position", target_pos_1, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		
		if login_logo2.visible:
			login_logo2.position = target_pos_2
			portal2.position = target_pos_2

func transition_to_next_level():
	# Add a short delay before transitioning
	await get_tree().create_timer(1.0).timeout
	# Replace this with your actual code to load the next level
	print("Transitioning to the next level")
	# get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _on_portal_signup(player: Node2D):
	if player == PlayerManager.player1:
		set_logo_color(portal, Color.hex(0x0164827F))
	elif player == PlayerManager.player2:
		set_logo_color(portal2, Color.hex(0x0164827F))

	if visible_players == PlayerManager.current_players.size():
		transition_to_next_level()

func _on_portal_signup_exited(player: Node2D):
	if player == PlayerManager.player1:
		set_logo_color(login_logo, Color.hex(0x00B6EEFF))
		set_logo_color(portal, Color.hex(0x00B6EE3F))
	elif player == PlayerManager.player2:
		set_logo_color(login_logo2, Color.hex(0x006888FF))
		set_logo_color(portal2, Color.hex(0x0068883F))

func _on_player_visibility_changed(player: Node):
	if player == PlayerManager.player1:
		if player.visible:
			visible_players += 1
			set_logo_color(login_logo, Color.hex(0x00B6EEFF))
			set_logo_color(portal, Color.hex(0x00B6EE3F))
			create_droplet_merge(login_logo)
			create_ripple_effect(portal)
		else:
			visible_players -= 1
			set_logo_color(login_logo, Color.hex(0x8F8F8FFF))
			set_logo_color(portal, Color.hex(0x8F8F8F7F))
	elif player == PlayerManager.player2:
		if player.visible:
			visible_players += 1
			show_player2_logo()
			set_logo_color(login_logo2, Color.hex(0x006888FF))
			set_logo_color(portal2, Color.hex(0x0068883F))
			create_droplet_merge(login_logo2)
			create_ripple_effect(portal2)
		else:
			visible_players -= 1
			hide_player2_logo()

	if visible_players > 0:
		ready_to_start.emit(visible_players)
	else:
		wait_for_players.emit()

	position_logos(true)
	
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
