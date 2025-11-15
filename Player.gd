extends CharacterBody2D


@export var speed: float = 220.0
@export var friction: float = 8.0


func _physics_process(delta: float) -> void:
	var input_vec = Vector2.ZERO
	input_vec.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vec.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vec = input_vec.normalized()


	if input_vec.length() > 0.0:
		velocity = velocity.move_toward(input_vec * speed, friction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
		

	# If the maze root exists, ask it whether player reached the entrance cell
	var maze = get_tree().get_root().get_current_scene().get_node_or_null("Maze")
	if maze:
		maze.check_player_reached_entrance(global_position)
