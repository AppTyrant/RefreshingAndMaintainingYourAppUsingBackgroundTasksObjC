//
//  PersistentContainer.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface PersistentContainer : NSPersistentContainer

+(nonnull PersistentContainer*)sharedContainer;

@property (nullable,nonatomic,strong) NSDate *lastCleaned;

@end
