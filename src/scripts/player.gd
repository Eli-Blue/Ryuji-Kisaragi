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
	health = max_health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
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
	if Input.is_action_just_pressed("attack_light"):
		_try_start_attack("light")
		return
	if Input.is_action_just_pressed("attack_elbow"):
		_try_start_attack("elbow")
		return
	if Input.is_action_just_pressed("grapple_throw"):
		_try_start_attack("grapple")
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
		if area == null or area.name != "Hurtbox":
			continue
		var target := area.get_parent()
		if target == null or not target.has_method("take_hit"):
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

func _position_attack_hitbox() -> void:
	if current_attack == "":
		return
	var profile: Dictionary = ATTACKS[current_attack]
	var attack_offset: Vector2 = facing.normalized() * float(profile["range"])
	attack_shape.position = attack_offset

func _update_visuals() -> void:
	if absf(facing.x) > 0.1:
		body.scale.x = signf(facing.x)
	body.color = Color(0.2, 0.47, 0.74, 1.0) if state != CombatState.BLOCK else Color(0.4, 0.8, 1.0, 1.0)

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
	state = CombatState.IDLE
	current_attack = ""
	attack_phase = ""
	attack_timer = 0.0
	for move_name: String in cooldowns.keys():
		cooldowns[move_name] = 0.0
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	health = max_health
	health_changed.emit(health, max_health)
