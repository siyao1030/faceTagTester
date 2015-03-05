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
#import "FTGroup.h"

@interface FTPhoto : FTModel

@property (nonatomic, strong) NSString *assetURLString;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, retain) NSSet *people;
@property (nonatomic, strong) NSString *photoAssetIdentifier;
@property (nonatomic, strong) NSSet *groups;
@property (nonatomic, strong) NSSet *faceIDs;
@property (nonatomic, strong) NSString *peopleNamesString;
@property (nonatomic, strong) NSDate *creationDate;

-(id)initWithPhotoAsset:(PHAsset *)asset;
-(id)initWithPhotoAsset:(PHAsset *)asset withContext:(NSManagedObjectContext *)context;

-(void)addPerson:(FTPerson *)person;
-(void)addGroup:(FTGroup *)group;

-(NSString *)namesString;
@end
