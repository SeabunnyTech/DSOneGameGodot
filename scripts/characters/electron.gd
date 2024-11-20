extends Node2D

enum ElectronType {
	TYPE1,
	TYPE2,
	TYPE3
}

var speed = 100
var follow_distance = 50
var leading_electron: Node2D = null
var current_type: ElectronType

func _ready():
	modulate = Color(1, 1, 1, 0.8)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func set_type(type: ElectronType):
	current_type = type
	
	# Hide all electron types
	for electron in [$Electron1, $Electron2, $Electron3]:
		electron.hide()
	
	# Show the selected type
	match type:
		ElectronType.TYPE1:
			$Electron1.show()
		ElectronType.TYPE2:
			$Electron2.show()
		ElectronType.TYPE3:
			$Electron3.show()

	# Start halo animation after type is set
	animate_halos()

func animate_halos():
	# Get current electron node
	var current_electron = get_current_electron()
	if not current_electron:
		return
		
	# Animate halos
	var halo1 = current_electron.get_node("Halo1")
	var halo2 = current_electron.get_node("Halo2")

	var tween = create_tween()
	tween.set_loops()
	
	# Halo1 animation (inner halo)
	tween.tween_property(halo1, "modulate:a", 0.8, 0.5)
	tween.parallel().tween_property(halo1, "scale", Vector2(1.1, 1.1), 0.7).set_trans(Tween.TRANS_CIRC)
	
	# Halo2 animation (outer halo)
	tween.parallel().tween_property(halo2, "modulate:a", 0.8, 0.5)
	tween.parallel().tween_property(halo2, "scale", Vector2(1.25, 1.25), 0.7).set_trans(Tween.TRANS_CIRC)

	# Contract both halos
	tween.chain().tween_property(halo1, "modulate:a", 0.1, 0.7)
	tween.parallel().tween_property(halo1, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo2, "modulate:a", 0.1, 0.7)
	tween.parallel().tween_property(halo2, "scale", Vector2(1, 1), 0.).set_trans(Tween.TRANS_CIRC)
	

func get_current_electron() -> Node2D:
	match current_type:
		ElectronType.TYPE1:
			return $Electron1
		ElectronType.TYPE2:
			return $Electron2
		ElectronType.TYPE3:
			return $Electron3
	return null
