# Player.gd
extends CharacterBody3D

@export var max_hp: float = 100.0
@export var collision_attack_damage: float = 20.0
@export var xp: int = 0
@export var is_computer: bool = false   # if true, drive by AI (we'll implement simple AI later)
@export var move_speed: float = 10.0


var current_hp: float
signal died(player_name)

# optional GameManager reference
var game_manager: Node = null
var is_hunter: bool = false

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Player")
	if has_node("HitArea"):
		$HitArea.connect("body_entered", Callable(self, "_on_hit_area_body_entered"))

func set_game_manager(gm: Node) -> void:
	game_manager = gm

func set_hunter_state(hunter_state: bool) -> void:
	is_hunter = hunter_state
	# optionally change visuals or flags

func take_damage(amount: float) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0.0, max_hp)
	# TODO: update HP UI
	if int(current_hp) % 10 == 0:
		print("PLayer current HP : " ,int (current_hp))
	
	if current_hp <= 0.0:
		emit_signal("died", name)

func gain_xp(amount: int) -> void:
	xp += amount
	# optional level-up logic

func _on_hit_area_body_entered(body: Node) -> void:
	# if this player is hunter and hits other player, deal damage
	if not is_hunter:
		return
	if body and body.is_in_group("Player") and body != self:
		if body.has_method("take_damage"):
			body.take_damage(collision_attack_damage)

# optional: helper for direct collisions
func on_direct_collision_with(other: Node) -> void:
	if is_hunter and other and other.is_in_group("Player") and other != self:
		if other.has_method("take_damage"):
			other.take_damage(collision_attack_damage)

func _physics_process(delta: float) -> void:
	if not is_computer:
		var input_dir = Vector3.ZERO
	
	# WASD movement
		if Input.is_action_pressed("move_forward"):
			input_dir.z -= move_speed
		if Input.is_action_pressed("move_backward"):
			input_dir.z += move_speed
		if Input.is_action_pressed("move_left"):
			input_dir.x -= move_speed
		if Input.is_action_pressed("move_right"):
			input_dir.x += move_speed

		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * move_speed
		velocity.z = input_dir.z * move_speed

		move_and_slide()
