# PlayerAI.gd
extends "res://Player.gd"

@export var chase_distance: float = 30.0    # تا چه فاصله‌ای دنبالش کند
@export var flee_distance: float = 12.0     # فاصله‌ی فرار
@export var ai_speed_multiplier: float = 0.5  # ضریب سختی بازی
@export var stop_threshold: float = 0.5       # فاصله‌ای که دیگه حرکت نمی‌کند

var target_player: Node = null

func _ready() -> void:
	is_computer = true
	current_hp = max_hp
	add_to_group("Player")
	if has_node("HitArea"):
		$HitArea.connect("body_entered", Callable(self, "_on_hit_area_body_entered"))
	
	# پیدا کردن پلیر انسانی
	if game_manager and game_manager.player1:
		target_player = game_manager.player1
	else:
		# در صورت نبود GameManager، از گروه "Player" کمک می‌گیریم
		var players = get_tree().get_nodes_in_group("Player")
		for p in players:
			if p != self:
				target_player = p
				break

func _physics_process(delta: float) -> void:
	if not target_player or not game_manager:
		return

	# به‌روزرسانی هدف در هر فریم
	var hunter = game_manager.get_hunter()
	var my_pos = global_transform.origin
	var target_pos = target_player.global_transform.origin

	var dir = Vector3.ZERO

	if hunter == self:
		# من شکارچی‌ام → حرکت به سمت هدف
		var distance = my_pos.distance_to(target_pos)
		if distance > stop_threshold:
			dir = (target_pos - my_pos).normalized()
	else:
		# من شکارم → فرار از هدف
		var distance = my_pos.distance_to(target_pos)
		if distance < chase_distance:
			dir = (my_pos - target_pos).normalized()  # فرار از هدف

	# حرکت
	velocity.x =  - dir.x * move_speed * ai_speed_multiplier
	velocity.z =  - dir.z * move_speed * ai_speed_multiplier
	move_and_slide()

	# محدود کردن به محدوده‌ی زمین (arena)
	_clamp_to_arena_bounds()

func _clamp_to_arena_bounds() -> void:
	if not game_manager:
		return
	var r = game_manager.arena_radius
	var pos = global_transform.origin
	pos.x = clamp(pos.x, -r, r)
	pos.z = clamp(pos.z, -r, r)
	global_transform.origin = pos
