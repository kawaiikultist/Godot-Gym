extends CanvasLayer

#
#  Exports
#
@export var fade_duration: float = 0.25;


#
#  Onready
#
@onready var progress_bar := $VBox/progLoading;
@onready var canvas_modulate := $CanvasModulate;


#
# Private
#
var _loading: bool = false;
## TODO: Current scenes may be to simple to test this. Check back later.
var _progress: Array[float] = [0] : 
	set(value):
		_progress = value;
		print_debug(value);
var _path: String = "";


func _ready() -> void:
	visible = false;
	canvas_modulate.color = Color.TRANSPARENT;



func load_scene_path(path: String) -> void:
	_path = path;
	
	var err := ResourceLoader.load_threaded_request(_path);
	if err:  push_error(error_string(err)); _stop_loading();
	else:    _start_loading();
	


func _process(_delta: float) -> void:
	if _loading:
		var status := ResourceLoader.load_threaded_get_status(_path, _progress);
		
		match status:
			# Push error (and return to previous scene?)
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Invalid Resource at '%s'" % _path);
				_stop_loading();
			
			# Update Progress
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				progress_bar.value = _progress[0];
			
			# Push error (and return to previous scene?)
			ResourceLoader.THREAD_LOAD_FAILED:
				## TODO: Maybe pause the current scene until loading done
				##       So it's easy to return to if loading fails?
				push_error("Failed to load resource at '%s'" % _path);
				_stop_loading();
			
			# Switch to new scene when finished loading
			ResourceLoader.THREAD_LOAD_LOADED:
				var new_scene := ResourceLoader.load_threaded_get(_path);
				
				if new_scene is PackedScene:
					var err := get_tree().change_scene_to_packed(new_scene);
					if err:  push_error(error_string(err));
					await get_tree().scene_changed;
					_stop_loading();


func _start_loading() -> void:
	visible = true;
	
	# Pause current scene
	get_tree().current_scene.set_process_mode(Node.PROCESS_MODE_DISABLED);
	
	# Fade loading screen in
	await create_tween().tween_property(
		canvas_modulate,
		^"color",
		Color.WHITE,
		fade_duration
	).finished;
	
	# Start loading
	_loading = true;


func _stop_loading() -> void:
	# Stop loading
	_loading = false;
	_path = "";
	
	# Fade loading screen out
	await create_tween().tween_property(
		canvas_modulate,
		^"color",
		Color.TRANSPARENT,
		fade_duration
	).finished;
	
	visible = false;
	
	# Unpause current scene if applicable.
	if get_tree().current_scene.process_mode == PROCESS_MODE_DISABLED:
		get_tree().current_scene.set_process_mode(PROCESS_MODE_INHERIT);
