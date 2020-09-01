//
//  Operations.h
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import "FeedEntry+CoreDataClass.h"
#import "Server.h"

@interface FetchMostRecentEntryOperation : NSOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context;

@property (nullable,nonatomic,readwrite,strong) FeedEntry *result;

@end

@interface DownloadEntriesFromServerOperation : NSOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                                server:(id<Server>_Nonnull)server
                             sinceDate:(nonnull NSDate*)date;

@property (nullable,strong,readonly) NSArray<ServerEntry*>*downloadedEntriesResult;
@property (nullable,strong,readonly) NSError *error;

@end

@interface AddEntriesToStoreOperation : NSOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                               entries:(nonnull NSArray<ServerEntry*>*)entries
                                 delay:(NSTimeInterval)delay;

@property (nonatomic,readonly) NSTimeInterval timeInterval;

@end

@interface DeleteFeedEntriesOperation : NSOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                             predicate:(nullable NSPredicate*)predicate
                                 delay:(NSTimeInterval)delay;

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                             predicate:(nullable NSPredicate*)predicate;

@property (nullable,nonatomic,strong,readonly) NSPredicate *predicate;
@property (nonatomic,readonly) NSTimeInterval timeInterval;

@end

@interface NSOperationQueue (GetOperationsToFetchLatestEntries)

// Returns an array of operations for fetching the latest entries and then adding them to the Core Data store.
+(nonnull NSArray<NSOperation*>*)getOperationsToFetchLatestEntriesUsingContext:(nonnull NSManagedObjectContext*)context
                                                                        server:(nonnull id<Server>)server;

@end

@interface FeedEntry (FeedEntryFromServerEntry)

+(nonnull FeedEntry*)createWithServerEntry:(nonnull ServerEntry*)serverEntry
                    inManagedObjectContext:(nonnull NSManagedObjectContext*)context;

@end
