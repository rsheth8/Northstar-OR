#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import pathlib
import subprocess
import sys

files = subprocess.check_output(['git', 'ls-files', '-z']).decode().split('\0')
errors = []
for name in filter(None, files):
    path = pathlib.PurePosixPath(name)
    if any(part.endswith(('.xcodeproj', '.xcworkspace')) for part in path.parts):
        errors.append(f'{name}: generated Xcode project/workspace must not be tracked')
    if any(part in {'.claude-flow', 'DerivedData', 'xcuserdata'} for part in path.parts):
        errors.append(f'{name}: local workspace state must not be tracked')
    if (path.name == '.env' or (path.name.startswith('.env.') and path.name != '.env.example')
            or path.name.endswith(('.p12', '.p8', '.mobileprovision', '.local.xcconfig'))
            or path.name == 'GoogleService-Info.plist'):
        errors.append(f'{name}: local credentials/config must not be tracked')
    if path.suffix in {'.swift', '.md', '.yml', '.yaml', '.sh'} and pathlib.Path(name).is_file():
        for number, line in enumerate(pathlib.Path(name).read_text().splitlines(), 1):
            if line.startswith(('<<<<<<< ', '>>>>>>> ')) or line == '=======':
                errors.append(f'{name}:{number}: unresolved merge conflict')
if errors:
    sys.exit('\n'.join(errors))
print('Repository checks passed (generated files, local credentials/config, conflict markers).')
PY

python3 -m unittest discover -s scripts -p 'test_*.py'
