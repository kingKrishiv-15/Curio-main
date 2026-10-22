#!/usr/bin/env python3
"""Check release inputs without printing passwords or API keys."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--platform', choices=['android', 'web'], required=True)
args = parser.parse_args()
errors = []

try:
    config = json.loads((ROOT / 'config/supabase.json').read_text())
    if not re.fullmatch(r'https://[A-Za-z0-9.-]+(?::\d+)?/?', config.get('SUPABASE_URL', '')) or 'YOUR_' in config.get('SUPABASE_URL', ''):
        errors.append('Configure the hosted SUPABASE_URL in config/supabase.json.')
    key = config.get('SUPABASE_PUBLISHABLE_KEY', '')
    if not key or 'YOUR_' in key:
        errors.append('Configure the Supabase publishable key.')
    if key.startswith('sb_secret_') or any('SECRET' in name.upper() or 'SERVICE_ROLE' in name.upper() for name in config):
        errors.append('Remove server-only keys from the bundled config.')
    if str(config.get('CURIO_DEMO', '')).lower() == 'true':
        errors.append('Remove CURIO_DEMO=true from the production build config.')
except (OSError, ValueError):
    errors.append('Create a valid config/supabase.json using the example file.')

result = subprocess.run(['python3', str(ROOT / 'tool/build_supabase_setup.py'), '--check'], capture_output=True, text=True)
if result.returncode:
    errors.append('Regenerate supabase/setup.sql: python3 tool/build_supabase_setup.py')

for name in ['privacy.html', 'delete-account.html']:
    if 'CONTACT_EMAIL' in (ROOT / 'docs' / name).read_text():
        errors.append(f'Replace CONTACT_EMAIL with the public support address in docs/{name}.')

if args.platform == 'android':
    try:
        props = dict(line.split('=', 1) for line in (ROOT / 'android/key.properties').read_text().splitlines()
                     if '=' in line and not line.lstrip().startswith('#'))
        if any(not props.get(k, '').strip() for k in ['storeFile', 'storePassword', 'keyAlias', 'keyPassword']):
            errors.append('Complete the Android upload-key settings in android/key.properties.')
        path = Path(props.get('storeFile', '')).expanduser()
        if not path.is_absolute():
            path = ROOT / 'android/app' / path
        if not path.is_file():
            errors.append('The configured Android upload keystore is missing; restore it before the signed release build.')
    except OSError:
        errors.append('Configure android/key.properties from android/key.properties.example.')

if errors:
    print('Release inputs still needed:')
    for error in errors:
        print(f'- {error}')
    raise SystemExit(1)
print(f'{args.platform.capitalize()} release inputs are ready.')
print('Hosted SQL, email delivery and edge-function deployment still require verification in the connected Supabase project.')
