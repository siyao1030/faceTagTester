//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupPhotosViewController.h"
#import "FTPerson.h"
#import "FTPhoto.h"
#import "FTGroupManagingViewController.h"
#import "FTFaceRecognitionManager.h"

#define CONFIDENCE 10
@interface FTGroupPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, PHPhotoLibraryChangeObserver> {
    BOOL _isOngoingGroup;
    int _imagesToProcess;
}
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *group;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *itemChanges;
@property (nonatomic, strong) PHFetchResult *cameraRollFetchResult;


@end

@implementation FTGroupPhotosViewController

- (id)initWithGroup:(FTGroup *)group {
    self = [super init];
    self.imageManager = [[PHImageManager alloc] init];
    
    self.group = group;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
        [[FTFaceRecognitionManager sharedManager] trainIfNeededForGroup:self.group WithCompletion:^{
            [self processImagesIfNeeded];
        }];
    });
    
    NSFetchRequest *frcRequest = [[NSFetchRequest alloc] init];
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"%@ IN groups", self.group];
    NSSortDescriptor* dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"peopleNamesString" ascending:NO];
    [frcRequest setSortDescriptors:@[nameDescriptor, dateDescriptor]];
    [frcRequest setEntity:[FTPhoto entity]];
    [frcRequest setPredicate:fetchPredicate];
    [frcRequest setFetchBatchSize:20];
    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:frcRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:@"peopleNamesString" cacheName:nil];
    [self.frc setDelegate:self];
    [self.frc performFetch:NULL];
    
    //fetch camera roll
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    if ([collectionResult count]) {
        //fetch image assets within group's specified date range
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage]];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
        self.cameraRollFetchResult = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
    }


    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[self navigationItem] setTitle:self.group.name];
    

    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 10, 0);
    self.collectionView = [[UICollectionView alloc] initWithFrame:[[self view] bounds] collectionViewLayout:flowLayout];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    
    [[self view] addSubview:self.collectionView];
    
    
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"HeaderView"];
    
    UIBarButtonItem *editGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editGroupButtonPressed)];
    self.navigationItem.rightBarButtonItem = editGroupButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark Image Processing
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.cameraRollFetchResult];
    if (collectionChanges) {
        // get the new fetch result
        self.cameraRollFetchResult = [collectionChanges fetchResultAfterChanges];
        
        NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
        if ([removedIndexes count]) {
            //delete them from core data and from self.group.photos
        }
        NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
        if ([insertedIndexes count]) {
            [[FTFaceRecognitionManager sharedManager] processNewImagesForGroup:self.group InFetchResult:self.cameraRollFetchResult forIndexes:insertedIndexes];
            /*
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                FTGroup *localGroup = [self.group MR_inContext:localContext];
                [localGroup setDidFinishProcessing:NO];
            }];
            //process them for face detection and identification
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
                [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
                    PHAsset *asset = [self.cameraRollFetchResult objectAtIndex:index];
                    if (self.group.endDate && [[asset creationDate] compare:self.group.endDate] == NSOrderedDescending) {
                        [self setIsOngoingGroup:NO];
                    } else {
                        dispatch_group_enter(ProcessImageGroup());
                        [[FTFaceRecognitionManager sharedManager] detectAndIdentifyPhotoAsset:asset inGroup:self.group Completion:^{
                            dispatch_group_leave(ProcessImageGroup());
                        }];
                    }
                }];
                
                dispatch_group_notify(ProcessImageGroup(), dispatch_get_main_queue(), ^{
                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                        FTGroup *localGroup = [self.group MR_inContext:localContext];
                        [localGroup setDidFinishProcessing:YES];
                    } completion:^(BOOL success, NSError *error) {
                        NSLog(@"finished Processing");
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
                            //retrain if new faces are added
                            [[FTFaceRecognitionManager sharedManager] trainIfNeededForGroup:self.group WithCompletion:nil];
                        });
                    }];
                });

            });*/
        }
        NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
        if ([changedIndexes count]) {
            //check whether we actually care about the changes -> self.frc -> asset localIdentifier -> reload collection view at index
            //[self.collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
        }
    }
}



- (void)processImagesIfNeeded {
    if (!self.group.didFinishProcessing) {
        //earlier(self.group.endDate, self.group.lastProcessedDate]
        NSDate *endDate = self.group.endDate;
        if ([self.group.lastProcessedDate compare:endDate] == NSOrderedAscending) {
            endDate = self.group.lastProcessedDate;
        }
        [self processImagesFromStartDate:self.group.startDate toEndDate:endDate];
    }
}

- (void)processImagesFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate {
    //get image for image assets
    NSMutableArray *imageAssets = [[NSMutableArray alloc] init];
    [self.cameraRollFetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        //later than end, not needed
        if ([[asset creationDate] compare:endDate] == NSOrderedDescending) {
            return;
        }
        //earlier than start, not needed and stop processing
        if ([[asset creationDate] compare:startDate] == NSOrderedAscending) {
            *stop = YES;
            return;
        }
        
        [imageAssets addObject:asset];
    }];
    
    [[FTFaceRecognitionManager sharedManager] detectAndIdentifyPhotoAssets:imageAssets inGroup:self.group];
}

#pragma mark Editing Group
- (void)editGroupButtonPressed {
    FTGroupManagingViewController *groupManagingViewController = [[FTGroupManagingViewController alloc] initWithGroup:self.group];
    
    [groupManagingViewController setTarget:self];
    [groupManagingViewController setAction:@selector(updateGroup:)];
    [self.navigationController showViewController:groupManagingViewController sender:self];
}

- (void)updateGroup:(NSDictionary *)updatedGroupInfo {
    NSString *updatedName = updatedGroupInfo[@"groupName"];
    if (![updatedName isEqualToString:self.group.name]) {
        [[self navigationItem] setTitle:updatedName];
    }
    
    if ([updatedGroupInfo[@"shouldTrainAgain"] boolValue]) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            FTGroup *localGroup = [self.group MR_inContext:localContext];
            [localGroup setDidFinishTraining:NO];
        }];
    }
    
    [[FTFaceRecognitionManager sharedManager] performSelectorOnMainThread:@selector(trainIfNeededForGroup:WithCompletion:) withObject:self.group waitUntilDone:YES];
    [self processDateRangeDifference:updatedGroupInfo];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FTGroup *localGroup = [self.group MR_inContext:localContext];
        [localGroup setName:updatedName];
        [localGroup setStartDate:updatedGroupInfo[@"startDate"]];
        [localGroup setEndDate:updatedGroupInfo[@"endDate"]];
        if ([localGroup.endDate compare:[NSDate date]] == NSOrderedDescending) {
            [localGroup setIsOngoing:YES];
        } else {
            [localGroup setIsOngoing:NO];
        }
    } completion:^(BOOL success, NSError *error) {
        [[AppDelegate sharedApplication] fetchOngoingGroups];
    }];
}

- (void)processDateRangeDifference:(NSDictionary *)updatedGroupInfo {
    NSDate *oldStart = self.group.startDate;
    NSDate *oldEnd = self.group.endDate;
    NSDate *newStart = updatedGroupInfo[@"startDate"];
    NSDate *newEnd = updatedGroupInfo[@"endDate"];
    // oldEnd < newStart || newEnd < oldStart -> discard all old, add all new
    if ([oldEnd compare:newStart] == NSOrderedAscending || [newEnd compare:oldStart] == NSOrderedAscending) {
        [self discardPhotosFromStartDate:oldStart toEndDate:oldEnd];
        [self processImagesFromStartDate:newStart toEndDate:newEnd];
    } else {
        if ([newStart compare:oldStart] == NSOrderedAscending) {
            //newStart - oldStart < 0 -> add
            [self processImagesFromStartDate:newStart toEndDate:oldStart];
        } else if ([newStart compare:oldStart] == NSOrderedDescending) {
            //newStart - oldStart > 0 -> discard
            [self discardPhotosFromStartDate:oldStart toEndDate:newStart];
        }
        
        if ([newEnd compare:oldEnd] == NSOrderedAscending) {
            //newEnd - oldEnd < 0 -> discard
            [self discardPhotosFromStartDate:newEnd toEndDate:oldEnd];
        } else if ([newEnd compare:oldEnd] == NSOrderedDescending) {
            //newEnd - oldEnd > 0 -> add
            [self processImagesFromStartDate:oldEnd toEndDate:newEnd];
        }
    }
}

- (void)discardPhotosFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate {
    //go through self.group.photos delete FTPhoto object from coreData
    //fetch by objectID
    //on coreDataWriteQueue
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (FTPhoto * photo in [self.group.photos copy]) {
            // startDate < creationDate < endDate

            if ([[photo creationDate] compare:endDate] != NSOrderedDescending && [[photo creationDate] compare:startDate] != NSOrderedAscending) {
                FTGroup *localGroup = [self.group MR_inContext:localContext];
                FTPhoto *localPhoto = [photo MR_inContext:localContext];
                [localGroup removePhoto:photo];
                [localPhoto MR_deleteEntity];
            }
        }
    }];
}


- (void)setIsOngoingGroup:(BOOL)ongoing {
    if (_isOngoingGroup != ongoing) {
        _isOngoingGroup = ongoing;
        if (ongoing) {
            NSLog(@"start ongoing");
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        } else {
            NSLog(@"stop ongoing");
            [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, 100);
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return [[self.frc sections] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    FTPhoto *photo = [self.frc objectAtIndexPath:indexPath];
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[photo.photoAssetIdentifier] options:nil] firstObject];
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    [requestOptions setSynchronous:NO];
    [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
    
    [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(100 ,100)
                                contentMode:PHImageContentModeAspectFill
                                    options:requestOptions
                              resultHandler:^(UIImage *image, NSDictionary *info) {
                                  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
                                  [imageView setImage:image];
                                  [cell addSubview:imageView];
                              }];
    
    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview == nil) {
            reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, 25)];
        }
        
        NSArray *viewsToRemove = [reusableview subviews];
        for (UIView *v in viewsToRemove) {
            [v removeFromSuperview];
        }
        
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][indexPath.section];
        UILabel *label = [[UILabel alloc] init];
        [label setText:[NSString stringWithFormat:@"#%@", [sectionInfo name]]];
        [label setFont:[UIFont boldSystemFontOfSize:18]];
        [label setTextColor:[UIColor colorForText:[sectionInfo name]]];
        [label sizeToFit];
        CGRect labelFrame = [label frame];
        labelFrame.origin.x = 5;
        [label setFrame:labelFrame];
        
        [reusableview addSubview:label];
        return reusableview;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize headerSize = CGSizeMake([self.view bounds].size.width, 25);
    return headerSize;
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
    [self.collectionView performBatchUpdates:^{
        for (NSDictionary *change in self.sectionChanges) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
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
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
        [self.collectionView reloadData];
    } completion:^(BOOL finished) {
        self.sectionChanges = nil;
        self.itemChanges = nil;
    }];
}


@end
