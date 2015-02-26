//
//  FTGroupManagingViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupManagingViewController.h"
#import "FTGroupPhotosViewController.h"

#define SIDE_PADDING 40
#define PEOPLE_GRID_WIDTH 70

@interface FTGroupManagingViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@end

@implementation FTGroupManagingViewController

- (id)initWithGroup:(FTGroup *)group {
    self = [super init];

    if (group) {
        [self setGroup:group];
        [self setGroupName:group.name];
        [self setStartDate:group.startDate];
        [self setEndDate:group.endDate];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createButtonPressed)];
        self.navigationItem.rightBarButtonItem = createButton;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.groupNameField = [[UITextField alloc] init];
    [self.groupNameField setFont:[UIFont boldSystemFontOfSize:24]];
    [self.groupNameField setPlaceholder:@"Name of the Group"];
    [self.groupNameField setTextAlignment:NSTextAlignmentLeft];
    if (self.groupName) {
        [self.groupNameField setText:self.groupName];
        [self.groupNameField setTextColor:[UIColor colorForText:self.groupName]];
    }
    [self.view addSubview:self.groupNameField];
    [self.groupNameField becomeFirstResponder];
    
    UIColor *dateColor = [UIColor colorForText:@"date"];
    self.fromLabel = [[UILabel alloc] init];
    [self.fromLabel setText:@"FROM"];
    [self.fromLabel setFont:[UIFont boldSystemFontOfSize:22]];
    [self.fromLabel setTextAlignment:NSTextAlignmentLeft];
    [self.fromLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.fromLabel];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    UIDatePicker *startDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [startDatePicker setDatePickerMode:UIDatePickerModeDate];
    [startDatePicker setDate:[NSDate date]];
    startDatePicker.backgroundColor = [UIColor whiteColor];
    [startDatePicker addTarget:self action:@selector(startDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.startDateField = [[UITextField alloc] init];
    [self.startDateField setUserInteractionEnabled:YES];
    [self.startDateField setInputView:startDatePicker];
    [self.startDateField setFont:[UIFont boldSystemFontOfSize:22]];
    if (self.startDate) {
        NSString *startDateString = [dateFormatter stringFromDate:self.startDate];
        [self.startDateField setText:startDateString];
        [self.startDateField setTextColor:dateColor];
        [startDatePicker setDate:self.startDate];
    } else {
        [self.startDateField setText:@"Once upon a time..."];
        [self.startDateField setTextColor:[dateColor pathDarkColor]];
    }
    [self.view addSubview:self.startDateField];
    
    self.toLabel = [[UILabel alloc] init];
    [self.toLabel setText:@"TO"];
    [self.toLabel setFont:[UIFont boldSystemFontOfSize:22]];
    [self.toLabel setTextAlignment:NSTextAlignmentLeft];
    [self.toLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.toLabel];

    
    UIDatePicker *endDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [endDatePicker setDatePickerMode:UIDatePickerModeDate];
    [endDatePicker setDate:[NSDate date]];
    endDatePicker.backgroundColor = [UIColor whiteColor];
    [endDatePicker addTarget:self action:@selector(endDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.endDateField = [[UITextField alloc] init];
    [self.endDateField setUserInteractionEnabled:YES];
    [self.endDateField setInputView:endDatePicker];
    [self.endDateField setFont:[UIFont boldSystemFontOfSize:22]];
    if (self.endDate) {
        NSString *endDateString = [dateFormatter stringFromDate:self.endDate];
        [self.endDateField setText:endDateString];
        [self.endDateField setTextColor:dateColor];
        [endDatePicker setDate:self.endDate];
    } else {
        [self.endDateField setText:@"The end of the world..."];
        [self.endDateField setTextColor:[dateColor pathDarkColor]];
    }
    [self.view addSubview:self.endDateField];
    
    self.addPeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, PEOPLE_GRID_WIDTH, PEOPLE_GRID_WIDTH)];
    self.addPeopleButton.layer.cornerRadius = rintf(PEOPLE_GRID_WIDTH / 2);
    self.addPeopleButton.clipsToBounds = YES;
    self.addPeopleButton.layer.borderWidth = 3.0f;
    self.addPeopleButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.addPeopleButton setTitle:@"Add" forState:UIControlStateNormal];
    [self.addPeopleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self.addPeopleButton titleLabel] setFont:[UIFont boldSystemFontOfSize:16]];
    [[self.addPeopleButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    [self.addPeopleButton setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.5]];
    [self.addPeopleButton addTarget:self action:@selector(addPeopleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.peopleCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [self.peopleCollectionView setDelegate:self];
    [self.peopleCollectionView setDataSource:self];
    [self.peopleCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.peopleCollectionView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.peopleCollectionView];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    
    /*
    NSFetchRequest *allPeopleRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [allPeopleRequest setSortDescriptors:@[nameDescriptor]];
    [allPeopleRequest setEntity:[FTPerson entity]];
    [allPeopleRequest setFetchBatchSize:20];
    
    self.allPeopleFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:allPeopleRequest managedObjectContext:context sectionNameKeyPath:@"peopleNamesString" cacheName:nil];
    [self.allPeopleFRC setDelegate:self];
    [self.allPeopleFRC performFetch:NULL];
    */
    
    NSFetchRequest *groupPeopleRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"%@ IN groups", self.group];
    [groupPeopleRequest setSortDescriptors:@[nameDescriptor]];
    [groupPeopleRequest setEntity:[FTPerson entity]];
    [groupPeopleRequest setPredicate:fetchPredicate];
    [groupPeopleRequest setFetchBatchSize:10];
    
    self.groupPeopleFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:groupPeopleRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    [self.groupPeopleFRC setDelegate:self];
    [self.groupPeopleFRC performFetch:NULL];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect bounds = [[self view] bounds];
    CGFloat yOffset = 100;
    
    [self.groupNameField sizeToFit];
    CGRect groupNameFrame = [self.groupNameField frame];
    groupNameFrame.size.width = bounds.size.width - 2 * SIDE_PADDING;
    groupNameFrame.origin.x = SIDE_PADDING;
    groupNameFrame.origin.y = yOffset;
    [self.groupNameField setFrame:groupNameFrame];
    yOffset = CGRectGetMaxY(groupNameFrame) + 20;
    
    [self.fromLabel sizeToFit];
    CGRect fromLabelFrame = [self.fromLabel frame];
    fromLabelFrame.origin.x = SIDE_PADDING;
    fromLabelFrame.origin.y = yOffset;
    [self.fromLabel setFrame:fromLabelFrame];

    [self.startDateField sizeToFit];
    CGRect startDateFieldFrame = [self.endDateField frame];
    startDateFieldFrame.origin.x = CGRectGetMaxX(fromLabelFrame) + 10;
    startDateFieldFrame.origin.y = fromLabelFrame.origin.y - rintf((startDateFieldFrame.size.height - fromLabelFrame.size.height) / 2.0);
    [self.startDateField setFrame:startDateFieldFrame];
    
    yOffset = CGRectGetMaxY(fromLabelFrame) + 20;
    
    [self.toLabel sizeToFit];
    CGRect toLabelFrame = [self.toLabel frame];
    toLabelFrame.origin.x = SIDE_PADDING;
    toLabelFrame.origin.y = yOffset;
    [self.toLabel setFrame:toLabelFrame];

    [self.endDateField sizeToFit];
    CGRect endDateFieldFrame = [self.endDateField frame];
    endDateFieldFrame.origin.x = startDateFieldFrame.origin.x;
    endDateFieldFrame.origin.y = toLabelFrame.origin.y - rintf((endDateFieldFrame.size.height - toLabelFrame.size.height) / 2.0);
    [self.endDateField setFrame:endDateFieldFrame];
    
    yOffset = CGRectGetMaxY(endDateFieldFrame) + 20;
    
    CGRect collectionFrame = [self.peopleCollectionView frame];
    collectionFrame.size.width = bounds.size.width - SIDE_PADDING * 2;
    float peoplePerRow = floorf(bounds.size.width / PEOPLE_GRID_WIDTH);
    int numOfRows = ceilf(([[self.groupPeopleFRC fetchedObjects] count] + 1) / peoplePerRow);
    collectionFrame.size.height = numOfRows * (PEOPLE_GRID_WIDTH + 10);
    collectionFrame.origin.x = SIDE_PADDING;
    collectionFrame.origin.y = yOffset;
    [self.peopleCollectionView setFrame:collectionFrame];

}

- (void)startDateSelected:(UIDatePicker *)datePicker {
    [self setStartDate:[datePicker date]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[datePicker date]];
    [self.startDateField setText:dateString];
}

- (void)endDateSelected:(UIDatePicker *)datePicker {
    [self setEndDate:[datePicker date]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[datePicker date]];
    [self.endDateField setText:dateString];
}


- (void)addPeopleButtonPressed {
    //pick from existing ppl
    //create new people
}

- (void)createPeopleButtonPressed {
    //name
    //photo(s)
    //select or take new ones -> https://github.com/chiunam/CTAssetsPickerController
}

- (void)doneButtonPressed {
    NSMutableDictionary *editedGroupInfo = [[NSMutableDictionary alloc] init];
    [editedGroupInfo setValue:self.groupNameField.text forKey:@"groupName"];
    [editedGroupInfo setValue:self.startDate forKey:@"startDate"];
    [editedGroupInfo setValue:self.endDate forKey:@"endDate"];

    [self.target performSelector:self.action withObject:editedGroupInfo afterDelay:0];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createButtonPressed {
    dispatch_sync(CoreDataWriteQueue(), ^{
        FTGroup *newGroup = [[FTGroup alloc] initWithName:self.groupNameField.text andPeople:self.people andStartDate:self.startDate andEndDate:self.endDate];
        FTGroupPhotosViewController *groupPhotosView = [[FTGroupPhotosViewController alloc] initWithGroup:newGroup];
        [self.navigationController showViewController:groupPhotosView sender:self];
    });
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(PEOPLE_GRID_WIDTH, PEOPLE_GRID_WIDTH);
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.groupPeopleFRC sections][section];
    return [sectionInfo numberOfObjects] + 1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    if (indexPath.row == [[self.groupPeopleFRC fetchedObjects] count]) {
        [cell addSubview:self.addPeopleButton];
    } else {
        FTPerson *person = [self.groupPeopleFRC objectAtIndexPath:indexPath];
        
        UIImage *profileImage = [UIImage imageWithData:person.profileImageData];
        UIImageView *profileView = [[UIImageView alloc] initWithImage:profileImage];
        [profileView setContentMode:UIViewContentModeScaleAspectFill];
        [profileView setFrame:CGRectMake(0, 0, PEOPLE_GRID_WIDTH, PEOPLE_GRID_WIDTH)];
        profileView.layer.cornerRadius = rintf(profileView.frame.size.width / 2);
        profileView.clipsToBounds = YES;
        profileView.layer.borderWidth = 3.0f;
        profileView.layer.borderColor = [UIColor whiteColor].CGColor;
        [cell addSubview:profileView];
    }
    return cell;
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    self.sectionChanges = [[NSMutableArray alloc] init];
    self.itemChanges = [[NSMutableArray alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
    change[@(type)] = @(sectionIndex);
    [self.sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [self.itemChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.peopleCollectionView performBatchUpdates:^{
        for (NSDictionary *change in self.sectionChanges) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.peopleCollectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.peopleCollectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeMove:
                    case NSFetchedResultsChangeUpdate:
                        break;
                }
            }];
        }
        for (NSDictionary *change in self.itemChanges) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.peopleCollectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.peopleCollectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.peopleCollectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.peopleCollectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
        [self.peopleCollectionView reloadData];
    } completion:^(BOOL finished) {
        self.sectionChanges = nil;
        self.itemChanges = nil;
    }];
}


@end
