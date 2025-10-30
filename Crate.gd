# Crate.gd
extends Area3D

# --- types ---
enum CrateType { DAMAGE, XP, SWAP }

# --- exported params ---
@export var crate_type: CrateType = CrateType.XP
@export var damage_amount: float = 15.0
@export var xp_amount: int = 10
@export var respawn_time: float = 12.0
@export var active_on_start: bool = true

# optional reference to game manager (set by GameManager or via editor)
var game_manager: Node = null
var rng := RandomNumberGenerator.new()

# internal
var _active: bool = true

func _ready():
  rng.randomize()
  _active = active_on_start
  if _active:
	set_process(false)
  # connect body entered
  connect("body_entered", Callable(self, "_on_body_entered"))

# mark active - make visible and enable monitoring
func activate_as_type() -> void:
  _active = true
  visible = true
  monitoring = true
  set_process(false)

func deactivate_temporarily(time_sec: float) -> void:
  _active = false
  visible = false
  monitoring = false
  # schedule respawn
  _defer_respawn(time_sec)

# helper coroutine to respawn after time 
#TODO: ehtemal kir shodan bala
func _defer_respawn(time_sec: float) -> void:
	await get_tree().create_timer(time_sec).timeout
	_respawn_after(time_sec)

func _respawn_after(time_sec: float) -> void:
  await get_tree().create_timer(time_sec).timeout
  _randomize_position()
  _active = true
  visible = true
  monitoring = true

# When a body enters crate area
func _on_body_entered(body: Node) -> void:
  if not _active:
	return
  if not body.is_in_group("Player"):
	return
  # apply effect based on type
  match crate_type:
	CrateType.DAMAGE:
	  if body.has_method("take_damage"):
		body.take_damage(damage_amount)
	CrateType.XP:
	  if body.has_method("gain_xp"):
		body.gain_xp(xp_amount)
	CrateType.SWAP:
	  # request swap from game manager
	  if game_manager and game_manager.has_method("_swap_hunter"):
		game_manager._swap_hunter()
  # deactivate self and schedule respawn
  _active = false
  visible = false
  monitoring = false
  # use respawn_time if provided, otherwise fall back to game_manager
  var t = respawn_time
  if game_manager and game_manager.has_variable("crate_respawn_time"):
	t = game_manager.crate_respawn_time
  _defer_respawn(t)

# place crate in random position within arena (uses GameManager if available)
func _randomize_position() -> void:
  if game_manager and game_manager.has_method("random_position_in_arena"):
	global_transform = Transform3D(global_transform.basis, game_manager.random_position_in_arena())
  else:
	# fallback: random within +-10
	var x = rng.randf_range(-10.0, 10.0)
	var z = rng.randf_range(-10.0, 10.0)
	global_transform = Transform3D(global_transform.basis, Vector3(x, 0.0, z))

# helper query
func is_swap() -> bool:
  return crate_type == CrateType.SWAP
