extends Node2D

signal portal_ready(player: Node2D)
signal portal_ready_exited(player: Node2D)

var players_in_portal: Array[Node2D] = []

func _ready() -> void:
	$Portal/PortalArea.connect("body_entered", _on_portal_area_body_entered.bind(PlayerManager.player1))
	$Portal/PortalArea.connect("body_exited", _on_portal_area_body_exited.bind(PlayerManager.player1))
	$Portal2/PortalArea.connect("body_entered", _on_portal_area_body_entered.bind(PlayerManager.player2))
	$Portal2/PortalArea.connect("body_exited", _on_portal_area_body_exited.bind(PlayerManager.player2))

	# Connect visibility changed signals
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("visibility_changed",
							_on_player_visibility_changed.bind(player),
							CONNECT_DEFERRED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	constrain_players()

func _on_player_visibility_changed(player: Node2D) -> void:
	if player.visible and player in players_in_portal:
		portal_ready.emit(player)
		
func _on_portal_area_body_entered(player: Node2D, expected_player: Node2D) -> void:
	if player == expected_player:
		players_in_portal.append(player)
		SignalBus.player_ready_portal_changed.emit(player, true)

func _on_portal_area_body_exited(player: Node2D, expected_player: Node2D) -> void:
	if player == expected_player:
		players_in_portal.erase(player)
		SignalBus.player_ready_portal_changed.emit(player, false)

func constrain_players() -> void:
	var portal1_center = $Portal/PortalArea/CollisionShape2D.global_position
	var portal2_center = $Portal2/PortalArea/CollisionShape2D.global_position
	var portal_radius = $Portal/PortalArea/CollisionShape2D.shape.radius  # Assuming both portals have the same radius

	for i in range(players_in_portal.size()):
		var player = players_in_portal[i]
		if player.visible:
			var portal_center = portal1_center if player == PlayerManager.player1 else portal2_center
			var direction = player.global_position - portal_center
			if direction.length() > portal_radius:
				player.global_position = portal_center + direction.normalized() * portal_radius
