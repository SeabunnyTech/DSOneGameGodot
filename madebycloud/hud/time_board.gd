extends CenterContainer


signal timeout

@export var total_time = 30


var seconds_left:
	set(value):
		seconds_left = value
		%TimeDisplay.text = "%02d:%02d" % [int(seconds_left / 60), int(seconds_left) % 60]



func reset():
	seconds_left = total_time



func _ready() -> void:
	reset()
	$Timer.timeout.connect(_tick)



func _tick():
	seconds_left -= 1
	if seconds_left == 0:
		timeout.emit()
		$Timer.stop()


func start():
	$Timer.start()
