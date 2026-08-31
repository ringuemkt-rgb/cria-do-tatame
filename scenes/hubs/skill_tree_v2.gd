class_name SkillTreeV2
extends Control

const TECHNIQUE_LAYOUT := "TreeFrame/Branches/TecnicaBranch/Layout"

var last_unlocked_technique := ""
var last_unlocked_level := 0

func _ready() -> void:
	if not TrainingManager.technique_leveled_up.is_connected(_on_technique_leveled_up):
		TrainingManager.technique_leveled_up.connect(_on_technique_leveled_up)
	$Header/Back.pressed.connect(_on_back_pressed)
	_refresh_lock_state()

func _exit_tree() -> void:
	if TrainingManager.technique_leveled_up.is_connected(_on_technique_leveled_up):
		TrainingManager.technique_leveled_up.disconnect(_on_technique_leveled_up)

func _refresh_lock_state() -> void:
	$Header/Points.text = "PONTOS DE TÉCNICA  •  %02d" % int(WorldState.skill_points)
	for branch in ["Tecnica", "Pressao", "Frieza", "Legado"]:
		for tier in range(1, 6):
			var path := "TreeFrame/Branches/%sBranch/Layout/%sTier%d" % [branch, branch, tier]
			if not has_node(path):
				continue
			var button: Button = get_node(path)
			button.disabled = tier > 1
			button.modulate = Color.WHITE if tier == 1 else Color(0.52, 0.56, 0.62, 0.72)

func _on_technique_leveled_up(technique_id: String, level: int) -> void:
	var tier := clampi(level, 1, 5)
	var path := "%s/TecnicaTier%d" % [TECHNIQUE_LAYOUT, tier]
	if not has_node(path):
		return
	var button: Button = get_node(path)
	button.disabled = false
	button.modulate = Color.WHITE
	button.set_meta("unlocked_by_technique", technique_id)
	button.tooltip_text = "%s alcançou maestria nível %d" % [technique_id.replace("_", " ").capitalize(), tier]
	if not button.text.begins_with("✓ "):
		button.text = "✓ " + button.text
	last_unlocked_technique = technique_id
	last_unlocked_level = tier

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hubs/TerreiroDaLuta.tscn")
