"""Run production progression/reward/fusion/automation modules in deterministic mocks."""
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
        parser.error("Luau CLI not found. Pass --luau PATH.")
    paths = {name: root / "src/shared" / f"{name}.luau" for name in ("Config", "ConfigGameplay", "CaptureMath", "ConfigOrbes", "ConfigCriaturas", "ConfigBiomas", "ConfigMutacoes", "ConfigProgression", "ConfigRecompensas", "GameplayMath")}
    paths.update({name: root / "src/server/Services" / f"{name}.luau" for name in ("ProgressionService", "SanctuaryService", "FusionService", "RewardService", "AutomationService")})
    sources = []
    for name, path in paths.items():
        source = path.read_text(encoding="utf-8")
        separator = "===="
        while f"]{separator}]" in source:
            separator += "="
        sources.append(f'{name} = [{separator}[\n{source}\n]{separator}],')
    template = (root / "tests/ProgressionSystems.spec.template.luau").read_text(encoding="utf-8")
    template = template.replace("__PRODUCTION_SOURCES__", "\n".join(sources))
    scratch = root / ".tools" / "test-scratch"
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="progression-tests-", dir=scratch) as temporary:
        script = Path(temporary) / "progression.luau"
        script.write_text(template, encoding="utf-8")
        result = subprocess.run([str(executable), str(script)], cwd=root, check=False)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
