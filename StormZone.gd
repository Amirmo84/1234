# StormZone.gd
extends Area3D

@export var initial_radius: float = 18.0
@export var min_radius: float = 2.0
@export var shrink_duration: float = 60.0       # seconds to shrink from initial to min
@export var base_damage_per_second: float = 4.0
@export var damage_increase_rate: float = 0.05  # damage increases per second elapsed
@export var active: bool = true

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: MeshInstance3D = $MeshInstance3D

var elapsed_time: float = 0.0
var current_radius: float = 0.0

func _ready() -> void:
 current_radius = initial_radius
 _update_collision_radius()
 _update_visual_scale()

func _process(delta: float) -> void:
 if not active:
  return

 elapsed_time += delta

 # Shrink over time
 if shrink_duration > 0.0:
  var t = clamp(elapsed_time / shrink_duration, 0.0, 1.0)
  current_radius = lerp(initial_radius, min_radius, t)
 else:
  current_radius = max(min_radius, current_radius - (delta * 0.1))

 _update_collision_radius()
 _update_visual_scale()

 # Increase damage as time passes
 var damage_now = base_damage_per_second * (1.0 + elapsed_time * damage_increase_rate)

 # Center position of the storm
 var storm_center = global_position

 # Damage all players *outside* the storm radius
 for player in get_tree().get_nodes_in_group("Player"):
  if not player or not player.has_method("take_damage"):
   continue

  var distance = player.global_position.distance_to(storm_center)

  # Damage if outside current storm radius
  if distance > current_radius:
   player.take_damage(damage_now * delta)

func _update_collision_radius() -> void:
 if not (collision_shape and collision_shape.shape):
  return
 var s = collision_shape.shape
 if s is SphereShape3D:
  s.radius = current_radius
  collision_shape.shape = s
 elif s is CylinderShape3D:
  s.radius = current_radius
  collision_shape.shape = s

func _update_visual_scale() -> void:
 if not visual:
  return
 # assume visual mesh is 1x1 unit; scale it in X/Z to match radius
 visual.scale = Vector3(current_radius, 1.0, current_radius)
