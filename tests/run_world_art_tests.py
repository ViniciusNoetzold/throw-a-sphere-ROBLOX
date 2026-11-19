"""Exercise the native world-art lifecycle without starting Studio or changing saves."""
from pathlib import Path
import argparse
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--luau", default=str(root / ".tools/luau/luau.exe"))
args = parser.parse_args()
source = (root / "tests/WorldArtService.spec.luau").read_text(encoding="utf-8")
source = source.replace("--[[WORLD_ART]]", (root / "src/server/Services/WorldArtService.luau").read_text(encoding="utf-8"))
with tempfile.TemporaryDirectory(prefix="world-art-tests-") as folder:
    path = Path(folder) / "world-art.luau"
    path.write_text(source, encoding="utf-8")
    raise SystemExit(subprocess.run([args.luau, str(path)], cwd=root).returncode)
