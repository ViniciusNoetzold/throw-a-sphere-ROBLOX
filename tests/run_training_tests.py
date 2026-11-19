"""Exercise production academy math/service against deterministic engine boundaries."""
from pathlib import Path
import argparse
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--luau', default=str(root / '.tools/luau/luau.exe'))
args = parser.parse_args()
source = (root / 'tests/TrainingService.spec.luau').read_text(encoding='utf-8')
for marker, path in [('RULES', 'src/shared/ConfigTraining.luau'), ('MATH', 'src/shared/TrainingMath.luau'), ('SERVICE', 'src/server/Services/TrainingService.luau')]:
    source = source.replace('--[[' + marker + ']]', (root / path).read_text(encoding='utf-8'))
with tempfile.TemporaryDirectory(prefix='training-tests-') as folder:
    path = Path(folder) / 'training.luau'
    path.write_text(source, encoding='utf-8')
    raise SystemExit(subprocess.run([args.luau, str(path)], cwd=root).returncode)
