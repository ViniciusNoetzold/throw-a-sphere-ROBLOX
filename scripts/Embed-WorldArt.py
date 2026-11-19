"""Embed reviewed native Roblox art in the creature-art build only.

Usage: python scripts/Embed-WorldArt.py PLACE NATIVE_SOURCE OUTPUT
       python scripts/Embed-WorldArt.py PLACE NATIVE_SOURCE --in-place

No models are uploaded. Sources can come from the bundled art or source checkout.
"""
import argparse
from collections import Counter
import math
import os
from pathlib import Path
import re
import tempfile
from xml.etree import ElementTree as ET


PRIVATE_PLACE = "ThrowASphere-ComModelos.rbxlx"
ORB_NAMES = (
    "Orbe001_Comum", "Orbe020_Reforcada", "Orbe040_Turbo", "Orbe060_Aco",
    "Orbe080_Vulcanica", "Orbe100_Esmeralda", "Orbe120_Glacial",
    "Orbe140_Plasma", "Orbe160_Cosmica", "Orbe180_Dourada", "Orbe200_Prisma",
)
GYM_NAMES = ("GaragemNivel01",) + tuple(f"GaragemNivel{level}" for level in range(10, 201, 10))
PACKS = (
    ("OrbesDeResgate_v2.rbxmx", "Folder", "OrbesDeResgate", "ImportedOrbModels", ORB_NAMES),
    ("GaragensDeTreino_Nivel200.rbxmx", "Folder", "GaragensDeTreino", "ImportedGyms", GYM_NAMES),
    ("ReservaNaturalGrande.rbxmx", "Model", "ReservaNaturalGrande", "ImportedReserve", None),
)
COMMON = {"Name": "string", "Archivable": "bool", "AttributesSerialize": "BinaryString", "Tags": "BinaryString"}
PROPERTIES = {
    "Folder": {},
    "Model": {"PrimaryPart": "Ref", "WorldPivotData": "OptionalCoordinateFrame", "WorldPivot": "CoordinateFrame"},
    "Part": {
        "CFrame": "CoordinateFrame", "PivotOffset": "CoordinateFrame", "size": "Vector3",
        "Color3uint8": "Color3uint8", "Material": "token", "shape": "token",
        "Anchored": "bool", "CanCollide": "bool", "CanQuery": "bool", "CanTouch": "bool",
        "CastShadow": "bool", "Massless": "bool", "Transparency": "float", "RootPriority": "int",
        **{surface + "Surface": "token" for surface in ("Top", "Bottom", "Left", "Right", "Front", "Back")},
    },
    "Attachment": {"CFrame": "CoordinateFrame"},
    "IntValue": {"Value": "int64"},
    "StringValue": {"Value": "string"},
    "Weld": {"C0": "CoordinateFrame", "C1": "CoordinateFrame", "Part0": "Ref", "Part1": "Ref"},
    "SurfaceLight": {"Color": "Color3", "Angle": "float", "Brightness": "float", "Range": "float", "Face": "token"},
}
CLASSES = (
    {"Folder", "Model", "Part", "Attachment", "IntValue", "StringValue", "Weld"},
    {"Folder", "Model", "Part", "Attachment", "SurfaceLight"},
    {"Folder", "Model", "Part", "Attachment"},
)
NUMERIC_TAGS = {"float", "int", "int64", "token", "Color3uint8", "X", "Y", "Z", "R", "G", "B"} | {
    f"R{row}{column}" for row in range(3) for column in range(3)
}
VALUE_TAGS = set(COMMON.values()) | {tag for props in PROPERTIES.values() for tag in props.values()} | NUMERIC_TAGS | {"CFrame"}
EXTERNAL_ID = re.compile(r"(?:rbxasset(?:id)?://|rbxhttp://|https?://|www\.)", re.IGNORECASE)
NULL_REFS = {"null", "nil"}


def item_name(item):
    prop = item.find("Properties/string[@name='Name']")
    return prop.text if prop is not None else None


def set_property(item, tag, name, value):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    prop = props.find(f"*[@name='{name}']")
    if prop is None:
        prop = ET.SubElement(props, tag, name=name)
    elif prop.tag != tag:
        raise ValueError(f"Wrong type for {name}")
    prop.text = value


def parse_xml(path):
    contents = path.read_bytes()
    # Assets need no DTD, entities, or file/network resolution.
    if re.search(br"<!\s*(?:DOCTYPE|ENTITY)\b", contents, re.IGNORECASE):
        raise ValueError(f"DTD/entities are forbidden: {path.name}")
    root = ET.fromstring(contents)
    if root.tag != "roblox" or root.get("version") != "4":
        raise ValueError(f"Expected Roblox XML v4: {path.name}")
    return ET.ElementTree(root)


def validate_references(root):
    items = list(root.iter("Item"))
    referents = [item.get("referent") for item in items]
    if any(not value or value in NULL_REFS for value in referents) or len(set(referents)) != len(referents):
        raise ValueError("Missing or duplicate Roblox referent")
    known = set(referents)
    for ref in root.iter("Ref"):
        if ref.text not in known | NULL_REFS:
            raise ValueError(f"External/dangling reference: {ref.text}")


def read_pack(source_dir, index):
    filename, expected_class, expected_name, imported_name, expected_models = PACKS[index]
    root = parse_xml(source_dir / filename).getroot()
    for child in root:
        if child.tag != "Item" and not (child.tag == "External" and child.text in NULL_REFS):
            raise ValueError(f"Unexpected root data in {filename}: {child.tag}")
    roots = root.findall("Item")
    if len(roots) != 1 or roots[0].get("class") != expected_class or item_name(roots[0]) != expected_name:
        raise ValueError(f"Unexpected model root in {filename}")
    model = roots[0]
    if expected_models is not None:
        children = model.findall("Item")
        if any(child.get("class") != "Model" for child in children) or Counter(map(item_name, children)) != Counter(expected_models):
            raise ValueError(f"Unexpected model catalog in {filename}")
    validate_references(model)
    for item in model.iter("Item"):
        cls = item.get("class")
        if cls not in CLASSES[index]:
            raise ValueError(f"Forbidden/unexpected class {cls} in {filename}")
        if any(child.tag not in {"Properties", "Item"} for child in item):
            raise ValueError(f"Unexpected item payload in {filename}")
        props = item.findall("Properties")
        if len(props) != 1:
            raise ValueError(f"Missing/duplicate Properties in {filename}")
        allowed = COMMON | PROPERTIES[cls]
        seen = set()
        for prop in props[0]:
            key = prop.get("name")
            if key in seen or key not in allowed or prop.tag != allowed[key]:
                raise ValueError(f"Unexpected property {cls}.{key} ({prop.tag}) in {filename}")
            seen.add(key)
            for value in prop.iter():
                if value.tag not in VALUE_TAGS:
                    raise ValueError(f"Unexpected value type {value.tag} in {filename}")
                if value.tag in NUMERIC_TAGS and (value.text is None or not math.isfinite(float(value.text))):
                    raise ValueError(f"Non-finite geometry/property in {filename}")
                if value.tag == "string" and value.text and EXTERNAL_ID.search(value.text):
                    raise ValueError(f"External asset ID/URL in {filename}")
        if not item_name(item):
            raise ValueError(f"Missing item name in {filename}")
    removed_welds = 0
    if index == 0:
        for parent in model.iter("Item"):
            for child in list(parent.findall("Item")):
                if child.get("class") == "Weld":
                    parent.remove(child)
                    removed_welds += 1
        for part in model.iter("Item"):
            if part.get("class") == "Part":
                for key, value in {"Anchored": "true", "CanCollide": "false", "CanQuery": "false", "CanTouch": "false"}.items():
                    set_property(part, "bool", key, value)
    set_property(model, "string", "Name", imported_name)
    validate_references(model)
    return model, removed_welds


def direct_child(parent, name, cls=None):
    matches = [item for item in parent.findall("Item") if item_name(item) == name]
    if len(matches) > 1 or (matches and cls and matches[0].get("class") != cls):
        raise ValueError(f"Missing/ambiguous destination: {name}")
    return matches[0] if matches else None


def make_item(cls, name):
    item = ET.Element("Item", {"class": cls})
    set_property(item, "string", "Name", name)
    return item


def embed_world_art(place, source_dir, output=None, *, in_place=False):
    place, source_dir = Path(place).resolve(), Path(source_dir).resolve()
    output = Path(output).resolve() if output is not None else place
    if place.name != PRIVATE_PLACE or output.name != PRIVATE_PLACE:
        raise ValueError("Native art belongs only in ThrowASphere-ComModelos.rbxlx")
    if output == place and not in_place:
        raise ValueError("Overwriting the input requires explicit --in-place")
    if in_place and output != place:
        raise ValueError("--in-place cannot target a different output")
    # The source is parsed independently before the destination is touched.
    packs = [read_pack(source_dir, index) for index in range(len(PACKS))]
    tree = parse_xml(place)
    root = tree.getroot()
    replicated = direct_child(root, "ReplicatedStorage", "ReplicatedStorage")
    shared = direct_child(replicated, "Shared", "Folder") if replicated is not None else None
    creatures = direct_child(shared, "CreatureMeshes", "Folder") if shared is not None else None
    if creatures is None or not any(child.get("class") == "ModuleScript" for child in creatures.findall("Item")):
        raise ValueError("Input must contain the creature-art build")
    server = direct_child(root, "ServerStorage", "ServerStorage")
    if server is None:
        server = make_item("ServerStorage", "ServerStorage")
        root.append(server)
    destinations = (shared, server, server)
    for target, (model, _) in zip(destinations, packs):
        existing = direct_child(target, item_name(model), model.get("class"))
        if existing is not None:
            target.remove(existing)
    known = {item.get("referent") for item in root.iter("Item") if item.get("referent")}
    serial = 0

    def new_referent():
        nonlocal serial
        while True:
            serial += 1
            value = f"NativeArt_{serial:08d}"
            if value not in known:
                known.add(value)
                return value

    if server.get("referent") is None:
        server.set("referent", new_referent())
    for target, (model, _) in zip(destinations, packs):
        mapping = {}
        for item in model.iter("Item"):
            original = item.get("referent")
            mapping[original] = new_referent()
            item.set("referent", mapping[original])
        for ref in model.iter("Ref"):
            if ref.text not in NULL_REFS:
                ref.text = mapping[ref.text]
        target.append(model)
    validate_references(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(mode="wb", dir=output.parent, prefix=".native-art-", suffix=".tmp", delete=False) as temporary:
            temporary_path = Path(temporary.name)
            tree.write(temporary, encoding="utf-8", xml_declaration=True)
            temporary.flush()
            os.fsync(temporary.fileno())
        validate_references(parse_xml(temporary_path).getroot())
        os.replace(temporary_path, output)
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    counts = {item_name(model): sum(item.get("class") == "Part" for item in model.iter("Item")) for model, _ in packs}
    return {"orb_models": len(ORB_NAMES), "gym_models": len(GYM_NAMES), "reserve_models": 1, "parts": counts, "removed_welds": packs[0][1]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("place", type=Path)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output", nargs="?", type=Path)
    parser.add_argument("--in-place", action="store_true", help="Atomically replace the input art build")
    args = parser.parse_args()
    try:
        counts = embed_world_art(args.place, args.source_dir, args.output, in_place=args.in_place)
    except (ValueError, OSError, ET.ParseError) as error:
        parser.exit(1, f"Native artwork rejected: {error}\n")
    print(f"Bundled native artwork: {counts}; output {args.output or args.place}")


if __name__ == "__main__":
    main()
