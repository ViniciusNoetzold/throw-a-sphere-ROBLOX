"""Export the collaborator's original meshes to GLB and local Roblox mesh data.

Run with Blender, in background mode with --factory-startup and --disable-autoexec.
Only the explicitly reviewed source builders below are executed.
"""
import csv
import json
from inspect import signature
from pathlib import Path
import runpy
import sys

import bpy


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
    source_arg, output_arg, glbs_arg, *workers = sys.argv[sys.argv.index("--") + 1:]
    source, output, glbs = map(Path, (source_arg, output_arg, glbs_arg))
    worker, jobs = map(int, workers[0].split("/")) if workers else (0, 1)
    if not 0 <= worker < jobs:
        raise ValueError("Specify a worker in the form 0/3, 1/3, or 2/3.")
    with Path(__file__).with_name("CreaturePack.csv").open(encoding="utf-8", newline="") as manifest:
        records = list(csv.DictReader(manifest))
    output.mkdir(parents=True, exist_ok=True)
    glbs.mkdir(parents=True, exist_ok=True)
    for record in records[worker::jobs]:
        creature_id, filename, builder = (record[key] for key in ("id", "filename", "builder"))
        reference = float(record["reference_studs"] or 0)
        height = HEIGHTS.get(creature_id, max(.45, min(5.4, reference * .69)))
        output_file = output / f"{creature_id}.json"
        if "resume" in workers and output_file.is_file():
            previous = json.loads(output_file.read_text(encoding="utf-8"))
            if "ReferenceScale" in previous:
                continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        module = runpy.run_path(str(source / "scripts_blender_criaturas" / filename))
        make = module[builder]
        obj = make(name=creature_id)
        bpy.context.view_layer.update()
        data, studs = mesh_data(obj, height)
        config = module.get("CONFIG", {})
        scales = config.get("scales", {})
        normal_scale = scales.get("Normal", 1)
        authored_sizes = {
            "Grande": scales.get("Grande"),
            "Enorme": scales.get("Gigante", config.get("huge_scale")),
            "Titanica": scales.get("Colossal"),
        }
        measure = max(studs) if int(filename.split("_")[0]) in {23, 24, 95, 130} else studs[1]
        if reference > 0:
            data["ReferenceScale"] = round(reference / measure, 4)
        data["Scales"] = {name: round(scale / normal_scale, 4) for name, scale in authored_sizes.items() if scale}
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(glbs / f"{creature_id}.glb"), use_selection=True, export_format="GLB")
        data["Palettes"] = {}
        data["Shapes"] = {}
        for mutation, kwargs in palettes(make).items():
            variant = make(name=f"{creature_id}_{mutation}", **kwargs)
            bpy.context.view_layer.update()
            alternate, _ = mesh_data(variant, height)
            if alternate["Vertices"] != data["Vertices"] or alternate["Faces"] != data["Faces"]:
                data["Shapes"][mutation] = alternate
            else:
                data["Palettes"][mutation] = alternate["Colors"]
        output_file.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
        print(f"EXPORT {creature_id}: {len(data['Vertices']) // 3} vertices, "
              f"{len(data['Faces']) // 4} triangles, bounds {studs} studs")


if __name__ == "__main__":
    main()
