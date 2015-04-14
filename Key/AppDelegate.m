//
//  AppDelegate.m
//  Key
//
//  Created by Brendan Farmer on 1/15/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "AppDelegate.h"
#import "PushManager.h"
#import "CollapsingFutures.h"
#import "KAccountManager.h"
#import "KStorageManager.h"
#import "KUser.h"

#define kUserUniqueId @"userId"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[PushManager sharedManager] registerForRemoteNotifications];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navController = [storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    UIViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];

    if([KAccountManager sharedManager].user) {
        [self.window setRootViewController:navController];
    }else {
        [self.window setRootViewController:loginViewController];
    }
    return YES;
}

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    [PushManager.sharedManager.userNotificationFutureSource trySetResult:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self saveCurrentUser];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[KAccountManager sharedManager] asyncGetFeed];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self restoreCurrentUser];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveCurrentUser];
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PushManager sharedManager] respondToRemoteNotification];
}

- (void)saveCurrentUser {
    [[NSUserDefaults standardUserDefaults] setObject:[KAccountManager sharedManager].user.uniqueId forKey:kUserUniqueId];
}

- (void)restoreCurrentUser {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserUniqueId];
    if(userId) {
        KUser *user = (KUser *)[[KStorageManager sharedManager] objectForKey:userId inCollection:[KUser collection]];
        if(user) {
            [[KAccountManager sharedManager] setUser:user];
        }
    }
}

@end
