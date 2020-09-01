//
//  FeedEntryTableViewCell.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/20/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedEntry+CoreDataClass.h"

@interface FeedEntryTableViewCell : UITableViewCell

@property (nonatomic,strong) FeedEntry *feedEntry;

@end
