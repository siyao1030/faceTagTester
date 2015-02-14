//
//  FTPhoto.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTModel.h"
#import <Photos/Photos.h>

@interface FTPhoto : FTModel

@property (nonatomic, strong) NSString *assetURLString;
@property (nonatomic, retain) NSSet *people;
@property (nonatomic, strong) PHAsset *photoAsset;
@property (nonatomic, strong) NSMutableSet *groups;
@property (nonatomic, strong) NSMutableSet *faceIDs;

-(id)initWithPhotoAsset:(PHAsset *)asset;

@end
