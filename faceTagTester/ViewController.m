//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *testGroup;
@property (nonatomic, strong) PHImageManager *imageManager;
@end

@implementation ViewController

- (id)init {
    self = [super init];
    
    self.imageManager = [[PHImageManager alloc] init];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:[[self view] bounds] collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
    [[self view] addSubview:self.collectionView];
    
    FTPerson *siyao = [FTPerson fetchWithID:@"siyao"];
    if (!siyao) {
        siyao = [[FTPerson alloc] initWithName:@"siyao"];
        [siyao addTrainingImages:@[[UIImage imageNamed:@"siyao-s.jpg"]]];
    }
    
    FTPerson *chengyue = [FTPerson fetchWithID:@"chengyue"];
    if (!chengyue) {
        chengyue = [[FTPerson alloc] initWithName:@"chengyue"];
        [chengyue addTrainingImages:@[[UIImage imageNamed:@"chengyue-s.jpg"]]];
    }
    
    self.testGroup = [FTGroup fetchWithID:@"testGroup"];
    if (!self.testGroup) {
        self.testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue]];
    }
    [self.testGroup setStartDate:[NSDate dateWithTimeIntervalSinceNow:-7*24*60*60]];
    [self.testGroup setEndDate:[NSDate date]];
    
    FaceppResult *result = [[FaceppAPI train] trainAsynchronouslyWithId:self.testGroup.fppID orName:self.testGroup.name andType:FaceppTrainIdentify];
    NSString *sessionID = [[result content] objectForKey:@"session_id"];
    if (sessionID) {
        [self getResultForSession:sessionID completion:^(FaceppResult *result) {
            if ([result success]) {
                if ([[self.testGroup photos] count] == 0) {
                    [self processImagesForGroup:self.testGroup];
                }
                [self fetchPhotos];
            }
        } afterDelay:2.0];
    }
    
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
            if ([[asset creationDate] compare:group.startDate] == NSOrderedAscending) {
                *stop = YES;
                return;
            }
            [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                              contentMode:PHImageContentModeAspectFit
                                  options:requestOptions
                            resultHandler:^(UIImage *image, NSDictionary *info) {
                                //only detect images that are not downloaded or screenshot
                                if ([[info objectForKey:@"PHImageFileUTIKey"] isEqualToString:@"public.png"]) {
                                    return;
                                }
                                if ([[[info objectForKey:@"PHImageFileURLKey"] absoluteString] isEqualToString:@"file:///var/mobile/Media/DCIM/106APPLE/IMG_6527.JPG"]) {
                                    NSLog(@"should have a face!");
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
                                NSArray *detectedFaceIDs = [FTDetector detectFaceIDsWithImage:image];
                                if ([detectedFaceIDs count]) {
                                    FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.fppID orGroupName:group.name andURL:nil orImageData:nil orKeyFaceId:detectedFaceIDs async:NO];
                                    
                                    NSArray *identifiedFaces = [[identifyResult content] objectForKey:@"face"];
                                    for (NSDictionary *face in identifiedFaces) {
                                        NSArray *candidates = [face objectForKey:@"candidate"];
                                        if ([candidates count]) {
                                            NSDictionary *candidate = candidates[0];
                                            if ([[candidate objectForKey:@"confidence"] floatValue] > 60) {
                                                FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_name"]];
                                                [[FaceppAPI person] addFaceWithPersonName:person.name orPersonId:person.fppID andFaceId:@[[face objectForKey:@"face_id"]]];
                                                if (person) {
                                                    FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset];
                                                    [person addPhoto:photo];
#warning TODO-should think about range checking for groups (date, location)
                                                    [group addPhoto:photo];
                                                }
                                            }
                                        }
                                    }

                                }
                                
                            }];
        }];

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
        /*NSArray *collection = [FTPhoto fetchWithPredicate:[NSPredicate predicateWithBlock:^BOOL(FTPhoto *evaluatedObject, NSDictionary *bindings) {
            return [[evaluatedObject people] containsObject:person];
        }]];*/
        NSArray *collection = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FTPhoto *evaluatedObject, NSDictionary *bindings) {
            return [[evaluatedObject people] containsObject:person];
        }]];
        [self.photoColletions addObject:collection];
    }
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(50, 50);
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [[self.photoColletions objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return [[self.testGroup people] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    FTPhoto *photo = [[self.photoColletions objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    [requestOptions setSynchronous:NO];
    [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
    
    [self.imageManager requestImageForAsset:photo.photoAsset targetSize:CGSizeMake(50,50)
                                contentMode:PHImageContentModeAspectFit
                                    options:requestOptions
                              resultHandler:^(UIImage *image, NSDictionary *info) {
                                  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
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

@end
