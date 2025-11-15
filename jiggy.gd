extends ColorRect

func _enter_tree() -> void:
	# Now the tree is guaranteed to exist
	await get_tree().process_frame
	fade_to_scene("res://home.tscn")


func fade_to_scene(path: String):
	# Fade in
	modulate.a = 0.0
	while modulate.a < 1.0:
		modulate.a += 0.01
		await get_tree().process_frame

	# Fade out
	modulate.a = 1.0
	while modulate.a > 0.0:
		modulate.a -= 0.01
		await get_tree().process_frame
		
	# Change scene
	get_tree().change_scene_to_file(path)

	
