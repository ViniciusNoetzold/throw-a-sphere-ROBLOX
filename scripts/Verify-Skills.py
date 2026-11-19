"""Verify the installed skill inventory and pinned file integrity without network access."""
import hashlib
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
lock = json.loads((root / 'skills.lock.json').read_text(encoding='utf-8'))
names = set()
files = 0
for skill in lock['skills']:
    name = skill['name']
    assert name not in names, f'Duplicate skill: {name}'
    names.add(name)
    base = root / skill['installedPath']
    assert base.resolve().is_relative_to(root / '.agents' / 'skills')
    content = (base / 'SKILL.md').read_text(encoding='utf-8')
    front = re.match(r'\A---\r?\n(.*?)\r?\n---', content, re.S)
    assert front and re.search(r'^name:\s*' + re.escape(name) + r'\s*$', front[1], re.M), name
    assert re.search(r'^description:\s*\S', front[1], re.M), f'Missing description: {name}'
    actual = {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in base.rglob('*') if p.is_file()}
    assert actual == skill['files'], f'Files changed or missing: {name}'
    assert re.fullmatch(r'[0-9a-f]{40}', skill['commit']), name
    files += len(actual)
for source in lock['sources']:
    assert (root / source['vendorPath']).is_dir(), source['repo']
expected = {p.parent.name for p in (root / '.agents' / 'skills').glob('*/SKILL.md')}
assert expected == names, 'Installed inventory differs from lock file'
print(f'PASS: {len(names)} unique skills, {files} files with matching SHA-256, {len(lock["sources"])} pinned sources')
