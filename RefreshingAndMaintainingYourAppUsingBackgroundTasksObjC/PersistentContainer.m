//
//  PersistentContainer.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 10/7/19.
//  Copyright © 2019 App Tyrant Corp. All rights reserved.
//

#import "PersistentContainer.h"
#import "Color.h"

@implementation PersistentContainer

+(nonnull PersistentContainer*)sharedContainer
{
    static PersistentContainer *sharedContainer = nil;
    
    static dispatch_once_t token;
    dispatch_once(&token,^{
       
        ColorTransformer *transformer = [[ColorTransformer alloc]init];
        [NSValueTransformer setValueTransformer:transformer forName:NSStringFromClass([ColorTransformer class])];
        
        sharedContainer = [[PersistentContainer alloc]initWithName:@"ColorFeed"];
        [sharedContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull desc,
                                                                     NSError * _Nullable error)
        {
            NSAssert(error == nil, @"Fatal error: %@",error);
            NSLog(@"Successfully loaded persistent store at: %@",desc.URL);
        }];
        
        sharedContainer.viewContext.automaticallyMergesChangesFromParent = YES;
        sharedContainer.viewContext.mergePolicy = [[NSMergePolicy alloc]initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
        
    });
    return sharedContainer;
}

-(void)setLastCleaned:(NSDate*)lastCleaned
{
    [[NSUserDefaults standardUserDefaults]setObject:lastCleaned forKey:@"lastCleaned"];
}

-(NSDate*)lastCleaned
{
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"lastCleaned"];
}

-(NSManagedObjectContext*)newBackgroundContext
{
    NSManagedObjectContext *bgContext = [super newBackgroundContext];
    bgContext.automaticallyMergesChangesFromParent = YES;
    bgContext.mergePolicy = [[NSMergePolicy alloc]initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
    return bgContext;
}

@end
