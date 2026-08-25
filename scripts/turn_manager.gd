class_name TurnManager
extends Node
## Drives the turn loop: player phase -> coworker phase -> resolution.
## Player actions spend action points; when the turn ends, coworkers act,
## pending cough chains resolve, alerts settle, and room rules refresh.

signal turn_started(turn_number: int)
signal phase_changed(phase: String)
signal action_points_changed(remaining: int)
signal turn_completed(result: TurnResult)

const PLAYER_PHASE := "player"
const COWORKER_PHASE := "coworkers"
const RESOLUTION_PHASE := "resolution"

var max_action_points: int = 3
var action_points: int = 0
var turn_number: int = 0
var phase: String = PLAYER_PHASE
var locked: bool = false

var player: Node
var sneeze_system: Node
var cough_chain: Node
var alert_system: Node
var room_etiquette: Node
var coworkers: Array = []

var _sneezes: int = 0
var _coughs: int = 0
var _alerts: int = 0
var _rule_changes: int = 0


func _ready() -> void:
	EventBus.sneeze_occurred.connect(_on_sneeze_occurred)
	EventBus.cough_chain_started.connect(_on_cough_chain_started)
	EventBus.coworker_alerted.connect(_on_coworker_alerted)
	EventBus.rule_changed.connect(_on_rule_changed)


func setup(p: Node, s: Node, c: Node, a: Node, r: Node, crew: Array) -> void:
	player = p
	sneeze_system = s
	cough_chain = c
	alert_system = a
	room_etiquette = r
	coworkers = crew
	max_action_points = int(GameState.settings.get("max_action_points", 3))
	begin_turn()


func begin_turn() -> void:
	turn_number += 1
	action_points = max_action_points
	_sneezes = 0
	_coughs = 0
	_alerts = 0
	_rule_changes = 0
	GameState.turn_number = turn_number
	phase = PLAYER_PHASE
	locked = false
	if sneeze_system and sneeze_system.has_method("tick_passive"):
		sneeze_system.tick_passive()
	for coworker in coworkers:
		if is_instance_valid(coworker) and coworker.has_method("tick_passive"):
			coworker.tick_passive()
	phase_changed.emit(PLAYER_PHASE)
	action_points_changed.emit(action_points)
	turn_started.emit(turn_number)


func is_player_phase() -> bool:
	return not locked and phase == PLAYER_PHASE


func can_act() -> bool:
	return is_player_phase