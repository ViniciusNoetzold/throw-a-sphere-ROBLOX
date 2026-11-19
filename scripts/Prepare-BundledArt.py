"""Pack, verify, or restore the team's redistributable creature and world models.

Defaults: art/packs/{creatures,world}.zip -> art/creatures/local/.
Restore only extracts an exact manifest allowlist and never executes Blender scripts.
"""
import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import tempfile
from xml.etree import ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
REVISION = "96a5c6fee9784d144a48d41425ccb01113324b8f"
SOURCE_URL = "https://github.com/nicolasdoeringsantos/modelospokemonroblox.git"
NATIVE_FILES = (
    "GaragensDeTreino_Nivel200.rbxmx", "OrbesDeResgate_v2.rbxmx",
    "ReservaNaturalGrande.rbxmx", "VitrineDosOrbes_v2.rbxlx",
)
ORB_NAMES = (
    "Orbe001_Comum", "Orbe020_Reforcada", "Orbe040_Turbo", "Orbe060_Aco",
    "Orbe080_Vulcanica", "Orbe100_Esmeralda", "Orbe120_Glacial",
    "Orbe140_Plasma", "Orbe160_Cosmica", "Orbe180_Dourada", "Orbe200_Prisma",
)
GYM_NAMES = ("GaragemNivel01",) + tuple(f"GaragemNivel{level}" for level in range(10, 201, 10))
NATIVE_CLASSES = {
    "Folder", "Model", "Part", "Attachment", "IntValue", "StringValue", "Weld",
    "SurfaceLight", "Workspace", "SurfaceGui", "TextLabel", "PointLight",
    "SpawnLocation", "Camera", "Lighting",
}
TIMESTAMP = (2026, 11, 19, 0, 0, 0)
MAX_FILE_BYTES = 64 * 1024 * 1024
MAX_UNPACKED_BYTES = 256 * 1024 * 1024
MAX_ZIP_BYTES = 99 * 1024 * 1024
MANIFEST_NAME = "manifest.json"
LOCK_NAME = "art-lock.json"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def decode_json(data):
    return json.loads(data, object_pairs_hook=unique_object)


def safe_relative(name):
    path = PurePosixPath(name)
    if not name or "\\" in name or ":" in name or path.is_absolute() or any(part in {"", ".", ".."} for part in name.split("/")) or str(path) != name:
        raise ValueError(f"Unsafe archive path: {name!r}")
    return path


def catalog():
    path = ROOT / "scripts/CreaturePack.csv"
    raw = path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    rows = list(csv.DictReader(io.StringIO(raw.decode("utf-8"))))
    ids = [row["id"] for row in rows]
    builders = [row["filename"] for row in rows]
    if len(rows) != 148 or len(set(ids)) != 148 or len(set(builders)) != 148:
        raise ValueError("CreaturePack.csv must identify exactly 148 unique species/builders")
    for row in rows:
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", row["id"]) or safe_relative(row["filename"]).name != row["filename"] or not row["filename"].endswith(".py"):
            raise ValueError("Invalid creature ID/Blender filename")
    return rows, sha256(raw)


def expected_paths(kind, rows):
    if kind == "world":
        return {f"modelos_roblox/{name}" for name in NATIVE_FILES}
    return {path for row in rows for path in (
        f"data/{row['id']}.json", f"glb/{row['id']}.glb",
        f"blender-source/scripts_blender_criaturas/{row['filename']}",
    )}


def native_name(item):
    name = item.find("Properties/string[@name='Name']")
    return name.text if name is not None else None


def validate_payload(name, data):
    if not data or len(data) > MAX_FILE_BYTES:
        raise ValueError(f"Empty/oversized payload: {name}")
    if name.endswith(".py"):
        # Syntax validation does not import or execute the artist's builder.
        compile(data.decode("utf-8-sig"), name, "exec")
    elif name.endswith(".json"):
        mesh = decode_json(data)
        if not isinstance(mesh, dict) or not all(isinstance(mesh.get(key), list) and mesh[key] for key in ("Vertices", "Faces", "Colors")):
            raise ValueError(f"Invalid creature geometry document: {name}")
    elif name.endswith(".glb"):
        if len(data) < 20 or struct.unpack_from("<4sII", data) != (b"glTF", 2, len(data)):
            raise ValueError(f"Invalid GLB header: {name}")
        offset, chunks = 12, []
        while offset < len(data):
            if offset + 8 > len(data):
                raise ValueError(f"Truncated GLB chunk: {name}")
            length, chunk_type = struct.unpack_from("<II", data, offset)
            offset += 8
            if length % 4 or offset + length > len(data):
                raise ValueError(f"Invalid GLB chunk size: {name}")
            chunks.append(chunk_type)
            if len(chunks) == 1:
                document = decode_json(data[offset:offset + length])
                if chunk_type != 0x4E4F534A or not isinstance(document, dict) or not isinstance(document.get("asset"), dict) or document["asset"].get("version") != "2.0":
                    raise ValueError(f"Missing GLB 2.0 JSON chunk: {name}")
            offset += length
        if not chunks or offset != len(data):
            raise ValueError(f"Incomplete GLB: {name}")
    elif name.endswith((".rbxmx", ".rbxlx")):
        if re.search(br"<!\s*(?:DOCTYPE|ENTITY)\b", data, re.IGNORECASE):
            raise ValueError(f"DTD/entities are forbidden: {name}")
        root = ET.fromstring(data)
        if root.tag != "roblox" or root.get("version") != "4":
            raise ValueError(f"Invalid Roblox XML: {name}")
        items = list(root.iter("Item"))
        references = [item.get("referent") for item in items]
        if any(not ref or ref in {"null", "nil"} for ref in references) or len(set(references)) != len(references):
            raise ValueError(f"Invalid native referents: {name}")
        known = set(references) | {"null", "nil"}
        if any(item.get("class") not in NATIVE_CLASSES for item in items) or any(ref.text not in known for ref in root.iter("Ref")):
            raise ValueError(f"Unexpected class or external reference in {name}")
        if any(element.tag in {"Content", "ContentId", "ProtectedString", "SharedString"} or (element.text and re.search(r"(?:rbxasset(?:id)?://|rbxhttp://|https?://)", element.text, re.IGNORECASE)) for element in root.iter()):
            raise ValueError(f"Unexpected script/asset content in {name}")
        models = {native_name(item) for item in items if item.get("class") == "Model"}
        required = GYM_NAMES if name.endswith(NATIVE_FILES[0]) else ORB_NAMES if name.endswith((NATIVE_FILES[1], NATIVE_FILES[3])) else ("ReservaNaturalGrande",)
        if not set(required).issubset(models):
            raise ValueError(f"Missing expected native models: {name}")


def source_revision(source):
    git = source / ".git"
    head = (git / "HEAD").read_text(encoding="utf-8").strip()
    if head.startswith("ref: "):
        ref = head[5:]
        safe_relative(ref)
        path = git / ref
        if path.is_file():
            head = path.read_text(encoding="utf-8").strip()
        else:
            packed = (git / "packed-refs").read_text(encoding="utf-8").splitlines()
            head = next((line.split()[0] for line in packed if line.endswith(" " + ref)), "")
    if head != REVISION:
        raise ValueError(f"Source checkout must be pinned to {REVISION}; found {head}")


def zip_info(name):
    info = zipfile.ZipInfo(name, date_time=TIMESTAMP)
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | 0o644) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    return info


def pack(packs_dir, source, local, kinds):
    rows, catalog_hash = catalog()
    source_revision(source)
    packs_dir.mkdir(parents=True, exist_ok=True)
    staged = []
    try:
        for kind in kinds:
            expected = expected_paths(kind, rows)
            if kind == "creatures":
                for folder, suffix in (("data", ".json"), ("glb", ".glb")):
                    actual = {f"{folder}/{p.name}" for p in (local / folder).glob("*" + suffix)}
                    wanted = {name for name in expected if name.startswith(folder + "/")}
                    if actual != wanted:
                        raise ValueError(f"Missing/unexpected {folder} files: {sorted(actual ^ wanted)}")
            temporary = tempfile.NamedTemporaryFile(dir=packs_dir, prefix=".pack-", suffix=".tmp", delete=False)
            temp_path = Path(temporary.name)
            temporary.close()
            staged.append((temp_path, packs_dir / f"{kind}.zip"))
            entries = {}
            with zipfile.ZipFile(temp_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
                for name in sorted(expected):
                    relative = safe_relative(name)
                    if name.startswith("blender-source/"):
                        path = source / "scripts_blender_criaturas" / relative.name
                    elif kind == "world":
                        path = source / "modelos_roblox" / relative.name
                    else:
                        path = local.joinpath(*relative.parts)
                    data = path.read_bytes()
                    validate_payload(name, data)
                    entries[name] = {"size": len(data), "sha256": sha256(data)}
                    archive.writestr(zip_info(name), data, compresslevel=9)
                manifest = {"format": 1, "kind": kind, "source": SOURCE_URL, "revision": REVISION, "catalog_sha256": catalog_hash, "entries": entries}
                archive.writestr(zip_info(MANIFEST_NAME), json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode(), compresslevel=9)
            if temp_path.stat().st_size > MAX_ZIP_BYTES:
                raise ValueError(f"Archive exceeds the per-file GitHub budget: {kind}")
            verify_archive(temp_path, kind, rows, catalog_hash)
        for temporary, destination in staged:
            os.replace(temporary, destination)
    finally:
        for temporary, _ in staged:
            temporary.unlink(missing_ok=True)
    result = verify(packs_dir, kinds, check_lock=False)
    lock = {"format": 1, "source": SOURCE_URL, "revision": REVISION, "catalog_sha256": catalog_hash, "packs": {}}
    lock_path = packs_dir / LOCK_NAME
    if lock_path.is_file():
        old = decode_json(lock_path.read_bytes())
        if isinstance(old, dict) and isinstance(old.get("packs"), dict) and all(old.get(key) == value for key, value in lock.items() if key != "packs"):
            lock["packs"].update(old.get("packs", {}))
    lock["packs"].update({kind: {"archive": f"{kind}.zip", **record} for kind, record in result.items()})
    temporary = tempfile.NamedTemporaryFile(dir=packs_dir, prefix=".lock-", suffix=".tmp", delete=False)
    temp_path = Path(temporary.name)
    try:
        with temporary:
            temporary.write((json.dumps(lock, sort_keys=True, indent=2) + "\n").encode())
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temp_path, lock_path)
    finally:
        temp_path.unlink(missing_ok=True)
    return verify(packs_dir, kinds)


def verify_archive(path, kind, rows, catalog_hash):
    if path.stat().st_size > MAX_ZIP_BYTES:
        raise ValueError(f"Oversized archive: {path.name}")
    expected = expected_paths(kind, rows)
    with zipfile.ZipFile(path) as archive:
        infos = archive.infolist()
        names = [info.filename for info in infos]
        if len(names) != len(set(names)) or set(names) != expected | {MANIFEST_NAME}:
            raise ValueError(f"Unexpected/duplicate archive entries: {path.name}")
        if sum(info.file_size for info in infos) > MAX_UNPACKED_BYTES:
            raise ValueError(f"Archive expands beyond its budget: {path.name}")
        for info in infos:
            safe_relative(info.filename)
            mode = stat.S_IFMT(info.external_attr >> 16)
            if info.is_dir() or mode not in {0, stat.S_IFREG} or info.flag_bits & 1 or info.file_size > MAX_FILE_BYTES or info.compress_type not in {zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED}:
                raise ValueError(f"Unsafe archive member: {info.filename}")
        if archive.getinfo(MANIFEST_NAME).file_size > 1024 * 1024:
            raise ValueError("Oversized manifest")
        manifest = decode_json(archive.read(MANIFEST_NAME))
        if not isinstance(manifest, dict) or manifest.get("format") != 1 or manifest.get("kind") != kind or manifest.get("source") != SOURCE_URL or manifest.get("revision") != REVISION or manifest.get("catalog_sha256") != catalog_hash:
            raise ValueError(f"Unexpected provenance/catalog: {path.name}")
        entries = manifest.get("entries")
        if not isinstance(entries, dict) or set(entries) != expected:
            raise ValueError(f"Invalid entry manifest: {path.name}")
        for name in sorted(expected):
            record = entries[name]
            if not isinstance(record, dict) or type(record.get("size")) is not int or record["size"] != archive.getinfo(name).file_size or not re.fullmatch(r"[a-f0-9]{64}", str(record.get("sha256", ""))):
                raise ValueError(f"Invalid manifest record: {name}")
            data = archive.read(name)
            if sha256(data) != record["sha256"]:
                raise ValueError(f"Content hash mismatch: {name}")
            validate_payload(name, data)
    return manifest


def read_lock(packs_dir, catalog_hash, kinds):
    path = packs_dir / LOCK_NAME
    if path.stat().st_size > 1024 * 1024:
        raise ValueError("Oversized art-lock.json")
    lock = decode_json(path.read_bytes())
    if not isinstance(lock, dict) or lock.get("format") != 1 or lock.get("source") != SOURCE_URL or lock.get("revision") != REVISION or lock.get("catalog_sha256") != catalog_hash or not isinstance(lock.get("packs"), dict):
        raise ValueError("Invalid bundled art provenance lock")
    for kind in kinds:
        record = lock["packs"].get(kind)
        path = packs_dir / f"{kind}.zip"
        if not isinstance(record, dict) or record.get("archive") != path.name or path.stat().st_size > MAX_ZIP_BYTES or path.stat().st_size != record.get("zip_bytes") or sha256(path.read_bytes()) != record.get("sha256"):
            raise ValueError(f"Archive does not match art-lock.json: {kind}")
    return lock


def verify(packs_dir, kinds, *, check_lock=True):
    rows, catalog_hash = catalog()
    lock = read_lock(packs_dir, catalog_hash, kinds) if check_lock else None
    result = {}
    for kind in kinds:
        path = packs_dir / f"{kind}.zip"
        manifest = verify_archive(path, kind, rows, catalog_hash)
        result[kind] = {"files": len(manifest["entries"]), "zip_bytes": path.stat().st_size, "unpacked_bytes": sum(record["size"] for record in manifest["entries"].values()), "sha256": sha256(path.read_bytes())}
        if lock and lock["packs"][kind] != {"archive": f"{kind}.zip", **result[kind]}:
            raise ValueError(f"Archive counts differ from art-lock.json: {kind}")
    return result


def destination_file(destination, name):
    target = destination.joinpath(*safe_relative(name).parts)
    if not target.resolve().is_relative_to(destination):
        raise ValueError(f"Destination escapes through a link: {name}")
    for item in (target, *target.parents):
        if item == destination.parent:
            break
        if item.is_symlink() or getattr(item, "is_junction", lambda: False)():
            raise ValueError(f"Destination contains a symlink/junction: {name}")
    return target


def restore(packs_dir, destination, kinds, *, overwrite=False):
    destination = destination.resolve()
    rows, catalog_hash = catalog()
    read_lock(packs_dir, catalog_hash, kinds)
    manifests = {kind: verify_archive(packs_dir / f"{kind}.zip", kind, rows, catalog_hash) for kind in kinds}
    pending = []
    for kind, manifest in manifests.items():
        for name, record in sorted(manifest["entries"].items()):
            target = destination_file(destination, name)
            if target.exists():
                if not target.is_file():
                    raise ValueError(f"Destination is not a file: {target}")
                if sha256(target.read_bytes()) == record["sha256"]:
                    continue
                if not overwrite:
                    raise ValueError(f"Local edit preserved; choose another --destination or explicitly --overwrite: {target}")
            pending.append((kind, name, target))
    for kind in kinds:
        with zipfile.ZipFile(packs_dir / f"{kind}.zip") as archive:
            for entry_kind, name, target in pending:
                if entry_kind != kind:
                    continue
                destination_file(destination, name)
                data = archive.read(name)
                if sha256(data) != manifests[kind]["entries"][name]["sha256"]:
                    raise ValueError(f"Archive changed during restore: {name}")
                target.parent.mkdir(parents=True, exist_ok=True)
                temp_path = None
                try:
                    with tempfile.NamedTemporaryFile(dir=target.parent, prefix=".restore-", suffix=".tmp", delete=False) as temporary:
                        temp_path = Path(temporary.name)
                        temporary.write(data)
                        temporary.flush()
                        os.fsync(temporary.fileno())
                    os.replace(temp_path, target)
                finally:
                    if temp_path is not None:
                        temp_path.unlink(missing_ok=True)
    return {"destination": str(destination), "restored": len(pending), "files": sum(len(manifest["entries"]) for manifest in manifests.values())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest="command", required=True)
    for command in ("pack", "verify", "restore"):
        sub = subcommands.add_parser(command)
        sub.add_argument("--packs", type=Path, default=ROOT / "art/packs")
        sub.add_argument("--kind", choices=("all", "creatures", "world"), default="all")
        if command == "pack":
            sub.add_argument("--source", type=Path, default=ROOT / ".tools/modelospokemonroblox")
            sub.add_argument("--local", type=Path, default=ROOT / "art/creatures/local")
        if command == "restore":
            sub.add_argument("--destination", type=Path, default=ROOT / "art/creatures/local")
            sub.add_argument("--overwrite", action="store_true", help="Explicitly replace divergent local files")
    args = parser.parse_args()
    kinds = ("creatures", "world") if args.kind == "all" else (args.kind,)
    try:
        if args.command == "pack":
            result = pack(args.packs, args.source, args.local, kinds)
        elif args.command == "restore":
            result = restore(args.packs, args.destination, kinds, overwrite=args.overwrite)
        else:
            result = verify(args.packs, kinds)
    except (OSError, ValueError, SyntaxError, KeyError, TypeError, ET.ParseError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Bundled artwork rejected: {error}\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
