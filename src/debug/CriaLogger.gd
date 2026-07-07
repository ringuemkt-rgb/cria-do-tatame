extends Node
class_name CriaLogger

static func log_event(channel: String, message: String, data: Dictionary = {}) -> void:
	var payload := {
		"channel": channel,
		"message": message,
		"data": data
	}
	print("[CRIA:" + channel.to_upper() + "] " + JSON.stringify(payload))

static func combat(message: String, data: Dictionary = {}) -> void:
	log_event("combat", message, data)

static func career(message: String, data: Dictionary = {}) -> void:
	log_event("career", message, data)

static func qa(message: String, data: Dictionary = {}) -> void:
	log_event("qa", message, data)
