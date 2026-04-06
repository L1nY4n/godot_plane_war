import bpy
import math
import os


ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT_DIR, "assets", "models")


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)


def ensure_out_dir():
    os.makedirs(OUT_DIR, exist_ok=True)


def make_material(name, color, emission=None, metallic=0.2, roughness=0.35, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, alpha)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 2.0
    if alpha < 0.999:
        mat.blend_method = "BLEND"
        bsdf.inputs["Alpha"].default_value = alpha
    return mat


def set_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def parent_keep(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def add_empty(name):
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    return obj


def add_cube(name, location, scale, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    set_material(obj, mat)
    return obj


def add_uv_sphere(name, location, radius, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location, segments=24, ring_count=12)
    obj = bpy.context.object
    obj.name = name
    set_material(obj, mat)
    return obj


def add_cylinder(name, location, radius, depth, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location, rotation=rotation, vertices=20)
    obj = bpy.context.object
    obj.name = name
    set_material(obj, mat)
    return obj


def add_capsule(name, location, radius, depth, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (1.0, 1.0, max(depth / (radius * 2.0), 1.0))
    obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    set_material(obj, mat)
    return obj


def export_root(root, filename):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT_DIR, filename),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
    )


def build_player():
    reset_scene()
    root = add_empty("player_ship")
    dark = make_material("player_dark", (0.08, 0.14, 0.2), emission=(0.0, 0.12, 0.2), metallic=0.25, roughness=0.28)
    accent = make_material("player_accent", (0.2, 0.48, 0.72), emission=(0.0, 0.35, 0.55), metallic=0.08, roughness=0.16)
    canopy = make_material("player_canopy", (0.4, 0.82, 1.0), emission=(0.12, 0.45, 0.7), metallic=0.02, roughness=0.08, alpha=0.72)
    glow = make_material("player_glow", (0.7, 0.95, 1.0), emission=(0.2, 0.8, 1.0), metallic=0.0, roughness=0.04)

    parts = [
        add_cube("body", (0, 0.18, 0.0), (0.42, 0.18, 1.3), dark),
        add_cube("nose", (0, 0.28, -1.34), (0.22, 0.12, 0.46), accent),
        add_cube("wing", (0, 0.08, 0.18), (1.12, 0.04, 0.52), dark),
        add_uv_sphere("canopy", (0, 0.32, -0.35), 0.22, canopy),
        add_uv_sphere("core", (0, 0.18, 0.2), 0.12, glow),
    ]
    for side in (-1, 1):
        parts.append(add_cube(f"tail_fin_{side}", (side * 0.32, 0.4, 0.92), (0.1, 0.24, 0.34), dark))
        parts.append(add_cylinder(f"engine_{side}", (side * 0.28, 0.05, 0.92), 0.13, 0.55, accent, rotation=(math.radians(90), 0, 0)))
    for part in parts:
        parent_keep(part, root)
    export_root(root, "player_ship.glb")


def build_wingman():
    reset_scene()
    root = add_empty("wingman_drone")
    dark = make_material("wingman_dark", (0.08, 0.22, 0.36), emission=(0.0, 0.12, 0.18), metallic=0.22, roughness=0.28)
    eye = make_material("wingman_eye", (0.55, 0.95, 1.0), emission=(0.12, 0.75, 0.55), metallic=0.0, roughness=0.06)
    parts = [
        add_cube("body", (0, 0.12, 0), (0.23, 0.1, 0.5), dark),
        add_cube("wing", (0, 0.06, 0.1), (0.5, 0.025, 0.22), dark),
        add_uv_sphere("eye", (0, 0.18, -0.32), 0.1, eye),
    ]
    for part in parts:
        parent_keep(part, root)
    export_root(root, "wingman_drone.glb")


def build_enemy_light():
    reset_scene()
    root = add_empty("enemy_light")
    red = make_material("enemy_light_red", (0.45, 0.1, 0.14), emission=(0.45, 0.08, 0.05), metallic=0.18, roughness=0.36)
    eye = make_material("enemy_light_eye", (1.0, 0.82, 0.35), emission=(1.0, 0.5, 0.08), metallic=0.0, roughness=0.05)
    parts = [
        add_cube("body", (0, 0.12, 0), (0.31, 0.11, 0.58), red),
        add_cube("wing", (0, 0.06, 0.12), (0.58, 0.02, 0.17), red),
        add_uv_sphere("eye", (0, 0.18, -0.28), 0.11, eye),
    ]
    for part in parts:
        parent_keep(part, root)
    export_root(root, "enemy_light.glb")


def build_enemy_mid():
    reset_scene()
    root = add_empty("enemy_mid")
    orange = make_material("enemy_mid_orange", (0.48, 0.22, 0.08), emission=(0.45, 0.18, 0.04), metallic=0.2, roughness=0.34)
    visor = make_material("enemy_mid_visor", (1.0, 0.76, 0.32), emission=(1.0, 0.48, 0.1), metallic=0.0, roughness=0.05)
    parts = [
        add_cube("body", (0, 0.15, 0), (0.48, 0.14, 0.88), orange),
        add_cube("wing", (0, 0.06, 0.1), (0.9, 0.03, 0.38), orange),
        add_cube("visor", (0, 0.24, -0.52), (0.17, 0.07, 0.25), visor),
    ]
    for side in (-1, 1):
        parts.append(add_cylinder(f"engine_{side}", (side * 0.62, 0.1, 0.44), 0.12, 0.45, orange, rotation=(math.radians(90), 0, 0)))
    for part in parts:
        parent_keep(part, root)
    export_root(root, "enemy_mid.glb")


def build_enemy_heavy():
    reset_scene()
    root = add_empty("enemy_heavy")
    purple = make_material("enemy_heavy_purple", (0.24, 0.07, 0.32), emission=(0.32, 0.08, 0.42), metallic=0.28, roughness=0.3)
    core = make_material("enemy_heavy_core", (1.0, 0.72, 0.35), emission=(1.0, 0.42, 0.1), metallic=0.0, roughness=0.05)
    parts = [
        add_cube("body", (0, 0.22, 0), (0.78, 0.2, 1.25), purple),
        add_cube("wing", (0, 0.08, 0.12), (1.35, 0.04, 0.68), purple),
        add_uv_sphere("core", (0, 0.28, -0.38), 0.18, core),
    ]
    for side in (-1, 1):
        parts.append(add_cylinder(f"cannon_{side}", (side * 0.86, 0.14, -0.22), 0.16, 0.75, purple, rotation=(math.radians(90), 0, 0)))
    for part in parts:
        parent_keep(part, root)
    export_root(root, "enemy_heavy.glb")


def build_boss():
    reset_scene()
    root = add_empty("boss_flagship")
    dark = make_material("boss_dark", (0.24, 0.07, 0.16), emission=(0.24, 0.02, 0.08), metallic=0.28, roughness=0.28)
    armor = make_material("boss_armor", (0.42, 0.12, 0.24), emission=(0.32, 0.04, 0.16), metallic=0.18, roughness=0.22)
    core = make_material("boss_core", (1.0, 0.84, 0.92), emission=(1.0, 0.24, 0.52), metallic=0.0, roughness=0.04)
    canopy = make_material("boss_canopy", (0.36, 0.78, 1.0), emission=(0.2, 0.7, 1.0), metallic=0.02, roughness=0.08, alpha=0.75)
    parts = [
        add_cube("hull", (0, 0.45, 0), (2.4, 0.42, 3.0), dark),
        add_cube("wing", (0, 0.14, 0.4), (3.7, 0.06, 1.0), dark),
        add_cube("armor", (0, 0.82, -0.4), (1.0, 0.21, 1.4), armor),
        add_uv_sphere("canopy", (0, 0.9, -1.15), 0.52, canopy),
        add_uv_sphere("core", (0, 0.68, -0.15), 0.42, core),
    ]
    for side in (-1, 1):
        blade = add_cube(f"blade_{side}", (side * 2.35, 0.18, 0.55), (0.6, 0.11, 1.15), armor, rotation=(0, 0, math.radians(side * 20)))
        thruster = add_cylinder(f"thruster_{side}", (side * 2.1, 0.22, 2.15), 0.28, 0.72, dark, rotation=(math.radians(90), 0, 0))
        parts.extend([blade, thruster])
    for part in parts:
        parent_keep(part, root)
    export_root(root, "boss_flagship.glb")


def build_player_bullet():
    reset_scene()
    root = add_empty("player_bullet")
    glow = make_material("player_bullet_glow", (0.45, 0.88, 1.0), emission=(0.3, 0.85, 1.0), metallic=0.0, roughness=0.05)
    part = add_capsule("bullet", (0, 0, 0), 0.08, 0.5, glow, rotation=(math.radians(90), 0, 0))
    parent_keep(part, root)
    export_root(root, "player_bullet.glb")


def build_enemy_bullet():
    reset_scene()
    root = add_empty("enemy_bullet")
    glow = make_material("enemy_bullet_glow", (1.0, 0.35, 0.18), emission=(1.0, 0.55, 0.1), metallic=0.0, roughness=0.05)
    part = add_uv_sphere("bullet", (0, 0, 0), 0.14, glow)
    parent_keep(part, root)
    export_root(root, "enemy_bullet.glb")


def build_missile():
    reset_scene()
    root = add_empty("homing_missile")
    orange = make_material("missile_orange", (0.95, 0.58, 0.22), emission=(1.0, 0.32, 0.12), metallic=0.0, roughness=0.08)
    body = add_capsule("body", (0, 0, 0), 0.11, 0.65, orange, rotation=(math.radians(90), 0, 0))
    parent_keep(body, root)
    for side in (-1, 1):
        fin = add_cube(f"fin_{side}", (side * 0.12, 0, 0.18), (0.025, 0.09, 0.12), orange)
        parent_keep(fin, root)
    export_root(root, "homing_missile.glb")


def build_pickups():
    reset_scene()
    root = add_empty("pickup_weapon")
    weapon_mat = make_material("pickup_weapon", (1.0, 0.82, 0.25), emission=(1.0, 0.7, 0.18), metallic=0.0, roughness=0.18)
    cube = add_cube("weapon", (0, 0, 0), (0.22, 0.22, 0.22), weapon_mat, rotation=(math.radians(45), 0, math.radians(45)))
    parent_keep(cube, root)
    export_root(root, "pickup_weapon.glb")

    reset_scene()
    root = add_empty("pickup_heal")
    heal_mat = make_material("pickup_heal", (0.3, 1.0, 0.45), emission=(0.15, 0.7, 0.22), metallic=0.0, roughness=0.1)
    h1 = add_cube("h1", (0, 0, 0), (0.12, 0.4, 0.12), heal_mat)
    h2 = add_cube("h2", (0, 0, 0), (0.4, 0.12, 0.12), heal_mat)
    parent_keep(h1, root)
    parent_keep(h2, root)
    export_root(root, "pickup_heal.glb")

    reset_scene()
    root = add_empty("pickup_shield")
    shield_mat = make_material("pickup_shield", (0.3, 0.65, 1.0), emission=(0.2, 0.6, 1.0), metallic=0.0, roughness=0.08, alpha=0.45)
    shield = add_uv_sphere("shield", (0, 0, 0), 0.34, shield_mat)
    parent_keep(shield, root)
    export_root(root, "pickup_shield.glb")

    reset_scene()
    root = add_empty("pickup_bomb")
    bomb_mat = make_material("pickup_bomb", (1.0, 0.22, 0.18), emission=(1.0, 0.32, 0.12), metallic=0.0, roughness=0.08)
    bomb = add_uv_sphere("bomb", (0, 0, 0), 0.28, bomb_mat)
    parent_keep(bomb, root)
    export_root(root, "pickup_bomb.glb")

    reset_scene()
    root = add_empty("pickup_missile")
    missile_mat = make_material("pickup_missile", (1.0, 0.55, 0.22), emission=(1.0, 0.35, 0.12), metallic=0.0, roughness=0.08)
    missile = add_capsule("missile", (0, 0, 0), 0.12, 0.5, missile_mat, rotation=(math.radians(90), 0, 0))
    parent_keep(missile, root)
    export_root(root, "pickup_missile.glb")


def main():
    ensure_out_dir()
    build_player()
    build_wingman()
    build_enemy_light()
    build_enemy_mid()
    build_enemy_heavy()
    build_boss()
    build_player_bullet()
    build_enemy_bullet()
    build_missile()
    build_pickups()


main()
