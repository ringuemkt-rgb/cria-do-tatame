class_name WorldMapUIV2
extends Control

const NODE_PATHS := {
	"valenca": "MapPanel/MapCanvas/MapNodes/Valenca",
	"taperoa": "MapPanel/MapCanvas/MapNodes/Taperoa",
	"itubera": "MapPanel/MapCanvas/MapNodes/Itubera",
	"nilo_pecanha": "MapPanel/MapCanvas/MapNodes/NiloPecanha",
	"cairu": "MapPanel/MapCanvas/MapNodes/Cairu",
	"igrapiuna": "MapPanel/MapCanvas/MapNodes/Igrapiuna",
	"camamu": "MapPanel/MapCanvas/MapNodes/Camamu",
	"marau": "MapPanel/MapCanvas/MapNodes/Marau",
	"pirai_do_norte": "MapPanel/MapCanvas/MapNodes/Pirai",
	"ibirapitanga": "MapPanel/MapCanvas/MapNodes/Ibirapitanga",
	"teolandia": "MapPanel/MapCanvas/MapNodes/Teolandia",
	"presidente_tancredo_neves": "MapPanel/MapCanvas/MapNodes/TancredoNeves"
}

const HUB_TO_MUNICIPALITY := {
	"itubera": "itubera",
	"zambiapunga": "nilo_pecanha",
	"camamu_manguezal": "camamu"
}

const FACTION_COLORS := {
	"ALE": Color("ff9408"),
	"LEM": Color("4a6741"),
	"NTM": Color("3fe3f5"),
	"neutral": Color("77808d")
}

var last_territory_id := ""
var last_municipality_id := ""
var last_time_block := ""
var last_tide_state := ""
var last_tide_level := 0.0

func _ready() -> void:
	if not FactionDirectorManager.territory_changed.is_connected(_on_territory_changed):
		FactionDirectorManager.territory_changed.connect(_on_territory_changed)
	if not WorldDirectorManager.time_advanced.is_connected(_on_time_advanced):
		WorldDirectorManager.time_advanced.connect(_on_time_advanced)
	if not WorldDirectorManager.tide_changed.is_connected(_on_tide_changed):
		WorldDirectorManager.tide_changed.connect(_on_tide_changed)
	_refresh_from_runtime()

func _exit_tree() -> void:
	if FactionDirectorManager.territory_changed.is_connected(_on_territory_changed):
		FactionDirectorManager.territory_changed.disconnect(_on_territory_changed)
	if WorldDirectorManager.time_advanced.is_connected(_on_time_advanced):
		WorldDirectorManager.time_advanced.disconnect(_on_time_advanced)
	if WorldDirectorManager.tide_changed.is_connected(_on_tide_changed):
		WorldDirectorManager.tide_changed.disconnect(_on_tide_changed)

func _refresh_from_runtime() -> void:
	var territories: Dictionary = FactionDirectorManager.get_snapshot().get("territories", {})
	var territory_ids: Array = territories.keys()
	territory_ids.sort()
	for territory_id_value in territory_ids:
		_on_territory_changed(str(territory_id_value), territories[territory_id_value])
	var visual := WorldDirectorManager.get_visual_environment_snapshot()
	_on_time_advanced(str(visual.get("time_block", "manha")), bool(visual.get("is_night", false)))
	_on_tide_changed(str(visual.get("tide_state", "baixa")), float(visual.get("tide_level", 0.0)))

func _on_territory_changed(territory_id: String, territory: Dictionary) -> void:
	var municipality_id := str(territory.get("municipality_id", territory.get("hub", territory_id)))
	municipality_id = str(HUB_TO_MUNICIPALITY.get(municipality_id, municipality_id))
	var path := str(NODE_PATHS.get(municipality_id, ""))
	if path == "" or not has_node(path):
		return
	var button: Button = get_node(path)
	var owner := str(territory.get("owner", "neutral"))
	var control := clampf(float(territory.get("control", 0.0)), 0.0, 100.0)
	var faction_color: Color = FACTION_COLORS.get(owner, FACTION_COLORS["neutral"])
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111722").lerp(faction_color, 0.18 + control / 250.0)
	style.border_color = faction_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	var municipality_name := button.text.split("\n")[0]
	button.text = "%s\n%s %d" % [municipality_name, owner.to_upper(), int(round(control))]
	button.tooltip_text = "%s • controle %d • atualizado pelo território" % [territory.get("name", territory_id), int(round(control))]
	last_territory_id = territory_id
	last_municipality_id = municipality_id

func _on_time_advanced(time_block: String, is_night: bool) -> void:
	last_time_block = time_block
	$Background.color = Color("080d16") if is_night else Color("111d2a")
	$Header/Status.text = "SEMANA %02d  •  %s  •  MARÉ %s" % [
		int(WorldState.week),
		time_block.to_upper(),
		last_tide_state.to_upper() if last_tide_state != "" else "—"
	]

func _on_tide_changed(tide_state: String, tide_level: float) -> void:
	last_tide_state = tide_state
	last_tide_level = clampf(tide_level, 0.0, 1.0)
	$TideOverlay/Layout/TideMeter.value = last_tide_level * 100.0
	$TideOverlay/Layout/TideState.text = "%s  •  NÍVEL %d%%  •  LEITURA VISUAL" % [
		tide_state.to_upper(),
		int(round(last_tide_level * 100.0))
	]
	_on_time_advanced(last_time_block if last_time_block != "" else "manha", last_time_block in ["noite", "madrugada"])
