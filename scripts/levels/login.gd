extends Node2D

@onready var player_manager = $PlayerManagerNode

func _ready():
	# Level-specific initialization
	player_manager.spawn_players(2)

func _process(_delta):
	# Level-specific update logic
	pass

# Other level-specific methods
