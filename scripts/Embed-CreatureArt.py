"""Produce a private Studio place with local mesh data. The public build stays clean."""
import json
import math
from pathlib import Path
import re
import sys
from xml.etree import ElementTree


def read_mesh(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    vertices, faces, colors = (data[key] for key in ("Vertices", "Faces", "Colors"))
    if len(vertices) % 3 or len(colors) % 3 or len(faces) % 4 or len(faces) > 80000:
        raise ValueError(f"Malformed mesh: {path.name}")
    if not vertices or not faces or any(type(n) not in (int, float) or not math.isfinite(n) for n in vertices + colors):
        raise ValueError(f"Invalid vertex data: {path.name}")
    limits = [len(vertices) // 3] * 3 + [len(colors) // 3]
    if any(type(n) is not int or not 1 <= n <= limits[i % 4] for i, n in enumerate(faces)):
        raise ValueError(f"Invalid triangle index: {path.name}")
    for name, palette in data.get("Palettes", {}).items():
        if name not in {"Dourada", "ArcoIris"} or len(palette) != len(colors) or any(
            type(channel) not in (int, float) or not 0 <= channel <= 1 for channel in palette
        ):
            raise ValueError(f"Invalid material palette: {path.name} {name}")
    return json.dumps(data, separators=(",", ":"))


def main():
    place, source_dir, output = map(Path, sys.argv[1:])
    files = sorted(source_dir.glob("*.json"))
    if not files:
        raise SystemExit("No private mesh data. Run Export-CreatureArt.py in Blender first.")
    if place.resolve() == output.resolve() or output.name != "ThrowASphere-ComModelos.rbxlx":
        raise SystemExit("Refusing to put private artwork into the public place.")
    tree = ElementTree.parse(place)
    target = tree.find(".//Item/Properties/string[@name='Name'][.='CreatureMeshes']/../..")
    if target is None or target.get("class") != "Folder":
        raise SystemExit("Missing CreatureMeshes folder in the base build.")
    for file in files:
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", file.stem):
            raise ValueError(f"Invalid creature ID: {file.stem}")
        mesh = read_mesh(file)
        module = ElementTree.SubElement(target, "Item", {"class": "ModuleScript", "referent": "Private_" + file.stem})
        props = ElementTree.SubElement(module, "Properties")
        ElementTree.SubElement(props, "string", name="Name").text = file.stem
        ElementTree.SubElement(props, "string", name="Source").text = "--!strict\nreturn [==[" + mesh + "]==]\n"
    tree.write(output, encoding="utf-8", xml_declaration=True)
    print(f"Private Studio build: {len(files)} meshes in {output}")


if __name__ == "__main__":
    main()
