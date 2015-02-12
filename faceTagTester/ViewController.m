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
@property (nonatomic, strong) PHPhotoLibrary *photoLibrary;
@property (nonatomic, strong) NSArray *photoColletions;
@end

@implementation ViewController

- (id)init {
    self = [super init];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:[[self view] bounds]];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    
    [[self view] addSubview:self.collectionView];
    
    self.photoLibrary = [[PHPhotoLibrary alloc] init];
    
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
    
    FTGroup *testGroup = [FTGroup fetchWithID:@"testGroup"];
    if (!testGroup) {
        testGroup = [[FTGroup alloc] initWithName:@"testGroup" andPeople:@[siyao, chengyue]];
        [testGroup setStartDate:[NSDate dateWithTimeIntervalSinceNow:7*24*60]];
        [testGroup setEndDate:[NSDate date]];
    }
    
    if ([[testGroup photos] count] == 0) {
        [self processImagesForGroup:testGroup];
    }
    return self;
    
}

- (void)processImagesForGroup:(FTGroup *)group {
    //fetch image assets within 
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    [options setPredicate:[NSPredicate predicateWithFormat:@"creationDate >= %@ && creationDate <= %@", group.startDate, group.endDate]];
    [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]]];
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    if ([collectionResult count]) {
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collectionResult[0] options:options];
        PHImageManager *manager = [[PHImageManager alloc] init];
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        [requestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeFastFormat];
        
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            [manager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth,asset.pixelHeight)
                              contentMode:PHImageContentModeAspectFit
                                  options:requestOptions
                            resultHandler:^(UIImage *image, NSDictionary *info) {
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
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchPhotos {
    
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    NSString *searchTerm = self.searches[section];
    return [self.searchResults[searchTerm] count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"FlickrCell " forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

@end
