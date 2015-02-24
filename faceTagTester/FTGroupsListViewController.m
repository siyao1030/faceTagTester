//
//  FTGroupsListViewController.m
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/23/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupsListViewController.h"
#import "FTGroupPhotosViewController.h"
#import "FTGroupManagingViewController.h"
#import "FTGroup.h"

#define SIDE_PADDING 30

@interface FTGroupsListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@end

@implementation FTGroupsListViewController
@synthesize frc = _frc;

- (id)init {
    self = [super init];
    self.groups = [NSMutableArray arrayWithArray:[FTGroup fetchAll]];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, [self.view bounds].size.height) style:UITableViewStylePlain];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView setRowHeight:100];
    
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *createGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createGroupButtonPressed)];
    self.navigationItem.rightBarButtonItem = createGroupButton;
    
    return self;
}

- (NSFetchedResultsController *)frc {
    if (_frc != nil) {
        return _frc;
    }
    
    NSFetchRequest *frcRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor* startDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO];
    NSSortDescriptor* endDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"endDate" ascending:NO];
    [frcRequest setSortDescriptors:@[endDateDescriptor, startDateDescriptor]];
    [frcRequest setEntity:[FTGroup entity]];
    [frcRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:frcRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:nil cacheName:nil];

    self.frc = frc;
    [self.frc setDelegate:self];
    
    return _frc;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error;
    if (![[self frc] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    // Do any additional setup after loading the view.
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)createGroupButtonPressed {
    FTGroupManagingViewController *groupManagingView = [[FTGroupManagingViewController alloc] initWithGroup:nil];
    [groupManagingView setTarget:self];
    [groupManagingView setAction:@selector(newGroupAdded:)];

    [self.navigationController showViewController:groupManagingView sender:self];
    //group name
    //start and end date (optional) or select a range of photos (https://github.com/chiunam/CTAssetsPickerController)
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id  sectionInfo = [[_frc sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}


- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    FTGroup *group = [self.frc objectAtIndexPath:indexPath];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setText:group.name];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel sizeToFit];
    
    CGRect titleFrame = [titleLabel frame];
    titleFrame.origin.x = SIDE_PADDING;
    titleFrame.origin.y = SIDE_PADDING;
    [titleLabel setFrame:titleFrame];
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString *startDateString = [dateFormatter stringFromDate:group.startDate];
    NSString *endDateString = [dateFormatter stringFromDate:group.endDate];
    NSString *subtitleString = [NSString stringWithFormat:@"%@ - %@", startDateString, endDateString];
    
    [subtitleLabel setText:subtitleString];
    [subtitleLabel setFont:[UIFont systemFontOfSize:16]];
    [subtitleLabel setTextAlignment:NSTextAlignmentLeft];
    [subtitleLabel setTextColor:[UIColor blackColor]];
    [subtitleLabel sizeToFit];
    
    CGRect subtitleFrame = [subtitleLabel frame];
    subtitleFrame.origin.x = SIDE_PADDING;
    subtitleFrame.origin.y = CGRectGetMaxY(titleFrame) + 10;
    [subtitleLabel setFrame:subtitleFrame];
    
    [cell addSubview:titleLabel];
    [cell addSubview:subtitleLabel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FTGroup *group = [self.frc objectAtIndexPath:indexPath];
    FTGroupPhotosViewController *groupPhotosView = [[FTGroupPhotosViewController alloc] initWithGroup:group];
    [self.navigationController showViewController:groupPhotosView sender:self];

}



#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] forIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


@end
