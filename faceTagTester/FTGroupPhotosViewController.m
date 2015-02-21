//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTGroupPhotosViewController.h"
#define START_DATE [NSDate dateWithTimeIntervalSinceNow:-5*24*60*60]
#define END_DATE [NSDate dateWithTimeIntervalSinceNow:-3*24*60*60]

@interface FTGroupPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *testGroup;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *itemChanges;

@end

@implementation FTGroupPhotosViewController

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
    } else {
        /*
        [self.testGroup setStartDate:START_DATE];
        [self.testGroup setEndDate:END_DATE];
        [self processImagesForGroup:self.testGroup];*/
        
    }
    //option 1: create a frc for each person
    /*
    for (FTPerson *person in [self.testGroup peopleArray]) {
        NSFetchRequest *frcRequest = [[NSFetchRequest alloc] init];
        NSPredicate *fetchPredicate = [NSPredicate predicateWithBlock:^BOOL(FTPhoto *photo, NSDictionary *bindings) {
            return [[photo people] containsObject:person] && [[photo groups] containsObject:self.testGroup];
        }];
        NSSortDescriptor* dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
        [frcRequest setSortDescriptors:@[dateDescriptor]];
        [frcRequest setEntity:[FTPhoto entity]];
        [frcRequest setPredicate:fetchPredicate];
        
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:frcRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:person.name cacheName:nil];
        [frc setDelegate:self];
        [frc performFetch:NULL];
    }*/
    
    //option 2: use FTPhoto's peopleNames
    NSFetchRequest *frcRequest = [[NSFetchRequest alloc] init];
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"%@ IN groups", self.testGroup];
    //NSSortDescriptor* dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"peopleNamesString" ascending:NO];
    [frcRequest setSortDescriptors:@[nameDescriptor]];
    [frcRequest setEntity:[FTPhoto entity]];
    [frcRequest setPredicate:fetchPredicate];
    [frcRequest setFetchBatchSize:20];

    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:frcRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:@"peopleNamesString" cacheName:nil];
    [self.frc setDelegate:self];
    [self.frc performFetch:NULL];
    
    [self.collectionView reloadData];

    return self;
    
}

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
#warning TODO:should check for existence
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
    FTGroupManagingViewController *groupManagingViewController = [[FTGroupManagingViewController alloc] initWithGroup:self.testGroup];
    
    [groupManagingViewController setDelegate:self];
    [groupManagingViewController setAction:@selector(updateGroup:)];
    [self.navigationController showViewController:groupManagingViewController sender:self];
    //same as createGroup with populated info
}

- (void)updateGroup:(FTGroup *)editedGroup {
    BOOL needsReProcessing = NO;
    if (![editedGroup.name isEqualToString:self.testGroup.name]) {
#warning TODO: need to make name editable but let id stays the same
        //[self.testGroup setName:editedGroup.name];
        //update whatever label
    } else if ([editedGroup.startDate isEqualToDate:self.testGroup.startDate]) {
        [self.testGroup setStartDate:self.testGroup.startDate];
        needsReProcessing = YES;
    } else if ([editedGroup.endDate isEqualToDate:self.testGroup.endDate]) {
        [self.testGroup setEndDate:self.testGroup.endDate];
        needsReProcessing = YES;
    }
    
    if (needsReProcessing) {
        [self processImagesForGroup:self.testGroup];
    }
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
