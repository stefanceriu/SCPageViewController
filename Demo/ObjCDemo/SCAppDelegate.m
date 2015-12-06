//
//  SCAppDelegate.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 10/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCAppDelegate.h"
#import "SCRootViewController.h"

@implementation SCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[SCRootViewController alloc] initWithNibName:NSStringFromClass([SCRootViewController class]) bundle:nil];
	[self.window makeKeyAndVisible];
	return YES;
}

@end
