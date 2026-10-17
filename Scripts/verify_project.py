#!/usr/bin/env python3
"""Static checks of source packaging and the explicit local-storage configuration."""
from pathlib import Path
import json
import plistlib
import re
import struct
import subprocess

root = Path(__file__).resolve().parents[1]
project = root/'DailyBalance.xcodeproj/project.pbxproj'
subprocess.run(['plutil', '-lint', str(project)], check=True)
plist = plistlib.loads((root/'DailyBalance/Resources/Info.plist').read_bytes())
privacy = plistlib.loads((root/'DailyBalance/Resources/PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
assert privacy['NSPrivacyCollectedDataTypes'] == []
assert 'NSCameraUsageDescription' in plist and 'NSFaceIDUsageDescription' in plist
assert 'NSAppTransportSecurity' not in plist
sources = list((root/'DailyBalance').rglob('*.swift'))
code = '\n'.join(p.read_text() for p in sources)
assert not re.search(r'\b(URLSession|URLRequest|NWConnection|CKContainer|HKHealthStore)\b', code)
assert 'cloudKitDatabase: .none' in code
assert 'isExcludedFromBackup = true' in code
assert '.completeFileProtection' in code
assert not list((root/'DailyBalance').rglob('*.entitlements'))
project_text = project.read_text()
for source in sources:
    assert str(source.relative_to(root)) in project_text, f'Unreferenced source: {source}'
icon_dir = root/'DailyBalance/Resources/Assets.xcassets/AppIcon.appiconset'
icon_json = json.loads((icon_dir/'Contents.json').read_text())
icon = (icon_dir/icon_json['images'][0]['filename']).read_bytes()
assert icon[:8] == b'\x89PNG\r\n\x1a\n'
width, height, depth, color = struct.unpack('>IIBB', icon[16:26])
assert (width, height) == (1024,1024)
assert color == 2, 'App icon must be opaque RGB'
print(f'PASS: {len(sources)} app source files referenced, plists and opaque icon valid, explicit local storage, no network clients in app source.')
print('Static inspection does not prove OS backup behavior or runtime network behavior.')
