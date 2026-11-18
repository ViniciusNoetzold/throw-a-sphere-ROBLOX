"""
Blender_Gerador_Arvore_e_Pet_VoxelStuds.py
==========================================
Script autossuficiente para Blender (`bpy`) que gera modelos 3D estilizados
no padrão dos jogos pesquisados (Throw a Seed / Steal An Egg / Throw Food / Ride Pets):
  1. Árvore Voxel Modular (estilo Golden Apple / Celestial Tree)
  2. Terreno em Grade Xadrez (4x4 blocos bicolores)
  3. Pet Cúbico/Low-Poly Estilizado (base de montaria/guardião)

Especificação Técnica Aplicada:
  - Shading 100% Flat (`bpy.ops.object.shade_flat()`)
  - Materiais de cor sólida (`use_nodes = False`, `mat.diffuse_color = rgba`)
  - Geometria facetada e modular com Bevel final aplicado
  - Função de variações automáticas (`generate_variations()`)

Como executar no Blender:
  1. Abra o Blender (3.x ou 4.x).
  2. Vá na aba `Scripting`, clique em `New`, cole este script e aperte `Run Script`.
  3. Exporte em `.fbx` ou `.obj` para importar no Roblox Studio como `MeshPart`.
"""

import math
import bpy


CONFIG = {
    "bevel_width": 0.02,
    "bevel_segments": 2,
    "palette": {
        "grass_a": (0.298, 0.851, 0.169, 1.0),     # #4CD92B
        "grass_b": (0.247, 0.753, 0.133, 1.0),     # #3FC022
        "trunk": (0.471, 0.282, 0.165, 1.0),       # #78482A
        "leaves_dark": (0.086, 0.639, 0.290, 1.0), # #16A34A
        "leaves_mid": (0.133, 0.773, 0.369, 1.0),  # #22C55E
        "leaves_top": (0.290, 0.871, 0.502, 1.0),  # #4ADE80
        "gold_fruit": (0.980, 0.800, 0.082, 1.0),  # #FACC15
        "pet_body": (0.976, 0.451, 0.086, 1.0),    # #F97316 (Raposa/Dinossauro)
        "pet_belly": (0.996, 0.941, 0.541, 1.0),   # #FEF08A
        "pet_horn": (0.118, 0.161, 0.231, 1.0),    # #1E293B
        "pet_eye": (0.133, 0.827, 0.933, 1.0),     # #22D3EE
    },
    "tree_dims": {
        "trunk_radius1": 0.65,
        "trunk_radius2": 0.45,
        "trunk_height": 2.6,
    },
}


def clean_existing_object(obj_name: str):
    """Remove objeto existente com o mesmo nome para permitir reexecução limpa."""
    obj = bpy.data.objects.get(obj_name)
    if obj is not None:
        bpy.data.objects.remove(obj, do_unlink=True)


def get_or_create_solid_material(name: str, rgba: tuple):
    """Cria material em cor sólida sem shader nodes (ideal para acabamento flat/voxel)."""
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)
    mat.use_nodes = False
    mat.diffuse_color = rgba
    return mat


def assign_material(obj, mat_name: str, rgba: tuple):
    mat = get_or_create_solid_material(mat_name, rgba)
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def create_cube(name: str, size: tuple, location: tuple, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_flat()
    return obj


def create_cone(name: str, vertices: int, radius1: float, radius2: float, depth: float, location: tuple, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.shade_flat()
    return obj


def join_and_bevel(parts: list, final_name: str, location: tuple = (0.0, 0.0, 0.0)):
    """Une todas as primitivas, aplica Bevel angular para chanfro faceted e ativa shade_flat."""
    clean_existing_object(final_name)
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()

    joined = bpy.context.active_object
    joined.name = final_name
    joined.location = location

    bevel = joined.modifiers.new(name="Bevel", type="BEVEL")
    bevel.width = CONFIG["bevel_width"]
    bevel.segments = CONFIG["bevel_segments"]
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(30)
    bpy.ops.object.modifier_apply(modifier="Bevel")
    bpy.ops.object.shade_flat()
    return joined


def build_checkered_ground(name: str = "Terreno_Xadrez_4x4", location=(0.0, 0.0, -0.25)):
    parts = []
    tile_size = 2.0
    for r in range(4):
        for c in range(4):
            px = (c - 1.5) * tile_size
            py = (r - 1.5) * tile_size
            tile = create_cube(f"_tmp_tile_{r}_{c}", (tile_size, tile_size, 0.5), (px, py, 0.0))
            is_a = (r + c) % 2 == 0
            assign_material(
                tile,
                "Mat_Grass_A" if is_a else "Mat_Grass_B",
                CONFIG["palette"]["grass_a"] if is_a else CONFIG["palette"]["grass_b"],
            )
            parts.append(tile)
    return join_and_bevel(parts, name, location)


def build_voxel_tree(name: str = "Arvore_Voxel_Seed", location=(0.0, 0.0, 0.0), scale=1.0, fruit_rgba=None):
    pal = CONFIG["palette"]
    dims = CONFIG["tree_dims"]
    parts = []

    # Tronco facetado (cone 6 lados afinando para cima)
    trunk = create_cone(
        "_tmp_trunk",
        vertices=6,
        radius1=dims["trunk_radius1"],
        radius2=dims["trunk_radius2"],
        depth=dims["trunk_height"],
        location=(0.0, 0.0, dims["trunk_height"] * 0.5),
    )
    assign_material(trunk, "Mat_Trunk", pal["trunk"])
    parts.append(trunk)

    # Camadas da copa (estilo blocos empilhados / pinheiro voxel)
    layers = [
        ((3.4, 3.4, 1.1), (0.0, 0.0, 2.7), (0, 0, math.radians(0)), "Mat_Leaves_Dark", pal["leaves_dark"]),
        ((2.6, 2.6, 1.0), (0.0, 0.0, 3.6), (0, 0, math.radians(15)), "Mat_Leaves_Mid", pal["leaves_mid"]),
        ((1.7, 1.7, 0.9), (0.0, 0.0, 4.4), (0, 0, math.radians(30)), "Mat_Leaves_Top", pal["leaves_top"]),
    ]
    for i, (sz, loc, rot, mname, rgba) in enumerate(layers):
        canopy = create_cube(f"_tmp_canopy_{i}", sz, loc, rot)
        assign_material(canopy, mname, rgba)
        parts.append(canopy)

    # Frutas cúbicas estilo Golden Apple Tree
    f_col = fruit_rgba if fruit_rgba is not None else pal["gold_fruit"]
    for i, floc in enumerate([(1.45, 0.9, 2.35), (-1.35, -0.8, 2.55), (0.85, -1.25, 3.35)]):
        fruit = create_cube(f"_tmp_fruit_{i}", (0.55, 0.55, 0.55), floc)
        assign_material(fruit, "Mat_Fruit_Custom", f_col)
        parts.append(fruit)

    tree = join_and_bevel(parts, name, location)
    tree.scale = (scale, scale, scale)
    return tree


def build_blocky_pet_mount(name: str = "Pet_Montaria_LowPoly", location=(4.5, 0.0, 0.0)):
    """Gera uma criatura/montaria quadrúpede estilizada (inspirada em Steal An Egg / Ride Pets)."""
    pal = CONFIG["palette"]
    parts = []

    # Corpo principal + barriga
    body = create_cube("_tmp_body", (1.6, 2.4, 1.3), (0.0, 0.0, 1.45))
    assign_material(body, "Mat_Pet_Body", pal["pet_body"])
    parts.append(body)

    belly = create_cube("_tmp_belly", (1.2, 2.1, 0.35), (0.0, 0.0, 0.85))
    assign_material(belly, "Mat_Pet_Belly", pal["pet_belly"])
    parts.append(belly)

    # Cabeça + focinho + chifres + olhos brilhantes
    head = create_cube("_tmp_head", (1.45, 1.3, 1.25), (0.0, -1.45, 2.15))
    assign_material(head, "Mat_Pet_Body", pal["pet_body"])
    parts.append(head)

    snout = create_cube("_tmp_snout", (0.95, 0.75, 0.6), (0.0, -2.25, 1.9))
    assign_material(snout, "Mat_Pet_Belly", pal["pet_belly"])
    parts.append(snout)

    for idx, sx in enumerate([-0.45, 0.45]):
        horn = create_cone("_tmp_horn_" + str(idx), 6, 0.22, 0.04, 0.85, (sx, -1.35, 3.05), (math.radians(-20), 0, 0))
        assign_material(horn, "Mat_Pet_Horn", pal["pet_horn"])
        parts.append(horn)

        eye = create_cube("_tmp_eye_" + str(idx), (0.24, 0.14, 0.24), (sx, -2.08, 2.35))
        assign_material(eye, "Mat_Pet_Eye", pal["pet_eye"])
        parts.append(eye)

    # 4 Patas facetadas (cones de 6 lados invertidos)
    leg_coords = [(-0.6, -0.85), (0.6, -0.85), (-0.6, 0.85), (0.6, 0.85)]
    for i, (lx, ly) in enumerate(leg_coords):
        leg = create_cone(f"_tmp_leg_{i}", 6, 0.32, 0.24, 0.95, (lx, ly, 0.48))
        assign_material(leg, "Mat_Pet_Body", pal["pet_body"])
        parts.append(leg)

    # Cauda afunilada inclinada
    tail = create_cone("_tmp_tail", 6, 0.42, 0.08, 1.7, (0.0, 1.75, 1.8), (math.radians(55), 0, 0))
    assign_material(tail, "Mat_Pet_Body", pal["pet_body"])
    parts.append(tail)

    return join_and_bevel(parts, name, location)


def generate_variations():
    """Gera o cenário base e 3 variações de escala/mutação para visualização imediata."""
    build_checkered_ground("Terreno_Xadrez_4x4", location=(0.0, 0.0, -0.25))

    # Variação 1: Árvore Normal
    build_voxel_tree("Arvore_Normal", location=(-3.2, -1.2, 0.0), scale=0.85)
    # Variação 2: Árvore Huge (Frutas Diamante/Ciano)
    build_voxel_tree(
        "Arvore_Huge_Diamond",
        location=(-3.2, 2.2, 0.0),
        scale=1.25,
        fruit_rgba=(0.220, 0.741, 0.973, 1.0),
    )
    # Montaria Low-Poly / Voxel
    build_blocky_pet_mount("Pet_Montaria_LowPoly", location=(2.2, 0.0, 0.0))


if __name__ == "__main__":
    generate_variations()
    print("Modelos gerados com sucesso! Prontos para exportar em FBX/OBJ para o Roblox Studio.")
