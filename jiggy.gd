extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func fade_to_scene(path: String):
	#fade out
	modulate.a = 0.0
	while modulate.a < 1.0:
		modulate.a += 0.03
		await get_tree().process_frame
		
	#Change scene
	get_tree().change_scene_to_file(path)
	
	#Fade in
	modulate.a = 1.0
	while modulate.a > 0.0:
		modulate.a -= 0.3
		await get_tree().process_frame
