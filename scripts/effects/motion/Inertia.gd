extends Node

# 這個節點的位置會受父節點的位置引導
# 但是有個延遲及慣性


@export var f = 5.0		# 目前的程式碼並不穩定，這數字只要設的稍高會爆開
@export var z = 0.2		# damping 項
@export var r = 0.0		# 還不太確定這一項的意義

#############

var leader: Node2D

var xp: Vector2		# prev input

var y: Vector2		# 會和 y 撞名所以改變數名稱
var yd: Vector2		# 

var k1: float
var k2: float
var k3: float


func init_second_order_dynamics(x0: Vector2):
	var two_pi_f = (2 * PI * f)
	k1 = 2 * z / two_pi_f
	k2 = two_pi_f ** -2
	k3 = r * z  / two_pi_f
	xp = x0
	y = x0
	yd = Vector2(0, 0)


func update(T: float, x: Vector2):
	var xd = (x - xp) / T
	xp = x
	
	y = y + T * yd
	yd = yd + T * (x + k3*xd - y - k1*yd) / k2
	return y


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	leader =  get_parent()
	init_second_order_dynamics(leader.global_position)


func _physics_process(delta: float):
	update(delta,leader.global_position)
	self.global_position = y
	#print(leader.position)
