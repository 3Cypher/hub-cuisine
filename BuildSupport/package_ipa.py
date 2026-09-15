#!/usr/bin/env python3
"""Package a successfully compiled iPhoneOS application; no Apple signing here."""
from pathlib import Path
import hashlib
import plistlib
import subprocess
import zipfile

root = Path(__file__).resolve().parent.parent
app = root / 'build/DerivedData/Build/Products/Release-iphoneos/HubCuisine.app'
assert app.is_dir(), 'No compiled iPhoneOS app exists. xcodebuild must succeed first.'
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'be.brendon.hubcuisine'
assert info.get('CFBundleSupportedPlatforms') == ['iPhoneOS'], 'Simulator build cannot be installed on an iPad.'
executable = app / info['CFBundleExecutable']
assert executable.is_file(), 'Mach-O executable missing.'
subprocess.run(['xcrun', 'lipo', str(executable), '-verify_arch', 'arm64'], check=True)
assert (app / 'Assets.car').is_file(), 'Compiled assets missing.'
assert (app / 'LegacyRecipes.json').is_file(), 'Demo recipes missing.'
ipa = root / 'build/HubCuisine-unsigned.ipa'
with zipfile.ZipFile(ipa, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for file in sorted(app.rglob('*')):
        if file.is_file():
            assert not file.is_symlink(), 'Unexpected symlink in application bundle.'
            archive.write(file, 'Payload/HubCuisine.app/' + file.relative_to(app).as_posix())
with zipfile.ZipFile(ipa) as archive:
    assert archive.testzip() is None
(root / 'build/HubCuisine-unsigned.sha256').write_text(hashlib.sha256(ipa.read_bytes()).hexdigest() + '  ' + ipa.name + '\n')
print(f'IPA ready for local signing: {ipa.stat().st_size} bytes')
