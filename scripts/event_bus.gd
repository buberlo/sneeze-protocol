extends Node
## Global signal bus for decoupled office stealth events.
##
## Systems emit here and UI/actors listen here. Payloads are intentionally
## untyped so this autoload can be loaded independently of data classes.

# Turn and action economy
signal turn_started(turn: int, action_points: int)
signal turn_ended(result: Variant)
signal action_points_changed(current: int, maximum: int)
signal action_consumed(action: String,