"""Execute the actual server modules against a deterministic Roblox/DataStore mock.

This tests state transitions; Studio's engine/network/DataStore integration still needs
the manual smoke checks documented in the README.
"""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", default=os.environ.get("LUAU_BIN"))
    args = parser.parse_args()
    executable = args.luau or shutil.which("luau")
    if not executable:
        candidates = [root / ".tools/luau/luau.exe", root / ".tools/luau/luau"]
        executable = next((str(path) for path in candidates if path.is_file()), None)
    if not executable:
        parser.error("Luau CLI not found. Pass --luau PATH or set LUAU_BIN.")
    template = (root / "tests/Services.spec.template.luau").read_text(encoding="utf-8")
    for module in ("DataService", "SanctuaryService", "ProgressionService"):
        source = (root / "src/server/Services" / f"{module}.luau").read_text(encoding="utf-8")
        separator = "===="
        while f"]{separator}]" in source:
            separator += "="
        literal = f"[{separator}[\n{source}\n]{separator}]"
        template = template.replace(f"__{module.upper()}_SOURCE__", literal)
    with tempfile.TemporaryDirectory(prefix="throw-a-sphere-tests-") as temporary:
        script = Path(temporary) / "services.luau"
        script.write_text(template, encoding="utf-8")
        result = subprocess.run([str(executable), str(script)], cwd=root, check=False)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
