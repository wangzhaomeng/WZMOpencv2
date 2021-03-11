//
//  AppDelegate.m
//  WZMOpencv2
//
//  Created by Zhaomeng Wang on 2021/3/10.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    self.window.rootViewController = [[ViewController alloc] init];
    
    //禁止多点触控
    [[UIView appearance] setExclusiveTouch:YES];
    
    return YES;
}

@end
