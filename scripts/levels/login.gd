extends Node2D

@onready var login_logo = $LoginLogo/LoginLogo
@onready var portal = $LoginLogo/Portal
@onready var login_logo_container = $LoginLogo

var login_logo2: Sprite2D
var portal2: Sprite2D

func _ready():
	var tween = create_tween()

	# Create parallel tweens for login_logo and portal
	tween.set_parallel(true)

	tween.tween_property(login_logo, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(portal, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	set_logo_color(login_logo, Color.hex(0x8F8F8FFF))  # Color from player1.svg
	set_logo_color(portal, Color.hex(0x8F8F8F7F))

	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("visibility_changed", _on_player_visibility_changed.bind(player))

func _process(_delta):
	# Level-specific update logic
	pass
	# Other level-specific methods

func set_logo_color(node, new_color: Color):
	# Assuming the logo is using a ShaderMaterial
	if node.material is ShaderMaterial:
		node.material.set_shader_parameter("tint_color", new_color)
	else:
		# If not using a shader, we can modulate the sprite directly
		var original_alpha = node.modulate.a
		node.modulate = new_color
		node.modulate.a = original_alpha * new_color.a

func create_player2_logo():
	login_logo2 = login_logo.duplicate()
	portal2 = portal.duplicate()
	
	login_logo_container.add_child(login_logo2)
	login_logo_container.add_child(portal2)
	
	# Animate the new logo
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(login_logo2, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(portal2, "scale", Vector2(1, 1), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func remove_player2_logo():
	if login_logo2:
		login_logo2.queue_free()
		login_logo2 = null
	if portal2:
		portal2.queue_free()
		portal2 = null

func position_logos():
	var screen_width = get_viewport_rect().size.x
	var logo_width = login_logo.texture.get_width()
	
	if login_logo2:
		# Position both logos
		login_logo.position.x = screen_width / 3 - logo_width / 2
		login_logo2.position.x = 2 * screen_width / 3 - logo_width / 2
		portal2.position = login_logo2.position
	else:
		# Center the single logo
		login_logo.position.x = screen_width / 2 - logo_width / 2
	
	# Update portal position
	portal.position = login_logo.position

func _on_player_visibility_changed(player: Node):
	if player == PlayerManager.player1:
		if player.visible:
			set_logo_color(login_logo, Color.hex(0x00B6EEFF))
			set_logo_color(portal, Color.hex(0x00B6EE5F))
	elif player == PlayerManager.player2:
		if player.visible:
			if not login_logo2:
				create_player2_logo()
			set_logo_color(login_logo2, Color.hex(0x006888FF))
			set_logo_color(portal2, Color.hex(0x0068887F))
		else:
			remove_player2_logo()
	
	# position_logos()
	
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
