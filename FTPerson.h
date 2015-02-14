//
//  FTPerson.h
//  faceTagTester
//
//  Created by Siyao Xie on 2/10/15.
//  Copyright (c) 2015 Siyao Xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTModel.h"
#import "FTPhoto.h"
#import "FaceppAPI.h"
#import "FTDetector.h"

@interface FTPerson : FTModel

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *fppID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableSet *photos;
@property (nonatomic, strong) NSMutableSet *groups;

- (id)initWithName:(NSString *)name;
- (void)addTrainingImages:(NSArray *)images;
- (void)addPhoto:(FTPhoto *)photo;

@end
