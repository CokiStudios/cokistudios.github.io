import os, hashlib

def make_id(seed):
    h = hashlib.md5(seed.encode('utf-8')).hexdigest().upper()
    return 'B8' + h[:22]

# iOS Files
ios_files = [
    ('ShineMapsApp.swift', 'sourcecode.swift', True),
    ('ContentView.swift', 'sourcecode.swift', True),
    ('LocationAndMapService.swift', 'sourcecode.swift', True),
    ('Models.swift', 'sourcecode.swift', True),
    ('ShineMapsTheme.swift', 'sourcecode.swift', True),
    ('CSIDManager.swift', 'sourcecode.swift', True),
    ('CSIDAuthViews.swift', 'sourcecode.swift', True),
    ('CarPlaySceneDelegate.swift', 'sourcecode.swift', True),
    ('Info.plist', 'text.plist.xml', False),
    ('README.md', 'net.daringfireball.markdown', False),
]

# Watch Files
watch_files = [
    ('Watch/ShineMapsWatchApp.swift', 'sourcecode.swift', True),
    ('Watch/ShineMapsWatchContentView.swift', 'sourcecode.swift', True),
    ('Watch/ShineMapsWatchConnectivity.swift', 'sourcecode.swift', True),
    ('Watch/ShineMapsWatchComplications.swift', 'sourcecode.swift', True),
    ('Watch/Info.plist', 'text.plist.xml', False),
]

file_refs = {}
build_files_ios = {}
build_files_watch = {}

for fname, ftype, is_src in ios_files:
    f_id = make_id('FILE_' + fname)
    file_refs[fname] = (f_id, ftype)
    if is_src:
        b_id = make_id('BUILD_IOS_' + fname)
        build_files_ios[fname] = b_id

for fname, ftype, is_src in watch_files:
    f_id = make_id('FILE_' + fname)
    file_refs[fname] = (f_id, ftype)
    if is_src:
        b_id = make_id('BUILD_WATCH_' + fname)
        build_files_watch[fname] = b_id

proj_id = make_id('PROJECT')
target_ios_id = make_id('TARGET_IOS')
target_watch_id = make_id('TARGET_WATCH')
app_ios_ref_id = make_id('APP_IOS_REF')
app_watch_ref_id = make_id('APP_WATCH_REF')
main_grp_id = make_id('MAIN_GRP')
prod_grp_id = make_id('PROD_GRP')
watch_grp_id = make_id('WATCH_GRP')

sources_phase_ios_id = make_id('SOURCES_PHASE_IOS')
frameworks_phase_ios_id = make_id('FRAMEWORKS_PHASE_IOS')
resources_phase_ios_id = make_id('RESOURCES_PHASE_IOS')

sources_phase_watch_id = make_id('SOURCES_PHASE_WATCH')
frameworks_phase_watch_id = make_id('FRAMEWORKS_PHASE_WATCH')
resources_phase_watch_id = make_id('RESOURCES_PHASE_WATCH')

cfg_proj_debug_id = make_id('CFG_PROJ_DEBUG')
cfg_proj_release_id = make_id('CFG_PROJ_RELEASE')
cfg_target_ios_debug_id = make_id('CFG_TARGET_IOS_DEBUG')
cfg_target_ios_release_id = make_id('CFG_TARGET_IOS_RELEASE')
cfg_target_watch_debug_id = make_id('CFG_TARGET_WATCH_DEBUG')
cfg_target_watch_release_id = make_id('CFG_TARGET_WATCH_RELEASE')

cfg_list_proj_id = make_id('CFG_LIST_PROJ')
cfg_list_target_ios_id = make_id('CFG_LIST_TARGET_IOS')
cfg_list_target_watch_id = make_id('CFG_LIST_TARGET_WATCH')

out = []
out.append('// !$*UTF8*$!')
out.append('{')
out.append('\tarchiveVersion = 1;')
out.append('\tclasses = {')
out.append('\t};')
out.append('\tobjectVersion = 56;')
out.append('\tobjects = {')
out.append('')

# PBXBuildFile
out.append('/* Begin PBXBuildFile section */')
for fname, b_id in build_files_ios.items():
    f_id, _ = file_refs[fname]
    out.append(f'\t\t{b_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {fname} */; }};')
for fname, b_id in build_files_watch.items():
    f_id, _ = file_refs[fname]
    out.append(f'\t\t{b_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {fname} */; }};')
out.append('/* End PBXBuildFile section */')
out.append('')

# PBXFileReference
out.append('/* Begin PBXFileReference section */')
out.append(f'\t\t{app_ios_ref_id} /* ShineMaps.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ShineMaps.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
out.append(f'\t\t{app_watch_ref_id} /* ShineMapsWatch.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ShineMapsWatch.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
for fname, (f_id, ftype) in file_refs.items():
    leaf_name = os.path.basename(fname)
    out.append(f'\t\t{f_id} /* {leaf_name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = "{leaf_name}"; sourceTree = "<group>"; }};')
out.append('/* End PBXFileReference section */')
out.append('')

# PBXFrameworksBuildPhase
out.append('/* Begin PBXFrameworksBuildPhase section */')
out.append(f'\t\t{frameworks_phase_ios_id} /* Frameworks */ = {{')
out.append('\t\t\tisa = PBXFrameworksBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append(f'\t\t{frameworks_phase_watch_id} /* Frameworks */ = {{')
out.append('\t\t\tisa = PBXFrameworksBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXFrameworksBuildPhase section */')
out.append('')

# PBXGroup
out.append('/* Begin PBXGroup section */')
out.append(f'\t\t{main_grp_id} = {{')
out.append('\t\t\tisa = PBXGroup;')
out.append('\t\t\tchildren = (')
for fname, _, _ in ios_files:
    f_id, _ = file_refs[fname]
    out.append(f'\t\t\t\t{f_id} /* {fname} */,')
out.append(f'\t\t\t\t{watch_grp_id} /* Watch */,')
out.append(f'\t\t\t\t{prod_grp_id} /* Products */,')
out.append('\t\t\t);')
out.append('\t\tsourceTree = "<group>";')
out.append('\t\t};')

out.append(f'\t\t{watch_grp_id} /* Watch */ = {{')
out.append('\t\t\tisa = PBXGroup;')
out.append('\t\t\tchildren = (')
for fname, _, _ in watch_files:
    f_id, _ = file_refs[fname]
    leaf = os.path.basename(fname)
    out.append(f'\t\t\t\t{f_id} /* {leaf} */,')
out.append('\t\t\t);')
out.append('\t\t\tpath = Watch;')
out.append('\t\t\tsourceTree = "<group>";')
out.append('\t\t};')

out.append(f'\t\t{prod_grp_id} /* Products */ = {{')
out.append('\t\t\tisa = PBXGroup;')
out.append('\t\t\tchildren = (')
out.append(f'\t\t\t\t{app_ios_ref_id} /* ShineMaps.app */,')
out.append(f'\t\t\t\t{app_watch_ref_id} /* ShineMapsWatch.app */,')
out.append('\t\t\t);')
out.append('\t\t\tname = Products;')
out.append('\t\t\tsourceTree = "<group>";')
out.append('\t\t};')
out.append('/* End PBXGroup section */')
out.append('')

# PBXNativeTarget
out.append('/* Begin PBXNativeTarget section */')
out.append(f'\t\t{target_ios_id} /* ShineMaps */ = {{')
out.append('\t\t\tisa = PBXNativeTarget;')
out.append(f'\t\t\tbuildConfigurationList = {cfg_list_target_ios_id} /* Build configuration list for PBXNativeTarget "ShineMaps" */;')
out.append('\t\t\tbuildPhases = (')
out.append(f'\t\t\t\t{sources_phase_ios_id} /* Sources */,')
out.append(f'\t\t\t\t{frameworks_phase_ios_id} /* Frameworks */,')
out.append(f'\t\t\t\t{resources_phase_ios_id} /* Resources */,')
out.append('\t\t\t);')
out.append('\t\t\tbuildRules = ();')
out.append('\t\t\tdependencies = ();')
out.append('\t\t\tname = ShineMaps;')
out.append('\t\t\tproductName = ShineMaps;')
out.append(f'\t\t\tproductReference = {app_ios_ref_id} /* ShineMaps.app */;')
out.append('\t\t\tproductType = "com.apple.product-type.application";')
out.append('\t\t};')

out.append(f'\t\t{target_watch_id} /* ShineMapsWatch */ = {{')
out.append('\t\t\tisa = PBXNativeTarget;')
out.append(f'\t\t\tbuildConfigurationList = {cfg_list_target_watch_id} /* Build configuration list for PBXNativeTarget "ShineMapsWatch" */;')
out.append('\t\t\tbuildPhases = (')
out.append(f'\t\t\t\t{sources_phase_watch_id} /* Sources */,')
out.append(f'\t\t\t\t{frameworks_phase_watch_id} /* Frameworks */,')
out.append(f'\t\t\t\t{resources_phase_watch_id} /* Resources */,')
out.append('\t\t\t);')
out.append('\t\t\tbuildRules = ();')
out.append('\t\t\tdependencies = ();')
out.append('\t\t\tname = ShineMapsWatch;')
out.append('\t\t\tproductName = ShineMapsWatch;')
out.append(f'\t\t\tproductReference = {app_watch_ref_id} /* ShineMapsWatch.app */;')
out.append('\t\t\tproductType = "com.apple.product-type.application.watchapp";')
out.append('\t\t};')
out.append('/* End PBXNativeTarget section */')
out.append('')

# PBXProject
out.append('/* Begin PBXProject section */')
out.append(f'\t\t{proj_id} /* Project object */ = {{')
out.append('\t\t\tisa = PBXProject;')
out.append('\t\t\tattributes = {')
out.append('\t\t\t\tBuildIndependentTargetsInParallel = 1;')
out.append('\t\t\t\tLastUpgradeCheck = 1500;')
out.append('\t\t\t\tTargetAttributes = {')
out.append(f'\t\t\t\t\t{target_ios_id} = {{')
out.append('\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;')
out.append('\t\t\t\t\t};')
out.append(f'\t\t\t\t\t{target_watch_id} = {{')
out.append('\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;')
out.append('\t\t\t\t\t};')
out.append('\t\t\t\t};')
out.append('\t\t\t};')
out.append(f'\t\t\tbuildConfigurationList = {cfg_list_proj_id} /* Build configuration list for PBXProject "ShineMaps" */;')
out.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
out.append('\t\t\tdevelopmentRegion = es;')
out.append('\t\t\thasScannedForEncodings = 0;')
out.append('\t\t\tknownRegions = (es, en, Base);')
out.append(f'\t\t\tmainGroup = {main_grp_id};')
out.append(f'\t\t\tproductRefGroup = {prod_grp_id} /* Products */;')
out.append('\t\t\tprojectDirPath = "";')
out.append('\t\t\tprojectRoot = "";')
out.append('\t\t\ttargets = (')
out.append(f'\t\t\t\t{target_ios_id} /* ShineMaps */,')
out.append(f'\t\t\t\t{target_watch_id} /* ShineMapsWatch */,')
out.append('\t\t\t);')
out.append('\t\t};')
out.append('/* End PBXProject section */')
out.append('')

# PBXResourcesBuildPhase
out.append('/* Begin PBXResourcesBuildPhase section */')
out.append(f'\t\t{resources_phase_ios_id} /* Resources */ = {{')
out.append('\t\t\tisa = PBXResourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append(f'\t\t{resources_phase_watch_id} /* Resources */ = {{')
out.append('\t\t\tisa = PBXResourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = ();')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXResourcesBuildPhase section */')
out.append('')

# PBXSourcesBuildPhase
out.append('/* Begin PBXSourcesBuildPhase section */')
out.append(f'\t\t{sources_phase_ios_id} /* Sources */ = {{')
out.append('\t\t\tisa = PBXSourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = (')
for fname, b_id in build_files_ios.items():
    out.append(f'\t\t\t\t{b_id} /* {fname} in Sources */,')
out.append('\t\t\t);')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')

out.append(f'\t\t{sources_phase_watch_id} /* Sources */ = {{')
out.append('\t\t\tisa = PBXSourcesBuildPhase;')
out.append('\t\t\tbuildActionMask = 2147483647;')
out.append('\t\t\tfiles = (')
for fname, b_id in build_files_watch.items():
    leaf = os.path.basename(fname)
    out.append(f'\t\t\t\t{b_id} /* {leaf} in Sources */,')
out.append('\t\t\t);')
out.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
out.append('\t\t};')
out.append('/* End PBXSourcesBuildPhase section */')
out.append('')

# XCBuildConfiguration
out.append('/* Begin XCBuildConfiguration section */')
out.append(f'\t\t{cfg_proj_debug_id} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
out.append('\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
out.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
out.append('\t\t\t\tCLANG_ENABLE_MODULES = YES;')
out.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
out.append('\t\t\t\tCOPY_PHASE_STRIP = NO;')
out.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;')
out.append('\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
out.append('\t\t\t\tENABLE_TESTABILITY = YES;')
out.append('\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
out.append('\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;')
out.append('\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;')
out.append('\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");')
out.append('\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;')
out.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;')
out.append('\t\t\t\tONLY_ACTIVE_ARCH = YES;')
out.append('\t\t\t\tSDKROOT = iphoneos;')
out.append('\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";')
out.append('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')

out.append(f'\t\t{cfg_proj_release_id} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
out.append('\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
out.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
out.append('\t\t\t\tCLANG_ENABLE_MODULES = YES;')
out.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
out.append('\t\t\t\tCOPY_PHASE_STRIP = NO;')
out.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
out.append('\t\t\t\tENABLE_NS_ASSERTIONS = NO;')
out.append('\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
out.append('\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
out.append('\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;')
out.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;')
out.append('\t\t\t\tSDKROOT = iphoneos;')
out.append('\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;')
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')

# Target iOS Configurations
out.append(f'\t\t{cfg_target_ios_debug_id} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
out.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
out.append('\t\t\t\tDEVELOPMENT_TEAM = 9CBRG74884;')
out.append('\t\t\t\tGENERATE_INFOPLIST_FILE = NO;')
out.append('\t\t\t\tINFOPLIST_FILE = Info.plist;')
out.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
out.append('\t\t\t\tMARKETING_VERSION = 2.1.0;')
out.append('\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cokistudios.shinemaps;')
out.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
out.append('\t\t\t\tSWIFT_VERSION = 5.0;')
out.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')

out.append(f'\t\t{cfg_target_ios_release_id} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
out.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
out.append('\t\t\t\tDEVELOPMENT_TEAM = 9CBRG74884;')
out.append('\t\t\t\tGENERATE_INFOPLIST_FILE = NO;')
out.append('\t\t\t\tINFOPLIST_FILE = Info.plist;')
out.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
out.append('\t\t\t\tMARKETING_VERSION = 2.1.0;')
out.append('\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cokistudios.shinemaps;')
out.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
out.append('\t\t\t\tSWIFT_VERSION = 5.0;')
out.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')

# Target Watch Configurations
out.append(f'\t\t{cfg_target_watch_debug_id} /* Debug */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
out.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
out.append('\t\t\t\tDEVELOPMENT_TEAM = 9CBRG74884;')
out.append('\t\t\t\tGENERATE_INFOPLIST_FILE = NO;')
out.append('\t\t\t\tINFOPLIST_FILE = Watch/Info.plist;')
out.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
out.append('\t\t\t\tMARKETING_VERSION = 2.1.0;')
out.append('\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cokistudios.shinemaps.watchkitapp;')
out.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
out.append('\t\t\t\tSDKROOT = watchos;')
out.append('\t\t\t\tSWIFT_VERSION = 5.0;')
out.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "4";')
out.append('\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;')
out.append('\t\t\t};')
out.append('\t\t\tname = Debug;')
out.append('\t\t};')

out.append(f'\t\t{cfg_target_watch_release_id} /* Release */ = {{')
out.append('\t\t\tisa = XCBuildConfiguration;')
out.append('\t\t\tbuildSettings = {')
out.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
out.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
out.append('\t\t\t\tDEVELOPMENT_TEAM = 9CBRG74884;')
out.append('\t\t\t\tGENERATE_INFOPLIST_FILE = NO;')
out.append('\t\t\t\tINFOPLIST_FILE = Watch/Info.plist;')
out.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
out.append('\t\t\t\tMARKETING_VERSION = 2.1.0;')
out.append('\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.cokistudios.shinemaps.watchkitapp;')
out.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
out.append('\t\t\t\tSDKROOT = watchos;')
out.append('\t\t\t\tSWIFT_VERSION = 5.0;')
out.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "4";')
out.append('\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;')
out.append('\t\t\t};')
out.append('\t\t\tname = Release;')
out.append('\t\t};')
out.append('/* End XCBuildConfiguration section */')
out.append('')

# XCConfigurationList
out.append('/* Begin XCConfigurationList section */')
out.append(f'\t\t{cfg_list_proj_id} /* Build configuration list for PBXProject "ShineMaps" */ = {{')
out.append('\t\t\tisa = XCConfigurationList;')
out.append('\t\t\tbuildConfigurations = (')
out.append(f'\t\t\t\t{cfg_proj_debug_id} /* Debug */,')
out.append(f'\t\t\t\t{cfg_proj_release_id} /* Release */,')
out.append('\t\t\t);')
out.append('\t\t\tdefaultConfigurationIsVisible = 0;')
out.append('\t\t\tdefaultConfigurationName = Release;')
out.append('\t\t};')

out.append(f'\t\t{cfg_list_target_ios_id} /* Build configuration list for PBXNativeTarget "ShineMaps" */ = {{')
out.append('\t\t\tisa = XCConfigurationList;')
out.append('\t\t\tbuildConfigurations = (')
out.append(f'\t\t\t\t{cfg_target_ios_debug_id} /* Debug */,')
out.append(f'\t\t\t\t{cfg_target_ios_release_id} /* Release */,')
out.append('\t\t\t);')
out.append('\t\t\tdefaultConfigurationIsVisible = 0;')
out.append('\t\t\tdefaultConfigurationName = Release;')
out.append('\t\t};')

out.append(f'\t\t{cfg_list_target_watch_id} /* Build configuration list for PBXNativeTarget "ShineMapsWatch" */ = {{')
out.append('\t\t\tisa = XCConfigurationList;')
out.append('\t\t\tbuildConfigurations = (')
out.append(f'\t\t\t\t{cfg_target_watch_debug_id} /* Debug */,')
out.append(f'\t\t\t\t{cfg_target_watch_release_id} /* Release */,')
out.append('\t\t\t);')
out.append('\t\t\tdefaultConfigurationIsVisible = 0;')
out.append('\t\t\tdefaultConfigurationName = Release;')
out.append('\t\t};')
out.append('/* End XCConfigurationList section */')

out.append('\t};')
out.append(f'\trootObject = {proj_id} /* Project object */;')
out.append('}')

content = '\n'.join(out) + '\n'

dirs = [
    '/Users/jerix/Documents/Xcode/Forkar/ShineMaps/ShineMaps.xcodeproj',
    '/Users/jerix/Documents/Xcode/Forkar/Shine Maps/Shine Maps.xcodeproj',
    '/Users/jerix/cokistudios.github.io/ShineMaps.iOS/ShineMaps.xcodeproj'
]

for d in dirs:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'project.pbxproj'), 'w') as f:
        f.write(content)
    print('Generated:', d)
