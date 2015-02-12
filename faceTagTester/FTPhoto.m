//
//  FTPhoto.m
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTPhoto.h"

@implementation FTPhoto

@dynamic assetURLString;
@dynamic people;
@dynamic photoAsset;


-(id)initWithPhotoAsset:(PHAsset *)asset {
    self = [super init];
    self.photoAsset = asset;
    return self;
}
@end
