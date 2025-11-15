extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Example color sets
var gradients = [
	[Color("#8B0000"), Color("#FF6B6B")], # Dark Red → Light Red
	[Color("#00008B"), Color("#4D4DFF")], # Dark Blue → Light Blue
	[Color("#4B0082"), Color("#D580FF")]  # Dark Purple → Light Purple
]

func set_gradient(index: int):
	var grad_texture = GradientTexture2D.new()
	var grad = Gradient.new()
	grad.add_point(0.0, gradients[index][0])  # start color
	grad.add_point(1.0, gradients[index][1])  # end color
	grad_texture.gradient = grad
	self.texture = grad_texture
