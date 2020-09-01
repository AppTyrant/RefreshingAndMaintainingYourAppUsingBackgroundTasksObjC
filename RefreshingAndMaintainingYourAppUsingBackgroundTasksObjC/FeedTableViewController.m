//
//  FeedTableViewController.m
//  RefreshingAndMaintainingYourAppUsingBackgroundTasksObjC
//
//  Created by ANTHONY CRUZ on 5/19/20.
//  Copyright © 2020 App Tyrant Corp. All rights reserved.
//

#import "FeedTableViewController.h"
#import "Operations.h"
#import "FeedEntryTableViewCell.h"
#import "PersistentContainer.h"
#import "AppDelegate.h"

@interface FeedTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FeedTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
           
    if (self.fetchRequest == nil)
    {
        self.fetchRequest = [FeedEntry fetchRequest];
        self.fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    }
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:self.fetchRequest
                                                                       managedObjectContext:[PersistentContainer sharedContainer].viewContext
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:self.description];
    self.fetchedResultsController.delegate = self;
    
    NSError *errorFetching = nil;
    
    if (![self.fetchedResultsController performFetch:&errorFetching])
    {
        NSLog(@"Error fetching results: %@",errorFetching);
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
-(void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController*)controller
 didChangeSection:(nonnull id<NSFetchedResultsSectionInfo>)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        break;
            
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        break;
            
        default:
        {
            NSLog(@"whoops!");
        }
        break;
    }
}

-(void)controller:(NSFetchedResultsController*)controller
  didChangeObject:(nonnull id)anObject
      atIndexPath:(nullable NSIndexPath*)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(nullable NSIndexPath*)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            //guard let newIndexPath = newIndexPath else { return }
            if (newIndexPath != nil)
            {
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else
            {
                NSLog(@"unexpected nil value for index path for inserted change type");
            }
        }
        break;
            
        case NSFetchedResultsChangeDelete:
        {
            if (indexPath != nil)
            {
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else
            {
                NSLog(@"unexpected nil value for index path for delete change type");
            }
        }
        break;
            
        case NSFetchedResultsChangeUpdate:
        {
            FeedEntryTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell != nil)
            {
                [self configureCell:cell atIndexPath:indexPath];
            }
        }
        break;
            
        case NSFetchedResultsChangeMove:
        {
            if (indexPath != nil && newIndexPath != nil)
            {
                [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            }
            else
            {
                NSLog(@"unexpected");
            }
        }
        break;
            
        default:
        {
            NSLog(@"whoops");
        }
        break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Table view data source/Delegate
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.fetchedResultsController.sections.count == 0)
    {
        NSLog(@"no section...");
        return 0;
    }
    
    id<NSFetchedResultsSectionInfo>sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedResultsController.sections.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    FeedEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"entryCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(FeedEntryTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    FeedEntry *feedEntry = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.feedEntry = feedEntry;
}

#pragma mark - Actions
-(IBAction)fetchLatestEntries:(UIRefreshControl*)sender
{
    [sender beginRefreshing];
           
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.qualityOfService = NSQualityOfServiceUserInitiated;
    queue.maxConcurrentOperationCount = 1;
           
    NSManagedObjectContext *context = [[PersistentContainer sharedContainer]newBackgroundContext];
    NSArray<NSOperation*>*operations = [NSOperationQueue getOperationsToFetchLatestEntriesUsingContext:context
                                                                                                server:self.server];
    
    
    [operations.lastObject setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender endRefreshing];
        });
    }];
    
    [queue addOperations:operations waitUntilFinished:NO];
}


-(IBAction)showActions:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
                                          
                                         
    alertController.popoverPresentationController.barButtonItem = sender;
                                          
    [alertController addAction:[UIAlertAction actionWithTitle:@"Reset Feed Data"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * _Nonnull action)
    {
        AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [appDelegate resetFeedData];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
