"""Run the actual flight service and math with deterministic Roblox mocks."""
import argparse
from pathlib import Path
import subprocess
import tempfile
import os
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--luau',default=str(root/'.tools/luau'/('luau.exe' if os.name=='nt' else 'luau')))
args=parser.parse_args()
source=(root/'tests/FlightService.spec.luau').read_text(encoding='utf-8')
for marker,path in [('MATH','src/shared/FlightMath.luau'),('SERVICE','src/server/Services/FlightService.luau')]:
    source=source.replace('--[['+marker+']]',(root/path).read_text(encoding='utf-8'))
with tempfile.TemporaryDirectory(prefix='flight-tests-') as temporary:
    path=Path(temporary)/'flight.luau'
    path.write_text(source,encoding='utf-8')
    raise SystemExit(subprocess.run([args.luau,str(path)],cwd=root).returncode)
