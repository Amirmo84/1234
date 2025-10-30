# Crate.gd
extends Area3D

enum CrateType {
	DAMAGE,
	XP,
	SWAP
}

@export var crate_type: CrateType = CrateType.XP
@export var damage_amount: float = 15.0
@export var xp_amount: int = 10
@export var respawn_time: float = 5.0
@export var active_on_start: bool = true

# optional reference to GameManager (set in editor or at runtime)
@export var game_manager: Node

@onready var mesh: MeshInstance3D = $MeshInstance3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _active: bool = true

func _ready() -> void:
	rng.randomize()
	_active = active_on_start
	monitoring = _active
	visible = _active
	connect("body_entered", Callable(self, "_on_body_entered"))
	_set_crate_color()   # <-- Apply color when crate spawns

func _set_crate_color() -> void:
	var mat := StandardMaterial3D.new()

	match crate_type:
		CrateType.DAMAGE:
			mat.albedo_color = Color(1, 0.2, 0.2)  # red
		CrateType.XP:
			mat.albedo_color = Color(0.2, 1, 0.2)  # green
		CrateType.SWAP:
			mat.albedo_color = Color(0.2, 0.4, 1)  # blue

	# Optional: slight glow so crates look cooler
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.6

	mesh.set_surface_override_material(0, mat)
	
func activate_as_type() -> void:
	_active = true
	visible = true
	monitoring = true

func deactivate_temporarily(time_sec: float) -> void:
	_active = false
	visible = false
	monitoring = false
	_defer_respawn(time_sec)

func _defer_respawn(time_sec: float) -> void:
	# Wait asynchronously for time_sec seconds, then respawn
	await get_tree().create_timer(time_sec).timeout
	_respawn_after()


func _respawn_after() -> void:
	# Actually respawn the crate
	_randomize_position()
	_active = true
	visible = true
	monitoring = true

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if not body or not body.is_in_group("Player"):
		return
	match crate_type:
		CrateType.DAMAGE:
			if body.has_method("take_damage"):
				body.take_damage(damage_amount)
		CrateType.XP:
			if body.has_method("gain_xp"):
				body.gain_xp(xp_amount)
		CrateType.SWAP:
			if game_manager and game_manager.has_method("_swap_hunter"):
				game_manager._swap_hunter()
	# deactivate and schedule respawn
	_active = false
	visible = false
	monitoring = false
	var t = respawn_time
	if game_manager and game_manager.has_variable("crate_respawn_time"):
		t = game_manager.crate_respawn_time
	_defer_respawn(t)

func _randomize_position() -> void:
	if game_manager and game_manager.has_method("random_position_in_arena"):
		global_transform = Transform3D(global_transform.basis, game_manager.random_position_in_arena())
	else:
		var x = rng.randf_range(-5.0, 5.0)
		var z = rng.randf_range(-5.0, 5.0)
		global_transform = Transform3D(global_transform.basis, Vector3(x, 0.0, z))
		print("type: ", crate_type)

func is_swap() -> bool:
	return crate_type == CrateType.SWAP
