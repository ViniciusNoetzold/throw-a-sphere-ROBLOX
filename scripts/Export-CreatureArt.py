"""Export the collaborator's original meshes to GLB and local Roblox mesh data.

Run with Blender, in background mode with --factory-startup and --disable-autoexec.
Only the explicitly reviewed source builders below are executed.
"""
import json
from inspect import signature
from pathlib import Path
import runpy
import sys

import bpy


BUILDERS = {
    "Pyrokit": ("01_Pyrokit_Leao_de_Brasa_Pyroar_Blender.py", "build_pyrokit_lion"),
    "Blazefox": ("02_Blazefox_Raposa_Chamejante_Braixen_Blender.py", "build_blazefox"),
    "Sproutling": ("07_Sproutling_Tatuzinho_Folha_Blender.py", "build_sproutling"),
    "Leviathorn": ("06_Leviathorn_Dragao_Abissal_Leviathan_Blender.py", "build_leviathorn"),
    "Ignisovereign": ("03_Ignisovereign_Rei_Leao_Solar_Ignishishi_Blender.py", "build_ignisovereign"),
    "Bulbavine": ("001_Bulbavine_Bulbasaur_5Variacoes_Blender.py", "build_bulbavine"),
    "Floradine": ("002_Floradine_Ivysaur_5Variacoes_Blender.py", "build_floradine"),
    "Jungleking": ("003_Jungleking_Venusaur_5Variacoes_Blender.py", "build_jungleking"),
    "Embernewt": ("004_Embernewt_Charmander_5Variacoes_Blender.py", "build_embernewt"),
    "Flareclaw": ("005_Flareclaw_Charmeleon_5Variacoes_Blender.py", "build_flareclaw"),
    "Ignidrake": ("006_Ignidrake_Charizard_5Variacoes_Blender.py", "build_ignidrake"),
    "Shellsplash": ("007_Shellsplash_Squirtle_5Variacoes_Blender.py", "build_shellsplash"),
    "Tidecrest": ("008_Tidecrest_Wartortle_5Variacoes_Blender.py", "build_tidecrest"),
    "Hydrocannon": ("009_Hydrocannon_Blastoise_5Variacoes_Blender.py", "build_hydrocannon"),
    "Silkworm": ("010_Silkworm_Caterpie_5Variacoes_Blender.py", "build_silkworm"),
    "Chrysalid": ("011_Chrysalid_Metapod_5Variacoes_Blender.py", "build_chrysalid"),
    "Flutterwing": ("012_Flutterwing_Butterfree_5Variacoes_Blender.py", "build_flutterwing"),
    "Stinglarva": ("013_Stinglarva_Weedle_5Variacoes_Blender.py", "build_stinglarva"),
    "Ambercocoon": ("014_Ambercocoon_Kakuna_5Variacoes_Blender.py", "build_ambercocoon"),
    "Lancewasp": ("015_Lancewasp_Beedrill_5Variacoes_Blender.py", "build_lancewasp"),
    "Gustfinch": ("016_Gustfinch_Pidgey_5Variacoes_Blender.py", "build_gustfinch"),
    "Skytalon": ("017_Skytalon_Pidgeotto_5Variacoes_Blender.py", "build_skytalon"),
    "Galehawk": ("018_Galehawk_Pidgeot_5Variacoes_Blender.py", "build_galehawk"),
}


# Approximate base height in studs next to a player avatar. Keep original proportions.
HEIGHTS = {
    "Pyrokit": 3.6, "Blazefox": 3.4, "Sproutling": 1.8, "Leviathorn": 5.0, "Ignisovereign": 5.5,
    "Bulbavine": 2.3, "Floradine": 3.2, "Jungleking": 5.5, "Embernewt": 2.0, "Flareclaw": 3.5,
    "Ignidrake": 5.5, "Shellsplash": 1.7, "Tidecrest": 3.2, "Hydrocannon": 5.0,
    "Silkworm": 1.0, "Chrysalid": 2.1, "Flutterwing": 3.5,
    "Stinglarva": 1.0, "Ambercocoon": 1.9, "Lancewasp": 3.3,
    "Gustfinch": 1.0, "Skytalon": 3.6, "Galehawk": 4.8,
}


def mesh_data(obj, height):
    mesh = obj.data
    mesh.calc_loop_triangles()
    coordinates = [obj.matrix_world @ vertex.co for vertex in mesh.vertices]
    # Blender is Z-up, with these models facing -Y. Roblox is Y-up and faces -Z.
    coords = [(v.x, v.z, v.y) for v in coordinates]
    low = tuple(min(v[axis] for v in coords) for axis in range(3))
    high = tuple(max(v[axis] for v in coords) for axis in range(3))
    center = tuple((a + b) / 2 for a, b in zip(low, high))
    extents = tuple(b - a for a, b in zip(low, high))
    scale = min(8.0 / max(extents[0], extents[2]), height / extents[1])
    vertices = [round((v[axis] - center[axis]) * scale, 5) for v in coords for axis in range(3)]
    # Swapping axes reverses winding, so reverse the last two triangle vertices.
    faces = [entry for f in mesh.loop_triangles for entry in (f.vertices[0] + 1, f.vertices[2] + 1, f.vertices[1] + 1, f.material_index + 1)]
    colors = [round(channel, 4) for mat in mesh.materials for channel in mat.diffuse_color[:3]]
    if len(mesh.loop_triangles) > 20000:
        raise ValueError(f"{obj.name} has {len(mesh.loop_triangles)} triangles")
    return {"Vertices": vertices, "Faces": faces, "Colors": colors}, tuple(round(x * scale, 2) for x in extents)


def palettes(builder):
    parameters = signature(builder).parameters
    if "variant" in parameters:
        return {"Dourada": {"variant": "DouradaSuperRara"}, "ArcoIris": {"variant": "Shiny"}}
    if "is_golden" in parameters:
        return {"Dourada": {"is_golden": True}}
    return {"ArcoIris": {"is_shiny": True}} if "is_shiny" in parameters else {}


def main():
    source, output, glbs = map(Path, sys.argv[sys.argv.index("--") + 1:])
    output.mkdir(parents=True, exist_ok=True)
    glbs.mkdir(parents=True, exist_ok=True)
    for creature_id, (filename, builder) in BUILDERS.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        module = runpy.run_path(str(source / "scripts_blender_criaturas" / filename))
        make = module[builder]
        obj = make(name=creature_id)
        bpy.context.view_layer.update()
        data, studs = mesh_data(obj, HEIGHTS[creature_id])
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(glbs / f"{creature_id}.glb"), use_selection=True, export_format="GLB")
        data["Palettes"] = {}
        for mutation, kwargs in palettes(make).items():
            variant = make(name=f"{creature_id}_{mutation}", **kwargs)
            bpy.context.view_layer.update()
            alternate, _ = mesh_data(variant, HEIGHTS[creature_id])
            if alternate["Vertices"] != data["Vertices"] or alternate["Faces"] != data["Faces"]:
                raise ValueError(f"{creature_id} {mutation} changes geometry or material slots")
            data["Palettes"][mutation] = alternate["Colors"]
        (output / f"{creature_id}.json").write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
        print(f"EXPORT {creature_id}: {len(data['Vertices']) // 3} vertices, "
              f"{len(data['Faces']) // 4} triangles, bounds {studs} studs")


if __name__ == "__main__":
    main()
