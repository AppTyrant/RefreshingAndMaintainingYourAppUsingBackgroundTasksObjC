//
//  AppDelegate.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

-(void)resetFeedData;

@property (nonnull,nonatomic,strong,readonly) id<Server>server;

@end

