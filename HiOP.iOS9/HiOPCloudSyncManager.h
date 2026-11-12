//
//  HiOPCloudSyncManager.h
//  HiOP for iOS 9 (Coki Studios)
//  CloudKit & NSUbiquitousKeyValueStore bridge for Looping Scripts
//

#import <Foundation/Foundation.h>

@protocol HiOPCloudSyncDelegate <NSObject>
@optional
- (void)cloudSyncDidReceiveRemoteUpdateWithCode:(NSString *)code filename:(NSString *)filename;
- (void)cloudSyncStatusDidChange:(BOOL)isAvailable accountStatus:(NSString *)statusText;
@end

@interface HiOPCloudSyncManager : NSObject

@property (nonatomic, weak) id<HiOPCloudSyncDelegate> delegate;
@property (nonatomic, readonly) BOOL isiCloudAvailable;
@property (nonatomic, readonly) NSString *statusDescription;

+ (instancetype)sharedManager;

- (void)startSync;
- (void)saveScriptWithCode:(NSString *)code filename:(NSString *)filename;
- (NSString *)loadLastScriptCode;
- (NSString *)loadLastFilename;

@end
