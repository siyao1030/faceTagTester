//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupPhotosViewController.h"
#define CONFIDENCE 10
@interface FTGroupPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, PHPhotoLibraryChangeObserver> {
    BOOL _isOngoingGroup;
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
    
    if ([self.group.endDate compare:[NSDate date]] == NSOrderedDescending) {
        [self setIsOngoingGroup:YES];
    }
    
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
    
    [self trainGroupIfNeededWithCompletion:^{
        [self processImagesFromStartDate:self.group.startDate toEndDate:self.group.endDate];
    }];
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
            //process them for face detection and identification
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
                [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
                    PHAsset *asset = [self.cameraRollFetchResult objectAtIndex:index];
                    if (self.group.endDate && [[asset creationDate] compare:self.group.endDate] == NSOrderedDescending) {
                        [self setIsOngoingGroup:NO];
                    } else {
                        dispatch_group_enter(ProcessImageGroup());
                        [self detectAndIdentifyInPhotoAsset:asset Completion:^{
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
                            [self trainGroupIfNeededWithCompletion:nil];
                        });
                    }];
#warning SAVING NOT WORKING
                });

            });
        }
        NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
        if ([changedIndexes count]) {
            //check whether we actually care about the changes -> self.frc -> asset localIdentifier -> reload collection view at index
            //[self.collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
        }
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
    
    [self detectAndIdentifyPhotoAssets:imageAssets];
}


- (void)detectAndIdentifyPhotoAssets:(NSArray *)imageAssets {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
        for (PHAsset *asset in imageAssets) {
            dispatch_group_enter(ProcessImageGroup());
            [self detectAndIdentifyInPhotoAsset:asset Completion:^{
                dispatch_group_leave(ProcessImageGroup());
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    FTGroup *localGroup = [self.group MR_inContext:localContext];
                    [localGroup setLastProcessedDate:[asset creationDate]]; //**maybe saving too much?
                }];
#warning TODO: could add progress bar info here
            }];
        }
        
        dispatch_group_notify(ProcessImageGroup(), dispatch_get_main_queue(), ^{
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                FTGroup *localGroup = [self.group MR_inContext:localContext];
                [localGroup setDidFinishProcessing:YES];
            } completion:^(BOOL success, NSError *error) {
                NSLog(@"finished Processing");
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
                    //retrain if new faces are added
                    [self trainGroupIfNeededWithCompletion:nil];
                });
            }];
        });
    });

}

- (void)detectAndIdentifyInPhotoAsset:(PHAsset *)asset Completion:(void(^)(void))completionBlock {
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    [requestOptions setSynchronous:YES];
    [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
    
    [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                                contentMode:PHImageContentModeAspectFit
                                    options:requestOptions
                              resultHandler:^(UIImage *image, NSDictionary *info) {
                                  @autoreleasepool {
                                      //only detect images that are not screenshot -> should eliminate download too
                                      if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                          if (completionBlock) {
                                              completionBlock();
                                          }
                                          return;
                                      }
                                      //detect faces
                                      NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image];
                                      if ([detectedFaceIDs count]) {
                                          //identify faces
                                          FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:self.group.fppID orGroupName:self.group.id andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:YES];
                                          
                                          NSString *sessionID = [[identifyResult content] objectForKey:@"session_id"];
                                          if (sessionID) {
                                              [FTNetwork getResultForSession:sessionID completion:^(FaceppResult *result) {
                                                  if ([result success]) {
                                                      NSArray *identifiedFaces = [[[result content] objectForKey:@"result"] objectForKey:@"face"];
                                                      
                                                      [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                          FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset withContext:localContext];
                                                          BOOL shouldAddToGroup = NO;
                                                          for (NSDictionary *face in identifiedFaces) {
                                                              NSArray *candidates = [face objectForKey:@"candidate"];
                                                              if ([candidates count]) {
                                                                  NSDictionary *candidate = candidates[0];
                                                                  if ([[candidate objectForKey:@"confidence"] floatValue] > CONFIDENCE) {
                                                                      shouldAddToGroup = YES;
                                                                      FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"] withContext:localContext];
                                                                      if (person) {
                                                                          if (![photo.people containsObject:person]) {
                                                                              [photo addPerson:person];
                                                                              [[FaceppAPI person] addFaceWithPersonName:person.id orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                                          }
                                                                      }
                                                                  }
                                                              }
                                                          }
                                                          if (shouldAddToGroup) {
                                                              FTGroup *localGroup = [self.group MR_inContext:localContext];
                                                              [photo addGroup:localGroup]; //**might not be saved
                                                          }

                                                      } completion:^(BOOL success, NSError *error) {
                                                          if (completionBlock) {
                                                              completionBlock();
                                                          }
                                                      }];
                                                  }
                                                  
                                              } afterDelay:0.5];
                                          }
                                      } else {
                                          if (completionBlock) {
                                              completionBlock();
                                          }
                                      }
                                  }
    }];
}

- (void)trainGroupIfNeededWithCompletion:(void(^)(void))completionBlock {
    NSInteger photosTrained = [self.group.photosTrained integerValue];
    if (self.group.photos.count > photosTrained || photosTrained == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"training");
            FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:self.group.fppID orName:self.group.id andType:FaceppTrainIdentify];
            NSString *sessionID = [[result content] objectForKey:@"session_id"];
            if (sessionID) {
                [FTNetwork getResultForSession:sessionID completion:^(FaceppResult *result) {
                    if ([result success]) {
                        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                            FTGroup *localGroup = [self.group MR_inContext:localContext];
                            [localGroup setPhotosTrained:@([self.group.photos count])];
                            [localGroup setDidFinishTraining:YES];
                        } completion:^(BOOL success, NSError *error) {
                            if (completionBlock) {
                                completionBlock();
                            }
                        }];
                    }
                } afterDelay:0.5];
            }
            
        });
    }
    
}


#pragma mark Editing Group
- (void)editGroupButtonPressed {
    FTGroupManagingViewController *groupManagingViewController = [[FTGroupManagingViewController alloc] initWithGroup:self.group];
    
    [groupManagingViewController setTarget:self];
    [groupManagingViewController setAction:@selector(updateGroup:)];
    [self.navigationController showViewController:groupManagingViewController sender:self];
    //same as createGroup with populated info
}

- (void)updateGroup:(NSDictionary *)updatedGroupInfo {
    NSString *updatedName = updatedGroupInfo[@"groupName"];

    if (![updatedName isEqualToString:self.group.name]) {
        [[self navigationItem] setTitle:updatedName];
    }
    [self processDateRangeDifference:updatedGroupInfo];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FTGroup *localGroup = [self.group MR_inContext:localContext];
        [localGroup setName:updatedName];
        [localGroup setStartDate:updatedGroupInfo[@"startDate"]];
        [localGroup setEndDate:updatedGroupInfo[@"endDate"]];
    } completion:^(BOOL success, NSError *error) {
        if ([self.group.endDate compare:[NSDate date]] == NSOrderedDescending) {
            [self setIsOngoingGroup:YES];
        } else {
            [self setIsOngoingGroup:NO];
        }
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
#warning todo: not deleting some photos
            if ([[photo creationDate] compare:endDate] == NSOrderedAscending && [[photo creationDate] compare:startDate] == NSOrderedDescending) {
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
        //[label setTextColor:[UIColor whiteColor]];
        [label setTextColor:[UIColor colorForText:[sectionInfo name]]];
        [label sizeToFit];
        CGRect labelFrame = [label frame];
        labelFrame.origin.x = 5;
        [label setFrame:labelFrame];
        
        [reusableview addSubview:label];
        //[reusableview setBackgroundColor:[UIColor colorForText:[sectionInfo name]]];
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
