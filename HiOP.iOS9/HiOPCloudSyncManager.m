//
//  HiOPCloudSyncManager.m
//  HiOP for iOS 9 (Coki Studios)
//

#import "HiOPCloudSyncManager.h"

static NSString * const kHiOPKeyLastCode = @"hiop_cloud_script_code";
static NSString * const kHiOPKeyLastFilename = @"hiop_cloud_script_filename";
static NSString * const kHiOPKeyLastTimestamp = @"hiop_cloud_script_timestamp";

@interface HiOPCloudSyncManager ()
@property (nonatomic, strong) NSUbiquitousKeyValueStore *cloudStore;
@end

@implementation HiOPCloudSyncManager

+ (instancetype)sharedManager {
    static HiOPCloudSyncManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    }
    return self;
}

- (BOOL)isiCloudAvailable {
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    return (token != nil);
}

- (NSString *)statusDescription {
    if ([self isiCloudAvailable]) {
        return @"☁️ iCloud Conectado (Sincronización Activa)";
    } else {
        return @"💾 Almacenamiento Local (Sin sesión de iCloud)";
    }
}

- (void)startSync {
    // 1. Escuchar notificaciones de cambios remotos de iCloud
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCloudStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:self.cloudStore];
    
    // 2. Sincronizar cambios iniciales
    [self.cloudStore synchronize];
    
    // 3. Notificar al delegado
    if ([self.delegate respondsToSelector:@selector(cloudSyncStatusDidChange:accountStatus:)]) {
        [self.delegate cloudSyncStatusDidChange:[self isiCloudAvailable]
                                  accountStatus:[self statusDescription]];
    }
}

- (void)handleCloudStoreDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    
    if (!reasonForChange) return;
    
    NSInteger reason = [reasonForChange integerValue];
    if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
        NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        if ([changedKeys containsObject:kHiOPKeyLastCode] || [changedKeys containsObject:kHiOPKeyLastFilename]) {
            NSString *newCode = [self.cloudStore stringForKey:kHiOPKeyLastCode];
            NSString *newFilename = [self.cloudStore stringForKey:kHiOPKeyLastFilename];
            
            // Actualizar caché local
            if (newCode) {
                [[NSUserDefaults standardUserDefaults] setObject:newCode forKey:kHiOPKeyLastCode];
            }
            if (newFilename) {
                [[NSUserDefaults standardUserDefaults] setObject:newFilename forKey:kHiOPKeyLastFilename];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(cloudSyncDidReceiveRemoteUpdateWithCode:filename:)]) {
                    [self.delegate cloudSyncDidReceiveRemoteUpdateWithCode:newCode filename:newFilename];
                }
            });
        }
    }
}

- (void)saveScriptWithCode:(NSString *)code filename:(NSString *)filename {
    if (!code) code = @"";
    if (!filename) filename = @"main.loop";
    
    double now = [[NSDate date] timeIntervalSince1970];
    
    // 1. Guardar en NSUbiquitousKeyValueStore (iCloud)
    [self.cloudStore setString:code forKey:kHiOPKeyLastCode];
    [self.cloudStore setString:filename forKey:kHiOPKeyLastFilename];
    [self.cloudStore setDouble:now forKey:kHiOPKeyLastTimestamp];
    [self.cloudStore synchronize];
    
    // 2. Guardar en caché local (NSUserDefaults & sandbox documents)
    [[NSUserDefaults standardUserDefaults] setObject:code forKey:kHiOPKeyLastCode];
    [[NSUserDefaults standardUserDefaults] setObject:filename forKey:kHiOPKeyLastFilename];
    [[NSUserDefaults standardUserDefaults] setDouble:now forKey:kHiOPKeyLastTimestamp];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 3. Escribir archivo físico en Documents
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        NSString *docDir = paths[0];
        NSString *filePath = [docDir stringByAppendingPathComponent:filename];
        [code writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (NSString *)loadLastScriptCode {
    // 1. Intentar leer de iCloud
    NSString *code = [self.cloudStore stringForKey:kHiOPKeyLastCode];
    if (code && code.length > 0) {
        return code;
    }
    // 2. Fallback local
    code = [[NSUserDefaults standardUserDefaults] stringForKey:kHiOPKeyLastCode];
    if (code && code.length > 0) {
        return code;
    }
    // 3. Código inicial de bienvenida de Looping
    return @"// HiOP para iOS 9 — Coki Studios\n// Script de ejemplo para iPad 3 Retina (Apple A5X)\n\ntarget \"shine_ui\"\nimport \"physics.loop\"\n\nui Screen {\n    title: \"Coki Studios Mobile Lab\"\n    theme: \"dark\"\n    \n    Widget EcoMonitor {\n        co2_saved: 14.8\n        points: 420\n        status: \"Supervisado\"\n    }\n}\n\nlog(\"✓ Looping Engine inicializado en iPad 3\");\n";
}

- (NSString *)loadLastFilename {
    NSString *fn = [self.cloudStore stringForKey:kHiOPKeyLastFilename];
    if (fn && fn.length > 0) return fn;
    fn = [[NSUserDefaults standardUserDefaults] stringForKey:kHiOPKeyLastFilename];
    return fn ?: @"sample.loop";
}

@end
