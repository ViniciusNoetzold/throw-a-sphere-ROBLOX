"""Run the production Roblox capture handler in the official Luau CLI with mocks."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", help="Path to the official Luau CLI executable")
    args = parser.parse_args()
    executable = args.luau or os.environ.get("LUAU_BIN") or shutil.which("luau")
    if not executable:
        bundled = root / ".tools" / "luau" / ("luau.exe" if os.name == "nt" else "luau")
        if bundled.is_file():
            executable = str(bundled)
    if not executable:
        parser.error("Luau CLI not found; pass --luau PATH or install the pinned toolchain.")

    suites = (
        ("DropService", (
            ("INJECT_DROP_CONFIG", root / "src" / "shared" / "ConfigDrops.luau"),
            ("INJECT_VARIANT_RULES", root / "src" / "shared" / "ConfigMutacoes.luau"),
            ("INJECT_VARIANTS", root / "src" / "shared" / "VariantMath.luau"),
            ("INJECT_DROPS", root / "src" / "server" / "Services" / "DropService.luau"),
        )),
        ("CaptureService", (
            ("INJECT_CAPTURE_MATH", root / "src" / "shared" / "CaptureMath.luau"),
            ("INJECT_GAMEPLAY_MATH", root / "src" / "shared" / "GameplayMath.luau"),
            ("INJECT_CAPTURE_VARIANTS", root / "src" / "shared" / "VariantMath.luau"),
            ("INJECT_CAPTURE_SERVICE", root / "src" / "server" / "Services" / "CaptureService.luau"),
        )),
        ("SpawnService", (
            ("INJECT_NUMBER_FORMATTER", root / "src" / "shared" / "NumberFormatter.luau"),
            ("INJECT_SPAWN_SERVICE", root / "src" / "server" / "Services" / "SpawnService.luau"),
        )),
        ("WorldServices", (
            ("INJECT_WORLD_NUMBERS", root / "src" / "shared" / "NumberFormatter.luau"),
            ("INJECT_EVENT_CONFIG", root / "src" / "shared" / "ConfigEvents.luau"),
            ("INJECT_BIOMES", root / "src" / "server" / "Services" / "BiomeService.luau"),
            ("INJECT_WEATHER", root / "src" / "server" / "Services" / "WeatherEventService.luau"),
            ("INJECT_BOSS", root / "src" / "server" / "Services" / "BossService.luau"),
            ("INJECT_RANKINGS", root / "src" / "server" / "Services" / "LeaderboardPodiumService.luau"),
        )),
    )
    for suite_name, modules in suites:
        harness = (root / "tests" / f"{suite_name}.spec.luau").read_text(encoding="utf-8")
        for marker, source in modules:
            placeholder = f"--[[{marker}]]"
            assert harness.count(placeholder) == 1, f"Missing or duplicate injection marker: {marker}"
            harness = harness.replace(placeholder, source.read_text(encoding="utf-8"))

        # Actual source is embedded unchanged: tests cannot accidentally pass
        # against a second implementation of either production service.
        with tempfile.TemporaryDirectory(prefix="throw-a-sphere-tests-") as directory:
            generated = Path(directory) / f"{suite_name}-tests.luau"
            generated.write_text(harness, encoding="utf-8")
            result = subprocess.run([executable, str(generated)], cwd=root, check=False)
            if result.returncode:
                return result.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
