//
//  FTPerson.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTModel.h"
#import "FaceppAPI.h"
#import "FTDetector.h"

@class FTPhoto;
@class FTGroup;

@interface FTPerson : FTModel

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *fppID;
@property (nonatomic, strong) NSString *objectIDString;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *facesTrained;
@property (nonatomic, strong) NSData *profileImageData;

@property (nonatomic, strong) NSMutableArray *trainingImages;
@property (nonatomic, strong) NSMutableSet *photos;
@property (nonatomic, strong) NSMutableSet *groups;

- (id)initWithName:(NSString *)name andInitialTrainingImages:(NSArray *)images;
- (id)initWithName:(NSString *)name andInitialTrainingImages:(NSArray *)images withContext:(NSManagedObjectContext *)context;
- (void)trainWithImages:(NSArray *)images;
- (void)addPhoto:(FTPhoto *)photo;
- (void)addGroup:(FTGroup *)group;

@end
