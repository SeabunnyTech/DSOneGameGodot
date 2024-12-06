extends Node2D

@export var num_rivers_scenes = 3
@export var num_players = 2

@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo

func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	river_game_1.init(0, num_players, random_river_index)
	river_game_2.init(1, num_players, random_river_index)

func _process(_delta: float) -> void:
	pass
