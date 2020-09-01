//
//  MockServer.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "Server.h"

@interface MockServer : NSObject <Server>

@end

#import "PersistentContainer.h"

@interface PersistentContainer (MockExtension)

// Fills the Core Data store with initial fake data
  // If onlyIfNeeded is true, only does so if the store is empty.
-(void)loadInitialDataOnlyIfNeeded:(BOOL)onlyIfNeeded;

@end
