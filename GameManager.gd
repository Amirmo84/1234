# GameManager.gd
extends Node

@export var hunter_swap_time: float = 20.0        # seconds between hunter swaps
@export var difficulty: float = 1.0               # 1.0 = normal, >1 harder (favors AI)
@export var crate_respawn_time: float = 15.0      # default respawn for crates
@export var arena_radius: float = 25.0            # radius of playable arena (XZ)
@export var crate_spawn_chance: float = 0.8       # base chance to enable crate on spawn pass

@onready var player1: CharacterBody3D = $"../Player1"        # adjust paths if necessary
@onready var player2: CharacterBody3D = $"../Player2"
@onready var crates_parent: Node = $"../Crates"
@onready var storm_zone: Node = $"../StormZone"

var hunter: Node = null
var _swap_timer: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
  rng.randomize()
  # default hunter is player1
  if player1:
	hunter = player1
  # ensure players are in group "Player"
  if player1 and not player1.is_in_group("Player"):
	player1.add_to_group("Player")
  if player2 and not player2.is_in_group("Player"):
	player2.add_to_group("Player")
  # connect player died signals (players should emit "died")
  if player1 and player1.has_signal("died"):
	player1.connect("died", Callable(self, "_on_player_died"))
  if player2 and player2.has_signal("died"):
	player2.connect("died", Callable(self, "_on_player_died"))
  # give players reference to game manager if they support it
  if player1 and player1.has_method("set_game_manager"):
	player1.set_game_manager(self)
  if player2 and player2.has_method("set_game_manager"):
	player2.set_game_manager(self)

func _process(delta: float) -> void:
  _swap_timer += delta
  if _swap_timer >= hunter_swap_time:
	_swap_timer = 0.0
	_swap_hunter()

func _swap_hunter() -> void:
  if not player1 or not player2:
	return
  hunter = player2 if hunter == player1 else player1
  # notify players if they implement set_hunter_state
  if player1 and player1.has_method("set_hunter_state"):
	player1.set_hunter_state(hunter == player1)
  if player2 and player2.has_method("set_hunter_state"):
	player2.set_hunter_state(hunter == player2)

func _on_player_died() -> void:
  print("GameManager: A player died. Pausing.")
  get_tree().paused = true
  # TODO: show end screen or emit signal

# Return current hunter node
func get_hunter() -> Node:
  return hunter

# Utility: random position inside arena (XZ plane)
# prefer_near: if provided, bias position toward that node by 'bias' in [0..1]
func random_position_in_arena(prefer_near: Node = null, bias: float = 0.0) -> Vector3:
  var angle = rng.randf_range(0.0, TAU)
  var r = rng.randf() * arena_radius
  var pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
  if prefer_near != null and bias > 0.0:
	var near_pos = prefer_near.global_transform.origin
	pos = pos.linear_interpolate(Vector3(near_pos.x, 0.0, near_pos.z), clamp(bias, 0.0, 1.0))
  return pos

# Distribute crates across arena, biasing by difficulty
func distribute_crates() -> void:
  if not crates_parent:
	return
  for crate in crates_parent.get_children():
	# skip nodes that aren't crates
	if not crate.has_method("activate_as_type") or not crate.has_method("deactivate_temporarily"):
	  continue
	if rng.randf() <= crate_spawn_chance:
	  # bias towards player2 (AI) when difficulty > 1
	  var bias = clamp((difficulty - 1.0) * 0.5, 0.0, 0.9)
	  # stronger bias for swap crate
	  if crate.has_method("is_swap") and crate.is_swap():
		bias = clamp(bias + 0.3, 0.0, 1.0)
	  var prefer_node: Node = null
	  # random chance to prefer player2 based on bias
	  if rng.randf() < bias and player2:
		prefer_node = player2
	  var pos = random_position_in_arena(prefer_node, bias)
	  crate.global_transform = Transform(crate.global_transform.basis, pos)
	  crate.activate_as_type()
	else:
	  crate.deactivate_temporarily(crate_respawn_time)
	
# Return the special swap crate (first found)
func get_swap_crate() -> Node:
  if not crates_parent:
	return null
  for crate in crates_parent.get_children():
	if crate.has_method("is_swap") and crate.is_swap():
	  return crate
  return null
