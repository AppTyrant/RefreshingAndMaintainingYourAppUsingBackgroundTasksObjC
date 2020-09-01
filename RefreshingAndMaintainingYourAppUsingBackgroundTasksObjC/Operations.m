//
//  Operations.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import "Operations.h"

@interface FetchMostRecentEntryOperation()

@property (nonatomic,strong) NSManagedObjectContext *context;

@end

@implementation FetchMostRecentEntryOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        _context = context;
    }
    return self;
}

-(void)main
{
    NSFetchRequest *request = [FeedEntry fetchRequest];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    request.fetchLimit = 1;
    
    [self.context performBlockAndWait:^{
       
        NSError *error = nil;
        NSArray *result = [self.context executeFetchRequest:request error:&error];
        
        if (result.count > 0)
        {
            self.result = result.firstObject;
        }
        else if (error != nil)
        {
            NSLog(@"Error fetching latest FeedEntry: %@",error);
        }
        else
        {
            NSLog(@"Didn't fetch anything. FeedEntry is empty.");
        }
        
    }];
}

@end

#import <stdatomic.h>

@interface DownloadEntriesFromServerOperation()
{
    atomic_bool _downloadingBacking;
    atomic_bool _finishedOpBacking;
}

@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSDate *sinceDate;
@property (nonatomic,strong) id<Server>server;
@property (nullable,strong,readwrite) NSArray<ServerEntry*>*downloadedEntriesResult;
@property (nullable,strong,readwrite) NSError *error;
@property (strong,nonatomic) id<DownloadTask>currentDownloadTask;

@end

@implementation DownloadEntriesFromServerOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                                server:(id<Server>)server
{
    self = [super init];
    if (self)
    {
        _context = context;
        _server = server;
        atomic_store(&_downloadingBacking, NO);
        atomic_store(&_finishedOpBacking, NO);
    }
    return self;
}

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                                server:(id<Server>)server
                             sinceDate:(NSDate*)date
{
    self = [super init];
    if (self)
    {
        _context = context;
        _sinceDate = date;
        _server = server;
        atomic_store(&_downloadingBacking, NO);
        atomic_store(&_finishedOpBacking, NO);
    }
    return self;
}

-(BOOL)isAsynchronous
{
    return YES;
}

-(BOOL)isExecuting
{
    BOOL downloading = atomic_load(&_downloadingBacking);
    return downloading;
}

-(BOOL)isFinished
{
    BOOL finished = atomic_load(&_finishedOpBacking);
    return finished;
}

-(void)cancel
{
    [super cancel];
    [self.currentDownloadTask cancel];
}

-(void)_doFinishWithEntries:(NSArray<ServerEntry*>*)entriesOrNil error:(NSError*)errorOrNil
{
    BOOL downloading = atomic_load(&_downloadingBacking);
    if (!downloading)
    {
        NSLog(@"unexpected: called private method to finish the operation but the operation is not executing.");
        return;
    }
          
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
          
    atomic_store(&_downloadingBacking, NO);
    self.downloadedEntriesResult = entriesOrNil;
    self.error = errorOrNil;
    self.currentDownloadTask = nil;
    atomic_store(&_finishedOpBacking, YES);
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

-(void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    atomic_store(&_downloadingBacking, YES);
    [self didChangeValueForKey:@"isExecuting"];
        
    NSDate *sinceDate = self.sinceDate;
    if (self.isCancelled || sinceDate == nil)
    {
        [self _doFinishWithEntries:nil error:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
        return;
    }
    
    self.currentDownloadTask = [self.server fetchEntriesSinceStartDate:sinceDate completion:^(NSArray<ServerEntry*>*_Nullable entries,
                                                                                              NSError *_Nullable error)
    {
        [self _doFinishWithEntries:entries error:error];
    }];
}

@end

@interface AddEntriesToStoreOperation()

@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSArray<ServerEntry*>*entries;

@end

@implementation AddEntriesToStoreOperation

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                               entries:(nonnull NSArray<ServerEntry*>*)entries
                                 delay:(NSTimeInterval)delay
{
    self = [super init];
    if (self)
    {
        _context = context;
        _timeInterval = delay;
        _entries = entries;
    }
    return self;
}

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        _context = context;
    }
    return self;
}

-(void)main
{
    NSArray *entries = self.entries;
    if (entries.count == 0)
    {
        return;
    }
    NSTimeInterval delay = self.timeInterval;
    
    [self.context performBlockAndWait:^{
        
        for (ServerEntry *aEntry in entries)
        {
            //_ = FeedEntry(context: context, serverEntry: entry)
           [FeedEntry createWithServerEntry:aEntry inManagedObjectContext:self.context];
            
            NSLog(@"Adding entry with timestamp: \(entry.timestamp)");
            
            // Simulate a slow process by sleeping
            if (delay > 0)
            {
                [NSThread sleepForTimeInterval:delay];
            }
            
            NSError *errorSaving = nil;
            if (![self.context save:&errorSaving])
            {
                NSLog(@"Error saving entries: %@",errorSaving);
            }
          

            if (self.isCancelled)
            {
                break;
            }
        }
        
    }];
}

@end

@interface DeleteFeedEntriesOperation()

@property (nonatomic,strong) NSManagedObjectContext *context;

@end

@implementation DeleteFeedEntriesOperation

-(instancetype)initWithContext:(NSManagedObjectContext*)context
                     predicate:(NSPredicate*)predicate
                         delay:(NSTimeInterval)delay
{
    self = [super init];
    if (self)
    {
        _context = context;
        _timeInterval = delay;
        _predicate = predicate;
    }
    return self;
}

-(nonnull instancetype)initWithContext:(nonnull NSManagedObjectContext*)context
                             predicate:(nullable NSPredicate*)predicate
{
    return [self initWithContext:context predicate:predicate delay:0.0005];
}

-(instancetype)initWithContext:(NSManagedObjectContext*)context
{
    return [self initWithContext:context predicate:nil delay:0.0005];
}

-(void)main
{
    NSTimeInterval delay = self.timeInterval;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    fetchRequest.predicate = self.predicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    
    [self.context performBlockAndWait:^{
        NSError *fetchError = nil;
        NSArray *entriesToDelete = [self.context executeFetchRequest:fetchRequest error:&fetchError];
        
        if (entriesToDelete != nil)
        {
            for (NSManagedObject *aObj in entriesToDelete)
            {
                [self.context deleteObject:aObj];
                
                 // Simulate a slow process by sleeping.
                if (delay > 0)
                {
                    [NSThread sleepForTimeInterval:delay];
                }
                
                if (self.isCancelled)
                {
                    break;
                }
            }
            
            NSError *saveError = nil;
            if (![self.context save:&saveError])
            {
                NSLog(@"Error deleting entries: %@",saveError);
            }
        }
        else
        {
            NSLog(@"Error deleting entries: %@",fetchError);
        }
        
    }];
}

@end

@implementation NSOperationQueue (GetOperationsToFetchLatestEntries)

+(NSArray<NSOperation*>*)getOperationsToFetchLatestEntriesUsingContext:(NSManagedObjectContext*)context server:(id<Server>)server
{
    FetchMostRecentEntryOperation *fetchMostRecentEntry = [[FetchMostRecentEntryOperation alloc]initWithContext:context];
    DownloadEntriesFromServerOperation *downloadFromServer = [[DownloadEntriesFromServerOperation alloc]initWithContext:context
                                                                                                                 server:server];
    
        
    NSBlockOperation *passTimestampToServer = [NSBlockOperation blockOperationWithBlock:^{
        FeedEntry *result = fetchMostRecentEntry.result;
        NSDate *timestamp = result.timestamp;
        if (timestamp == nil)
        {
            [downloadFromServer cancel];
        }
        else
        {
            downloadFromServer.sinceDate = timestamp;
        }
    }];
         
    
    [passTimestampToServer addDependency:fetchMostRecentEntry];
    [downloadFromServer addDependency:passTimestampToServer];
      
    AddEntriesToStoreOperation *addToStore = [[AddEntriesToStoreOperation alloc]initWithContext:context];
    
    NSBlockOperation *passServerResultsToStore = [NSBlockOperation blockOperationWithBlock:^{
       
        NSArray *entries = downloadFromServer.downloadedEntriesResult;
        if (entries.count == 0)
        {
            [addToStore cancel];
        }
        else
        {
            addToStore.entries = entries;
        }
    }];
   
    [passServerResultsToStore addDependency:downloadFromServer];
    [addToStore addDependency:passServerResultsToStore];
          
    return @[fetchMostRecentEntry,
             passTimestampToServer,
             downloadFromServer,
             passServerResultsToStore,
             addToStore];
}


@end

@implementation FeedEntry (FeedEntryFromServerEntry)

+(FeedEntry*)createWithServerEntry:(nonnull ServerEntry*)serverEntry
            inManagedObjectContext:(nonnull NSManagedObjectContext*)context
{
    FeedEntry *feedEntry = [[FeedEntry alloc]initWithContext:context];
    feedEntry.firstColor = serverEntry.firstColor;
    feedEntry.secondColor = serverEntry.secondColor;
    feedEntry.gradientDirection = serverEntry.gradientDirection;
    feedEntry.timestamp = serverEntry.timestamp;
    return feedEntry;
}

@end
