class_name LoginAnimations

### TODO: 降低耦合度，因為以下所有 nodes 都還需要參照 login.gd 中的 node Dictionary

const DURATIONS = {
	ELASTIC = 2.5,
	FADE = 1.0,
	RIPPLE = 2.0,
	MERGE = 0.4,
	POSITION = 1.0,
	SQUASH = 0.2,
	STRETCH = 0.15
}

const SCALES = {
	NORMAL = Vector2(1.0, 1.0),
	SMALL = Vector2(0.1, 0.1),
	RIPPLE = Vector2(1.2, 1.2),
	SQUASH = Vector2(1.1, 0.9),
	STRETCH = Vector2(0.9, 1.1),
	BOUNCE = Vector2(0.95, 1.05)
}

static func set_logo_color(node: Node2D, new_color: Color, duration: float = 0.5) -> Tween:
	var tween = node.create_tween()
	
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
	
	return tween

static func create_ripple_effect(node: Node2D) -> void:
	var tween = node.create_tween()
	
	tween.tween_property(node, "scale", SCALES.RIPPLE, DURATIONS.RIPPLE)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 0.8, DURATIONS.FADE)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node, "scale", SCALES.NORMAL, DURATIONS.SQUASH)
	tween.parallel().tween_property(node, "modulate:a", 1.0, 0.0)
	
	tween.finished.connect(func():
		if node.visible:
			create_ripple_effect(node)
	)

static func create_droplet_merge(node: Node2D) -> void:
	var tween = node.create_tween()
	
	tween.tween_property(node, "scale", SCALES.SQUASH, DURATIONS.MERGE)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", SCALES.STRETCH, DURATIONS.SQUASH)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "scale", SCALES.SQUASH, DURATIONS.SQUASH)\
		.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(node, "scale", SCALES.BOUNCE, DURATIONS.STRETCH)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", SCALES.NORMAL, 0.25)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.6)
	
	tween.finished.connect(func():
		if node.visible:
			create_droplet_merge(node)
	)

static func show_logo(logo_node: Node2D, portal_node: Node2D) -> void:
	var tween = logo_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(logo_node, "scale", SCALES.NORMAL, DURATIONS.FADE)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(portal_node, "scale", SCALES.NORMAL, DURATIONS.FADE)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)

static func hide_logo(nodes: Dictionary) -> Tween:
	if not nodes.player2.logo.visible:
		return
		
	var kill_tween = nodes.player2.logo.create_tween()
	kill_tween.tween_callback(func():
		nodes.player2.logo.scale = SCALES.SMALL
		nodes.player2.portal.scale = SCALES.SMALL
	)
	await kill_tween.finished
	
	var pos_tween = nodes.player2.logo.create_tween()
	pos_tween.set_parallel(true)
	pos_tween.tween_property(nodes.player1.logo, "position", nodes.player1.logo.position, DURATIONS.FADE)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	pos_tween.tween_property(nodes.player1.portal, "position", nodes.player1.portal.position, DURATIONS.FADE)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	
	await pos_tween.finished
	
	var scale_tween = nodes.player2.logo.create_tween()
	scale_tween.set_parallel(true)
	scale_tween.tween_property(nodes.player2.logo, "scale", SCALES.SMALL, DURATIONS.FADE)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_property(nodes.player2.portal, "scale", SCALES.SMALL, DURATIONS.FADE)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	
	return scale_tween

static func tween_signup_positions(root: Node, nodes: Dictionary, pos1: float, pos2: float) -> void:
	var tween = root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(nodes.player1.logo, "position:x", pos1, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player1.portal, "position:x", pos1, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player2.logo, "position:x", pos2, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player2.portal, "position:x", pos2, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)

static func tween_tutorial_positions(root: Node, nodes: Dictionary, pos1: float, pos2: float) -> void:
	var tween = root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(nodes.player1.mimic_player, "position:x", pos1, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player1.portal, "position:x", pos1, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player2.mimic_player, "position:x", pos2, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(nodes.player2.portal, "position:x", pos2, DURATIONS.POSITION)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
