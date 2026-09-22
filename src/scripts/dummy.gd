extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal defeated_changed(is_defeated: bool)

@export var max_health := 100

var health := max_health
var defeated := false
var flash_timer := 0.0

@onready var body: Polygon2D = $Body

func _ready() -> void:
	health = max_health
	defeated = false
	health_changed.emit(health, max_health)
	defeated_changed.emit(false)

func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
	_update_visuals()

	if not defeated:
		velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func take_hit(hit_data: Dictionary) -> bool:
	if defeated:
		return false

	var damage: int = int(hit_data.get("damage", 0))
	health = max(0, health - damage)
	flash_timer = 0.12
	velocity = hit_data.get("knockback", Vector2.ZERO) as Vector2
	health_changed.emit(health, max_health)

	if health == 0:
		defeated = true
		velocity = Vector2.ZERO
		defeated_changed.emit(true)

	return true

func _update_visuals() -> void:
	if defeated:
		body.color = Color(0.25, 0.25, 0.25, 1.0)
		return
	if flash_timer > 0.0:
		body.color = Color(1.0, 0.88, 0.35, 1.0)
	else:
		body.color = Color(0.9, 0.33, 0.31, 1.0)

func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	health = max_health
	defeated = false
	flash_timer = 0.0
	_update_visuals()
	health_changed.emit(health, max_health)
	defeated_changed.emit(false)
