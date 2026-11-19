"""Run actual monetization/trade/auction modules against deterministic services."""
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
        executable = next((str(path) for path in (root / ".tools/luau/luau.exe", root / ".tools/luau/luau") if path.is_file()), None)
    if not executable:
        parser.error("Luau CLI not found")
    template = (root / "tests/Economy.spec.template.luau").read_text(encoding="utf-8")
    for module in ("MonetizationService", "TradeService", "AuctionService"):
        source = (root / "src/server/Services" / f"{module}.luau").read_text(encoding="utf-8")
        separator = "===="
        while f"]{separator}]" in source:
            separator += "="
        template = template.replace(f"__{module.upper()}_SOURCE__", f"[{separator}[\n{source}\n]{separator}]")
    with tempfile.TemporaryDirectory(prefix="throw-a-sphere-economy-") as temporary:
        script = Path(temporary) / "economy.luau"
        script.write_text(template, encoding="utf-8")
        raise SystemExit(subprocess.run([str(executable), str(script)], cwd=root, check=False).returncode)


if __name__ == "__main__":
    main()
