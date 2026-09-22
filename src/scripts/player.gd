extends CharacterBody2D

signal health_changed(current: int, maximum: int)

const MOVE_SPEED := 260.0
const BLOCK_SPEED_FACTOR := 0.45

enum CombatState {
	IDLE,
	MOVE,
	BLOCK,
	ATTACK
}

const ATTACKS := {
	"light": {
		"label": "Light Strike",
		"windup": 0.06,
		"active": 0.08,
		"recovery": 0.18,
		"damage": 12,
		"range": 26.0,
		"knockback": 280.0,
		"cooldown": 0.22
	},
	"elbow": {
		"label": "Explosive Elbow",
		"windup": 0.12,
		"active": 0.1,
		"recovery": 0.28,
		"damage": 20,
		"range": 34.0,
		"knockback": 380.0,
		"cooldown": 0.45
	},
	"grapple": {
		"label": "Grapple Throw",
		"windup": 0.16,
		"active": 0.12,
		"recovery": 0.36,
		"damage": 28,
		"range": 22.0,
		"knockback": 450.0,
		"cooldown": 0.7
	}
}

@export var max_health := 100

var health := max_health
var defeated := false
var state: CombatState = CombatState.IDLE
var facing := Vector2.RIGHT
var current_attack := ""
var attack_phase := ""
var attack_timer := 0.0
var cooldowns := {
	"light": 0.0,
	"elbow": 0.0,
	"grapple": 0.0
}
var hit_registry: Dictionary = {}

@onready var body: Polygon2D = $Body
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

func _ready() -> void:
	add_to_group("combat_target")
	$Hurtbox.add_to_group("hurtbox")
	health = max_health
	defeated = false
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if defeated:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visuals()
		return

	for move_name: String in cooldowns.keys():
		cooldowns[move_name] = max(0.0, float(cooldowns[move_name]) - delta)

	if state == CombatState.ATTACK:
		_process_attack(delta)
	else:
		_process_movement_and_inputs()

	velocity = velocity.limit_length(MOVE_SPEED)
	move_and_slide()
	_update_visuals()

func _process_movement_and_inputs() -> void:
	var attack_inputs := {
		"attack_light": "light",
		"attack_elbow": "elbow",
		"grapple_throw": "grapple"
	}
	for action_name: String in attack_inputs.keys():
		if Input.is_action_just_pressed(action_name):
			_try_start_attack(attack_inputs[action_name])
			return

	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length() > 0.1:
		facing = move_input.normalized()

	var speed := MOVE_SPEED
	if Input.is_action_pressed("block"):
		state = CombatState.BLOCK
		speed *= BLOCK_SPEED_FACTOR
	else:
		state = CombatState.MOVE if move_input.length() > 0.05 else CombatState.IDLE

	velocity = move_input * speed

func _try_start_attack(attack_name: String) -> void:
	if cooldowns.get(attack_name, 0.0) > 0.0:
		return

	_update_facing_from_target()
	state = CombatState.ATTACK
	current_attack = attack_name
	attack_phase = "windup"
	attack_timer = ATTACKS[attack_name]["windup"]
	hit_registry.clear()
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	_position_attack_hitbox()

func _process_attack(delta: float) -> void:
	attack_timer -= delta

	if attack_phase == "active":
		_check_attack_hits()

	if attack_timer > 0.0:
		return

	match attack_phase:
		"windup":
			attack_phase = "active"
			attack_timer = ATTACKS[current_attack]["active"]
			attack_hitbox.monitorable = true
			attack_hitbox.monitoring = true
			_position_attack_hitbox()
		"active":
			attack_phase = "recovery"
			attack_timer = ATTACKS[current_attack]["recovery"]
			attack_hitbox.monitoring = false
			attack_hitbox.monitorable = false
		"recovery":
			cooldowns[current_attack] = ATTACKS[current_attack]["cooldown"]
			current_attack = ""
			attack_phase = ""
			attack_hitbox.monitoring = false
			attack_hitbox.monitorable = false
			state = CombatState.IDLE

func _check_attack_hits() -> void:
	for area: Area2D in attack_hitbox.get_overlapping_areas():
		if area == null or not area.is_in_group("hurtbox"):
			continue
		var target := _resolve_damage_target(area)
		if target == null:
			continue
		var target_id := target.get_instance_id()
		if hit_registry.has(target_id):
			continue

		var profile: Dictionary = ATTACKS[current_attack]
		var hit_info := {
			"move": profile["label"],
			"damage": int(profile["damage"]),
			"knockback": facing.normalized() * float(profile["knockback"])
		}
		if target.take_hit(hit_info):
			hit_registry[target_id] = true

func _resolve_damage_target(from_node: Node) -> Node:
	var cursor: Node = from_node
	while cursor != null:
		if cursor != self and cursor.has_method("take_hit"):
			return cursor
		cursor = cursor.get_parent()
	return null

func _position_attack_hitbox() -> void:
	if current_attack == "":
		return
	var profile: Dictionary = ATTACKS[current_attack]
	var attack_offset := Vector2(_facing_sign() * float(profile["range"]), 0.0)
	attack_shape.position = attack_offset

func _update_facing_from_target() -> void:
	var closest_distance := INF
	var closest_direction := Vector2.ZERO
	for target: Node in get_tree().get_nodes_in_group("combat_target"):
		if target == self or not target is Node2D:
			continue
		var offset := (target as Node2D).global_position - global_position
		var distance := offset.length()
		if distance < closest_distance and distance > 0.0:
			closest_distance = distance
			closest_direction = offset / distance
	if closest_direction != Vector2.ZERO:
		facing = closest_direction

func _update_visuals() -> void:
	var facing_sign := _facing_sign()
	body.scale.x = facing_sign
	if defeated:
		body.color = Color(0.3, 0.3, 0.3, 1.0)
		return
	body.color = Color(0.2, 0.47, 0.74, 1.0) if state != CombatState.BLOCK else Color(0.4, 0.8, 1.0, 1.0)

func _facing_sign() -> float:
	return 1.0 if facing.x >= 0.0 else -1.0

func get_state_label() -> String:
	if state == CombatState.ATTACK and current_attack != "":
		return ATTACKS[current_attack]["label"] + " (" + attack_phase.capitalize() + ")"
	match state:
		CombatState.IDLE:
			return "Ready"
		CombatState.MOVE:
			return "Footwork"
		CombatState.BLOCK:
			return "Guarding"
		_:
			return "Ready"

func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	facing = Vector2.RIGHT
	_update_facing_from_target()
	defeated = false
	state = CombatState.IDLE
	current_attack = ""
	attack_phase = ""
	attack_timer = 0.0
	hit_registry.clear()
	for move_name: String in cooldowns.keys():
		cooldowns[move_name] = 0.0
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.position = Vector2(_facing_sign() * float(ATTACKS["light"]["range"]), 0.0)
	health = max_health
	health_changed.emit(health, max_health)

func take_hit(hit_data: Dictionary) -> bool:
	if defeated:
		return false
	var was_blocking := state == CombatState.BLOCK
	var damage := int(hit_data.get("damage", 0))
	var knockback := hit_data.get("knockback", Vector2.ZERO) as Vector2
	var is_guarding_front := false
	if knockback.length() > 0.0 and facing.length() > 0.0:
		var incoming_direction := -knockback.normalized()
		var approach_dot := facing.normalized().dot(incoming_direction)
		is_guarding_front = approach_dot > 0.1
	if was_blocking and is_guarding_front:
		damage = int(roundi(float(damage) * 0.4))
		velocity = knockback * 0.35
	else:
		velocity = knockback

	if state == CombatState.ATTACK:
		if current_attack != "":
			cooldowns[current_attack] = float(ATTACKS[current_attack]["cooldown"])
		current_attack = ""
		attack_phase = ""
		attack_timer = 0.0
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
		hit_registry.clear()
		state = CombatState.IDLE

	health = max(0, health - damage)
	health_changed.emit(health, max_health)
	if health == 0:
		defeated = true
		velocity = Vector2.ZERO
		state = CombatState.IDLE
	return true
