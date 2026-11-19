"""Export the collaborator's original meshes to GLB and local Roblox mesh data.

Run with Blender, in background mode with --factory-startup and --disable-autoexec.
Only the explicitly reviewed source builders below are executed.
"""
import json
from pathlib import Path
import runpy
import sys

import bpy


BUILDERS = {
    "Sproutling": ("07_Sproutling_Tatuzinho_Folha_Blender.py", "build_sproutling"),
    "Leviathorn": ("06_Leviathorn_Dragao_Abissal_Leviathan_Blender.py", "build_leviathorn"),
    "Ignisovereign": ("03_Ignisovereign_Rei_Leao_Solar_Ignishishi_Blender.py", "build_ignisovereign"),
}


def mesh_data(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    coordinates = [obj.matrix_world @ vertex.co for vertex in mesh.vertices]
    # Blender is Z-up, with these models facing -Y. Roblox is Y-up and faces -Z.
    coords = [(v.x, v.z, v.y) for v in coordinates]
    low = tuple(min(v[axis] for v in coords) for axis in range(3))
    high = tuple(max(v[axis] for v in coords) for axis in range(3))
    center = tuple((a + b) / 2 for a, b in zip(low, high))
    extents = tuple(b - a for a, b in zip(low, high))
    scale = min(3.65 / max(extents[0], extents[2]), 4.2 / extents[1])
    vertices = [round((v[axis] - center[axis]) * scale, 5) for v in coords for axis in range(3)]
    # Swapping axes reverses winding, so reverse the last two triangle vertices.
    faces = [entry for f in mesh.loop_triangles for entry in (f.vertices[0] + 1, f.vertices[2] + 1, f.vertices[1] + 1, f.material_index + 1)]
    colors = [round(channel, 4) for mat in mesh.materials for channel in mat.diffuse_color[:3]]
    if len(mesh.loop_triangles) > 20000:
        raise ValueError(f"{obj.name} has {len(mesh.loop_triangles)} triangles")
    return {"Vertices": vertices, "Faces": faces, "Colors": colors}, tuple(round(x * scale, 2) for x in extents)


def main():
    source, output, glbs = map(Path, sys.argv[sys.argv.index("--") + 1:])
    output.mkdir(parents=True, exist_ok=True)
    glbs.mkdir(parents=True, exist_ok=True)
    for creature_id, (filename, builder) in BUILDERS.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        module = runpy.run_path(str(source / "scripts_blender_criaturas" / filename))
        obj = module[builder](name=creature_id)
        bpy.context.view_layer.update()
        data, studs = mesh_data(obj)
        (output / f"{creature_id}.json").write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(glbs / f"{creature_id}.glb"), use_selection=True, export_format="GLB")
        print(f"EXPORT {creature_id}: {len(data['Vertices']) // 3} vertices, "
              f"{len(data['Faces']) // 4} triangles, bounds {studs} studs")


if __name__ == "__main__":
    main()
