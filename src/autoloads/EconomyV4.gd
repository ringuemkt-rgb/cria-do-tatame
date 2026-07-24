extends Node

## Economia dual canônica. CRIAcoin preserva compatibilidade com WorldState.money.
## Molho nunca pode comprar poder de combate.

const CRIACOIN := "CRIACOIN"
const MOLHO := "MOLHO"
const COMBAT_FORBIDDEN_MOLHO := ["card", "carta", "skill_tree", "atributo", "combat_power", "technique", "treino_tecnico"]

var balances := {CRIACOIN: 0, MOLHO: 0}
var transactions: Array = []
var ntm_marking := 0
var _counter := 0

func _ready() -> void:
	reset()

func reset() -> void:
	balances = {
		CRIACOIN: maxi(0, int(WorldState.money)),
		MOLHO: int(DataRegistry.economy.get("moedas", {}).get(MOLHO, {}).get("saldo_inicial", 0)),
	}
	transactions = []
	ntm_marking = 0
	_counter = 0
	_sync_legacy_money()

func reconcile_legacy_money() -> void:
	balances[CRIACOIN] = maxi(0, int(WorldState.money))

func get_balance(currency: String) -> int:
	if currency == CRIACOIN:
		reconcile_legacy_money()
	return int(balances.get(currency, 0))

func earn(currency: String, amount: int, source: String, metadata: Dictionary = {}) -> Dictionary:
	if not balances.has(currency) or amount <= 0:
		return {"ok": false, "error": "invalid_transaction"}
	if currency == CRIACOIN:
		reconcile_legacy_money()
	balances[currency] = int(balances[currency]) + amount
	_apply_moral_effect(currency, amount, true)
	var transaction := _record("earn", currency, amount, source, metadata)
	_sync_legacy_money()
	_emit_balance(currency, transaction)
	return {"ok": true, "balance": int(balances[currency]), "transaction": transaction}

func spend(currency: String, amount: int, category: String, metadata: Dictionary = {}) -> Dictionary:
	if not balances.has(currency) or amount < 0:
		return {"ok": false, "error": "invalid_transaction"}
	if currency == MOLHO and _is_combat_power_category(category):
		return {"ok": false, "error": "molho_cannot_buy_combat_power"}
	if currency == CRIACOIN:
		reconcile_legacy_money()
	if int(balances[currency]) < amount:
		return {"ok": false, "error": "insufficient_balance", "balance": int(balances[currency]), "required": amount}
	balances[currency] = int(balances[currency]) - amount
	_apply_moral_effect(currency, amount, false)
	var transaction := _record("spend", currency, -amount, category, metadata)
	_sync_legacy_money()
	_emit_balance(currency, transaction)
	return {"ok": true, "balance": int(balances[currency]), "transaction": transaction}

func transfer_to_criacoin_at_festival(molho_amount: int, informant_mission_active: bool = false) -> Dictionary:
	if molho_amount <= 0 or get_balance(MOLHO) < molho_amount:
		return {"ok": false, "error": "insufficient_molho"}
	var laundering: Dictionary = DataRegistry.economy.get("lavagem", {})
	var rate := clampf(float(laundering.get("taxa_base", 0.65)), 0.0, 1.0)
	var cria_amount := int(floor(float(molho_amount) * rate))
	balances[MOLHO] = int(balances[MOLHO]) - molho_amount
	balances[CRIACOIN] = get_balance(CRIACOIN) + cria_amount
	WorldState.modify_reputation("sombra", 6.0)
	FactionManager.apply_relation_delta("NTM", 4.0, "festival_laundering")
	FactionManager.apply_heat_delta("NTM", 3.0, "festival_laundering")
	ntm_marking = mini(3, ntm_marking + 1)
	var metadata := {
		"molho_input": molho_amount,
		"criacoin_output": cria_amount,
		"rate": rate,
		"informant_mission_active": informant_mission_active,
	}
	if informant_mission_active and has_node("/root/InformantSystem"):
		InformantSystem.add_evidence("registro_contador_festival", 1, {"source": "economy_laundering"})
	var transaction := _record("convert", MOLHO, -molho_amount, "paralelo_pratigi", metadata)
	_record("convert", CRIACOIN, cria_amount, "paralelo_pratigi", metadata)
	_sync_legacy_money()
	_emit_balance(MOLHO, transaction)
	_emit_balance(CRIACOIN, transaction)
	return {"ok": true, "spent_molho": molho_amount, "received_criacoin": cria_amount, "rate": rate, "ntm_marking": ntm_marking}

func quote_travel(node: Dictionary, mode: String) -> Dictionary:
	var costs: Dictionary = node.get("travel_cost", {}).get(mode, {})
	if costs.is_empty():
		return {"ok": false, "error": "travel_mode_unavailable"}
	var currency := str(costs.keys()[0])
	var amount := int(costs[currency])
	if mode == "fluvial" and currency == CRIACOIN:
		amount = int(ceil(float(amount) * 1.5))
	return {"ok": true, "currency": currency, "amount": amount, "mode": mode}

func to_dict() -> Dictionary:
	reconcile_legacy_money()
	return {
		"version": 4,
		"balances": balances.duplicate(true),
		"transactions": transactions.duplicate(true),
		"ntm_marking": ntm_marking,
		"counter": _counter,
	}

func load_from_dict(data: Dictionary) -> void:
	balances = {CRIACOIN: 0, MOLHO: 0}
	var saved: Dictionary = data.get("balances", {})
	balances[CRIACOIN] = maxi(0, int(saved.get(CRIACOIN, WorldState.money)))
	balances[MOLHO] = maxi(0, int(saved.get(MOLHO, 0)))
	transactions = data.get("transactions", []).duplicate(true)
	while transactions.size() > 128:
		transactions.pop_front()
	ntm_marking = clampi(int(data.get("ntm_marking", 0)), 0, 3)
	_counter = int(data.get("counter", transactions.size()))
	_sync_legacy_money()

func _is_combat_power_category(category: String) -> bool:
	var normalized := category.to_lower()
	for forbidden in COMBAT_FORBIDDEN_MOLHO:
		if normalized.contains(forbidden):
			return true
	return false

func _apply_moral_effect(currency: String, amount: int, earning: bool) -> void:
	if currency == MOLHO:
		var scale := clampf(float(amount) / 500.0, 1.0, 8.0)
		WorldState.modify_reputation("sombra", scale)
		if not earning:
			WorldState.modify_reputation("honra", -scale * 0.5)
		FactionManager.apply_relation_delta("NTM", scale * 0.5, "molho_transaction")
	elif currency == CRIACOIN and earning:
		WorldState.modify_reputation("honra", clampf(float(amount) / 1000.0, 0.0, 2.0))

func _record(kind: String, currency: String, delta: int, reason: String, metadata: Dictionary) -> Dictionary:
	_counter += 1
	var transaction := {
		"id": "tx_%06d" % _counter,
		"kind": kind,
		"currency": currency,
		"delta": delta,
		"reason": reason.left(64),
		"week": int(WorldState.week),
		"day": str(WorldState.current_day),
		"metadata": metadata.duplicate(true),
	}
	transactions.append(transaction)
	while transactions.size() > 128:
		transactions.pop_front()
	return transaction

func _sync_legacy_money() -> void:
	WorldState.money = maxi(0, int(balances.get(CRIACOIN, 0)))
	WorldState.dinheiro = WorldState.money

func _emit_balance(currency: String, transaction: Dictionary) -> void:
	if SignalBus.has_signal("economy_balance_changed"):
		SignalBus.economy_balance_changed.emit(currency, int(balances[currency]))
	if SignalBus.has_signal("economy_transaction_recorded"):
		SignalBus.economy_transaction_recorded.emit(transaction)
