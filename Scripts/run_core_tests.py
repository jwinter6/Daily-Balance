#!/usr/bin/env python3
"""Run pure Foundation tests without requiring a Simulator or changing xcode-select."""
from pathlib import Path
import os
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
developer = Path(os.environ.get('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer'))
frameworks = developer / 'Platforms/MacOSX.platform/Developer/Library/Frameworks'
libraries = developer / 'Platforms/MacOSX.platform/Developer/usr/lib'
toolchain = developer / 'Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc'
sdk = developer / 'Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'
source = (root / 'CoreTests/BalanceCoreTests.swift').read_text().replace('@testable import BalanceCore', '')
methods = re.findall(r'    func (test\w+)\(', source)
with tempfile.TemporaryDirectory(prefix='balance-core-') as temporary:
    work = Path(temporary)
    (work / 'Tests.swift').write_text(source)
    (work / 'main.swift').write_text(
        'import XCTest\nimport Darwin\n'
        'let suite = XCTestSuite(forTestCaseClass: BalanceCoreTests.self)\n'
        'suite.run()\n'
        'guard let run = suite.testRun, run.executionCount == ' + str(len(methods)) + ' else { exit(2) }\n'
        'exit(run.totalFailureCount == 0 ? 0 : 1)\n')
    command = [str(toolchain), '-disable-sandbox', '-swift-version', '5', '-sdk', str(sdk),
               '-module-cache-path', str(work / 'ModuleCache'), '-F', str(frameworks), '-I', str(libraries),
               '-L', str(libraries), '-framework', 'XCTest', '-lXCTestSwiftSupport',
               '-Xlinker', '-rpath', '-Xlinker', str(frameworks),
               '-Xlinker', '-rpath', '-Xlinker', str(libraries),
               str(root / 'DailyBalance/Models/Domain.swift'), str(work / 'Tests.swift'), str(work / 'main.swift'),
               '-o', str(work / 'CoreTests')]
    subprocess.run(command, check=True)
    result = subprocess.run([str(work / 'CoreTests')])
    raise SystemExit(result.returncode)
