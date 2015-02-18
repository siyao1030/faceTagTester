//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *testGroup;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *itemChanges;

@end

@implementation ViewController

- (id)init {
    self = [super init];
    
    self.imageManager = [[PHImageManager alloc] init];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:[[self view] bounds] collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    
    [[self view] addSubview:self.collectionView];
    
    __block FTPerson *siyao = [FTPerson fetchWithID:@"siyao"];
    if (!siyao) {
            siyao = [[FTPerson alloc] initWithName:@"siyao"];
            [siyao addTrainingImages:@[[UIImage imageNamed:@"siyao-s.jpg"]]];
    }
    
    __block FTPerson *chengyue = [FTPerson fetchWithID:@"chengyue"];
    if (!chengyue) {
            chengyue = [[FTPerson alloc] initWithName:@"chengyue"];
            [chengyue addTrainingImages:@[[UIImage imageNamed:@"chengyue-s.jpg"]]];
    }
    
    self.testGroup = [FTGroup fetchWithID:@"testGroup"];
    if (!self.testGroup) {
            self.testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue] andStartDate:[NSDate dateWithTimeIntervalSinceNow:-2*24*60*60] andEndDate:[NSDate dateWithTimeIntervalSinceNow:-1*24*60*60]];
            FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:self.testGroup.fppID orName:self.testGroup.name andType:FaceppTrainIdentify];
            NSString *sessionID = [[result content] objectForKey:@"session_id"];
            if (sessionID) {
                [self getResultForSession:sessionID completion:^(FaceppResult *result) {
                    if ([result success]) {
                        if ([[self.testGroup photos] count] == 0) {
                            [self processImagesForGroup:self.testGroup];
                        }
                    }
                } afterDelay:2.0];
            }
    } else {
        [self.testGroup setStartDate:[NSDate dateWithTimeIntervalSinceNow:-2.5*24*60*60]];
        [self.testGroup setEndDate:[NSDate dateWithTimeIntervalSinceNow:-2*24*60*60]];
        [self processImagesForGroup:self.testGroup];
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
    NSSortDescriptor* dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"photoAsset.creationDate" ascending:NO];
    [frcRequest setSortDescriptors:@[dateDescriptor]];
    [frcRequest setEntity:[FTPhoto entity]];
    [frcRequest setPredicate:fetchPredicate];
    [frcRequest setFetchBatchSize:20];

    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:frcRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:@"peopleNamesString" cacheName:nil];
    [self.frc setDelegate:self];
    //[self fetchPhotos];


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
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            if ([[asset creationDate] compare:group.endDate] == NSOrderedDescending) {
                return;
            }
            if ([[asset creationDate] compare:group.startDate] == NSOrderedAscending) {
                *stop = YES;
                return;
            }
            [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                              contentMode:PHImageContentModeAspectFit
                                  options:requestOptions
                            resultHandler:^(UIImage *image, NSDictionary *info) {
                                @autoreleasepool {
                                    //only detect images that are not downloaded or screenshot
                                    if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                        return;
                                    }
                                    /*
                                    //use local detector to find faces
                                    FaceppResult *detectResult = [FTDetector detectAndUploadWithImage:image];
                                    NSArray *faces = [[detectResult content] objectForKey:@"face"];
                                    NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
                                    for (NSDictionary *face in faces) {
                                        [faceIDs addObject:[face objectForKey:@"face_id"]];
                                    }
                                    FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.id orGroupName:nil andURL:nil orImageData:nil orKeyFaceId:faceIDs async:NO];
                                    */
                                    
                                    
                                    //NSArray *detectedFaces = [FTDetector detectFacesWithImage:image andImageInfo:info];
                                    //for (NSData *faceData in detectedFaces) {
                                        //FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.fppID orGroupName:group.name andURL:nil orImageData:faceData orKeyFaceId:nil async:NO];
                                    NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image andImageInfo:info];
                                    if ([detectedFaceIDs count]) {
                                        FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.fppID orGroupName:group.name andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:YES];
                                        
                                        NSString *sessionID = [[identifyResult content] objectForKey:@"session_id"];
                                        if (sessionID) {
                                            [self getResultForSession:sessionID completion:^(FaceppResult *result) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                if ([result success]) {
                                                    NSArray *identifiedFaces = [[[result content] objectForKey:@"result"] objectForKey:@"face"];
                                                    for (NSDictionary *face in identifiedFaces) {
                                                        NSArray *candidates = [face objectForKey:@"candidate"];
                                                        if ([candidates count]) {
                                                            NSDictionary *candidate = candidates[0];
                                                            // need to adjust confidence threshold based on performance
                                                            CGFloat confidenceThreshold = 5;
                                                            if ([[candidate objectForKey:@"confidence"] floatValue] > confidenceThreshold) {
                                                                    FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"]];
                                                                    [[FaceppAPI person] addFaceWithPersonName:person.name orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                                    if (person) {
                                                                        FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset];
                                                                        [person addPhoto:photo];
                                                                        [group addPhoto:photo];
                                                                    }
                                                                
                                                            }
                                                        }
                                                    }
                                                    
                                                }
                                                });
                                            } afterDelay:1.0];
                                        }
                                    }
                                }
                            }];
        }];

    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchPhotos];
        //[self.frc performFetch:NULL];
    });

    
    
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
        dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self getResultForSession:sessionID completion:completionBlock afterDelay:delay];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIBarButtonItem *createGroupButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createGroup)];
    
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(20, 0, 20, 0);
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchPhotos {
    self.photoColletions = [[NSMutableArray alloc] init];
    NSArray *photos = [FTPhoto fetchAll];
    for (FTPerson *person in [self.testGroup peopleArray]) {
        NSArray *collection = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FTPhoto *photo, NSDictionary *bindings) {
            return [[photo people] containsObject:person] && [[photo groups] containsObject:self.testGroup];
        }]];
        [self.photoColletions addObject:collection];
    }
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, 100);
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    //id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][section];
    //return [sectionInfo numberOfObjects];
    return [[self.photoColletions objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    //return [[self.frc sections] count];
    return [[self.testGroup people] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    FTPhoto *photo = [[self.photoColletions objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    //FTPhoto *photo = [self.frc objectAtIndexPath:indexPath];
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    [requestOptions setSynchronous:NO];
    [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
    
    [self.imageManager requestImageForAsset:photo.photoAsset targetSize:CGSizeMake(100 ,100)
                                contentMode:PHImageContentModeAspectFit
                                    options:requestOptions
                              resultHandler:^(UIImage *image, NSDictionary *info) {
                                  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
                                  [imageView setImage:image];
                                  [cell addSubview:imageView];
                              }];
    
    return cell;
}

/*
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, 44)];
        }
        
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, 44)];
        FTPerson *person = [[self.testGroup peopleArray] objectAtIndex:indexPath.section];
        label.text = [NSString stringWithFormat:@"%@", person.name];
        [reusableview addSubview:label];
        return reusableview;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize headerSize = CGSizeMake([self.view bounds].size.width, 44);
    return headerSize;
}
 */


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
    [self.collectionView reloadData];
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
    } completion:^(BOOL finished) {
        self.sectionChanges = nil;
        self.itemChanges = nil;
    }];
}


@end
