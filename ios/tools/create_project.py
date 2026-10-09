"""Generate a minimal Xcode project with no package manager or paid SDK dependency."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
uid=lambda n:f'{n:024X}'
files=['HouseOnSiteApp.swift','ContentView.swift','HouseAsset.swift','Placement.swift','HouseSession.swift','ARPhotoCapture.swift']
objects=[]
def add(n,body): objects.append(f'{uid(n)} = {{ {body} }};')
for i,file in enumerate(files):
 add(100+i,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HouseOnSite/{file}; sourceTree = "<group>";')
 add(200+i,f'isa = PBXBuildFile; fileRef = {uid(100+i)};')
add(110,'isa = PBXFileReference; lastKnownFileType = file; name = house2story.usdz; path = ../public/models/ios/house2story.usdz; sourceTree = "<group>";')
add(210,f'isa = PBXBuildFile; fileRef = {uid(110)};')
add(111,'isa = PBXFileReference; explicitFileType = wrapper.application; path = HouseOnSite.app; sourceTree = BUILT_PRODUCTS_DIR;')
add(1,f'isa = PBXGroup; children = ({", ".join(uid(100+i) for i in range(len(files)))}, {uid(110)}, {uid(2)}); sourceTree = "<group>";')
add(2,f'isa = PBXGroup; name = Products; children = ({uid(111)}); sourceTree = "<group>";')
add(3,f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(uid(200+i) for i in range(len(files)))}); runOnlyForDeploymentPostprocessing = 0;')
add(4,f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({uid(210)}); runOnlyForDeploymentPostprocessing = 0;')
add(5,'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
add(6,f'isa = PBXNativeTarget; buildConfigurationList = {uid(9)}; buildPhases = ({uid(3)}, {uid(5)}, {uid(4)}); buildRules = (); dependencies = (); name = HouseOnSite; productName = HouseOnSite; productReference = {uid(111)}; productType = "com.apple.product-type.application";')
add(7,f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 2630; TargetAttributes = {{ {uid(6)} = {{ CreatedOnToolsVersion = 26.3; }}; }}; }}; buildConfigurationList = {uid(8)}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {uid(1)}; productRefGroup = {uid(2)}; projectDirPath = ""; projectRoot = ""; targets = ({uid(6)});')
for listid,configs in [(8,(10,11)),(9,(12,13))]:
 add(listid,f'isa = XCConfigurationList; buildConfigurations = ({uid(configs[0])}, {uid(configs[1])}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
for n,name in [(10,'Debug'),(11,'Release')]:
 add(n,f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 5.0; SWIFT_OPTIMIZATION_LEVEL = "{"-Onone" if name=="Debug" else "-O"}"; }};')
for n,name in [(12,'Debug'),(13,'Release')]:
 add(n,f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.example.HouseOnSite; INFOPLIST_FILE = HouseOnSite/Info.plist; GENERATE_INFOPLIST_FILE = NO; CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = ""; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_STRICT_CONCURRENCY = complete; }};')
(root/'HouseOnSite.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {uid(7)}; }}\n')
