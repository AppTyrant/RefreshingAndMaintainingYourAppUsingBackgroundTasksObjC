//
//  Server.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "ServerEntry.h"

@protocol DownloadTask <NSObject>

@property (readonly,getter=isCancelled) BOOL cancelled;
-(void)cancel;

@end

@protocol Server <NSObject>

-(nonnull id<DownloadTask>)fetchEntriesSinceStartDate:(nonnull NSDate*)startDate
                                           completion:(void (^_Nonnull)(NSArray<ServerEntry*>*_Nullable,
                                                                        NSError *_Nullable error))block;

@end
