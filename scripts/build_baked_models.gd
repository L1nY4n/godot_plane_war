extends SceneTree


const OUT_DIR := "res://assets/baked_models"


func _init() -> void:
	var err := _build_all()
	if err != OK:
		push_error("build_baked_models failed: %s" % err)
	quit(err)


func _build_all() -> int:
	var mk_err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if mk_err != OK:
		return mk_err

	var jobs := [
		{"name": "player_ship_baked", "build": Callable(self, "_build_player_root")},
		{"name": "wingman_drone_baked", "build": Callable(self, "_build_wingman_root")},
		{"name": "enemy_light_baked", "build": Callable(self, "_build_enemy_light_root")},
		{"name": "enemy_mid_baked", "build": Callable(self, "_build_enemy_mid_root")},
		{"name": "enemy_heavy_baked", "build": Callable(self, "_build_enemy_heavy_root")},
		{"name": "boss_flagship_baked", "build": Callable(self, "_build_boss_root")},
	]

	for job in jobs:
		var root: Node3D = job.build.call()
		root.name = job.name
		_assign_owner_recursive(root, root)
		var packed := PackedScene.new()
		var pack_err := packed.pack(root)
		if pack_err != OK:
			root.free()
			return pack_err
		var save_err := ResourceSaver.save(packed, "%s/%s.tscn" % [OUT_DIR, job.name])
		root.free()
		if save_err != OK:
			return save_err

	return OK


func _make_material(albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.35, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(albedo.r, albedo.g, albedo.b, alpha)
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = emission != Color.BLACK
	material.emission = emission
	material.emission_energy_multiplier = 1.2
	if alpha < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _assign_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner_recursive(child, owner)


func _make_box(size: Vector3, albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.2, roughness: float = 0.28, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _make_material(albedo, emission, metallic, roughness, alpha)
	return instance


func _make_sphere(radius: float, albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.0, roughness: float = 0.08, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _make_material(albedo, emission, metallic, roughness, alpha)
	return instance


func _make_cylinder(radius: float, height: float, albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.24, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _make_material(albedo, emission, metallic, roughness, alpha)
	return instance


func _attach(parent: Node3D, child: Node3D, position: Vector3, rotation_deg: Vector3 = Vector3.ZERO) -> void:
	child.position = position
	child.rotation_degrees = rotation_deg
	parent.add_child(child)


func _build_player_root() -> Node3D:
	var root := Node3D.new()
	var dark := Color(0.08, 0.14, 0.2)
	var accent := Color(0.22, 0.52, 0.78)
	var trim := Color(0.76, 0.95, 1.0)
	var canopy := Color(0.42, 0.84, 1.0)

	_attach(root, _make_box(Vector3(0.42, 0.18, 1.6), dark, Color(0.0, 0.14, 0.22), 0.24, 0.28), Vector3(0.0, 0.18, 0.06))
	_attach(root, _make_box(Vector3(0.2, 0.1, 1.15), accent, Color(0.0, 0.28, 0.45), 0.08, 0.16), Vector3(0.0, 0.38, 0.0))
	_attach(root, _make_box(Vector3(0.12, 0.08, 0.58), accent, Color(0.0, 0.3, 0.55), 0.04, 0.12), Vector3(0.0, 0.24, -1.38), Vector3(14.0, 0.0, 0.0))
	_attach(root, _make_box(Vector3(0.1, 0.08, 0.96), trim, Color(0.14, 0.74, 0.96), 0.0, 0.08), Vector3(0.0, 0.1, 0.18))
	_attach(root, _make_box(Vector3(0.08, 0.12, 0.34), accent, Color(0.08, 0.4, 0.68), 0.04, 0.12), Vector3(0.0, 0.44, -0.82), Vector3(18.0, 0.0, 0.0))
	_attach(root, _make_sphere(0.18, canopy, Color(0.12, 0.48, 0.75), 0.02, 0.08, 0.72), Vector3(0.0, 0.34, -0.46))
	_attach(root, _make_sphere(0.1, trim, Color(0.2, 0.8, 1.0)), Vector3(0.0, 0.22, 0.16))

	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.18, 0.03, 0.36), accent, Color(0.04, 0.38, 0.66), 0.02, 0.1), Vector3(side * 0.28, 0.14, -0.52), Vector3(0.0, 0.0, side * 24.0))
		_attach(root, _make_box(Vector3(0.68, 0.04, 0.72), dark, Color(0.0, 0.12, 0.2), 0.18, 0.26), Vector3(side * 0.72, 0.08, 0.18), Vector3(0.0, 0.0, side * 18.0))
		_attach(root, _make_box(Vector3(0.34, 0.03, 0.28), accent, Color(0.0, 0.4, 0.6), 0.06, 0.14), Vector3(side * 1.26, 0.1, 0.22), Vector3(0.0, 0.0, side * 30.0))
		_attach(root, _make_box(Vector3(0.22, 0.025, 0.18), trim, Color(0.16, 0.72, 0.98), 0.0, 0.08), Vector3(side * 0.36, 0.15, -0.86), Vector3(0.0, 0.0, side * 26.0))
		_attach(root, _make_box(Vector3(0.14, 0.1, 0.22), dark, Color(0.0, 0.14, 0.22), 0.14, 0.22), Vector3(side * 0.56, 0.12, 0.54), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_box(Vector3(0.08, 0.24, 0.42), dark, Color(0.0, 0.12, 0.2), 0.18, 0.28), Vector3(side * 0.28, 0.44, 1.08), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_box(Vector3(0.22, 0.03, 0.24), accent, Color(0.0, 0.34, 0.58), 0.04, 0.14), Vector3(side * 0.46, 0.1, 1.02), Vector3(0.0, 0.0, side * 14.0))
		_attach(root, _make_box(Vector3(0.08, 0.18, 0.18), trim, Color(0.14, 0.74, 0.96), 0.0, 0.08), Vector3(side * 1.46, 0.18, 0.42), Vector3(0.0, 0.0, side * 26.0))
		_attach(root, _make_cylinder(0.13, 0.72, dark, Color(0.0, 0.16, 0.26), 0.2, 0.24), Vector3(side * 0.24, 0.02, 1.06), Vector3(90.0, 0.0, 0.0))
		_attach(root, _make_sphere(0.06, trim, Color(0.18, 0.76, 1.0)), Vector3(side * 0.24, 0.02, 1.42))

	return root


func _build_wingman_root() -> Node3D:
	var root := Node3D.new()
	var dark := Color(0.08, 0.22, 0.34)
	var accent := Color(0.2, 0.72, 0.8)
	var trim := Color(0.72, 0.96, 1.0)

	_attach(root, _make_box(Vector3(0.18, 0.1, 0.58), dark, Color(0.0, 0.12, 0.18), 0.18, 0.24), Vector3(0.0, 0.12, 0.04))
	_attach(root, _make_box(Vector3(0.08, 0.12, 0.34), accent, Color(0.08, 0.52, 0.6), 0.02, 0.1), Vector3(0.0, 0.3, 0.18))
	_attach(root, _make_box(Vector3(0.06, 0.08, 0.18), trim, Color(0.16, 0.78, 0.64), 0.0, 0.06), Vector3(0.0, 0.22, -0.06))
	_attach(root, _make_sphere(0.09, trim, Color(0.12, 0.8, 0.58)), Vector3(0.0, 0.18, -0.3))
	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.24, 0.02, 0.18), dark, Color(0.0, 0.08, 0.16), 0.12, 0.2), Vector3(side * 0.26, 0.07, 0.08), Vector3(0.0, 0.0, side * 18.0))
		_attach(root, _make_box(Vector3(0.14, 0.02, 0.16), accent, Color(0.08, 0.52, 0.6), 0.02, 0.08), Vector3(side * 0.44, 0.06, 0.1), Vector3(0.0, 0.0, side * 28.0))
		_attach(root, _make_box(Vector3(0.06, 0.12, 0.12), accent, Color(0.08, 0.52, 0.6), 0.02, 0.1), Vector3(side * 0.52, 0.12, 0.08), Vector3(0.0, 0.0, side * 20.0))
		_attach(root, _make_box(Vector3(0.08, 0.03, 0.16), trim, Color(0.16, 0.78, 0.64), 0.0, 0.06), Vector3(side * 0.22, 0.1, -0.18), Vector3(10.0, 0.0, side * 10.0))
		_attach(root, _make_cylinder(0.05, 0.22, dark, Color(0.0, 0.12, 0.18), 0.16, 0.2), Vector3(side * 0.14, 0.04, 0.28), Vector3(90.0, 0.0, 0.0))
	return root


func _build_enemy_light_root() -> Node3D:
	var root := Node3D.new()
	var red := Color(0.46, 0.12, 0.16)
	var plate := Color(0.72, 0.16, 0.18)
	var glow := Color(1.0, 0.82, 0.3)

	_attach(root, _make_box(Vector3(0.22, 0.1, 0.68), red, Color(0.22, 0.04, 0.04), 0.14, 0.26), Vector3(0.0, 0.1, 0.02))
	_attach(root, _make_box(Vector3(0.1, 0.06, 0.24), plate, Color(0.28, 0.04, 0.02), 0.08, 0.18), Vector3(0.0, 0.12, -0.46), Vector3(18.0, 0.0, 0.0))
	_attach(root, _make_box(Vector3(0.06, 0.12, 0.16), plate, Color(0.24, 0.04, 0.02), 0.06, 0.16), Vector3(0.0, 0.2, 0.08))
	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.08, 0.02, 0.18), plate, Color(0.24, 0.04, 0.02), 0.04, 0.14), Vector3(side * 0.12, 0.14, -0.22), Vector3(20.0, 0.0, side * 22.0))
		_attach(root, _make_box(Vector3(0.24, 0.02, 0.16), plate, Color(0.22, 0.02, 0.02), 0.06, 0.16), Vector3(side * 0.34, 0.05, 0.08), Vector3(0.0, 0.0, side * 22.0))
		_attach(root, _make_box(Vector3(0.06, 0.08, 0.16), red, Color(0.18, 0.02, 0.02), 0.08, 0.18), Vector3(side * 0.22, 0.08, 0.54), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_sphere(0.05, glow, Color(1.0, 0.42, 0.08)), Vector3(side * 0.2, 0.08, 0.42))
	_attach(root, _make_sphere(0.08, glow, Color(1.0, 0.48, 0.08)), Vector3(0.0, 0.16, -0.24))
	return root


func _build_enemy_mid_root() -> Node3D:
	var root := Node3D.new()
	var orange := Color(0.48, 0.22, 0.08)
	var armor := Color(0.76, 0.36, 0.12)
	var visor := Color(1.0, 0.78, 0.34)

	_attach(root, _make_box(Vector3(0.34, 0.14, 1.0), orange, Color(0.2, 0.08, 0.02), 0.16, 0.24), Vector3(0.0, 0.15, 0.02))
	_attach(root, _make_box(Vector3(0.18, 0.1, 0.34), armor, Color(0.24, 0.08, 0.02), 0.08, 0.16), Vector3(0.0, 0.3, 0.46))
	_attach(root, _make_box(Vector3(0.14, 0.06, 0.24), visor, Color(1.0, 0.46, 0.08), 0.0, 0.05), Vector3(0.0, 0.23, -0.46))
	_attach(root, _make_box(Vector3(0.08, 0.16, 0.48), armor, Color(0.24, 0.08, 0.02), 0.06, 0.16), Vector3(0.0, 0.26, 0.1))
	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.14, 0.02, 0.24), armor, Color(0.24, 0.08, 0.02), 0.04, 0.14), Vector3(side * 0.24, 0.12, -0.18), Vector3(0.0, 0.0, side * 20.0))
		_attach(root, _make_box(Vector3(0.42, 0.03, 0.24), orange, Color(0.16, 0.06, 0.02), 0.12, 0.22), Vector3(side * 0.52, 0.06, 0.12), Vector3(0.0, 0.0, side * 16.0))
		_attach(root, _make_box(Vector3(0.24, 0.025, 0.26), armor, Color(0.24, 0.08, 0.02), 0.06, 0.16), Vector3(side * 0.92, 0.05, 0.18), Vector3(0.0, 0.0, side * 26.0))
		_attach(root, _make_box(Vector3(0.08, 0.04, 0.24), armor, Color(0.24, 0.08, 0.02), 0.04, 0.16), Vector3(side * 0.16, 0.12, -0.64), Vector3(12.0, side * 12.0, 0.0))
		_attach(root, _make_box(Vector3(0.12, 0.08, 0.18), armor, Color(0.24, 0.08, 0.02), 0.04, 0.14), Vector3(side * 0.72, 0.12, 0.72), Vector3(0.0, 0.0, side * 16.0))
		_attach(root, _make_cylinder(0.12, 0.56, orange, Color(0.24, 0.08, 0.02), 0.16, 0.22), Vector3(side * 0.5, 0.08, 0.44), Vector3(90.0, 0.0, 0.0))
		_attach(root, _make_sphere(0.05, visor, Color(1.0, 0.46, 0.08)), Vector3(side * 0.5, 0.08, 0.78))
	return root


func _build_enemy_heavy_root() -> Node3D:
	var root := Node3D.new()
	var purple := Color(0.24, 0.07, 0.32)
	var armor := Color(0.56, 0.14, 0.64)
	var core := Color(1.0, 0.78, 0.36)

	_attach(root, _make_box(Vector3(0.58, 0.2, 1.45), purple, Color(0.18, 0.04, 0.24), 0.22, 0.24), Vector3(0.0, 0.22, 0.08))
	_attach(root, _make_box(Vector3(0.34, 0.1, 0.72), armor, Color(0.16, 0.02, 0.28), 0.08, 0.18), Vector3(0.0, 0.44, -0.06))
	_attach(root, _make_box(Vector3(0.18, 0.18, 0.36), armor, Color(0.16, 0.02, 0.28), 0.08, 0.18), Vector3(0.0, 0.58, 0.42))
	_attach(root, _make_box(Vector3(0.12, 0.14, 0.62), armor, Color(0.16, 0.02, 0.28), 0.06, 0.16), Vector3(0.0, 0.12, -0.16))
	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.7, 0.04, 0.42), purple, Color(0.12, 0.02, 0.18), 0.16, 0.22), Vector3(side * 0.66, 0.08, 0.16), Vector3(0.0, 0.0, side * 12.0))
		_attach(root, _make_box(Vector3(0.24, 0.12, 0.54), armor, Color(0.16, 0.02, 0.28), 0.08, 0.2), Vector3(side * 0.62, 0.18, 0.08), Vector3(0.0, 0.0, side * 16.0))
		_attach(root, _make_box(Vector3(0.1, 0.08, 0.32), armor, Color(0.16, 0.02, 0.28), 0.06, 0.18), Vector3(side * 1.12, 0.12, 0.24), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_box(Vector3(0.1, 0.12, 0.22), armor, Color(0.16, 0.02, 0.28), 0.06, 0.18), Vector3(side * 0.54, 0.24, -0.18), Vector3(0.0, 0.0, side * 8.0))
		_attach(root, _make_box(Vector3(0.12, 0.18, 0.18), purple, Color(0.16, 0.02, 0.24), 0.12, 0.18), Vector3(side * 1.28, 0.18, 0.14), Vector3(0.0, 0.0, side * 18.0))
		_attach(root, _make_cylinder(0.15, 0.96, purple, Color(0.18, 0.04, 0.24), 0.22, 0.22), Vector3(side * 0.82, 0.16, -0.22), Vector3(90.0, 0.0, 0.0))
	_attach(root, _make_sphere(0.16, core, Color(1.0, 0.42, 0.08)), Vector3(0.0, 0.28, -0.34))
	_attach(root, _make_sphere(0.08, core, Color(1.0, 0.42, 0.08)), Vector3(0.0, 0.28, -0.58))
	return root


func _build_boss_root() -> Node3D:
	var root := Node3D.new()
	var dark := Color(0.24, 0.07, 0.16)
	var armor := Color(0.48, 0.12, 0.26)
	var trim := Color(0.76, 0.24, 0.38)
	var canopy := Color(0.36, 0.78, 1.0)
	var core := Color(1.0, 0.84, 0.94)

	_attach(root, _make_box(Vector3(1.8, 0.34, 3.4), dark, Color(0.16, 0.02, 0.08), 0.24, 0.24), Vector3(0.0, 0.42, 0.16))
	_attach(root, _make_box(Vector3(0.92, 0.18, 1.54), armor, Color(0.2, 0.04, 0.12), 0.08, 0.18), Vector3(0.0, 0.82, -0.35))
	_attach(root, _make_box(Vector3(0.36, 0.18, 0.82), trim, Color(0.4, 0.06, 0.14), 0.04, 0.16), Vector3(0.0, 1.18, -0.82))
	_attach(root, _make_box(Vector3(0.18, 0.1, 0.96), armor, Color(0.2, 0.04, 0.12), 0.06, 0.16), Vector3(0.0, 0.12, 1.46))
	_attach(root, _make_box(Vector3(0.48, 0.16, 0.66), trim, Color(0.4, 0.06, 0.14), 0.04, 0.16), Vector3(0.0, 0.38, -1.95), Vector3(12.0, 0.0, 0.0))
	_attach(root, _make_box(Vector3(0.18, 0.2, 1.18), armor, Color(0.2, 0.04, 0.12), 0.06, 0.16), Vector3(0.0, 0.12, 0.12))
	_attach(root, _make_box(Vector3(0.22, 0.26, 0.46), trim, Color(0.4, 0.06, 0.14), 0.04, 0.14), Vector3(0.0, 1.04, 0.16))
	_attach(root, _make_sphere(0.46, canopy, Color(0.2, 0.7, 1.0), 0.02, 0.08, 0.75), Vector3(0.0, 0.96, -1.18))
	_attach(root, _make_sphere(0.38, core, Color(1.0, 0.22, 0.46)), Vector3(0.0, 0.68, -0.18))

	for side in [-1.0, 1.0]:
		_attach(root, _make_box(Vector3(0.28, 0.08, 0.72), trim, Color(0.36, 0.06, 0.12), 0.04, 0.14), Vector3(side * 0.52, 0.42, -1.76), Vector3(16.0, side * 8.0, 0.0))
		_attach(root, _make_box(Vector3(1.2, 0.06, 0.82), dark, Color(0.12, 0.02, 0.08), 0.18, 0.22), Vector3(side * 1.2, 0.14, 0.46), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_box(Vector3(0.84, 0.05, 0.62), armor, Color(0.2, 0.04, 0.12), 0.08, 0.18), Vector3(side * 2.1, 0.16, 0.72), Vector3(0.0, 0.0, side * 20.0))
		_attach(root, _make_box(Vector3(0.42, 0.08, 1.08), armor, Color(0.2, 0.04, 0.12), 0.06, 0.18), Vector3(side * 2.46, 0.18, 0.28), Vector3(0.0, 0.0, side * 18.0))
		_attach(root, _make_box(Vector3(0.24, 0.18, 0.88), armor, Color(0.2, 0.04, 0.12), 0.08, 0.16), Vector3(side * 2.92, 0.28, 1.38), Vector3(0.0, 0.0, side * 14.0))
		_attach(root, _make_box(Vector3(0.14, 0.1, 0.64), trim, Color(0.4, 0.06, 0.14), 0.04, 0.14), Vector3(side * 0.58, 0.26, -2.12), Vector3(14.0, side * 10.0, 0.0))
		_attach(root, _make_box(Vector3(0.28, 0.16, 0.72), trim, Color(0.4, 0.06, 0.14), 0.04, 0.14), Vector3(side * 0.96, 0.62, -0.18), Vector3(0.0, 0.0, side * 8.0))
		_attach(root, _make_box(Vector3(0.12, 0.22, 0.22), trim, Color(0.4, 0.06, 0.14), 0.04, 0.14), Vector3(side * 1.84, 0.74, -0.2), Vector3(0.0, 0.0, side * 10.0))
		_attach(root, _make_cylinder(0.24, 0.92, dark, Color(0.18, 0.04, 0.08), 0.22, 0.2), Vector3(side * 2.46, 0.22, 2.42), Vector3(90.0, 0.0, 0.0))
		_attach(root, _make_sphere(0.14, core, Color(1.0, 0.22, 0.46)), Vector3(side * 2.46, 0.22, 2.92))

	return root
