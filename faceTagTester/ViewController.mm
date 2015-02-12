//
//  ViewController.m
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) FaceppLocalDetector *faceDetector;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *photoColletions;
@property (nonatomic, strong) FTGroup *testGroup;
@property (nonatomic, strong) PHImageManager *imageManager;
@end

@implementation ViewController

- (id)init {
    self = [super init];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:[[self view] bounds]];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
    [[self view] addSubview:self.collectionView];
    
    self.imageManager = [[PHImageManager alloc] init];
    
    FTPerson *siyao = [FTPerson fetchWithID:@"siyao"];
    if (!siyao) {
        siyao = [[FTPerson alloc] initWithName:@"siyao"];
    }
    [siyao trainWithImages:@[[UIImage imageNamed:@"siyao"]]];
    
    FTPerson *chengyue = [FTPerson fetchWithID:@"chengyue"];
    if (!chengyue) {
        chengyue = [[FTPerson alloc] initWithName:@"chengyue"];
    }
    [chengyue trainWithImages:@[[UIImage imageNamed:@"chengyue"]]];
    
    self.testGroup = [FTGroup fetchWithID:@"testGroup"];
    if (!self.testGroup) {
        self.testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue]];
        [self.testGroup setStartDate:[NSDate dateWithTimeIntervalSinceNow:7*24*60]];
        [self.testGroup setEndDate:[NSDate date]];
    }
    
    if ([[self.testGroup photos] count] == 0) {
        [self processImagesForGroup:self.testGroup];
    }
    return self;
    
}

- (void)processImagesForGroup:(FTGroup *)group {
    //fetch image assets within group's specified date range and only in camera roll
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    [options setPredicate:[NSPredicate predicateWithFormat:@"creationDate >= %@ && creationDate <= %@", group.startDate, group.endDate]];
    [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]]];
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    if ([collectionResult count]) {
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        [requestOptions setSynchronous:YES];
        [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
        
        //get image for image assets
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                              contentMode:PHImageContentModeAspectFit
                                  options:requestOptions
                            resultHandler:^(UIImage *image, NSDictionary *info) {
                                //only detect images that are not downloaded or screenshot
                                NSDictionary *metaData = [image CIImage].properties;
                                //use local detector to find faces
                                FaceppResult *detectResult = [FTDetector detectAndUploadWithImage:image];
                                NSArray *faces = [[detectResult content] objectForKey:@"face"];
                                NSMutableArray *faceIDs = [[NSMutableArray alloc] init];
                                for (NSDictionary *face in faces) {
                                    [faceIDs addObject:[face objectForKey:@"face_id"]];
                                }
                                FaceppResult *identifyResult = [[FaceppAPI recognition] identifyWithGroupId:group.id orGroupName:nil andURL:nil orImageData:nil orKeyFaceId:faceIDs async:NO];
                                
                                NSArray *identifiedFaces = [[identifyResult content] objectForKey:@"face"];
                                for (NSDictionary *face in identifiedFaces) {
                                    NSArray *candidates = [face objectForKey:@"candidate"];
                                    if ([candidates count]) {
                                        NSDictionary *candidate = candidates[0];
                                        if ([[candidate objectForKey:@"confidence"] floatValue] > 80) {
                                            FTPerson *person = [FTPerson fetchWithID:[candidate objectForKey:@"person_id"]];
                                            if (person) {
                                                FTPhoto *photo = [[FTPhoto alloc] initWithPhotoAsset:asset];
                                                [person addPhoto:photo];
#warning TODO-should think about range checking for groups (date, location)
                                                [group addPhoto:photo];
                                            }
                                        }
                                    }
                                    [faceIDs addObject:[face objectForKey:@"face_id"]];
                                }
                                
                            }];
        }];

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
    for (FTPerson *person in [self.testGroup people]) {
        NSArray *collection = [FTPhoto fetchWithPredicate:[NSPredicate predicateWithBlock:^BOOL(FTPhoto *evaluatedObject, NSDictionary *bindings) {
            return [[evaluatedObject people] containsObject:person];
        }]];
        [self.photoColletions addObject:collection];
    }
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, 44)];
        }
        
        UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, 44)];
        FTPerson * person = [[self.testGroup people] objectAtIndex:indexPath.section];
        label.text=[NSString stringWithFormat:@"%@", person.name];
        [reusableview addSubview:label];
        return reusableview;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize headerSize = CGSizeMake([self.view bounds].size.width, 44);
    return headerSize;
}

@end
