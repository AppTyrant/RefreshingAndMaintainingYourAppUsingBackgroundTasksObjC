//
//  FeedTableViewController.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
@class NSFetchRequest;

@interface FeedTableViewController : UITableViewController

@property (nonatomic,strong) id<Server>server;

@property (nonatomic,strong) NSFetchRequest *fetchRequest;

@end

