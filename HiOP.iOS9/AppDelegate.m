//
//  AppDelegate.m
//  HiOP for iOS 9 (Coki Studios)
//

#import "AppDelegate.h"
#import "HiOPEditorViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRed:18/255.0 green:19/255.0 blue:22/255.0 alpha:1.0];
    
    HiOPEditorViewController *editorVC = [[HiOPEditorViewController alloc] init];
    self.window.rootViewController = editorVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
