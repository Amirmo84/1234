# Player.gd
extends CharacterBody3D

# --- exported gameplay ---
@export var max_hp: float = 100.0
@export var collision_attack_damage: float = 20.0
@export var xp: int = 0

# internal state
var current_hp: float
signal died

# reference to game manager
var game_manager: Node = null
var is_hunter: bool = false

func _ready():
  current_hp = max_hp
  add_to_group("Player")
  # Optionally connect collision detection (if using Area3D child for hit)
  if has_node("HitArea"):
	$HitArea.connect("body_entered", Callable(self, "_on_hit_area_body_entered"))

# Allow GameManager to set reference
func set_game_manager(gm: Node) -> void:
  game_manager = gm

# Called by GameManager to set hunter state
func set_hunter_state(hunter_state: bool) -> void:
  is_hunter = hunter_state
  # optionally change visuals (e.g., tint or icon). Not implemented here.

# Apply damage to player
func take_damage(amount: float) -> void:
  current_hp -= amount
  # clamp
  current_hp = clamp(current_hp, 0.0, max_hp)
  # optional: update HP UI here
  if current_hp <= 0.0:
	emit_signal("died")

# Gain XP
func gain_xp(amount: int) -> void:
  xp += amount
  # optional: level up logic

# Called when this player's hit-area collides with another player/body
func _on_hit_area_body_entered(body: Node) -> void:
  # if this player is hunter and hits other player, deal damage
  if not is_hunter:
	return
  if body.is_in_group("Player") and body != self:
	if body.has_method("take_damage"):
	  body.take_damage(collision_attack_damage)

# Optionally provide function for external 'melee' collision (e.g., direct physics body collision)
func on_direct_collision_with(other: Node) -> void:
  if is_hunter and other.is_in_group("Player") and other != self:
	if other.has_method("take_damage"):
	  other.take_damage(collision_attack_damage)
