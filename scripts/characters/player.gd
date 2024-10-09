extends Node2D

var player_color: Color = Color.WHITE

@export var sprite_texture: Texture2D

func set_sprite(texture: Texture2D):
	sprite_texture = texture
	$Sprite2D.texture = sprite_texture

func _ready():
	if sprite_texture:
		$Sprite2D.texture = sprite_texture
