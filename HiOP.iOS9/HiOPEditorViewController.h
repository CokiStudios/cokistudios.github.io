//
//  HiOPEditorViewController.h
//  HiOP for iOS 9 (Coki Studios)
//  Native Looping Script Editor & Cloud Console
//

#import <UIKit/UIKit.h>
#import "HiOPCloudSyncManager.h"

@interface HiOPEditorViewController : UIViewController <UITextViewDelegate, HiOPCloudSyncDelegate>

@property (nonatomic, strong) UITextView *codeTextView;
@property (nonatomic, strong) UITextView *consoleTextView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *hardwareLabel;

- (void)runLoopingScript;
- (void)syncWithiCloud;

@end
