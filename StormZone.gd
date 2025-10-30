# StormZone.gd
extends Area3D

# --- exported tuning ---
@export var initial_radius: float = 18.0
@export var min_radius: float = 2.0
@export var shrink_duration: float = 60.0       # time (sec) it takes to shrink from initial to min
@export var base_damage_per_second: float = 4.0
@export var damage_increase_rate: float = 0.05  # damage increases per second of game elapsed
@export var active: bool = true

# --- nodes ---
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: MeshInstance3D = $MeshInstance3D

# internal
var elapsed_time: float = 0.0
var current_radius: float

func _ready():
  current_radius = initial_radius
  _update_collision_radius()
  _update_visual_scale()

func _process(delta: float) -> void:
  if not active:
	return
  elapsed_time += delta
  # compute current radius based on linear shrink over shrink_duration
  if shrink_duration > 0:
	var t = clamp(elapsed_time / shrink_duration, 0.0, 1.0)
	current_radius = lerp(initial_radius, min_radius, t)
  else:
	current_radius = max(min_radius, current_radius - (delta * 0.1))
  _update_collision_radius()
  _update_visual_scale()
  # compute damage based on elapsed time
  var damage_now = base_damage_per_second * (1.0 + elapsed_time * damage_increase_rate)
  # apply damage to overlapping bodies
  for body in get_overlapping_bodies():
	if body.has_method("take_damage"):
	  body.take_damage(damage_now * delta)

# Adjust physics collision shape to match current_radius
func _update_collision_radius() -> void:
  if collision_shape and collision_shape.shape:
	var s = collision_shape.shape
	# Support SphereShape3D and CylinderShape3D
	if s is SphereShape3D:
	  s.radius = current_radius
	elif s is CylinderShape3D:
	  s.height = 1.0
	  s.radius = current_radius
	# if using other shapes, consider scaling the node instead

# Update mesh visual to represent the circle on XZ plane
func _update_visual_scale() -> void:
  if visual:
	# default mesh scale uses 1 unit -> scale by current_radius
	visual.scale = Vector3(current_radius, 1.0, current_radius)
