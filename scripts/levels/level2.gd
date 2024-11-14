extends Node2D

func _ready():
	pass
	## Hide all sprites initially
	#for sprite in get_children():
		#sprite.hide()

func toggle_sprite(index):
	if index < get_child_count():
		var sprite = get_child(index)
		sprite.visible = !sprite.visible
