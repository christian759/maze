extends ColorRect

# Example color sets
var gradients = [
	[Color("#8B0000"), Color("#FF6B6B")], # Dark Red → Light Red
	[Color("#00008B"), Color("#4D4DFF")], # Dark Blue → Light Blue
	[Color("#4B0082"), Color("#D580FF")]  # Dark Purple → Light Purple
]

func set_gradient(index: int):
	# Create Gradient
	var grad := Gradient.new()
	grad.add_point(0.0, gradients[index][0])
	grad.add_point(1.0, gradients[index][1])

	# Create GradientTexture2D
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad

	# Assign as texture (works in Godot 4)
	self.texture = grad_tex
