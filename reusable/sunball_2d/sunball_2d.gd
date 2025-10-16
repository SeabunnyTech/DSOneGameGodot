@tool
extends Node2D

@export var tint_color: Color = Color(1, 1, 1) :
	set(new_color):
		tint_color = new_color
		$Sprite2D.color = new_color
