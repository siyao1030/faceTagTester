//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupPhotosViewController.h"

@interface FTGroupPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate> {
    BOOL _didFinishProcessing;
    BOOL _didFinishTraining;
}
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *group;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *itemChanges;


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
    
    //train the group
    if (!_didFinishTraining) {
        FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:self.group.fppID orName:self.group.id andType:FaceppTrainIdentify];
        NSString *sessionID = [[result content] objectForKey:@"session_id"];
        if (sessionID) {
            [FTNetwork getResultForSession:sessionID completion:^(FaceppResult *result) {
                if ([result success]) {
                    _didFinishTraining = YES;
                    if (![[self.frc fetchedObjects] count] && !_didFinishProcessing) {
                        [self processImagesFromStartDate:self.group.startDate toEndDate:self.group.endDate];
                    }
                }
            } afterDelay:0.5];
        }
    }

    return self;
}


- (void)processImagesFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate {
    //fetch camera roll
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    if ([collectionResult count]) {
        //fetch image assets within group's specified date range
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage]];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
        
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        [requestOptions setSynchronous:YES];
        [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
        
        //get image for image assets
        NSMutableArray *imageAssets = [[NSMutableArray alloc] init];
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
            for (PHAsset *asset in imageAssets) {
                [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                                            contentMode:PHImageContentModeAspectFit
                                                options:requestOptions
                                          resultHandler:^(UIImage *image, NSDictionary *info) {
                                              @autoreleasepool {
                                                  //only detect images that are not downloaded or screenshot
                                                  if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                                      return;
                                                  }
                                                  
                                                  NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image andImageInfo:info];
                                                  if ([detectedFaceIDs count]) {
                                                      FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:self.group.fppID orGroupName:self.group.id andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:YES];
                                                      
                                                      NSString *sessionID = [[identifyResult content] objectForKey:@"session_id"];
                                                      if (sessionID) {
                                                          [self getResultForSession:sessionID completion:^(FaceppResult *result) {
                                                              if ([result success]) {
                                                                  NSArray *identifiedFaces = [[[result content] objectForKey:@"result"] objectForKey:@"face"];
                                                                  for (NSDictionary *face in identifiedFaces) {
                                                                      NSArray *candidates = [face objectForKey:@"candidate"];
                                                                      if ([candidates count]) {
                                                                          NSDictionary *candidate = candidates[0];
                                                                          // need to adjust confidence threshold based on performance
                                                                          CGFloat confidenceThreshold = 5;
                                                                          if ([[candidate objectForKey:@"confidence"] floatValue] > confidenceThreshold) {
                                                                              dispatch_async(CoreDataWriteQueue(), ^{
                                                                                  FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"]];
                                                                                  if (person) {
#warning TODO:should check for existence
                                                                                      FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset];
                                                                                      [person addPhoto:photo];
                                                                                      [self.group addPhoto:photo];
                                                                                      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
                                                                                  }
                                                                                  [[FaceppAPI person] addFaceWithPersonName:person.id orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                                              });
                                                                              
                                                                          }
                                                                      }
                                                                  }
                                                                  
                                                              }
                                                              
                                                          } afterDelay:0.5];
                                                      }
                                                  }
                                              }
                                          }];
                
                
            }
        });
    }
    

}





- (void)getResultForSession:(NSString *)sessionID completion:(void(^)(FaceppResult *result))completionBlock afterDelay:(double)delay {
    FaceppResult *result = [[FaceppAPI info] getSessionWithSessionId:sessionID];
    NSString *status = [[result content] objectForKey:@"status"];
    if ([status isEqualToString:@"SUCC"]) {
        if (completionBlock) {
            completionBlock(result);
        }
    } else if ([status isEqualToString:@"FAILED"]) {
        NSLog(@"%@ failed", sessionID);
        return;
    } else {
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) , ^(void){
            [self getResultForSession:sessionID completion:completionBlock afterDelay:delay];
        });
    }
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
    
    //UIBarButtonItem *createGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createGroupButtonPressed)];
    //self.navigationItem.rightBarButtonItem = createGroupButton;
    
    UIBarButtonItem *editGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editGroupButtonPressed)];
    self.navigationItem.rightBarButtonItem = editGroupButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)createGroupButtonPressed {
    //group name
    //start and end date (optional) or select a range of photos (https://github.com/chiunam/CTAssetsPickerController)
    
}

- (void)editGroupButtonPressed {
    FTGroupManagingViewController *groupManagingViewController = [[FTGroupManagingViewController alloc] initWithGroup:self.group];
    
    [groupManagingViewController setDelegate:self];
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
    
#warning TODO: update CoreData Object as well?
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
        } else if ([newStart compare:oldStart] == NSOrderedDescending) {
            //newEnd - oldEnd > 0 -> add
            [self processImagesFromStartDate:oldEnd toEndDate:newEnd];
        }
    }
    
    [self.group setStartDate:newStart];
    [self.group setEndDate:newEnd];

}

- (void)discardPhotosFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate {
    //go through self.group.photos delete FTPhoto object from coreData
    //fetch by objectID
    //on coreDataWriteQueue
    
    dispatch_async(CoreDataWriteQueue(), ^{
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        for (FTPhoto * photo in self.group.photos) {
            [self.group.photos removeObject:photo];
            NSManagedObject *coreDataPhoto = [context objectWithID:[photo objectID]];
            [coreDataPhoto MR_deleteEntity];
        }
        [context MR_saveToPersistentStoreAndWait];
    });

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

/*
- (id)init {
    self = [super init];
    
    self.imageManager = [[PHImageManager alloc] init];
    
    
    //test checking all photos
    NSLog(@"photo counts %lu",(unsigned long)[[FTPhoto fetchAll] count]);
    
    //temp setup for testing
    __block FTPerson *siyao = [FTPerson fetchWithID:@"siyao"];
    if (!siyao) {
        dispatch_sync(CoreDataWriteQueue(), ^{
            siyao = [[FTPerson alloc] initWithName:@"siyao"];
        });
        [siyao addTrainingImages:@[[UIImage imageNamed:@"siyao-s.jpg"]]];
    }
    
    __block FTPerson *chengyue = [FTPerson fetchWithID:@"chengyue"];
    if (!chengyue) {
        dispatch_sync(CoreDataWriteQueue(), ^{
            chengyue = [[FTPerson alloc] initWithName:@"chengyue"];
        });
        [chengyue addTrainingImages:@[[UIImage imageNamed:@"chengyue-s.jpg"]]];
    }
    
    self.testGroup = [FTGroup fetchWithID:@"testGroup"];
    if (!self.testGroup) {
        dispatch_sync(CoreDataWriteQueue(), ^{
            self.testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue] andStartDate:START_DATE andEndDate:END_DATE];
        });
        //train the group
        FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:self.testGroup.fppID orName:self.testGroup.name andType:FaceppTrainIdentify];
        NSString *sessionID = [[result content] objectForKey:@"session_id"];
        if (sessionID) {
            [self getResultForSession:sessionID completion:^(FaceppResult *result) {
                if ([result success]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self processImagesForGroup:self.testGroup];
                    });
                }
            } afterDelay:0.5];
        }
    }
    
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
    
    [self.collectionView reloadData];
    
    return self;
    
}*/

/*
- (void)processImagesForGroup:(FTGroup *)group {
    //fetch camera roll
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    if ([collectionResult count]) {
        //fetch image assets within group's specified date range
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage]];
        //[options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %d && creationDate >= %@ && creationDate <= %@", PHAssetMediaTypeImage, group.startDate, group.endDate]];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
        
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        [requestOptions setSynchronous:YES];
        [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
        
        //get image for image assets
        NSMutableArray *imageAssets = [[NSMutableArray alloc] init];
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            if ([[asset creationDate] compare:group.endDate] == NSOrderedDescending) {
                return;
            }
            if ([[asset creationDate] compare:group.startDate] == NSOrderedAscending) {
                *stop = YES;
                return;
            }
            
            [imageAssets addObject:asset];
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(void){
            for (PHAsset *asset in imageAssets) {
                [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                                            contentMode:PHImageContentModeAspectFit
                                                options:requestOptions
                                          resultHandler:^(UIImage *image, NSDictionary *info) {
                                              @autoreleasepool {
                                                  //only detect images that are not downloaded or screenshot
                                                  if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                                      return;
                                                  }
                                                  
                                                  NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image andImageInfo:info];
                                                  if ([detectedFaceIDs count]) {
                                                      FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.fppID orGroupName:group.name andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:YES];
                                                      
                                                      NSString *sessionID = [[identifyResult content] objectForKey:@"session_id"];
                                                      if (sessionID) {
                                                          [self getResultForSession:sessionID completion:^(FaceppResult *result) {
                                                              if ([result success]) {
                                                                  NSArray *identifiedFaces = [[[result content] objectForKey:@"result"] objectForKey:@"face"];
                                                                  for (NSDictionary *face in identifiedFaces) {
                                                                      NSArray *candidates = [face objectForKey:@"candidate"];
                                                                      if ([candidates count]) {
                                                                          NSDictionary *candidate = candidates[0];
                                                                          // need to adjust confidence threshold based on performance
                                                                          CGFloat confidenceThreshold = 5;
                                                                          if ([[candidate objectForKey:@"confidence"] floatValue] > confidenceThreshold) {
                                                                              dispatch_async(CoreDataWriteQueue(), ^{
                                                                                  FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"]];
                                                                                  if (person) {
                                                                                      FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset];
                                                                                      [person addPhoto:photo];
                                                                                      [group addPhoto:photo];
                                                                                      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
                                                                                  }
                                                                                  [[FaceppAPI person] addFaceWithPersonName:person.name orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                                              });
                                                                              
                                                                          }
                                                                      }
                                                                  }
                                                                  
                                                              }
                                                              
                                                          } afterDelay:0.5];
                                                      }
                                                  }
                                              }
                                          }];
                
                
            }
        });
    }
    
} */


@end
