"""Exercise the native Roblox XML importer independently of WorldArtService."""
import argparse
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("embed_world_art", ROOT / "scripts/Embed-WorldArt.py")
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
NATIVE = next((folder for folder in (
    ROOT / ".tools/modelospokemonroblox/modelos_roblox",
    ROOT / "build/bundled-art/modelos_roblox",
    ROOT / "art/creatures/local/modelos_roblox",
) if all((folder / pack[0]).is_file() for pack in art.PACKS)), None)


def add_item(parent, cls, name, referent):
    item = ET.SubElement(parent, "Item", {"class": cls, "referent": referent})
    art.set_property(item, "string", "Name", name)
    return item


def cframe(item, name):
    cf = ET.SubElement(item.find("Properties"), "CoordinateFrame", name=name)
    values = {"X": "12.5", "Y": "2", "Z": "-7", **{f"R{a}{b}": str(int(a == b)) for a in range(3) for b in range(3)}}
    for axis, value in values.items():
        ET.SubElement(cf, axis).text = value


def make_base(path, *, with_creatures=True):
    root = ET.Element("roblox", version="4")
    replicated = add_item(root, "ReplicatedStorage", "ReplicatedStorage", "NativeArt_00000001")
    shared = add_item(replicated, "Folder", "Shared", "Shared")
    meshes = add_item(shared, "Folder", "CreatureMeshes", "Meshes")
    if with_creatures:
        module = add_item(meshes, "ModuleScript", "TestCreature", "TestCreature")
        art.set_property(module, "string", "Source", "return '{}'")
    ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=True)


def make_sources(folder):
    for index, (filename, cls, name, _, expected_models) in enumerate(art.PACKS):
        root = ET.Element("roblox", version="4")
        ET.SubElement(root, "External").text = "null"
        top = add_item(root, cls, name, "Root")
        models = [add_item(top, "Model", value, f"Model_{number}") for number, value in enumerate(expected_models)] if expected_models else [top]
        for number, model in enumerate(models):
            part_ref = f"Part_{number}"
            name = "Nucleo" if index == 0 else "PivoArremesso" if index == 1 else "PivoEntrada"
            part = add_item(model, "Part", name, part_ref)
            cframe(part, "CFrame")
            cframe(part, "PivotOffset")
            art.set_property(part, "bool", "CanCollide", "true")
            art.set_property(model, "Ref", "PrimaryPart", part_ref)
            art.set_property(model, "BinaryString", "AttributesSerialize", "AQIDBA==")
            if index == 0:
                weld = add_item(part, "Weld", "VisualWeld", f"Weld_{number}")
                art.set_property(weld, "Ref", "Part0", part_ref)
                art.set_property(weld, "Ref", "Part1", part_ref)
        ET.ElementTree(root).write(folder / filename, encoding="utf-8", xml_declaration=True)


class EmbedWorldArtTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="embed-world-art-tests-")
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.source = self.folder / "native"
        self.source.mkdir()
        self.place = self.folder / art.PRIVATE_PLACE
        make_base(self.place)
        make_sources(self.source)

    def mutate_orbs(self, callback):
        path = self.source / art.PACKS[0][0]
        tree = ET.parse(path)
        callback(tree.getroot())
        tree.write(path, encoding="utf-8", xml_declaration=True)

    def test_remapped_refs_pivots_metadata_and_visual_flags(self):
        original = self.place.read_bytes()
        output = self.folder / "separate" / art.PRIVATE_PLACE
        result = art.embed_world_art(self.place, self.source, output)
        self.assertEqual(self.place.read_bytes(), original)
        self.assertEqual((result["orb_models"], result["gym_models"], result["reserve_models"], result["removed_welds"]), (11, 21, 1, 11))
        root = ET.parse(output).getroot()
        art.validate_references(root)
        self.assertEqual(sum(item.get("class") == "ModuleScript" for item in root.iter("Item")), 1)
        orbs = root.find(".//Item/Properties/string[@name='Name'][.='ImportedOrbModels']/../..")
        self.assertEqual(tuple(map(art.item_name, orbs.findall("Item"))), art.ORB_NAMES)
        self.assertFalse(any(item.get("class") == "Weld" for item in orbs.iter("Item")))
        for part in orbs.iter("Item"):
            if part.get("class") == "Part":
                for key, expected in {"Anchored": "true", "CanCollide": "false", "CanQuery": "false", "CanTouch": "false"}.items():
                    self.assertEqual(part.find(f"Properties/bool[@name='{key}']").text, expected)
                self.assertEqual(part.find("Properties/CoordinateFrame[@name='PivotOffset']/X").text, "12.5")
        reserve = root.find(".//Item/Properties/string[@name='Name'][.='ImportedReserve']/../..")
        self.assertEqual(reserve.get("class"), "Model")
        self.assertEqual(reserve.find("Properties/BinaryString").text, "AQIDBA==")
        self.assertEqual(reserve.find("Item/Properties/bool[@name='CanCollide']").text, "true")
        primary = reserve.find("Properties/Ref[@name='PrimaryPart']").text
        self.assertEqual(art.item_name(next(item for item in reserve.iter("Item") if item.get("referent") == primary)), "PivoEntrada")

    def test_explicit_atomic_in_place_is_repeatable(self):
        with self.assertRaisesRegex(ValueError, "--in-place"):
            art.embed_world_art(self.place, self.source)
        art.embed_world_art(self.place, self.source, in_place=True)
        art.embed_world_art(self.place, self.source, in_place=True)
        root = ET.parse(self.place).getroot()
        art.validate_references(root)
        for name in ("ImportedOrbModels", "ImportedGyms", "ImportedReserve"):
            self.assertEqual(sum(art.item_name(item) == name for item in root.iter("Item")), 1)

    def test_public_output_and_art_free_input_rejected(self):
        for output in (self.folder / "ThrowASphere.rbxlx", self.folder / "game.rbxlx"):
            with self.subTest(output=output), self.assertRaisesRegex(ValueError, "only in"):
                art.embed_world_art(self.place, self.source, output)
            self.assertFalse(output.exists())
        make_base(self.place, with_creatures=False)
        with self.assertRaisesRegex(ValueError, "creature-art"):
            art.embed_world_art(self.place, self.source, in_place=True)

    def test_scripts_external_content_and_nonfinite_properties_rejected(self):
        changes = (
            lambda r: add_item(r.find("Item/Item"), "Script", "Payload", "Payload"),
            lambda r: art.set_property(r.find("Item/Item"), "string", "Name", "https://example.com/asset"),
            lambda r: art.set_property(r.find("Item/Item/Item"), "Content", "TextureID", "rbxassetid://123"),
            lambda r: art.set_property(r.find("Item/Item/Item"), "float", "Transparency", "NaN"),
        )
        for change in changes:
            with self.subTest(change=change):
                make_sources(self.source)
                self.mutate_orbs(change)
                before = self.place.read_bytes()
                with self.assertRaises(ValueError):
                    art.embed_world_art(self.place, self.source, in_place=True)
                self.assertEqual(self.place.read_bytes(), before)

    def test_dangling_duplicate_and_unknown_catalog_ids_rejected(self):
        changes = (
            lambda r: art.set_property(r.find("Item/Item"), "Ref", "PrimaryPart", "ExternalPart"),
            lambda r: r.find("Item/Item/Item").set("referent", "Root"),
            lambda r: art.set_property(r.find("Item/Item"), "string", "Name", "UnexpectedOrb"),
        )
        for change in changes:
            with self.subTest(change=change):
                make_sources(self.source)
                self.mutate_orbs(change)
                with self.assertRaises(ValueError):
                    art.embed_world_art(self.place, self.source, in_place=True)

    def test_atomic_write_failure_keeps_original_output(self):
        before = self.place.read_bytes()
        with mock.patch.object(art.os, "replace", side_effect=OSError("simulated disk failure")):
            with self.assertRaises(OSError):
                art.embed_world_art(self.place, self.source, in_place=True)
        self.assertEqual(self.place.read_bytes(), before)
        self.assertEqual(list(self.folder.glob(".native-art-*.tmp")), [])

    def test_entity_declarations_rejected(self):
        path = self.source / art.PACKS[0][0]
        path.write_text('<!DOCTYPE roblox [<!ENTITY test "unsafe">]><roblox version="4"/>', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "DTD/entities"):
            art.embed_world_art(self.place, self.source, in_place=True)

    @unittest.skipUnless(NATIVE is not None, "native models unavailable in checkout/bundled restoration")
    def test_real_native_xml_models(self):
        public = ROOT / "game/ThrowASphere.rbxlx"
        before = public.read_bytes() if public.exists() else None
        result = art.embed_world_art(self.place, NATIVE, in_place=True)
        self.assertEqual(result["parts"], {"ImportedOrbModels": 3729, "ImportedGyms": 13630, "ImportedReserve": 804})
        self.assertEqual(result["removed_welds"], 3718)
        art.validate_references(ET.parse(self.place).getroot())
        if before is not None:
            self.assertEqual(public.read_bytes(), before)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", help="Accepted for Test.ps1; these tests run pure Python")
    args, remaining = parser.parse_known_args()
    unittest.main(argv=[sys.argv[0], *remaining])
