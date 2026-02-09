class_name Player extends CharacterBody3D;


# ############# #
# ## EXPORTS ## #
# ############# #

@export_group("-- Features --")
@export var enable_zoom: bool = true;
@export var enable_viewbob: bool = true;

@export_category("Basics")
@export_group("H Movement")
@export var move_speed: float = 7.0
## Multiplied by delta to get the weight for interoplating move_speed.
@export var move_accel: float = 20.0;
## Same as move_accel but used when the player stops moving.
@export var move_decel: float = 15.0;

@export_group("V Movement")
@export var max_fall_speed: float = 50.0;
@export var gravity_accel: float = 25.0;
@export var jump_force: float = 7.5;

@export_group("Camera")
## Multiplied by delta to get the weight for interoplating the camera's FOV.
@export var zoom_speed: float = 15.0;
@export var zoom_fov: float = 35.0;
@export var bob_freq: float = 2.0;
@export var bob_amp: float = 1.0;


# ############### #
# ## NODE REFS ## #
# ############### #

@onready var pivot := $Pivot as Node3D;
@onready var camera := $Pivot/Camera as Camera3D;


# ############# #
# ## ONREADY ## #
# ############# #
@onready var _init_cam_fov: float = camera.fov;


# ####################### #
# ## Private Variables ## #
# ####################### #
var _bob_time: float = 0.0;


# ######################## #
# ## Built-in Overrides ## #
# ######################## #

func _ready() -> void:
	pass;


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse();


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_view(event.relative, PlayerConf.VIEW_SENS_MOUSE);


func _process(delta: float) -> void:
	rotate_view(
		Input.get_vector("look_left", "look_right", "look_up", "look_down"),
		PlayerConf.VIEW_SENS_CONTROLLER
	);
	
	if enable_zoom:
		handlecamera_zoom(Input.is_action_pressed("action_zoom"), delta);
	
	if enable_viewbob && is_on_floor():
		handle_viewbob(delta);


func _physics_process(delta: float) -> void:
	var input_vec := get_input().rotated(Vector3.UP, rotation.y);
	var accel := get_accel(input_vec, delta);
	var v_move := get_vertical_movement(delta);
	
	velocity.x = lerpf(velocity.x, input_vec.x, accel);
	velocity.z = lerpf(velocity.z, input_vec.z, accel);
	
	velocity += v_move;
	velocity.y = clampf(velocity.y, -max_fall_speed, max_fall_speed);
	
	move_and_slide();




# ##################### #
# ## Camera Controls ## #
# ##################### #

func handlecamera_zoom(do: bool, delta: float) -> void:
	var target := zoom_fov if do else _init_cam_fov;
	camera.fov = lerpf(camera.fov, target, zoom_speed * delta);


func rotate_view(vec: Vector2, sens: float) -> void:
	# Lowers sensitivity when zooming in.
	var zoom_fix: float = inverse_lerp(0.0, _init_cam_fov, camera.fov);
	
	rotate_y(-vec.x * sens * zoom_fix);
	pivot.rotate_x(-vec.y * sens * zoom_fix);
	pivot.rotation.x = clampf(
		pivot.rotation.x,
		deg_to_rad(-90),
		deg_to_rad(90)
	);


func handle_viewbob(delta: float) -> void:
	var strength := smoothstep(
		0.0,
		move_speed,
		Vector2(velocity.x, velocity.z).length()
	);
	
	_bob_time += delta*strength;
	
	var bob := Vector2(
		sin(_bob_time * bob_freq) * bob_amp,
		sin(_bob_time * bob_freq * 2.0) * bob_amp * 0.5,
	);
	
	camera.h_offset = bob.x;
	camera.v_offset = bob.y;
	

func toggle_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);




# ############## #
# ## Movement ## #
# ############## #

func get_input() -> Vector3:
	var _in := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	);
	return Vector3(_in.x, 0.0, _in.y).normalized() * move_speed;


func get_accel(input_vec: Vector3, delta: float) -> float:
	var _weight := move_accel if input_vec.length_squared() > 0 else move_decel;
	return clampf(_weight * delta, 0.0, 1.0)


func get_vertical_movement(delta: float) -> Vector3:
	var v_move := Vector3.ZERO;
	
	if is_on_floor():
		if Input.is_action_just_pressed("move_jump"):
			v_move = Vector3.UP * jump_force;
		else:
			v_move = -get_floor_normal();
	else:
		v_move.y = -gravity_accel * delta;
	
	
	return v_move;
