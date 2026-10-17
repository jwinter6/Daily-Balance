#!/usr/bin/env python3
"""Compiler checks against the installed iOS Simulator SDK; does not run the app."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
developer = Path(os.environ.get('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer'))
platform = developer / 'Platforms/iPhoneSimulator.platform/Developer'
compiler = developer / 'Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc'
sources = sorted(str(p) for p in (root/'DailyBalance').rglob('*.swift'))
with tempfile.TemporaryDirectory(prefix='balance-ios-check-') as directory:
    work = Path(directory)
    flags = [str(compiler), '-disable-sandbox', '-swift-version', '5', '-sdk', str(platform/'SDKs/iPhoneSimulator.sdk'),
             '-target', 'arm64-apple-ios17.0-simulator', '-module-cache-path', str(work/'ModuleCache')]
    subprocess.run(flags + ['-emit-module', '-enable-testing', '-D', 'DEBUG', '-module-name', 'DailyBalance',
                           '-emit-module-path', str(work/'DailyBalance.swiftmodule')] + sources, check=True)
    test_flags = flags + ['-typecheck', '-F', str(platform/'Library/Frameworks'), '-I', str(platform/'usr/lib'), '-I', str(work)]
    unit_sources = sorted(str(p) for folder in ['DailyBalanceTests', 'CoreTests'] for p in (root/folder).glob('*.swift'))
    subprocess.run(test_flags + ['-module-name', 'DailyBalanceTests'] + unit_sources, check=True)
    subprocess.run(test_flags + ['-module-name', 'DailyBalanceUITests'] + sorted(str(p) for p in (root/'DailyBalanceUITests').glob('*.swift')), check=True)
    # Also exercise code generation and linking, independently of xcodebuild's license gate.
    subprocess.run(flags + ['-emit-executable', '-parse-as-library', '-D', 'DEBUG', '-module-name', 'DailyBalance',
                           '-o', str(work/'DailyBalance')] + sources, check=True)
    print('PASS: iOS app module, unit tests and UI tests compile; app executable links. No Simulator run performed.')
