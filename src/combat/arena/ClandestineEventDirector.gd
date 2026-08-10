class_name ClandestineEventDirector
extends Node

signal state_changed(state: String)
signal bet_changed(snapshot: Dictionary)
signal heat_changed(value: float, state: String)
signal warning_issued(snapshot: Dictionary)
signal interdiction_triggered(snapshot: Dictionary)
signal event_settled(settlement: Dictionary)

enum EventState { SETUP, READY, LIVE, WARNING, INTERDICTED, RESOLVED }

var arena_id: String = ""
var config: Dictionary = {}
var state: EventState = EventState.SETUP
var heat: float = 0.0
var elapsed_seconds: float = 0.0
var bet_stake: int = 0
var potential_payout: int = 0
var bet_placed: bool = false
var bet_locked: bool = false


func _ready() -> void:
	set_process(false)


func configure(event_config: Dictionary) -> void:
	config = event_config.duplicate(true)
	arena_id = str(config.get("arena_id", "praia_de_pratigi_festival"))
	var heat_config: Dictionary = config.get("heat", {})
	heat = clampf(float(heat_config.get("starting_value", 0.0)), 0.0, 100.0)
	elapsed_seconds = 0.0
	bet_stake = 0
	potential_payout = 0
	bet_placed = false
	bet_locked = false
	_set_state(EventState.SETUP)
	heat_changed.emit(heat, get_state_name())
	bet_changed.emit(get_bet_snapshot())


func place_bet(stake: int, wallet_balance: int) -> Dictionary:
	if state not in [EventState.SETUP, EventState.READY] or bet_locked:
		return {"ok": false, "reason": "betting_closed", "wallet_delta": 0}
	var betting: Dictionary = config.get("betting", {})
	if bool(betting.get("real_money_allowed", false)):
		return {"ok": false, "reason": "unsafe_betting_config", "wallet_delta": 0}
	var minimum: int = int(betting.get("minimum_stake", 0))
	var maximum: int = int(betting.get("maximum_stake", 0))
	var step: int = maxi(1, int(betting.get("stake_step", 1)))
	if stake < minimum or stake > maximum or stake % step != 0:
		return {"ok": false, "reason": "invalid_stake", "wallet_delta": 0}
	if stake > wallet_balance:
		return {"ok": false, "reason": "insufficient_funds", "wallet_delta": 0}
	var refund: int = bet_stake if bet_placed else 0
	bet_stake = stake
	bet_placed = stake > 0
	potential_payout = int(round(float(stake) * float(betting.get("payout_multiplier", 1.0))))
	_set_state(EventState.READY)
	var snapshot := get_bet_snapshot()
	bet_changed.emit(snapshot)
	return {
		"ok": true,
		"reason": "bet_registered" if bet_placed else "no_bet_selected",
		"wallet_delta": refund - stake,
		"bet": snapshot
	}


func cancel_bet() -> Dictionary:
	if bet_locked or state not in [EventState.SETUP, EventState.READY]:
		return {"ok": false, "wallet_delta": 0, "reason": "bet_locked"}
	var refund := bet_stake
	bet_stake = 0
	potential_payout = 0
	bet_placed = false
	_set_state(EventState.SETUP)
	var snapshot := get_bet_snapshot()
	bet_changed.emit(snapshot)
	return {"ok": true, "wallet_delta": refund, "reason": "bet_cancelled", "bet": snapshot}


func start_event() -> Dictionary:
	if state not in [EventState.SETUP, EventState.READY]:
		return {"ok": false, "reason": "event_not_ready"}
	bet_locked = true
	elapsed_seconds = 0.0
	_set_state(EventState.LIVE)
	set_process(true)
	if bet_placed:
		register_public_exposure(float(config.get("heat", {}).get("bet_exposure", 0.0)), "bet_registered")
	return {"ok": true, "state": get_state_name(), "bet": get_bet_snapshot()}


func _process(delta: float) -> void:
	if state not in [EventState.LIVE, EventState.WARNING]:
		return
	elapsed_seconds += delta
	var heat_config: Dictionary = config.get("heat", {})
	var passive_rate: float = maxf(0.0, float(heat_config.get("passive_per_second", 0.0)))
	_add_heat(passive_rate * delta, "passive_exposure")


func register_technique(result: Dictionary) -> void:
	if state not in [EventState.LIVE, EventState.WARNING]:
		return
	var heat_config: Dictionary = config.get("heat", {})
	var amount: float = float(heat_config.get("technique_exposure", 0.0))
	if bool(result.get("success", false)):
		amount += float(heat_config.get("successful_technique_bonus", 0.0))
	if str(result.get("phase", "")) == "TECHNICAL":
		amount += float(heat_config.get("technical_phase_bonus", 0.0))
	register_public_exposure(amount, "combat_technique")


func register_public_exposure(amount: float, source: String = "public_exposure") -> void:
	if state not in [EventState.LIVE, EventState.WARNING]:
		return
	_add_heat(maxf(0.0, amount), source)


func force_interdiction(reason: String = "authority_arrival") -> void:
	if state in [EventState.INTERDICTED, EventState.RESOLVED]:
		return
	heat = 100.0
	_set_state(EventState.INTERDICTED)
	set_process(false)
	heat_changed.emit(heat, get_state_name())
	var snapshot := get_snapshot()
	snapshot["reason"] = reason
	interdiction_triggered.emit(snapshot)


func settle(combat_result: Dictionary, player_id: String) -> Dictionary:
	if state == EventState.RESOLVED:
		return {"ok": false, "reason": "already_settled", "wallet_delta": 0}
	set_process(false)
	var interrupted: bool = state == EventState.INTERDICTED or bool(combat_result.get("interrupted", false))
	var player_won: bool = str(combat_result.get("winner", "")) == player_id
	var payout: int = 0
	var status := "no_bet"
	if interrupted:
		status = "interdicted"
	elif bet_placed and player_won:
		payout = potential_payout
		status = "won"
	elif bet_placed:
		status = "lost"
	_set_state(EventState.RESOLVED)
	var settlement := {
		"ok": true,
		"arena_id": arena_id,
		"status": status,
		"stake": bet_stake,
		"payout": payout,
		"wallet_delta": payout,
		"heat": heat,
		"interrupted": interrupted,
		"player_won": player_won
	}
	event_settled.emit(settlement)
	return settlement


func get_bet_snapshot() -> Dictionary:
	return {
		"stake": bet_stake,
		"potential_payout": potential_payout,
		"placed": bet_placed,
		"locked": bet_locked,
		"currency": str(config.get("betting", {}).get("currency", "moeda_interna"))
	}


func get_snapshot() -> Dictionary:
	return {
		"arena_id": arena_id,
		"state": get_state_name(),
		"heat": heat,
		"elapsed_seconds": elapsed_seconds,
		"bet": get_bet_snapshot()
	}


func get_state_name() -> String:
	return str(EventState.keys()[state]).to_lower()


func _add_heat(amount: float, source: String) -> void:
	if amount <= 0.0:
		return
	heat = clampf(heat + amount, 0.0, 100.0)
	var heat_config: Dictionary = config.get("heat", {})
	var warning_threshold: float = float(heat_config.get("warning_threshold", 70.0))
	var interdiction_threshold: float = float(heat_config.get("interdiction_threshold", 100.0))
	if heat >= interdiction_threshold:
		force_interdiction(source)
		return
	if heat >= warning_threshold and state == EventState.LIVE:
		_set_state(EventState.WARNING)
		var warning_snapshot := get_snapshot()
		warning_snapshot["reason"] = source
		warning_issued.emit(warning_snapshot)
	heat_changed.emit(heat, get_state_name())


func _set_state(new_state: EventState) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(get_state_name())
