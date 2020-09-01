//
//  AppDelegate.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import "AppDelegate.h"
#import "MockServer.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import "Operations.h"

#define BACKGROUND_TASK_REFRESH_IDENTIFIER @"com.example.atobjc-samplecode.ColorFeed.refresh"
#define BACKGROUND_TASK_DB_CLEANUP_IDENTIFIER @"com.example.atobjc-samplecode.ColorFeed.db_cleaning"

@interface AppDelegate ()
{
    MockServer *_server;
}

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    // Override point for customization after application launch.
    [[PersistentContainer sharedContainer]loadInitialDataOnlyIfNeeded:YES];
   
    
    //Registering Launch Handlers for Tasks
    [[BGTaskScheduler sharedScheduler]registerForTaskWithIdentifier:BACKGROUND_TASK_REFRESH_IDENTIFIER
                                                         usingQueue:nil
                                                      launchHandler:^(__kindof BGTask * _Nonnull task)
    {
        [self handleAppRefreshWithTask:task];
    }];
    
    [[BGTaskScheduler sharedScheduler]registerForTaskWithIdentifier:BACKGROUND_TASK_DB_CLEANUP_IDENTIFIER
                                                         usingQueue:nil
                                                      launchHandler:^(__kindof BGTask * _Nonnull task)
    {
        [self handleDatabaseCleaningWithTask:task];
    }];
    
    return YES;
}

-(void)applicationDidEnterBackground:(UIApplication*)application
{
    [self scheduleAppRefresh];
    [self scheduleDatabaseCleaningIfNeeded];
    
    /*
    How to Test Background Tasks (from https://developer.apple.com/documentation/backgroundtasks/starting_and_terminating_tasks_during_development?language=objc)
     
    Overview
     The delay between the time you schedule a background task and when the system launches your app to run the task can be many hours. While developing your app, you can use two private functions to start a task and to force early termination of the task according to your selected timeline. The debug functions work only on devices.
     
    Important
    Use private functions only during development. Including a reference to these functions in apps submitted to the App Store is cause for rejection.
     
     
    Launch a Task
    -------------
    To launch a task:
    1) Set a breakpoint in the code that executes after a successful call to submitTaskRequest:error:.
    2) Run your app on a device until the breakpoint pauses your app.
    3) In the debugger, execute the line shown below, substituting the identifier of the desired task for TASK_IDENTIFIER.
    4) Resume your app. The system calls the launch handler for the desired task.
    e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"TASK_IDENTIFIER"]
    
    Force Early Termination of a Task
    ---------------------------------
    To force termination of a task:
    1) Set a breakpoint in the desired task.
    2) Launch the task using the debugger as described in the previous section.
    3) Wait for your app to pause at the breakpoint.
    4) In the debugger, execute the line shown below, substituting the identifier of the desired task for TASK_IDENTIFIER.
    5) Resume your app. The system calls the expiration handler for the desired task.
    e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdent
     */
}

#pragma mark - Background Tasks
-(void)scheduleAppRefresh
{
    BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc]initWithIdentifier:BACKGROUND_TASK_REFRESH_IDENTIFIER];
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:15 * 60]; // Fetch no earlier than 15 minutes from now
    
    NSError *error = nil;
    if ([[BGTaskScheduler sharedScheduler]submitTaskRequest:request error:&error])
    {
        NSLog(@"Successfully scheduled app refresh.");
    }
    else
    {
        NSLog(@"Could not schedule app refresh: \(error)");
    }
}

-(void)handleAppRefreshWithTask:(BGAppRefreshTask*)task
{
    // Fetch the latest feed entries from server.
    [self scheduleAppRefresh];
       
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
       
    NSManagedObjectContext *context = [[PersistentContainer sharedContainer]newBackgroundContext];
    NSArray <NSOperation*>*operations = [NSOperationQueue getOperationsToFetchLatestEntriesUsingContext:context server:self.server];
    
    NSOperation *lastOperation = operations.lastObject;
       
    [task setExpirationHandler:^{
        // After all operations are cancelled, the completion block below is called to set the task to complete.
        [queue cancelAllOperations];
    }];

    __weak NSOperation *weakLastOperation = lastOperation;
    [lastOperation setCompletionBlock:^{
        __strong NSOperation *strongLastOperation = weakLastOperation;
        BOOL success = !strongLastOperation.isCancelled;
        [task setTaskCompletedWithSuccess:success];
    }];

    [queue addOperations:operations waitUntilFinished:NO];
}

-(void)scheduleDatabaseCleaningIfNeeded
{
    NSDate *lastCleanDate = [PersistentContainer sharedContainer].lastCleaned;
    if (lastCleanDate == nil) { lastCleanDate = [NSDate distantPast]; }

    NSDate *now = [NSDate date];
    NSTimeInterval oneWeekInterval = 7 * 24 * 60 * 60;
    NSDate *oneWeekFromLastCleanedDate = [lastCleanDate dateByAddingTimeInterval:oneWeekInterval];
    
    // Clean the database at most once per week.
    if ([now laterDate:oneWeekFromLastCleanedDate] == now)
    {
        BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc]initWithIdentifier:BACKGROUND_TASK_DB_CLEANUP_IDENTIFIER];
        request.requiresNetworkConnectivity = NO;
        request.requiresExternalPower = YES;
        
        NSError *error = nil;
        if ([[BGTaskScheduler sharedScheduler]submitTaskRequest:request error:&error])
        {
            NSLog(@"Successfully scheduled database cleanup operation.");
        }
        else
        {
            NSLog(@"Could not schedule database cleaning: %@",error);
        }
    }
    else
    {
        NSLog(@"Too early for cleanup.");
    }
}

-(void)handleDatabaseCleaningWithTask:(BGProcessingTask*)task
{
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
    
    NSManagedObjectContext *context = [[PersistentContainer sharedContainer]newBackgroundContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp < %@",[NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60]];
    DeleteFeedEntriesOperation *cleanDatabaseOperation = [[DeleteFeedEntriesOperation alloc]initWithContext:context predicate:predicate];
    
    [task setExpirationHandler:^{
        //After all operations are cancelled, the completion block below is called to set the task to complete.
        [queue cancelAllOperations];
    }];
    
    __weak DeleteFeedEntriesOperation *weakCleanDatabaseOperation = cleanDatabaseOperation;
    [cleanDatabaseOperation setCompletionBlock:^{
        __strong DeleteFeedEntriesOperation *strongCleanDatabaseOperation = weakCleanDatabaseOperation;
        BOOL success = !strongCleanDatabaseOperation.isCancelled;
        if (success)
        {
            // Update the last clean date to the current time.
            [PersistentContainer sharedContainer].lastCleaned = [NSDate date];
        }
        
        [task setTaskCompletedWithSuccess:success];
    }];
    
    [queue addOperation:cleanDatabaseOperation];
}

#pragma mark - UISceneSession lifecycle
-(UISceneConfiguration*)application:(UIApplication*)application
configurationForConnectingSceneSession:(UISceneSession*)connectingSceneSession
                              options:(UISceneConnectionOptions*)options
{
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    UISceneConfiguration *config = [[UISceneConfiguration alloc]initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
    return config;
}

#pragma mark - Reset Feed Data
-(void)resetFeedData
{
    [[PersistentContainer sharedContainer]loadInitialDataOnlyIfNeeded:NO];
}

#pragma mark - Getters
-(MockServer*)server
{
    if (_server == nil)
    {
        _server = [[MockServer alloc]init];
    }
    return _server;
}

@end
