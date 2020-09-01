//
//  MockServer.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "MockServer.h"

@interface MockDownloadTask : NSObject <DownloadTask>

@property dispatch_queue_t queue;
@property (readwrite,getter=isCancelled) BOOL cancelled;
@property (nonatomic, copy) void (^onCancelled)(void);

@end

@implementation MockDownloadTask

-(instancetype)initWithDelay:(NSTimeInterval)delay
                       queue:(dispatch_queue_t)dispatchQueue
                   onSuccess:(void (^)(void))onSuccess
                 onCancelled:(void (^)(void))onCancelled
{
    self = [super init];
    if (self)
    {
        _onCancelled = [onCancelled copy];
        _queue = dispatchQueue;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay * NSEC_PER_SEC)),
                       dispatchQueue, ^{
            
            if (!self.isCancelled)
            {
                onSuccess();
            }
        });
    }
    return self;
}

-(void)cancel
{
    dispatch_async(self.queue, ^{
        
        if (self.isCancelled)
        {
            NSLog(@"already cancelled");
        }
        else
        {
            self.cancelled = YES;
            if (self.onCancelled != nil)
            {
                self.onCancelled();
            }
        }
    });
}

@end


#define DEFAULT_INTERVAL_FOR_FAKE_ENTRY_CREATION 600.0
#define DEFAULT_VARIATION_FOR_FAKE_ENTRY_CREATION 300.0

@implementation MockServer

static dispatch_queue_t OurMockQueue = nil;

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OurMockQueue = dispatch_queue_create("MockServerQueue", NULL);
    });
}

-(nonnull id<DownloadTask>)fetchEntriesSinceStartDate:(nonnull NSDate*)startDate
                                           completion:(void (^_Nonnull)(NSArray<ServerEntry*>*_Nullable,
                                                                        NSError *_Nullable error))completion
{
    NSDate *now = [NSDate date];
    
    NSArray<ServerEntry*>*entries = [MockServer _generateFakeEntriesFromStartDate:startDate
                                                                        toEndDate:now
                                                                         interval:DEFAULT_INTERVAL_FOR_FAKE_ENTRY_CREATION
                                                                        variation:DEFAULT_VARIATION_FOR_FAKE_ENTRY_CREATION];
    
    NSTimeInterval maxDelay = 2.5;
    NSTimeInterval wholeNumberDelay = arc4random_uniform(3);
    srand48(time(0));
    NSTimeInterval decimalPortionDelay = drand48()-0.5;
    NSTimeInterval delay = wholeNumberDelay + decimalPortionDelay;
    if (delay > maxDelay) { delay = maxDelay; }
    else if (delay < 0.0) { delay = 0.0; }
    
    MockDownloadTask *mockTest = [[MockDownloadTask alloc]initWithDelay:delay
                                                                  queue:OurMockQueue
                                                              onSuccess:^
    {
        completion(entries,nil);
    }
    onCancelled:^{
        completion(nil,
                   [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]);
    }];
    
    return mockTest;
}

/*
func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> DownloadTask {
    let now = Date()

    let entries = generateFakeEntries(from: startDate, to: now)

    return MockDownloadTask(delay: Double.random(in: 0..<2.5), queue: queue, onSuccess: {
        completion(.success(entries))
    }, onCancelled: {
        completion(.failure(DownloadError.cancelled))
    })
}
*/

+(NSArray<ServerEntry*>*)_generateFakeEntriesFromStartDate:(NSDate*)startDate
                                                 toEndDate:(NSDate*)endDate
                                                  interval:(NSTimeInterval)interval
                                                 variation:(NSTimeInterval)variation
{
    NSMutableArray<ServerEntry*>*entriesArray = [NSMutableArray array];
    NSTimeInterval startInterval = startDate.timeIntervalSince1970;
    NSTimeInterval endInterval = endDate.timeIntervalSince1970;
    
    for (NSTimeInterval time = endInterval; time > startInterval; time = time-interval)
    {
        double negatedVariation = variation*-1.0;
        double randomVariation = negatedVariation + arc4random_uniform(variation-negatedVariation+1);
        NSTimeInterval fakeTime = MAX(startInterval, MIN(time+randomVariation, endInterval));
        NSDate *fakeTimeDate = [NSDate dateWithTimeIntervalSince1970:fakeTime];
        
        double randomGradient = arc4random_uniform(361);
        ServerEntry *fakeEntry = [[ServerEntry alloc]initWithTimeStamp:fakeTimeDate
                                                            firstColor:[Color makeRandomColor]
                                                           secondColor:[Color makeRandomColor]
                                                     gradientDirection:randomGradient];
        
        [entriesArray addObject:fakeEntry];
    }
   
    return entriesArray;
}
/*
private func generateFakeEntries(from startDate: Date,
                                 to endDate: Date,
                                 interval: TimeInterval = 60 * 10,
                                 variation: TimeInterval = 5 * 60) -> [ServerEntry] {
    var entries = [ServerEntry]()
    for time in stride(from: startDate.timeIntervalSince1970, to: endDate.timeIntervalSince1970, by: interval) {
        let randomVariation = Double.random(in: -(variation)...(variation))
        let fakeTime = max(startDate.timeIntervalSince1970, min(time + randomVariation, endDate.timeIntervalSince1970))
        entries.append(ServerEntry.makeRandom(timestamp: Date(timeIntervalSince1970: fakeTime)))
    }
    return entries
}
*/


@end

#import "Operations.h"

@implementation PersistentContainer (MockExtension)

-(void)loadInitialDataOnlyIfNeeded:(BOOL)onlyIfNeeded
{
    NSManagedObjectContext *context = [self newBackgroundContext];
    [context performBlock:^
    {
        NSFetchRequest *allEntriesRequest = [FeedEntry fetchRequest];
        if (!onlyIfNeeded)
        {
            // Delete all data currently in the store
            NSBatchDeleteRequest *deleteAllRequest = [[NSBatchDeleteRequest alloc]initWithFetchRequest:allEntriesRequest];
            deleteAllRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
            NSError *errorDeleting = nil;
            NSBatchDeleteResult *deleteResult = [context executeRequest:deleteAllRequest error:&errorDeleting];
            id deletedObjects = deleteResult.result;
            if (deletedObjects != nil)
            {
                [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey:deletedObjects}
                                                             intoContexts:@[self.viewContext]];
            }
            else
            {
                NSLog(@"failed to delete data with error: %@",errorDeleting);
            }
        }
        
        NSError *fetchCountError = nil;
        if (!onlyIfNeeded
            || [context countForFetchRequest:allEntriesRequest error:&fetchCountError] == 0)
        {
            NSDate *now = [NSDate date];
            NSTimeInterval timeIntervalToAdd = (7 * 24 * 60 * 60) * -1;
            NSDate *start = [now dateByAddingTimeInterval:timeIntervalToAdd];
            
           NSArray<ServerEntry*>*fakeEntries = [MockServer _generateFakeEntriesFromStartDate:start
                                                                                   toEndDate:now
                                                                                    interval:DEFAULT_INTERVAL_FOR_FAKE_ENTRY_CREATION
                                                                                   variation:DEFAULT_VARIATION_FOR_FAKE_ENTRY_CREATION];
            
            for (ServerEntry *aEntry in fakeEntries)
            {
                [FeedEntry createWithServerEntry:aEntry inManagedObjectContext:context];
            }
            
            NSError *errorSaving = nil;
            if ([context save:&errorSaving])
            {
                
            }
            else
            {
                NSLog(@"Error saving managed object context: %@",errorSaving);
            }
            
            self.lastCleaned = nil;
        }
        else if (fetchCountError != nil)
        {
            NSLog(@"Could not load initial data due to error: %@",fetchCountError);
        }
    }];
}

@end
