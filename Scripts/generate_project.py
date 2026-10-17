#!/usr/bin/env python3
"""Reproducible Xcode project, with no third-party generator dependency."""
from pathlib import Path
import hashlib
import json
import html

ROOT = Path(__file__).resolve().parents[1]
objects = {}
def uid(key): return hashlib.sha256(key.encode()).hexdigest()[:24].upper()
def obj(key, body):
    ident = uid(key)
    objects[ident] = body
    return ident
def q(s): return json.dumps(str(s), ensure_ascii=False)
def refs(values): return '(' + ', '.join(values) + ',)' if values else '()'

def file_ref(path, kind):
    return obj('file:'+path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(path)}; sourceTree = SOURCE_ROOT;')
def build_file(ref): return obj('build:'+ref, f'isa = PBXBuildFile; fileRef = {ref};')
def phase(name, kind, files):
    return obj(name, f'isa = {kind}; buildActionMask = 2147483647; files = {refs(files)}; runOnlyForDeploymentPostprocessing = 0;')
def group(key, name, children):
    return obj(key, f'isa = PBXGroup; name = {q(name)}; children = {refs(children)}; sourceTree = "<group>";')
def config_list(name, base):
    configs=[]
    for mode in ('Debug','Release'):
        values = dict(base)
        values.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O',
                       'DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym'})
        if mode=='Debug': values.update({'ENABLE_TESTABILITY':'YES','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG'})
        body = ' '.join(f'{k} = {q(v)};' for k,v in sorted(values.items()))
        configs.append(obj(name+mode, f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {mode};'))
    return obj(name+'configs', f'isa = XCConfigurationList; buildConfigurations = {refs(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

app_sources = [file_ref(str(p.relative_to(ROOT)), 'sourcecode.swift') for p in sorted((ROOT/'DailyBalance').rglob('*.swift'))]
resources = [file_ref('DailyBalance/Resources/Assets.xcassets', 'folder.assetcatalog'),
             file_ref('DailyBalance/Resources/PrivacyInfo.xcprivacy','text.xml')]
info = file_ref('DailyBalance/Resources/Info.plist','text.plist.xml')
test_sources = [file_ref(str(p.relative_to(ROOT)), 'sourcecode.swift') for p in sorted((ROOT/'DailyBalanceTests').glob('*.swift')) + sorted((ROOT/'CoreTests').glob('*.swift'))]
ui_sources = [file_ref(str(p.relative_to(ROOT)), 'sourcecode.swift') for p in sorted((ROOT/'DailyBalanceUITests').glob('*.swift'))]
products=[]
targets=[]
base={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_VERSION':'5.0',
      'CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','TARGETED_DEVICE_FAMILY':'1',
      'SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','CODE_SIGN_STYLE':'Automatic',
      'MARKETING_VERSION':'1.2','CURRENT_PROJECT_VERSION':'3',
      'SWIFT_EMIT_LOC_STRINGS':'YES','SUPPORTS_MACCATALYST':'NO'}
for name, sources, product_type, ext in [
    ('DailyBalance',app_sources,'application','app'),
    ('DailyBalanceTests',test_sources,'bundle.unit-test','xctest'),
    ('DailyBalanceUITests',ui_sources,'bundle.ui-testing','xctest')]:
    product=obj(name+'product',f'isa = PBXFileReference; explicitFileType = {"wrapper.application" if ext=="app" else "wrapper.cfbundle"}; includeInIndex = 0; path = {name}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;')
    products.append(product)
    settings=dict(base, PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='de.jan.dailybalance'+('' if ext=='app' else '.'+name))
    if ext=='app':
        settings.update({'INFOPLIST_FILE':'DailyBalance/Resources/Info.plist','GENERATE_INFOPLIST_FILE':'NO',
                         'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks'})
    else:
        settings.update({'GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'DailyBalance'})
        if name=='DailyBalanceTests':
            settings.update({'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/DailyBalance.app/DailyBalance','BUNDLE_LOADER':'$(TEST_HOST)'})
    phases=[phase(name+'sources','PBXSourcesBuildPhase',[build_file(r) for r in sources]),
            phase(name+'frameworks','PBXFrameworksBuildPhase',[]),
            phase(name+'resources','PBXResourcesBuildPhase',[build_file(r) for r in resources] if ext=='app' else [])]
    deps=[]
    if ext!='app':
        proxy=obj(name+'proxy',f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("DailyBalancetarget")}; remoteInfo = DailyBalance;')
        deps=[obj(name+'dependency',f'isa = PBXTargetDependency; target = {uid("DailyBalancetarget")}; targetProxy = {proxy};')]
    configs=config_list(name,settings)
    target=obj(name+'target',f'isa = PBXNativeTarget; buildConfigurationList = {configs}; buildPhases = {refs(phases)}; buildRules = (); dependencies = {refs(deps) if deps else "()"}; name = {name}; productName = {name}; productReference = {product}; productType = "com.apple.product-type.{product_type}";')
    targets.append(target)
main=group('main','Daily Balance',[
    group('sources','App',app_sources),group('resources','Resources',resources+[info]),
    group('tests','Unit Tests',test_sources),group('uitests','UI Tests',ui_sources),group('products','Products',products)])
project_configs=config_list('project', {'CLANG_ENABLE_MODULES':'YES','SWIFT_VERSION':'5.0'})
project=obj('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2700; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = de; hasScannedForEncodings = 0; knownRegions = (de, en, Base); mainGroup = {main}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; targets = {refs(targets)};')
path=ROOT/'DailyBalance.xcodeproj'
path.mkdir(exist_ok=True)
(path/'project.pbxproj').write_text('// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'+''.join(f'  {k} = {{ {v} }};\n' for k,v in objects.items())+' };\n rootObject = '+project+';\n}\n')
schemes=path/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
def reference(name, ext):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(name+"target")}" BuildableName="{name}.{ext}" BlueprintName="{name}" ReferencedContainer="container:DailyBalance.xcodeproj"/>'
app=reference('DailyBalance','app')
scheme=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
<TestableReference skipped="NO">{reference('DailyBalanceTests','xctest')}</TestableReference>
<TestableReference skipped="NO">{reference('DailyBalanceUITests','xctest')}</TestableReference>
</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(schemes/'DailyBalance.xcscheme').write_text(scheme)
print(path)
