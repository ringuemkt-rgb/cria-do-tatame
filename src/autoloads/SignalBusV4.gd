extends "res://src/autoloads/SignalBus.gd"

signal economy_balance_changed(currency, balance)
signal economy_transaction_recorded(transaction)
signal informant_status_changed(status, state)
signal informant_evidence_added(record, total)
signal world_node_unlocked(node_id, reason)
signal world_travel_completed_v4(from_id, to_id, mode, quote)
signal terrain_modifiers_changed(tags, modifiers)
