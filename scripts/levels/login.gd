extends Node2D

func _ready():
	pass
	# Level-specific initialization

func _process(_delta):
	# Level-specific update logic
	pass
	# Other level-specific methods

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
