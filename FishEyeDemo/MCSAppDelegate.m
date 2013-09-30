//
//  MCSAppDelegate.m
//  FishEyeDemo
//
//  Created by Bartosz Ciechanowski on 8/29/13.
//  Copyright (c) 2013 Macoscope. All rights reserved.
//

#import "MCSAppDelegate.h"
#import "MCSViewController.h"

@implementation MCSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  MCSViewController *viewController = [[MCSViewController alloc] init];
  [self.window setRootViewController:viewController];
  [self.window makeKeyAndVisible];
  
  return YES;
}

@end
