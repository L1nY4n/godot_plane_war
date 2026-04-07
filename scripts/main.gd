## Main game scene: advanced weapon system with power-ups, weapon levels, and combos.
##
## Weapon levels (up to 8):
##   1  Single shot
##   2  Dual shot
##   3  Triple spread
##   4  Double dual (4 bullets)
##   5  Fan spread + side shots
##   6  Wide fan (7 bullets)
##   7  Dual fan + missiles
##   8  Mega spread (9 bullets + faster fire rate)
##
## Power-ups drop from enemies and give: weapon up, HP heal, shield, bomb
## WASD / Arrows = move, camera adapts to player position, Q = missile, R = bomb, T = shield
##
## Combo system: kill enemies quickly to build a multiplier (up to 5x).
## I-frames: brief invincibility after being hit.
## Boss spawns every 3 waves.

extends Node2D

const VW := 960
const VH := 1200

const PLAYER_SPEED := 300.0
const BULLET_SPEED := 600.0
const E_BULLET_SPEED := 350.0
const FIRE_BASE := 0.15
const MAX_HP := 100
const PICKUP_LIFE := 10.0
const INVINCIBLE_TIME := 2.0
const COMBO_WINDOW := 2.0
const MAX_COMBO := 5
const MAX_WPN_LEVEL := 8
const WAVE_INTERVAL := 40.0

# --- Boss ---
var _boss: BossData = null
var _boss_warning := 0.0
var _boss_phase_banner := 0.0
var _boss_fire_flash := 0.0

class BossData:
	var pos: Vector2 = Vector2.ZERO
	var hp: int = 200
	var max_hp: int = 200
	var phase: float = 0.0
	var attack: int = 0
	var fire_cd: float = 0.0
	var fire_rate: float = 0.8
	var w: float = 120.0
	var h: float = 80.0
	var col: Color = Color(1.0, 0.0, 0.4)
	var hit_flash: float = 0.0
	var entering: bool = true
	var pattern: int = 0
	var pattern_timer: float = 0.0
	var scale: float = 1.0
	var visual: Node3D
	var phase_level: int = 1
	var phase_transition: float = 0.0

# --- Homing missiles ---
const MISSILE_COOLDOWN := 10.0
const MISSILE_SPEED := 450.0
const MISSILE_TURN_RATE := 3.0
const MISSILE_DMG := 3
const MISSILE_LIFE := 5.0
const MAX_MISSILES := 10
var _missile_cd := 0.0
var _missiles: int = 5

class HomingMissile:
	var pos: Vector2
	var angle: float = 0.0
	var speed: float
	var dmg: int
	var life: float
	var smoke: PackedVector2Array = []
	var visual: Node3D

# --- Stored pickups ---
const MAX_PICKUP_STORE := 10
var _stored_pickups: Array[int] = []

# --- Wingmen ---
var _wingmen: Array[Wingman] = []

class Wingman:
	var offset: Vector2
	var missile_cd: float = 0.0
	var fire_flash: float = 0.0
	var visual: Node3D

enum PickupType { WEAPON, HEAL, SHIELD, BOMB, MISSILE }
enum BossAttack { STRAIGHT, SPREAD, BURST }

# --- Player ---
var _player: Rect2
var _player_alive := false
var _has_shield := false
var _shield_flash := 0.0
var _invincible := 0.0
var _player_bank := 0.0
var _player_fire_flash := 0.0

# --- State ---
var _score: int = 0
var _display_score: int = 0
var _hp: int = MAX_HP
var _fire_cd := 0.0
var _elapsed := 0.0
var _running := false
var _paused := false
var _game_over_elapsed := 0.0
var _high_score: int = 0
var _edge_warning := 0.0

# --- Combo ---
var _combo: int = 0
var _combo_timer := 0.0
var _combo_display_timer := 0.0
var _combo_bar := 0.0  # Visual bar width for combo timer

# --- Weapon ---
var _wpn_level: int = 1
var _fire_rate := FIRE_BASE
var _weapon_up_flash := 0.0  # Brief screen flash on weapon upgrade

# --- Spawn ---
const _SPAWN_INTERVAL_MIN := 0.20
const _SPAWN_INTERVAL_BASE := 1.5
const _SPAWN_ACCEL := 0.008
var _spawn_cd := 0.0

# --- Difficulty waves ---
var _wave_timer := 0.0
var _wave_number: int = 0
var _wave_warning := 0.0  # Countdown display for "WAVE X INCOMING"
var _ambient_lane_step := 0

# --- Screen shake ---
var _shake := 0.0
var _shake_intensity := 60.0

class StarPoint:
	var pos: Vector2
	var speed: float
	var size: float
	var alpha: float
	var phase: float

class Nebula:
	var pos: Vector2
	var radius: float
	var drift: Vector2
	var alpha: float
	var col: Color
	var phase: float

# --- Background ---
var _stars: Array[StarPoint] = []
var _nebulae: Array[Nebula] = []

# --- Entity pools ---
var _pbullets: Array[Bullet] = []
var _ebullets: Array[EnemyBullet] = []
var _missile_pool: Array[HomingMissile] = []
var _enemies: Array[EnemyData] = []

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var col: Color
	var dmg: int
	var trail: bool
	var visual: Node3D

class EnemyBullet:
	var pos: Vector2
	var vel: Vector2
	var visual: Node3D

# --- Pickups ---
var _pickups: Array[Pickup] = []

class Pickup:
	var pos: Vector2
	var type: int
	var life: float
	var bob: float
	var rot: float
	var visual: Node3D

# --- FX ---
var _explosions: Array[Explosion] = []
var _sparks: Array[Spark] = []
var _text_fx: Array[TextFX] = []
var _ring_fx: Array[RingFX] = []  # Expanding ring effect

class Explosion:
	var pos: Vector2
	var radius: float
	var max_radius: float
	var col: Color
	var lift: float
	var flash: float
	var spin: float
	var visual: Node3D

class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var col: Color
	var size: float
	var visual: Node3D

class TextFX:
	var pos: Vector2
	var text: String
	var life: float
	var max_life: float
	var vel: Vector2
	var col: Color = Color(1.0, 1.0, 0.6, 1.0)

class RingFX:
	var pos: Vector2
	var radius: float
	var max_radius: float
	var col: Color
	var line_width: float
	var height: float
	var tilt: float
	var spin: float
	var visual: Node3D

# --- Enemy data ---
class EnemyData:
	var pos: Vector2
	var hp: int
	var max_hp: int
	var spd: float
	var score: int
	var fire_cd: float
	var fire_rate: float
	var w: float
	var h: float
	var col: Color
	var phase: float
	var boss_attack: int
	var hit_flash: float
	var fire_flash: float
	var visual: Node3D
	var lane_x: float
	var lane_band: float

# --- Enemy stats: [hp, speed, score, fire_rate, width, height, color] ---
const _ENEMY_STATS = [
	[1, 150.0, 100, 0.0, 20.0, 20.0, Color(1.0, 0.2, 0.25)],
	[3, 100.0, 300, 1.5, 32.0, 32.0, Color(1.0, 0.55, 0.15)],
	[20, 50.0, 5000, 0.5, 52.0, 48.0, Color(0.65, 0.0, 0.95)],
]

# --- UI ---
var _ui_score: Label
var _ui_hp: Label
var _ui_wpn: Label
var _ui_shield: Label
var _ui_missiles: Label
var _ui_wave: Label
var _ui_start: Control
var _ui_over: Control
var _ui_game_over_score: Label
var _ui_game_over_high: Label
var _ui_store: Label

# --- 3D World ---
var _is_web_build := OS.has_feature("web")
var _use_3d := not _is_web_build
const MODEL_PLAYER_PATH := "res://assets/models/player_ship.glb"
const MODEL_WINGMAN_PATH := "res://assets/models/wingman_drone.glb"
const MODEL_ENEMY_LIGHT_PATH := "res://assets/models/enemy_light.glb"
const MODEL_ENEMY_MID_PATH := "res://assets/models/enemy_mid.glb"
const MODEL_ENEMY_HEAVY_PATH := "res://assets/models/enemy_heavy.glb"
const MODEL_BOSS_PATH := "res://assets/models/boss_flagship.glb"
const BAKED_MODEL_PLAYER_PATH := "res://assets/baked_models/player_ship_baked.tscn"
const BAKED_MODEL_WINGMAN_PATH := "res://assets/baked_models/wingman_drone_baked.tscn"
const BAKED_MODEL_ENEMY_LIGHT_PATH := "res://assets/baked_models/enemy_light_baked.tscn"
const BAKED_MODEL_ENEMY_MID_PATH := "res://assets/baked_models/enemy_mid_baked.tscn"
const BAKED_MODEL_ENEMY_HEAVY_PATH := "res://assets/baked_models/enemy_heavy_baked.tscn"
const BAKED_MODEL_BOSS_PATH := "res://assets/baked_models/boss_flagship_baked.tscn"
const MODEL_PLAYER_BULLET_PATH := "res://assets/models/player_bullet.glb"
const MODEL_ENEMY_BULLET_PATH := "res://assets/models/enemy_bullet.glb"
const MODEL_MISSILE_PATH := "res://assets/models/homing_missile.glb"
const PICKUP_MODEL_PATHS := {
	PickupType.WEAPON: "res://assets/models/pickup_weapon.glb",
	PickupType.HEAL: "res://assets/models/pickup_heal.glb",
	PickupType.SHIELD: "res://assets/models/pickup_shield.glb",
	PickupType.BOMB: "res://assets/models/pickup_bomb.glb",
	PickupType.MISSILE: "res://assets/models/pickup_missile.glb",
}
const WORLD_SCALE := 0.05
const WORLD_HALF_WIDTH := VW * WORLD_SCALE * 0.5
const WORLD_HALF_HEIGHT := VH * WORLD_SCALE * 0.5
const GROUND_HALF_LENGTH := 120.0
const GROUND_HALF_WIDTH := 36.0
const PLAYER_SAFE_MARGIN_X_3D := 150.0
const PLAYER_SAFE_MARGIN_TOP_3D := 70.0
const PLAYER_SAFE_MARGIN_BOTTOM_3D := 170.0
const CAMERA_VIEW_PRESETS := [0.0, 1.0, 2.0]
const CAMERA_VIEW_LABELS := ["远景", "标准", "近景"]
const CAMERA_VIEW_TACTICS := ["航线", "压制", "核心"]
const CAMERA_AUTO_REASON_LABELS := ["巡航", "推进", "拾取", "Boss"]
const BOSS_PHASE_TITLES := ["", "扫描", "压制", "过载"]
const CAMERA_VIEW_FOCUS_OFFSETS := [-0.2, -1.4, -3.0]
const CAMERA_VIEW_FOCUS_X := [0.28, 0.42, 0.58]
const CAMERA_VIEW_HEIGHTS := [78.0, 64.0, 54.0]
const CAMERA_VIEW_DISTANCES := [102.0, 76.0, 56.0]
const CAMERA_VIEW_FOVS := [28.5, 34.5, 41.0]
const CAMERA_VIEW_SMOOTH := [0.04, 0.055, 0.075]
const CAMERA_VIEW_TRACK_X := [0.72, 0.98, 1.15]
const CAMERA_VIEW_BOSS_X_BLEND := [0.28, 0.52, 0.82]
const CAMERA_VIEW_BOSS_Y_AHEAD := [176.0, 148.0, 112.0]
const CAMERA_VIEW_BOSS_COMPOSITION := [0.58, 0.68, 0.78]
const CAMERA_VIEW_BOSS_HEIGHT_OFFSETS := [10.0, 4.5, 0.0]
const CAMERA_VIEW_BOSS_DISTANCE_OFFSETS := [18.0, 10.0, 4.0]
const CAMERA_VIEW_BOSS_FOV_OFFSETS := [1.4, 0.8, 1.8]
const CAMERA_VIEW_BOSS_FOCUS_Y := [0.72, 0.86, 1.06]
const CAMERA_VIEW_BOSS_TRACK_X_OFFSETS := [-0.08, -0.03, 0.04]
const BACKDROP_SYNC_INTERVAL_3D := 0.033
const VISUAL_MARGIN_X_3D := 240.0
const VISUAL_MARGIN_Y_3D := 220.0
const FX_VISUAL_MARGIN_X_3D := 320.0
const FX_VISUAL_MARGIN_Y_3D := 320.0
const MAX_ACTIVE_EXPLOSIONS := 18
const MAX_ACTIVE_RING_FX := 24
const MAX_ACTIVE_SPARKS := 140
const MAX_ACTIVE_EXPLOSION_VISUALS_3D := 12
const MAX_ACTIVE_RING_VISUALS_3D := 14
const MAX_ACTIVE_SPARK_VISUALS_3D := 56
const MAX_ACTIVE_ENEMY_SENSOR_GLOWS_3D := 22
const MAX_ACTIVE_PLAYER_BULLET_VISUALS_3D := 72
const MAX_ACTIVE_ENEMY_BULLET_VISUALS_3D := 96
const WINGMAN_TRAIL_BASE := -10.0
const WINGMAN_TRAIL_CLOSE := -4.0
const WINGMAN_LATERAL_BASE := 72.0
const WINGMAN_LATERAL_CLOSE := 96.0
var _world_root: Node3D
var _camera_3d: Camera3D
var _entity_root_3d: Node3D
var _player_root_3d: Node3D
var _wingmen_root_3d: Node3D
var _bullets_root_3d: Node3D
var _enemy_bullets_root_3d: Node3D
var _enemies_root_3d: Node3D
var _pickups_root_3d: Node3D
var _missiles_root_3d: Node3D
var _boss_root_3d: Node3D
var _ground_root_3d: Node3D
var _fx_root_3d: Node3D
var _background_root_3d: Node3D
var _player_visual_3d: Node3D
var _shield_visual_3d: MeshInstance3D
var _ground_lines_3d: Array[MeshInstance3D] = []
var _ground_center_markers_3d: Array[MeshInstance3D] = []
var _ground_safe_guides_3d: Array[MeshInstance3D] = []
var _space_clouds_3d: Array[MeshInstance3D] = []
var _space_stars_3d: Array[MeshInstance3D] = []
var _space_planet_3d: MeshInstance3D
var _space_ring_root_3d: Node3D
var _space_ring_bands_3d: Array[MeshInstance3D] = []
var _space_ring_debris_3d: Array[MeshInstance3D] = []
var _model_scene_cache: Dictionary = {}
var _detail_material_cache: Dictionary = {}
var _part_material_cache: Dictionary = {}
var _primitive_mesh_cache: Dictionary = {}
var _camera_focus_3d := Vector3.ZERO
var _camera_focus_ready := false
var _camera_view_bias := 1.0
var _camera_view_preset := 1
var _camera_auto_reason := "巡航"
var _view_up_prev := false
var _view_down_prev := false
var _player_move_hint := Vector2.ZERO
var _backdrop_sync_accum := 0.0


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_SPACE:
		if _ui_start.visible:
			_start_game()
		elif _ui_over.visible and not _running:
			_restart()
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		if _paused:
			_unpause()
		elif _running:
			_pause()
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_Q: _release_stored(PickupType.MISSILE)
			KEY_R: _release_stored(PickupType.BOMB)
			KEY_T: _release_stored(PickupType.SHIELD)


func _ready() -> void:
	_ui_score = $UI/ScoreLabel
	_ui_hp = $UI/HPLabel
	_ui_wpn = $UI/WpnLabel
	_ui_shield = $UI/ShieldLabel
	_ui_missiles = $UI/MissileCount
	_ui_wave = $UI/WaveLabel
	_ui_start = $UI/StartScreen
	_ui_over = $UI/GameOver
	_ui_game_over_score = $UI/GameOver/ScoreText
	_ui_game_over_high = $UI/GameOver/HighText
	_ui_store = $UI/StoreLabel
	_ui_over.visible = false
	_ui_start.visible = true
	if _use_3d:
		_setup_3d_world()
	_setup_background()
	_ui_update()


func _setup_background() -> void:
	_stars.clear()
	_nebulae.clear()

	var star_count := 120 if _is_web_build else 240
	for _i in star_count:
		var star := StarPoint.new()
		star.pos = Vector2(randf_range(-20.0, VW + 20.0), randf_range(0, VH))
		star.speed = randf_range(12.0, 240.0)
		star.size = randf_range(0.7, 2.8)
		star.alpha = randf_range(0.14, 0.95)
		star.phase = randf_range(0.0, TAU)
		_stars.append(star)

	var nebula_palette := [
		Color(0.1, 0.22, 0.56),
		Color(0.06, 0.38, 0.72),
		Color(0.36, 0.14, 0.58),
		Color(0.74, 0.22, 0.48),
		Color(0.18, 0.12, 0.32),
	]
	var nebula_count := 4 if _is_web_build else 8
	for i in nebula_count:
		var nebula := Nebula.new()
		nebula.pos = Vector2(randf_range(-40.0, VW + 40.0), randf_range(40.0, VH - 40.0))
		nebula.radius = randf_range(110.0, 240.0)
		nebula.drift = Vector2(randf_range(-4.5, 4.5), randf_range(3.5, 10.0))
		nebula.alpha = randf_range(0.05, 0.16)
		nebula.col = nebula_palette[i % nebula_palette.size()]
		nebula.phase = randf_range(0.0, TAU)
		_nebulae.append(nebula)


func _setup_space_backdrop_3d() -> void:
	_background_root_3d = Node3D.new()
	_background_root_3d.name = "Background3D"
	_world_root.add_child(_background_root_3d)

	_space_clouds_3d.clear()
	_space_stars_3d.clear()

	var planet_glow := _make_sphere_part(44.0, Color(0.16, 0.24, 0.55, 0.08), Color(0.12, 0.34, 0.82), 0.0, 0.02)
	planet_glow.material_override = _make_space_material(Color(0.16, 0.24, 0.55, 0.08), Color(0.12, 0.34, 0.82), 0.02, 2.2)
	planet_glow.position = Vector3(-84.0, 56.0, -284.0)
	planet_glow.scale = Vector3(1.16, 1.16, 1.16)
	_background_root_3d.add_child(planet_glow)

	_space_planet_3d = _make_sphere_part(38.0, Color(0.05, 0.08, 0.18), Color(0.03, 0.08, 0.18), 0.0, 0.08)
	_space_planet_3d.material_override = _make_space_material(Color(0.05, 0.08, 0.18), Color(0.04, 0.12, 0.24), 0.08, 1.0)
	_space_planet_3d.position = Vector3(-88.0, 54.0, -290.0)
	_background_root_3d.add_child(_space_planet_3d)

	var rng := RandomNumberGenerator.new()
	rng.seed = 9042601

	_space_ring_root_3d = Node3D.new()
	_space_ring_root_3d.name = "PlanetRing3D"
	_space_ring_root_3d.position = Vector3(-88.0, 56.0, -290.0)
	_space_ring_root_3d.rotation_degrees = Vector3(74.0, 16.0, -18.0)
	_background_root_3d.add_child(_space_ring_root_3d)

	_space_ring_bands_3d.clear()
	for i in range(3):
		var band := MeshInstance3D.new()
		band.mesh = _get_box_mesh(Vector3(98.0 + float(i) * 16.0, 0.12, 2.6 + float(i) * 1.1))
		band.position = Vector3(0.0, -1.0 + float(i) * 0.18, 0.0)
		band.material_override = _make_space_material(
			Color(0.16, 0.22 + float(i) * 0.02, 0.42 + float(i) * 0.06, 0.08 - float(i) * 0.016),
			Color(0.1, 0.26, 0.62),
			0.1,
			1.25 - float(i) * 0.14
		)
		_space_ring_root_3d.add_child(band)
		_space_ring_bands_3d.append(band)

	_space_ring_debris_3d.clear()
	for i in range(28):
		var angle := TAU * float(i) / 28.0 + rng.randf_range(-0.12, 0.12)
		var radius := rng.randf_range(48.0, 70.0)
		var debris := _make_box_part(
			Vector3(rng.randf_range(0.45, 1.6), rng.randf_range(0.12, 0.32), rng.randf_range(0.25, 1.1)),
			Color(0.12, 0.14, 0.22, 0.55),
			Color(0.08, 0.14, 0.24),
			0.04,
			0.42
		)
		debris.material_override = _make_space_material(Color(0.14, 0.18, 0.28, 0.46), Color(0.08, 0.12, 0.2), 0.32, 0.55)
		debris.position = Vector3(cos(angle) * radius, rng.randf_range(-0.7, 0.7), sin(angle) * radius)
		debris.rotation_degrees = Vector3(rng.randf_range(-18.0, 18.0), rad_to_deg(angle) + 90.0, rng.randf_range(-42.0, 42.0))
		debris.set_meta("base_pos", debris.position)
		debris.set_meta("base_rot", debris.rotation_degrees)
		debris.set_meta("phase", rng.randf_range(0.0, TAU))
		debris.set_meta("spin", rng.randf_range(-18.0, 18.0))
		_space_ring_root_3d.add_child(debris)
		_space_ring_debris_3d.append(debris)

	var cloud_specs := [
		[Vector3(-54.0, 36.0, -224.0), Vector3(1.9, 0.56, 1.1), 20.0, Color(0.24, 0.08, 0.44, 0.08), Color(0.26, 0.08, 0.62), 0.2],
		[Vector3(62.0, 48.0, -248.0), Vector3(1.45, 0.52, 1.24), 26.0, Color(0.04, 0.2, 0.44, 0.1), Color(0.0, 0.46, 0.82), 1.4],
		[Vector3(4.0, 28.0, -318.0), Vector3(2.25, 0.44, 1.5), 30.0, Color(0.22, 0.1, 0.3, 0.07), Color(0.4, 0.12, 0.56), 2.7],
		[Vector3(94.0, 84.0, -338.0), Vector3(1.6, 0.5, 1.2), 22.0, Color(0.08, 0.18, 0.38, 0.08), Color(0.14, 0.34, 0.78), 3.6],
	]
	for spec in cloud_specs:
		var cloud := _make_sphere_part(spec[2], spec[3], spec[4], 0.0, 0.04)
		cloud.material_override = _make_space_material(spec[3], spec[4], 0.04, 1.8)
		cloud.position = spec[0]
		cloud.scale = spec[1]
		cloud.set_meta("base_scale", spec[1])
		cloud.set_meta("phase", spec[5])
		_background_root_3d.add_child(cloud)
		_space_clouds_3d.append(cloud)

	var star_palette := [
		[Color(0.92, 0.97, 1.0, 0.9), Color(0.42, 0.7, 1.0)],
		[Color(1.0, 0.93, 0.8, 0.9), Color(0.96, 0.58, 0.18)],
		[Color(0.86, 0.92, 1.0, 0.86), Color(0.48, 0.88, 1.0)],
	]
	for i in range(56):
		var palette_entry = star_palette[i % star_palette.size()]
		var star := _make_sphere_part(rng.randf_range(0.16, 0.72), palette_entry[0], palette_entry[1], 0.0, 0.02)
		star.material_override = _make_space_material(palette_entry[0], palette_entry[1], 0.02, rng.randf_range(1.8, 3.1))
		star.position = Vector3(
			rng.randf_range(-132.0, 132.0),
			rng.randf_range(12.0, 124.0),
			rng.randf_range(-364.0, -158.0)
		)
		star.scale = Vector3.ONE * rng.randf_range(0.85, 1.4)
		star.set_meta("base_scale", star.scale)
		star.set_meta("phase", rng.randf_range(0.0, TAU))
		_background_root_3d.add_child(star)
		_space_stars_3d.append(star)


func _start_game() -> void:
	_ui_start.visible = false
	_running = true
	_score = 0
	_display_score = 0
	_hp = MAX_HP
	_wpn_level = 1
	_elapsed = 0.0
	_fire_cd = 0.0
	_spawn_cd = 1.0
	_shield_flash = 0.0
	_has_shield = false
	_invincible = 0.0
	_combo = 0
	_combo_timer = 0.0
	_combo_display_timer = 0.0
	_combo_bar = 0.0
	_shake = 0.0
	_wave_timer = 0.0
	_wave_number = 0
	_wave_warning = 0.0
	_ambient_lane_step = 0
	_boss_warning = 0.0
	_boss_phase_banner = 0.0
	_boss_fire_flash = 0.0
	_boss = null
	_weapon_up_flash = 0.0
	_player_fire_flash = 0.0
	_player = Rect2(VW / 2.0 - 12.0, VH - 120.0, 24.0, 32.0)
	_player_alive = true
	_player_bank = 0.0
	_fire_rate = FIRE_BASE
	_pbullets.clear()
	_ebullets.clear()
	_missile_pool.clear()
	_enemies.clear()
	_explosions.clear()
	_sparks.clear()
	_pickups.clear()
	_text_fx.clear()
	_ring_fx.clear()
	_missile_cd = 0.0
	_missiles = 5
	_stored_pickups.clear()
	_wingmen.clear()
	if _use_3d:
		_clear_3d_dynamic_visuals()
	_ui_update()


func _restart() -> void:
	_ui_over.visible = false
	_start_game()


func _physics_process(delta: float) -> void:
	if _paused:
		queue_redraw()
		return

	if not _running:
		if _game_over_elapsed > 0.0:
			_game_over_elapsed += delta
			if _display_score < _score:
				_display_score = mini(int(_game_over_elapsed * 2000.0), _score)
				_ui_score.text = "SCORE  " + str(_display_score)
			if _display_score >= _score:
				_game_over_elapsed = 0.0
			queue_redraw()
		return

	_elapsed += delta
	_game_over_elapsed = 0.0

	if _player_alive:
		_move_player(delta)
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_player_shoot()
			_fire_cd = _fire_rate
		_invincible = maxf(_invincible - delta, 0.0)

	if _shield_flash > 0.0:
		_shield_flash = maxf(_shield_flash - delta * 3.0, 0.0)

	if _wave_warning > 0.0:
		_wave_warning -= delta

	if _weapon_up_flash > 0.0:
		_weapon_up_flash -= delta * 4.0
	if _player_fire_flash > 0.0:
		_player_fire_flash = maxf(_player_fire_flash - delta * 6.0, 0.0)
	if _boss_fire_flash > 0.0:
		_boss_fire_flash = maxf(_boss_fire_flash - delta * 3.8, 0.0)

	# Combo
	if _combo_timer > 0.0:
		_combo_timer -= delta
		_combo_bar = _combo_timer / COMBO_WINDOW
		if _combo_timer <= 0.0:
			_combo = 0
			_combo_bar = 0.0
	if _combo_display_timer > 0.0:
		_combo_display_timer -= delta

	# Shake
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 8.0, 0.0)

	# Waves
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
		_wave_warning = 2.0
		_trigger_wave()

	# Background drift
	for star in _stars:
		star.pos.y += star.speed * delta
		if star.pos.y > VH + 8.0:
			star.pos.y = -8.0
			star.pos.x = randf_range(0.0, VW)

	for nebula in _nebulae:
		nebula.pos += nebula.drift * delta
		nebula.phase += delta * 0.2
		if nebula.pos.y - nebula.radius > VH:
			nebula.pos.y = -nebula.radius
			nebula.pos.x = randf_range(50.0, VW - 50.0)
		if nebula.pos.x < -nebula.radius:
			nebula.pos.x = VW + nebula.radius
		elif nebula.pos.x > VW + nebula.radius:
			nebula.pos.x = -nebula.radius

	# Player bullets
	for b in _pbullets:
		b.pos += b.vel * delta

	# Enemy bullets
	for eb in _ebullets:
		eb.pos += eb.vel * delta

	# Homing missiles
	_missile_cd = maxf(_missile_cd - delta, 0.0)
	_update_missiles(delta)
	_update_wingmen(delta)

	# Spawn
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_do_spawn()
		_spawn_cd = maxf(_SPAWN_INTERVAL_MIN, _SPAWN_INTERVAL_BASE - _elapsed * _SPAWN_ACCEL)

	# Enemies
	for e in _enemies:
		_move_enemy(e, delta)
		if e.fire_rate > 0.0:
			e.fire_cd -= delta
			if e.fire_cd <= 0.0:
				_spawn_enemy_bullet(e)
				e.fire_cd = e.fire_rate
		if e.hit_flash > 0.0:
			e.hit_flash -= delta * 5.0
		if e.fire_flash > 0.0:
			e.fire_flash = maxf(e.fire_flash - delta * 4.6, 0.0)

	# Boss
	if _boss != null:
		_update_boss(delta)

	if _boss_warning > 0.0:
		_boss_warning -= delta
	if _boss_phase_banner > 0.0:
		_boss_phase_banner -= delta

	# Pickups
	for pu in _pickups:
		pu.life -= delta
		pu.bob += delta * 4.0
		pu.rot += delta * 3.0
		pu.pos.y += 40.0 * delta
	_pickups = _pickups.filter(func(p): return p.life > 0.0)

	if _player_alive:
		_collect_pickups()

	# FX
	for ex in _explosions:
		ex.radius += 400.0 * delta
	for s in _sparks:
		s.pos += s.vel * delta
		s.life -= delta
	for tfx in _text_fx:
		tfx.pos += tfx.vel * delta
		tfx.life -= delta
	for rfx in _ring_fx:
		rfx.radius += 500.0 * delta

	# Collisions
	_collide_pbullets_vs_enemies()
	_collide_missiles_vs_enemies()
	if _player_alive:
		_collide_bullets_vs_boss()
		_collide_missiles_vs_boss()
	if _player_alive:
		_collide_ebullets_vs_player()
		_collide_enemies_vs_player()

	# Cull
	_compact_player_bullets()
	_compact_enemy_bullets()
	_missile_pool = _missile_pool.filter(func(m): return m.life > 0.0)
	_enemies = _enemies.filter(func(e): return e.pos.y < VH + 60)
	_explosions = _explosions.filter(func(ex): return ex.radius < ex.max_radius)
	_sparks = _sparks.filter(func(s): return s.life > 0.0)
	_text_fx = _text_fx.filter(func(t): return t.life > 0.0)
	_ring_fx = _ring_fx.filter(func(r): return r.radius < r.max_radius)

	_update_camera_view_input(delta)
	_ui_update()
	if _use_3d:
		_sync_3d_world(delta)
	queue_redraw()


func _move_player(dt: float) -> void:
	var d := Vector2.ZERO
	d.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	d.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	# Direct arrow key fallback
	if Input.is_key_pressed(KEY_LEFT): d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT): d.x += 1
	if Input.is_key_pressed(KEY_UP): d.y -= 1
	if Input.is_key_pressed(KEY_DOWN): d.y += 1
	if d.length() > 0:
		d = d.normalized()
		_player.position += d * PLAYER_SPEED * dt
	_player_bank = lerpf(_player_bank, d.x * 0.5, 0.12)
	_player_move_hint = _player_move_hint.lerp(d, 0.18)
	var min_x := 0.0
	var max_x := VW - _player.size.x
	var min_y := 0.0
	var max_y := VH - _player.size.y
	if _use_3d:
		min_x = PLAYER_SAFE_MARGIN_X_3D
		max_x = VW - _player.size.x - PLAYER_SAFE_MARGIN_X_3D
		min_y = PLAYER_SAFE_MARGIN_TOP_3D
		max_y = VH - _player.size.y - PLAYER_SAFE_MARGIN_BOTTOM_3D
	_player.position.x = clampf(_player.position.x, min_x, max_x)
	_player.position.y = clampf(_player.position.y, min_y, max_y)
	var left_margin := _player.position.x - min_x
	var right_margin := max_x - _player.position.x
	var edge_dist := minf(left_margin, right_margin)
	var edge_ratio := clampf(1.0 - edge_dist / 72.0, 0.0, 1.0)
	_edge_warning = lerpf(_edge_warning, edge_ratio, 0.18)


func _update_camera_view_input(dt: float) -> void:
	if not _use_3d:
		return
	var player_center := _player.get_center() if _player_alive else Vector2(VW * 0.5, VH * 0.74)
	var min_y := PLAYER_SAFE_MARGIN_TOP_3D + _player.size.y * 0.5
	var max_y := VH - PLAYER_SAFE_MARGIN_BOTTOM_3D - _player.size.y * 0.5
	var y_span := maxf(max_y - min_y, 1.0)
	var y_norm := clampf((player_center.y - min_y) / y_span, 0.0, 1.0)
	var desired_bias := lerpf(0.22, 1.22, y_norm)
	var pickup_focus := _camera_pickup_focus(player_center)
	var pickup_pull := float(pickup_focus.weight)
	var move_up_pull := clampf(-_player_move_hint.y, 0.0, 1.0)
	var move_down_push := clampf(_player_move_hint.y, 0.0, 1.0)
	desired_bias -= move_up_pull * 0.18
	desired_bias += move_down_push * 0.14
	if pickup_pull > 0.0:
		desired_bias -= pickup_pull * 0.28
	if _boss != null:
		desired_bias += 0.12 + float(maxi(_boss.phase_level - 1, 0)) * 0.08
		_camera_auto_reason = CAMERA_AUTO_REASON_LABELS[3]
	elif pickup_pull > 0.26:
		_camera_auto_reason = CAMERA_AUTO_REASON_LABELS[2]
	elif move_up_pull > 0.18:
		_camera_auto_reason = CAMERA_AUTO_REASON_LABELS[1]
	else:
		_camera_auto_reason = CAMERA_AUTO_REASON_LABELS[0]
	desired_bias = clampf(desired_bias, 0.0, 1.75)
	_camera_view_bias = lerpf(_camera_view_bias, desired_bias, minf(dt * (3.6 + absf(desired_bias - _camera_view_bias) * 2.8), 1.0))
	_camera_view_preset = clampi(int(round(_camera_view_bias)), 0, CAMERA_VIEW_PRESETS.size() - 1)


func _sample_camera_setting(values: Array) -> float:
	var idx0 := int(floor(_camera_view_bias))
	var idx1 := mini(idx0 + 1, values.size() - 1)
	idx0 = clampi(idx0, 0, values.size() - 1)
	var t := clampf(_camera_view_bias - float(idx0), 0.0, 1.0)
	return lerpf(float(values[idx0]), float(values[idx1]), t)


func _camera_view_norm() -> float:
	return clampf(_camera_view_bias / float(maxi(CAMERA_VIEW_PRESETS.size() - 1, 1)), 0.0, 1.0)


func _camera_pickup_focus(player_center: Vector2) -> Dictionary:
	var best_weight := 0.0
	var best_pos := player_center
	for p in _pickups:
		var dx := absf(p.pos.x - player_center.x)
		var dy := p.pos.y - player_center.y
		if dx > 220.0:
			continue
		if absf(dy) > 300.0:
			continue
		var horiz_t := 1.0 - dx / 220.0
		var vert_t := 1.0 - absf(dy) / 300.0
		var ahead_bonus := 0.2 if dy < 0.0 else 0.0
		var weight := clampf(horiz_t * 0.45 + vert_t * 0.4 + ahead_bonus, 0.0, 1.0)
		if weight > best_weight:
			best_weight = weight
			best_pos = p.pos
	return {"pos": best_pos, "weight": best_weight}


func _boss_phase_title(phase: int) -> String:
	return BOSS_PHASE_TITLES[clampi(phase, 0, BOSS_PHASE_TITLES.size() - 1)]


func _wingman_slot_offset(slot: int) -> Vector2:
	var view_t := _camera_view_norm() if _use_3d else 0.5
	var lateral := lerpf(WINGMAN_LATERAL_BASE, WINGMAN_LATERAL_CLOSE, view_t)
	var trail := lerpf(WINGMAN_TRAIL_BASE, WINGMAN_TRAIL_CLOSE, view_t)
	var side := -1.0 if slot % 2 == 0 else 1.0
	var slot_pair := int(slot / 2)
	var extra_trail := float(slot_pair) * 18.0
	return Vector2(side * (lateral + float(slot_pair) * 12.0), trail + extra_trail)


func _boss_camera_intensity() -> float:
	if _boss == null:
		return 0.0
	var phase_t := float(maxi(_boss.phase_level - 1, 0)) / 2.0
	var transition_t := clampf(_boss.phase_transition / 1.15, 0.0, 1.0)
	var banner_t := clampf(_boss_phase_banner / 2.1, 0.0, 1.0)
	return clampf(0.36 + phase_t * 0.24 + maxf(transition_t, banner_t) * 0.34, 0.0, 1.0)


func _get_safe_lane_centers() -> Array[float]:
	var left := 30.0
	var right := VW - 30.0
	if _use_3d:
		left = PLAYER_SAFE_MARGIN_X_3D + 30.0
		right = VW - PLAYER_SAFE_MARGIN_X_3D - 30.0
	var mid := (left + right) * 0.5
	var span := (right - left) * lerpf(0.36, 0.24, _camera_view_norm())
	return [mid - span, mid, mid + span]


func _camera_composition_target(player_center: Vector2) -> Vector2:
	var lanes := _get_safe_lane_centers()
	var center_lane := _lane_pick(lanes, 1)
	var forward_x := clampf(player_center.x + _player_move_hint.x * 120.0, PLAYER_SAFE_MARGIN_X_3D, VW - PLAYER_SAFE_MARGIN_X_3D)
	var forward_y := clampf(player_center.y - 240.0 - clampf(-_player_move_hint.y, 0.0, 1.0) * 90.0, 150.0, VH * 0.66)
	var anchor := Vector2(lerpf(center_lane, forward_x, 0.24), forward_y)

	if _boss != null:
		var boss_x_blend := _sample_camera_setting(CAMERA_VIEW_BOSS_X_BLEND)
		var boss_y_ahead := _sample_camera_setting(CAMERA_VIEW_BOSS_Y_AHEAD)
		var boss_comp := _sample_camera_setting(CAMERA_VIEW_BOSS_COMPOSITION)
		var phase_t := float(maxi(_boss.phase_level - 1, 0)) / 2.0
		var phase_pull := clampf(_boss.phase_transition * 0.14 + _boss_phase_banner * 0.08, 0.0, 0.2)
		var focus_x := lerpf(center_lane, _boss.pos.x, clampf(boss_x_blend + phase_t * 0.08, 0.0, 0.94))
		anchor = Vector2(
			focus_x,
			clampf(
				_boss.pos.y + boss_y_ahead - phase_t * 18.0,
				118.0,
				player_center.y - lerpf(84.0, 24.0, _camera_view_norm())
			)
		)
		return player_center.lerp(anchor, clampf(boss_comp + phase_pull, 0.36, 0.9))
	else:
		var found := false
		var best_y := -INF
		var best_x := center_lane
		for e in _enemies:
			if e.pos.y < player_center.y - 40.0 and e.pos.y > best_y:
				best_y = e.pos.y
				best_x = e.lane_x if e.lane_x != 0.0 else e.pos.x
				found = true
		if found:
			anchor = Vector2(best_x, clampf(best_y - 120.0, 120.0, player_center.y - 60.0))
		var pickup_focus := _camera_pickup_focus(player_center)
		var pickup_weight := float(pickup_focus.weight)
		if pickup_weight > 0.0:
			var pickup_pos := pickup_focus.pos as Vector2
			var pickup_anchor := Vector2(
				clampf(lerpf(player_center.x, pickup_pos.x, 0.68), PLAYER_SAFE_MARGIN_X_3D, VW - PLAYER_SAFE_MARGIN_X_3D),
				clampf(minf(player_center.y - 90.0, pickup_pos.y - 64.0), 120.0, player_center.y - 24.0)
			)
			anchor = anchor.lerp(pickup_anchor, pickup_weight * 0.42)

	var cinematic_t := 1.0 - _camera_view_norm()
	return player_center.lerp(anchor, 0.18 + cinematic_t * 0.5)


func _lane_band_for_enemy(enemy_hp: int) -> float:
	if enemy_hp <= 1:
		return 54.0
	if enemy_hp <= 3:
		return 38.0
	return 22.0


func _setup_enemy_lane(e: EnemyData, lane_x: float) -> void:
	e.lane_x = lane_x
	e.lane_band = _lane_band_for_enemy(e.max_hp)
	e.pos.x = clampf(lane_x + randf_range(-e.lane_band * 0.3, e.lane_band * 0.3), e.w / 2.0, VW - e.w / 2.0)


func _spawn_enemy_from_tier(tier: int, lane_x: float, y_pos: float, phase_offset: float = 0.0, band_scale: float = 1.0) -> void:
	var s: Array = _ENEMY_STATS[tier]
	var e := EnemyData.new()
	e.pos = Vector2(lane_x, y_pos)
	e.w = s[4]; e.h = s[5]
	e.hp = s[0]; e.max_hp = s[0]
	e.spd = s[1]; e.score = s[2]
	e.fire_cd = randf_range(0.0, s[3])
	e.fire_rate = s[3]; e.col = s[6]
	e.phase = randf_range(0, TAU) + phase_offset
	e.boss_attack = 0; e.hit_flash = 0.0; e.fire_flash = 0.0
	_setup_enemy_lane(e, lane_x)
	e.lane_band *= band_scale
	e.pos.x = clampf(lane_x + randf_range(-e.lane_band * 0.3, e.lane_band * 0.3), e.w / 2.0, VW - e.w / 2.0)
	_enemies.append(e)


func _spawn_lane_column(tier: int, lane_x: float, count: int, y_start: float, y_gap: float, phase_seed: float = 0.0, band_scale: float = 1.0) -> void:
	for i in count:
		_spawn_enemy_from_tier(tier, lane_x, y_start - float(i) * y_gap, phase_seed + float(i) * 0.35, band_scale)


func _lane_pick(lanes: Array[float], idx: int) -> float:
	var count := lanes.size()
	if count == 0:
		return VW * 0.5
	return lanes[posmod(idx, count)]


func _spawn_wave_composition(wave_no: int, lanes: Array[float], count: int, base_tier: int) -> void:
	var center_idx := lanes.size() / 2
	var left_idx := center_idx - 1
	var right_idx := center_idx + 1
	var pattern := posmod(wave_no - 1, 5)

	match pattern:
		0:
			_spawn_lane_column(base_tier, _lane_pick(lanes, center_idx), maxi(count / 2, 3), -40.0, 60.0, 0.0, 0.65)
			_spawn_lane_column(0, _lane_pick(lanes, left_idx), maxi(count / 4, 2), -180.0, 85.0, 0.8, 0.9)
			_spawn_lane_column(0, _lane_pick(lanes, right_idx), maxi(count / 4, 2), -220.0, 85.0, 1.3, 0.9)
		1:
			_spawn_lane_column(base_tier, _lane_pick(lanes, left_idx), maxi(count / 3, 2), -80.0, 72.0, 0.0, 0.7)
			_spawn_lane_column(base_tier, _lane_pick(lanes, right_idx), maxi(count / 3, 2), -140.0, 72.0, 0.5, 0.7)
			_spawn_lane_column(0, _lane_pick(lanes, center_idx), maxi(count - (maxi(count / 3, 2) * 2), 2), -260.0, 90.0, 1.0, 0.95)
		2:
			for i in count:
				var lane_x := _lane_pick(lanes, center_idx + ((i % 3) - 1))
				var tier := base_tier if i % 4 != 3 else 0
				_spawn_enemy_from_tier(tier, lane_x, -40.0 - float(i) * 58.0, float(i) * 0.22, 0.75)
		3:
			var hammer_tier := 2 if wave_no >= 6 else base_tier
			_spawn_lane_column(hammer_tier, _lane_pick(lanes, center_idx), maxi(count / 3, 2), -50.0, 96.0, 0.0, 0.45)
			_spawn_lane_column(base_tier, _lane_pick(lanes, left_idx), maxi(count / 3, 2), -170.0, 78.0, 0.7, 0.8)
			_spawn_lane_column(base_tier, _lane_pick(lanes, right_idx), maxi(count / 3, 2), -250.0, 78.0, 1.2, 0.8)
		_:
			_spawn_lane_column(base_tier, _lane_pick(lanes, center_idx), maxi(count / 3, 2), -40.0, 68.0, 0.1, 0.68)
			_spawn_lane_column(base_tier, _lane_pick(lanes, left_idx), maxi(count / 3, 2), -120.0, 74.0, 0.6, 0.78)
			_spawn_lane_column(base_tier, _lane_pick(lanes, right_idx), maxi(count / 3, 2), -200.0, 74.0, 1.1, 0.78)
			if wave_no >= 5:
				_spawn_enemy_from_tier(2 if wave_no >= 7 else base_tier, _lane_pick(lanes, center_idx), -340.0, 1.7, 0.42)


func _trigger_wave() -> void:
	_wave_number += 1
	var count := mini(_wave_number * 2 + 3, 15)
	var tier := 0 if _wave_number < 3 else 1
	var lanes := _get_safe_lane_centers()

	# Boss every 3 waves
	if _wave_number % 3 == 0 and _boss == null:
		_spawn_boss()
		_boss_warning = 3.0

	_spawn_wave_composition(_wave_number, lanes, count, tier)

	# Wave ring effect
	_make_ring(Vector2(VW / 2.0, 0), Color(0.8, 0.2, 1.0))
	for lane_x in lanes:
		_make_ring(Vector2(lane_x, 40.0), Color(0.18, 0.72, 1.0))


func _move_enemy(e: EnemyData, dt: float) -> void:
	e.phase += dt
	e.pos.y += e.spd * dt

	match int(e.max_hp):
		1:
			var target_x := e.lane_x + sin(e.phase * 2.8 + e.pos.y * 0.02) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 2.8 * dt
		3:
			var target_x := e.lane_x + sin(e.phase * 1.8 + e.pos.y * 0.01) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 2.2 * dt
		_:
			var target_x := e.lane_x + sin(e.phase * 0.7) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 1.8 * dt

	e.pos.x = clampf(e.pos.x, e.w / 2.0, VW - e.w / 2.0)


func _player_shoot() -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var ty := _player.position.y - 6
	_player_fire_flash = maxf(_player_fire_flash, minf(0.52 + float(_wpn_level) * 0.08, 1.15))

	match _wpn_level:
		1:
			_add_bullet(Vector2(cx, ty), Vector2.UP * BULLET_SPEED, Color(0.3, 0.8, 1.0), 1, false)
		2:
			_add_bullet(Vector2(cx - 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.3, 0.85, 1.0), 1, false)
			_add_bullet(Vector2(cx + 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.3, 0.85, 1.0), 1, false)
		3:
			_add_bullet(Vector2(cx, ty), Vector2.UP * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
			_add_bullet(Vector2(cx - 8, ty + 2), Vector2(-0.025, -1.0).normalized() * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
			_add_bullet(Vector2(cx + 8, ty + 2), Vector2(0.025, -1.0).normalized() * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
		4:
			_add_bullet(Vector2(cx - 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.4, 0.95, 1.0), 1, false)
			_add_bullet(Vector2(cx + 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.4, 0.95, 1.0), 1, false)
			_add_bullet(Vector2(cx - 12, ty + 6), Vector2(-0.033, -1.0).normalized() * BULLET_SPEED, Color(0.9, 0.6, 1.0), 1, false)
			_add_bullet(Vector2(cx + 12, ty + 6), Vector2(0.033, -1.0).normalized() * BULLET_SPEED, Color(0.9, 0.6, 1.0), 1, false)
		_:
			for i in range(-2, 3):
				var angle := -PI / 2 + i * (PI / 10.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_bullet(Vector2(cx + i * 5, ty), dir * BULLET_SPEED, Color(1.0, 0.8, 0.4), 1, true)


func _add_bullet(pos: Vector2, vel: Vector2, col: Color, dmg: int, trail: bool) -> void:
	var b := Bullet.new()
	b.pos = pos; b.vel = vel; b.col = col; b.dmg = dmg; b.trail = trail
	_pbullets.append(b)


# --- Homing missiles ---
func _fire_player_missile() -> void:
	if _missiles <= 0 or _missile_cd > 0.0 or _missile_pool.size() >= MAX_MISSILES:
		return
	_missiles -= 1
	_missile_cd = MISSILE_COOLDOWN
	var m := HomingMissile.new()
	m.pos = _player.get_center()
	m.angle = -PI / 2
	m.speed = MISSILE_SPEED
	m.dmg = MISSILE_DMG
	m.life = MISSILE_LIFE
	_missile_pool.append(m)


func _update_missiles(dt: float) -> void:
	for m in _missile_pool:
		var nearest := _find_nearest_enemy(m.pos)
		if nearest != Vector2.INF:
			var desired := atan2(nearest.y - m.pos.y, nearest.x - m.pos.x)
			var diff := desired - m.angle
			while diff < -PI:
				diff += TAU
			while diff > PI:
				diff -= TAU
			m.angle += clampf(diff, -MISSILE_TURN_RATE * dt, MISSILE_TURN_RATE * dt)
		m.speed += 100.0 * dt
		m.pos += Vector2.from_angle(m.angle) * m.speed * dt
		m.life -= dt
		# Smoke trail
		if randf() < 0.6:
			m.smoke.append(m.pos)
			if m.smoke.size() > 10:
				m.smoke.remove_at(0)


func _find_nearest_enemy(pos: Vector2) -> Vector2:
	var min_dist := INF
	var target := Vector2.INF
	for e in _enemies:
		var d := pos.distance_squared_to(e.pos)
		if d < min_dist:
			min_dist = d
			target = e.pos
	return target


func _collide_missiles_vs_enemies() -> void:
	for mi in range(_missile_pool.size() - 1, -1, -1):
		var m := _missile_pool[mi]
		for ei in range(_enemies.size() - 1, -1, -1):
			var e := _enemies[ei]
			var mr := Rect2(m.pos.x - 4, m.pos.y - 4, 8, 8)
			var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
			if mr.intersects(er):
				e.hp -= m.dmg
				e.hit_flash = 0.6
				_make_explosion(e.pos, Color(1.0, 0.5, 0.1), 25)
				_make_ring(e.pos, Color(1.0, 0.4, 0.2))
				_make_text_popup(e.pos, str(m.dmg), Color(1.0, 0.5, 0.2))
				if e.hp <= 0:
					_add_combo_score(e.score, e.pos)
					_make_explosion(e.pos, e.col, e.w)
					_make_ring(e.pos, e.col * Color(1, 1, 1, 0.6))
					_drop_pickup(e.pos, e.max_hp)
					_enemies.remove_at(ei)
				_missile_pool.remove_at(mi)
				_shake = 0.15
				break



func _upgrade_weapon() -> void:
	if _wpn_level < MAX_WPN_LEVEL:
		_wpn_level += 1
		_fire_rate = FIRE_BASE * pow(0.85, _wpn_level - 1)
		_weapon_up_flash = 1.0
		# Ring effect at player
		_make_ring(_player.get_center(), Color(0.4, 1.0, 0.8))


func _spawn_enemy_bullet(e: EnemyData) -> void:
	e.fire_flash = maxf(e.fire_flash, 0.72 if e.max_hp <= 1 else 0.92 if e.max_hp <= 3 else 1.12)
	match int(e.max_hp):
		1, 3:
			_add_enemy_bullet_at(e.pos + Vector2(0, e.h / 2.0 + 4), Vector2.DOWN * E_BULLET_SPEED)
		_:
			_e_boss_attack(e)


func _add_enemy_bullet_at(pos: Vector2, vel: Vector2) -> void:
	var b := EnemyBullet.new()
	b.pos = pos; b.vel = vel
	_ebullets.append(b)


# --- Boss ---
func _spawn_boss() -> void:
	var b := BossData.new()
	b.pos = Vector2(VW / 2.0, -100)
	b.scale = 1.0 + float(_wave_number) * 0.1
	b.max_hp = 200 + _wave_number * 50
	b.hp = b.max_hp
	b.fire_rate = maxf(0.3, 0.8 - float(_wave_number) * 0.05)
	b.pattern = 0
	b.pattern_timer = 3.0
	b.phase_level = 1
	b.phase_transition = 1.0
	_boss = b
	_boss_phase_banner = 2.4
	_make_ring(Vector2(VW / 2.0, 56.0), Color(1.0, 0.28, 0.48))
	_make_ring(Vector2(VW / 2.0, 84.0), Color(0.24, 0.78, 1.0))


func _boss_phase_for_ratio(ratio: float) -> int:
	if ratio > 0.66:
		return 1
	if ratio > 0.33:
		return 2
	return 3


func _enter_boss_phase(b: BossData, new_phase: int) -> void:
	b.phase_level = new_phase
	b.phase_transition = 1.15
	b.pattern = posmod(new_phase - 1, 4)
	b.pattern_timer = 2.0
	b.fire_rate = maxf(0.16, 0.62 - float(new_phase) * 0.1 - float(_wave_number) * 0.03)
	_boss_phase_banner = 2.1
	_shake = maxf(_shake, 0.45 + float(new_phase) * 0.08)
	_make_ring(b.pos, Color(1.0, 0.3, 0.5))
	_make_ring(b.pos, Color(0.3, 0.8, 1.0))
	for lane_x in _get_safe_lane_centers():
		_make_ring(Vector2(lane_x, 72.0), Color(0.2, 0.75, 1.0))
	if new_phase == 2:
		var lanes := _get_safe_lane_centers()
		_spawn_lane_column(1, _lane_pick(lanes, 0), 2, -80.0, 84.0, 0.2, 0.72)
		_spawn_lane_column(1, _lane_pick(lanes, 2), 2, -120.0, 84.0, 0.7, 0.72)
	elif new_phase == 3:
		var lanes := _get_safe_lane_centers()
		_spawn_lane_column(2, _lane_pick(lanes, 1), 1, -80.0, 90.0, 0.1, 0.4)
		_spawn_lane_column(0, _lane_pick(lanes, 0), 2, -150.0, 72.0, 0.4, 0.95)
		_spawn_lane_column(0, _lane_pick(lanes, 2), 2, -210.0, 72.0, 0.8, 0.95)


func _update_boss(dt: float) -> void:
	var b := _boss
	if b.entering:
		b.pos.y += 80.0 * dt
		if b.pos.y >= 100:
			b.entering = false
		return

	b.phase += dt
	b.phase_transition = maxf(b.phase_transition - dt, 0.0)
	var desired_phase := _boss_phase_for_ratio(float(b.hp) / float(maxi(b.max_hp, 1)))
	if desired_phase > b.phase_level:
		_enter_boss_phase(b, desired_phase)
	b.pattern_timer -= dt
	if b.pattern_timer <= 0.0:
		b.pattern = (b.pattern + 1) % 4
		b.pattern_timer = (4.8 - float(b.phase_level) * 0.8) + randf_range(-0.8, 0.8)
		b.fire_rate = maxf(0.16, 0.68 - float(_wave_number) * 0.03 - float(b.phase_level) * 0.08)

	# Horizontal movement
	var move_amp := VW * (0.18 + float(b.phase_level) * 0.06)
	var target_x := VW / 2.0 + sin(b.phase * (0.45 + float(b.phase_level) * 0.14)) * move_amp
	b.pos.x += (target_x - b.pos.x) * (1.5 + float(b.phase_level) * 0.45) * dt
	b.hit_flash = maxf(b.hit_flash - dt * 4.0, 0.0)

	# Fire
	b.fire_cd -= dt
	if b.fire_cd <= 0.0 and b.phase_transition <= 0.0:
		_boss_attack(b)
		b.fire_cd = b.fire_rate


func _collide_bullets_vs_boss() -> void:
	if _boss == null or _boss.entering:
		return
	for bi in range(_pbullets.size() - 1, -1, -1):
		if bi >= _pbullets.size(): break
		var b := _pbullets[bi]
		var bs := _boss.scale
		var br := Rect2(b.pos.x - 3, b.pos.y - 6, 6, 12)
		var boss_rect := Rect2(_boss.pos.x - _boss.w / 2.0 * bs, _boss.pos.y - _boss.h / 2.0 * bs, _boss.w * bs, _boss.h * bs)
		if br.intersects(boss_rect):
			_pbullets.remove_at(bi)
			_boss.hp -= b.dmg
			_boss.hit_flash = 0.5
			_make_hit_spark(b.pos, b.col, 1.8)
			if _boss.hp <= 0:
				_kill_boss()
			return


func _collide_missiles_vs_boss() -> void:
	if _boss == null or _boss.entering:
		return
	for mi in range(_missile_pool.size() - 1, -1, -1):
		var m := _missile_pool[mi]
		var bs := _boss.scale
		var mr := Rect2(m.pos.x - 4, m.pos.y - 4, 8, 8)
		var boss_rect := Rect2(_boss.pos.x - _boss.w / 2.0 * bs, _boss.pos.y - _boss.h / 2.0 * bs, _boss.w * bs, _boss.h * bs)
		if mr.intersects(boss_rect):
			_boss.hp -= m.dmg
			_boss.hit_flash = 0.6
			_make_explosion(m.pos, Color(1.0, 0.5, 0.1), 25)
			_make_text_popup(m.pos, str(m.dmg), Color(1.0, 0.5, 0.2))
			_missile_pool.remove_at(mi)
			_shake = 0.15
			if _boss.hp <= 0:
				_kill_boss()
			return


func _kill_boss() -> void:
	_score += 10000
	_make_explosion(_boss.pos, _boss.col, 80)
	_make_explosion(_boss.pos, Color(1.0, 0.8, 0.3), 120)
	_make_ring(_boss.pos, Color(1.0, 0.3, 0.5), 136.0, 4.0, 0.18, 0.0)
	_make_ring(_boss.pos, Color(1.0, 0.8, 0.2), 188.0, 4.6, 0.24, randf_range(-6.0, 6.0))
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + randf_range(-0.18, 0.18)
		var offset := Vector2(cos(angle), sin(angle)) * randf_range(28.0, 68.0)
		_make_explosion(_boss.pos + offset, _boss.col.lightened(0.18), randf_range(26.0, 46.0))
	_boss = null
	_shake = 1.0


func _boss_attack(b: BossData) -> void:
	var cx := b.pos.x
	var cy := b.pos.y + b.h / 2.0 * b.scale
	var phase_boost := b.phase_level - 1
	_boss_fire_flash = maxf(_boss_fire_flash, minf(0.72 + float(phase_boost) * 0.16, 1.15))

	match b.pattern:
		0: # Spread rain
			for i in range(-5 - phase_boost, 6 + phase_boost):
				var angle := PI / 2 + float(i) * (PI / (7.0 + float(phase_boost)))
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		1: # Aimed burst
			var target := _player.get_center() if _player_alive else Vector2(cx, VH)
			var dir := (target - Vector2(cx, cy)).normalized()
			var burst_count := 5 + phase_boost * 2
			for j in range(burst_count):
				var spread := dir.rotated(float(j - burst_count / 2) * 0.12)
				_add_enemy_bullet_at(Vector2(cx, cy) + spread * 8, spread * E_BULLET_SPEED)
		2: # Spiral
			for j in 4 + phase_boost * 2:
				var angle := b.phase * (2.0 + float(phase_boost) * 0.45) + float(j) * (TAU / float(4 + phase_boost * 2))
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		_: # Ring burst
			var ring_count := 8 + phase_boost * 2
			for i in ring_count:
				var angle := TAU * float(i) / float(ring_count) + b.phase * 0.5
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)

	if b.phase_level >= 3:
		for side in [-1.0, 1.0]:
			var side_dir := Vector2(side * 0.38, 1.0).normalized()
			_add_enemy_bullet_at(Vector2(cx + side * 24.0, cy - 4.0), side_dir * E_BULLET_SPEED)


func _e_boss_attack(e: EnemyData) -> void:
	var cx := e.pos.x
	var cy := e.pos.y + e.h / 2.0 + 4

	match e.boss_attack:
		BossAttack.STRAIGHT:
			_add_enemy_bullet_at(Vector2(cx, cy), Vector2.DOWN * E_BULLET_SPEED)
		BossAttack.SPREAD:
			for i in range(-2, 3):
				var angle := PI / 2 + i * (PI / 8.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		BossAttack.BURST:
			for j in range(3):
				var target := _player.get_center() if _player_alive else Vector2(cx, VH)
				var dir := (target - Vector2(cx, cy)).normalized()
				var spread := dir.rotated(float(j - 1) * 0.2)
				_add_enemy_bullet_at(Vector2(cx, cy) + spread * 10, spread * E_BULLET_SPEED)

	e.boss_attack = (e.boss_attack + 1) % 3


func _drop_pickup(pos: Vector2, enemy_max_hp: int) -> void:
	if _wpn_level >= MAX_WPN_LEVEL and randf() < 0.5:
		_do_drop_pickup(pos, PickupType.HEAL)
		return

	var ptype := _pick_type_for_enemy(enemy_max_hp)
	if ptype >= 0:
		_do_drop_pickup(pos, ptype)


func _do_drop_pickup(pos: Vector2, ptype: int) -> void:
	var pu := Pickup.new()
	pu.pos = pos; pu.life = PICKUP_LIFE; pu.bob = 0.0; pu.rot = 0.0; pu.type = ptype
	_pickups.append(pu)


func _pick_type_for_enemy(ehp: int) -> int:
	var chance := 0.0
	if ehp <= 1: chance = 0.08
	elif ehp <= 3: chance = 0.25
	elif ehp <= 5: chance = 0.4
	else: chance = 1.0

	if randf() > chance:
		return -1

	var r := randf()
	if r < 0.50: return PickupType.WEAPON
	elif r < 0.72: return PickupType.HEAL
	elif r < 0.88: return PickupType.SHIELD
	elif r < 0.96: return PickupType.BOMB
	else: return PickupType.MISSILE


func _collect_pickups() -> void:
	for i in range(_pickups.size() - 1, -1, -1):
		var p := _pickups[i]
		var pr := Rect2(p.pos.x - 8, p.pos.y - 8 + sin(p.bob) * 3, 16, 16)
		if _player.intersects(pr):
			_store_pickup(p.type)
			_pickups.remove_at(i)


func _store_pickup(ptype: int) -> void:
	# Weapon and heal auto-apply
	match ptype:
		PickupType.WEAPON:
			_upgrade_weapon()
			return
		PickupType.HEAL:
			_hp = mini(_hp + 5, MAX_HP)
			return
	if _stored_pickups.size() >= MAX_PICKUP_STORE:
		return
	_stored_pickups.push_back(ptype)
	var tfx := TextFX.new()
	tfx.pos = _player.get_center()
	tfx.text = "+" + _pickup_name(ptype)
	tfx.life = 0.8
	tfx.max_life = 0.8
	tfx.vel = Vector2.UP * 60.0
	tfx.col = Color(1.0, 0.9, 0.45, 1.0)
	_text_fx.append(tfx)


func _pickup_name(t: int) -> String:
	match t:
		PickupType.WEAPON: return "武器"
		PickupType.HEAL: return "HP"
		PickupType.SHIELD: return "盾"
		PickupType.BOMB: return "炸弹"
		PickupType.MISSILE: return "导弹"
	return "?"


func _release_stored(ptype: int) -> void:
	if not _running or _paused or not _player_alive:
		return
	var idx := _stored_pickups.find(ptype)
	if idx == -1:
		return
	var found := _stored_pickups[idx]
	match found:
		PickupType.HEAL: _hp = mini(_hp + 5, MAX_HP)
		PickupType.MISSILE: _missiles += 3
		PickupType.BOMB: _activate_bomb()
		PickupType.SHIELD:
			_has_shield = true
			_shield_flash = 1.0
	_stored_pickups.remove_at(idx)
	_make_ring(_player.get_center(), Color(1.0, 0.8, 0.3))
	_make_text_popup(_player.get_center(), _pickup_name(found), Color(1.0, 0.8, 0.3))


func _apply_pickup_immediate(ptype: int) -> void:
	match ptype:
		PickupType.WEAPON: _upgrade_weapon()
		PickupType.HEAL: _hp = mini(_hp + 2, MAX_HP)
		PickupType.SHIELD:
			_has_shield = true
			_shield_flash = 1.0
		PickupType.BOMB: _activate_bomb()
		PickupType.MISSILE: _missiles += 3


func _activate_bomb() -> void:
	for e in _enemies:
		_make_explosion(e.pos, e.col, e.w)
		_score += e.score
	_enemies.clear(); _ebullets.clear()
	_shake = 1.0
	var ex := Explosion.new()
	ex.pos = Vector2(VW / 2.0, VH / 2.0)
	ex.radius = 10.0
	ex.max_radius = maxf(VW, VH)
	ex.col = Color(1.0, 1.0, 1.0)
	_explosions.push_front(ex)
	_make_ring(Vector2(VW / 2.0, VH / 2.0), Color(1.0, 0.5, 0.2))


func _do_spawn() -> void:
	var r := randf()
	var tier := 0
	if _elapsed > 60.0 and r > 0.95: tier = 2
	elif _elapsed > 30.0 and r > 0.7: tier = 1

	var lanes := _get_safe_lane_centers()
	var lane_order := [1, 0, 2, 1, 2, 0]
	var lane_x := _lane_pick(lanes, lane_order[_ambient_lane_step % lane_order.size()])
	_ambient_lane_step += 1
	_spawn_enemy_from_tier(tier, lane_x, -_ENEMY_STATS[tier][5] - randf_range(0.0, 30.0), _elapsed * 0.04, 0.72 if tier > 0 else 0.9)

	if _elapsed > 42.0 and randf() < 0.18:
		var escort_lane := _lane_pick(lanes, lane_order[_ambient_lane_step % lane_order.size()])
		_spawn_enemy_from_tier(0, escort_lane, -40.0 - randf_range(0.0, 45.0), _elapsed * 0.05 + 0.7, 0.95)


func _collide_pbullets_vs_enemies() -> void:
	if _pbullets.is_empty() or _enemies.is_empty():
		return
	var dead_enemies: Array[int] = []
	var dead_enemy_map := {}
	var lanes := _get_safe_lane_centers()
	var enemy_buckets := _build_enemy_lane_buckets(lanes)

	for bi in range(_pbullets.size() - 1, -1, -1):
		if bi >= _pbullets.size():
			break
		var b := _pbullets[bi]
		var br := Rect2(b.pos.x - 3, b.pos.y - 6, 6, 12)
		var lane_idx := _enemy_lane_index_for_x(b.pos.x, lanes)
		var lane_from := maxi(lane_idx - 1, 0)
		var lane_to := mini(lane_idx + 1, enemy_buckets.size() - 1)
		var bullet_hit := false
		for bucket_idx in range(lane_from, lane_to + 1):
			var candidate_bucket := enemy_buckets[bucket_idx] as PackedInt32Array
			for ei in candidate_bucket:
				if dead_enemy_map.has(ei):
					continue
				var e := _enemies[ei]
				if absf(e.pos.x - b.pos.x) > e.w * 0.5 + 10.0:
					continue
				if absf(e.pos.y - b.pos.y) > e.h * 0.5 + 14.0:
					continue
				var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
				if not br.intersects(er):
					continue
				_pbullets.remove_at(bi)
				e.hp -= b.dmg
				e.hit_flash = 0.4
				_make_hit_spark(b.pos, b.col)
				if e.hp <= 0 and not dead_enemy_map.has(ei):
					dead_enemy_map[ei] = true
					dead_enemies.append(ei)
					_add_combo_score(e.score, e.pos)
					_make_explosion(e.pos, e.col, e.w)
					_make_ring(e.pos, e.col * Color(1, 1, 1, 0.6))
					_drop_pickup(e.pos, e.max_hp)
				bullet_hit = true
				break
			if bullet_hit:
				break

	dead_enemies.sort()
	for i in range(dead_enemies.size() - 1, -1, -1):
		_enemies.remove_at(dead_enemies[i])


func _make_hit_spark(pos: Vector2, col: Color, intensity: float = 1.0) -> void:
	var available := maxi(MAX_ACTIVE_SPARKS - _sparks.size(), 0)
	if available <= 0:
		return
	var spark_count := mini(maxi(3, int(round(3.0 * intensity))), available)
	for i in spark_count:
		var s := Spark.new()
		s.pos = pos
		var angle := randf_range(0, TAU)
		var sp := randf_range(50, 150) * lerpf(0.9, 1.6, clampf(intensity - 1.0, 0.0, 1.0))
		s.vel = Vector2(cos(angle), sin(angle)) * sp
		s.life = randf_range(0.1, 0.25) * lerpf(1.0, 1.4, clampf(intensity - 1.0, 0.0, 1.0))
		s.max_life = s.life
		s.col = col
		s.size = randf_range(0.9, 1.7) * intensity
		_sparks.append(s)


func _make_ring(pos: Vector2, col: Color, max_radius: float = 50.0, line_width: float = 2.0, height: float = 0.08, tilt: float = 0.0) -> void:
	if _ring_fx.size() >= MAX_ACTIVE_RING_FX:
		_ring_fx.remove_at(0)
	var rfx := RingFX.new()
	rfx.pos = pos
	rfx.radius = 5.0
	rfx.max_radius = max_radius
	rfx.col = col
	rfx.line_width = line_width
	rfx.height = height
	rfx.tilt = tilt
	rfx.spin = randf_range(-0.9, 0.9)
	_ring_fx.append(rfx)


func _add_combo_score(base_score: int, pos: Vector2) -> void:
	if _combo_timer > 0.0:
		_combo = mini(_combo + 1, MAX_COMBO)
	else:
		_combo = 1
	_combo_timer = COMBO_WINDOW
	_combo_display_timer = 1.5

	var multiplier := maxi(_combo, 1)
	var gained := base_score * multiplier
	_score += gained

	var tfx := TextFX.new()
	tfx.pos = pos
	tfx.text = str(gained)
	if multiplier > 1:
		tfx.text += " x" + str(multiplier)
	tfx.life = 1.0; tfx.max_life = 1.0
	tfx.vel = Vector2.UP * 60.0
	tfx.col = Color(1.0, 0.92, 0.45, 1.0)
	_text_fx.append(tfx)


func _collide_ebullets_vs_player() -> void:
	if not _player_alive or _invincible > 0.0:
		return
	for i in range(_ebullets.size() - 1, -1, -1):
		var dot := Rect2(_ebullets[i].pos.x - 3, _ebullets[i].pos.y - 3, 6, 6)
		if _player.intersects(dot):
			_ebullets.remove_at(i)
			_player_hit()
			if not _player_alive:
				return


func _collide_enemies_vs_player() -> void:
	if not _player_alive or _invincible > 0.0:
		return
	for i in range(_enemies.size() - 1, -1, -1):
		var e := _enemies[i]
		var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
		if _player.intersects(er):
			_enemies.remove_at(i)
			_add_combo_score(e.score, e.pos)
			_make_explosion(e.pos, e.col, e.w)
			_player_hit()
			if not _player_alive:
				return


func _player_hit() -> void:
	if _has_shield:
		_has_shield = false
		_shield_flash = 1.0
		_shake = 0.2
		return
	_invincible = INVINCIBLE_TIME
	_hp -= 1
	_shake = 0.4
	if _hp <= 0:
		_player_alive = false
		_running = false
		_ui_over.visible = true
		_game_over_elapsed = 0.01
		if _score > _high_score:
			_high_score = _score
		_ui_game_over_score.text = "SCORE  " + str(_score)
		_ui_game_over_high.text = "HI-SCORE  " + str(_high_score)
		_make_explosion(_player.get_center(), Color(0.2, 0.7, 1.0), 40)
		_make_ring(_player.get_center(), Color(0.2, 0.7, 1.0))


func _pause() -> void:
	_paused = true

func _unpause() -> void:
	_paused = false

func _ui_update() -> void:
	_ui_score.text = "SCORE  " + str(_score)
	_ui_hp.text = "HP  " + str(_hp) + " / " + str(MAX_HP)
	if _ui_missiles:
		var cd_txt := "" if _missile_cd <= 0.0 else " (" + str(snapped(_missile_cd, 0.1)) + "s)"
		_ui_missiles.text = "MISSILE  " + str(_missiles) + cd_txt
	if _ui_wpn:
		var stars = ""
		for _i in _wpn_level:
			stars += "★"
		_ui_wpn.text = "WPN  " + str(_wpn_level) + " " + stars
	if _ui_shield:
		_ui_shield.text = "[盾]" if _has_shield else ""
	if _ui_wave:
		var next_wave := maxi(int(ceil(maxf(WAVE_INTERVAL - _wave_timer, 0.0))), 0)
		_ui_wave.text = "BOSS P" + str(_boss.phase_level) + "  " + str(_boss.hp) + " / " + str(_boss.max_hp) if _boss != null else "WAVE  " + str(maxi(_wave_number, 1)) + "  NEXT " + str(next_wave) + "s"
	if _ui_store:
		var counts := {"盾": 0, "炸弹": 0, "导弹": 0}
		for p in _stored_pickups:
			match p:
				PickupType.SHIELD: counts["盾"] += 1
				PickupType.BOMB: counts["炸弹"] += 1
				PickupType.MISSILE: counts["导弹"] += 1
		_ui_store.text = "自动拾取: 武器 / HP   Q导弹:" + str(counts["导弹"]) + "   R炸弹:" + str(counts["炸弹"]) + "   T护盾:" + str(counts["盾"])


func _make_explosion(pos: Vector2, col: Color, size: float) -> void:
	if _explosions.size() >= MAX_ACTIVE_EXPLOSIONS:
		_explosions.remove_at(0)
	var ex := Explosion.new()
	ex.pos = pos; ex.radius = 4.0
	ex.max_radius = size * 2.5
	ex.col = col
	ex.lift = clampf(size * 0.008, 0.08, 0.85)
	ex.flash = clampf(size / 72.0, 0.18, 1.35)
	ex.spin = randf_range(-1.4, 1.4)
	_explosions.append(ex)

	var available := maxi(MAX_ACTIVE_SPARKS - _sparks.size(), 0)
	var spark_count := mini(8 + int(size / 5), available)
	for i in spark_count:
		var s := Spark.new()
		s.pos = pos
		var angle := TAU * float(i) / spark_count + randf_range(-0.3, 0.3)
		var sp := randf_range(80, 300)
		s.vel = Vector2(cos(angle), sin(angle)) * sp
		s.life = randf_range(0.2, 0.6)
		s.max_life = s.life
		s.col = col
		s.size = randf_range(1.2, 2.6) * clampf(size / 38.0, 0.8, 2.0)
		_sparks.append(s)
	if size >= 24.0:
		_make_ring(pos, col.lightened(0.18), size * 1.45, 2.4, 0.12, randf_range(-18.0, 18.0))
	if size >= 56.0:
		_make_ring(pos, Color(1.0, 0.82, 0.36), size * 1.92, 3.2, 0.18, randf_range(-10.0, 10.0))


func _draw() -> void:
	var offset := _get_shake_offset()
	if not _use_3d:
		_draw_background(offset)
		_draw_grid(offset)

		if _player_alive:
			_draw_player(offset)
			_draw_wingmen(offset)

		for b in _pbullets:
			_draw_bullet(b, offset)

		# Bullet trails
		for b in _pbullets:
			if b.trail:
				draw_circle(b.pos + offset - b.vel.normalized() * 8, 3.0, Color(b.col, 0.1))

		for e in _enemies:
			_draw_enemy(e, offset)

		if _boss != null:
			_draw_boss(offset)

		for eb in _ebullets:
			_draw_enemy_bullet(eb.pos, offset)

		# Homing missiles
		for m in _missile_pool:
			_draw_missile(m, offset)

	if not _use_3d:
		# Explosion rings
		for ex in _explosions:
			var ratio := ex.radius / ex.max_radius
			var alpha := 1.0 - ratio
			draw_circle(ex.pos + offset, ex.radius, ex.col * Color(1, 1, 1, alpha * 0.6))
			draw_arc(ex.pos + offset, ex.radius, 0, TAU, 16, Color(1, 1, 1, alpha * 0.8), 1.5)

		for s in _sparks:
			var ratio := s.life / s.max_life
			draw_circle(s.pos + offset, (2.0 * ratio + 1.0) * maxf(s.size * 0.5, 0.85), s.col * Color(1, 1, 1, ratio))

	if _use_3d:
		for b in _pbullets:
			if b.visual == null or not is_instance_valid(b.visual) or not b.visual.visible:
				_draw_bullet(b, offset)
				if b.trail:
					draw_circle(b.pos + offset - b.vel.normalized() * 8.0, 3.0, Color(b.col, 0.1))
		for eb in _ebullets:
			if eb.visual == null or not is_instance_valid(eb.visual) or not eb.visual.visible:
				_draw_enemy_bullet(eb.pos, offset)
		for ex in _explosions:
			var ratio := ex.radius / ex.max_radius
			var alpha := pow(maxf(1.0 - ratio, 0.0), 1.35) * (0.2 + ex.flash * 0.22)
			var glow_pos := _project_world_to_screen(ex.pos, 1.12 + ex.lift * 0.5)
			if glow_pos != Vector2.INF:
				draw_circle(glow_pos, lerpf(18.0, ex.max_radius * 0.34, ratio), ex.col * Color(1, 1, 1, alpha * 0.18))
				draw_circle(glow_pos, lerpf(10.0, ex.max_radius * 0.18, ratio), Color(1.0, 0.96, 0.82, alpha * 0.14))
		if _player_alive and _player_fire_flash > 0.02:
			var player_flash_pos := _project_world_to_screen(_player.get_center() + Vector2(0.0, -20.0), 1.5)
			if player_flash_pos != Vector2.INF:
				draw_circle(player_flash_pos, 8.0 + _player_fire_flash * 10.0, Color(0.56, 0.94, 1.0, 0.12 + _player_fire_flash * 0.18))
				draw_circle(player_flash_pos, 3.0 + _player_fire_flash * 4.0, Color(1.0, 0.98, 0.84, 0.2 + _player_fire_flash * 0.3))
		for wm in _wingmen:
			if wm.fire_flash <= 0.02:
				continue
			var wingman_flash_pos := _project_world_to_screen(_player.get_center() + wm.offset + Vector2(0.0, -10.0), 1.18)
			if wingman_flash_pos != Vector2.INF:
				draw_circle(wingman_flash_pos, 4.0 + wm.fire_flash * 5.0, Color(0.32, 1.0, 0.78, 0.12 + wm.fire_flash * 0.2))
		for e in _enemies:
			if e.fire_flash <= 0.02:
				continue
			var enemy_flash_pos := _project_world_to_screen(e.pos + Vector2(0.0, -e.h * 0.2), 1.0 + float(e.max_hp) * 0.02)
			if enemy_flash_pos != Vector2.INF:
				var enemy_glow := 4.0 + e.fire_flash * (4.0 if e.max_hp <= 1 else 6.0 if e.max_hp <= 3 else 9.0)
				draw_circle(enemy_flash_pos, enemy_glow, e.col.lightened(0.38) * Color(1, 1, 1, 0.12 + e.fire_flash * 0.14))
				draw_circle(enemy_flash_pos, enemy_glow * 0.45, Color(1.0, 0.92, 0.82, 0.14 + e.fire_flash * 0.18))
		if _boss != null and _boss_fire_flash > 0.02:
			var boss_flash_pos := _project_world_to_screen(_boss.pos + Vector2(0.0, -20.0), 2.2)
			if boss_flash_pos != Vector2.INF:
				draw_circle(boss_flash_pos, 14.0 + _boss_fire_flash * 18.0, Color(1.0, 0.44, 0.62, 0.08 + _boss_fire_flash * 0.14))
				draw_circle(boss_flash_pos, 8.0 + _boss_fire_flash * 8.0, Color(1.0, 0.94, 0.86, 0.1 + _boss_fire_flash * 0.16))

	if not _use_3d:
		for p in _pickups:
			_draw_pickup(p, offset)

	for tfx in _text_fx:
		var alpha := tfx.life / tfx.max_life
		var draw_pos := tfx.pos + offset
		if _use_3d:
			draw_pos = _project_world_to_screen(tfx.pos, 1.6)
			if draw_pos == Vector2.INF:
				continue
		draw_string(
			ThemeDB.fallback_font, draw_pos,
			tfx.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16,
			tfx.col * Color(1, 1, 1, alpha)
		)

	if not _use_3d:
		# Ring FX
		for rfx in _ring_fx:
			var ratio := rfx.radius / rfx.max_radius
			var alpha := 1.0 - ratio
			draw_arc(rfx.pos + offset, rfx.radius, 0, TAU, 24,
				rfx.col * Color(1, 1, 1, alpha), rfx.line_width * alpha)
	elif _use_3d:
		for rfx in _ring_fx:
			var ratio := rfx.radius / rfx.max_radius
			var alpha := pow(maxf(1.0 - ratio, 0.0), 1.25)
			var ring_pos := _project_world_to_screen(rfx.pos, 0.3 + rfx.height)
			if ring_pos != Vector2.INF:
				draw_arc(ring_pos, rfx.radius * 0.34, 0, TAU, 32, rfx.col * Color(1, 1, 1, alpha * 0.12), maxf(rfx.line_width * 0.45, 1.0))

	_draw_hud_chrome()
	_draw_boundary_warning()

	# Combo display
	if _combo > 1 and _combo_display_timer > 0.0:
		var combo_alpha := minf(_combo_display_timer * 2.0, 1.0)
		var combo_text := str(_combo) + "x COMBO!"
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 40, 92), combo_text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1.0, 0.9, 0.3, combo_alpha))

		# Combo timer bar
		if _combo_bar > 0.0:
			var bar_w := 140.0
			var bar_x := VW / 2.0 - bar_w / 2.0
			var bar_y := 118.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, 3), Color(0.2, 0.2, 0.2, 0.5))
			draw_rect(Rect2(bar_x, bar_y, bar_w * _combo_bar, 3),
				Color(1.0, 0.9, 0.3, combo_alpha))

	# Wave warning
	if _wave_warning > 0.0:
		var alpha := sin(_wave_warning * 8.0) * 0.5 + 0.5
		draw_rect(Rect2(0.0, VH / 2.0 - 28.0, VW, 56.0), Color(0.3, 0.04, 0.08, alpha * 0.18))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 70, VH / 2.0),
			"WAVE " + str(_wave_number) + " INCOMING!",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 22,
			Color(1.0, 0.3, 0.3, alpha))

	if _boss_warning > 0.0:
		var boss_alpha := sin(_boss_warning * 10.0) * 0.35 + 0.65
		draw_rect(Rect2(0.0, VH / 2.0 - 40.0, VW, 80.0), Color(0.45, 0.02, 0.08, boss_alpha * 0.2))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 140.0, VH / 2.0 + 6.0),
			"WARNING // BOSS APPROACHING",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 26,
			Color(1.0, 0.45, 0.45, boss_alpha))

	if _boss != null and _boss_phase_banner > 0.0:
		var phase_alpha := minf(_boss_phase_banner * 0.7, 1.0)
		draw_rect(Rect2(0.0, 140.0, VW, 54.0), Color(0.32, 0.04, 0.1, phase_alpha * 0.22))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 112.0, 176.0),
			"PHASE " + str(_boss.phase_level) + " // " + _boss_phase_title(_boss.phase_level),
			HORIZONTAL_ALIGNMENT_CENTER, -1, 24,
			Color(1.0, 0.55, 0.68, phase_alpha)
		)

	# Weapon upgrade flash
	if _weapon_up_flash > 0.0:
		var alpha := _weapon_up_flash * 0.15
		draw_rect(Rect2(Vector2.ZERO, Vector2(VW, VH)), Color(0.3, 1.0, 0.8, alpha))

	# Paused overlay
	if _paused:
		draw_rect(Rect2(Vector2.ZERO, Vector2(VW, VH)), Color(0, 0, 0, 0.5))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 40, VH / 2.0 - 20),
			"已暂停",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 32,
			Color(0.3, 0.8, 1.0, 0.9))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 80, VH / 2.0 + 30),
			"按 ESC 继续",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 18,
			Color(0.7, 0.7, 0.7, 0.8))


func _draw_boundary_warning() -> void:
	var view_t := _camera_view_norm()
	var base_alpha := lerpf(0.035, 0.1, view_t) + _edge_warning * lerpf(0.12, 0.28, view_t)
	var pulse := 0.65 + 0.35 * sin(_elapsed * lerpf(5.0, 9.5, view_t))
	var edge_alpha := base_alpha * pulse

	var safe_left := 0.0
	var safe_right := float(VW)
	if _use_3d:
		safe_left = PLAYER_SAFE_MARGIN_X_3D
		safe_right = VW - PLAYER_SAFE_MARGIN_X_3D

	draw_rect(Rect2(0.0, 0.0, safe_left, VH), Color(0.04, 0.09, 0.16, edge_alpha * lerpf(0.28, 0.62, view_t)))
	draw_rect(Rect2(safe_right, 0.0, VW - safe_right, VH), Color(0.04, 0.09, 0.16, edge_alpha * lerpf(0.28, 0.62, view_t)))

	draw_rect(Rect2(safe_left - 3.0, 0.0, 3.0, VH), Color(0.12, 0.45, 0.9, edge_alpha * lerpf(0.75, 1.1, view_t)))
	draw_rect(Rect2(safe_right, 0.0, 3.0, VH), Color(0.12, 0.45, 0.9, edge_alpha * lerpf(0.75, 1.1, view_t)))

	for i in range(10):
		var y := 120.0 + float(i) * 92.0
		var seg_alpha := edge_alpha * (0.65 + 0.35 * sin(_elapsed * 6.0 + float(i)))
		draw_rect(Rect2(safe_left - 8.0, y, 8.0, 36.0), Color(0.32, 0.85, 1.0, seg_alpha * lerpf(0.55, 1.0, view_t)))
		draw_rect(Rect2(safe_right + 3.0, y, 8.0, 36.0), Color(0.32, 0.85, 1.0, seg_alpha * lerpf(0.55, 1.0, view_t)))

	if _use_3d:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 52.0, VH - 18.0),
			"安全航道",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
			Color(0.4, 0.86, 1.0, lerpf(0.18, 0.36, view_t) + edge_alpha * lerpf(0.25, 0.55, view_t))
		)

	if _edge_warning > 0.08:
		var warn_alpha := _edge_warning * pulse
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 44.0, VH - 34.0),
			"边界警示",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16,
			Color(0.45, 0.9, 1.0, warn_alpha)
		)


func _get_shake_offset() -> Vector2:
	if _shake <= 0.0: return Vector2.ZERO
	return Vector2(
		randf_range(-1.0, 1.0) * _shake * _shake_intensity,
		randf_range(-1.0, 1.0) * _shake * _shake_intensity
	)


func _setup_3d_world() -> void:
	if _world_root != null and is_instance_valid(_world_root):
		return

	_world_root = Node3D.new()
	_world_root.name = "World3D"
	add_child(_world_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.008, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.24, 0.42)
	env.ambient_light_energy = 0.72

	var env_node := WorldEnvironment.new()
	env_node.environment = env
	_world_root.add_child(env_node)

	_camera_3d = Camera3D.new()
	_camera_3d.name = "Camera3D"
	_camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera_3d.fov = 37.0
	_camera_3d.position = Vector3(0.0, 58.0, 58.0)
	_world_root.add_child(_camera_3d)
	_camera_3d.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
	_camera_3d.current = true
	get_viewport().msaa_3d = Viewport.MSAA_4X

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.7
	sun.light_color = Color(0.82, 0.9, 1.0)
	sun.rotation_degrees = Vector3(-44.0, -18.0, 0.0)
	_world_root.add_child(sun)

	var rim := DirectionalLight3D.new()
	rim.light_energy = 1.1
	rim.light_color = Color(0.2, 0.6, 1.0)
	rim.rotation_degrees = Vector3(-22.0, 148.0, 0.0)
	_world_root.add_child(rim)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 12.0, 16.0)
	fill.omni_range = 80.0
	fill.light_energy = 0.52
	fill.light_color = Color(0.12, 0.34, 0.78)
	_world_root.add_child(fill)

	_setup_space_backdrop_3d()

	_ground_root_3d = Node3D.new()
	_ground_root_3d.name = "Ground3D"
	_world_root.add_child(_ground_root_3d)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(GROUND_HALF_WIDTH * 2.0, 0.25, GROUND_HALF_LENGTH * 2.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.82, 0.0)
	floor.material_override = _make_space_material(Color(0.02, 0.06, 0.1, 0.24), Color(0.0, 0.2, 0.34), 0.18, 1.4)
	_ground_root_3d.add_child(floor)

	var border_material := _make_space_material(Color(0.05, 0.14, 0.2, 0.4), Color(0.0, 0.58, 0.95), 0.1, 2.2)
	for side in [-1.0, 1.0]:
		var border := MeshInstance3D.new()
		var border_mesh := BoxMesh.new()
		border_mesh.size = Vector3(1.1, 0.08, GROUND_HALF_LENGTH * 2.0)
		border.mesh = border_mesh
		border.position = Vector3(side * (WORLD_HALF_WIDTH + 0.2), -0.58, 0.0)
		border.material_override = border_material
		_ground_root_3d.add_child(border)

		for beacon_z in [-96.0, -72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0, 96.0]:
			var beacon := _make_box_part(Vector3(0.18, 1.8, 0.18), Color(0.06, 0.16, 0.22), Color(0.0, 0.24, 0.36), 0.06, 0.34)
			beacon.position = Vector3(side * (WORLD_HALF_WIDTH - 0.9), 0.0, beacon_z)
			_ground_root_3d.add_child(beacon)

			var beacon_cap := _make_sphere_part(0.18, Color(0.32, 0.88, 1.0), Color(0.0, 0.72, 1.0), 0.0, 0.04)
			beacon_cap.position = Vector3(side * (WORLD_HALF_WIDTH - 0.9), 0.95, beacon_z)
			_ground_root_3d.add_child(beacon_cap)

	_ground_lines_3d.clear()
	for i in range(42):
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(GROUND_HALF_WIDTH - 8.0, 0.03, 0.35)
		strip.mesh = strip_mesh
		strip.position = Vector3(0.0, -0.56, float(i) * 6.0 - GROUND_HALF_LENGTH)
		strip.material_override = _make_space_material(Color(0.06, 0.18, 0.28, 0.22), Color(0.0, 0.42, 0.7), 0.08, 1.2)
		_ground_root_3d.add_child(strip)
		_ground_lines_3d.append(strip)

	_ground_center_markers_3d.clear()
	for i in range(24):
		var center_marker := MeshInstance3D.new()
		var center_mesh := BoxMesh.new()
		center_mesh.size = Vector3(1.2, 0.04, 2.2)
		center_marker.mesh = center_mesh
		center_marker.position = Vector3(0.0, -0.54, float(i) * 10.0 - GROUND_HALF_LENGTH)
		center_marker.material_override = _make_space_material(Color(0.46, 0.88, 1.0, 0.46), Color(0.2, 0.74, 1.0), 0.04, 2.0)
		_ground_root_3d.add_child(center_marker)
		_ground_center_markers_3d.append(center_marker)

	var safe_left_world := _to_world(Vector2(PLAYER_SAFE_MARGIN_X_3D, VH * 0.5), -0.52).x
	var safe_right_world := _to_world(Vector2(VW - PLAYER_SAFE_MARGIN_X_3D, VH * 0.5), -0.52).x
	_ground_safe_guides_3d.clear()
	for x_pos in [safe_left_world, safe_right_world]:
		var guide := MeshInstance3D.new()
		var guide_mesh := BoxMesh.new()
		guide_mesh.size = Vector3(0.55, 0.04, GROUND_HALF_LENGTH * 2.0)
		guide.mesh = guide_mesh
		guide.position = Vector3(x_pos, -0.52, 0.0)
		guide.material_override = _make_space_material(Color(0.16, 0.7, 1.0, 0.24), Color(0.0, 0.72, 1.0), 0.02, 1.8)
		_ground_root_3d.add_child(guide)
		_ground_safe_guides_3d.append(guide)

	_entity_root_3d = Node3D.new()
	_entity_root_3d.name = "Entities3D"
	_world_root.add_child(_entity_root_3d)

	_player_root_3d = Node3D.new()
	_player_root_3d.name = "Player3D"
	_entity_root_3d.add_child(_player_root_3d)

	_wingmen_root_3d = Node3D.new()
	_wingmen_root_3d.name = "Wingmen3D"
	_entity_root_3d.add_child(_wingmen_root_3d)

	_bullets_root_3d = Node3D.new()
	_bullets_root_3d.name = "PlayerBullets3D"
	_entity_root_3d.add_child(_bullets_root_3d)

	_enemy_bullets_root_3d = Node3D.new()
	_enemy_bullets_root_3d.name = "EnemyBullets3D"
	_entity_root_3d.add_child(_enemy_bullets_root_3d)

	_enemies_root_3d = Node3D.new()
	_enemies_root_3d.name = "Enemies3D"
	_entity_root_3d.add_child(_enemies_root_3d)

	_pickups_root_3d = Node3D.new()
	_pickups_root_3d.name = "Pickups3D"
	_entity_root_3d.add_child(_pickups_root_3d)

	_fx_root_3d = Node3D.new()
	_fx_root_3d.name = "FX3D"
	_entity_root_3d.add_child(_fx_root_3d)

	_missiles_root_3d = Node3D.new()
	_missiles_root_3d.name = "Missiles3D"
	_entity_root_3d.add_child(_missiles_root_3d)

	_boss_root_3d = Node3D.new()
	_boss_root_3d.name = "Boss3D"
	_entity_root_3d.add_child(_boss_root_3d)

	_clear_3d_dynamic_visuals()
	_camera_focus_ready = false
	_sync_3d_world(0.0)


func _clear_children(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	for child in node.get_children():
		child.queue_free()


func _clear_3d_dynamic_visuals() -> void:
	for root in [_player_root_3d, _wingmen_root_3d, _bullets_root_3d, _enemy_bullets_root_3d, _enemies_root_3d, _pickups_root_3d, _fx_root_3d, _missiles_root_3d, _boss_root_3d]:
		_clear_children(root)
	_player_visual_3d = null
	_shield_visual_3d = null
	_camera_focus_ready = false
	_backdrop_sync_accum = BACKDROP_SYNC_INTERVAL_3D


func _to_world(pos: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((pos.x - VW * 0.5) * WORLD_SCALE, height, (pos.y - VH * 0.5) * WORLD_SCALE)


func _project_world_to_screen(pos: Vector2, height: float = 1.0) -> Vector2:
	if _camera_3d == null or not is_instance_valid(_camera_3d):
		return Vector2.INF
	var world_pos := _to_world(pos, height)
	if _camera_3d.is_position_behind(world_pos):
		return Vector2.INF
	return _camera_3d.unproject_position(world_pos)


func _prune_container(root: Node3D, active_ids: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	for child in root.get_children():
		var entity_id := str(child.get_meta("entity_id", ""))
		if entity_id == "" or not active_ids.has(entity_id):
			child.queue_free()


func _is_visual_target_in_bounds(pos: Vector2, margin_x: float = VISUAL_MARGIN_X_3D, margin_y: float = VISUAL_MARGIN_Y_3D) -> bool:
	return pos.x >= -margin_x and pos.x <= VW + margin_x and pos.y >= -margin_y and pos.y <= VH + margin_y


func _spark_visual_budget() -> int:
	var pressure := _enemies.size() + _ebullets.size() + _pbullets.size()
	if pressure >= 72:
		return 22
	if pressure >= 48:
		return 34
	return MAX_ACTIVE_SPARK_VISUALS_3D


func _explosion_visual_budget() -> int:
	var pressure := _enemies.size() + _ebullets.size() + int(_sparks.size() * 0.08)
	if pressure >= 72:
		return 6
	if pressure >= 48:
		return 9
	return MAX_ACTIVE_EXPLOSION_VISUALS_3D


func _ring_visual_budget() -> int:
	var pressure := _enemies.size() + _ebullets.size() + int(_sparks.size() * 0.08)
	if pressure >= 72:
		return 8
	if pressure >= 48:
		return 10
	return MAX_ACTIVE_RING_VISUALS_3D


func _player_bullet_visual_budget() -> int:
	var pressure := _pbullets.size() + int(_ebullets.size() * 0.45) + int(_enemies.size() * 1.2)
	if pressure >= 180:
		return 44
	if pressure >= 120:
		return 58
	return MAX_ACTIVE_PLAYER_BULLET_VISUALS_3D


func _enemy_bullet_visual_budget() -> int:
	var pressure := _ebullets.size() + int(_pbullets.size() * 0.3) + int(_enemies.size() * 0.8)
	if pressure >= 220:
		return 60
	if pressure >= 140:
		return 78
	return MAX_ACTIVE_ENEMY_BULLET_VISUALS_3D


func _enemy_sensor_glow_budget() -> int:
	var pressure := _enemies.size() * 2 + int(_ebullets.size() * 0.6) + int(_sparks.size() * 0.08)
	if pressure >= 68:
		return 8
	if pressure >= 42:
		return 14
	return MAX_ACTIVE_ENEMY_SENSOR_GLOWS_3D


func _mesh_cache_key(kind: String, values: Array) -> String:
	var parts := PackedStringArray([kind])
	for value in values:
		parts.append("%.3f" % float(value))
	return ":".join(parts)


func _enemy_lane_index_for_x(x_pos: float, lanes: Array[float]) -> int:
	var best_idx := 0
	var best_dist := INF
	for i in range(lanes.size()):
		var dist := absf(lanes[i] - x_pos)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	return best_idx


func _build_enemy_lane_buckets(lanes: Array[float]) -> Array:
	var buckets: Array = []
	for _i in range(lanes.size()):
		buckets.append(PackedInt32Array())
	for ei in range(_enemies.size()):
		var lane_idx := _enemy_lane_index_for_x(_enemies[ei].pos.x, lanes)
		var bucket := buckets[lane_idx] as PackedInt32Array
		bucket.append(ei)
		buckets[lane_idx] = bucket
	return buckets


func _compact_player_bullets() -> void:
	var write := 0
	for read in range(_pbullets.size()):
		var b := _pbullets[read]
		var p := b.pos
		if p.y <= -30.0 or p.y >= VH + 30.0 or p.x <= -30.0 or p.x >= VW + 30.0:
			continue
		if write != read:
			_pbullets[write] = b
		write += 1
	if write != _pbullets.size():
		_pbullets.resize(write)


func _compact_enemy_bullets() -> void:
	var write := 0
	for read in range(_ebullets.size()):
		var b := _ebullets[read]
		if b.pos.y >= VH + 30.0:
			continue
		if write != read:
			_ebullets[write] = b
		write += 1
	if write != _ebullets.size():
		_ebullets.resize(write)


func _sphere_segments_for_radius(radius: float) -> Vector2i:
	if radius <= 0.12:
		return Vector2i(8, 4)
	if radius <= 0.5:
		return Vector2i(12, 6)
	if radius <= 4.0:
		return Vector2i(16, 10)
	if radius <= 18.0:
		return Vector2i(20, 12)
	return Vector2i(24, 16)


func _capsule_segments_for_radius(radius: float) -> Vector2i:
	if radius <= 0.08:
		return Vector2i(8, 2)
	if radius <= 0.2:
		return Vector2i(10, 3)
	if radius <= 0.6:
		return Vector2i(12, 4)
	return Vector2i(16, 5)


func _cylinder_radial_segments_for_radius(radius: float) -> int:
	if radius <= 0.08:
		return 8
	if radius <= 0.2:
		return 10
	if radius <= 0.8:
		return 12
	return 16


func _get_box_mesh(size: Vector3) -> BoxMesh:
	var key := _mesh_cache_key("box", [size.x, size.y, size.z])
	if _primitive_mesh_cache.has(key):
		return _primitive_mesh_cache[key] as BoxMesh
	var mesh := BoxMesh.new()
	mesh.size = size
	_primitive_mesh_cache[key] = mesh
	return mesh


func _get_sphere_mesh(radius: float) -> SphereMesh:
	var segs := _sphere_segments_for_radius(radius)
	var key := _mesh_cache_key("sphere", [radius, segs.x, segs.y])
	if _primitive_mesh_cache.has(key):
		return _primitive_mesh_cache[key] as SphereMesh
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segs.x
	mesh.rings = segs.y
	_primitive_mesh_cache[key] = mesh
	return mesh


func _get_cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var radial_segments := _cylinder_radial_segments_for_radius(radius)
	var key := _mesh_cache_key("cylinder", [radius, height, radial_segments])
	if _primitive_mesh_cache.has(key):
		return _primitive_mesh_cache[key] as CylinderMesh
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	_primitive_mesh_cache[key] = mesh
	return mesh


func _get_capsule_mesh(radius: float, height: float) -> CapsuleMesh:
	var segs := _capsule_segments_for_radius(radius)
	var key := _mesh_cache_key("capsule", [radius, height, segs.x, segs.y])
	if _primitive_mesh_cache.has(key):
		return _primitive_mesh_cache[key] as CapsuleMesh
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = segs.x
	mesh.rings = segs.y
	_primitive_mesh_cache[key] = mesh
	return mesh


func _make_material(albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.35) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = emission != Color.BLACK
	material.emission = emission
	material.emission_energy_multiplier = 1.2
	if albedo.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = false
	return material


func _material_cache_key(albedo: Color, emission: Color, metallic: float, roughness: float) -> String:
	return "mat:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f" % [
		albedo.r, albedo.g, albedo.b, albedo.a,
		emission.r, emission.g, emission.b, emission.a,
		metallic, roughness
	]


func _get_part_material(albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.35) -> StandardMaterial3D:
	var key := _material_cache_key(albedo, emission, metallic, roughness)
	if _part_material_cache.has(key):
		return _part_material_cache[key] as StandardMaterial3D
	var material := _make_material(albedo, emission, metallic, roughness)
	_part_material_cache[key] = material
	return material


func _make_space_material(albedo: Color, emission: Color = Color.BLACK, roughness: float = 0.18, emission_energy: float = 1.6) -> StandardMaterial3D:
	var material := _make_material(albedo, emission, 0.0, roughness)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_energy_multiplier = emission_energy
	return material


func _get_detail_material(key: String, albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.35) -> StandardMaterial3D:
	if _detail_material_cache.has(key):
		return _detail_material_cache[key]
	var material := _make_material(albedo, emission, metallic, roughness)
	_detail_material_cache[key] = material
	return material


func _attach_detail_part(parent: Node3D, part: Node3D, position: Vector3, rotation_degrees: Vector3 = Vector3.ZERO) -> Node3D:
	part.position = position
	part.rotation_degrees = rotation_degrees
	parent.add_child(part)
	return part


func _ensure_effect_part(parent: Node3D, name: String, part: Node3D, position: Vector3, rotation_degrees: Vector3 = Vector3.ZERO) -> Node3D:
	var existing := parent.get_node_or_null(name)
	if existing != null and existing is Node3D:
		return existing
	part.name = name
	part.position = position
	part.rotation_degrees = rotation_degrees
	parent.add_child(part)
	return part


func _ensure_effect_sphere(parent: Node3D, name: String, radius: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.28, position: Vector3 = Vector3.ZERO, rotation_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var existing := parent.get_node_or_null(name)
	if existing != null and existing is MeshInstance3D:
		return existing
	var part := _make_sphere_part(radius, color, emission, metallic, roughness)
	part.name = name
	part.position = position
	part.rotation_degrees = rotation_degrees
	parent.add_child(part)
	return part


func _make_box_part(size: Vector3, color: Color, emission: Color = Color.BLACK, metallic: float = 0.22, roughness: float = 0.32) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = _get_box_mesh(size)
	part.material_override = _get_part_material(color, emission, metallic, roughness)
	return part


func _make_sphere_part(radius: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.28) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = _get_sphere_mesh(radius)
	part.material_override = _get_part_material(color, emission, metallic, roughness)
	return part


func _make_cylinder_part(radius: float, height: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.25, roughness: float = 0.3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = _get_cylinder_mesh(radius, height)
	part.material_override = _get_part_material(color, emission, metallic, roughness)
	return part


func _make_capsule_part(radius: float, height: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.2, roughness: float = 0.25) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = _get_capsule_mesh(radius, height)
	part.material_override = _get_part_material(color, emission, metallic, roughness)
	return part


func _instantiate_model_scene(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene = _model_scene_cache.get(path)
	if scene == null:
		var loaded = load(path)
		if loaded is PackedScene:
			scene = loaded
			_model_scene_cache[path] = scene
	if scene is PackedScene:
		var instance = scene.instantiate()
		if instance is Node3D:
			return instance
	return null


func _decorate_player_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_player", false)):
		return
	root.set_meta("decorated_player", true)
	var accent := _get_detail_material("detail_player_accent", Color(0.24, 0.56, 0.82), Color(0.08, 0.42, 0.68), 0.06, 0.16)
	var trim := _get_detail_material("detail_player_trim", Color(0.72, 0.94, 1.0), Color(0.2, 0.78, 1.0), 0.02, 0.08)
	var dark := _get_detail_material("detail_player_dark", Color(0.08, 0.16, 0.24), Color(0.0, 0.1, 0.18), 0.22, 0.3)
	_attach_detail_part(root, _make_box_part(Vector3(0.16, 0.1, 1.18), accent.albedo_color, accent.emission, 0.08, 0.18), Vector3(0.0, 0.44, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.06, 0.05, 1.1), trim.albedo_color, trim.emission, 0.0, 0.08), Vector3(0.0, 0.28, 0.08))
	_attach_detail_part(root, _make_capsule_part(0.06, 1.34, accent.albedo_color, accent.emission, 0.04, 0.16), Vector3(0.0, 0.33, -0.06), Vector3(90.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.1, 0.16, 0.42), dark.albedo_color, dark.emission, 0.18, 0.26), Vector3(0.0, 0.08, 0.74))
	_attach_detail_part(root, _make_capsule_part(0.1, 0.42, trim.albedo_color, trim.emission, 0.0, 0.08), Vector3(0.0, 0.34, -1.08), Vector3(18.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.08, 0.28), dark.albedo_color, dark.emission, 0.18, 0.26), Vector3(0.0, 0.06, -0.88), Vector3(16.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.14, 0.08, 0.22), accent.albedo_color, accent.emission, 0.04, 0.14), Vector3(0.0, 0.46, -0.5))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.26, 0.03, 0.22), trim.albedo_color, trim.emission, 0.0, 0.08), Vector3(side * 0.36, 0.15, -0.88), Vector3(0.0, 0.0, side * 26.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.34, 0.04, 0.34), accent.albedo_color, accent.emission, 0.06, 0.14), Vector3(side * 1.28, 0.08, 0.18), Vector3(0.0, 0.0, side * 28.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.18, 0.26), dark.albedo_color, dark.emission, 0.18, 0.26), Vector3(side * 0.34, 0.48, 1.06), Vector3(0.0, 0.0, side * 10.0))
		_attach_detail_part(root, _make_capsule_part(0.04, 0.58, trim.albedo_color, trim.emission, 0.0, 0.08), Vector3(side * 0.5, 0.18, -1.06), Vector3(18.0, 0.0, side * 16.0))
		_attach_detail_part(root, _make_capsule_part(0.07, 0.44, dark.albedo_color, dark.emission, 0.16, 0.24), Vector3(side * 0.56, 0.04, 0.92), Vector3(90.0, 0.0, 0.0))
		_attach_detail_part(root, _make_capsule_part(0.06, 0.56, accent.albedo_color, accent.emission, 0.04, 0.14), Vector3(side * 1.52, 0.08, 0.04), Vector3(0.0, 0.0, side * 84.0))
		_attach_detail_part(root, _make_sphere_part(0.06, trim.albedo_color, trim.emission, 0.0, 0.04), Vector3(side * 0.24, 0.03, 1.42))
		_attach_detail_part(root, _make_sphere_part(0.045, trim.albedo_color, trim.emission, 0.0, 0.03), Vector3(side * 1.66, 0.08, -0.12))
		_attach_detail_part(root, _make_box_part(Vector3(0.22, 0.08, 0.44), dark.albedo_color, dark.emission, 0.18, 0.26), Vector3(side * 0.92, 0.06, -0.22), Vector3(0.0, 0.0, side * 22.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.14, 0.14, 0.24), accent.albedo_color, accent.emission, 0.04, 0.12), Vector3(side * 0.78, 0.16, 0.6), Vector3(0.0, 0.0, side * 12.0))
		_attach_detail_part(root, _make_sphere_part(0.05, dark.albedo_color, dark.emission, 0.12, 0.24), Vector3(side * 0.3, 0.05, -1.28))


func _decorate_wingman_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_wingman", false)):
		return
	root.set_meta("decorated_wingman", true)
	var accent := _get_detail_material("detail_wingman_accent", Color(0.22, 0.74, 0.8), Color(0.08, 0.52, 0.6), 0.04, 0.12)
	var trim := _get_detail_material("detail_wingman_trim", Color(0.68, 0.96, 1.0), Color(0.15, 0.78, 0.62), 0.0, 0.06)
	var dark := _get_detail_material("detail_wingman_dark", Color(0.08, 0.16, 0.22), Color(0.02, 0.1, 0.16), 0.18, 0.26)
	_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.12, 0.34), accent.albedo_color, accent.emission, 0.02, 0.1), Vector3(0.0, 0.3, 0.18))
	_attach_detail_part(root, _make_capsule_part(0.04, 0.48, accent.albedo_color, accent.emission, 0.02, 0.1), Vector3(0.0, 0.22, 0.02), Vector3(90.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.12, 0.08, 0.16), dark.albedo_color, dark.emission, 0.16, 0.24), Vector3(0.0, 0.06, 0.24))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.16, 0.02, 0.14), accent.albedo_color, accent.emission, 0.0, 0.08), Vector3(side * 0.42, 0.07, 0.08), Vector3(0.0, 0.0, side * 24.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.03, 0.16), trim.albedo_color, trim.emission, 0.0, 0.06), Vector3(side * 0.24, 0.1, -0.18), Vector3(10.0, 0.0, side * 10.0))
		_attach_detail_part(root, _make_capsule_part(0.05, 0.26, dark.albedo_color, dark.emission, 0.12, 0.24), Vector3(side * 0.2, 0.04, 0.3), Vector3(90.0, 0.0, 0.0))
		_attach_detail_part(root, _make_sphere_part(0.035, trim.albedo_color, trim.emission, 0.0, 0.03), Vector3(side * 0.46, 0.08, -0.04))
		_attach_detail_part(root, _make_capsule_part(0.03, 0.2, accent.albedo_color, accent.emission, 0.02, 0.1), Vector3(side * 0.34, 0.08, -0.26), Vector3(18.0, 0.0, side * 16.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.09, 0.07, 0.18), dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(side * 0.12, 0.08, -0.08), Vector3(0.0, 0.0, side * 10.0))


func _decorate_enemy_light_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_enemy_light", false)):
		return
	root.set_meta("decorated_enemy_light", true)
	var red := _get_detail_material("detail_enemy_light_red", Color(0.7, 0.16, 0.18), Color(0.32, 0.04, 0.03), 0.1, 0.22)
	var glow := _get_detail_material("detail_enemy_light_glow", Color(1.0, 0.8, 0.3), Color(1.0, 0.42, 0.08), 0.0, 0.04)
	var dark := _get_detail_material("detail_enemy_light_dark", Color(0.14, 0.06, 0.08), Color(0.08, 0.02, 0.02), 0.18, 0.28)
	_attach_detail_part(root, _make_box_part(Vector3(0.1, 0.06, 0.22), red.albedo_color, red.emission, 0.1, 0.22), Vector3(0.0, 0.12, -0.46), Vector3(16.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.14, 0.28), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(0.0, 0.18, 0.06))
	_attach_detail_part(root, _make_capsule_part(0.05, 0.34, dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(0.0, 0.12, -0.08), Vector3(90.0, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.2, 0.02, 0.12), red.albedo_color, red.emission, 0.06, 0.18), Vector3(side * 0.5, 0.05, 0.12), Vector3(0.0, 0.0, side * 24.0))
		_attach_detail_part(root, _make_capsule_part(0.04, 0.22, red.albedo_color, red.emission, 0.06, 0.18), Vector3(side * 0.44, 0.06, -0.16), Vector3(14.0, 0.0, side * 34.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.08, 0.2), dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(side * 0.16, 0.08, 0.42), Vector3(0.0, 0.0, side * 14.0))
		_attach_detail_part(root, _make_sphere_part(0.05, glow.albedo_color, glow.emission, 0.0, 0.04), Vector3(side * 0.22, 0.1, 0.42))
		_attach_detail_part(root, _make_sphere_part(0.035, red.albedo_color, red.emission, 0.0, 0.03), Vector3(side * 0.56, 0.06, -0.02))


func _decorate_enemy_mid_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_enemy_mid", false)):
		return
	root.set_meta("decorated_enemy_mid", true)
	var orange := _get_detail_material("detail_enemy_mid_orange", Color(0.76, 0.36, 0.12), Color(0.24, 0.08, 0.02), 0.08, 0.18)
	var visor := _get_detail_material("detail_enemy_mid_visor", Color(1.0, 0.78, 0.34), Color(1.0, 0.46, 0.08), 0.0, 0.05)
	var dark := _get_detail_material("detail_enemy_mid_dark", Color(0.18, 0.08, 0.04), Color(0.08, 0.03, 0.01), 0.18, 0.28)
	_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.1, 0.34), orange.albedo_color, orange.emission, 0.06, 0.16), Vector3(0.0, 0.28, 0.42))
	_attach_detail_part(root, _make_capsule_part(0.06, 0.76, orange.albedo_color, orange.emission, 0.04, 0.16), Vector3(0.0, 0.24, 0.06), Vector3(90.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.16, 0.14, 0.26), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(0.0, 0.12, -0.18))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.22, 0.03, 0.22), orange.albedo_color, orange.emission, 0.05, 0.16), Vector3(side * 0.82, 0.05, 0.12), Vector3(0.0, 0.0, side * 18.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.08, 0.04, 0.24), orange.albedo_color, orange.emission, 0.04, 0.16), Vector3(side * 0.16, 0.12, -0.64), Vector3(12.0, side * 12.0, 0.0))
		_attach_detail_part(root, _make_capsule_part(0.06, 0.34, dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(side * 0.64, 0.12, 0.5), Vector3(90.0, 0.0, 0.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.12, 0.12, 0.3), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(side * 0.28, 0.1, 0.72), Vector3(0.0, 0.0, side * 12.0))
		_attach_detail_part(root, _make_sphere_part(0.05, visor.albedo_color, visor.emission, 0.0, 0.04), Vector3(side * 0.52, 0.08, 0.76))
		_attach_detail_part(root, _make_capsule_part(0.05, 0.3, orange.albedo_color, orange.emission, 0.04, 0.14), Vector3(side * 0.94, 0.08, -0.1), Vector3(0.0, 0.0, side * 82.0))
		_attach_detail_part(root, _make_sphere_part(0.04, dark.albedo_color, dark.emission, 0.12, 0.24), Vector3(side * 0.72, 0.1, 0.24))


func _decorate_enemy_heavy_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_enemy_heavy", false)):
		return
	root.set_meta("decorated_enemy_heavy", true)
	var armor := _get_detail_material("detail_enemy_heavy_armor", Color(0.56, 0.14, 0.64), Color(0.16, 0.02, 0.28), 0.1, 0.18)
	var core := _get_detail_material("detail_enemy_heavy_core", Color(1.0, 0.78, 0.36), Color(1.0, 0.42, 0.08), 0.0, 0.04)
	var dark := _get_detail_material("detail_enemy_heavy_dark", Color(0.14, 0.06, 0.18), Color(0.05, 0.01, 0.08), 0.18, 0.26)
	_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.16, 0.42), armor.albedo_color, armor.emission, 0.08, 0.18), Vector3(0.0, 0.56, 0.44))
	_attach_detail_part(root, _make_capsule_part(0.09, 1.02, armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(0.0, 0.36, 0.18), Vector3(90.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.22, 0.4), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(0.0, 0.22, -0.4))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.22, 0.12, 0.52), armor.albedo_color, armor.emission, 0.08, 0.2), Vector3(side * 0.62, 0.18, 0.08), Vector3(0.0, 0.0, side * 16.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.1, 0.08, 0.32), armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(side * 1.12, 0.12, 0.24), Vector3(0.0, 0.0, side * 10.0))
		_attach_detail_part(root, _make_capsule_part(0.08, 0.52, dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(side * 0.98, 0.14, -0.22), Vector3(90.0, 0.0, 0.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.14, 0.46), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(side * 0.42, 0.2, 0.68), Vector3(0.0, 0.0, side * 10.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.16, 0.16, 0.52), armor.albedo_color, armor.emission, 0.08, 0.2), Vector3(side * 1.34, 0.16, -0.08), Vector3(0.0, 0.0, side * 14.0))
		_attach_detail_part(root, _make_sphere_part(0.05, armor.albedo_color, armor.emission, 0.04, 0.14), Vector3(side * 1.3, 0.2, 0.58))
	_attach_detail_part(root, _make_sphere_part(0.08, core.albedo_color, core.emission, 0.0, 0.04), Vector3(0.0, 0.28, -0.58))
	_attach_detail_part(root, _make_box_part(Vector3(0.14, 0.18, 0.32), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(0.0, 0.42, -0.18))
	_attach_detail_part(root, _make_capsule_part(0.08, 0.44, armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(0.0, 0.62, -0.02), Vector3(0.0, 0.0, 90.0))


func _decorate_boss_model(root: Node3D) -> void:
	if bool(root.get_meta("decorated_boss", false)):
		return
	root.set_meta("decorated_boss", true)
	var trim := _get_detail_material("detail_boss_trim", Color(0.76, 0.24, 0.38), Color(0.4, 0.06, 0.14), 0.06, 0.16)
	var armor := _get_detail_material("detail_boss_armor", Color(0.48, 0.12, 0.26), Color(0.2, 0.04, 0.12), 0.08, 0.18)
	var core := _get_detail_material("detail_boss_core", Color(1.0, 0.84, 0.94), Color(1.0, 0.22, 0.46), 0.0, 0.04)
	var dark := _get_detail_material("detail_boss_dark", Color(0.12, 0.04, 0.08), Color(0.06, 0.01, 0.04), 0.18, 0.28)
	_attach_detail_part(root, _make_box_part(Vector3(0.36, 0.18, 0.82), trim.albedo_color, trim.emission, 0.04, 0.16), Vector3(0.0, 1.18, -0.82))
	_attach_detail_part(root, _make_box_part(Vector3(0.18, 0.1, 0.96), armor.albedo_color, armor.emission, 0.06, 0.16), Vector3(0.0, 0.12, 1.46))
	_attach_detail_part(root, _make_capsule_part(0.16, 2.8, armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(0.0, 0.86, 0.2), Vector3(90.0, 0.0, 0.0))
	_attach_detail_part(root, _make_box_part(Vector3(0.62, 0.34, 1.18), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(0.0, 1.3, -1.1))
	_attach_detail_part(root, _make_box_part(Vector3(0.34, 0.54, 0.88), armor.albedo_color, armor.emission, 0.08, 0.18), Vector3(0.0, 1.42, -1.52))
	_attach_detail_part(root, _make_capsule_part(0.12, 1.18, trim.albedo_color, trim.emission, 0.04, 0.14), Vector3(0.0, 1.08, -2.0), Vector3(90.0, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		_attach_detail_part(root, _make_box_part(Vector3(0.42, 0.08, 1.08), armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(side * 2.46, 0.18, 0.28), Vector3(0.0, 0.0, side * 18.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.14, 0.1, 0.64), trim.albedo_color, trim.emission, 0.04, 0.14), Vector3(side * 0.58, 0.26, -2.12), Vector3(14.0, side * 10.0, 0.0))
		_attach_detail_part(root, _make_capsule_part(0.12, 0.94, dark.albedo_color, dark.emission, 0.14, 0.24), Vector3(side * 2.68, 0.26, 0.52), Vector3(90.0, 0.0, 0.0))
		_attach_detail_part(root, _make_box_part(Vector3(0.22, 0.3, 0.86), armor.albedo_color, armor.emission, 0.06, 0.18), Vector3(side * 1.32, 0.42, -1.54), Vector3(10.0, side * 12.0, 0.0))
		_attach_detail_part(root, _make_sphere_part(0.1, core.albedo_color, core.emission, 0.0, 0.04), Vector3(side * 2.46, 0.22, 3.06))
		_attach_detail_part(root, _make_sphere_part(0.08, trim.albedo_color, trim.emission, 0.0, 0.04), Vector3(side * 3.04, 0.36, 2.4))
		_attach_detail_part(root, _make_box_part(Vector3(0.3, 0.32, 1.02), dark.albedo_color, dark.emission, 0.16, 0.26), Vector3(side * 2.08, 0.36, -0.92), Vector3(8.0, side * 10.0, 0.0))
		_attach_detail_part(root, _make_capsule_part(0.08, 0.62, trim.albedo_color, trim.emission, 0.04, 0.14), Vector3(side * 3.28, 0.18, 1.46), Vector3(90.0, 0.0, 0.0))


func _make_player_model() -> Node3D:
	var asset := _instantiate_model_scene(BAKED_MODEL_PLAYER_PATH)
	if asset != null:
		_decorate_player_model(asset)
		return asset
	asset = _instantiate_model_scene(MODEL_PLAYER_PATH)
	if asset != null:
		_decorate_player_model(asset)
		return asset
	var root := Node3D.new()

	var body := _make_box_part(Vector3(0.85, 0.36, 2.6), Color(0.08, 0.14, 0.2), Color(0.0, 0.2, 0.35))
	body.position = Vector3(0.0, 0.18, 0.0)
	root.add_child(body)

	var nose := _make_box_part(Vector3(0.46, 0.24, 0.9), Color(0.22, 0.52, 0.75), Color(0.1, 0.35, 0.6), 0.1, 0.18)
	nose.position = Vector3(0.0, 0.28, -1.35)
	root.add_child(nose)

	var wing := _make_box_part(Vector3(2.25, 0.08, 1.05), Color(0.1, 0.22, 0.34), Color(0.0, 0.14, 0.22), 0.22, 0.32)
	wing.position = Vector3(0.0, 0.08, 0.18)
	root.add_child(wing)

	for side in [-1.0, 1.0]:
		var tail_fin := _make_box_part(Vector3(0.2, 0.48, 0.68), Color(0.12, 0.2, 0.3), Color(0.0, 0.16, 0.24))
		tail_fin.position = Vector3(side * 0.32, 0.4, 0.92)
		root.add_child(tail_fin)

		var engine := _make_cylinder_part(0.13, 0.55, Color(0.2, 0.24, 0.3), Color(0.0, 0.2, 0.28))
		engine.rotation_degrees.x = 90.0
		engine.position = Vector3(side * 0.28, 0.05, 0.92)
		root.add_child(engine)

	var canopy := _make_sphere_part(0.22, Color(0.45, 0.88, 1.0, 0.72), Color(0.15, 0.4, 0.7), 0.05, 0.1)
	canopy.position = Vector3(0.0, 0.32, -0.35)
	root.add_child(canopy)

	var core := _make_sphere_part(0.12, Color(0.6, 0.95, 1.0), Color(0.2, 0.8, 1.0), 0.0, 0.05)
	core.position = Vector3(0.0, 0.18, 0.2)
	root.add_child(core)

	_decorate_player_model(root)
	return root


func _make_wingman_model() -> Node3D:
	var asset := _instantiate_model_scene(BAKED_MODEL_WINGMAN_PATH)
	if asset != null:
		_decorate_wingman_model(asset)
		return asset
	asset = _instantiate_model_scene(MODEL_WINGMAN_PATH)
	if asset != null:
		_decorate_wingman_model(asset)
		return asset
	var root := Node3D.new()
	var body := _make_box_part(Vector3(0.46, 0.2, 1.0), Color(0.08, 0.2, 0.32), Color(0.0, 0.15, 0.24))
	body.position = Vector3(0.0, 0.12, 0.0)
	root.add_child(body)
	var wing := _make_box_part(Vector3(1.0, 0.05, 0.44), Color(0.14, 0.3, 0.42), Color(0.0, 0.1, 0.18))
	wing.position = Vector3(0.0, 0.06, 0.1)
	root.add_child(wing)
	var eye := _make_sphere_part(0.1, Color(0.6, 0.95, 1.0), Color(0.15, 0.8, 0.55), 0.0, 0.05)
	eye.position = Vector3(0.0, 0.18, -0.32)
	root.add_child(eye)
	_decorate_wingman_model(root)
	return root


func _make_enemy_model(enemy_hp: int) -> Node3D:
	var asset_path := MODEL_ENEMY_HEAVY_PATH
	var baked_asset_path := BAKED_MODEL_ENEMY_HEAVY_PATH
	if enemy_hp <= 1:
		asset_path = MODEL_ENEMY_LIGHT_PATH
		baked_asset_path = BAKED_MODEL_ENEMY_LIGHT_PATH
	elif enemy_hp <= 3:
		asset_path = MODEL_ENEMY_MID_PATH
		baked_asset_path = BAKED_MODEL_ENEMY_MID_PATH
	var asset := _instantiate_model_scene(baked_asset_path)
	if asset != null:
		if enemy_hp <= 1:
			_decorate_enemy_light_model(asset)
		elif enemy_hp <= 3:
			_decorate_enemy_mid_model(asset)
		else:
			_decorate_enemy_heavy_model(asset)
		return asset
	asset = _instantiate_model_scene(asset_path)
	if asset != null:
		if enemy_hp <= 1:
			_decorate_enemy_light_model(asset)
		elif enemy_hp <= 3:
			_decorate_enemy_mid_model(asset)
		else:
			_decorate_enemy_heavy_model(asset)
		return asset
	var root := Node3D.new()
	match enemy_hp:
		1:
			var body := _make_box_part(Vector3(0.62, 0.22, 1.15), Color(0.36, 0.08, 0.12), Color(0.5, 0.1, 0.08), 0.18, 0.38)
			body.position = Vector3(0.0, 0.12, 0.0)
			root.add_child(body)
			var wing := _make_box_part(Vector3(1.15, 0.04, 0.34), Color(0.55, 0.14, 0.16), Color(0.4, 0.06, 0.02), 0.16, 0.42)
			wing.position = Vector3(0.0, 0.06, 0.12)
			root.add_child(wing)
			var eye := _make_sphere_part(0.11, Color(1.0, 0.8, 0.35), Color(1.0, 0.5, 0.1), 0.0, 0.05)
			eye.position = Vector3(0.0, 0.18, -0.28)
			root.add_child(eye)
		3:
			var body_mid := _make_box_part(Vector3(0.95, 0.28, 1.75), Color(0.4, 0.18, 0.08), Color(0.45, 0.18, 0.04), 0.2, 0.34)
			body_mid.position = Vector3(0.0, 0.15, 0.0)
			root.add_child(body_mid)
			var wing_mid := _make_box_part(Vector3(1.8, 0.06, 0.75), Color(0.7, 0.26, 0.1), Color(0.5, 0.12, 0.02), 0.2, 0.4)
			wing_mid.position = Vector3(0.0, 0.06, 0.1)
			root.add_child(wing_mid)
			for side in [-1.0, 1.0]:
				var nacelle := _make_cylinder_part(0.12, 0.45, Color(0.28, 0.18, 0.12), Color(0.35, 0.15, 0.08))
				nacelle.rotation_degrees.x = 90.0
				nacelle.position = Vector3(side * 0.62, 0.1, 0.44)
				root.add_child(nacelle)
			var visor := _make_box_part(Vector3(0.34, 0.14, 0.5), Color(1.0, 0.74, 0.3), Color(1.0, 0.5, 0.12), 0.0, 0.06)
			visor.position = Vector3(0.0, 0.24, -0.52)
			root.add_child(visor)
		_:
			var hull := _make_box_part(Vector3(1.55, 0.4, 2.5), Color(0.22, 0.06, 0.3), Color(0.35, 0.08, 0.45), 0.26, 0.32)
			hull.position = Vector3(0.0, 0.22, 0.0)
			root.add_child(hull)
			var wing_heavy := _make_box_part(Vector3(2.7, 0.08, 1.35), Color(0.45, 0.08, 0.55), Color(0.25, 0.02, 0.4), 0.24, 0.36)
			wing_heavy.position = Vector3(0.0, 0.08, 0.12)
			root.add_child(wing_heavy)
			for side in [-1.0, 1.0]:
				var cannon := _make_cylinder_part(0.16, 0.75, Color(0.28, 0.12, 0.32), Color(0.25, 0.1, 0.34))
				cannon.rotation_degrees.x = 90.0
				cannon.position = Vector3(side * 0.86, 0.14, -0.22)
				root.add_child(cannon)
			var core := _make_sphere_part(0.18, Color(1.0, 0.72, 0.35), Color(1.0, 0.45, 0.12), 0.0, 0.04)
			core.position = Vector3(0.0, 0.28, -0.38)
			root.add_child(core)
	if enemy_hp <= 1:
		_decorate_enemy_light_model(root)
	elif enemy_hp <= 3:
		_decorate_enemy_mid_model(root)
	else:
		_decorate_enemy_heavy_model(root)
	return root


func _make_boss_model() -> Node3D:
	var asset := _instantiate_model_scene(BAKED_MODEL_BOSS_PATH)
	if asset != null:
		_decorate_boss_model(asset)
		return asset
	asset = _instantiate_model_scene(MODEL_BOSS_PATH)
	if asset != null:
		_decorate_boss_model(asset)
		return asset
	var root := Node3D.new()
	var hull := _make_box_part(Vector3(4.8, 0.85, 6.0), Color(0.22, 0.06, 0.16), Color(0.22, 0.02, 0.08), 0.28, 0.3)
	hull.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(hull)
	var wing := _make_box_part(Vector3(7.4, 0.12, 2.0), Color(0.36, 0.08, 0.18), Color(0.24, 0.02, 0.08), 0.3, 0.34)
	wing.position = Vector3(0.0, 0.14, 0.4)
	root.add_child(wing)
	var armor := _make_box_part(Vector3(2.0, 0.42, 2.8), Color(0.42, 0.1, 0.24), Color(0.3, 0.04, 0.14), 0.18, 0.24)
	armor.position = Vector3(0.0, 0.82, -0.4)
	root.add_child(armor)
	for side in [-1.0, 1.0]:
		var blade := _make_box_part(Vector3(1.2, 0.22, 2.3), Color(0.48, 0.08, 0.18), Color(0.24, 0.02, 0.04), 0.24, 0.3)
		blade.position = Vector3(side * 2.35, 0.18, 0.55)
		blade.rotation_degrees.z = side * 20.0
		root.add_child(blade)
		var thruster := _make_cylinder_part(0.28, 0.72, Color(0.3, 0.12, 0.16), Color(0.8, 0.18, 0.08))
		thruster.rotation_degrees.x = 90.0
		thruster.position = Vector3(side * 2.1, 0.22, 2.15)
		root.add_child(thruster)
	var canopy := _make_sphere_part(0.52, Color(0.34, 0.76, 1.0, 0.75), Color(0.25, 0.7, 1.0), 0.02, 0.08)
	canopy.position = Vector3(0.0, 0.9, -1.15)
	root.add_child(canopy)
	var core := _make_sphere_part(0.42, Color(1.0, 0.82, 0.9), Color(1.0, 0.25, 0.55), 0.0, 0.04)
	core.position = Vector3(0.0, 0.68, -0.15)
	root.add_child(core)
	_decorate_boss_model(root)
	return root


func _make_bullet_model(col: Color) -> Node3D:
	var asset := _instantiate_model_scene(MODEL_PLAYER_BULLET_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var shot := _make_capsule_part(0.08, 0.5, col, col.lightened(0.4), 0.0, 0.08)
	shot.rotation_degrees.x = 90.0
	root.add_child(shot)
	return root


func _make_enemy_bullet_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_ENEMY_BULLET_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var shot := _make_sphere_part(0.14, Color(1.0, 0.35, 0.18), Color(1.0, 0.55, 0.1), 0.0, 0.06)
	root.add_child(shot)
	return root


func _make_pickup_model(pickup_type: int) -> Node3D:
	var asset := _instantiate_model_scene(PICKUP_MODEL_PATHS.get(pickup_type, ""))
	if asset != null:
		return asset
	var root := Node3D.new()
	match pickup_type:
		PickupType.WEAPON:
			var weapon := _make_box_part(Vector3(0.45, 0.45, 0.45), Color(1.0, 0.82, 0.25), Color(1.0, 0.7, 0.18), 0.0, 0.18)
			weapon.rotation_degrees = Vector3(45.0, 0.0, 45.0)
			root.add_child(weapon)
		PickupType.HEAL:
			var h1 := _make_box_part(Vector3(0.25, 0.8, 0.25), Color(0.3, 1.0, 0.45), Color(0.15, 0.7, 0.2), 0.0, 0.1)
			var h2 := _make_box_part(Vector3(0.8, 0.25, 0.25), Color(0.3, 1.0, 0.45), Color(0.15, 0.7, 0.2), 0.0, 0.1)
			root.add_child(h1)
			root.add_child(h2)
		PickupType.SHIELD:
			var shield := _make_sphere_part(0.34, Color(0.3, 0.65, 1.0, 0.42), Color(0.2, 0.6, 1.0), 0.0, 0.08)
			root.add_child(shield)
		PickupType.BOMB:
			var bomb := _make_sphere_part(0.28, Color(1.0, 0.2, 0.2), Color(1.0, 0.3, 0.12), 0.0, 0.08)
			root.add_child(bomb)
		PickupType.MISSILE:
			var missile := _make_capsule_part(0.12, 0.5, Color(1.0, 0.55, 0.22), Color(1.0, 0.35, 0.12), 0.0, 0.08)
			missile.rotation_degrees.x = 90.0
			root.add_child(missile)
	return root


func _make_missile_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_MISSILE_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var body := _make_capsule_part(0.11, 0.65, Color(0.95, 0.58, 0.22), Color(1.0, 0.34, 0.12), 0.0, 0.08)
	body.rotation_degrees.x = 90.0
	root.add_child(body)
	for side in [-1.0, 1.0]:
		var fin := _make_box_part(Vector3(0.05, 0.18, 0.24), Color(0.95, 0.52, 0.2), Color(0.8, 0.24, 0.08), 0.0, 0.12)
		fin.position = Vector3(side * 0.12, 0.0, 0.18)
		root.add_child(fin)
	return root


func _make_explosion_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var outer := _make_sphere_part(0.42, col * Color(1, 1, 1, 0.35), col.lightened(0.2), 0.0, 0.08)
	outer.name = "Outer"
	root.add_child(outer)
	var core := _make_sphere_part(0.22, col.lightened(0.35), col.lightened(0.45), 0.0, 0.04)
	core.name = "Core"
	core.position.y = 0.06
	root.add_child(core)
	var ring := _make_cylinder_part(0.32, 0.08, col * Color(1, 1, 1, 0.3), col, 0.0, 0.08)
	ring.name = "Ring"
	ring.position.y = -0.02
	root.add_child(ring)
	var column := _make_cylinder_part(0.12, 0.95, col * Color(1, 1, 1, 0.2), col.lightened(0.3), 0.0, 0.08)
	column.name = "Column"
	column.position.y = 0.28
	root.add_child(column)
	var flash := _make_sphere_part(0.12, Color(1.0, 0.96, 0.84, 0.78), col.lightened(0.55), 0.0, 0.02)
	flash.name = "Flash"
	flash.position.y = 0.12
	root.add_child(flash)
	root.set_meta("outer_ref", outer)
	root.set_meta("core_ref", core)
	root.set_meta("ring_ref", ring)
	root.set_meta("column_ref", column)
	root.set_meta("flash_ref", flash)
	return root


func _make_ring_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var ring := _make_cylinder_part(0.45, 0.04, col * Color(1, 1, 1, 0.45), col, 0.0, 0.08)
	ring.name = "Primary"
	root.add_child(ring)
	var secondary := _make_cylinder_part(0.34, 0.02, col * Color(1, 1, 1, 0.18), col.lightened(0.28), 0.0, 0.08)
	secondary.name = "Secondary"
	secondary.position.y = 0.05
	root.add_child(secondary)
	root.set_meta("primary_ref", ring)
	root.set_meta("secondary_ref", secondary)
	return root


func _make_spark_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var core := _make_capsule_part(0.05, 0.42, col.lightened(0.25), col.lightened(0.4), 0.0, 0.05)
	core.name = "Core"
	core.rotation_degrees.x = 90.0
	root.add_child(core)
	return root


func _sync_ground_3d() -> void:
	for i in _ground_lines_3d.size():
		var strip := _ground_lines_3d[i]
		if strip == null or not is_instance_valid(strip):
			continue
		var scroll_speed := 8.0 + minf(_elapsed * 0.18, 8.0) + float(_wave_number) * 0.4
		strip.position.z = fmod(float(i) * 6.0 + _elapsed * scroll_speed, GROUND_HALF_LENGTH * 2.0) - GROUND_HALF_LENGTH
		strip.scale.x = 1.0 + sin(_elapsed * 1.8 + float(i)) * 0.06
		var strip_mat := strip.material_override as StandardMaterial3D
		if strip_mat != null:
			var strip_pulse := 0.55 + 0.45 * sin(_elapsed * 2.1 + float(i) * 0.35)
			strip_mat.albedo_color = Color(0.08, 0.22 + strip_pulse * 0.08, 0.34 + strip_pulse * 0.14, 0.18 + strip_pulse * 0.1)
			strip_mat.emission_energy_multiplier = 1.0 + strip_pulse * 1.5

	for i in _ground_center_markers_3d.size():
		var marker := _ground_center_markers_3d[i]
		if marker == null or not is_instance_valid(marker):
			continue
		var center_speed := 11.0 + minf(_elapsed * 0.22, 10.0) + float(_wave_number) * 0.55
		marker.position.z = fmod(float(i) * 10.0 + _elapsed * center_speed, GROUND_HALF_LENGTH * 2.0) - GROUND_HALF_LENGTH
		marker.scale = Vector3.ONE * (1.0 + sin(_elapsed * 2.6 + float(i) * 0.35) * 0.04)
		var marker_mat := marker.material_override as StandardMaterial3D
		if marker_mat != null:
			var marker_pulse := 0.62 + 0.38 * sin(_elapsed * 3.0 + float(i) * 0.42)
			marker_mat.albedo_color = Color(0.42 + marker_pulse * 0.12, 0.82 + marker_pulse * 0.1, 1.0, 0.3 + marker_pulse * 0.18)
			marker_mat.emission_energy_multiplier = 1.6 + marker_pulse * 1.6

	var lane_emphasis := clampf(1.0 - _camera_view_norm() + _boss_camera_intensity() * 0.55, 0.0, 1.7)
	for i in _ground_safe_guides_3d.size():
		var guide := _ground_safe_guides_3d[i]
		if guide == null or not is_instance_valid(guide):
			continue
		guide.scale.x = 1.0 + lane_emphasis * 0.12
		var guide_mat := guide.material_override as StandardMaterial3D
		if guide_mat != null:
			guide_mat.albedo_color = Color(0.14, 0.74, 1.0, 0.22 + lane_emphasis * 0.14)
			guide_mat.emission_energy_multiplier = 1.5 + lane_emphasis * 1.2


func _sync_space_backdrop_3d(delta: float) -> void:
	if _background_root_3d == null or not is_instance_valid(_background_root_3d):
		return
	_background_root_3d.position.x = lerpf(_background_root_3d.position.x, _camera_focus_3d.x * 0.14, 0.025)
	_background_root_3d.position.z = lerpf(_background_root_3d.position.z, -_camera_focus_3d.z * 0.035, 0.02)
	_backdrop_sync_accum += delta
	if _backdrop_sync_accum < BACKDROP_SYNC_INTERVAL_3D:
		return
	_backdrop_sync_accum = fmod(_backdrop_sync_accum, BACKDROP_SYNC_INTERVAL_3D)

	if _space_planet_3d != null and is_instance_valid(_space_planet_3d):
		_space_planet_3d.rotation_degrees = Vector3(0.0, fmod(_elapsed * 1.35, 360.0), 7.0)

	if _space_ring_root_3d != null and is_instance_valid(_space_ring_root_3d):
		_space_ring_root_3d.rotation_degrees = Vector3(74.0, 16.0 + sin(_elapsed * 0.12) * 5.0, -18.0 + sin(_elapsed * 0.18) * 2.5)

	for i in range(_space_ring_bands_3d.size()):
		var band := _space_ring_bands_3d[i]
		if band == null or not is_instance_valid(band):
			continue
		var band_mat := band.material_override as StandardMaterial3D
		if band_mat != null:
			var band_pulse := 0.42 + 0.58 * sin(_elapsed * 0.45 + float(i) * 0.9)
			band_mat.albedo_color = Color(0.14, 0.22 + band_pulse * 0.05, 0.42 + band_pulse * 0.12, 0.04 + band_pulse * 0.035)
			band_mat.emission_energy_multiplier = 0.8 + band_pulse * 0.9

	for debris in _space_ring_debris_3d:
		if debris == null or not is_instance_valid(debris):
			continue
		var base_pos: Vector3 = debris.get_meta("base_pos", Vector3.ZERO)
		var base_rot: Vector3 = debris.get_meta("base_rot", Vector3.ZERO)
		var phase := float(debris.get_meta("phase", 0.0))
		var spin := float(debris.get_meta("spin", 0.0))
		debris.position = Vector3(base_pos.x, base_pos.y + sin(_elapsed * 0.34 + phase) * 0.32, base_pos.z)
		debris.rotation_degrees = Vector3(
			base_rot.x + sin(_elapsed * 0.48 + phase) * 8.0,
			base_rot.y + _elapsed * spin,
			base_rot.z + cos(_elapsed * 0.4 + phase) * 10.0
		)

	for cloud in _space_clouds_3d:
		if cloud == null or not is_instance_valid(cloud):
			continue
		var base_scale: Vector3 = cloud.get_meta("base_scale", Vector3.ONE)
		var phase := float(cloud.get_meta("phase", 0.0))
		var pulse := 1.0 + sin(_elapsed * 0.22 + phase) * 0.06
		cloud.scale = base_scale * pulse
		var cloud_mat := cloud.material_override as StandardMaterial3D
		if cloud_mat != null:
			cloud_mat.emission_energy_multiplier = 1.4 + (0.5 + 0.5 * sin(_elapsed * 0.36 + phase)) * 1.0

	for star in _space_stars_3d:
		if star == null or not is_instance_valid(star):
			continue
		var base_scale: Vector3 = star.get_meta("base_scale", Vector3.ONE)
		var phase := float(star.get_meta("phase", 0.0))
		var twinkle := 1.0 + sin(_elapsed * 4.2 + phase) * 0.16
		star.scale = base_scale * twinkle
		var star_mat := star.material_override as StandardMaterial3D
		if star_mat != null:
			star_mat.emission_energy_multiplier = 1.8 + (0.5 + 0.5 * sin(_elapsed * 5.0 + phase)) * 1.8


func _sync_3d_world(delta: float) -> void:
	if not _use_3d or _world_root == null or not is_instance_valid(_world_root):
		return

	_sync_ground_3d()
	_sync_camera_3d()
	_sync_space_backdrop_3d(delta)
	_sync_player_3d()
	_sync_wingmen_3d()
	_sync_bullets_3d()
	_sync_enemy_bullets_3d()
	_sync_enemies_3d()
	_sync_pickups_3d()
	_sync_fx_3d()
	_sync_missiles_3d()
	_sync_boss_3d()


func _sync_camera_3d() -> void:
	if _camera_3d == null or not is_instance_valid(_camera_3d):
		return
	var player_center := _player.get_center() if _player_alive else Vector2(VW * 0.5, VH * 0.72)
	var composition_target := _camera_composition_target(player_center)
	var target_world := _to_world(composition_target, 0.0)
	var focus_z_offset := _sample_camera_setting(CAMERA_VIEW_FOCUS_OFFSETS)
	var focus_x_mul := _sample_camera_setting(CAMERA_VIEW_FOCUS_X)
	var smooth := _sample_camera_setting(CAMERA_VIEW_SMOOTH)
	var boss_camera_t := _boss_camera_intensity()
	var focus_y := lerpf(0.45, _sample_camera_setting(CAMERA_VIEW_BOSS_FOCUS_Y), boss_camera_t)
	var desired_focus := Vector3(
		target_world.x * focus_x_mul,
		focus_y,
		target_world.z + focus_z_offset - boss_camera_t * lerpf(1.2, 3.2, _camera_view_norm())
	)
	if not _camera_focus_ready:
		_camera_focus_3d = desired_focus
		_camera_focus_ready = true
	else:
		_camera_focus_3d = _camera_focus_3d.lerp(desired_focus, smooth)
	var shake_x := sin(_elapsed * 28.0) * _shake * 1.25
	var shake_y := cos(_elapsed * 24.0) * _shake * 0.8
	var cam_height := _sample_camera_setting(CAMERA_VIEW_HEIGHTS)
	var cam_distance := _sample_camera_setting(CAMERA_VIEW_DISTANCES)
	var track_x := _sample_camera_setting(CAMERA_VIEW_TRACK_X)
	if _boss != null:
		cam_height += _sample_camera_setting(CAMERA_VIEW_BOSS_HEIGHT_OFFSETS) * boss_camera_t
		cam_distance += _sample_camera_setting(CAMERA_VIEW_BOSS_DISTANCE_OFFSETS) * boss_camera_t
		track_x += _sample_camera_setting(CAMERA_VIEW_BOSS_TRACK_X_OFFSETS) * boss_camera_t
	var cam_pos := Vector3(_camera_focus_3d.x * track_x + shake_x, cam_height + shake_y, cam_distance + absf(_player_bank) * 1.1 - clampf(_elapsed * 0.015, 0.0, 1.2))
	_camera_3d.position = _camera_3d.position.lerp(cam_pos, 0.08)
	var target_fov := _sample_camera_setting(CAMERA_VIEW_FOVS) + _shake * 2.6 + clampf(absf(_player_bank) * 1.2, 0.0, 0.8)
	if _boss != null:
		target_fov += _sample_camera_setting(CAMERA_VIEW_BOSS_FOV_OFFSETS) * boss_camera_t
	_camera_3d.fov = lerpf(_camera_3d.fov, target_fov, 0.08)
	_camera_3d.look_at(_camera_focus_3d + Vector3(0.0, 0.0, -_shake * 0.12), Vector3.UP)


func _sync_player_3d() -> void:
	if _player_root_3d == null or not is_instance_valid(_player_root_3d):
		return

	if _player_alive:
		if _player_visual_3d == null or not is_instance_valid(_player_visual_3d):
			_player_visual_3d = _make_player_model()
			_player_root_3d.add_child(_player_visual_3d)
			_shield_visual_3d = _make_sphere_part(0.7, Color(0.3, 0.65, 1.0, 0.16), Color(0.22, 0.65, 1.0), 0.0, 0.05)
			_shield_visual_3d.position = Vector3(0.0, 0.18, 0.0)
			_player_visual_3d.add_child(_shield_visual_3d)
		_player_visual_3d.visible = true
		_player_visual_3d.position = _to_world(_player.get_center(), 1.25 + sin(_elapsed * 8.0) * 0.04)
		_player_visual_3d.rotation = Vector3(_player_bank * 0.08, 0.0, -_player_bank * 0.55)
		_player_visual_3d.scale = Vector3.ONE * (1.0 + _weapon_up_flash * 0.08)
		for side in [-1.0, 1.0]:
			var thruster := _ensure_effect_sphere(
				_player_visual_3d,
				"Thruster_%s" % ("L" if side < 0.0 else "R"),
				0.08,
				Color(0.3, 0.86, 1.0, 0.66),
				Color(0.18, 0.7, 1.0),
				0.0,
				0.04,
				Vector3(side * 0.24, 0.02, 1.42)
			) as MeshInstance3D
			if thruster != null:
				var thrust_scale := 0.85 + sin(_elapsed * 18.0 + side * 0.8) * 0.18 + absf(_player_bank) * 0.08 + _player_fire_flash * 0.46
				thruster.scale = Vector3(0.9, 0.72, maxf(1.0, thrust_scale * 2.2))
			var wingtip := _ensure_effect_sphere(
				_player_visual_3d,
				"WingtipGlow_%s" % ("L" if side < 0.0 else "R"),
				0.06,
				Color(0.58, 0.96, 1.0, 0.68),
				Color(0.18, 0.82, 1.0),
				0.0,
				0.03,
				Vector3(side * 1.18, 0.08, -0.18)
			) as MeshInstance3D
			if wingtip != null:
				wingtip.scale = Vector3.ONE * (0.92 + sin(_elapsed * 4.8 + side) * 0.08 + _player_fire_flash * 0.18)
		var muzzle := _ensure_effect_sphere(
			_player_visual_3d,
			"MuzzleFlash",
			0.1,
			Color(1.0, 0.94, 0.78, 0.8),
			Color(0.4, 0.88, 1.0),
			0.0,
			0.02,
			Vector3(0.0, 0.18, -1.56)
		) as MeshInstance3D
		if muzzle != null:
			muzzle.visible = _player_fire_flash > 0.02
			muzzle.scale = Vector3.ONE * lerpf(0.45, 1.85, _player_fire_flash)
		if _shield_visual_3d != null and is_instance_valid(_shield_visual_3d):
			_shield_visual_3d.visible = _has_shield or _shield_flash > 0.0
			var shield_scale := 1.0 + _shield_flash * 0.35
			_shield_visual_3d.scale = Vector3.ONE * shield_scale
	elif _player_visual_3d != null and is_instance_valid(_player_visual_3d):
		_player_visual_3d.visible = false


func _sync_wingmen_3d() -> void:
	if _wingmen_root_3d == null or not is_instance_valid(_wingmen_root_3d):
		return

	var active_ids := {}
	var base_center := _player.get_center()
	for wm in _wingmen:
		var entity_id := str(wm.get_instance_id())
		active_ids[entity_id] = true
		if wm.visual == null or not is_instance_valid(wm.visual):
			wm.visual = _make_wingman_model()
			wm.visual.set_meta("entity_id", entity_id)
			_wingmen_root_3d.add_child(wm.visual)
		var bob := sin(_elapsed * 6.0 + wm.offset.x * 0.04) * 0.06
		wm.visual.position = _to_world(base_center + wm.offset, 1.0 + bob)
		wm.visual.rotation = Vector3(0.0, sin(_elapsed * 3.0 + wm.offset.x * 0.01) * 0.12, -_player_bank * 0.35)
		var tail := _ensure_effect_sphere(
			wm.visual,
			"Thruster",
			0.06,
			Color(0.34, 0.92, 0.86, 0.62),
			Color(0.12, 0.72, 0.56),
			0.0,
			0.04,
			Vector3(0.0, 0.02, 0.42)
		) as MeshInstance3D
		if tail != null:
			tail.scale = Vector3(0.85, 0.62, 1.25 + sin(_elapsed * 15.0 + wm.offset.x * 0.02) * 0.2 + wm.fire_flash * 1.2)
		for side in [-1.0, 1.0]:
			var marker := _ensure_effect_sphere(
				wm.visual,
				"Marker_%s" % ("L" if side < 0.0 else "R"),
				0.045,
				Color(0.44, 0.96, 0.88, 0.62),
				Color(0.12, 0.86, 0.68),
				0.0,
				0.03,
				Vector3(side * 0.38, 0.08, -0.06)
			) as MeshInstance3D
			if marker != null:
				marker.scale = Vector3.ONE * (0.94 + sin(_elapsed * 5.5 + wm.offset.x * 0.02 + side) * 0.1)
		var nose := _ensure_effect_sphere(
			wm.visual,
			"NoseFlash",
			0.07,
			Color(1.0, 0.96, 0.82, 0.82),
			Color(0.2, 1.0, 0.76),
			0.0,
			0.02,
			Vector3(0.0, 0.14, -0.4)
		) as MeshInstance3D
		if nose != null:
			nose.visible = wm.fire_flash > 0.02
			nose.scale = Vector3.ONE * lerpf(0.4, 1.5, wm.fire_flash)
	_prune_container(_wingmen_root_3d, active_ids)


func _sync_bullets_3d() -> void:
	var active_ids := {}
	var visible_from := maxi(_pbullets.size() - _player_bullet_visual_budget(), 0)
	for i in range(_pbullets.size()):
		var b := _pbullets[i]
		var entity_id := str(b.get_instance_id())
		active_ids[entity_id] = true
		var bullet_visible := i >= visible_from and _is_visual_target_in_bounds(b.pos, VISUAL_MARGIN_X_3D, VISUAL_MARGIN_Y_3D)
		if not bullet_visible:
			if b.visual != null and is_instance_valid(b.visual):
				b.visual.visible = false
			continue
		if b.visual == null or not is_instance_valid(b.visual):
			b.visual = _make_bullet_model(b.col)
			b.visual.set_meta("entity_id", entity_id)
			_bullets_root_3d.add_child(b.visual)
		b.visual.visible = true
		b.visual.position = _to_world(b.pos, 0.8)
		var dir := Vector3(b.vel.x, 0.0, b.vel.y).normalized()
		if dir.length() > 0.0:
			b.visual.look_at(b.visual.position + dir, Vector3.UP, true)
	_prune_container(_bullets_root_3d, active_ids)


func _sync_enemy_bullets_3d() -> void:
	var active_ids := {}
	var visible_from := maxi(_ebullets.size() - _enemy_bullet_visual_budget(), 0)
	for i in range(_ebullets.size()):
		var eb := _ebullets[i]
		var entity_id := str(eb.get_instance_id())
		active_ids[entity_id] = true
		var bullet_visible := i >= visible_from and _is_visual_target_in_bounds(eb.pos, VISUAL_MARGIN_X_3D + 60.0, VISUAL_MARGIN_Y_3D + 60.0)
		if not bullet_visible:
			if eb.visual != null and is_instance_valid(eb.visual):
				eb.visual.visible = false
			continue
		if eb.visual == null or not is_instance_valid(eb.visual):
			eb.visual = _make_enemy_bullet_model()
			eb.visual.set_meta("entity_id", entity_id)
			_enemy_bullets_root_3d.add_child(eb.visual)
		eb.visual.visible = true
		eb.visual.position = _to_world(eb.pos, 0.65)
		var dir := Vector3(eb.vel.x, 0.0, eb.vel.y).normalized()
		if dir.length() > 0.0:
			eb.visual.look_at(eb.visual.position + dir, Vector3.UP, true)
	_prune_container(_enemy_bullets_root_3d, active_ids)


func _sync_enemies_3d() -> void:
	var active_ids := {}
	var sensor_budget := _enemy_sensor_glow_budget()
	var sensor_visuals := 0
	for e in _enemies:
		var entity_id := str(e.get_instance_id())
		active_ids[entity_id] = true
		var enemy_visible := _is_visual_target_in_bounds(e.pos, VISUAL_MARGIN_X_3D + 80.0, VISUAL_MARGIN_Y_3D + 180.0)
		if not enemy_visible:
			if e.visual != null and is_instance_valid(e.visual):
				e.visual.visible = false
			continue
		if e.visual == null or not is_instance_valid(e.visual):
			e.visual = _make_enemy_model(e.max_hp)
			e.visual.set_meta("entity_id", entity_id)
			_enemies_root_3d.add_child(e.visual)
		e.visual.visible = true
		var hover := sin(e.phase * 2.0 + float(e.max_hp)) * 0.08
		e.visual.position = _to_world(e.pos, 1.0 + float(e.max_hp) * 0.015 + hover)
		e.visual.rotation = Vector3(0.0, PI + sin(e.phase * 0.7) * 0.08, sin(e.phase * 2.0) * 0.12)
		e.visual.scale = Vector3.ONE * (1.0 + e.hit_flash * 0.08)
		var thruster_z := 0.48
		var thruster_y := 0.08
		var thruster_xs := [-0.18, 0.18]
		var muzzle_pos := Vector3(0.0, 0.14, -0.34)
		if e.max_hp <= 3 and e.max_hp > 1:
			thruster_z = 0.72
			thruster_y = 0.08
			thruster_xs = [-0.5, 0.5]
			muzzle_pos = Vector3(0.0, 0.22, -0.62)
		elif e.max_hp > 3:
			thruster_z = 0.92
			thruster_y = 0.16
			thruster_xs = [-0.82, 0.82]
			muzzle_pos = Vector3(0.0, 0.28, -0.72)
		for i in range(thruster_xs.size()):
			var side_x := float(thruster_xs[i])
			var thruster := _ensure_effect_sphere(
				e.visual,
				"Thruster_%s" % i,
				0.06 if e.max_hp <= 1 else 0.08 if e.max_hp <= 3 else 0.12,
				Color(1.0, 0.5, 0.2, 0.64),
				Color(1.0, 0.32, 0.08),
				0.0,
				0.04,
				Vector3(side_x, thruster_y, thruster_z)
			) as MeshInstance3D
			if thruster != null:
				var thrust_scale := 0.95 + sin(_elapsed * 12.0 + e.phase + float(i)) * 0.18 + e.fire_flash * 0.35 + float(mini(e.max_hp, 8)) * 0.02
				thruster.scale = Vector3(0.9, 0.8, maxf(1.0, thrust_scale * 1.7))
		for side in [-1.0, 1.0]:
			var sensor_name := "Sensor_%s" % ("L" if side < 0.0 else "R")
			var allow_sensor := sensor_visuals < sensor_budget
			if not allow_sensor:
				var hidden_sensor := e.visual.get_node_or_null(sensor_name) as MeshInstance3D
				if hidden_sensor != null:
					hidden_sensor.visible = false
				continue
			var sensor := _ensure_effect_sphere(
				e.visual,
				sensor_name,
				0.05 if e.max_hp <= 1 else 0.06 if e.max_hp <= 3 else 0.08,
				Color(1.0, 0.68, 0.34, 0.58),
				e.col.lightened(0.18),
				0.0,
				0.03,
				Vector3(side * (0.24 if e.max_hp <= 1 else 0.52 if e.max_hp <= 3 else 0.88), 0.12 if e.max_hp <= 3 else 0.22, -0.12)
			) as MeshInstance3D
			if sensor != null:
				sensor.visible = true
				sensor.scale = Vector3.ONE * (0.9 + sin(_elapsed * 4.4 + e.phase + side) * 0.08 + e.fire_flash * 0.16)
				sensor_visuals += 1
		var muzzle := _ensure_effect_sphere(
			e.visual,
			"MuzzleFlash",
			0.08 if e.max_hp <= 1 else 0.1 if e.max_hp <= 3 else 0.14,
			Color(1.0, 0.94, 0.8, 0.82),
			e.col.lightened(0.38),
			0.0,
			0.02,
			muzzle_pos
		) as MeshInstance3D
		if muzzle != null:
			muzzle.visible = e.fire_flash > 0.02
			muzzle.scale = Vector3.ONE * lerpf(0.42, 1.55, e.fire_flash)
	_prune_container(_enemies_root_3d, active_ids)


func _sync_pickups_3d() -> void:
	var active_ids := {}
	for p in _pickups:
		var entity_id := str(p.get_instance_id())
		active_ids[entity_id] = true
		var pickup_visible := _is_visual_target_in_bounds(p.pos, VISUAL_MARGIN_X_3D, VISUAL_MARGIN_Y_3D)
		if not pickup_visible:
			if p.visual != null and is_instance_valid(p.visual):
				p.visual.visible = false
			continue
		if p.visual == null or not is_instance_valid(p.visual):
			p.visual = _make_pickup_model(p.type)
			p.visual.set_meta("entity_id", entity_id)
			_pickups_root_3d.add_child(p.visual)
		p.visual.visible = true
		p.visual.position = _to_world(Vector2(p.pos.x, p.pos.y + sin(p.bob) * 3.0), 0.9 + sin(p.bob * 1.5) * 0.12)
		p.visual.rotation = Vector3(p.rot * 0.25, p.rot, p.rot * 0.4)
	_prune_container(_pickups_root_3d, active_ids)


func _sync_fx_3d() -> void:
	if _fx_root_3d == null or not is_instance_valid(_fx_root_3d):
		return

	var active_ids := {}
	var explosion_visible_from := maxi(_explosions.size() - _explosion_visual_budget(), 0)
	var ring_visible_from := maxi(_ring_fx.size() - _ring_visual_budget(), 0)
	var spark_budget := _spark_visual_budget()
	var spark_visible_from := maxi(_sparks.size() - spark_budget, 0)
	for i in range(_explosions.size()):
		var ex := _explosions[i]
		var entity_id := "ex_%s" % str(ex.get_instance_id())
		active_ids[entity_id] = true
		var hero_explosion := ex.flash >= 1.0
		var fx_visible := (hero_explosion or i >= explosion_visible_from) and _is_visual_target_in_bounds(ex.pos, FX_VISUAL_MARGIN_X_3D, FX_VISUAL_MARGIN_Y_3D)
		if not fx_visible:
			if ex.visual != null and is_instance_valid(ex.visual):
				ex.visual.visible = false
			continue
		if ex.visual == null or not is_instance_valid(ex.visual):
			ex.visual = _make_explosion_fx_model(ex.col)
			ex.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(ex.visual)
		ex.visual.visible = true
		var ratio := clampf(ex.radius / ex.max_radius, 0.0, 1.0)
		var fx_height := 1.0 + ex.lift * ratio + clampf(ex.max_radius * 0.002, 0.0, 0.35)
		ex.visual.position = _to_world(ex.pos, fx_height)
		ex.visual.rotation = Vector3(0.0, _elapsed * ex.spin, ratio * ex.spin * 2.6)
		ex.visual.scale = Vector3.ONE * maxf(ex.radius * 0.02, 0.24)
		var outer := ex.visual.get_meta("outer_ref", null) as MeshInstance3D
		if outer != null:
			outer.scale = Vector3.ONE * (1.0 + ratio * 1.1)
		var core := ex.visual.get_meta("core_ref", null) as MeshInstance3D
		if core != null:
			core.scale = Vector3.ONE * lerpf(1.2 + ex.flash * 0.6, 0.55, ratio)
		var ring := ex.visual.get_meta("ring_ref", null) as MeshInstance3D
		if ring != null:
			ring.scale = Vector3(1.0 + ratio * 1.8, lerpf(1.15, 0.35, ratio), 1.0 + ratio * 1.8)
			ring.rotation_degrees = Vector3(ex.spin * 10.0, 0.0, ex.spin * 6.0)
		var column := ex.visual.get_meta("column_ref", null) as MeshInstance3D
		if column != null:
			column.scale = Vector3(lerpf(1.0, 2.8, ratio), lerpf(1.4 + ex.flash * 0.4, 0.2, ratio), lerpf(1.0, 2.8, ratio))
		var flash := ex.visual.get_meta("flash_ref", null) as MeshInstance3D
		if flash != null:
			flash.scale = Vector3.ONE * lerpf(1.8 + ex.flash * 0.8, 0.25, ratio)
	for i in range(_ring_fx.size()):
		var rfx := _ring_fx[i]
		var entity_id := "ring_%s" % str(rfx.get_instance_id())
		active_ids[entity_id] = true
		var hero_ring := rfx.max_radius >= 130.0
		var ring_visible := (hero_ring or i >= ring_visible_from) and _is_visual_target_in_bounds(rfx.pos, FX_VISUAL_MARGIN_X_3D, FX_VISUAL_MARGIN_Y_3D)
		if not ring_visible:
			if rfx.visual != null and is_instance_valid(rfx.visual):
				rfx.visual.visible = false
			continue
		if rfx.visual == null or not is_instance_valid(rfx.visual):
			rfx.visual = _make_ring_fx_model(rfx.col)
			rfx.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(rfx.visual)
		rfx.visual.visible = true
		var ring_ratio := clampf(rfx.radius / rfx.max_radius, 0.0, 1.0)
		rfx.visual.position = _to_world(rfx.pos, 0.08 + rfx.height)
		rfx.visual.rotation_degrees = Vector3(rfx.tilt * (1.0 - ring_ratio), _elapsed * rfx.spin * 32.0, rfx.tilt * 0.35 * (1.0 - ring_ratio))
		rfx.visual.scale = Vector3(maxf(rfx.radius * 0.02, 0.15), lerpf(1.2, 0.24, ring_ratio), maxf(rfx.radius * 0.02, 0.15))
		var primary := rfx.visual.get_meta("primary_ref", null) as MeshInstance3D
		if primary != null:
			primary.scale = Vector3.ONE * lerpf(1.0, 1.45, ring_ratio)
		var secondary := rfx.visual.get_meta("secondary_ref", null) as MeshInstance3D
		if secondary != null:
			secondary.scale = Vector3.ONE * lerpf(1.12, 1.86, ring_ratio)
	for i in range(_sparks.size()):
		var s := _sparks[i]
		var entity_id := "spark_%s" % str(s.get_instance_id())
		active_ids[entity_id] = true
		var spark_visible := i >= spark_visible_from and _is_visual_target_in_bounds(s.pos, FX_VISUAL_MARGIN_X_3D, FX_VISUAL_MARGIN_Y_3D)
		if not spark_visible:
			if s.visual != null and is_instance_valid(s.visual):
				s.visual.visible = false
			continue
		if s.visual == null or not is_instance_valid(s.visual):
			s.visual = _make_spark_fx_model(s.col)
			s.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(s.visual)
		s.visual.visible = true
		s.visual.position = _to_world(s.pos, 1.0)
		s.visual.scale = Vector3.ONE * maxf(s.life / s.max_life, 0.18) * maxf(s.size * 0.45, 0.85)
		var dir := Vector3(s.vel.x, 0.0, s.vel.y).normalized()
		if dir.length() > 0.0:
			s.visual.look_at(s.visual.position + dir, Vector3.UP, true)
	_prune_container(_fx_root_3d, active_ids)


func _sync_missiles_3d() -> void:
	var active_ids := {}
	for m in _missile_pool:
		var entity_id := str(m.get_instance_id())
		active_ids[entity_id] = true
		var missile_visible := _is_visual_target_in_bounds(m.pos, VISUAL_MARGIN_X_3D + 120.0, VISUAL_MARGIN_Y_3D + 120.0)
		if not missile_visible:
			if m.visual != null and is_instance_valid(m.visual):
				m.visual.visible = false
			continue
		if m.visual == null or not is_instance_valid(m.visual):
			m.visual = _make_missile_model()
			m.visual.set_meta("entity_id", entity_id)
			_missiles_root_3d.add_child(m.visual)
		m.visual.visible = true
		var dir := Vector3(cos(m.angle), 0.0, sin(m.angle))
		m.visual.position = _to_world(m.pos, 0.88 + sin(_elapsed * 18.0 + float(m.get_instance_id() % 17)) * 0.03)
		m.visual.look_at(m.visual.position + dir, Vector3.UP, true)
		m.visual.rotation.z += sin(_elapsed * 20.0 + float(m.get_instance_id() % 23)) * 0.08
	_prune_container(_missiles_root_3d, active_ids)


func _sync_boss_3d() -> void:
	if _boss_root_3d == null or not is_instance_valid(_boss_root_3d):
		return

	if _boss != null:
		var entity_id := str(_boss.get_instance_id())
		if _boss.visual == null or not is_instance_valid(_boss.visual):
			_boss.visual = _make_boss_model()
			_boss.visual.set_meta("entity_id", entity_id)
			_boss_root_3d.add_child(_boss.visual)
		var hover := sin(_boss.phase * 1.3) * 0.18
		_boss.visual.position = _to_world(_boss.pos, 1.8 + hover)
		_boss.visual.rotation = Vector3(sin(_boss.phase * 0.8) * 0.03 + float(_boss.phase_level - 1) * 0.01, PI + sin(_boss.phase * 0.3) * 0.06, sin(_boss.phase * 0.5) * 0.05)
		_boss.visual.scale = Vector3.ONE * (_boss.scale * (1.0 + _boss.hit_flash * 0.05 + _boss.phase_transition * 0.08))
		for side in [-1.0, 1.0]:
			var thruster := _ensure_effect_sphere(
				_boss.visual,
				"Thruster_%s" % ("L" if side < 0.0 else "R"),
				0.18,
				Color(1.0, 0.54, 0.22, 0.72),
				Color(1.0, 0.3, 0.12),
				0.0,
				0.04,
				Vector3(side * 2.46, 0.22, 2.96)
			) as MeshInstance3D
			if thruster != null:
				var thrust_scale := 1.2 + sin(_elapsed * 8.0 + side * 0.9 + _boss.phase) * 0.22 + float(_boss.phase_level) * 0.08 + _boss_fire_flash * 0.36
				thruster.scale = Vector3(0.9, 0.8, thrust_scale * 1.8)
			var rail_glow := _ensure_effect_sphere(
				_boss.visual,
				"RailGlow_%s" % ("L" if side < 0.0 else "R"),
				0.1,
				Color(1.0, 0.58, 0.72, 0.6),
				Color(0.86, 0.12, 0.42),
				0.0,
				0.03,
				Vector3(side * 2.78, 0.34, 0.14)
			) as MeshInstance3D
			if rail_glow != null:
				rail_glow.scale = Vector3.ONE * (0.92 + sin(_elapsed * 3.8 + side + _boss.phase) * 0.08 + _boss.phase_transition * 0.12)
			var cannon_flash := _ensure_effect_sphere(
				_boss.visual,
				"CannonFlash_%s" % ("L" if side < 0.0 else "R"),
				0.16,
				Color(1.0, 0.9, 0.74, 0.84),
				Color(1.0, 0.44, 0.18),
				0.0,
				0.02,
				Vector3(side * 2.08, 0.26, -0.38)
			) as MeshInstance3D
			if cannon_flash != null:
				cannon_flash.visible = _boss_fire_flash > 0.02
				cannon_flash.scale = Vector3.ONE * lerpf(0.45, 1.65, _boss_fire_flash)
		var core_flash := _ensure_effect_sphere(
			_boss.visual,
			"CoreFlash",
			0.2,
			Color(1.0, 0.92, 0.96, 0.78),
			Color(1.0, 0.26, 0.52),
			0.0,
			0.02,
			Vector3(0.0, 0.7, -0.18)
		) as MeshInstance3D
		if core_flash != null:
			core_flash.scale = Vector3.ONE * (1.0 + _boss.phase_transition * 0.7 + _boss_fire_flash * 0.75 + _boss.hit_flash * 0.35)
		_prune_container(_boss_root_3d, {entity_id: true})
	else:
		_prune_container(_boss_root_3d, {})


func _draw_background(offset: Vector2) -> void:
	draw_rect(Rect2(offset, Vector2(VW, VH)), Color(0.005, 0.01, 0.026))
	draw_circle(Vector2(VW * 0.84, -150.0) + offset, 290.0, Color(0.05, 0.08, 0.16, 0.96))
	draw_circle(Vector2(VW * 0.79, -178.0) + offset, 250.0, Color(0.16, 0.28, 0.58, 0.16))
	draw_circle(Vector2(VW * 0.18, VH * 0.14) + offset, 180.0, Color(0.16, 0.08, 0.34, 0.09))
	draw_circle(Vector2(VW * 0.74, VH * 0.26) + offset, 210.0, Color(0.04, 0.16, 0.42, 0.08))
	draw_circle(Vector2(VW * 0.22, VH * 0.84) + offset, 230.0, Color(0.08, 0.22, 0.3, 0.06))

	for i in range(7):
		var t := float(i) / 6.0
		var band_y := lerpf(VH * 0.14, VH * 0.58, t) + sin(_elapsed * 0.12 + t * 4.2) * 18.0
		var band_col := Color(0.08 + t * 0.08, 0.14 + t * 0.08, 0.3 + t * 0.14, 0.018 + (1.0 - absf(t - 0.5) * 1.6) * 0.018)
		draw_line(Vector2(-80.0, band_y) + offset, Vector2(VW + 80.0, band_y + 120.0) + offset, band_col, 58.0 - absf(t - 0.5) * 18.0)

	for nebula in _nebulae:
		var pulse := 0.9 + 0.1 * sin(_elapsed * 0.45 + nebula.phase)
		var c := nebula.pos + offset
		draw_circle(c, nebula.radius * pulse, nebula.col * Color(1, 1, 1, nebula.alpha))
		draw_circle(
			c + Vector2(cos(nebula.phase) * nebula.radius * 0.18, sin(nebula.phase * 1.3) * nebula.radius * 0.12),
			nebula.radius * 0.62 * pulse,
			nebula.col.lightened(0.2) * Color(1, 1, 1, nebula.alpha * 0.75)
		)

	for star in _stars:
		var bright := clampf(star.alpha + 0.18 * sin(_elapsed * 2.4 + star.phase), 0.12, 1.0)
		var p := star.pos + offset
		var col := Color(0.75 + bright * 0.2, 0.82 + bright * 0.12, 0.95 + bright * 0.05, bright)
		draw_circle(p, star.size, col)
		if star.alpha > 0.72:
			draw_line(p - Vector2(star.size * 4.4, 0.0), p + Vector2(star.size * 4.4, 0.0), col * Color(1, 1, 1, 0.14), 0.8)
			draw_line(p - Vector2(0.0, star.size * 4.4), p + Vector2(0.0, star.size * 4.4), col * Color(1, 1, 1, 0.18), 0.9)
		if star.speed > 110.0:
			draw_line(p - Vector2(0.0, 10.0 + star.size * 2.4), p, col * Color(1, 1, 1, 0.22), maxf(star.size - 0.45, 0.55))


func _draw_hud_chrome() -> void:
	var view_t := _camera_view_norm()
	var hud_alpha := lerpf(0.54, 0.78, view_t)
	var line_alpha := lerpf(0.36, 0.62, view_t)
	var top_rect := Rect2(12.0, 10.0, VW - 24.0, 86.0)
	draw_rect(top_rect, Color(0.01, 0.05, 0.1, hud_alpha))
	draw_rect(Rect2(12.0, 10.0, VW - 24.0, 2.0), Color(0.18, 0.7, 1.0, line_alpha))
	draw_rect(Rect2(12.0, 94.0, VW - 24.0, 2.0), Color(0.2, 0.4, 0.6, line_alpha * 0.4))

	if _use_3d:
		var view_box := Rect2(VW - 194.0, 18.0, 168.0, 22.0)
		draw_rect(view_box, Color(0.04, 0.09, 0.14, lerpf(0.72, 0.92, view_t)))
		draw_rect(Rect2(view_box.position.x, view_box.position.y + view_box.size.y - 3.0, view_box.size.x, 3.0), Color(0.1, 0.22, 0.34, lerpf(0.72, 0.95, view_t)))
		var segment_w := view_box.size.x / float(CAMERA_VIEW_PRESETS.size())
		var view_col := Color(0.3, 0.78, 0.96) if _camera_view_preset < 1 else Color(0.36, 0.88, 1.0) if _camera_view_preset == 1 else Color(0.42, 0.96, 1.0)
		draw_rect(Rect2(view_box.position.x + segment_w * float(_camera_view_preset), view_box.position.y + view_box.size.y - 3.0, segment_w, 3.0), view_col * Color(1, 1, 1, 0.95))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(view_box.position.x + 8.0, view_box.position.y + 15.0),
			"AUTO " + CAMERA_VIEW_LABELS[_camera_view_preset] + " // " + CAMERA_VIEW_TACTICS[_camera_view_preset],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			view_col.lightened(0.18) * Color(1, 1, 1, lerpf(0.82, 0.96, view_t))
		)

	var hp_ratio := float(_hp) / float(MAX_HP)
	draw_rect(Rect2(18.0, 76.0, 210.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(18.0, 76.0, 210.0 * hp_ratio, 6.0), Color(0.25, 1.0, 0.55, 0.9))

	var weapon_ratio := float(_wpn_level) / float(MAX_WPN_LEVEL)
	draw_rect(Rect2(250.0, 76.0, 220.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(250.0, 76.0, 220.0 * weapon_ratio, 6.0), Color(1.0, 0.78, 0.28, 0.9))

	var missile_ratio := 1.0 if _missile_cd <= 0.0 else 1.0 - clampf(_missile_cd / MISSILE_COOLDOWN, 0.0, 1.0)
	draw_rect(Rect2(492.0, 76.0, 170.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(492.0, 76.0, 170.0 * missile_ratio, 6.0), Color(1.0, 0.45, 0.18, 0.9))

	var wave_ratio := 1.0 - clampf(_wave_timer / WAVE_INTERVAL, 0.0, 1.0)
	draw_rect(Rect2(VW - 220.0, 76.0, 190.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(VW - 220.0, 76.0, 190.0 * wave_ratio, 6.0), Color(0.35, 0.85, 1.0, 0.85))

	if _boss != null:
		var boss_ratio := clampf(float(_boss.hp) / float(_boss.max_hp), 0.0, 1.0)
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6, 10.0), Color(0.05, 0.02, 0.05, 0.85))
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6 * boss_ratio, 10.0), Color(1.0, 0.2, 0.45, 0.9))
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6, 10.0), Color(1.0, 0.4, 0.6, 0.18), false, 1.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW * 0.2, 101.0),
			"BOSS / " + _boss_phase_title(_boss.phase_level) + " / " + CAMERA_VIEW_TACTICS[_camera_view_preset],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(1.0, 0.72, 0.82, 0.84)
		)


func _draw_grid(offset: Vector2) -> void:
	for y in range(0, VH, 40):
		var alpha := 0.03 + 0.025 * sin(y * 0.05 + _elapsed * 2.0)
		var width := 1.2 if y % 120 == 0 else 0.8
		draw_line(Vector2(0, y) + offset, Vector2(VW, y) + offset, Color(0.0, 0.3, 0.6, alpha), width)
	for x in range(0, VW, 40):
		var cx_alpha := 0.02 + 0.03 * (1.0 - absf((float(x) - VW * 0.5) / (VW * 0.5)))
		draw_line(Vector2(x, 0) + offset, Vector2(x, VH) + offset, Color(0.0, 0.3, 0.6, cx_alpha))


func _offset_points(points: PackedVector2Array, delta: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array(points.duplicate())
	for i in shifted.size():
		shifted[i] += delta
	return shifted


func _draw_poly_with_outline(points: PackedVector2Array, fill_col: Color, stroke_col: Color, stroke_width: float) -> void:
	draw_colored_polygon(points, fill_col)
	var outline := PackedVector2Array(points.duplicate())
	outline.append(outline[0])
	draw_polyline(outline, stroke_col, stroke_width)


func _draw_player(offset: Vector2) -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var ty := _player.position.y
	var by := _player.position.y + _player.size.y
	var engine_y := by - 1.0

	# Blink during I-frames
	if _invincible > 0.0 and sin(_invincible * 30.0) > 0.0:
		return

	draw_circle(_player.get_center() + offset + Vector2(0, 14), 18.0, Color(0, 0, 0, 0.18))

	var flame_h := 4.5 + sin(_elapsed * 20.0) * 2.2 + _player_fire_flash * 4.0 + absf(_player_bank) * 1.5
	for engine_x in [-5.0, 5.0]:
		draw_circle(Vector2(cx + engine_x, engine_y + 1.5) + offset, 4.5 + _player_fire_flash * 1.8, Color(0.18, 0.72, 1.0, 0.18 + _player_fire_flash * 0.14))
		_draw_poly_with_outline(
			_offset_points(PackedVector2Array([
				Vector2(cx + engine_x - 2.8, engine_y),
				Vector2(cx + engine_x, engine_y + flame_h),
				Vector2(cx + engine_x + 2.8, engine_y),
			]), offset),
			Color(0.05, 0.6, 1.0, 0.8),
			Color(0.8, 0.95, 1.0, 0.4),
			0.8
		)
	if _player_fire_flash > 0.02:
		var muzzle_len := 10.0 + _player_fire_flash * 12.0
		_draw_poly_with_outline(
			_offset_points(PackedVector2Array([
				Vector2(cx, ty - 10.0 - muzzle_len),
				Vector2(cx + 4.0 + _player_fire_flash * 2.0, ty - 2.0),
				Vector2(cx, ty + 3.0),
				Vector2(cx - 4.0 - _player_fire_flash * 2.0, ty - 2.0),
			]), offset),
			Color(0.55, 0.92, 1.0, 0.18 + _player_fire_flash * 0.28),
			Color(1.0, 0.98, 0.82, 0.3 + _player_fire_flash * 0.4),
			0.8
		)
		draw_circle(Vector2(cx, ty - 3.0) + offset, 4.0 + _player_fire_flash * 3.0, Color(1.0, 0.98, 0.84, 0.22 + _player_fire_flash * 0.24))

	var body_local := PackedVector2Array([
		Vector2(cx, ty - 1),
		Vector2(cx + 5, ty + 7),
		Vector2(cx + 14, ty + 11),
		Vector2(cx + 22, ty + 19),
		Vector2(cx + 12, ty + 21),
		Vector2(cx + 19, ty + 30),
		Vector2(cx + 8, by - 8),
		Vector2(cx + 7, by - 2),
		Vector2(cx + 2, by - 7),
		Vector2(cx, by - 4),
		Vector2(cx - 2, by - 7),
		Vector2(cx - 7, by - 2),
		Vector2(cx - 8, by - 8),
		Vector2(cx - 19, ty + 30),
		Vector2(cx - 12, ty + 21),
		Vector2(cx - 22, ty + 19),
		Vector2(cx - 14, ty + 11),
		Vector2(cx - 5, ty + 7),
	])
	var shadow := PackedVector2Array(body_local.duplicate())
	for si in shadow.size():
		shadow[si] += offset + Vector2(0, 6)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.16))
	var body := _offset_points(body_local, offset)
	_draw_poly_with_outline(body, Color(0.06, 0.14, 0.24), Color(0.05, 0.88, 1.0), 1.5)

	var center_panel := _offset_points(PackedVector2Array([
		Vector2(cx, ty + 7),
		Vector2(cx + 8, ty + 17),
		Vector2(cx + 4, by - 10),
		Vector2(cx, by - 5),
		Vector2(cx - 4, by - 10),
		Vector2(cx - 8, ty + 17),
	]), offset)
	_draw_poly_with_outline(center_panel, Color(0.18, 0.42, 0.62, 0.62), Color(0.45, 0.92, 1.0, 0.5), 1.0)

	var canopy := _offset_points(PackedVector2Array([
		Vector2(cx, ty + 6),
		Vector2(cx + 5, ty + 15),
		Vector2(cx, ty + 22),
		Vector2(cx - 5, ty + 15),
	]), offset)
	_draw_poly_with_outline(canopy, Color(0.38, 0.88, 1.0, 0.34), Color(0.7, 0.96, 1.0, 0.75), 0.9)

	for wing_sign in [-1.0, 1.0]:
		var fin := _offset_points(PackedVector2Array([
			Vector2(cx + wing_sign * 10, ty + 20),
			Vector2(cx + wing_sign * 15, ty + 26),
			Vector2(cx + wing_sign * 10, by - 6),
			Vector2(cx + wing_sign * 6, by - 12),
		]), offset)
		_draw_poly_with_outline(fin, Color(0.12, 0.22, 0.33, 0.78), Color(0.3, 0.75, 1.0, 0.45), 0.8)
		if wing_sign < 0.0:
			draw_circle(Vector2(cx + wing_sign * 18, ty + 20) + offset, 1.6, Color(1.0, 0.3, 0.32, 0.9))
		else:
			draw_circle(Vector2(cx + wing_sign * 18, ty + 20) + offset, 1.6, Color(0.3, 1.0, 0.8, 0.9))

	draw_line(Vector2(cx, ty + 3) + offset, Vector2(cx, by - 7) + offset, Color(0.65, 0.95, 1.0, 0.45), 1.0)
	draw_line(Vector2(cx - 14, ty + 20) + offset, Vector2(cx - 6, ty + 23) + offset, Color(0.45, 0.92, 1.0, 0.55), 1.0)
	draw_line(Vector2(cx + 14, ty + 20) + offset, Vector2(cx + 6, ty + 23) + offset, Color(0.45, 0.92, 1.0, 0.55), 1.0)
	draw_circle(Vector2(cx, ty + 12) + offset, 10.0, Color(0.2, 0.8, 1.0, 0.08))

	# Shield visual
	if _has_shield or _shield_flash > 0.0:
		var col := Color(0.2, 0.6, 1.0, 0.15)
		if _shield_flash > 0.0:
			col = Color(0.5, 0.9, 1.0, _shield_flash * 0.4)
		draw_circle(_player.get_center() + offset, 24.0, col)
		if _has_shield and _shield_flash <= 0.0:
			draw_arc(_player.get_center() + offset, 24.0, 0, TAU, 24, Color(0.3, 0.7, 1.0, 0.5), 1.0)


func _draw_wingmen(offset: Vector2) -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var cy := _player.position.y + _player.size.y / 2.0
	for wm in _wingmen:
		var wx := cx + wm.offset.x
		var wy := cy + wm.offset.y
		var body := _offset_points(PackedVector2Array([
			Vector2(wx, wy - 8),
			Vector2(wx + 5, wy - 2),
			Vector2(wx + 9, wy + 5),
			Vector2(wx + 2, wy + 3),
			Vector2(wx, wy + 7),
			Vector2(wx - 2, wy + 3),
			Vector2(wx - 9, wy + 5),
			Vector2(wx - 5, wy - 2),
		]), offset)
		_draw_poly_with_outline(body, Color(0.08, 0.22, 0.36), Color(0.42, 1.0, 0.62), 1.0)
		var canopy := _offset_points(PackedVector2Array([
			Vector2(wx, wy - 5),
			Vector2(wx + 2.2, wy - 1),
			Vector2(wx, wy + 2.2),
			Vector2(wx - 2.2, wy - 1),
		]), offset)
		draw_colored_polygon(canopy, Color(0.5, 0.95, 1.0, 0.4))
		draw_line(Vector2(wx - 5, wy + 3) + offset, Vector2(wx + 5, wy + 3) + offset, Color(0.42, 1.0, 0.62, 0.5), 0.8)
		draw_circle(Vector2(wx, wy + 5) + offset, 1.8, Color(0.2, 0.7, 1.0, 0.75))
		draw_circle(Vector2(wx, wy) + offset, 4.0, Color(0.3, 1.0, 0.7, 0.08))
		var wingman_flame := 3.0 + sin(_elapsed * 16.0 + wm.offset.x * 0.06) * 1.2 + wm.fire_flash * 2.6
		_draw_poly_with_outline(
			_offset_points(PackedVector2Array([
				Vector2(wx - 1.8, wy + 6.0),
				Vector2(wx, wy + 6.0 + wingman_flame),
				Vector2(wx + 1.8, wy + 6.0),
			]), offset),
			Color(0.18, 0.88, 0.82, 0.72),
			Color(0.86, 1.0, 0.92, 0.3),
			0.7
		)
		if wm.fire_flash > 0.02:
			draw_circle(Vector2(wx, wy - 7.0) + offset, 2.8 + wm.fire_flash * 2.6, Color(1.0, 0.96, 0.84, 0.22 + wm.fire_flash * 0.34))


func _draw_bullet(b: Bullet, offset: Vector2) -> void:
	var p := b.pos + offset
	var tail := b.vel.normalized() * -10.0
	draw_circle(p, 10.0, Color(b.col, 0.12))
	draw_line(p + tail, p + Vector2(0, 5), Color(b.col, 0.35), 2.2)
	draw_rect(Rect2(p.x - 1.8, p.y - 7.0, 3.6, 14.0), b.col)
	draw_rect(Rect2(p.x - 0.6, p.y - 9.0, 1.2, 18.0), Color(1, 1, 1, 0.9))


func _draw_enemy(e: EnemyData, offset: Vector2) -> void:
	var ox := e.pos.x + offset.x
	var oy := e.pos.y + offset.y
	var hw := e.w / 2.0
	var hh := e.h / 2.0
	var pts: PackedVector2Array
	var line_w: float
	var fill_col := e.col * Color(0.3, 0.3, 0.35)
	if e.hit_flash > 0.0:
		fill_col = Color(1, 1, 1, e.hit_flash) + fill_col * (1.0 - e.hit_flash)

	match int(e.max_hp):
		1:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.45, oy - hh * 0.25),
				Vector2(ox + hw, oy + hh * 0.05),
				Vector2(ox + hw * 0.3, oy + hh * 0.75),
				Vector2(ox, oy + hh * 0.4),
				Vector2(ox - hw * 0.3, oy + hh * 0.75),
				Vector2(ox - hw, oy + hh * 0.05),
				Vector2(ox - hw * 0.45, oy - hh * 0.25),
			]); line_w = 1.0
		3:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.42, oy - hh * 0.62),
				Vector2(ox + hw * 0.95, oy - hh * 0.2),
				Vector2(ox + hw, oy + hh * 0.24),
				Vector2(ox + hw * 0.42, oy + hh * 0.46),
				Vector2(ox + hw * 0.18, oy + hh),
				Vector2(ox - hw * 0.18, oy + hh),
				Vector2(ox - hw * 0.42, oy + hh * 0.46),
				Vector2(ox - hw, oy + hh * 0.24),
				Vector2(ox - hw * 0.95, oy - hh * 0.2),
				Vector2(ox - hw * 0.42, oy - hh * 0.62),
			]); line_w = 1.25
		_:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.34, oy - hh * 0.82),
				Vector2(ox + hw * 0.8, oy - hh * 0.56),
				Vector2(ox + hw, oy - hh * 0.1),
				Vector2(ox + hw * 0.78, oy + hh * 0.18),
				Vector2(ox + hw * 0.95, oy + hh * 0.66),
				Vector2(ox + hw * 0.32, oy + hh * 0.48),
				Vector2(ox + hw * 0.14, oy + hh),
				Vector2(ox - hw * 0.14, oy + hh),
				Vector2(ox - hw * 0.32, oy + hh * 0.48),
				Vector2(ox - hw * 0.95, oy + hh * 0.66),
				Vector2(ox - hw * 0.78, oy + hh * 0.18),
				Vector2(ox - hw, oy - hh * 0.1),
				Vector2(ox - hw * 0.8, oy - hh * 0.56),
				Vector2(ox - hw * 0.34, oy - hh * 0.82),
			]); line_w = 1.5

	draw_circle(Vector2(ox, oy + hh * 0.35), hw * 0.95, Color(0, 0, 0, 0.14))
	_draw_poly_with_outline(pts, fill_col, e.col, line_w)
	var engine_flame := 3.0 + sin(_elapsed * 14.0 + e.phase) * 1.1 + e.fire_flash * 3.2
	var thruster_y := oy + hh * (0.54 if e.max_hp <= 1 else 0.62 if e.max_hp <= 3 else 0.7)
	var thruster_spread := hw * (0.34 if e.max_hp <= 1 else 0.5 if e.max_hp <= 3 else 0.62)
	for side in [-1.0, 1.0]:
		_draw_poly_with_outline(
			PackedVector2Array([
				Vector2(ox + thruster_spread * side - 2.2, thruster_y),
				Vector2(ox + thruster_spread * side, thruster_y + engine_flame),
				Vector2(ox + thruster_spread * side + 2.2, thruster_y),
			]),
			e.col.lightened(0.18) * Color(1, 1, 1, 0.72),
			Color(1.0, 0.94, 0.84, 0.22 + e.fire_flash * 0.18),
			0.7
		)
	if e.fire_flash > 0.02:
		var muzzle_y := oy - hh * (0.34 if e.max_hp <= 1 else 0.42 if e.max_hp <= 3 else 0.5)
		draw_circle(Vector2(ox, muzzle_y), 3.0 + e.fire_flash * (2.4 if e.max_hp <= 1 else 3.0 if e.max_hp <= 3 else 4.0), Color(1.0, 0.96, 0.84, 0.18 + e.fire_flash * 0.24))
		draw_circle(Vector2(ox, muzzle_y), 5.5 + e.fire_flash * (3.2 if e.max_hp <= 1 else 4.5 if e.max_hp <= 3 else 6.0), e.col.lightened(0.3) * Color(1, 1, 1, 0.08 + e.fire_flash * 0.12))

	match int(e.max_hp):
		1:
			var cockpit := PackedVector2Array([
				Vector2(ox, oy - hh * 0.42),
				Vector2(ox + hw * 0.14, oy - hh * 0.02),
				Vector2(ox, oy + hh * 0.18),
				Vector2(ox - hw * 0.14, oy - hh * 0.02),
			])
			draw_colored_polygon(cockpit, Color(1.0, 0.88, 0.45, 0.38))
			draw_line(Vector2(ox, oy - hh * 0.26), Vector2(ox, oy + hh * 0.3), Color(1.0, 0.78, 0.32, 0.5), 0.9)
			draw_circle(Vector2(ox - hw * 0.52, oy + hh * 0.12), 2.0, Color(1.0, 0.42, 0.2, 0.55))
			draw_circle(Vector2(ox + hw * 0.52, oy + hh * 0.12), 2.0, Color(1.0, 0.42, 0.2, 0.55))
		3:
			var panel := PackedVector2Array([
				Vector2(ox, oy - hh * 0.42),
				Vector2(ox + hw * 0.26, oy - hh * 0.06),
				Vector2(ox + hw * 0.1, oy + hh * 0.52),
				Vector2(ox - hw * 0.1, oy + hh * 0.52),
				Vector2(ox - hw * 0.26, oy - hh * 0.06),
			])
			_draw_poly_with_outline(panel, e.col * Color(0.55, 0.55, 0.82, 0.42), Color(0.95, 0.92, 0.68, 0.35), 0.8)
			draw_line(Vector2(ox - hw * 0.58, oy + hh * 0.05), Vector2(ox + hw * 0.58, oy + hh * 0.05), Color(1.0, 0.62, 0.22, 0.45), 1.0)
			draw_circle(Vector2(ox - hw * 0.64, oy + hh * 0.22), 3.1, Color(1.0, 0.4, 0.18, 0.62))
			draw_circle(Vector2(ox + hw * 0.64, oy + hh * 0.22), 3.1, Color(1.0, 0.4, 0.18, 0.62))
		_:
			var armor := PackedVector2Array([
				Vector2(ox, oy - hh * 0.56),
				Vector2(ox + hw * 0.18, oy - hh * 0.26),
				Vector2(ox + hw * 0.22, oy + hh * 0.18),
				Vector2(ox, oy + hh * 0.34),
				Vector2(ox - hw * 0.22, oy + hh * 0.18),
				Vector2(ox - hw * 0.18, oy - hh * 0.26),
			])
			_draw_poly_with_outline(armor, Color(0.92, 0.62, 0.2, 0.22), Color(1.0, 0.78, 0.4, 0.35), 0.8)
			draw_line(Vector2(ox - hw * 0.68, oy + hh * 0.02), Vector2(ox + hw * 0.68, oy + hh * 0.02), Color(1.0, 0.42, 0.22, 0.45), 1.2)
			draw_circle(Vector2(ox, oy), 4.0, e.col * Color(1.2, 0.6, 0.4))
			draw_circle(Vector2(ox, oy), 3.0, Color(1.0, 0.7, 0.3))
			draw_circle(Vector2(ox - hw * 0.45, oy + hh * 0.2), 3.2, Color(1.0, 0.35, 0.2, 0.6))
			draw_circle(Vector2(ox + hw * 0.45, oy + hh * 0.2), 3.2, Color(1.0, 0.35, 0.2, 0.6))

	if e.max_hp > 1:
		_draw_hp_bar(ox, oy, e)


func _draw_boss(offset: Vector2) -> void:
	if _boss == null:
		return

	var b := _boss
	var center := b.pos + offset
	var hw := b.w * b.scale * 0.5
	var hh := b.h * b.scale * 0.5
	var body := PackedVector2Array([
		center + Vector2(0.0, -hh),
		center + Vector2(hw * 0.24, -hh * 0.88),
		center + Vector2(hw * 0.56, -hh * 0.7),
		center + Vector2(hw * 1.08, -hh * 0.34),
		center + Vector2(hw * 0.82, -hh * 0.02),
		center + Vector2(hw * 0.98, hh * 0.42),
		center + Vector2(hw * 0.62, hh * 0.32),
		center + Vector2(hw * 0.42, hh * 0.72),
		center + Vector2(hw * 0.14, hh),
		center + Vector2(-hw * 0.14, hh),
		center + Vector2(-hw * 0.42, hh * 0.72),
		center + Vector2(-hw * 0.62, hh * 0.32),
		center + Vector2(-hw * 0.98, hh * 0.42),
		center + Vector2(-hw * 0.82, -hh * 0.02),
		center + Vector2(-hw * 1.08, -hh * 0.34),
		center + Vector2(-hw * 0.56, -hh * 0.7),
		center + Vector2(-hw * 0.24, -hh * 0.88),
	])
	var shadow := PackedVector2Array(body.duplicate())
	for i in shadow.size():
		shadow[i] += Vector2(0.0, 14.0)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.2))

	var fill_col := b.col * Color(0.24, 0.14, 0.22)
	if b.hit_flash > 0.0:
		fill_col = Color(1, 1, 1, b.hit_flash) + fill_col * (1.0 - b.hit_flash)
	_draw_poly_with_outline(body, fill_col, Color(1.0, 0.35, 0.65, 0.9), 2.0)

	var armor := PackedVector2Array([
		center + Vector2(0.0, -hh * 0.72),
		center + Vector2(hw * 0.3, -hh * 0.32),
		center + Vector2(hw * 0.24, hh * 0.16),
		center + Vector2(0.0, hh * 0.44),
		center + Vector2(-hw * 0.24, hh * 0.16),
		center + Vector2(-hw * 0.3, -hh * 0.32),
	])
	_draw_poly_with_outline(armor, Color(0.32, 0.1, 0.22, 0.85), Color(1.0, 0.55, 0.7, 0.36), 1.2)

	var canopy := PackedVector2Array([
		center + Vector2(0.0, -hh * 0.48),
		center + Vector2(hw * 0.22, -hh * 0.08),
		center + Vector2(0.0, hh * 0.14),
		center + Vector2(-hw * 0.22, -hh * 0.08),
	])
	_draw_poly_with_outline(canopy, Color(0.28, 0.78, 1.0, 0.32), Color(0.86, 0.96, 1.0, 0.55), 1.0)

	for wing_sign in [-1.0, 1.0]:
		var blade := PackedVector2Array([
			center + Vector2(wing_sign * hw * 0.56, -hh * 0.12),
			center + Vector2(wing_sign * hw * 0.92, hh * 0.06),
			center + Vector2(wing_sign * hw * 0.72, hh * 0.38),
			center + Vector2(wing_sign * hw * 0.46, hh * 0.26),
		])
		_draw_poly_with_outline(blade, Color(0.4, 0.12, 0.22, 0.78), Color(1.0, 0.48, 0.56, 0.45), 1.0)
		draw_circle(center + Vector2(wing_sign * hw * 0.74, hh * 0.18), 5.0 * b.scale, Color(1.0, 0.42, 0.18, 0.66))
		draw_circle(center + Vector2(wing_sign * hw * 0.82, hh * 0.42), (6.0 + sin(_elapsed * 8.0 + wing_sign) * 1.4 + _boss_fire_flash * 3.2) * b.scale, Color(1.0, 0.28, 0.12, 0.16))
		if _boss_fire_flash > 0.02:
			draw_circle(center + Vector2(wing_sign * hw * 0.66, -hh * 0.04), (6.0 + _boss_fire_flash * 5.5) * b.scale, Color(1.0, 0.92, 0.82, 0.16 + _boss_fire_flash * 0.24))

	draw_circle(center, 20.0 * b.scale, Color(1.0, 0.28, 0.55, 0.14))
	draw_circle(center, 9.0 * b.scale, Color(1.0, 0.88, 0.96, 0.98))
	draw_circle(center, (10.0 + _boss_fire_flash * 6.0) * b.scale, Color(1.0, 0.92, 0.98, 0.12 + _boss_fire_flash * 0.18))
	draw_arc(center, 18.0 * b.scale, b.phase, b.phase + TAU * 0.78, 28, Color(1.0, 0.55, 0.75, 0.4), 1.4)
	draw_line(center + Vector2(-hw * 0.7, hh * 0.14), center + Vector2(hw * 0.7, hh * 0.14), Color(1.0, 0.24, 0.42, 0.36), 2.2)
	draw_line(center + Vector2(0.0, -hh * 0.6), center + Vector2(0.0, hh * 0.64), Color(1.0, 0.48, 0.68, 0.22), 1.4)


func _draw_hp_bar(cx: float, cy: float, e: EnemyData) -> void:
	var bw := e.w + 6
	var bh := 3
	var px := cx - bw / 2.0
	var py := cy - e.h / 2.0 - 8
	draw_rect(Rect2(px, py, bw, bh), Color(0.1, 0.1, 0.1, 0.8))
	var ratio := float(e.hp) / float(e.max_hp)
	var hp_c := Color(1.0, 0.3, 0.3) if ratio < 0.3 else Color(0.3, 1.0, 0.5)
	draw_rect(Rect2(px, py, bw * ratio, bh), hp_c)
	draw_rect(Rect2(px, py, bw, bh), Color(0.5, 0.5, 0.5), false, 0.5)


func _draw_enemy_bullet(pos: Vector2, offset: Vector2) -> void:
	var p := pos + offset
	draw_circle(p, 8.0, Color(1.0, 0.2, 0.2, 0.08))
	draw_line(p - Vector2(0, 8), p + Vector2(0, 1), Color(1.0, 0.3, 0.15, 0.25), 2.2)
	draw_circle(p, 4.0, Color(1.0, 0.35, 0.15, 0.5))
	draw_circle(p, 2.5, Color(1.0, 0.5, 0.2))
	draw_circle(p, 1.0, Color(1.0, 0.9, 0.6))


func _draw_pickup(p: Pickup, offset: Vector2) -> void:
	var y := p.pos.y + sin(p.bob) * 3.0
	var alpha := minf(p.life, 1.0)
	var center := Vector2(p.pos.x, y) + offset

	draw_circle(center, 10.0, Color(0.3, 0.3, 0.3, alpha * 0.3))

	match p.type:
		PickupType.WEAPON:
			var pts := PackedVector2Array([
				Vector2(p.pos.x, y - 7), Vector2(p.pos.x + 7, y),
				Vector2(p.pos.x, y + 7), Vector2(p.pos.x - 7, y),
			])
			var cos_r := cos(p.rot); var sin_r := sin(p.rot)
			for i in pts.size():
				var dx := pts[i].x - p.pos.x
				var dy := pts[i].y - y
				pts[i] = Vector2(p.pos.x + dx * cos_r - dy * sin_r, y + dx * sin_r + dy * cos_r) + offset
			draw_colored_polygon(pts, Color(1.0, 0.85, 0.2, alpha * 0.7))
			pts.append(pts[0])
			draw_polyline(pts, Color(1.0, 1.0, 0.5, alpha), 1.0)
		PickupType.HEAL:
			var pulse := 1.0 + sin(p.bob * 2.0) * 0.15
			draw_rect(Rect2(p.pos.x - 2 * pulse, y - 6 * pulse, 4 * pulse, 12 * pulse), Color(0.3, 1.0, 0.4, alpha))
			draw_rect(Rect2(p.pos.x - 6 * pulse, y - 2 * pulse, 12 * pulse, 4 * pulse), Color(0.3, 1.0, 0.4, alpha))
		PickupType.SHIELD:
			draw_circle(center, 6.0, Color(0.3, 0.6, 1.0, alpha * 0.7))
			draw_arc(center, 8.0, p.rot, TAU + p.rot, 12, Color(0.5, 0.8, 1.0, alpha), 1.0)
		PickupType.BOMB:
			draw_circle(center, 12.0, Color(1.0, 0.1, 0.1, alpha * 0.2))
			var bomb_pts := PackedVector2Array()
			for i in 8:
				var angle := TAU * float(i) / 8 + p.rot
				bomb_pts.append(Vector2(p.pos.x + cos(angle) * 7, y + sin(angle) * 7))
			draw_colored_polygon(bomb_pts.duplicate(), Color(1.0, 0.2, 0.2, alpha * 0.7))
			bomb_pts.append(bomb_pts[0])
			for i in bomb_pts.size():
				bomb_pts[i] += offset
			draw_polyline(bomb_pts, Color(1.0, 0.8, 0.5, alpha), 1.2)
		PickupType.MISSILE:
			var oct := PackedVector2Array()
			for i in 8:
				var a := TAU * float(i) / 8.0
				oct.append(Vector2(p.pos.x + cos(a) * 7.0, y + sin(a) * 7.0) + offset)
			draw_colored_polygon(oct, Color(1.0, 0.5, 0.2, alpha * 0.6))
			oct.append(oct[0])
			draw_polyline(oct, Color(1.0, 0.7, 0.3, alpha), 1.0)


# --- Homing missile visual ---
func _draw_missile(m: HomingMissile, offset: Vector2) -> void:
	# Smoke trail
	for si in m.smoke.size():
		var sa := 0.15 * float(si) / float(m.smoke.size())
		draw_circle(m.smoke[si] + offset, 2.2, Color(0.4, 0.4, 0.4, sa))
	# Missile body
	var p := m.pos + offset
	var dir := Vector2.from_angle(m.angle)
	var side := dir.orthogonal()
	var tail := p - dir * 8.0
	draw_circle(p, 7.0, Color(1.0, 0.4, 0.1, 0.15))
	var body := PackedVector2Array([
		p + dir * 6.0,
		p + side * 2.0,
		tail + side * 3.0,
		tail,
		tail - side * 3.0,
		p - side * 2.0,
	])
	_draw_poly_with_outline(body, Color(0.95, 0.56, 0.2, 0.92), Color(1.0, 0.84, 0.62, 0.78), 1.0)
	_draw_poly_with_outline(PackedVector2Array([
		tail + side * 3.0,
		tail + side * 5.4 - dir * 2.2,
		tail + side * 1.2 - dir * 1.4,
	]), Color(0.92, 0.48, 0.18, 0.9), Color(1.0, 0.78, 0.58, 0.5), 0.8)
	_draw_poly_with_outline(PackedVector2Array([
		tail - side * 3.0,
		tail - side * 5.4 - dir * 2.2,
		tail - side * 1.2 - dir * 1.4,
	]), Color(0.92, 0.48, 0.18, 0.9), Color(1.0, 0.78, 0.58, 0.5), 0.8)
	draw_line(tail + side * 1.6, p + dir * 2.0, Color(1.0, 0.92, 0.72, 0.75), 0.8)
	draw_line(tail - side * 1.6, p + dir * 2.0, Color(1.0, 0.92, 0.72, 0.75), 0.8)
	draw_circle(p + dir * 1.2, 2.1, Color(1.0, 0.86, 0.58, 0.95))
	# Flame
	draw_circle(tail, 2.5, Color(1.0, 0.3, 0.1, 0.7))


# --- Small text popup at position ---
func _make_text_popup(pos: Vector2, text: String, col: Color) -> void:
	var tfx := TextFX.new()
	tfx.pos = pos
	tfx.text = text
	tfx.life = 0.8
	tfx.max_life = 0.8
	tfx.vel = Vector2.UP * 50.0
	tfx.col = col
	_text_fx.append(tfx)


# --- Wingmen ---
func _update_wingmen(dt: float) -> void:
	if _wpn_level >= 3 and _wingmen.is_empty():
		_add_wingman(_wingman_slot_offset(0))
		_add_wingman(_wingman_slot_offset(1))

	for i in range(_wingmen.size()):
		var wm := _wingmen[i]
		wm.offset = wm.offset.lerp(_wingman_slot_offset(i), minf(dt * 5.0, 1.0))
		wm.fire_flash = maxf(wm.fire_flash - dt * 4.8, 0.0)
		wm.missile_cd = maxf(wm.missile_cd - dt, 0.0)
		if wm.missile_cd <= 0.0 and _missile_pool.size() < MAX_MISSILES:
			_fire_wingman_missile(wm)
			wm.missile_cd = 8.0


func _add_wingman(off: Vector2) -> void:
	var wm := Wingman.new()
	wm.offset = off
	_wingmen.append(wm)


func _fire_wingman_missile(wm: Wingman) -> void:
	var m := HomingMissile.new()
	m.pos = _player.get_center() + wm.offset
	m.angle = -PI / 2
	m.speed = MISSILE_SPEED * 0.85
	m.dmg = 2
	m.life = MISSILE_LIFE * 0.9
	wm.fire_flash = 1.0
	_missile_pool.append(m)
