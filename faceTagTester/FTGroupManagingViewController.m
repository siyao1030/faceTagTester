//
//  FTGroupManagingViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/20/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupManagingViewController.h"
#import "FTGroupPhotosViewController.h"
#import "FTPersonViewController.h"
#import "CTAssetsPickerController.h"


#define SIDE_PADDING 40
#define VERTICAL_PADDING 10
#define PEOPLE_GRID_WIDTH 70

@interface FTGroupManagingViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, CTAssetsPickerControllerDelegate, FTPopupViewDelegate> {
    BOOL _isCreatingNewGroup;
}

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
        _isCreatingNewGroup = YES;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            FTGroup *newGroup = [[FTGroup alloc] initWithContext:localContext];
            [self setGroup:newGroup];
        }];
        UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createButtonPressed)];
        self.navigationItem.rightBarButtonItem = createButton;
    }
    
    return self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        // cancel editing, should discard new group if it was created but not used
        if (_isCreatingNewGroup && !self.group.name) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                FTGroup *localGroup = [self.group MR_inContext:localContext];
                [localGroup MR_deleteEntity];
            }];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *mainColor = [UIColor colorForText:@"melon"];
    UIColor *mainColorTransparent = [mainColor colorWithAlphaComponent:0.5];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.groupNameField = [[UITextField alloc] init];
    [self.groupNameField setFont:[UIFont boldSystemFontOfSize:24]];
    [self.groupNameField setPlaceholder:@"Name of the Group"];
    [self.groupNameField setTextAlignment:NSTextAlignmentLeft];
    //[self.groupNameField setBackgroundColor:mainColorTransparent];
    [self.groupNameField setTextColor:mainColor];
    if (self.groupName) {
        [self.groupNameField setText:self.groupName];
    }
    [self.view addSubview:self.groupNameField];
    [self.groupNameField becomeFirstResponder];
    
    UIColor *dateColor = [UIColor colorForText:@"date"];
    self.fromLabel = [[UILabel alloc] init];
    [self.fromLabel setText:@"from"];
    [self.fromLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [self.fromLabel setTextAlignment:NSTextAlignmentLeft];
    [self.fromLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.fromLabel];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    self.startDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [self.startDatePicker setDatePickerMode:UIDatePickerModeDate];
    [self.startDatePicker setDate:[NSDate date]];
    self.startDatePicker.backgroundColor = [UIColor whiteColor];
    [self.startDatePicker addTarget:self action:@selector(startDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.startDateField = [[UITextField alloc] init];
    [self.startDateField setUserInteractionEnabled:YES];
    [self.startDateField setInputView:self.startDatePicker];
    [self.startDateField setFont:[UIFont boldSystemFontOfSize:22]];
    [self.startDateField setBackgroundColor:[UIColor whiteColor]];
    [self.startDateField setTextColor:mainColor];
    if (self.startDate) {
        NSString *startDateString = [dateFormatter stringFromDate:self.startDate];
        [self.startDateField setText:startDateString];
        [self.startDatePicker setDate:self.startDate];
    } else {
        [self.startDateField setText:@"Once upon a time..."];
    }
    [self.view addSubview:self.startDateField];
    
    self.toLabel = [[UILabel alloc] init];
    [self.toLabel setText:@"to"];
    [self.toLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [self.toLabel setTextAlignment:NSTextAlignmentLeft];
    [self.toLabel setTextColor:[dateColor pathDarkestColor]];
    [self.view addSubview:self.toLabel];

    self.endDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 210, 320, 216)];
    [self.endDatePicker setDatePickerMode:UIDatePickerModeDate];
    [self.endDatePicker setDate:[NSDate date]];
    self.endDatePicker.backgroundColor = [UIColor whiteColor];
    [self.endDatePicker addTarget:self action:@selector(endDateSelected:) forControlEvents:UIControlEventValueChanged];
    
    self.endDateField = [[UITextField alloc] init];
    [self.endDateField setUserInteractionEnabled:YES];
    [self.endDateField setInputView:self.endDatePicker];
    [self.endDateField setFont:[UIFont boldSystemFontOfSize:22]];
    [self.endDateField setBackgroundColor:[UIColor whiteColor]];
    [self.endDateField setTextColor:mainColor];

    if (self.endDate) {
        NSString *endDateString = [dateFormatter stringFromDate:self.endDate];
        [self.endDateField setText:endDateString];
        [self.endDatePicker setDate:self.endDate];
    } else {
        [self.endDateField setText:@"The end of the world..."];
    }
    [self.view addSubview:self.endDateField];
    
    self.selectDatesButton = [[UIButton alloc] init];
    [self.selectDatesButton setImage:[[UIImage imageNamed:@"date-select"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.selectDatesButton setTintColor:mainColor];
    //[self.selectDatesButton setBackgroundColor:[UIColor whiteColor]];
    //[self.selectDatesButton setTitle:@"Select Dates" forState:UIControlStateNormal];
    //[self.selectDatesButton setTitleColor:mainColor forState:UIControlStateNormal];
    //[[self.selectDatesButton titleLabel] setFont:[UIFont systemFontOfSize:22]];
    //[[self.selectDatesButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    [self.selectDatesButton addTarget:self action:@selector(selectDates) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.selectDatesButton];
    
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
    
    if (self.group) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];

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
    yOffset = CGRectGetMaxY(groupNameFrame) + VERTICAL_PADDING;
    
    [self.fromLabel sizeToFit];
    CGRect fromLabelFrame = [self.fromLabel frame];
    fromLabelFrame.origin.x = SIDE_PADDING;
    fromLabelFrame.origin.y = yOffset;
    [self.fromLabel setFrame:fromLabelFrame];

    [self.startDateField sizeToFit];
    CGRect startDateFieldFrame = [self.startDateField frame];
    startDateFieldFrame.size.width = bounds.size.width - 2 * SIDE_PADDING;
    startDateFieldFrame.origin.x = SIDE_PADDING;
    startDateFieldFrame.origin.y = CGRectGetMaxY(fromLabelFrame);
    [self.startDateField setFrame:startDateFieldFrame];
    
    yOffset = CGRectGetMaxY(startDateFieldFrame) + VERTICAL_PADDING;
    
    [self.toLabel sizeToFit];
    CGRect toLabelFrame = [self.toLabel frame];
    toLabelFrame.origin.x = SIDE_PADDING;
    toLabelFrame.origin.y = yOffset;
    [self.toLabel setFrame:toLabelFrame];

    [self.endDateField sizeToFit];
    CGRect endDateFieldFrame = [self.endDateField frame];
    endDateFieldFrame.size.width = bounds.size.width - 2 * SIDE_PADDING;
    endDateFieldFrame.origin.x = SIDE_PADDING;
    endDateFieldFrame.origin.y = CGRectGetMaxY(toLabelFrame);
    [self.endDateField setFrame:endDateFieldFrame];
    
    [self.selectDatesButton sizeToFit];
    CGRect selectDatesFrame = [self.selectDatesButton frame];
    selectDatesFrame.origin.x = bounds.size.width - SIDE_PADDING - selectDatesFrame.size.width;
    selectDatesFrame.origin.y = CGRectGetMaxY(startDateFieldFrame);
    [self.selectDatesButton setFrame:selectDatesFrame];
    
    yOffset = CGRectGetMaxY(endDateFieldFrame) + VERTICAL_PADDING * 2;

    CGRect collectionFrame = [self.peopleCollectionView frame];
    collectionFrame.size.width = bounds.size.width - SIDE_PADDING * 2;
    float peoplePerRow = floorf(collectionFrame.size.width / PEOPLE_GRID_WIDTH);
    int numOfRows = ceilf(([[self.groupPeopleFRC fetchedObjects] count] + 1) / peoplePerRow);
    collectionFrame.size.height = numOfRows * (PEOPLE_GRID_WIDTH + 10);
    collectionFrame.origin.x = SIDE_PADDING;
    collectionFrame.origin.y = yOffset;
    [self.peopleCollectionView setFrame:collectionFrame];

}

- (void)updateColletionViewFrame {
    CGRect collectionFrame = [self.peopleCollectionView frame];
    float peoplePerRow = floorf(collectionFrame.size.width / PEOPLE_GRID_WIDTH);
    int numOfRows = ceilf(([[self.groupPeopleFRC fetchedObjects] count] + 1) / peoplePerRow);
    collectionFrame.size.height = numOfRows * (PEOPLE_GRID_WIDTH + 10);
    [self.peopleCollectionView setFrame:collectionFrame];
}

- (void)startDateSelected:(UIDatePicker *)datePicker {
    [self.groupNameField resignFirstResponder];
    [self updateStartDate:[datePicker date]];
    
    if ([[self.endDatePicker date] compare:[datePicker date]] == NSOrderedAscending) {
        [self.endDatePicker setDate:[datePicker date] animated:YES];
    }
}

- (void)updateStartDate:(NSDate *)startDate {
    [self setStartDate:startDate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:startDate];
    [self.startDateField setText:dateString];
    [self.startDateField sizeToFit];
}

- (void)updateEndDate:(NSDate *)endDate {
    [self setEndDate:endDate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:endDate];
    [self.endDateField setText:dateString];
    [self.endDateField sizeToFit];
}

- (void)endDateSelected:(UIDatePicker *)datePicker {
    [self.groupNameField resignFirstResponder];
    [self updateEndDate:[datePicker date]];

    if ([[self.startDatePicker date] compare:[datePicker date]] == NSOrderedDescending) {
        [self.startDatePicker setDate:[datePicker date] animated:YES];
    }
    
}


- (void)selectDates {
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)addPeopleButtonPressed {
    [self presentPersonViewForPerson:nil];
}

- (void)presentPersonViewForPerson:(FTPerson *)person {
    if ([self.groupNameField isFirstResponder]) {
        [self.groupNameField resignFirstResponder];
    }
    
    self.personPopUpView = [[FTPersonPopUpView alloc] initWithGroup:self.group Person:person];
    [self.personPopUpView setDelegate:self];
    [self.personPopUpView showPopup];

}

- (void)dismssPersonView:(UIGestureRecognizer *)sender {
    [self.personPopUpView dismissPopup];
    self.personPopUpView = nil;
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
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FTGroup *localGroup = [self.group MR_inContext:localContext];
        [localGroup setName:self.groupNameField.text];
        [localGroup addPeople:self.people];
        [localGroup setStartDate:self.startDate];
        [localGroup setEndDate:self.endDate];
    } completion:^(BOOL success, NSError *error) {
        FTGroupPhotosViewController *groupPhotosView = [[FTGroupPhotosViewController alloc] initWithGroup:self.group];
        [self.navigationController showViewController:groupPhotosView sender:self];
    }];
}

#pragma mark - FTPopupViewDelegate

- (void)popupViewDidDismiss:(FTPopupView*)popupView {
    [self.groupPeopleFRC performFetch:nil];
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FTPerson *person = [self.groupPeopleFRC objectAtIndexPath:indexPath];
    [self presentPersonViewForPerson:person];
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
        [self updateColletionViewFrame];
    } completion:^(BOOL finished) {
        self.sectionChanges = nil;
        self.itemChanges = nil;
    }];
}

#pragma mark - CTAssetsPickerDelegate


- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group
{
    return ([[group valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos);
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    if ([assets count] > 1) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        NSArray *sortedAssets = [assets sortedArrayUsingDescriptors:@[sort]];
        NSDate *startDate = [(ALAsset *)[sortedAssets objectAtIndex:0] date];
        NSDate *endDate = [(ALAsset *)[sortedAssets objectAtIndex:1] date];
        [self updateStartDate:startDate];
        [self updateEndDate:endDate];
    } else {
        NSDate *startDate = [(ALAsset *)[assets objectAtIndex:0] date];
        [self updateStartDate:startDate];
        if (!self.endDate) {
            [self updateEndDate:[NSDate date]];
        }
    }
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
#warning TODO: automatically change selected range? but which to switch
    if (picker.selectedAssets.count > 1)
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Attention"
                                   message:@"Please select only a start and an end"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }
    
    if (!asset.defaultRepresentation)
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Attention"
                                   message:@"Your asset has not yet been downloaded to your device"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }
    
    return (picker.selectedAssets.count <= 1 && asset.defaultRepresentation != nil);
}




@end
