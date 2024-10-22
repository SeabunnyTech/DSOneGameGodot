extends Node2D

signal portal_signup(player: Node2D)
signal portal_signup_exited(player: Node2D)

var players_in_portal: Array[Node2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	constrain_players()

# TODO: Constrain to player1->portal1 and player2->portal2
func _on_portal_area_body_entered(player: Node2D) -> void:
	if player == PlayerManager.player1:
		players_in_portal.append(player)
		portal_signup.emit(player)

func _on_portal_area_body_exited(player: Node2D) -> void:
	if player == PlayerManager.player1:
		players_in_portal.erase(player)
		portal_signup_exited.emit(player)

func _on_portal_area_2_body_entered(player: Node2D) -> void:
	if player == PlayerManager.player2:
		players_in_portal.append(player)
		portal_signup.emit(player)

func _on_portal_area_2_body_exited(player: Node2D) -> void:
	if player == PlayerManager.player2:
		players_in_portal.erase(player)
		portal_signup_exited.emit(player)


func constrain_players() -> void:
	var portal1_center = $Portal/PortalArea/CollisionShape2D.global_position
	var portal2_center = $Portal2/PortalArea2/CollisionShape2D.global_position
	var portal_radius = $Portal/PortalArea/CollisionShape2D.shape.radius  # Assuming both portals have the same radius

	for i in range(players_in_portal.size()):
		var player = players_in_portal[i]
		var portal_center = portal1_center if player == PlayerManager.player1 else portal2_center
		var direction = player.global_position - portal_center
		if direction.length() > portal_radius:
			player.global_position = portal_center + direction.normalized() * portal_radius
