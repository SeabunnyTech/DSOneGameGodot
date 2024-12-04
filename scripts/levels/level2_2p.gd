extends Node2D

func _ready():
	var player1_viewport = $GameScene/Player1UI/SubViewport
	var player2_viewport = $GameScene/Player2UI/SubViewport
	
	PlayerManager.register_player_in_viewport(0, player1_viewport)
	PlayerManager.register_player_in_viewport(1, player2_viewport)

func _exit_tree():
	PlayerManager.clear_viewports()
