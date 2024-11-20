extends CanvasLayer

var messages: Array = []
const max_messages = 10  # Maximum number of messages to show
const message_lifetime = 10.0  # Messages will be removed after this many seconds


var label: Label

func _ready():
	# Create CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	add_child(canvas_layer, true)
	
	# Create MarginContainer
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	canvas_layer.add_child(margin, true)
	
	# Create Label
	label = Label.new()
	label.add_theme_color_override("font_color", Color(1, 0, 0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 32)
	margin.add_child(label, true)
	
	# Only show in dev mode
	canvas_layer.visible = Globals.debug_message

func info(message: String):
	if not Globals.debug_message:
		return
		
	messages.push_front(str(message))
	if messages.size() > max_messages:
		messages.pop_back()
	
	# Update label text
	label.text = "\n".join(messages)

# Clear all messages
func clear_messages():
	messages.clear()
	label.text = "" 
