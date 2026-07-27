extends CharacterBody3D

@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@export_group("Movement Tuning")
@export var walk_speed: float = 7.0
@export var ground_accel: float = 12.0
@export var air_accel: float = 15.0
@export var friction: float = 5.0
@export var stop_speed: float = 2.0
@export var air_speed_cap: float = 1.5 # multiplier on wish_speed, caps strafe-jump gain per tick

@onready var head: Node3D = $Head

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()

	if not was_on_floor:
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and was_on_floor:
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wish_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if was_on_floor:
		apply_friction(delta)
		accelerate(wish_dir, walk_speed, ground_accel, delta)
	else:
		air_accelerate(wish_dir, walk_speed, air_accel, delta)

	move_and_slide()

func apply_friction(delta: float) -> void:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var speed := horizontal_velocity.length()
	if speed < 0.1:
		return
	var control: float = max(speed, stop_speed)
	var drop: float = control * friction * delta
	var new_speed: float = max(speed - drop, 0.0) / speed
	velocity.x *= new_speed
	velocity.z *= new_speed

func accelerate(wish_dir: Vector3, wish_speed: float, accel: float, delta: float) -> void:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var current_speed := horizontal_velocity.dot(wish_dir)
	var add_speed := wish_speed - current_speed
	if add_speed <= 0.0:
		return
	var accel_speed: float = min(accel * delta * wish_speed, add_speed)
	velocity.x += accel_speed * wish_dir.x
	velocity.z += accel_speed * wish_dir.z

func air_accelerate(wish_dir: Vector3, wish_speed: float, accel: float, delta: float) -> void:
	var capped_speed := wish_speed * air_speed_cap
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var current_speed := horizontal_velocity.dot(wish_dir)
	var add_speed := capped_speed - current_speed
	if add_speed <= 0.0:
		return
	var accel_speed: float = min(accel * capped_speed * delta, add_speed)
	velocity.x += accel_speed * wish_dir.x
	velocity.z += accel_speed * wish_dir.z
