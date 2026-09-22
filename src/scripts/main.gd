extends Node2D

const PLAYER_SPAWN := Vector2(360, 360)
const DUMMY_SPAWN := Vector2(860, 360)

@onready var player = $Player
@onready var dummy = $Dummy
@onready var player_health_bar: ProgressBar = $HUD/Root/PlayerHealthBar
@onready var dummy_health_bar: ProgressBar = $HUD/Root/DummyHealthBar
@onready var status_label: Label = $HUD/Root/StatusLabel

var status_lock_timer := 0.0

func _ready() -> void:
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if dummy.has_signal("health_changed"):
		dummy.health_changed.connect(_on_dummy_health_changed)
	if dummy.has_signal("defeated_changed"):
		dummy.defeated_changed.connect(_on_dummy_defeated_changed)

	_on_player_health_changed(player.health, player.max_health)
	_on_dummy_health_changed(dummy.health, dummy.max_health)
	status_label.text = "Close in and chain short-range pressure."

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_round"):
		reset_round()

	status_lock_timer = max(0.0, status_lock_timer - delta)
	if status_lock_timer > 0.0:
		return

	if player.has_method("get_state_label"):
		var state_label: String = player.get_state_label()
		if not _dummy_is_defeated():
			status_label.text = "State: %s" % state_label

func _on_player_health_changed(current: int, maximum: int) -> void:
	player_health_bar.max_value = maximum
	player_health_bar.value = current

func _on_dummy_health_changed(current: int, maximum: int) -> void:
	dummy_health_bar.max_value = maximum
	dummy_health_bar.value = current

func _on_dummy_defeated_changed(is_defeated: bool) -> void:
	if is_defeated:
		status_lock_timer = 0.0
		status_label.text = "Dummy down. Press R to reset and drill again."

func reset_round() -> void:
	if player.has_method("reset_for_round"):
		player.reset_for_round(PLAYER_SPAWN)
	if dummy.has_method("reset_for_round"):
		dummy.reset_for_round(DUMMY_SPAWN)
	status_label.text = "Round reset. Re-engage with pressure and throws."
	status_lock_timer = 1.0

func _dummy_is_defeated() -> bool:
	return dummy.has_method("is_defeated") and dummy.is_defeated()
