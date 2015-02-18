//
//  FTPhoto.h
//  faceTagTester
//
//  Created by Siyao Clara Xie on 2/11/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import "FTModel.h"
#import <Photos/Photos.h>
#import "FTPerson.h"

@class FTGroup;

@interface FTPhoto : FTModel

@property (nonatomic, strong) NSString *assetURLString;
@property (nonatomic, retain) NSMutableSet *people;
@property (nonatomic, strong) PHAsset *photoAsset;
@property (nonatomic, strong) NSMutableSet *groups;
@property (nonatomic, strong) NSMutableSet *faceIDs;
@property (nonatomic, readonly) NSString *peopleNamesString;

-(id)initWithPhotoAsset:(PHAsset *)asset;
-(void)addPerson:(FTPerson *)person;
-(void)addGroup:(FTGroup *)group;

@end
